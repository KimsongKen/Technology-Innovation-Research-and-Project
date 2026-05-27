import asyncio
import logging
import numpy as np
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.bridge.config import CFG
from api.bridge.router import bridge_health_snapshot, router as bridge_router, stt_service

logger = logging.getLogger("saca.startup")


async def _prewarm_stt() -> None:
    """Run a silent dummy transcription so the model is loaded and JIT-compiled
    before the first real patient request arrives.  This converts a cold-start
    30-60 s spike into a predictable sub-second response."""
    try:
        # 0.5 s of silence at 16 kHz — enough to exercise the full pipeline
        dummy = np.zeros(8000, dtype=np.float32)
        await stt_service.transcribe_audio(dummy, language="en-AU")
        logger.info("STT model pre-warm complete (provider=%s)", stt_service.provider)
    except Exception as exc:
        logger.warning("STT pre-warm skipped: %s", exc)


@asynccontextmanager
async def lifespan(app: FastAPI):  # noqa: ARG001
    # ── startup ──────────────────────────────────────────────────────────────
    logger.info("SACA bridge starting — pre-warming STT model in background …")
    asyncio.create_task(_prewarm_stt())
    yield
    # ── shutdown ─────────────────────────────────────────────────────────────


app = FastAPI(
    title="Swin SACA Intelligence Hub",
    description="Secure bridge API for deterministic voice triage analysis.",
    version="0.1.0",
    lifespan=lifespan,
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
