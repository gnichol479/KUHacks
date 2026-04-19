"""XRPL Testnet helpers.

NEVER use these on mainnet — the seed is stored in plaintext in MongoDB to
enable demo "Settle Up" payments. The faucet wallet returned by
`generate_faucet_wallet` is a throwaway testnet account.
"""

from xrpl.clients import JsonRpcClient
from xrpl.models.requests import AccountInfo
from xrpl.wallet import generate_faucet_wallet

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
