"""XRPL Testnet helpers.

NEVER use these on mainnet — the seed is stored in plaintext in MongoDB to
enable demo "Settle Up" payments. The faucet wallet returned by
`generate_faucet_wallet` is a throwaway testnet account.
"""

from typing import List, Optional, Tuple

from xrpl.clients import JsonRpcClient
from xrpl.models.requests import AccountInfo, AccountNFTs
from xrpl.models.transactions import (
    Batch,
    NFTokenAcceptOffer,
    NFTokenCreateOffer,
    NFTokenMint,
    Payment,
)
from xrpl.models.transactions.batch import BatchFlag
from xrpl.models.transactions.nftoken_create_offer import NFTokenCreateOfferFlag
from xrpl.models.transactions.nftoken_mint import NFTokenMintFlag
from xrpl.transaction import autofill_and_sign, submit_and_wait
from xrpl.utils import str_to_hex
from xrpl.wallet import Wallet, generate_faucet_wallet

# Per the XRPL Batch spec, every inner transaction must carry this global
# flag (tfInnerBatchTxn = 0x40000000) so the network refuses any attempt to
# broadcast it independently of the outer Batch.
TF_INNER_BATCH_TXN = 0x40000000

XRPL_TESTNET_URL = "https://s.altnet.rippletest.net:51234"

# Single shared client. JsonRpcClient is stateless (just stores the URL) so
# reusing one across requests is safe under Gunicorn workers on Fly.io.
xrpl_client = JsonRpcClient(XRPL_TESTNET_URL)


def create_xrpl_wallet(client: JsonRpcClient = xrpl_client) -> dict:
    """Generates and funds a TESTNET XRPL wallet via the public faucet.

    Returns a dict containing the classic address, secret seed, and the
    derived public key. The seed is included so that the caller can persist
    it for later signing — DO NOT echo it back to clients.
    """
    wallet = generate_faucet_wallet(client)
    return {
        "address": wallet.classic_address,
        "seed": wallet.seed,
        "public_key": wallet.public_key,
    }


def get_xrp_balance(address: str, client: JsonRpcClient = xrpl_client) -> int:
    """Returns the validated balance for `address` in drops (1 XRP = 1e6 drops).

    Returns 0 on any failure so that registration / status flows never crash
    when the testnet ledger is briefly unreachable or the account hasn't
    propagated yet.
    """
    try:
        resp = client.request(
            AccountInfo(account=address, ledger_index="validated")
        )
        return int(resp.result["account_data"]["Balance"])
    except Exception:
        return 0


# --- Display-layer conversion helpers -------------------------------------
# Hardcoded for the demo. This is NOT a live FX rate; the on-chain balance
# remains the source of truth.
XRP_TO_USD_RATE = 1.5
DROPS_PER_XRP = 1_000_000


def drops_to_xrp(drops: int) -> float:
    """Convert raw drops returned by the ledger into whole XRP."""
    return round(drops / DROPS_PER_XRP, 6)


def convert_xrp_to_usd(xrp_amount: float) -> float:
    """Apply the fixed display-layer conversion rate (1 XRP = 1.50 USD)."""
    return round(xrp_amount * XRP_TO_USD_RATE, 2)


def usd_to_drops(usd_amount: float) -> int:
    """Convert a USD amount into raw XRPL drops using the fixed display rate."""
    xrp = usd_amount / XRP_TO_USD_RATE
    return int(round(xrp * DROPS_PER_XRP))


def send_xrp_payment(
    sender_seed: str,
    destination: str,
    drops: int,
    client: JsonRpcClient = xrpl_client,
) -> dict:
    """Submit a Payment on testnet from the seed-derived wallet to `destination`.

    Returns the validated tx hash + engine result on success. Raises
    `RuntimeError` with the engine result string on any non-tesSUCCESS outcome
    so callers can surface a meaningful error to the UI.
    """
    if drops <= 0:
        raise RuntimeError("XRPL payment amount must be greater than 0 drops")

    wallet = Wallet.from_seed(sender_seed)
    tx = Payment(
        account=wallet.classic_address,
        destination=destination,
        amount=str(drops),
    )
    response = submit_and_wait(tx, client, wallet)
    result = response.result or {}
    engine = (
        (result.get("meta") or {}).get("TransactionResult")
        or result.get("engine_result")
    )
    if engine != "tesSUCCESS":
        raise RuntimeError(f"XRPL payment failed: {engine or 'unknown'}")
    return {
        "hash": result.get("hash"),
        "engine_result": engine,
    }


