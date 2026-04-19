<div align="center">
  <img src="frontend/assets/raven.webp" alt="Ledger Shredder" width="120"/>

# Ledger Shredder

**Settle up. On-chain. Atomically.**

A Splitwise-style IOU tracker that settles real money on the **XRP Ledger** — with batched multi-recipient payouts, a one-tap Auto-Settle, AI receipt scanning, and commemorative NFT "Memories" minted when you forgive a friend's debt.

Built at **HackKU 2026**.

</div>

---

## Table of Contents

- [What it does](#what-it-does)
- [Highlights](#highlights)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Repository Layout](#repository-layout)
- [Quickstart](#quickstart)
- [Environment Variables](#environment-variables)
- [API Reference](#api-reference)
- [XRPL Deep Dive](#xrpl-deep-dive)
- [Deployment](#deployment)

---

## What it does

You and your friends spend money on each other constantly — splitting Ubers, lunches, group rentals. Ledger Shredder keeps the running tab and, when it's time to pay up, *actually moves the money* over the XRP Ledger Testnet instead of pasting Venmo links into a group chat.

| | |
|--|--|
| **Track** | Per-friend ledgers and group ledgers (think: Splitwise). |
| **Scan** | Snap a receipt → Gemini extracts the merchant + total. |
| **Settle** | One tap sends an XRPL Payment from your wallet to theirs. |
| **Batch** | Settle every debt you owe in **one atomic XRPL Batch transaction** — all-or-nothing. |
| **Auto-Settle** | Opt in to automatically pay off debts as they appear, all at once. |
| **Forgive** | "Let 'em slide" + optionally **mint them an NFT memory** on the XRPL as a keepsake, with a personal message embedded on-chain. |
| **Score** | An accountability score that rewards on-time settlements and decays for late ones. |

## Highlights

### XRPL Batch Transactions (atomic multi-pay)
When you tap **Auto-Settle ALL**, every debt is bundled into a single `Batch` transaction with the `tfAllOrNothing` flag. Either every payment lands on-ledger or none of them do — no more "I paid 4 of 5 friends and the 5th bounced." Up to 8 payments per batch (XRPL spec cap), with automatic chunking beyond that.

### Memory NFTs (forgiveness on-chain)
Forgiving a debt optionally mints a transferable XRPL NFT directly into the recipient's wallet. The NFT URI carries a compact JSON payload with the amount, both usernames, timestamp, and your message — all 256 bytes max, the rest stored off-chain. Implements the standard 3-step *mint → offer → accept* pattern server-side so users never see XRPL plumbing.

### AI Receipt Scanning
The "Add IOU" sheet has a camera shortcut that base64-uploads the photo to a backend endpoint, which calls Google Gemini with a structured-output schema and returns `{store, total}`. The user just confirms.

### Friend requests & group ledgers
Adding a friend is a two-way handshake (request → accept), so unsolicited people can't spam you with debts. Groups support per-member balances on a single shared ledger.

---

## Tech Stack

### Frontend — `frontend/`
- **[Flutter](https://flutter.dev/) 3.9+** (Dart) — single codebase shipping iOS, Android, web, macOS, Linux.
- **`http`** for REST calls, **`shared_preferences`** for local JWT + Auto-Settle config persistence.
- **`image_picker`** for receipts and avatars (resized + base64 client-side).
- **`device_preview`** (dev-only) for SwiftUI-style framed previews while iterating on UI.

### Backend — `backend/`
- **[Flask](https://flask.palletsprojects.com/) 3** + **Gunicorn** + **flask-cors**.
- **MongoDB Atlas** via **PyMongo** — collections: `users`, `ledgers`, `groups`, `entry_requests`, `memories`.
- **[xrpl-py](https://xrpl.org/) 4.5** — Testnet wallet provisioning, `Payment`, `Batch`, `NFTokenMint`/`CreateOffer`/`AcceptOffer`.
- **PyJWT** + **bcrypt** for auth.
- **[Google Gemini API](https://ai.google.dev/)** for receipt OCR, called via `requests` (server-side; key never leaves the backend).

### Infra
- **[Fly.io](https://fly.io/)** — backend hosted at `https://hackku-backend.fly.dev`. Dockerized via `backend/Dockerfile`, configured by `backend/fly.toml`.
- **MongoDB Atlas** — managed Mongo cluster.
- **XRPL Testnet** — public faucet wallets for the demo (seeds stored server-side in Mongo, **never** echoed to clients).

---

## Architecture

```
┌──────────────────────┐      HTTPS / JSON       ┌──────────────────────┐
│  Flutter app         │ ──────────────────────► │  Flask API           │
│  (iOS / Android /    │ ◄────────────────────── │  on Fly.io           │
│   web / desktop)     │       JWT bearer        │                      │
└──────────────────────┘                         └──────────┬───────────┘
                                                            │
                                            ┌───────────────┼─────────────────┐
                                            │               │                 │
                                       ┌────▼─────┐    ┌────▼────┐      ┌─────▼──────┐
                                       │ MongoDB  │    │  XRPL   │      │  Gemini    │
                                       │ Atlas    │    │ Testnet │      │  API       │
                                       │          │    │ (xrpl-py)│      │ (receipts) │
                                       └──────────┘    └─────────┘      └────────────┘
```

Each user is provisioned a faucet-funded XRPL Testnet wallet at registration. The backend stores `{address, seed, public_key}` server-side and brokers all on-chain transactions; the client only ever sees balances, tx hashes, and NFT IDs.

---

## Repository Layout

```
KUHacks/
├── backend/
│   ├── app.py              # Flask app, all routes, Mongo + XRPL orchestration
│   ├── xrpl_utils.py       # Testnet wallet helpers, Payment, Batch, NFT mint flow
│   ├── requirements.txt
│   ├── Dockerfile          # Gunicorn-on-Python image used by Fly.io
│   └── fly.toml            # Fly.io app config
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   │   ├── auth/                    # signup, login, entry screen with raven + ripples
    │   │   ├── main/                    # home tab + new-ledger sheet
    │   │   ├── people/                  # ledgers, friend screen, settle-up sheet
    │   │   ├── groups/                  # group list + group detail
    │   │   ├── profile/                 # auto-pay overlay, profile, add-funds, memories
    │   │   └── settings/                # settings sheet + per-key detail pages
    │   ├── services/                    # api_client, auth_service, auto_pay_service
    │   └── widgets/                     # avatar_with_score, person_tile, etc.
    └── pubspec.yaml
```

---

## Quickstart

### Prerequisites
- **Flutter** 3.9+ (`flutter doctor` should be all green)
- **Python** 3.11+
- A **MongoDB Atlas** connection string (or any Mongo URI)
- *(Optional)* a **Google AI Studio** API key for receipt scanning
- *(Optional)* **`flyctl`** if you want to deploy your own backend

### 1. Backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Create a .env file (see "Environment Variables" below)
cp .env.example .env   # if you make one, otherwise create manually

flask --app app run --port 5000
```

The backend will create the necessary Mongo indices on first boot and provision XRPL Testnet wallets for new users via the public faucet.

### 2. Frontend

```bash
cd frontend
flutter pub get

# Point the app at your local backend (default in api_client.dart points at Fly.io).
# Easiest override: edit lib/services/api_client.dart -> baseUrl
flutter run                  # picks the first available device
flutter run -d chrome        # web
flutter run -d 00008130-...  # specific device by id
```

To run the web build accessible on your local Wi-Fi:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

---

## Environment Variables

Create `backend/.env`:

```bash
# Mongo connection string (Atlas or local)
MONGO_URI="mongodb+srv://USER:PASS@CLUSTER.mongodb.net/?retryWrites=true&w=majority"

# Symmetric JWT secret. Generate with: python -c "import secrets; print(secrets.token_hex(32))"
JWT_SECRET="..."

# Optional: enables /scan-receipt
GEMINI_API_KEY="..."
```

Never commit `.env` — it's already in `.gitignore`.

---

## API Reference

All endpoints (except `/register` and `/login`) require a `Authorization: Bearer <jwt>` header.

### Auth & profile
| Method | Path | Purpose |
|--|--|--|
| `POST` | `/register` | Create an account. Auto-provisions an XRPL Testnet wallet. |
| `POST` | `/login` | Email + password → JWT. |
| `GET` | `/profile` | Profile, XRPL balance (USD-display), accountability score. |
| `PATCH` | `/profile` | Update display name + base64 avatar. |
| `POST` | `/onboarding` | Mark onboarding complete. |

### Friends & ledgers
| Method | Path | Purpose |
|--|--|--|
| `GET` | `/users/search?q=` | Username search for "Add Friend". |
| `POST` | `/contacts/add` | Send a friend request (creates a pending ledger). |
| `GET` | `/contacts/requests` | Inbox of pending friend requests. |
| `GET` | `/contacts/sent` | Outbox of friend requests you sent. |
| `POST` | `/contacts/accept` | Accept a friend request. |
| `POST` | `/contacts/reject` | Reject a friend request. |
| `GET` | `/ledgers` | Every friend ledger you're part of. |
| `GET` | `/ledgers/<id>` | Detail (including history). |
| `POST` | `/ledgers/<id>/entries` | Add an IOU. |
| `POST` | `/ledgers/<id>/settle` | Settle one ledger via XRPL Payment. |
| `POST` | `/ledgers/settle-batch` | **Settle 1–8 ledgers atomically via XRPL Batch.** |
| `POST` | `/ledgers/<id>/forgive` | Forgive a debt. Optionally mint a Memory NFT. |
| `GET` | `/memories` | Every Memory NFT you've issued or received. |

### Groups
| Method | Path | Purpose |
|--|--|--|
| `POST` | `/groups` | Create a group. |
| `GET` | `/groups` | Groups you're in. |
| `GET` | `/groups/<id>` | Detail. |
| `POST` | `/groups/<id>/entries` | Add a group IOU (between two members). |
| `POST` | `/groups/<id>/settle` | Settle inside a group via XRPL Payment. |

### Entry requests (IOUs awaiting acceptance)
| Method | Path | Purpose |
|--|--|--|
| `POST` | `/ledgers/<id>/entry-requests` | Propose an IOU on a 1:1 ledger. |
| `POST` | `/groups/<id>/entry-requests` | Propose an IOU inside a group. |
| `GET` | `/entry-requests/incoming` | Pending requests addressed to you. |
| `GET` | `/entry-requests/sent` | Pending requests you sent. |
| `POST` | `/entry-requests/<id>/accept` | Accept an IOU. |
| `POST` | `/entry-requests/<id>/reject` | Reject an IOU. |

### Misc
| Method | Path | Purpose |
|--|--|--|
| `POST` | `/scan-receipt` | Body: `{image_base64}` → `{store, total}` via Gemini. |

---

## XRPL Deep Dive

### Batch Settlement
`POST /ledgers/settle-batch` accepts up to 8 `{ledger_id, amount}` items. The backend:

1. Validates every row up-front (caller is in ledger, amount ≤ debt, recipient wallet exists).
2. Builds inner `Payment` txns with `Fee=0`, empty `SigningPubKey`, and the `tfInnerBatchTxn` flag (`0x40000000`).
3. Wraps them in an outer `Batch` with `BatchFlag.TF_ALL_OR_NOTHING`.
4. Lets `xrpl-py`'s `autofill_and_sign` assign each inner sequence (`outer.Sequence + 1, +2, …`) and compute the outer fee = `2 * base + Σ(inner_fees)`.
5. **Only on `tesSUCCESS`** does it write settlement entries to Mongo and recompute scores.

Implementation: `backend/xrpl_utils.py::send_xrp_batch`.

### Memory NFT Minting
`POST /ledgers/<id>/forgive` with `{mint_memory: true, memory_message: "..."}` triggers the standard XRPL "mint and transfer" 3-step flow:

1. **`NFTokenMint`** from the forgiver's wallet, with `tfTransferable`, taxon 0, transfer-fee 0, and a compact JSON payload in the URI: `{v, k:"memory", m, amt, ts, f:<from-username>, t:<to-username>}`. Capped at 256 raw bytes; message progressively trimmed if needed.
2. **`NFTokenCreateOffer`** — sell offer for `0` XRP, `Destination=<recipient address>`, `tfSellNFToken`.
3. **`NFTokenAcceptOffer`** signed by the recipient's wallet (server-side — we hold both seeds for the demo).

After step 3 the NFT lives in the recipient's `account_nfts`. The full message + on-chain handles (`nft_id`, `mint_hash`, `offer_id`, `accept_hash`) are stored in the `memories` Mongo collection. The forgive itself commits to Mongo *before* the mint, so a flaky testnet never blocks the user's intent — failures surface as `memory_error` instead of HTTP 502.

Implementation: `backend/xrpl_utils.py::mint_memory_nft`, `backend/app.py::forgive_ledger`.

### Display rate
On-chain values are XRP drops; the app displays USD using a **fixed display rate of 1 XRP = $1.50** (defined in `xrpl_utils.py`). This is purely cosmetic — the chain remains the source of truth.

> ⚠️ **Demo only.** Wallet seeds are stored in plaintext in MongoDB to enable fully server-side settlement. **Do not point this at mainnet.**

---

## Deployment

The backend deploys to Fly.io with one command:

```bash
cd backend
fly deploy
```

Fly builds the included `Dockerfile`, pushes to Fly's registry, and rolling-restarts the machines defined in `fly.toml` (`hackku-backend` app, `dfw` region, 1GB RAM).

Mongo connection strings, JWT secret, and Gemini key live as Fly secrets:

```bash
fly secrets set MONGO_URI="..." JWT_SECRET="..." GEMINI_API_KEY="..."
```

The frontend is unhosted by default (it's a hackathon app); use `flutter build web` or `flutter build ipa` / `apk` when you want artifacts.

---

## Acknowledgements

- The [XRP Ledger Foundation](https://xrpl.org/) for the Batch and NFToken amendments that this project lives on.
- [Flutter](https://flutter.dev/), [Flask](https://flask.palletsprojects.com/), [Fly.io](https://fly.io/), [MongoDB Atlas](https://www.mongodb.com/atlas), [Google AI Studio](https://ai.google.dev/).
- HackKU 2026 organizers + everyone at the venue who tested the app on their own phones.
