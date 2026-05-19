import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.bridge.config import CFG
from api.bridge.router import bridge_health_snapshot, router as bridge_router


app = FastAPI(
    title="Swin SACA Intelligence Hub",
    description="Secure bridge API for deterministic voice triage analysis.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=list(CFG.cors_allow_origins),
    allow_origin_regex=CFG.cors_allow_origin_regex,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

app.include_router(bridge_router)


@app.get("/health", tags=["system"])
def health_check() -> dict:
    # For local Android/LAN testing you may allow broad origins.
    # For production, set SACA_CORS_ALLOW_ORIGINS and SACA_CORS_ALLOW_ORIGIN_REGEX explicitly.
    return bridge_health_snapshot()


if __name__ == "__main__":
    uvicorn.run("api.main:app", host=CFG.host, port=CFG.port, reload=False)
