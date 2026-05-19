from __future__ import annotations

from fastapi import Header, HTTPException

from api.bridge.config import CFG


def verify_bearer_token(authorization: str | None = Header(default=None)) -> str:
    """Basic auth-token stub (replace with JWT/OIDC in production)."""
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    if token != CFG.auth_token:
        raise HTTPException(status_code=403, detail="Invalid token")
    return token

