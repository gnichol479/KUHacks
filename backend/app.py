"""Flask backend for Ledger Shredder.

Implements bcrypt-hashed password storage, JWT-based login, and a protected
profile endpoint backed by MongoDB Atlas.
"""

import base64
import json
import math
import os
import re
from datetime import datetime, timedelta, timezone
from functools import wraps

import bcrypt
import jwt
import requests
from bson import ObjectId
from bson.errors import InvalidId
from dotenv import load_dotenv
from flask import Flask, g, jsonify, request
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError
from pymongo.server_api import ServerApi

from xrpl_utils import (
    XRP_TO_USD_RATE,
    convert_xrp_to_usd,
    create_xrpl_wallet,
    drops_to_xrp,
    get_xrp_balance,
    send_xrp_payment,
    usd_to_drops,
)

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
JWT_SECRET = os.getenv("JWT_SECRET")
# Optional — if unset, /scan-receipt returns 503 so the rest of the API still
# boots cleanly in dev environments without a Gemini key.
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
GEMINI_ENDPOINT = (
    "https://generativelanguage.googleapis.com/v1beta/models/"
    f"{GEMINI_MODEL}:generateContent"
)

if not MONGO_URI:
    raise RuntimeError("MONGO_URI is not set in environment")
if not JWT_SECRET:
    raise RuntimeError("JWT_SECRET is not set in environment")

JWT_ALGORITHM = "HS256"
JWT_EXPIRES_IN = timedelta(days=7)
EMAIL_REGEX = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
MIN_PASSWORD_LEN = 6
DEFAULT_ACCOUNTABILITY_SCORE = 100


def initialize_accountability_score() -> int:
    """Starting score for every new account. Scoring logic is intentionally
    out of scope for now — callers should treat 100 as a clean slate."""
    return DEFAULT_ACCOUNTABILITY_SCORE

app = Flask(__name__)

client = MongoClient(MONGO_URI, server_api=ServerApi("1"))
db = client["hackku_db"]
users = db["users"]
ledgers = db["ledgers"]
groups = db["groups"]
entry_requests = db["entry_requests"]

# Enforce one account per email at the database layer
users.create_index("email", unique=True)

# Legacy: an earlier version of this file declared
#   ledgers.create_index("users", unique=True)
# which Mongo turned into a *multikey* unique index. Multikey unique indexes
# enforce uniqueness on each individual array element across the entire
# collection, so once user A appeared in any ledger, no other ledger doc could
# include A — silently breaking every subsequent friend request from A. Drop
# that index if it's still around so existing deployments self-heal.
try:
    ledgers.drop_index("users_1")
except Exception:
    pass

# Backfill: any pre-friend-request-system ledgers (no `status`) were created
# under the old "instant add" model and should be treated as accepted so the
# People screen still shows them after we tighten /ledgers to accepted-only.
ledgers.update_many(
    {"status": {"$exists": False}},
    {"$set": {"status": "accepted"}},
)


def _pair_key(user_ids: list) -> str:
    """Canonical scalar identity for a 2-user ledger: sorted ids joined by '|'.
    Stored on every ledger and indexed uniquely so duplicate pairs are rejected
    without falling into the multikey-unique trap above."""
    return "|".join(sorted(user_ids))


# Allowed values for the "Due in" picker. Anything outside this set is
# rejected so we don't end up with arbitrary client-supplied due dates.
ALLOWED_DUE_IN_DAYS = {3, 7, 14, 30, 90}


def _parse_due_in_days(raw):
    """Coerce the request body's `due_in_days` into either a whitelisted int
    or `None` (= no due date). Returns `(days, error)` where `error` is
    `(payload, code)` on validation failure."""
    if raw is None:
        return None, None
    try:
        days = int(raw)
    except (TypeError, ValueError):
        return None, ({"error": "due_in_days must be an integer"}, 400)
    if days not in ALLOWED_DUE_IN_DAYS:
        allowed = ", ".join(str(d) for d in sorted(ALLOWED_DUE_IN_DAYS))
        return None, (
            {"error": f"due_in_days must be one of: {allowed}"},
            400,
        )
    return days, None


# Backfill `pair_key` on legacy ledger docs that predate this field so the
# unique index below can be built without conflicts.
for _doc in ledgers.find(
    {"pair_key": {"$exists": False}}, {"users": 1}
):
    pair = _doc.get("users") or []
    if len(pair) != 2:
        continue
    ledgers.update_one(
        {"_id": _doc["_id"]},
        {"$set": {"pair_key": _pair_key(pair)}},
    )

# Real per-pair uniqueness lives on the scalar `pair_key` field.
ledgers.create_index("pair_key", unique=True)
# Non-unique multikey index on `users` to keep membership queries
# ({"users": me}) fast.
ledgers.create_index("users")

# Multikey index on group membership so the "groups I'm in" query stays fast.
groups.create_index("members")

# Entry-request lookups: pending IOUs awaiting acceptance from a recipient.
# Both the inbox query (`to_user_id == me`) and the outbox query
# (`from_user_id == me`) need to be O(log n).
entry_requests.create_index("to_user_id")
entry_requests.create_index("from_user_id")
entry_requests.create_index([("scope", 1), ("ledger_id", 1)])
entry_requests.create_index([("scope", 1), ("group_id", 1)])


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

    # Pre-check duplicate so we don't burn a faucet wallet on a request that
    # is going to fail at insert anyway.
    if users.find_one({"email": email}):
        return jsonify({"error": "User already exists"}), 409

    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())

    # Provision a TESTNET XRPL wallet for the new account. If the public
    # faucet is unavailable we surface a 503 instead of half-creating a user.
    try:
        wallet = create_xrpl_wallet()
    except Exception:
        return jsonify({"error": "XRPL faucet unavailable, please retry"}), 503

    # Best-effort balance fetch; helper returns 0 on any failure so this never
    # blocks registration. The ledger speaks in drops — convert for display.
    balance_drops = get_xrp_balance(wallet["address"])
    balance_xrp = drops_to_xrp(balance_drops)
    balance_usd = convert_xrp_to_usd(balance_xrp)

    try:
        users.insert_one(
            {
                "email": email,
                "password": hashed,
                "created_at": datetime.now(tz=timezone.utc),
                "xrpl": {
                    "address": wallet["address"],
                    "seed": wallet["seed"],  # TESTNET ONLY — never returned by the API
                    "public_key": wallet["public_key"],
                    "balance_xrp": balance_xrp,
                    "balance_usd": balance_usd,
                    "conversion_rate": XRP_TO_USD_RATE,
                },
                "profile": {
                    "full_name": None,
                    "username": None,
                    "phone": None,
                    "onboarding_completed": False,
                },
                "accountability_score": initialize_accountability_score(),
            }
        )
    except DuplicateKeyError:
        # Race with a concurrent registration that won the unique index.
        return jsonify({"error": "User already exists"}), 409

    return jsonify(
        {
            "message": "User created",
            "xrpl_address": wallet["address"],
            "balance_xrp": balance_xrp,
            "balance_usd": balance_usd,
            "conversion_rate": XRP_TO_USD_RATE,
        }
    ), 201


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


# Mongo projection slice that pulls every public profile field — including
# the avatar — so list endpoints can denormalize the same shape /profile
# returns. Spread into a `find` projection to avoid repeating field names.
_PUBLIC_PROFILE_PROJECTION = {
    "profile.full_name": 1,
    "profile.username": 1,
    "profile.avatar_base64": 1,
    "profile.avatar_mime": 1,
}


def _avatar_fields(profile_doc: dict) -> dict:
    """Return just the avatar half of a public user view. Spread into the
    output dict at every "other user" emission site so friends, group
    members, request senders, etc. all carry the photo to the client."""
    return {
        "avatar_base64": (profile_doc or {}).get("avatar_base64"),
        "avatar_mime": (profile_doc or {}).get("avatar_mime"),
    }


def _serialize_profile(user_doc: dict) -> dict:
    """Build the public-facing `profile` block for a user document. Defaults
    keep legacy accounts (created before the onboarding feature) safe."""
    profile_doc = user_doc.get("profile") or {}
    return {
        "full_name": profile_doc.get("full_name"),
        "username": profile_doc.get("username"),
        "phone": profile_doc.get("phone"),
        "onboarding_completed": bool(profile_doc.get("onboarding_completed", False)),
        "avatar_base64": profile_doc.get("avatar_base64"),
        "avatar_mime": profile_doc.get("avatar_mime"),
        "accountability_score": user_doc.get(
            "accountability_score", DEFAULT_ACCOUNTABILITY_SCORE
        ),
    }


