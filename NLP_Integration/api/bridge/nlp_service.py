from __future__ import annotations

import hashlib
from dataclasses import dataclass

import numpy as np


@dataclass
class NLPVector:
    embedding: np.ndarray
    dim: int


class NLPService:
    """SBERT encoder service with deterministic fallback."""

    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2") -> None:
        self._model_name = model_name
        self._model = None
        self._provider = "fallback"
        try:
            from sentence_transformers import SentenceTransformer  # type: ignore

            self._model = SentenceTransformer(model_name)
            self._provider = "sbert"
        except Exception:
            self._model = None
            self._provider = "fallback"

    @property
    def provider(self) -> str:
        return self._provider

    def encode(self, text: str) -> NLPVector:
        if self._model is not None:
            emb = self._model.encode(
                [text or ""],
                convert_to_numpy=True,
                normalize_embeddings=True,
                show_progress_bar=False,
            ).astype(np.float32)[0]
            return NLPVector(embedding=emb, dim=int(emb.shape[0]))
        emb = self._fallback_embedding(text, dim=384)
        return NLPVector(embedding=emb, dim=384)

    @staticmethod
    def _fallback_embedding(text: str, dim: int) -> np.ndarray:
        out = np.zeros((dim,), dtype=np.float32)
        seed = hashlib.sha256((text or "").encode("utf-8")).digest()
        for i in range(dim):
            out[i] = (seed[i % len(seed)] / 255.0) * 2.0 - 1.0
        n = np.linalg.norm(out)
        if n > 0:
            out /= n
        return out

