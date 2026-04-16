from __future__ import annotations

from dataclasses import dataclass


@dataclass
class SACAConfig:
    # Data
    csv_path: str = "data/healthcare_dataset.csv"
    val_size: float = 0.2
    random_state: int = 42

    # Modalities (placeholders now; swap in real pipelines later)
    text_model_name: str = "all-MiniLM-L6-v2"
    use_sbert: bool = False
    text_embedding_dim: int = 384

    audio_seq_len: int = 128
    vitals_seq_len: int = 12

    # Training
    batch_size: int = 32
    learning_rate: float = 1e-3
    num_epochs: int = 20

    # Model
    num_classes: int = 3
    fusion_dim: int = 128
    mlp_hidden_mult: int = 2
    dropout: float = 0.3

    # Loss blending (safety emphasis on Severe recall)
    ce_weight: float = 0.7
    f1_weight: float = 0.3
    severe_class_name: str = "Severe"