def send_xrp_batch(
    sender_seed: str,
    payments: List[Tuple[str, int]],
    mode: str = "ALLORNOTHING",
    client: JsonRpcClient = xrpl_client,
) -> dict:
    """Submit an XRPL Batch transaction containing one Payment per (dest, drops).

    `payments` is a list of `(destination_address, drops)` tuples. Up to 8
    inner transactions are allowed by the protocol — we enforce that here so
    the caller fails fast instead of getting a cryptic engine result.

    `mode` selects the Batch behavior:
      - "ALLORNOTHING" (default) — every inner Payment must succeed for any
        of them to settle. This is what we want for "Auto-Settle all my
        debts" so the user never ends up half-paid.
      - "ONLYONE", "UNTILFAILURE", "INDEPENDENT" — also supported, mirror
        the spec.

    All inner Payments come from the same account (the seed-derived wallet).
    Per the spec they must carry `tfInnerBatchTxn`, have `Fee=0`, and be
    unsigned (`SigningPubKey=""`, no `TxnSignature`). The outer Batch is the
    only thing that gets signed and pays the cumulative fee.

    Returns the validated outer-tx hash + a list of inner results in the
    order they were submitted. Raises RuntimeError on any non-tesSUCCESS
    outcome on the *outer* transaction (which, in ALLORNOTHING mode, also
    means none of the inner Payments settled).
    """
    if not payments:
        raise RuntimeError("Batch payment list is empty")
    if len(payments) > 8:
        raise RuntimeError("XRPL Batch supports at most 8 inner transactions")
    for dest, drops in payments:
        if drops <= 0:
            raise RuntimeError("Each batch payment must be > 0 drops")
        if not dest:
            raise RuntimeError("Each batch payment needs a destination address")

    mode_to_flag = {
        "ALLORNOTHING": BatchFlag.TF_ALL_OR_NOTHING,
        "ONLYONE": BatchFlag.TF_ONLY_ONE,
        "UNTILFAILURE": BatchFlag.TF_UNTIL_FAILURE,
        "INDEPENDENT": BatchFlag.TF_INDEPENDENT,
    }
    if mode not in mode_to_flag:
        raise RuntimeError(f"Unknown batch mode: {mode}")

    wallet = Wallet.from_seed(sender_seed)
    sender_addr = wallet.classic_address

    # Build each inner Payment per the Batch spec: fee 0, no signature, no
    # signing pub key, and the inner-batch flag set so the network refuses
    # to accept the txn outside of an outer Batch.
    inner_txns = [
        Payment(
            account=sender_addr,
            destination=dest,
            amount=str(drops),
            fee="0",
            signing_pub_key="",
            flags=TF_INNER_BATCH_TXN,
        )
        for dest, drops in payments
    ]

    batch_tx = Batch(
        account=sender_addr,
        raw_transactions=inner_txns,
        flags=mode_to_flag[mode].value,
    )

    # autofill is Batch-aware in xrpl-py >= 4.3 — it walks raw_transactions
    # and assigns each inner the right Sequence (outer.Sequence+1, +2, …)
    # and computes the outer Fee = 2*base + sum(inner_fees) + extras.
    signed = autofill_and_sign(batch_tx, client, wallet)
    response = submit_and_wait(signed, client)
    result = response.result or {}
    engine = (
        (result.get("meta") or {}).get("TransactionResult")
        or result.get("engine_result")
    )
    if engine != "tesSUCCESS":
        raise RuntimeError(f"XRPL batch failed: {engine or 'unknown'}")

    # Per the spec, each inner transaction is committed to the ledger with
    # its own metadata. submit_and_wait only returns the outer tx, so we
    # surface the engine result + the validated outer hash. Callers that
    # need per-inner status can re-query by ParentBatchID.
    return {
        "hash": result.get("hash"),
        "engine_result": engine,
        "inner_count": len(payments),
    }


# --- NFT memories ----------------------------------------------------------
# When a user "forgives" a debt they can optionally mint a memory NFT to the
# debtor. The 3-step flow below is the standard XRPL pattern for "mint &
# transfer" because NFTokenMint deposits the NFT into the issuer's account
# by default. We do all three transactions server-side (we hold both seeds
# in the demo Mongo store) so the recipient ends up actually owning the
# token without any client-side signing UX.

# NFT URI must be a hex string and the raw payload is capped at 256 bytes
# by the network. We slice the message before composing the payload so a
# long memo never breaks minting.
NFT_URI_MAX_BYTES = 256


def _extract_nftoken_id(meta: dict) -> Optional[str]:
    """Modern xrpl-py / rippled versions surface the freshly minted token
    id as `meta.nftoken_id`. Older nodes don't, so we fall back to walking
    `AffectedNodes` for the new NFTokenPage entry — exactly the same trick
    the official xrpl.js client uses."""
    direct = meta.get("nftoken_id")
    if direct:
        return direct
    for node in meta.get("AffectedNodes", []) or []:
        for kind in ("CreatedNode", "ModifiedNode"):
            entry = node.get(kind) or {}
            if entry.get("LedgerEntryType") != "NFTokenPage":
                continue
            new_fields = entry.get("NewFields") or entry.get("FinalFields") or {}
            tokens = new_fields.get("NFTokens") or []
            if tokens:
                return (tokens[-1] or {}).get("NFToken", {}).get("NFTokenID")
    return None


def _extract_offer_id(meta: dict) -> Optional[str]:
    """Same idea as `_extract_nftoken_id` but for the NFTokenOffer entry
    created by NFTokenCreateOffer. Falls back to scanning AffectedNodes
    when the node didn't add the convenience `offer_id` field."""
    direct = meta.get("offer_id")
    if direct:
        return direct
    for node in meta.get("AffectedNodes", []) or []:
        cn = node.get("CreatedNode") or {}
        if cn.get("LedgerEntryType") == "NFTokenOffer":
            return cn.get("LedgerIndex")
    return None


