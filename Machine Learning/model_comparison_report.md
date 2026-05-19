# SACA Model Evaluation Report (CatBoost vs ExtraNGvboost)

## Evaluation Setup

- Test data source: `archive/Model_catboost/saca_top40_dataset 1.csv`
- Standardized hold-out split: 20% test set, fixed random seed 42, stratified by `Severity`
- Both models were evaluated on the exact same `standardized_test_set.csv`
- Targets evaluated: `diseases` and `Severity`

### Disease Prediction Metrics

| Model | Accuracy | Precision (Macro) | Recall (Macro) | F1 (Macro) | Precision (Weighted) | Recall (Weighted) | F1 (Weighted) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ExtraNGvboost | 0.9678 | 0.9668 | 0.9675 | 0.9669 | 0.9683 | 0.9678 | 0.9678 |
| CatBoost | 0.9647 | 0.9669 | 0.9621 | 0.9635 | 0.9652 | 0.9647 | 0.9641 |

### Severity Prediction Metrics

| Model | Accuracy | Precision (Macro) | Recall (Macro) | F1 (Macro) | Precision (Weighted) | Recall (Weighted) | F1 (Weighted) | Recall (Severe Class) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ExtraNGvboost | 0.9781 | 0.9772 | 0.9777 | 0.9774 | 0.9781 | 0.9781 | 0.9781 | 0.9786 |
| CatBoost | 0.9767 | 0.9772 | 0.9731 | 0.9751 | 0.9768 | 0.9767 | 0.9767 | 0.9889 |

## Winners

- **Disease Winner:** `ExtraNGvboost`
- **Severity Winner:** `CatBoost`

## Why These Winners

- **Disease:** ExtraNGvboost is selected because it has the highest weighted F1 (0.9678) and strong macro F1 (0.9669) on disease classes.
- **Severity:** CatBoost is selected because it achieves the best Severe recall (0.9889) while also maintaining competitive weighted F1 (0.9767).

## Clinical Safety Note

The `Recall (Severe Class)` metric is the most clinically sensitive signal here. A lower value means more truly severe patients are being missed.
