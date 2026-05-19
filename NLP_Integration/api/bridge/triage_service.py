from __future__ import annotations

import logging
import re
from dataclasses import dataclass

import numpy as np

from api.bridge.config import CFG
from api.bridge.ml_predictor import CatBoostPredictor
from api.bridge.symptom_lexicon import PHRASE_TO_CANONICAL, SYMPTOM_PHRASES

logger = logging.getLogger("saca.bridge.triage")

SEVERE_REC = "Evacuate immediately to nearest emergency-capable facility and monitor airway/breathing continuously."
MODERATE_REC = "Attend clinic within 4 hours for clinician assessment and worsening-sign monitoring."
MILD_REC = "Routine check-up recommended; continue hydration/rest and return if symptoms worsen."

PAIN_MAP: dict[str, str] = {
    "chest": "sharp chest pain",
    "head": "headache",
    "stomach": "sharp abdominal pain",
    "abdomen": "sharp abdominal pain",
    "back": "back pain",
    "arm": "joint pain",
    "arms": "joint pain",
    "leg": "muscle pain",
    "legs": "muscle pain",
}

SEVERE_KEYWORDS = {"chest pain", "shortness of breath", "fainting", "severe", "bleeding", "stroke", "cannot breathe"}
MODERATE_KEYWORDS = {"fever", "vomiting", "dizziness", "headache", "abdominal pain", "weakness"}

_REC_BY_LEVEL = {"Severe": SEVERE_REC, "Moderate": MODERATE_REC, "Mild": MILD_REC}


@dataclass
class TriageDecision:
    triage_level: str
    top_condition: str
    recommendation: str
    confidence: float


def _normalize_level(label: str) -> str:
    t = (label or "").strip().title()
    if t in _REC_BY_LEVEL:
        return t
    return "Moderate"


class TriageService:
    def __init__(self) -> None:
        self._catboost = CatBoostPredictor(CFG.catboost_model_dir)
        # symptom_columns are populated lazily from the model's feature_names
        # on first successful prediction; used to filter _extract_symptoms results.
        self._symptom_columns_cache: list[str] = []

    @property
    def symptom_columns(self) -> list[str]:
        if not self._symptom_columns_cache:
            self._symptom_columns_cache = self._catboost.feature_names
        return self._symptom_columns_cache

    def decide(
        self,
        transcript: str,
        semantic_vector: np.ndarray,
        text_input: str = "",
        pain_locations: list[str] | None = None,
    ) -> TriageDecision:
        pain_locations = pain_locations or []
        merged = " ".join([text_input or "", transcript or ""]).strip().lower()
        merged = re.sub(r"\s+", " ", merged)
        matched = self._extract_symptoms(merged, pain_locations)

        if self._catboost.is_available():
            try:
                ml = self._catboost.predict_symptom_phrases(sorted(matched))
            except Exception as exc:
                logger.warning("CatBoost inference failed; using heuristic triage: %s", exc)
                ml = None
            if ml is not None:
                level = _normalize_level(ml.severity)
                recommendation = _REC_BY_LEVEL[level]
                confidence = float(ml.severity_confidence)
                top_condition = ml.disease
                if confidence < 0.35:
                    top_condition = "Needs clinical review"
                return TriageDecision(
                    triage_level=level,
                    top_condition=top_condition,
                    recommendation=recommendation,
                    confidence=confidence,
                )

        return self._heuristic_decide(merged, matched, transcript, semantic_vector)

    def _heuristic_decide(
        self,
        merged: str,
        matched: set[str],
        transcript: str,
        semantic_vector: np.ndarray,
    ) -> TriageDecision:
        model_bias = self._semantic_risk_bias(semantic_vector)
        severe_score = sum(1 for k in SEVERE_KEYWORDS if k in merged)
        moderate_score = sum(1 for k in MODERATE_KEYWORDS if k in merged)

        if severe_score > 0 or len(matched) >= 6 or model_bias >= 0.75:
            level = "Severe"
            recommendation = SEVERE_REC
        elif moderate_score > 0 or len(matched) >= 3 or model_bias >= 0.45:
            level = "Moderate"
            recommendation = MODERATE_REC
        else:
            level = "Mild"
            recommendation = MILD_REC

        top_condition = self._pick_top_condition(matched, merged)
        confidence = self._confidence(
            level=level,
            n_symptoms=len(matched),
            has_transcript=bool(transcript.strip()),
            semantic_bias=model_bias,
        )
        if confidence < 0.35:
            top_condition = "Needs clinical review"
        return TriageDecision(
            triage_level=level,
            top_condition=top_condition,
            recommendation=recommendation,
            confidence=confidence,
        )

    def _extract_symptoms(self, merged_text: str, pain_locations: list[str]) -> set[str]:
        matched: set[str] = set()
        cols = set(self.symptom_columns) if self.symptom_columns else None

        for phrase, target in SYMPTOM_PHRASES.items():
            if phrase in merged_text and (not cols or target in cols):
                matched.add(target)

        for raw in re.split(r"[,;\n]+", merged_text):
            chunk = raw.strip().strip('"').strip("'").strip("`").lower()
            if len(chunk) < 2:
                continue
            mapped = PHRASE_TO_CANONICAL.get(chunk, chunk)
            if cols:
                if mapped in cols:
                    matched.add(mapped)
                elif chunk in cols:
                    matched.add(chunk)
            elif chunk in PHRASE_TO_CANONICAL:
                matched.add(PHRASE_TO_CANONICAL[chunk])

        for p in pain_locations:
            mapped = PAIN_MAP.get(p.strip().lower())
            if mapped and (not cols or mapped in cols):
                matched.add(mapped)
        return matched

    def _pick_top_condition(self, matched: set[str], merged_text: str) -> str:
        if "sharp chest pain" in matched or "heart" in merged_text:
            return "heart attack"
        if "shortness of breath" in merged_text or "cough" in merged_text:
            return "pneumonia"
        if "sharp abdominal pain" in matched:
            return "acute pancreatitis"
        if "headache" in matched and "weakness" in merged_text:
            return "stroke"
        return "general medical condition"

    @staticmethod
    def _semantic_risk_bias(semantic_vector: np.ndarray) -> float:
        if semantic_vector.size == 0:
            return 0.0
        score = float(np.mean(np.abs(semantic_vector[: min(32, semantic_vector.shape[0])])))
        return max(0.0, min(score, 1.0))

    @staticmethod
    def _confidence(level: str, n_symptoms: int, has_transcript: bool, semantic_bias: float) -> float:
        base = 0.35 if not has_transcript else 0.5
        if level == "Severe":
            base += 0.2
        elif level == "Moderate":
            base += 0.12
        base += min(n_symptoms, 6) * 0.05
        base += semantic_bias * 0.1
        return round(max(0.05, min(base, 0.95)), 4)
