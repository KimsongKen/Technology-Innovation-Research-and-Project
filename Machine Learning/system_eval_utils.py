from __future__ import annotations

import random
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer

from data_prep import create_standardized_test_set


EVAL_DIR = Path(__file__).resolve().parent


def load_standardized_test_set() -> pd.DataFrame:
    return create_standardized_test_set()


def symptom_columns_from_df(df: pd.DataFrame) -> list[str]:
    return [c for c in df.columns if c not in {"diseases", "Severity"}]


def row_to_symptoms(row: pd.Series, symptom_columns: list[str]) -> list[str]:
    symptoms: list[str] = []
    for c in symptom_columns:
        val = row.get(c, 0)
        if pd.notna(val) and float(val) > 0:
            symptoms.append(c)
    return symptoms


SLANG_MAP = {
    "sharp chest pain": "chest pan real bad",
    "shortness of breath": "cant breath proper",
    "feeling ill": "feelin crook",
    "nausea": "feelin sick",
    "vomiting": "throwin up",
    "dizziness": "head all spinny",
    "headache": "head hurt bad",
    "painful urination": "pee burnin",
    "sore throat": "throat hurt",
    "fatigue": "real tired",
    "weakness": "no strength",
    "chills": "shaky cold",
    "fever": "burning up",
}


def _inject_typo(text: str, rng: random.Random) -> str:
    if len(text) < 5:
        return text
    chars = list(text)
    idx = rng.randint(1, len(chars) - 2)
    # Delete one character to mimic common tablet typing omission.
    del chars[idx]
    return "".join(chars)


def inject_human_noise(symptoms: list[str], rng: random.Random) -> list[str]:
    noisy: list[str] = []
    for s in symptoms:
        token = SLANG_MAP.get(s, s)
        if rng.random() < 0.25:
            token = _inject_typo(token, rng)
        if rng.random() < 0.15:
            token = token.replace("ing", "in")
        noisy.append(token)
    return noisy


@dataclass
class SbertSymptomMapper:
    symptom_names: list[str]
    model_name: str = "all-MiniLM-L6-v2"
    threshold: float = 0.35

    def __post_init__(self) -> None:
        self.model = SentenceTransformer(self.model_name)
        self.symptom_embeddings = self.model.encode(
            self.symptom_names,
            normalize_embeddings=True,
            show_progress_bar=False,
        )
        self._cache: dict[str, str | None] = {}

    def _map_one(self, noisy_chunk: str) -> str | None:
        cached = self._cache.get(noisy_chunk)
        if noisy_chunk in self._cache:
            return cached

        emb = self.model.encode([noisy_chunk], normalize_embeddings=True, show_progress_bar=False)[
            0
        ]
        sims = np.dot(self.symptom_embeddings, emb)
        idx = int(np.argmax(sims))
        if float(sims[idx]) < self.threshold:
            self._cache[noisy_chunk] = None
            return None
        mapped = self.symptom_names[idx]
        self._cache[noisy_chunk] = mapped
        return mapped

    def map_noisy_symptoms(self, noisy_chunks: list[str]) -> list[str]:
        mapped: list[str] = []
        seen: set[str] = set()
        for chunk in noisy_chunks:
            candidate = self._map_one(chunk)
            if candidate and candidate not in seen:
                mapped.append(candidate)
                seen.add(candidate)
        return mapped
