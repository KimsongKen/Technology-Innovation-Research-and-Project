from __future__ import annotations

from typing import Optional, Tuple

import torch
import torch.nn as nn


class NLPBranch(nn.Module):
    """
    Integration point for Sentence Transformers.

    Training code currently passes precomputed/placeholder embeddings (text_emb).
    Later you can swap this to encode raw strings externally or in a wrapper.
    """

    def __init__(self, text_dim: int, fusion_dim: int, dropout: float):
        super().__init__()
        self.proj = nn.Sequential(
            nn.Linear(text_dim, fusion_dim),
            nn.ReLU(),
            nn.Dropout(dropout),
        )

    def forward(self, text_emb: torch.Tensor) -> torch.Tensor:
        return self.proj(text_emb)


class AcousticCNN1D(nn.Module):
    def __init__(self, out_dim: int, dropout: float):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv1d(1, 32, kernel_size=5, padding=2),
            nn.ReLU(),
            nn.MaxPool1d(kernel_size=2),
            nn.Conv1d(32, 64, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.MaxPool1d(kernel_size=2),
            nn.Conv1d(64, 128, kernel_size=3, padding=1),
            nn.ReLU(),
            nn.AdaptiveAvgPool1d(1),
        )
        self.head = nn.Sequential(
            nn.Flatten(),
            nn.Dropout(dropout),
            nn.Linear(128, out_dim),
        )

    def forward(self, audio: torch.Tensor) -> torch.Tensor:
        x = self.features(audio)
        return self.head(x)


class ClinicalLSTM(nn.Module):
    def __init__(
        self,
        input_size: int,
        hidden_size: int,
        num_layers: int,
        out_dim: int,
        dropout: float,
    ):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0,
        )
        self.proj = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(hidden_size, out_dim),
        )

    def forward(self, vitals: torch.Tensor) -> torch.Tensor:
        _, (h_n, _) = self.lstm(vitals)
        last_hidden = h_n[-1]
        return self.proj(last_hidden)


class MultimodalLateFusionModel(nn.Module):
    """
    Late fusion:
      - NLP: SBERT embeddings -> projection
      - Audio: 1D-CNN -> embedding
      - Clinical: LSTM -> embedding
      - Fusion: concat -> 3-layer MLP classifier
    """

    def __init__(
        self,
        text_dim: int,
        vitals_feature_dim: int,
        fusion_dim: int,
        num_classes: int,
        dropout: float = 0.3,
        lstm_hidden_size: int = 64,
        lstm_layers: int = 1,
        mlp_hidden_mult: int = 2,
    ):
        super().__init__()
        self.nlp = NLPBranch(text_dim=text_dim, fusion_dim=fusion_dim, dropout=dropout)
        self.acoustic = AcousticCNN1D(out_dim=fusion_dim, dropout=dropout)
        self.clinical = ClinicalLSTM(
            input_size=vitals_feature_dim,
            hidden_size=lstm_hidden_size,
            num_layers=lstm_layers,
            out_dim=fusion_dim,
            dropout=dropout,
        )

        fused_dim = fusion_dim * 3
        h1 = fusion_dim * mlp_hidden_mult
        h2 = fusion_dim * mlp_hidden_mult
        self.classifier = nn.Sequential(
            nn.Linear(fused_dim, h1),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(h1, h2),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(h2, num_classes),
        )

    def forward(
        self,
        text_emb: torch.Tensor,
        audio: torch.Tensor,
        vitals: torch.Tensor,
    ) -> torch.Tensor:
        t = self.nlp(text_emb)
        a = self.acoustic(audio)
        c = self.clinical(vitals)
        fused = torch.cat([t, a, c], dim=-1)
        logits = self.classifier(fused)
        return logits