@app.route("/profile", methods=["GET"])
@require_auth
def profile():
    try:
        oid = ObjectId(g.user_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid token subject"}), 401

    # Strip the password hash AND the XRPL seed from the projection so neither
    # ever leaves the server.
    user = users.find_one({"_id": oid}, {"password": 0, "xrpl.seed": 0})
    if not user:
        return jsonify({"error": "User not found"}), 404

    created_at = user.get("created_at")
    xrpl_doc = user.get("xrpl") or {}
    return jsonify(
        {
            "id": str(user["_id"]),
            "email": user["email"],
            "created_at": created_at.isoformat() if created_at else None,
            "xrpl": {
                "address": xrpl_doc.get("address"),
                "public_key": xrpl_doc.get("public_key"),
                # Default to 0 for legacy docs created before the USD fields
                # were added — keeps /profile from crashing on older accounts.
                "balance_xrp": xrpl_doc.get("balance_xrp", 0),
                "balance_usd": xrpl_doc.get("balance_usd", 0),
                "conversion_rate": xrpl_doc.get("conversion_rate", XRP_TO_USD_RATE),
            },
            "profile": _serialize_profile(user),
        }
    )


ALLOWED_AVATAR_MIMES = {"image/jpeg", "image/png", "image/webp"}
MAX_AVATAR_BYTES = 512 * 1024  # 512 KB raw image budget


@app.route("/profile", methods=["PATCH"])
@require_auth
def update_profile():
    """Partial profile update used by the in-app Settings > Profile tab.

    Accepts any subset of `full_name`, `avatar_base64`, `avatar_mime`. Pass
    `avatar_base64: null` to remove an existing photo. Only the keys actually
    present in the body are written, so callers can edit the name and the
    avatar independently.
    """
    try:
        oid = ObjectId(g.user_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid token subject"}), 401

    data = request.get_json(silent=True) or {}

    set_ops: dict = {}
    unset_ops: dict = {}

    if "full_name" in data:
        full_name = (data.get("full_name") or "").strip()
        if not full_name:
            return jsonify({"error": "full_name cannot be empty"}), 400
        set_ops["profile.full_name"] = full_name

    if "avatar_base64" in data:
        raw_b64 = data.get("avatar_base64")
        if raw_b64 is None or (isinstance(raw_b64, str) and not raw_b64.strip()):
            unset_ops["profile.avatar_base64"] = ""
            unset_ops["profile.avatar_mime"] = ""
        else:
            if not isinstance(raw_b64, str):
                return jsonify({"error": "avatar_base64 must be a string"}), 400
            try:
                decoded = base64.b64decode(raw_b64, validate=True)
            except (ValueError, base64.binascii.Error):
                return jsonify({"error": "avatar_base64 is not valid base64"}), 400
            if len(decoded) > MAX_AVATAR_BYTES:
                return jsonify(
                    {"error": "Avatar exceeds 512 KB after decoding"}
                ), 413

            mime = (data.get("avatar_mime") or "image/jpeg").strip().lower()
            if mime not in ALLOWED_AVATAR_MIMES:
                return jsonify(
                    {
                        "error": "avatar_mime must be one of "
                        + ", ".join(sorted(ALLOWED_AVATAR_MIMES))
                    }
                ), 400
            set_ops["profile.avatar_base64"] = raw_b64
            set_ops["profile.avatar_mime"] = mime

    if not set_ops and not unset_ops:
        return jsonify({"error": "No editable fields supplied"}), 400

    update_doc: dict = {}
    if set_ops:
        update_doc["$set"] = set_ops
    if unset_ops:
        update_doc["$unset"] = unset_ops

    result = users.update_one({"_id": oid}, update_doc)
    if result.matched_count == 0:
        return jsonify({"error": "User not found"}), 404

    user = users.find_one({"_id": oid}, {"password": 0, "xrpl.seed": 0})
    return jsonify(
        {
            "message": "Profile updated",
            "profile": _serialize_profile(user),
        }
    )


@app.route("/onboarding", methods=["POST"])
@require_auth
def onboarding():
    try:
        oid = ObjectId(g.user_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid token subject"}), 401

    data = request.get_json(silent=True) or {}
    full_name = (data.get("full_name") or "").strip()
    username = (data.get("username") or "").strip()
    phone = (data.get("phone") or "").strip()

    if not full_name or not username or not phone:
        return jsonify(
            {"error": "full_name, username, and phone are required"}
        ), 400

    # Backfill accountability_score for legacy accounts that predate this
    # field, so they don't end up null after onboarding.
    users.update_one(
        {"_id": oid, "accountability_score": {"$exists": False}},
        {"$set": {"accountability_score": initialize_accountability_score()}},
    )

    result = users.update_one(
        {"_id": oid},
        {
            "$set": {
                "profile.full_name": full_name,
                "profile.username": username,
                "profile.phone": phone,
                "profile.onboarding_completed": True,
            }
        },
    )
    if result.matched_count == 0:
        return jsonify({"error": "User not found"}), 404

    user = users.find_one({"_id": oid}, {"password": 0, "xrpl.seed": 0})
    profile_block = _serialize_profile(user)

    return jsonify(
        {
            "message": "Onboarding complete",
            "profile": profile_block,
            "accountability_score": profile_block["accountability_score"],
        }
    )


@app.route("/users/search", methods=["GET"])
@require_auth
def search_users():
    """Find up to 10 onboarded users matching `q` against username or
    full_name (case-insensitive). Self is excluded so users can't add themselves
    on the frontend, and accounts without a username (legacy / pre-onboarding)
    are filtered out since they're not actionable."""
    q = (request.args.get("q") or "").strip()
    if not q:
        return jsonify([])

    try:
        me = ObjectId(g.user_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid token subject"}), 401

    pattern = {"$regex": re.escape(q), "$options": "i"}
    cursor = users.find(
        {
            "_id": {"$ne": me},
            "$or": [
                {"profile.username": pattern},
                {"profile.full_name": pattern},
            ],
        },
        {
            **_PUBLIC_PROFILE_PROJECTION,
            "accountability_score": 1,
        },
    ).limit(10)

    results = []
    for doc in cursor:
        prof = doc.get("profile") or {}
        if not prof.get("username"):
            continue
        uid = str(doc["_id"])
        results.append(
            {
                "id": uid,
                "full_name": prof.get("full_name"),
                "username": prof.get("username"),
                **_avatar_fields(prof),
                "accountability_score": _compute_accountability_score(uid),
            }
        )
    return jsonify(results)


@app.route("/contacts/add", methods=["POST"])
@require_auth
def add_contact():
    """Send a friend request to the given user. Creates a `pending` ledger
    keyed on the sorted pair so the unique index still rejects duplicate
    requests (in either direction). If a ledger already exists between the
    two users we return its current state so the client can react (e.g. "you
    already sent this request" vs. "already a contact")."""
    data = request.get_json(silent=True) or {}
    target_id = (data.get("user_id") or "").strip()
    if not target_id:
        return jsonify({"error": "user_id is required"}), 400
    if target_id == g.user_id:
        return jsonify({"error": "Cannot add yourself"}), 400

    try:
        target_oid = ObjectId(target_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid user_id"}), 400

    if not users.find_one({"_id": target_oid}, {"_id": 1}):
        return jsonify({"error": "User not found"}), 404

    pair = sorted([g.user_id, target_id])
    pair_key = _pair_key(pair)
    existing = ledgers.find_one({"pair_key": pair_key})
    if existing:
        status = existing.get("status", "accepted")
        message = (
            "Contact already exists"
            if status == "accepted"
            else "Request already exists"
        )
        return jsonify(
            {
                "message": message,
                "ledger_id": str(existing["_id"]),
                "status": status,
                "users": existing["users"],
            }
        )

    now = datetime.now(tz=timezone.utc)
    try:
        result = ledgers.insert_one(
            {
                "users": pair,
                "pair_key": pair_key,
                "balance": 0,
                "status": "pending",
                "requested_by": g.user_id,
                "created_at": now,
                "updated_at": now,
            }
        )
        ledger_id = str(result.inserted_id)
        status = "pending"
    except DuplicateKeyError:
        # True race on the same pair — refetch by the scalar pair_key (the
        # only field with a unique constraint now) so we always have a real
        # ledger_id to return.
        existing = ledgers.find_one({"pair_key": pair_key})
        ledger_id = str(existing["_id"]) if existing else ""
        status = (existing or {}).get("status", "pending")

    return jsonify(
        {
            "message": "Request sent",
            "ledger_id": ledger_id,
            "status": status,
            "users": pair,
        }
    )


@app.route("/contacts/requests", methods=["GET"])
@require_auth
def list_contact_requests():
    """Return incoming pending friend requests — i.e. ledgers where the
    current user is a member, status is pending, and the *other* side
    initiated the request."""
    me = g.user_id
    docs = list(
        ledgers.find(
            {
                "users": me,
                "status": "pending",
                "requested_by": {"$ne": me},
            }
        )
    )

    requester_oids = []
    for d in docs:
        sid = d.get("requested_by")
        if not sid:
            continue
        try:
            requester_oids.append(ObjectId(sid))
        except (InvalidId, TypeError):
            continue

    profile_by_id = {}
    if requester_oids:
        for u in users.find(
            {"_id": {"$in": requester_oids}},
            _PUBLIC_PROFILE_PROJECTION,
        ):
            profile_by_id[str(u["_id"])] = u.get("profile") or {}

    out = []
    for d in docs:
        from_id = d.get("requested_by")
        if from_id is None:
            continue
        prof = profile_by_id.get(from_id, {})
        out.append(
            {
                "ledger_id": str(d["_id"]),
                "from_user": {
                    "id": from_id,
                    "full_name": prof.get("full_name"),
                    "username": prof.get("username"),
                    **_avatar_fields(prof),
                    "accountability_score": _compute_accountability_score(
                        from_id
                    ),
                },
            }
        )
    return jsonify(out)


@app.route("/contacts/sent", methods=["GET"])
@require_auth
def list_sent_requests():
    """Return outgoing pending friend requests — i.e. ledgers where the
    current user initiated the request and it hasn't been accepted yet."""
    me = g.user_id
    docs = list(
        ledgers.find(
            {
                "users": me,
                "status": "pending",
                "requested_by": me,
            }
        )
    )

    other_oids = []
    for d in docs:
        for sid in d.get("users", []):
            if sid == me:
                continue
            try:
                other_oids.append(ObjectId(sid))
            except (InvalidId, TypeError):
                continue

    profile_by_id = {}
    if other_oids:
        for u in users.find(
            {"_id": {"$in": other_oids}},
            _PUBLIC_PROFILE_PROJECTION,
        ):
            profile_by_id[str(u["_id"])] = u.get("profile") or {}

    out = []
    for d in docs:
        other_id = next((u for u in d.get("users", []) if u != me), None)
        if other_id is None:
            continue
        prof = profile_by_id.get(other_id, {})
        out.append(
            {
                "ledger_id": str(d["_id"]),
                "to_user": {
                    "id": other_id,
                    "full_name": prof.get("full_name"),
                    "username": prof.get("username"),
                    **_avatar_fields(prof),
                    "accountability_score": _compute_accountability_score(
                        other_id
                    ),
                },
            }
        )
    return jsonify(out)


@app.route("/contacts/accept", methods=["POST"])
@require_auth
def accept_contact():
    """Accept an incoming pending request. The query enforces that the current
    user is a member of the ledger, the ledger is still pending, and they are
    NOT the original requester (you can't accept your own outgoing request)."""
    data = request.get_json(silent=True) or {}
    ledger_id = (data.get("ledger_id") or "").strip()
    if not ledger_id:
        return jsonify({"error": "ledger_id is required"}), 400

    try:
        lid = ObjectId(ledger_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid ledger_id"}), 400

    result = ledgers.update_one(
        {
            "_id": lid,
            "users": g.user_id,
            "status": "pending",
            "requested_by": {"$ne": g.user_id},
        },
        {
            "$set": {
                "status": "accepted",
                "updated_at": datetime.now(tz=timezone.utc),
            }
        },
    )
    if result.matched_count == 0:
        return jsonify({"error": "Request not found"}), 404
    return jsonify({"message": "Request accepted"})


@app.route("/contacts/reject", methods=["POST"])
@require_auth
def reject_contact():
    """Reject (or cancel) a pending request by deleting the ledger. Either
    side may call this; once accepted, the relationship is no longer
    "rejectable" via this route."""
    data = request.get_json(silent=True) or {}
    ledger_id = (data.get("ledger_id") or "").strip()
    if not ledger_id:
        return jsonify({"error": "ledger_id is required"}), 400

    try:
        lid = ObjectId(ledger_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid ledger_id"}), 400

    result = ledgers.delete_one(
        {
            "_id": lid,
            "users": g.user_id,
            "status": "pending",
        }
    )
    if result.deleted_count == 0:
        return jsonify({"error": "Request not found"}), 404
    return jsonify({"message": "Request rejected"})


def _viewer_sign(ledger_doc: dict, viewer_id: str) -> int:
    """Return +1 if viewer is users[0] in the sorted pair, -1 otherwise.
    Used to flip the canonical (users[0] POV) balance/deltas into a value
    that means "positive => they owe you" for whichever side is viewing."""
    pair = ledger_doc.get("users") or []
    if not pair:
        return 1
    return 1 if viewer_id == pair[0] else -1


def _serialize_entry(entry: dict, viewer_sign: int, viewer_id: str) -> dict:
    raw_amount = entry.get("amount", 0) or 0
    delta = entry.get("delta_users0", 0) or 0
    signed = delta * viewer_sign
    created_at = entry.get("created_at")
    due_at = entry.get("due_at")
    return {
        "id": str(entry.get("_id")) if entry.get("_id") is not None else None,
        "description": entry.get("description"),
        "amount": float(raw_amount),
        "signed_amount": float(signed),
        "direction": "they_owe_you" if signed >= 0 else "you_owe",
        "created_at": created_at.isoformat() if created_at else None,
        "due_at": due_at.isoformat() if due_at else None,
        "mine": entry.get("created_by") == viewer_id,
        "method": entry.get("method"),
        "tx_hash": entry.get("tx_hash"),
    }


@app.route("/ledgers", methods=["GET"])
@require_auth
def list_ledgers():
    """Return every accepted ledger the current user is part of, with the
    *other* user's public profile fields denormalized into the response so
    the client can render the list in one round-trip. The `balance` is
    flipped into the viewer's POV (positive => they owe you)."""
    me = g.user_id
    docs = list(ledgers.find({"users": me, "status": "accepted"}))

    other_oids = []
    for d in docs:
        for sid in d.get("users", []):
            if sid == me:
                continue
            try:
                other_oids.append(ObjectId(sid))
            except (InvalidId, TypeError):
                continue

    profile_by_id = {}
    if other_oids:
        for u in users.find(
            {"_id": {"$in": other_oids}},
            _PUBLIC_PROFILE_PROJECTION,
        ):
            profile_by_id[str(u["_id"])] = u.get("profile") or {}

    out = []
    for d in docs:
        other_id = next((u for u in d.get("users", []) if u != me), None)
        if other_id is None:
            continue
        prof = profile_by_id.get(other_id, {})
        sign = _viewer_sign(d, me)
        raw_balance = d.get("balance", 0) or 0
        out.append(
            {
                "ledger_id": str(d["_id"]),
                "other_user": {
                    "id": other_id,
                    "full_name": prof.get("full_name"),
                    "username": prof.get("username"),
                    **_avatar_fields(prof),
                    "accountability_score": _compute_accountability_score(
                        other_id
                    ),
                },
                "balance": float(raw_balance) * sign,
            }
        )
    return jsonify(out)


@app.route("/ledgers/<ledger_id>", methods=["GET"])
@require_auth
def get_ledger(ledger_id: str):
    """Return a single accepted ledger with its entry history, all flipped
    into the viewer's POV. Newest entry first."""
    me = g.user_id
    try:
        lid = ObjectId(ledger_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid ledger_id"}), 400

    doc = ledgers.find_one({"_id": lid, "users": me, "status": "accepted"})
    if not doc:
        return jsonify({"error": "Ledger not found"}), 404

    other_id = next((u for u in doc.get("users", []) if u != me), None)
    other_profile = {}
    if other_id:
        try:
            other_doc = users.find_one(
                {"_id": ObjectId(other_id)},
                _PUBLIC_PROFILE_PROJECTION,
            )
            if other_doc:
                other_profile = other_doc.get("profile") or {}
        except (InvalidId, TypeError):
            pass

    sign = _viewer_sign(doc, me)
    raw_balance = doc.get("balance", 0) or 0
    raw_entries = doc.get("entries") or []
    history = [
        _serialize_entry(e, sign, me) for e in reversed(raw_entries)
    ]

    return jsonify(
        {
            "ledger_id": str(doc["_id"]),
            "other_user": {
                "id": other_id,
                "full_name": other_profile.get("full_name"),
                "username": other_profile.get("username"),
                **_avatar_fields(other_profile),
                "accountability_score": (
                    _compute_accountability_score(other_id)
                    if other_id
                    else None
                ),
            },
            "balance": float(raw_balance) * sign,
            "history": history,
        }
    )


def _apply_ledger_entry(
    lid: ObjectId,
    me: str,
    description: str,
    amount: float,
    direction: str,
    due_at=None,
):
    """Append a validated IOU entry to an accepted ledger and update its
    running balance. Returns `(status_code, payload)` where payload is the
    JSON-serializable dict the route should return. Direction is interpreted
    from `me`'s POV (`they_owe_me` / `i_owe_them`). The signed delta is
    stored in users[0]'s POV so both members share one canonical history.
    `due_at` is the optional deadline carried from the create-request payload
    (or computed at instant-IOU time) and is what the accountability score
    reads to decide if a settle was on-time."""
    doc = ledgers.find_one({"_id": lid, "users": me, "status": "accepted"})
    if not doc:
        return 404, {"error": "Ledger not found"}

    me_is_users0 = doc.get("users", [None])[0] == me
    viewer_sign = 1 if me_is_users0 else -1
    delta_viewer = amount if direction == "they_owe_me" else -amount
    signed = delta_viewer * viewer_sign

    now = datetime.now(tz=timezone.utc)
    entry_doc = {
        "_id": ObjectId(),
        "description": description,
        "amount": amount,
        "delta_users0": signed,
        "created_by": me,
        "created_at": now,
        "due_at": due_at,
    }

    ledgers.update_one(
        {"_id": lid},
        {
            "$push": {"entries": entry_doc},
            "$inc": {"balance": signed},
            "$set": {"updated_at": now},
        },
    )

    sign = _viewer_sign(doc, me)
    new_balance = (float(doc.get("balance", 0) or 0) + signed) * sign
    return 201, {
        "entry": _serialize_entry(entry_doc, sign, me),
        "balance": new_balance,
    }


@app.route("/ledgers/<ledger_id>/entries", methods=["POST"])
@require_auth
def add_ledger_entry(ledger_id: str):
    """Append an IOU entry to an accepted ledger and update its running
    balance. `direction` is interpreted from the caller's POV:
        - "they_owe_me": the other party now owes the caller `amount`.
        - "i_owe_them":  the caller now owes the other party `amount`.
    Kept for back-compat with the old "instant IOU" flow; the live UI now
    uses /ledgers/<id>/entry-requests + acceptance instead."""
    me = g.user_id
    try:
        lid = ObjectId(ledger_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid ledger_id"}), 400

    data = request.get_json(silent=True) or {}
    description = (data.get("description") or "").strip()
    direction = (data.get("direction") or "").strip()
    raw_amount = data.get("amount")

    if not description:
        return jsonify({"error": "Description is required"}), 400
    if len(description) > 120:
        return jsonify({"error": "Description must be 120 chars or fewer"}), 400
    if direction not in ("they_owe_me", "i_owe_them"):
        return jsonify({"error": "direction must be they_owe_me or i_owe_them"}), 400
    try:
        amount = float(raw_amount)
    except (TypeError, ValueError):
        return jsonify({"error": "amount must be a number"}), 400
    if not (amount > 0):
        return jsonify({"error": "amount must be greater than 0"}), 400

    due_in_days, due_err = _parse_due_in_days(data.get("due_in_days"))
    if due_err is not None:
        err_payload, err_code = due_err
        return jsonify(err_payload), err_code
    due_at = (
        datetime.now(tz=timezone.utc) + timedelta(days=due_in_days)
        if due_in_days is not None
        else None
    )

    status, payload = _apply_ledger_entry(
        lid, me, description, amount, direction, due_at=due_at
    )
    return jsonify(payload), status


def _refresh_user_xrpl_cache(user_id: str) -> None:
    """Re-read the on-chain balance for `user_id`'s wallet and update the
    cached `xrpl.balance_xrp` / `xrpl.balance_usd` fields. Best-effort —
    swallows lookup failures so settlement responses are never blocked by a
    flaky testnet."""
    try:
        oid = ObjectId(user_id)
    except (InvalidId, TypeError):
        return
    user_doc = users.find_one({"_id": oid}, {"xrpl.address": 1})
    address = ((user_doc or {}).get("xrpl") or {}).get("address")
    if not address:
        return
    try:
        drops = get_xrp_balance(address)
        xrp = drops_to_xrp(drops)
        users.update_one(
            {"_id": oid},
            {
                "$set": {
                    "xrpl.balance_xrp": xrp,
                    "xrpl.balance_usd": convert_xrp_to_usd(xrp),
                }
            },
        )
    except Exception:
        pass


@app.route("/ledgers/<ledger_id>/settle", methods=["POST"])
@require_auth
def settle_ledger(ledger_id: str):
    """Settle (part of) the caller's debt on `ledger_id` by sending an XRPL
    Payment from the caller's wallet to the other party's wallet, then
    appending a settlement entry that moves the ledger balance toward 0.

    Body: { "amount": float (USD), "method": "xrp" }.
    Bank settlement is intentionally frontend-only for now and rejected here
    with HTTP 400 so the UI never silently treats it as paid.
    """
    me = g.user_id
    try:
        lid = ObjectId(ledger_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid ledger_id"}), 400

    data = request.get_json(silent=True) or {}
    method = (data.get("method") or "").strip().lower()
    raw_amount = data.get("amount")

    if method != "xrp":
        return jsonify({"error": "Only XRP settlement is supported right now"}), 400
    try:
        amount = float(raw_amount)
    except (TypeError, ValueError):
        return jsonify({"error": "amount must be a number"}), 400
    if not (amount > 0):
        return jsonify({"error": "amount must be greater than 0"}), 400

    doc = ledgers.find_one({"_id": lid, "users": me, "status": "accepted"})
    if not doc:
        return jsonify({"error": "Ledger not found"}), 404

    sign = _viewer_sign(doc, me)
    raw_balance = float(doc.get("balance", 0) or 0)
    viewer_balance = raw_balance * sign
    if viewer_balance >= 0:
        return jsonify({"error": "Nothing to settle on this ledger"}), 400
    debt = abs(viewer_balance)
    if amount > debt + 0.01:
        return jsonify({"error": "Amount exceeds your current debt"}), 400

    other_id = next((u for u in doc.get("users", []) if u != me), None)
    if not other_id:
        return jsonify({"error": "Ledger is missing the other party"}), 409

    try:
        sender_doc = users.find_one(
            {"_id": ObjectId(me)}, {"xrpl": 1}
        )
        recipient_doc = users.find_one(
            {"_id": ObjectId(other_id)}, {"xrpl.address": 1}
        )
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid user id on ledger"}), 409

    sender_seed = ((sender_doc or {}).get("xrpl") or {}).get("seed")
    recipient_address = ((recipient_doc or {}).get("xrpl") or {}).get("address")
    if not sender_seed or not recipient_address:
        return jsonify({"error": "Wallet not provisioned for one of the users"}), 409

    drops = usd_to_drops(amount)
    if drops <= 0:
        return jsonify({"error": "Amount is too small to send on XRPL"}), 400

    try:
        tx_result = send_xrp_payment(sender_seed, recipient_address, drops)
    except Exception as exc:
        return jsonify({"error": f"XRPL payment failed: {exc}"}), 502

    me_is_users0 = doc.get("users", [None])[0] == me
    viewer_sign = 1 if me_is_users0 else -1
    signed = amount * viewer_sign

    now = datetime.now(tz=timezone.utc)
    entry_doc = {
        "_id": ObjectId(),
        "description": f"Settled ${amount:.2f} via XRP",
        "amount": amount,
        "delta_users0": signed,
        "created_by": me,
        "created_at": now,
        "method": "xrp",
        "tx_hash": tx_result.get("hash"),
    }

    ledgers.update_one(
        {"_id": lid},
        {
            "$push": {"entries": entry_doc},
            "$inc": {"balance": signed},
            "$set": {"updated_at": now},
        },
    )

    _refresh_user_xrpl_cache(me)
    _refresh_user_xrpl_cache(other_id)
    # Cache fresh accountability scores so /profile reads stay accurate
    # even before either party next browses a list endpoint.
    _compute_accountability_score(me)
    _compute_accountability_score(other_id)

    new_balance = (raw_balance + signed) * sign
    return jsonify(
        {
            "entry": _serialize_entry(entry_doc, sign, me),
            "balance": new_balance,
            "tx_hash": tx_result.get("hash"),
        }
    ), 201


@app.route("/ledgers/<ledger_id>/forgive", methods=["POST"])
@require_auth
def forgive_ledger(ledger_id: str):
    """Voluntarily reduce the credit the caller is owed on `ledger_id`
    without any XRPL transfer. Only valid when the caller is currently in
    the positive (the other party owes them). Body: { "amount": float }."""
    me = g.user_id
    try:
        lid = ObjectId(ledger_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid ledger_id"}), 400

    data = request.get_json(silent=True) or {}
    raw_amount = data.get("amount")
    try:
        amount = float(raw_amount)
    except (TypeError, ValueError):
        return jsonify({"error": "amount must be a number"}), 400
    if not (amount > 0):
        return jsonify({"error": "amount must be greater than 0"}), 400

    doc = ledgers.find_one({"_id": lid, "users": me, "status": "accepted"})
    if not doc:
        return jsonify({"error": "Ledger not found"}), 404

    sign = _viewer_sign(doc, me)
    raw_balance = float(doc.get("balance", 0) or 0)
    viewer_balance = raw_balance * sign
    if viewer_balance <= 0:
        return jsonify({"error": "Nothing to forgive on this ledger"}), 400
    credit = viewer_balance
    if amount > credit + 0.01:
        return jsonify({"error": "Amount exceeds what they owe you"}), 400

    me_is_users0 = doc.get("users", [None])[0] == me
    viewer_sign = 1 if me_is_users0 else -1
    signed = -amount * viewer_sign

    now = datetime.now(tz=timezone.utc)
    entry_doc = {
        "_id": ObjectId(),
        "description": f"Forgave ${amount:.2f} (let 'em slide)",
        "amount": amount,
        "delta_users0": signed,
        "created_by": me,
        "created_at": now,
        "method": "forgive",
    }

    ledgers.update_one(
        {"_id": lid},
        {
            "$push": {"entries": entry_doc},
            "$inc": {"balance": signed},
            "$set": {"updated_at": now},
        },
    )

    new_balance = (raw_balance + signed) * sign
    return jsonify(
        {
            "entry": _serialize_entry(entry_doc, sign, me),
            "balance": new_balance,
        }
    ), 201


RECEIPT_PROMPT = (
    "You are a receipt parser. Look at this receipt image and extract exactly "
    "two fields:\n"
    "  - store: the merchant / brand name as a customer would say it "
    "(e.g. \"Chipotle\", \"Crumbl Cookies\", \"Culver's\"). Title-case, no "
    "address, no store number.\n"
    "  - total: the FINAL amount the customer paid in dollars, as a number. "
    "If a tip line is filled in, use the post-tip grand total. Otherwise use "
    "the post-tax total. Never return the subtotal.\n"
    "If you cannot read the receipt confidently, return store as an empty "
    "string and total as 0."
)

RECEIPT_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "store": {"type": "string"},
        "total": {"type": "number"},
    },
    "required": ["store", "total"],
}


@app.route("/scan-receipt", methods=["POST"])
@require_auth
def scan_receipt():
    """Forward a receipt image to Gemini and return `{store, total}`. Keeps
    the API key server-side; the client only ever sees the parsed fields."""
    if not GEMINI_API_KEY:
        return jsonify({"error": "Receipt scanning is not configured"}), 503

    data = request.get_json(silent=True) or {}
    image_b64 = (data.get("image_base64") or "").strip()
    mime_type = (data.get("mime_type") or "image/jpeg").strip() or "image/jpeg"
    if not image_b64:
        return jsonify({"error": "image_base64 is required"}), 400

    # Strip a "data:image/...;base64," prefix if the client included one, then
    # validate by attempting to decode. We re-encode the raw bytes so Gemini
    # always gets clean base64.
    if image_b64.startswith("data:"):
        _, _, image_b64 = image_b64.partition(",")
    try:
        raw_bytes = base64.b64decode(image_b64, validate=True)
    except Exception:
        return jsonify({"error": "image_base64 is not valid base64"}), 400
    if not raw_bytes:
        return jsonify({"error": "image_base64 decoded to empty bytes"}), 400
    clean_b64 = base64.b64encode(raw_bytes).decode("ascii")

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": clean_b64,
                        }
                    },
                    {"text": RECEIPT_PROMPT},
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json",
            "responseSchema": RECEIPT_RESPONSE_SCHEMA,
            "temperature": 0,
        },
    }

    try:
        resp = requests.post(
            GEMINI_ENDPOINT,
            params={"key": GEMINI_API_KEY},
            json=payload,
            timeout=30,
        )
    except requests.RequestException as exc:
        return jsonify({"error": f"Gemini request failed: {exc}"}), 502

    if resp.status_code >= 300:
        # Surface Gemini's error message for easier debugging without leaking
        # the full request payload back to the client.
        try:
            err = resp.json().get("error", {}).get("message") or resp.text
        except ValueError:
            err = resp.text
        return jsonify({"error": f"Gemini error: {err}"}), 502

    try:
        body = resp.json()
        text = (
            body["candidates"][0]["content"]["parts"][0]["text"]
        )
        parsed = json.loads(text)
    except (KeyError, IndexError, ValueError, TypeError):
        return jsonify({"error": "Could not parse Gemini response"}), 422

    store = parsed.get("store")
    total = parsed.get("total")
    if not isinstance(store, str) or not isinstance(total, (int, float)):
        return jsonify({"error": "Gemini returned an unexpected shape"}), 422

    return jsonify({"store": store.strip(), "total": float(total)})


def _pair_net_in_group(entries: list, viewer_id: str, other_id: str) -> float:
    """Fold a group's entries into the signed net between `viewer_id` and
    `other_id` from the viewer's POV: positive => `other_id` owes `viewer_id`.
    Entries between any other pair, or with method `forgive` from the wrong
    side, are left to the caller to interpret consistently — here we just
    treat each entry as `from_user_id` (debtor) owes `to_user_id` (creditor)
    `amount`."""
    net = 0.0
    for e in entries:
        frm = e.get("from_user_id")
        to = e.get("to_user_id")
        amt = float(e.get("amount", 0) or 0)
        if frm == other_id and to == viewer_id:
            net += amt
        elif frm == viewer_id and to == other_id:
            net -= amt
    return net


def _serialize_group_member(user_doc: dict) -> dict:
    prof = user_doc.get("profile") or {}
    return {
        "id": str(user_doc["_id"]),
        "full_name": prof.get("full_name"),
        "username": prof.get("username"),
        **_avatar_fields(prof),
    }


# Tunables for the accountability score. `LATE_PENALTY_PER_DAY` is the
# straight per-day penalty applied to historical late settles weighted by
# dollar size. `OVERDUE_PENALTY_DIVISOR` softens the currently-overdue
# component via sqrt so a single large overdue debt doesn't immediately
# zero a user out.
LATE_PENALTY_PER_DAY = 4
OVERDUE_PENALTY_DIVISOR = 10
_EPOCH_NAIVE = datetime.min.replace(tzinfo=timezone.utc)


def _aware(dt):
    """Treat naive datetimes from older Mongo docs as UTC so subtraction
    against `datetime.now(tz=utc)` doesn't blow up."""
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def _compute_accountability_score(user_id: str) -> int:
    """Live-compute the 0-100 accountability score for `user_id` by walking
    every accepted ledger and group they belong to. Builds per-counterparty
    FIFO debt queues, matches payments against them to gather a dollar-
    weighted average days-late, and adds a softened penalty for any debt
    currently past its `due_at`. Caches the result back onto the user doc
    opportunistically so /profile reads stay cheap."""
    debts_by_other: dict = {}
    matched_late_dollar_days = 0.0
    matched_dollars = 0.0

    def consume(other_id, pay_amount, settled_at, weight_late=True):
        nonlocal matched_late_dollar_days, matched_dollars
        queue = debts_by_other.get(other_id, [])
        remaining = pay_amount
        settled_at = _aware(settled_at)
        while remaining > 1e-9 and queue:
            head = queue[0]
            chunk = min(head["amount"], remaining)
            if weight_late:
                due_at = _aware(head.get("due_at"))
                if due_at is not None and settled_at is not None:
                    delta = (settled_at - due_at).total_seconds() / 86400.0
                    days_late = max(0.0, delta)
                else:
                    days_late = 0.0
                matched_late_dollar_days += days_late * chunk
                matched_dollars += chunk
            head["amount"] -= chunk
            remaining -= chunk
            if head["amount"] <= 1e-9:
                queue.pop(0)
        debts_by_other[other_id] = queue

    for ldoc in ledgers.find(
        {"users": user_id, "status": "accepted"},
        {"users": 1, "entries": 1},
    ):
        pair = ldoc.get("users") or []
        if user_id not in pair:
            continue
        other = next((u for u in pair if u != user_id), None)
        if not other:
            continue
        viewer_sign = 1 if pair[0] == user_id else -1
        for e in sorted(
            ldoc.get("entries") or [],
            key=lambda x: _aware(x.get("created_at")) or _EPOCH_NAIVE,
        ):
            method = e.get("method") or "iou"
            amount = float(e.get("amount", 0) or 0)
            delta = float(e.get("delta_users0", 0) or 0)
            signed_for_user = delta * viewer_sign
            created_at = e.get("created_at")

            if method == "xrp":
                if e.get("created_by") == user_id and signed_for_user > 0:
                    consume(other, amount, created_at, weight_late=True)
            elif method == "forgive":
                # Forgiveness reduces the debtor's debt without rewarding
                # or punishing on-time stats — it simply wipes from the
                # FIFO queue.
                if signed_for_user > 0:
                    consume(other, amount, created_at, weight_late=False)
            else:
                if signed_for_user < 0:
                    debts_by_other.setdefault(other, []).append(
                        {"amount": amount, "due_at": e.get("due_at")}
                    )

    for gdoc in groups.find(
        {"members": user_id},
        {"entries": 1},
    ):
        for e in sorted(
            gdoc.get("entries") or [],
            key=lambda x: _aware(x.get("created_at")) or _EPOCH_NAIVE,
        ):
            method = e.get("method") or "iou"
            amount = float(e.get("amount", 0) or 0)
            frm = e.get("from_user_id")
            to = e.get("to_user_id")
            created_at = e.get("created_at")

            if method == "xrp":
                # In settle_group, from_user_id is the recipient (creditor)
                # and to_user_id is the payer (debtor). The payer is the
                # one whose score we tally a settle against.
                if e.get("created_by") == user_id:
                    other = frm if frm != user_id else to
                    if other:
                        consume(other, amount, created_at, weight_late=True)
            else:
                if frm == user_id and to:
                    debts_by_other.setdefault(to, []).append(
                        {"amount": amount, "due_at": e.get("due_at")}
                    )

    avg_days_late = (
        matched_late_dollar_days / matched_dollars
        if matched_dollars > 1e-9
        else 0.0
    )

    now = datetime.now(tz=timezone.utc)
    overdue_dollar_days = 0.0
    for queue in debts_by_other.values():
        for d in queue:
            due_at = _aware(d.get("due_at"))
            if due_at is None:
                continue
            delta_days = (now - due_at).total_seconds() / 86400.0
            if delta_days > 0:
                overdue_dollar_days += delta_days * d["amount"]

    raw = (
        100.0
        - LATE_PENALTY_PER_DAY * avg_days_late
        - math.sqrt(max(0.0, overdue_dollar_days) / OVERDUE_PENALTY_DIVISOR)
    )
    score = int(max(0, min(100, round(raw))))

    # Opportunistic cache write so /profile (which reads the stored field
    # directly) stays accurate without a per-request recompute.
    try:
        users.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": {"accountability_score": score}},
        )
    except (InvalidId, TypeError):
        pass

    return score


def _load_member_profiles(member_ids: list) -> dict:
    """Bulk-fetch the public profile fields for a set of user_id strings.
    Returns `{user_id_str: {full_name, username, accountability_score}}`.
    Score is recomputed live per id so every list endpoint that funnels
    through here automatically gets fresh values."""
    oids = []
    for sid in member_ids:
        try:
            oids.append(ObjectId(sid))
        except (InvalidId, TypeError):
            continue
    out = {}
    if not oids:
        return out
    for u in users.find(
        {"_id": {"$in": oids}},
        {**_PUBLIC_PROFILE_PROJECTION, "accountability_score": 1},
    ):
        uid = str(u["_id"])
        prof = u.get("profile") or {}
        score = _compute_accountability_score(uid)
        out[uid] = {
            "id": uid,
            "full_name": prof.get("full_name"),
            "username": prof.get("username"),
            **_avatar_fields(prof),
            "accountability_score": score,
        }
    return out


@app.route("/groups", methods=["POST"])
@require_auth
def create_group():
    """Create a new group. Body: `{name, member_user_ids: [..]}`. The caller
    is always added to the member set. Requires at least one other member so
    a group is never just yourself."""
    me = g.user_id
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()
    raw_members = data.get("member_user_ids") or []

    if not name:
        return jsonify({"error": "name is required"}), 400
    if len(name) > 80:
        return jsonify({"error": "name must be 80 chars or fewer"}), 400
    if not isinstance(raw_members, list):
        return jsonify({"error": "member_user_ids must be a list"}), 400

    member_set = {me}
    for mid in raw_members:
        if not isinstance(mid, str) or not mid.strip():
            continue
        member_set.add(mid.strip())
    if len(member_set) < 2:
        return jsonify({"error": "Pick at least one other member"}), 400

    member_oids = []
    for mid in member_set:
        try:
            member_oids.append(ObjectId(mid))
        except (InvalidId, TypeError):
            return jsonify({"error": f"Invalid user id: {mid}"}), 400

    found = users.count_documents({"_id": {"$in": member_oids}})
    if found != len(member_oids):
        return jsonify({"error": "One or more members not found"}), 404

    now = datetime.now(tz=timezone.utc)
    members_sorted = sorted(member_set)
    result = groups.insert_one(
        {
            "name": name,
            "members": members_sorted,
            "created_by": me,
            "created_at": now,
            "updated_at": now,
            "entries": [],
        }
    )
    return jsonify(
        {
            "group_id": str(result.inserted_id),
            "name": name,
            "members": members_sorted,
        }
    ), 201


@app.route("/groups", methods=["GET"])
@require_auth
def list_groups():
    """Return every group the current user belongs to, with denormalized
    member profiles and the viewer's net balance (positive => others owe
    the viewer, negative => viewer owes others)."""
    me = g.user_id
    docs = list(groups.find({"members": me}).sort("updated_at", -1))

    all_member_ids = set()
    for d in docs:
        for sid in d.get("members", []):
            all_member_ids.add(sid)
    profile_by_id = _load_member_profiles(list(all_member_ids))

    out = []
    for d in docs:
        members = d.get("members", []) or []
        entries = d.get("entries", []) or []
        net = 0.0
        for other in members:
            if other == me:
                continue
            net += _pair_net_in_group(entries, me, other)
        out.append(
            {
                "group_id": str(d["_id"]),
                "name": d.get("name"),
                "members": [
                    profile_by_id.get(
                        m, {"id": m, "full_name": None, "username": None}
                    )
                    for m in members
                ],
                "member_count": len(members),
                "balance": float(net),
            }
        )
    return jsonify(out)


@app.route("/groups/<group_id>", methods=["GET"])
@require_auth
def get_group(group_id: str):
    """Return one group's full state from the viewer's POV: members with
    their pair-net to the viewer, plus a chronological history of entries
    with `from_user`/`to_user` resolved."""
    me = g.user_id
    try:
        gid = ObjectId(group_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid group_id"}), 400

    doc = groups.find_one({"_id": gid, "members": me})
    if not doc:
        return jsonify({"error": "Group not found"}), 404

    members = doc.get("members", []) or []
    entries = doc.get("entries", []) or []
    profile_by_id = _load_member_profiles(members)

    members_view = []
    net_total = 0.0
    for sid in members:
        prof = profile_by_id.get(
            sid, {"id": sid, "full_name": None, "username": None}
        )
        if sid == me:
            members_view.append({**prof, "is_self": True, "net": 0.0})
            continue
        pair_net = _pair_net_in_group(entries, me, sid)
        net_total += pair_net
        members_view.append({**prof, "is_self": False, "net": float(pair_net)})

    history = []
    for e in entries:
        frm = e.get("from_user_id")
        to = e.get("to_user_id")
        history.append(
            {
                "id": str(e["_id"]) if e.get("_id") is not None else None,
                "from_user": profile_by_id.get(
                    frm, {"id": frm, "full_name": None, "username": None}
                ),
                "to_user": profile_by_id.get(
                    to, {"id": to, "full_name": None, "username": None}
                ),
                "description": e.get("description"),
                "amount": float(e.get("amount", 0) or 0),
                "method": e.get("method") or "iou",
                "tx_hash": e.get("tx_hash"),
                "created_at": e["created_at"].isoformat()
                if e.get("created_at")
                else None,
                "due_at": e["due_at"].isoformat() if e.get("due_at") else None,
                "created_by": e.get("created_by"),
                "mine": e.get("created_by") == me,
            }
        )
    history.reverse()

    return jsonify(
        {
            "group_id": str(doc["_id"]),
            "name": doc.get("name"),
            "created_by": doc.get("created_by"),
            "members": members_view,
            "balance": float(net_total),
            "history": history,
        }
    )


def _apply_group_entry(
    gid: ObjectId,
    me: str,
    to_user_id: str,
    description: str,
    amount: float,
    direction: str,
    due_at=None,
):
    """Append a validated IOU entry to a group and bump `updated_at`.
    Returns `(status_code, payload)`. `to_user_id` is always the *other*
    member; `direction` (caller's POV) decides who ends up as the debtor on
    the appended entry. `due_at` is the optional deadline persisted on the
    entry so the accountability score can use it later."""
    doc = groups.find_one({"_id": gid, "members": me})
    if not doc:
        return 404, {"error": "Group not found"}
    if to_user_id not in (doc.get("members") or []):
        return 400, {"error": "to_user_id is not a member of this group"}

    if direction == "they_owe_me":
        from_id, creditor_id = to_user_id, me
    else:
        from_id, creditor_id = me, to_user_id

    now = datetime.now(tz=timezone.utc)
    entry_doc = {
        "_id": ObjectId(),
        "from_user_id": from_id,
        "to_user_id": creditor_id,
        "description": description,
        "amount": amount,
        "method": "iou",
        "created_by": me,
        "created_at": now,
        "due_at": due_at,
    }
    groups.update_one(
        {"_id": gid},
        {
            "$push": {"entries": entry_doc},
            "$set": {"updated_at": now},
        },
    )

    return 201, {
        "entry_id": str(entry_doc["_id"]),
        "amount": amount,
        "from_user_id": from_id,
        "to_user_id": creditor_id,
        "direction": direction,
    }


@app.route("/groups/<group_id>/entries", methods=["POST"])
@require_auth
def add_group_entry(group_id: str):
    """Append an IOU entry to a group between caller and `to_user_id`.
    Kept for back-compat; the live UI now goes through
    /groups/<id>/entry-requests + acceptance."""
    me = g.user_id
    try:
        gid = ObjectId(group_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid group_id"}), 400

    data = request.get_json(silent=True) or {}
    to_user_id = (data.get("to_user_id") or "").strip()
    description = (data.get("description") or "").strip()
    raw_amount = data.get("amount")
    direction = (data.get("direction") or "i_owe_them").strip()

    if direction not in ("i_owe_them", "they_owe_me"):
        return jsonify(
            {"error": "direction must be i_owe_them or they_owe_me"}
        ), 400
    if not to_user_id:
        return jsonify({"error": "to_user_id is required"}), 400
    if to_user_id == me:
        return jsonify({"error": "You can't owe yourself"}), 400
    if not description:
        return jsonify({"error": "Description is required"}), 400
    if len(description) > 120:
        return jsonify({"error": "Description must be 120 chars or fewer"}), 400
    try:
        amount = float(raw_amount)
    except (TypeError, ValueError):
        return jsonify({"error": "amount must be a number"}), 400
    if not (amount > 0):
        return jsonify({"error": "amount must be greater than 0"}), 400

    due_in_days, due_err = _parse_due_in_days(data.get("due_in_days"))
    if due_err is not None:
        err_payload, err_code = due_err
        return jsonify(err_payload), err_code
    due_at = (
        datetime.now(tz=timezone.utc) + timedelta(days=due_in_days)
        if due_in_days is not None
        else None
    )

    status, payload = _apply_group_entry(
        gid, me, to_user_id, description, amount, direction, due_at=due_at
    )
    return jsonify(payload), status


@app.route("/groups/<group_id>/settle", methods=["POST"])
@require_auth
def settle_group(group_id: str):
    """Settle (part of) what the caller owes `to_user_id` inside this group
    by sending an XRPL Payment from caller -> recipient and appending a
    settlement entry. Mirrors `/ledgers/<id>/settle` but scoped to the
    pair-net within this group."""
    me = g.user_id
    try:
        gid = ObjectId(group_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid group_id"}), 400

    data = request.get_json(silent=True) or {}
    to_user_id = (data.get("to_user_id") or "").strip()
    raw_amount = data.get("amount")
    method = (data.get("method") or "xrp").strip().lower()

    if method != "xrp":
        return jsonify({"error": "Only XRP settlement is supported right now"}), 400
    if not to_user_id:
        return jsonify({"error": "to_user_id is required"}), 400
    if to_user_id == me:
        return jsonify({"error": "Pick a different group member"}), 400
    try:
        amount = float(raw_amount)
    except (TypeError, ValueError):
        return jsonify({"error": "amount must be a number"}), 400
    if not (amount > 0):
        return jsonify({"error": "amount must be greater than 0"}), 400

    doc = groups.find_one({"_id": gid, "members": me})
    if not doc:
        return jsonify({"error": "Group not found"}), 404
    if to_user_id not in (doc.get("members") or []):
        return jsonify({"error": "to_user_id is not a member of this group"}), 400

    pair_net = _pair_net_in_group(doc.get("entries") or [], me, to_user_id)
    # pair_net > 0 => other owes me (nothing to settle from my side).
    # pair_net < 0 => I owe other |pair_net|.
    if pair_net >= 0:
        return jsonify({"error": "Nothing to settle with this member"}), 400
    debt = abs(pair_net)
    if amount > debt + 0.01:
        return jsonify({"error": "Amount exceeds your current debt"}), 400

    try:
        sender_doc = users.find_one({"_id": ObjectId(me)}, {"xrpl": 1})
        recipient_doc = users.find_one(
            {"_id": ObjectId(to_user_id)}, {"xrpl.address": 1}
        )
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid user id on group"}), 409

    sender_seed = ((sender_doc or {}).get("xrpl") or {}).get("seed")
    recipient_address = ((recipient_doc or {}).get("xrpl") or {}).get("address")
    if not sender_seed or not recipient_address:
        return jsonify({"error": "Wallet not provisioned for one of the users"}), 409

    drops = usd_to_drops(amount)
    if drops <= 0:
        return jsonify({"error": "Amount is too small to send on XRPL"}), 400

    try:
        tx_result = send_xrp_payment(sender_seed, recipient_address, drops)
    except Exception as exc:
        return jsonify({"error": f"XRPL payment failed: {exc}"}), 502

    now = datetime.now(tz=timezone.utc)
    # A settlement reduces what the caller owes the recipient. Modeled as
    # the *recipient* "owing" the caller `amount` so the pair-net moves
    # toward 0.
    entry_doc = {
        "_id": ObjectId(),
        "from_user_id": to_user_id,
        "to_user_id": me,
        "description": f"Settled ${amount:.2f} via XRP",
        "amount": amount,
        "method": "xrp",
        "tx_hash": tx_result.get("hash"),
        "created_by": me,
        "created_at": now,
    }
    groups.update_one(
        {"_id": gid},
        {
            "$push": {"entries": entry_doc},
            "$set": {"updated_at": now},
        },
    )

    _refresh_user_xrpl_cache(me)
    _refresh_user_xrpl_cache(to_user_id)
    _compute_accountability_score(me)
    _compute_accountability_score(to_user_id)

    new_pair_net = pair_net + amount
    return jsonify(
        {
            "entry_id": str(entry_doc["_id"]),
            "amount": amount,
            "tx_hash": tx_result.get("hash"),
            "pair_balance": float(new_pair_net),
        }
    ), 201


def _validate_entry_payload(data: dict):
    """Shared validation for entry-request creation. Returns
    `(description, amount, direction, error)` where `error` is `(payload, code)`
    or None on success."""
    description = (data.get("description") or "").strip()
    direction = (data.get("direction") or "").strip()
    raw_amount = data.get("amount")

    if not description:
        return None, None, None, ({"error": "Description is required"}, 400)
    if len(description) > 120:
        return None, None, None, (
            {"error": "Description must be 120 chars or fewer"},
            400,
        )
    if direction not in ("they_owe_me", "i_owe_them"):
        return None, None, None, (
            {"error": "direction must be they_owe_me or i_owe_them"},
            400,
        )
    try:
        amount = float(raw_amount)
    except (TypeError, ValueError):
        return None, None, None, ({"error": "amount must be a number"}, 400)
    if not (amount > 0):
        return None, None, None, (
            {"error": "amount must be greater than 0"},
            400,
        )
    return description, amount, direction, None


@app.route("/ledgers/<ledger_id>/entry-requests", methods=["POST"])
@require_auth
def create_ledger_entry_request(ledger_id: str):
    """Create a pending IOU request on an accepted ledger. The recipient
    (the *other* member of the ledger) must accept before the entry is
    actually appended to the ledger. Body: `{description, amount, direction}`
    where direction is interpreted from the caller's POV."""
    me = g.user_id
    try:
        lid = ObjectId(ledger_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid ledger_id"}), 400

    data = request.get_json(silent=True) or {}
    description, amount, direction, err = _validate_entry_payload(data)
    if err is not None:
        payload, code = err
        return jsonify(payload), code
    due_in_days, due_err = _parse_due_in_days(data.get("due_in_days"))
    if due_err is not None:
        err_payload, err_code = due_err
        return jsonify(err_payload), err_code

    doc = ledgers.find_one({"_id": lid, "users": me, "status": "accepted"})
    if not doc:
        return jsonify({"error": "Ledger not found"}), 404
    other = next((u for u in doc.get("users", []) if u != me), None)
    if other is None:
        return jsonify({"error": "Ledger has no other member"}), 400

    now = datetime.now(tz=timezone.utc)
    due_at = (
        now + timedelta(days=due_in_days) if due_in_days is not None else None
    )
    req_doc = {
        "_id": ObjectId(),
        "scope": "ledger",
        "ledger_id": lid,
        "from_user_id": me,
        "to_user_id": other,
        "direction": direction,
        "description": description,
        "amount": amount,
        "due_in_days": due_in_days,
        "due_at": due_at,
        "created_at": now,
    }
    entry_requests.insert_one(req_doc)

    return jsonify(
        {
            "id": str(req_doc["_id"]),
            "scope": "ledger",
            "ledger_id": ledger_id,
            "from_user_id": me,
            "to_user_id": other,
            "direction": direction,
            "amount": amount,
            "description": description,
            "due_in_days": due_in_days,
            "due_at": due_at.isoformat() if due_at else None,
            "status": "pending",
        }
    ), 201


@app.route("/groups/<group_id>/entry-requests", methods=["POST"])
@require_auth
def create_group_entry_request(group_id: str):
    """Create a pending IOU request inside a group between caller and
    `to_user_id`. The recipient must accept before the entry hits the
    group's `entries` array."""
    me = g.user_id
    try:
        gid = ObjectId(group_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid group_id"}), 400

    data = request.get_json(silent=True) or {}
    to_user_id = (data.get("to_user_id") or "").strip()
    description, amount, direction, err = _validate_entry_payload(data)
    if err is not None:
        payload, code = err
        return jsonify(payload), code
    due_in_days, due_err = _parse_due_in_days(data.get("due_in_days"))
    if due_err is not None:
        err_payload, err_code = due_err
        return jsonify(err_payload), err_code
    if not to_user_id:
        return jsonify({"error": "to_user_id is required"}), 400
    if to_user_id == me:
        return jsonify({"error": "You can't owe yourself"}), 400

    doc = groups.find_one({"_id": gid, "members": me})
    if not doc:
        return jsonify({"error": "Group not found"}), 404
    if to_user_id not in (doc.get("members") or []):
        return jsonify(
            {"error": "to_user_id is not a member of this group"}
        ), 400

    now = datetime.now(tz=timezone.utc)
    due_at = (
        now + timedelta(days=due_in_days) if due_in_days is not None else None
    )
    req_doc = {
        "_id": ObjectId(),
        "scope": "group",
        "group_id": gid,
        "from_user_id": me,
        "to_user_id": to_user_id,
        "direction": direction,
        "description": description,
        "amount": amount,
        "due_in_days": due_in_days,
        "due_at": due_at,
        "created_at": now,
    }
    entry_requests.insert_one(req_doc)

    return jsonify(
        {
            "id": str(req_doc["_id"]),
            "scope": "group",
            "group_id": group_id,
            "from_user_id": me,
            "to_user_id": to_user_id,
            "direction": direction,
            "amount": amount,
            "description": description,
            "due_in_days": due_in_days,
            "due_at": due_at.isoformat() if due_at else None,
            "status": "pending",
        }
    ), 201


def _serialize_entry_request(
    req: dict,
    profile_by_id: dict,
    group_name_by_id: dict,
    counterpart_key: str,
) -> dict:
    """Project an entry_requests doc into the JSON shape the client expects.
    `counterpart_key` is "to_user" for sent listings, "from_user" for
    incoming listings — the *other* side of the request relative to viewer."""
    other_id = (
        req.get("to_user_id")
        if counterpart_key == "to_user"
        else req.get("from_user_id")
    )
    prof = profile_by_id.get(
        other_id, {"id": other_id, "full_name": None, "username": None}
    )
    out = {
        "id": str(req["_id"]),
        "scope": req.get("scope"),
        counterpart_key: prof,
        "direction": req.get("direction"),
        "description": req.get("description"),
        "amount": float(req.get("amount", 0) or 0),
        "from_user_id": req.get("from_user_id"),
        "to_user_id": req.get("to_user_id"),
        "due_in_days": req.get("due_in_days"),
        "due_at": req["due_at"].isoformat() if req.get("due_at") else None,
        "created_at": req["created_at"].isoformat()
        if req.get("created_at")
        else None,
    }
    if req.get("scope") == "ledger" and req.get("ledger_id") is not None:
        out["ledger_id"] = str(req["ledger_id"])
    if req.get("scope") == "group" and req.get("group_id") is not None:
        gid_str = str(req["group_id"])
        out["group_id"] = gid_str
        out["group_name"] = group_name_by_id.get(gid_str)
    return out


def _list_entry_requests(viewer_field: str, counterpart_key: str):
    """Shared list handler for /entry-requests/incoming and /sent.
    `viewer_field` selects whether the viewer is the recipient
    (`to_user_id`) or the sender (`from_user_id`)."""
    me = g.user_id
    docs = list(
        entry_requests.find({viewer_field: me}).sort("created_at", -1)
    )
    counterpart_field = (
        "from_user_id" if viewer_field == "to_user_id" else "to_user_id"
    )

    other_ids = {d.get(counterpart_field) for d in docs if d.get(counterpart_field)}
    profile_by_id = _load_member_profiles(list(other_ids))

    group_oids = []
    for d in docs:
        if d.get("scope") == "group" and d.get("group_id") is not None:
            group_oids.append(d["group_id"])
    group_name_by_id = {}
    if group_oids:
        for grp in groups.find(
            {"_id": {"$in": group_oids}}, {"name": 1}
        ):
            group_name_by_id[str(grp["_id"])] = grp.get("name")

    out = [
        _serialize_entry_request(
            d, profile_by_id, group_name_by_id, counterpart_key
        )
        for d in docs
    ]
    return jsonify(out)


@app.route("/entry-requests/incoming", methods=["GET"])
@require_auth
def list_entry_requests_incoming():
    """Pending IOU requests where the caller is the recipient (must
    accept/reject)."""
    return _list_entry_requests("to_user_id", "from_user")


@app.route("/entry-requests/sent", methods=["GET"])
@require_auth
def list_entry_requests_sent():
    """Pending IOU requests the caller has sent and is waiting on the
    recipient to accept."""
    return _list_entry_requests("from_user_id", "to_user")


@app.route("/entry-requests/<request_id>/accept", methods=["POST"])
@require_auth
def accept_entry_request(request_id: str):
    """Recipient accepts a pending IOU request. Applies the entry to the
    underlying ledger or group from the *sender's* POV (so the canonical
    direction stored on the request is honored), then removes the request."""
    me = g.user_id
    try:
        rid = ObjectId(request_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid request id"}), 400

    req = entry_requests.find_one({"_id": rid})
    if not req:
        return jsonify({"error": "Request not found"}), 404
    if req.get("to_user_id") != me:
        return jsonify({"error": "Only the recipient can accept this request"}), 403

    sender = req.get("from_user_id")
    description = req.get("description") or ""
    amount = float(req.get("amount", 0) or 0)
    direction = req.get("direction") or "i_owe_them"
    scope = req.get("scope")
    due_at = req.get("due_at")

    if scope == "ledger":
        lid = req.get("ledger_id")
        if not isinstance(lid, ObjectId):
            return jsonify({"error": "Invalid ledger reference on request"}), 400
        status, payload = _apply_ledger_entry(
            lid, sender, description, amount, direction, due_at=due_at
        )
    elif scope == "group":
        gid = req.get("group_id")
        if not isinstance(gid, ObjectId):
            return jsonify({"error": "Invalid group reference on request"}), 400
        # In a group request, `to_user_id` is always the recipient (me).
        # When applying from the sender's POV, the "other" member is me.
        status, payload = _apply_group_entry(
            gid, sender, me, description, amount, direction, due_at=due_at
        )
    else:
        return jsonify({"error": "Unknown request scope"}), 400

    if status >= 400:
        return jsonify(payload), status

    entry_requests.delete_one({"_id": rid})
    return jsonify(
        {
            "accepted": True,
            "request_id": request_id,
            "scope": scope,
            "applied": payload,
        }
    ), 200


@app.route("/entry-requests/<request_id>/reject", methods=["POST"])
@require_auth
def reject_entry_request(request_id: str):
    """Either party can dismiss a pending IOU request — the recipient
    rejects, the sender cancels. Both flows just delete the request."""
    me = g.user_id
    try:
        rid = ObjectId(request_id)
    except (InvalidId, TypeError):
        return jsonify({"error": "Invalid request id"}), 400

    result = entry_requests.delete_one(
        {
            "_id": rid,
            "$or": [{"to_user_id": me}, {"from_user_id": me}],
        }
    )
    if result.deleted_count == 0:
        return jsonify({"error": "Request not found"}), 404
    return jsonify({"rejected": True, "request_id": request_id})


if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)