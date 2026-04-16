from __future__ import annotations

import hashlib
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd
import torch
from sklearn.model_selection import train_test_split
from torch.utils.data import DataLoader, Dataset

from configs.saca_config import SACAConfig

try:
    from imblearn.over_sampling import SMOTE  # type: ignore
except Exception:  # pragma: no cover
    SMOTE = None


def _try_read_csv(path: str) -> pd.DataFrame:
    try:
        return pd.read_csv(path)
    except FileNotFoundError:
        # fallback for users who keep the CSV at repo root
        if path.replace("\\", "/").endswith("data/healthcare_dataset.csv"):
            return pd.read_csv("healthcare_dataset.csv")
        raise


def _infer_column(columns: List[str], preferred: List[str]) -> str:
    lowered = {c.lower(): c for c in columns}
    for p in preferred:
        if p.lower() in lowered:
            return lowered[p.lower()]
    for c in columns:
        for p in preferred:
            if p.lower() in c.lower():
                return c
    raise ValueError(f"Could not infer required column. Tried: {preferred}")


def _stable_hash_to_rng_seed(text: str) -> int:
    return int(hashlib.sha256(text.encode("utf-8")).hexdigest(), 16) % (2**32)


def _placeholder_text_embedding(text: str, dim: int) -> np.ndarray:
    """
    Deterministic placeholder embedding. Swap with SBERT later.
    """
    rng = np.random.default_rng(_stable_hash_to_rng_seed(text))
    v = rng.normal(0.0, 1.0, dim).astype(np.float32)
    v /= (np.linalg.norm(v) + 1e-8)
    return v


def _placeholder_audio_features(text: str, seq_len: int) -> np.ndarray:
    rng = np.random.default_rng(_stable_hash_to_rng_seed("audio:" + text))
    signal = rng.normal(0.0, 1.0, seq_len).astype(np.float32)
    trend = np.linspace(-0.2, 0.2, seq_len, dtype=np.float32)
    return signal + trend


