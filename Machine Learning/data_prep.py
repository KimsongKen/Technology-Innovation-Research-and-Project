from __future__ import annotations

import json
from pathlib import Path

import pandas as pd
from sklearn.model_selection import train_test_split


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_DATASET_PATH = PROJECT_ROOT / "archive" / "Model_catboost" / "saca_top40_dataset 1.csv"
OUTPUT_TEST_PATH = Path(__file__).resolve().parent / "standardized_test_set.csv"
SPLIT_META_PATH = Path(__file__).resolve().parent / "standardized_split_meta.json"


def create_standardized_test_set(
    dataset_path: Path = SOURCE_DATASET_PATH,
    output_test_path: Path = OUTPUT_TEST_PATH,
    split_meta_path: Path = SPLIT_META_PATH,
    test_size: float = 0.20,
    random_state: int = 42,
) -> pd.DataFrame:
    df = pd.read_csv(dataset_path)

    if "Severity" not in df.columns:
        raise ValueError("Expected 'Severity' column in dataset for stratified split.")

    indices = df.index.to_numpy()
    _, test_idx = train_test_split(
        indices,
        test_size=test_size,
        random_state=random_state,
        shuffle=True,
        stratify=df["Severity"],
    )

    test_df = df.loc[test_idx].copy().reset_index(drop=True)
    test_df.to_csv(output_test_path, index=False)

    split_meta = {
        "dataset_path": str(dataset_path),
        "test_size": test_size,
        "random_state": random_state,
        "stratify_column": "Severity",
        "test_indices": test_idx.tolist(),
        "n_total": int(len(df)),
        "n_test": int(len(test_df)),
    }
    split_meta_path.write_text(json.dumps(split_meta, indent=2), encoding="utf-8")

    return test_df


if __name__ == "__main__":
    out_df = create_standardized_test_set()
    print(f"Saved standardized test set to: {OUTPUT_TEST_PATH}")
    print(f"Saved split metadata to: {SPLIT_META_PATH}")
    print(f"Rows in standardized test set: {len(out_df)}")
