"""CatBoost severity/disease predictor — the winning model from saca_model_evaluation.

Evaluation result (final_architecture_recommendation.md):
    CatBoost 7 pts  vs  ExtraNGvboost 3 pts
    Winner criteria: NLP noise robustness, latency, clinical safety weighting.

Artifacts loaded from SACA_CATBOOST_MODEL_DIR (default: archive/saca_model_evaluation/catboost_runtime_artifacts):
    catboost_severity.cbm    — severity classifier (Mild / Moderate / Severe)
    catboost_disease.cbm     — disease classifier (40 disease classes)
    severity_classes.json    — ordered class label list for severity argmax
    disease_classes.json     — ordered class label list for disease argmax

Feature names are read directly from the .cbm files via model.feature_names_,
so no separate symptom_columns file is required.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np

from api.bridge.symptom_lexicon import PHRASE_TO_CANONICAL

logger = logging.getLogger("saca.bridge.ml")

_REQUIRED = (
    "catboost_severity.cbm",
    "catboost_disease.cbm",
    "severity_classes.json",
    "disease_classes.json",
)


@dataclass
class CatBoostPredictResult:
    severity: str
    severity_confidence: float
    disease: str
    disease_confidence: float
    matched_syms: list[str]
    unmatched_syms: list[str]
    severity_probs: dict[str, float]
    suggestion: str
    symptom_hint: str


class CatBoostPredictor:
    def __init__(self, model_dir: Path) -> None:
        self._dir = model_dir
        self._loaded = False
        self._severity_model: Any = None
        self._disease_model: Any = None
        self._severity_classes: list[str] = []
        self._disease_classes: list[str] = []
        self._feature_names: list[str] = []

    @property
    def feature_names(self) -> list[str]:
        """Symptom column names from the trained model (loaded lazily)."""
        if not self._feature_names and self.is_available():
            self._ensure_loaded()
        return self._feature_names

    def is_available(self) -> bool:
        return all((self._dir / name).exists() for name in _REQUIRED)

    def _ensure_loaded(self) -> None:
        if self._loaded:
            return
        if not self.is_available():
            raise FileNotFoundError(f"Missing CatBoost artifacts under {self._dir}")

        try:
            from catboost import CatBoostClassifier  # type: ignore
        except ImportError as exc:
            raise ImportError(
                "catboost is not installed. Run: pip install catboost"
            ) from exc

        base = self._dir

        self._severity_model = CatBoostClassifier()
        self._severity_model.load_model(str(base / "catboost_severity.cbm"))

        self._disease_model = CatBoostClassifier()
        self._disease_model.load_model(str(base / "catboost_disease.cbm"))

        self._severity_classes = json.loads((base / "severity_classes.json").read_text(encoding="utf-8"))
        self._disease_classes  = json.loads((base / "disease_classes.json").read_text(encoding="utf-8"))

        # Feature names are stored inside the .cbm file — no external file needed.
        self._feature_names = list(self._severity_model.feature_names_)

        self._loaded = True
        logger.info(
            "CatBoost models loaded from %s | features=%d | severity_classes=%s",
            base,
            len(self._feature_names),
            self._severity_classes,
        )

    def predict_symptom_phrases(self, symptom_list: list[str]) -> CatBoostPredictResult | None:
        if not self.is_available():
            return None
        self._ensure_loaded()

        feature_set = set(self._feature_names)
        x = np.zeros((1, len(self._feature_names)), dtype=np.float32)
        matched: list[str] = []
        unmatch: list[str] = []

        for sym in symptom_list:
            sym_clean = sym.strip().lower()
            sym_mapped = PHRASE_TO_CANONICAL.get(sym_clean, sym_clean)
            if sym_mapped in feature_set:
                x[0, self._feature_names.index(sym_mapped)] = 1.0
                matched.append(sym_mapped)
            elif sym_clean in feature_set:
                x[0, self._feature_names.index(sym_clean)] = 1.0
                matched.append(sym_clean)
            else:
                unmatch.append(sym_clean)

        sev_proba = self._severity_model.predict_proba(x)[0]
        sev_idx   = int(np.argmax(sev_proba))
        sev_label = self._severity_classes[sev_idx]
        sev_conf  = float(sev_proba[sev_idx])

        dis_proba = self._disease_model.predict_proba(x)[0]
        dis_idx   = int(np.argmax(dis_proba))
        dis_label = self._disease_classes[dis_idx]
        dis_conf  = float(dis_proba[dis_idx])

        if sev_conf >= 0.80:
            suggestion = "High confidence — result is reliable"
        elif sev_conf >= 0.60:
            suggestion = "Moderate confidence — consider adding more symptoms"
        else:
            suggestion = "Low confidence — please add more symptoms (recommended: 5-6)"

        n = len(matched)
        if n < 3:
            symptom_hint = f"Only {n} symptom(s) matched — more symptoms will improve accuracy"
        elif n < 4:
            symptom_hint = f"{n} symptoms matched — adding 1-2 more may increase confidence"
        else:
            symptom_hint = f"{n} symptoms matched — sufficient for reliable prediction"

        return CatBoostPredictResult(
            severity=sev_label,
            severity_confidence=round(sev_conf, 3),
            disease=dis_label,
            disease_confidence=round(dis_conf, 3),
            matched_syms=matched,
            unmatched_syms=unmatch,
            severity_probs={
                cls: round(float(p), 3)
                for cls, p in zip(self._severity_classes, sev_proba)
            },
            suggestion=suggestion,
            symptom_hint=symptom_hint,
        )