def mint_memory_nft(
    issuer_seed: str,
    recipient_seed: str,
    recipient_address: str,
    uri_payload: str,
    taxon: int = 0,
    client: JsonRpcClient = xrpl_client,
) -> dict:
    """Mint an NFT from the issuer wallet, offer it to `recipient_address`
    for 0 XRP, and accept the offer using the recipient's seed.

    Returns a dict with the on-chain identifiers so the caller can persist
    them next to the off-chain memory record:
        {
          "nft_id": "...",
          "mint_hash": "...",
          "offer_id": "...",
          "offer_hash": "...",
          "accept_hash": "...",
          "uri_hex": "...",
        }

    Raises RuntimeError on any non-tesSUCCESS engine result so the caller
    can either roll back or surface the error to the user.
    """
    if not issuer_seed or not recipient_seed or not recipient_address:
        raise RuntimeError("Issuer + recipient wallets are required")

    payload_bytes = uri_payload.encode("utf-8")
    if len(payload_bytes) > NFT_URI_MAX_BYTES:
        raise RuntimeError(
            f"NFT URI payload is {len(payload_bytes)} bytes; max is "
            f"{NFT_URI_MAX_BYTES}"
        )
    uri_hex = str_to_hex(uri_payload)

    issuer_wallet = Wallet.from_seed(issuer_seed)
    recipient_wallet = Wallet.from_seed(recipient_seed)
    if recipient_wallet.classic_address != recipient_address:
        raise RuntimeError(
            "Recipient seed does not match the supplied recipient address"
        )

    # 1) Mint with TF_TRANSFERABLE so the issuer can move it to the
    #    recipient via a sell offer. Transfer fee is 0 — memories aren't
    #    meant to be re-traded for profit.
    mint_tx = NFTokenMint(
        account=issuer_wallet.classic_address,
        nftoken_taxon=int(taxon),
        flags=NFTokenMintFlag.TF_TRANSFERABLE,
        uri=uri_hex,
        transfer_fee=0,
    )
    mint_resp = submit_and_wait(mint_tx, client, issuer_wallet)
    mint_result = mint_resp.result or {}
    mint_meta = mint_result.get("meta") or {}
    if mint_meta.get("TransactionResult") != "tesSUCCESS":
        raise RuntimeError(
            f"NFT mint failed: {mint_meta.get('TransactionResult')}"
        )
    nft_id = _extract_nftoken_id(mint_meta)
    if not nft_id:
        raise RuntimeError("Mint succeeded but NFTokenID was not returned")

    # 2) Issuer creates a sell offer for 0 XRP, restricted to the
    #    recipient via the Destination field. tfSellNFToken (=1) marks
    #    this as a sell offer.
    offer_tx = NFTokenCreateOffer(
        account=issuer_wallet.classic_address,
        nftoken_id=nft_id,
        amount="0",
        flags=NFTokenCreateOfferFlag.TF_SELL_NFTOKEN,
        destination=recipient_address,
    )
    offer_resp = submit_and_wait(offer_tx, client, issuer_wallet)
    offer_result = offer_resp.result or {}
    offer_meta = offer_result.get("meta") or {}
    if offer_meta.get("TransactionResult") != "tesSUCCESS":
        raise RuntimeError(
            f"NFT offer failed: {offer_meta.get('TransactionResult')}"
        )
    offer_id = _extract_offer_id(offer_meta)
    if not offer_id:
        raise RuntimeError("Offer succeeded but offer index was not returned")

    # 3) Recipient accepts the sell offer. After this transaction the NFT
    #    lives in the recipient's NFTokenPage and `account_nfts` will list
    #    it under their address.
    accept_tx = NFTokenAcceptOffer(
        account=recipient_wallet.classic_address,
        nftoken_sell_offer=offer_id,
    )
    accept_resp = submit_and_wait(accept_tx, client, recipient_wallet)
    accept_result = accept_resp.result or {}
    accept_meta = accept_result.get("meta") or {}
    if accept_meta.get("TransactionResult") != "tesSUCCESS":
        raise RuntimeError(
            f"NFT accept failed: {accept_meta.get('TransactionResult')}"
        )

    return {
        "nft_id": nft_id,
        "mint_hash": mint_result.get("hash"),
        "offer_id": offer_id,
        "offer_hash": offer_result.get("hash"),
        "accept_hash": accept_result.get("hash"),
        "uri_hex": uri_hex,
    }


def list_account_nfts(address: str, client: JsonRpcClient = xrpl_client) -> list:
    """Return the raw `account_nfts` array for `address` (or [] on failure).

    Useful for letting the UI display "this memory really exists on-chain"
    confirmations without us re-reading the ledger every time.
    """
    try:
        resp = client.request(AccountNFTs(account=address))
        return (resp.result or {}).get("account_nfts", []) or []
    except Exception:
        return []
