from __future__ import annotations

from typing import Literal

from pydantic import BaseModel


class TriageAnalyzeVoiceResponse(BaseModel):
    transcript: str
    triage_level: Literal["Severe", "Moderate", "Mild"]
    top_condition: str
    recommendation: str
    language: str = "en"
    warlpiri_raw_transcript: str | None = None


class TranscribeResponse(BaseModel):
    transcript: str
    transcript_final: str


class TriagePredictRequest(BaseModel):
    raw_transcript: str
    verified_transcript: str
    language: str = "en"


class TriagePredictResponse(BaseModel):
    triage_level: Literal["Severe", "Moderate", "Mild"]
    top_condition: str
    confidence: float
    top_3_symptoms: list[str]
    recommendation: str
    escalation_triggered: bool
    language: str = "en"
    warlpiri_raw_transcript: str | None = None

