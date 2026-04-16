from __future__ import annotations

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F


def make_weighted_ce_weights(labels: np.ndarray, num_classes: int) -> torch.Tensor:
    counts = np.bincount(labels, minlength=num_classes).astype(np.float32)
    weights = counts.sum() / (num_classes * (counts + 1e-8))
    return torch.tensor(weights, dtype=torch.float32)


class F1RecallSafetyLoss(nn.Module):
    """
    Differentiable proxy that emphasizes Severe recall using an F_beta score.
    Using beta>1 weights recall higher than precision.
    """

    def __init__(self, severe_idx: int, beta: float = 2.0, eps: float = 1e-8):
        super().__init__()
        self.severe_idx = int(severe_idx)
        self.beta = float(beta)
        self.eps = float(eps)

    def forward(self, logits: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
        probs = torch.softmax(logits, dim=1)
        one_hot = F.one_hot(targets, num_classes=logits.size(1)).float()

        tp = (probs * one_hot).sum(dim=0)
        fp = (probs * (1 - one_hot)).sum(dim=0)
        fn = ((1 - probs) * one_hot).sum(dim=0)

        precision = tp / (tp + fp + self.eps)
        recall = tp / (tp + fn + self.eps)

        beta_sq = self.beta**2
        fbeta = (1 + beta_sq) * precision * recall / (beta_sq * precision + recall + self.eps)
        severe_fbeta = fbeta[self.severe_idx]
        return 1.0 - severe_fbeta
