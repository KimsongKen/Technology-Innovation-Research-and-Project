# Swin SACA (Smart Adaptive Clinical Assistant)

Clinical triage support for the Yuendumu community. Swin SACA is designed to prioritize **high recall (sensitivity)** for **Severe** presentations to support medical safety in remote settings.

The long-term product concept combines:
- **Warlpiri voice** (spoken symptoms and urgency cues)
- **Visual icons** (low-literacy friendly symptom and severity selection)
- **Clinical vitals** (age, symptom count, heart rate, SpO\(_2\), and future sensors)

## Architecture summary (Late Fusion)

Swin SACA follows a **late-fusion multimodal** design where each modality is encoded independently and fused near the classifier:

- **NLP branch (Sentence Transformers / SBERT)**  
  Converts symptom text (and later Warlpiri transcripts) into a dense embedding vector.

- **Acoustic branch (1D-CNN)**  
  Models urgency-related audio cues (placeholder vectors now; later audio features/waveforms).

- **Clinical branch (LSTM)**  
  Models vitals/sensor trends over time (placeholder sequences now; supports future streaming sensors).

The three modality embeddings are **concatenated** and passed through a **3-layer MLP classifier** to predict triage severity: **Mild / Moderate / Severe**.

## Repository structure

```text
data/                 # healthcare_dataset.csv and future raw audio/sensors
src/                  # core source code
  data_loader/         # preprocessing + dataset creation
  models/              # model architectures
  utils/               # losses + metrics
configs/              # config files (SACAConfig)
output/               # saved models, logs, SHAP visualizations
train.py              # main entry point (training start commented for review)
requirements.txt
README.md
```

## Setup

Create a Python environment (3.10+ recommended) and install dependencies:

```bash
pip install -r requirements.txt
```

Place your dataset at:
- `data/healthcare_dataset.csv`

## Preprocessing

Run preprocessing to validate schema, create severity labels, split train/val, and apply SMOTE to the training split:

```bash
python -m src.data_loader.preprocessing
```

This produces an in-memory dataset pipeline (and prints basic stats). It is intentionally conservative and uses placeholders for SBERT embeddings and audio/vitals where your future data streams will be integrated.

## Training (intentionally not started yet)

The `train.py` entry point wires:
- `SACAConfig`
- **Weighted Cross-Entropy** (class imbalance)
- **F1/Recall safety loss** (focus on Severe recall)
- training/validation loops

But the **actual training call is commented out** for architectural review.

```bash
python train.py
```

## Notes on safety objective

This project is optimized for medical safety in remote areas:
- **Primary objective**: maximize recall for the **Severe** class (reduce false negatives).
- **Secondary objective**: maintain reasonable precision and stability across Mild/Moderate.