def _scalar_to_trend(value: float, seq_len: int, noise: float, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    base = np.full(seq_len, float(value), dtype=np.float32)
    drift = np.linspace(-0.5, 0.5, seq_len, dtype=np.float32)
    jitter = rng.normal(0.0, noise, seq_len).astype(np.float32)
    return base + drift + jitter


def map_disease_to_triage(disease: str) -> str:
    """
    Lightweight clinical triage heuristic mapping Disease -> Mild/Moderate/Severe.
    This is intentionally conservative and should be refined with clinical review.
    """
    d = str(disease or "").strip().lower()
    if not d:
        return "Moderate"

    severe_keywords = [
        "heart attack",
        "myocard",
        "stroke",
        "sepsis",
        "pneumonia",
        "tuberculosis",
        "tb",
        "mening",
        "cancer",
        "renal failure",
        "kidney failure",
        "respiratory failure",
        "asthma attack",
        "anaphyl",
        "dengue",
        "malaria",
        "embol",
        "hemorr",
        "fracture",
        "burn",
    ]
    moderate_keywords = [
        "diabetes",
        "hypertension",
        "asthma",
        "bronchitis",
        "uti",
        "infection",
        "influenza",
        "flu",
        "gastro",
        "dehydrat",
        "migraine",
        "appendic",
        "covid",
        "pregnan",
    ]
    mild_keywords = [
        "cold",
        "cough",
        "sore throat",
        "allergy",
        "rash",
        "sprain",
        "headache",
        "diarrhea",
        "vomit",
        "nausea",
        "fever",
    ]

    if any(k in d for k in severe_keywords):
        return "Severe"
    if any(k in d for k in moderate_keywords):
        return "Moderate"
    if any(k in d for k in mild_keywords):
        return "Mild"
    return "Moderate"


class SACA_Dataset(Dataset):
    def __init__(
        self,
        text_emb: np.ndarray,
        audio: np.ndarray,
        vitals: np.ndarray,
        labels: np.ndarray,
    ):
        self.text_emb = text_emb.astype(np.float32)
        self.audio = audio.astype(np.float32)
        self.vitals = vitals.astype(np.float32)
        self.labels = labels.astype(np.int64)

    def __len__(self) -> int:
        return int(len(self.labels))

    def __getitem__(self, idx: int) -> Dict[str, torch.Tensor]:
        return {
            "text_emb": torch.tensor(self.text_emb[idx], dtype=torch.float32),
            "audio": torch.tensor(self.audio[idx], dtype=torch.float32).unsqueeze(0),  # [1, L]
            "vitals": torch.tensor(self.vitals[idx], dtype=torch.float32),  # [T, F]
            "label": torch.tensor(self.labels[idx], dtype=torch.long),
        }


def _apply_smote_multimodal(
    text_emb: np.ndarray,
    audio: np.ndarray,
    vitals: np.ndarray,
    labels: np.ndarray,
    random_state: int,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    if SMOTE is None:
        print("Warning: imbalanced-learn is not installed; skipping SMOTE oversampling.")
        return text_emb, audio, vitals, labels

    n_text = text_emb.shape[1]
    n_audio = audio.shape[1]
    n_vitals = vitals.shape[1] * vitals.shape[2]

    combined = np.concatenate([text_emb, audio, vitals.reshape(len(vitals), -1)], axis=1)
    smote = SMOTE(random_state=random_state)
    x_res, y_res = smote.fit_resample(combined, labels)

    text_res = x_res[:, :n_text]
    audio_res = x_res[:, n_text : n_text + n_audio]
    vitals_flat = x_res[:, n_text + n_audio : n_text + n_audio + n_vitals]
    vitals_res = vitals_flat.reshape(-1, vitals.shape[1], vitals.shape[2])
    return text_res, audio_res, vitals_res, y_res


def build_arrays_from_csv(cfg: SACAConfig) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, Dict[str, int]]:
    df = _try_read_csv(cfg.csv_path)

    disease_col = _infer_column(df.columns.tolist(), ["Disease"])
    text_col = _infer_column(
        df.columns.tolist(),
        [
            "Symptoms",
            "Symptom",
            "Complaint",
            "Symptom_Text",
            "symptom_text",
            "text",
            "description",
            "transcript",
        ],
    )
    age_col = _infer_column(df.columns.tolist(), ["Age"])
    sc_col = _infer_column(df.columns.tolist(), ["Symptom_Count", "symptom_count", "symptomcount"])

    triage = df[disease_col].map(map_disease_to_triage).astype(str).str.title()
    classes = ["Mild", "Moderate", "Severe"]
    class_to_idx = {c: i for i, c in enumerate(classes)}
    y = triage.map(class_to_idx).fillna(class_to_idx["Moderate"]).astype(int).to_numpy()

    texts = df[text_col].fillna("").astype(str).tolist()
    text_emb = np.stack([_placeholder_text_embedding(t, cfg.text_embedding_dim) for t in texts], axis=0)

    audio = np.stack([_placeholder_audio_features(t, cfg.audio_seq_len) for t in texts], axis=0)

    ages = pd.to_numeric(df[age_col], errors="coerce").fillna(df[age_col].median()).astype(float).to_numpy()
    sym_ct = pd.to_numeric(df[sc_col], errors="coerce").fillna(df[sc_col].median()).astype(float).to_numpy()

    # Vitals features: [Age, Symptom_Count, HeartRate(dummy), SpO2(dummy)] as a sequence [T, 4]
    vitals = []
    for i in range(len(df)):
        seed = _stable_hash_to_rng_seed(f"vitals:{texts[i]}")
        hr = _scalar_to_trend(75.0 + 0.2 * sym_ct[i], cfg.vitals_seq_len, noise=1.5, seed=seed + 1)
        spo2 = _scalar_to_trend(97.0 - 0.1 * sym_ct[i], cfg.vitals_seq_len, noise=0.5, seed=seed + 2)
        age_seq = np.full(cfg.vitals_seq_len, ages[i], dtype=np.float32)
        sc_seq = np.full(cfg.vitals_seq_len, sym_ct[i], dtype=np.float32)
        vitals.append(np.stack([age_seq, sc_seq, hr, spo2], axis=-1).astype(np.float32))
    vitals = np.stack(vitals, axis=0)

    return text_emb, audio, vitals, y, class_to_idx


def prepare_dataloaders(cfg: SACAConfig):
    text_emb, audio, vitals, y, class_to_idx = build_arrays_from_csv(cfg)

    idx = np.arange(len(y))
    train_idx, val_idx = train_test_split(
        idx, test_size=cfg.val_size, random_state=cfg.random_state, stratify=y
    )

    x_text_train, x_audio_train, x_vitals_train, y_train = (
        text_emb[train_idx],
        audio[train_idx],
        vitals[train_idx],
        y[train_idx],
    )
    x_text_val, x_audio_val, x_vitals_val, y_val = (
        text_emb[val_idx],
        audio[val_idx],
        vitals[val_idx],
        y[val_idx],
    )

    y_train_before = y_train.copy()

    # Apply SMOTE to the training data
    x_text_train, x_audio_train, x_vitals_train, y_train = _apply_smote_multimodal(
        x_text_train, x_audio_train, x_vitals_train, y_train, cfg.random_state
    )

    train_ds = SACA_Dataset(x_text_train, x_audio_train, x_vitals_train, y_train)
    val_ds = SACA_Dataset(x_text_val, x_audio_val, x_vitals_val, y_val)

    train_loader = DataLoader(train_ds, batch_size=cfg.batch_size, shuffle=True)
    val_loader = DataLoader(val_ds, batch_size=cfg.batch_size, shuffle=False)

    severe_idx = class_to_idx.get(cfg.severe_class_name, 2)
    return (
        train_loader,
        val_loader,
        severe_idx,
        cfg.text_embedding_dim,
        y_train_before,
        y_train,
        class_to_idx,
    )


if __name__ == "__main__":
    cfg = SACAConfig()
    train_loader, val_loader, severe_idx, text_dim, y_train_before, y_train_after, class_to_idx = prepare_dataloaders(
        cfg
    )

    print("Preprocessing OK.")
    print(f"Class mapping: {class_to_idx}")
    unique_b, counts_b = np.unique(y_train_before, return_counts=True)
    print("Train counts before SMOTE:", {int(k): int(v) for k, v in zip(unique_b, counts_b)})
    unique_a, counts_a = np.unique(y_train_after, return_counts=True)
    print("Train counts after SMOTE:", {int(k): int(v) for k, v in zip(unique_a, counts_a)})
    batch = next(iter(train_loader))
    print("Batch shapes:", {k: tuple(v.shape) for k, v in batch.items()})
