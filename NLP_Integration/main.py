"""
Compatibility entrypoint.

This file intentionally re-exports the unified FastAPI app from `api.main`
so legacy commands like `uvicorn main:app` continue to work while all active
routes and logic are maintained in one place.
"""

from api.main import app


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("api.main:app", host="0.0.0.0", port=8000, workers=1, log_level="info")
