"""Flask backend for Ledgar Shredder.

Implements bcrypt-hashed password storage, JWT-based login, and a protected
profile endpoint backed by MongoDB Atlas.
"""

import os
import re
from datetime import datetime, timedelta, timezone
from functools import wraps

import bcrypt
import jwt
from bson import ObjectId
from bson.errors import InvalidId
from dotenv import load_dotenv
from flask import Flask, g, jsonify, request
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
from pymongo.server_api import ServerApi

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
JWT_SECRET = os.getenv("JWT_SECRET")

if not MONGO_URI:
    raise RuntimeError("MONGO_URI is not set in environment")
if not JWT_SECRET:
    raise RuntimeError("JWT_SECRET is not set in environment")

JWT_ALGORITHM = "HS256"
JWT_EXPIRES_IN = timedelta(days=7)
EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
MIN_PASSWORD_LEN = 6

app = Flask(__name__)

client = MongoClient(MONGO_URI, server_api=ServerApi("1"))
db = client["hackku_db"]
users = db["users"]

# Enforce one account per email at the database layer
users.create_index("email", unique=True)


def _issue_token(user_id: str, email: str) -> str:
    """Create a signed JWT carrying the user id and email."""
    payload = {
        "user_id": user_id,
        "email": email,
        "exp": datetime.now(tz=timezone.utc) + JWT_EXPIRES_IN,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def require_auth(view):
    """Decorator that validates `Authorization: Bearer <jwt>` and exposes the
    decoded identity through `flask.g`."""

    @wraps(view)
    def wrapper(*args, **kwargs):
        header = request.headers.get("Authorization", "")
        if not header.startswith("Bearer "):
            return jsonify({"error": "Missing or malformed Authorization header"}), 401

        token = header[len("Bearer "):].strip()
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expired"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid token"}), 401

        g.user_id = payload.get("user_id")
        g.email = payload.get("email")
        return view(*args, **kwargs)

    return wrapper


@app.route("/")
def home():
    return {"status": "API running"}


@app.route("/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not EMAIL_REGEX.match(email):
        return jsonify({"error": "Invalid email"}), 400
    if len(password) < MIN_PASSWORD_LEN:
        return jsonify(
            {"error": f"Password must be at least {MIN_PASSWORD_LEN} characters"}
        ), 400

    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())

    try:
        users.insert_one(
            {
                "email": email,
                "password": hashed,
                "created_at": datetime.now(tz=timezone.utc),
            }
        )
    except DuplicateKeyError:
        return jsonify({"error": "User already exists"}), 409

    return jsonify({"message": "User created"}), 201


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    user = users.find_one({"email": email})
    if not user:
        return jsonify({"error": "Invalid credentials"}), 401

    stored_hash = user.get("password")
    # Legacy plaintext rows from the previous version would not be bytes; reject them
    if not isinstance(stored_hash, (bytes, bytearray)):
        return jsonify({"error": "Invalid credentials"}), 401

    if not bcrypt.checkpw(password.encode("utf-8"), stored_hash):
        return jsonify({"error": "Invalid credentials"}), 401

    token = _issue_token(str(user["_id"]), user["email"])
    return jsonify({"token": token})


@app.route("/profile", methods=["GET"])
@require_auth
def profile():
    try:
        oid = ObjectId(g.user_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid token subject"}), 401

    user = users.find_one({"_id": oid}, {"password": 0})
    if not user:
        return jsonify({"error": "User not found"}), 404

    created_at = user.get("created_at")
    return jsonify(
        {
            "id": str(user["_id"]),
            "email": user["email"],
            "created_at": created_at.isoformat() if created_at else None,
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
