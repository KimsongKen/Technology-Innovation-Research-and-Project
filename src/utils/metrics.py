from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional

import numpy as np
import torch


@dataclass
class EvalResult:
    accuracy: float
    macro_f1: float
    severe_recall: float
    severe_precision: float


def _safe_div(n: float, d: float, eps: float = 1e-12) -> float:
    return float(n) / float(d + eps)


def classification_report_from_logits(
    logits: torch.Tensor,
    targets: torch.Tensor,
    severe_idx: int,
) -> EvalResult:
    preds = torch.argmax(logits, dim=1).detach().cpu().numpy().astype(int)
    y = targets.detach().cpu().numpy().astype(int)

    acc = float((preds == y).mean()) if len(y) else 0.0

    num_classes = int(max(preds.max(initial=0), y.max(initial=0)) + 1) if len(y) else 0
    f1s = []
    for c in range(num_classes):
        tp = int(((preds == c) & (y == c)).sum())
        fp = int(((preds == c) & (y != c)).sum())
        fn = int(((preds != c) & (y == c)).sum())
        precision = _safe_div(tp, tp + fp)
        recall = _safe_div(tp, tp + fn)
        f1 = _safe_div(2 * precision * recall, precision + recall)
        f1s.append(f1)

    macro_f1 = float(np.mean(f1s)) if f1s else 0.0

    s = int(severe_idx)
    tp_s = int(((preds == s) & (y == s)).sum())
    fp_s = int(((preds == s) & (y != s)).sum())
    fn_s = int(((preds != s) & (y == s)).sum())
    severe_precision = _safe_div(tp_s, tp_s + fp_s)
    severe_recall = _safe_div(tp_s, tp_s + fn_s)

    return EvalResult(
        accuracy=acc,
        macro_f1=macro_f1,
        severe_recall=severe_recall,
        severe_precision=severe_precision,
    )


def as_dict(res: EvalResult) -> Dict[str, float]:
    return {
        "accuracy": float(res.accuracy),
        "macro_f1": float(res.macro_f1),
        "severe_recall": float(res.severe_recall),
        "severe_precision": float(res.severe_precision),
    }
