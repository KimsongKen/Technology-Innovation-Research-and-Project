# Fine-Tuning a Speech Recognition Model for Warlpiri (wbp)

**Target:** Replace the `facebook/mms-1b-all` fallback adapter with a Warlpiri-specific ASR checkpoint  
**Base model options:** `facebook/mms-1b-all` (recommended) or `facebook/wav2vec2-large-xlsr-53`  
**Framework:** Hugging Face `transformers` + `datasets`  
**Integration point:** `api/bridge/warlpiri_stt.py` — drop the fine-tuned model path into `SACA_MMS_MODEL_ID`

---

## Table of Contents

1. [Why fine-tuning is necessary](#1-why-fine-tuning-is-necessary)
2. [Ethical and community obligations](#2-ethical-and-community-obligations)
3. [Data collection strategy](#3-data-collection-strategy)
4. [Data preparation pipeline](#4-data-preparation-pipeline)
5. [Environment setup](#5-environment-setup)
6. [Tokenizer and processor preparation](#6-tokenizer-and-processor-preparation)
7. [Dataset loading and preprocessing](#7-dataset-loading-and-preprocessing)
8. [Fine-tuning with Hugging Face Trainer](#8-fine-tuning-with-hugging-face-trainer)
9. [Evaluating the model](#9-evaluating-the-model)
10. [Integrating into SACA](#10-integrating-into-saca)
11. [Iterative improvement](#11-iterative-improvement)
12. [Minimum viable dataset targets](#12-minimum-viable-dataset-targets)

---

## 1. Why fine-tuning is necessary

`facebook/mms-1b-all` covers ~1,100 languages but Warlpiri (`wbp`) has **no validated adapter** in the public checkpoint. The current code tries `wbp` first, then falls back to `pjt` (Pitjantjatjara) — a related but distinct Australian language. Using a wrong-language adapter in a clinical triage system is dangerous: medical terms get mangled, severity keywords get dropped, and the system silently produces plausible-looking but incorrect transcripts.

Fine-tuning on even a small Warlpiri corpus (2–5 hours) will dramatically outperform the `pjt` fallback.

---

## 2. Ethical and community obligations

Working with an indigenous Australian language requires explicit community consent and data governance agreements **before** any recording begins. This is non-negotiable and also improves data quality.

### Required steps before collecting any data

1. **Contact the Warlpiri community first.** The primary governance bodies are:
   - Warlpiri Education and Training Trust (WETT)
   - Central Land Council (CLC), Northern Territory
   - Yuendumu, Lajamanu, Willowra, and Nyirripi community councils

2. **Follow AIATSIS (Australian Institute of Aboriginal and Torres Strait Islander Studies) data protocols:**
   - AIATSIS Code of Ethics for Aboriginal and Torres Strait Islander Research (2020)
   - All recordings are owned by the community, not the project
   - Data must be stored on community-controlled or Australian-sovereign infrastructure
   - Community members must be able to request deletion at any time

3. **Establish a data agreement** covering:
   - Who can access the recordings (researchers, model trainers, clinicians)
   - Whether the fine-tuned model can be published publicly or must remain private
   - Revenue or benefit sharing if the system is commercialised
   - Attribution and acknowledgement requirements

4. **Recruit community linguists or language workers** as co-investigators — they verify transcription accuracy and flag culturally sensitive terms that should not appear in training data.

5. **Compensate speakers fairly** at professional rates, not as volunteers.

> A model built without community consent cannot be used in clinical care and may violate the Privacy Act 1988 and the NT Information Act 2002.

---

## 3. Data collection strategy

### 3.1 Target speakers

Prioritise speakers who:
- Are fluent first-language speakers (ideally L1 rather than L2)
- Span ages (older speakers often have different phonology)
- Include both male and female voices
- Include speakers across the four main Warlpiri communities (dialectal variation exists)

Minimum recommended: **20 unique speakers** for a first usable model.

### 3.2 Recording content

For a clinical ASR model you need domain-matched speech. Record in three categories:

**Category A — Clinical prompted speech (highest priority)**  
Read-aloud prompts of medical phrases translated into Warlpiri by community health workers and linguists. Covers the vocabulary the model will actually encounter.

Example prompts to translate and record:
```
"I have chest pain"
"I cannot breathe properly"
"I have a fever and cough"
"My child has a seizure"
"I feel dizzy and want to vomit"
"I have been bleeding for a long time"
"My head hurts badly"
"I am very weak"
```

**Category B — Natural conversational speech**  
Spontaneous conversation between community members about health topics, daily activities, and family. This teaches the model prosody, connected speech, and natural word boundaries.

**Category C — Elicited word lists**  
Individual words: body parts, symptoms, place names, common verbs. Useful for vocabulary coverage even though isolated words sound different from connected speech.

### 3.3 Recording conditions

| Parameter | Requirement |
|---|---|
| Microphone | Close-talk headset (SM10A or similar) preferred; lapel acceptable |
| Sample rate | 44.1 kHz or 48 kHz (downsample to 16 kHz during preprocessing) |
| Bit depth | 24-bit |
| Environment | Quiet indoor space; record ambient noise sample for spectral subtraction |
| Format | WAV (lossless); never MP3 for training data |
| Session length | 30–60 minutes per speaker, multiple sessions better than one long session |

### 3.4 Data volume targets

| Hours of audio | Expected WER improvement | Notes |
|---|---|---|
| < 1 hour | Marginal | Too little to beat `pjt` fallback reliably |
| 1–3 hours | Significant | Clinically usable for high-frequency terms |
| 3–10 hours | Strong | Recommended minimum for deployment |
| 10–50 hours | Excellent | Comparable to well-resourced language ASR |
| > 50 hours | Production-grade | Unlikely to be achievable in phase 1 |

Even 3 hours of high-quality, domain-matched speech with accurate transcripts will outperform the current fallback by a large margin.

---

## 4. Data preparation pipeline

### 4.1 Directory layout

```
data/warlpiri_asr/
├── raw/                  # original recordings from field sessions
│   ├── speaker_001/
│   │   ├── session_01_clinical.wav
│   │   └── session_01_clinical.txt   # verbatim Warlpiri transcript
│   └── speaker_002/
├── processed/            # 16 kHz mono segments after splitting
│   ├── train/
│   ├── validation/
│   └── test/
├── metadata.csv          # path, speaker_id, duration_s, transcript, split
└── vocab.json            # character vocabulary for the tokenizer
```

### 4.2 Audio preprocessing script

Save as `archive/warlpiri_finetune/prepare_audio.py`:

```python
"""
Segment long recordings into short clips (3–15 s) aligned with transcript sentences.
Run once per speaker session.
"""
from __future__ import annotations

import csv
import hashlib
import re
import wave
from pathlib import Path

import numpy as np

RAW_DIR = Path("data/warlpiri_asr/raw")
OUT_DIR = Path("data/warlpiri_asr/processed")
SAMPLE_RATE = 16000
MIN_DURATION_S = 1.5
MAX_DURATION_S = 15.0


def resample_to_16k(waveform: np.ndarray, orig_sr: int) -> np.ndarray:
    if orig_sr == SAMPLE_RATE:
        return waveform
    target_len = int(len(waveform) * SAMPLE_RATE / orig_sr)
    idx = np.linspace(0, len(waveform) - 1, target_len)
    left = np.floor(idx).astype(np.int64)
    right = np.minimum(left + 1, len(waveform) - 1)
    frac = (idx - left).astype(np.float32)
    return (waveform[left] * (1 - frac) + waveform[right] * frac).astype(np.float32)


def read_wav_float32(path: Path) -> tuple[np.ndarray, int]:
    with wave.open(str(path), "rb") as wf:
        sr = wf.getframerate()
        sw = wf.getsampwidth()
        ch = wf.getnchannels()
        raw = wf.readframes(wf.getnframes())
    if sw == 2:
        arr = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    elif sw == 3:
        b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
        i32 = b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16)
        i32 = np.where(i32 >= 0x800000, i32 - 0x1000000, i32)
        arr = i32.astype(np.float32) / 8388608.0
    else:
        arr = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    if ch > 1:
        arr = arr.reshape(-1, ch).mean(axis=1)
    return arr, sr


def save_wav_16k(waveform: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.clip(waveform * 32767, -32768, 32767).astype(np.int16)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(pcm.tobytes())


def clean_transcript(text: str) -> str:
    """Lowercase, remove punctuation except apostrophes (common in Warlpiri orthography)."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s']", "", text)
    text = re.sub(r"\s+", " ", text)
    return text


def segment_by_transcript(wav_path: Path, txt_path: Path, speaker_id: str, split: str) -> list[dict]:
    """
    txt_path: plain text, one sentence per line, matching audio sentence boundaries.
    Assumes sentences are evenly spaced (good for prompted speech).
    For spontaneous speech, use a tool like WebMAUS or Audacity labels instead.
    """
    waveform, sr = read_wav_float32(wav_path)
    waveform = resample_to_16k(waveform, sr)
    
    sentences = [clean_transcript(ln) for ln in txt_path.read_text(encoding="utf-8").splitlines() if ln.strip()]
    if not sentences:
        return []
    
    total_samples = len(waveform)
    samples_per_sentence = total_samples // len(sentences)
    
    rows = []
    for i, sentence in enumerate(sentences):
        start = i * samples_per_sentence
        end = min(start + samples_per_sentence, total_samples)
        clip = waveform[start:end]
        duration = len(clip) / SAMPLE_RATE
        if duration < MIN_DURATION_S or duration > MAX_DURATION_S:
            continue
        
        uid = hashlib.sha1(f"{speaker_id}_{i}_{sentence}".encode()).hexdigest()[:12]
        out_path = OUT_DIR / split / f"{uid}.wav"
        save_wav_16k(clip, out_path)
        
        rows.append({
            "path": str(out_path),
            "speaker_id": speaker_id,
            "duration_s": round(duration, 2),
            "transcript": sentence,
            "split": split,
        })
    return rows


def build_metadata(train_ratio: float = 0.85, val_ratio: float = 0.10) -> None:
    all_rows: list[dict] = []
    for spk_dir in sorted(RAW_DIR.iterdir()):
        if not spk_dir.is_dir():
            continue
        speaker_id = spk_dir.name
        for wav_path in sorted(spk_dir.glob("*.wav")):
            txt_path = wav_path.with_suffix(".txt")
            if not txt_path.exists():
                print(f"  WARNING: no transcript for {wav_path.name} — skipping")
                continue
            # Assign split deterministically from speaker hash so the same
            # speaker is never in both train and test sets.
            h = int(hashlib.md5(speaker_id.encode()).hexdigest(), 16) % 100
            split = "train" if h < train_ratio * 100 else ("validation" if h < (train_ratio + val_ratio) * 100 else "test")
            rows = segment_by_transcript(wav_path, txt_path, speaker_id, split)
            all_rows.extend(rows)
            print(f"  {speaker_id}/{wav_path.name}: {len(rows)} segments → {split}")
    
    meta_path = Path("data/warlpiri_asr/metadata.csv")
    with meta_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["path", "speaker_id", "duration_s", "transcript", "split"])
        writer.writeheader()
        writer.writerows(all_rows)
    
    totals = {}
    for row in all_rows:
        totals[row["split"]] = totals.get(row["split"], 0) + 1
    print(f"\nDone. {len(all_rows)} total segments: {totals}")
    print(f"Total audio: {sum(r['duration_s'] for r in all_rows) / 3600:.2f} hours")


if __name__ == "__main__":
    build_metadata()
```

### 4.3 Building the character vocabulary

Warlpiri uses a Latin-based orthography. The vocabulary must include all characters found in your transcripts, plus special CTC tokens.

```python
# archive/warlpiri_finetune/build_vocab.py
import json
import csv
from pathlib import Path
from collections import Counter

meta = list(csv.DictReader(open("data/warlpiri_asr/metadata.csv", encoding="utf-8")))
char_counter: Counter = Counter()
for row in meta:
    char_counter.update(list(row["transcript"]))

# Remove space (handled separately as word boundary token)
char_counter.pop(" ", None)

vocab = {ch: i for i, ch in enumerate(sorted(char_counter))}
vocab["[UNK]"] = len(vocab)
vocab["[PAD]"] = len(vocab)  # CTC blank token — must be last

Path("data/warlpiri_asr/vocab.json").write_text(
    json.dumps(vocab, ensure_ascii=False, indent=2), encoding="utf-8"
)
print(f"Vocabulary size: {len(vocab)} characters")
print("Characters:", sorted(char_counter.keys()))
```

Expected Warlpiri characters include: `a b d g i j k l m n p r rd rl rn rr rt u w y` plus vowel length markers.  
Note: some digraphs (`rd`, `rl`, `rn`, `rt`) represent single phonemes — if your orthography uses them, keep them as two characters in the vocab and let the model learn the sequence.

---

## 5. Environment setup

```bash
# Create a dedicated training environment (separate from the API venv)
python -m venv .venv_train
source .venv_train/bin/activate        # Linux/Mac
# .venv_train\Scripts\activate          # Windows

pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install transformers==4.40.0
pip install datasets==2.19.0
pip install accelerate==0.29.0
pip install evaluate jiwer            # WER/CER metrics
pip install soundfile librosa         # audio I/O
pip install tensorboard               # training curves
```

GPU requirement: fine-tuning `mms-1b-all` needs at least **16 GB VRAM** (e.g. RTX 3090, A10G).  
If you only have a smaller GPU (8 GB), use `facebook/wav2vec2-base` instead — lower accuracy ceiling but trainable on modest hardware.  
If you have no local GPU, use Google Colab Pro+ (A100, ~40 GB VRAM) or AWS `g5.2xlarge`.

---

## 6. Tokenizer and processor preparation

```python
# archive/warlpiri_finetune/build_processor.py
"""
Build and save the Wav2Vec2 processor (feature extractor + tokenizer) for Warlpiri.
Run once before training.
"""
import json
from pathlib import Path
from transformers import Wav2Vec2CTCTokenizer, Wav2Vec2FeatureExtractor, Wav2Vec2Processor

VOCAB_PATH = "data/warlpiri_asr/vocab.json"
PROCESSOR_DIR = "data/warlpiri_asr/processor"

# Tokenizer from our Warlpiri character vocabulary
tokenizer = Wav2Vec2CTCTokenizer(
    VOCAB_PATH,
    unk_token="[UNK]",
    pad_token="[PAD]",
    word_delimiter_token="|",   # pipe = word boundary in Wav2Vec2 convention
)

# Feature extractor — same for all Wav2Vec2/MMS models
feature_extractor = Wav2Vec2FeatureExtractor(
    feature_size=1,
    sampling_rate=16000,
    padding_value=0.0,
    do_normalize=True,
    return_attention_mask=True,
)

processor = Wav2Vec2Processor(
    feature_extractor=feature_extractor,
    tokenizer=tokenizer,
)
processor.save_pretrained(PROCESSOR_DIR)
print(f"Processor saved to {PROCESSOR_DIR}")
print(f"Vocab size: {tokenizer.vocab_size}")
```

---

## 7. Dataset loading and preprocessing

```python
# archive/warlpiri_finetune/dataset_loader.py
"""
Load metadata CSV into a Hugging Face Dataset, attach audio arrays,
and apply the processor to produce input_values + labels.
"""
from __future__ import annotations

import csv
import re
import numpy as np
import soundfile as sf
from datasets import Dataset, DatasetDict, Audio
from transformers import Wav2Vec2Processor

PROCESSOR_DIR = "data/warlpiri_asr/processor"
META_PATH = "data/warlpiri_asr/metadata.csv"


def load_split(split: str) -> Dataset:
    rows = [r for r in csv.DictReader(open(META_PATH, encoding="utf-8")) if r["split"] == split]
    return Dataset.from_dict({
        "path": [r["path"] for r in rows],
        "transcript": [r["transcript"] for r in rows],
        "speaker_id": [r["speaker_id"] for r in rows],
    })


def prepare_datasets() -> DatasetDict:
    processor = Wav2Vec2Processor.from_pretrained(PROCESSOR_DIR)

    def load_audio(batch: dict) -> dict:
        waveform, sr = sf.read(batch["path"])
        if sr != 16000:
            # librosa resample as fallback
            import librosa
            waveform = librosa.resample(waveform, orig_sr=sr, target_sr=16000)
        batch["audio_array"] = waveform.astype(np.float32)
        return batch

    def preprocess(batch: dict) -> dict:
        # Feature extraction
        inputs = processor(
            batch["audio_array"],
            sampling_rate=16000,
            return_tensors="np",
            padding=False,
        )
        batch["input_values"] = inputs.input_values[0]
        batch["attention_mask"] = inputs.attention_mask[0]

        # Label encoding — replace space with pipe (word boundary token)
        text = batch["transcript"].replace(" ", "|")
        with processor.as_target_processor():
            batch["labels"] = processor(text).input_ids
        return batch

    raw = DatasetDict({
        "train": load_split("train"),
        "validation": load_split("validation"),
        "test": load_split("test"),
    })

    processed = raw.map(load_audio, num_proc=4)
    processed = processed.map(preprocess, remove_columns=["path", "audio_array"], num_proc=4)
    return processed
```

---

## 8. Fine-tuning with Hugging Face Trainer

Save as `archive/warlpiri_finetune/train.py`:

```python
"""
Fine-tune facebook/mms-1b-all on Warlpiri speech data.

Key hyperparameters to tune:
  - learning_rate: start at 1e-4, reduce if loss explodes
  - num_train_epochs: 30–100 depending on dataset size
  - per_device_train_batch_size: reduce if OOM (use gradient_accumulation_steps to compensate)

Usage:
  python archive/warlpiri_finetune/train.py
"""
from __future__ import annotations

import re
import numpy as np
import torch
from dataclasses import dataclass
from typing import Any

import evaluate
from transformers import (
    Wav2Vec2ForCTC,
    Wav2Vec2Processor,
    TrainingArguments,
    Trainer,
    EarlyStoppingCallback,
)

from dataset_loader import prepare_datasets

# ── Config ─────────────────────────────────────────────────────────────────

BASE_MODEL   = "facebook/mms-1b-all"  # swap for wav2vec2-base if low VRAM
PROCESSOR_DIR = "data/warlpiri_asr/processor"
OUTPUT_DIR   = "data/warlpiri_asr/checkpoints"
FINAL_DIR    = "data/warlpiri_asr/warlpiri_mms_finetuned"

# ── Processor & model ───────────────────────────────────────────────────────

processor = Wav2Vec2Processor.from_pretrained(PROCESSOR_DIR)

model = Wav2Vec2ForCTC.from_pretrained(
    BASE_MODEL,
    attention_dropout=0.1,
    hidden_dropout=0.1,
    feat_proj_dropout=0.0,
    mask_time_prob=0.05,       # SpecAugment — mask 5% of time steps
    layerdrop=0.1,
    ctc_loss_reduction="mean",
    pad_token_id=processor.tokenizer.pad_token_id,
    vocab_size=processor.tokenizer.vocab_size,
    ignore_mismatched_sizes=True,  # replaces the MMS head with our Warlpiri vocab head
)

# Freeze the feature extractor — only fine-tune transformer layers and the new head.
# Unfreeze all layers only if you have > 10 hours of data.
model.freeze_feature_extractor()

# ── Data collator ──────────────────────────────────────────────────────────

@dataclass
class DataCollatorCTCWithPadding:
    processor: Wav2Vec2Processor
    padding: bool | str = True

    def __call__(self, features: list[dict[str, Any]]) -> dict[str, torch.Tensor]:
        input_features = [{"input_values": f["input_values"]} for f in features]
        label_features = [{"input_ids": f["labels"]} for f in features]

        batch = self.processor.pad(
            input_features,
            padding=self.padding,
            return_tensors="pt",
        )
        with self.processor.as_target_processor():
            labels_batch = self.processor.pad(
                label_features,
                padding=self.padding,
                return_tensors="pt",
            )

        # Replace padding id with -100 so CTC loss ignores them
        labels = labels_batch["input_ids"].masked_fill(
            labels_batch.attention_mask.ne(1), -100
        )
        batch["labels"] = labels
        return batch


data_collator = DataCollatorCTCWithPadding(processor=processor, padding=True)

# ── Metrics ────────────────────────────────────────────────────────────────

wer_metric = evaluate.load("wer")
cer_metric = evaluate.load("cer")

def compute_metrics(pred) -> dict:
    pred_logits = pred.predictions
    pred_ids = np.argmax(pred_logits, axis=-1)
    pred.label_ids[pred.label_ids == -100] = processor.tokenizer.pad_token_id

    pred_str  = processor.batch_decode(pred_ids)
    label_str = processor.batch_decode(pred.label_ids, group_tokens=False)

    # Remove the pipe word-boundary token before scoring
    pred_str  = [s.replace("|", " ").strip() for s in pred_str]
    label_str = [s.replace("|", " ").strip() for s in label_str]

    wer = wer_metric.compute(predictions=pred_str, references=label_str)
    cer = cer_metric.compute(predictions=pred_str, references=label_str)
    return {"wer": round(wer, 4), "cer": round(cer, 4)}

# ── Training arguments ─────────────────────────────────────────────────────

training_args = TrainingArguments(
    output_dir=OUTPUT_DIR,
    group_by_length=True,           # batch similar-length sequences → fewer padding tokens
    per_device_train_batch_size=8,  # reduce to 4 if OOM
    gradient_accumulation_steps=2,  # effective batch = 16
    evaluation_strategy="epoch",
    save_strategy="epoch",
    num_train_epochs=60,
    fp16=torch.cuda.is_available(),
    learning_rate=1e-4,
    warmup_ratio=0.1,
    lr_scheduler_type="cosine",
    save_total_limit=3,
    load_best_model_at_end=True,
    metric_for_best_model="wer",
    greater_is_better=False,
    logging_steps=50,
    dataloader_num_workers=4,
    report_to=["tensorboard"],
    push_to_hub=False,              # set True + hub_model_id to publish privately
)

# ── Dataset ────────────────────────────────────────────────────────────────

datasets = prepare_datasets()

# ── Trainer ────────────────────────────────────────────────────────────────

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=datasets["train"],
    eval_dataset=datasets["validation"],
    tokenizer=processor.feature_extractor,
    data_collator=data_collator,
    compute_metrics=compute_metrics,
    callbacks=[EarlyStoppingCallback(early_stopping_patience=8)],
)

trainer.train()

# Save final model + processor together
trainer.save_model(FINAL_DIR)
processor.save_pretrained(FINAL_DIR)
print(f"\nFine-tuned model saved to: {FINAL_DIR}")
```

### Training monitoring

```bash
# In a separate terminal while training runs
tensorboard --logdir data/warlpiri_asr/checkpoints/runs

# Watch WER drop per epoch — a healthy run looks like:
# Epoch 5:  WER 0.85   (model is learning character shapes)
# Epoch 20: WER 0.55   (word boundaries emerging)
# Epoch 40: WER 0.30   (clinical terms becoming consistent)
# Epoch 60: WER 0.15–0.25  (plateau for 3-5 hour dataset)
```

---

## 9. Evaluating the model

```python
# archive/warlpiri_finetune/evaluate_warlpiri.py
"""
Full evaluation on the held-out test set.
Run after training completes.
"""
from __future__ import annotations

import csv
import torch
import numpy as np
import soundfile as sf
import evaluate
from pathlib import Path
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor

MODEL_DIR = "data/warlpiri_asr/warlpiri_mms_finetuned"
META_PATH  = "data/warlpiri_asr/metadata.csv"

processor = Wav2Vec2Processor.from_pretrained(MODEL_DIR)
model     = Wav2Vec2ForCTC.from_pretrained(MODEL_DIR).eval()
device    = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

wer_metric = evaluate.load("wer")
cer_metric = evaluate.load("cer")

test_rows = [r for r in csv.DictReader(open(META_PATH, encoding="utf-8")) if r["split"] == "test"]

all_refs, all_hyps = [], []
errors: list[dict] = []

for row in test_rows:
    waveform, sr = sf.read(row["path"])
    if sr != 16000:
        import librosa
        waveform = librosa.resample(waveform, orig_sr=sr, target_sr=16000)
    
    inputs = processor(waveform.astype(np.float32), sampling_rate=16000, return_tensors="pt").to(device)
    with torch.inference_mode():
        logits = model(**inputs).logits
    ids = torch.argmax(logits, dim=-1)
    hyp = processor.batch_decode(ids)[0].replace("|", " ").strip()
    ref = row["transcript"]
    
    all_refs.append(ref)
    all_hyps.append(hyp)
    
    word_errors = wer_metric.compute(predictions=[hyp], references=[ref])
    if word_errors > 0.3:
        errors.append({"ref": ref, "hyp": hyp, "wer": round(word_errors, 3), "path": row["path"]})

wer = wer_metric.compute(predictions=all_hyps, references=all_refs)
cer = cer_metric.compute(predictions=all_hyps, references=all_refs)

print(f"\n=== Test Set Results ===")
print(f"  Samples : {len(test_rows)}")
print(f"  WER     : {wer:.4f}  ({wer*100:.1f}%)")
print(f"  CER     : {cer:.4f}  ({cer*100:.1f}%)")
print(f"\n--- Worst predictions (WER > 30%) ---")
for e in sorted(errors, key=lambda x: -x["wer"])[:10]:
    print(f"  REF: {e['ref']}")
    print(f"  HYP: {e['hyp']}")
    print(f"  WER: {e['wer']}  [{Path(e['path']).name}]")
    print()
```

### Interpreting results

| WER | Interpretation for clinical use |
|---|---|
| < 10% | Excellent — deploy with confidence |
| 10–25% | Good — review high-severity transcripts manually |
| 25–40% | Marginal — usable with human-in-the-loop verification |
| > 40% | Not ready — collect more data or check transcript quality |

For a clinical triage system, **CER < 15%** is a reasonable deployment threshold since the symptom keyword extraction (`clinical_text.py`) and Warlpiri dictionary bridge can still recover the key terms even with some character errors.

---

## 10. Integrating into SACA

Once you have a fine-tuned checkpoint at `data/warlpiri_asr/warlpiri_mms_finetuned/`:

### Step 1 — Point the env var at the new model

In `run_api.ps1` (or your `.env`):

```powershell
$env:SACA_MMS_MODEL_ID = "data/warlpiri_asr/warlpiri_mms_finetuned"
$env:SACA_USE_MMS_WARLPIRI_STT = "1"
$env:SACA_MMS_ADAPTER_CHAIN = ""   # clear this — fine-tuned model has no adapters
```

### Step 2 — Update `warlpiri_stt.py` to skip adapter loading

The fine-tuned model has its Warlpiri head baked in — it does not use adapter swapping. Add a config flag to bypass the adapter chain:

In `api/bridge/config.py`, add:
```python
mms_is_finetuned: bool = os.getenv("SACA_MMS_IS_FINETUNED", "0") in {"1", "true", "yes"}
```

In `api/bridge/warlpiri_stt.py`, update `_ensure_mms_model_and_device()`:
```python
def _ensure_mms_model_and_device() -> None:
    global _processor, _model, _loaded_adapter

    if not CFG.use_mms_warlpiri_stt:
        raise RuntimeError("MMS Warlpiri STT is disabled.")

    import torch
    from transformers import AutoProcessor, Wav2Vec2ForCTC

    if _model is None:
        logger.info("Loading MMS ASR model_id=%s (finetuned=%s)", CFG.mms_model_id, CFG.mms_is_finetuned)
        _processor = AutoProcessor.from_pretrained(CFG.mms_model_id)
        _model = Wav2Vec2ForCTC.from_pretrained(CFG.mms_model_id)
        _model.eval()
        _loaded_adapter = "finetuned" if CFG.mms_is_finetuned else None

    device = torch.device("cuda" if CFG.mms_device == "cuda" and torch.cuda.is_available() else "cpu")
    _model.to(device)
```

And update `_ensure_mms_adapter()` to skip adapter loading when fine-tuned:
```python
def _ensure_mms_adapter() -> str:
    global _active_mms_adapter
    with _lock:
        _ensure_mms_model_and_device()
        if CFG.mms_is_finetuned:
            _active_mms_adapter = "wbp-finetuned"
            return "wbp-finetuned"
        # ... existing adapter chain logic ...
```

### Step 3 — Set the env var and restart

```powershell
$env:SACA_MMS_IS_FINETUNED = "1"
.\run_api.ps1 -WarlpiriMms
```

### Step 4 — Smoke test

```powershell
# Play a Warlpiri test recording through the API
.\test_api.ps1 -AudioFile "data/warlpiri_asr/processed/test/some_clip.wav" -Language "wbp"
```

Compare the transcript against the known reference. Check that clinical symptom keywords are correctly transcribed.

---

## 11. Iterative improvement

Fine-tuning is not a one-time event. Plan for multiple rounds:

### Round 1 (bootstrap)
- 2–3 hours prompted clinical speech
- Target: WER < 40%, CER < 20%
- Ship as a gated feature — human review required before triage action

### Round 2 (active learning)
- Collect the transcripts the model got wrong (from `transcript_audit.jsonl`)
- Have community linguists correct them
- Re-train adding corrected examples to the training set
- Target: WER < 25%

### Round 3 (domain expansion)
- Add spontaneous conversational speech
- Add recordings from additional communities (dialect coverage)
- Optionally unfreeze all model layers for end-to-end fine-tuning (needs > 10 h data)
- Target: WER < 15%

### Language model rescoring (advanced)
If you have enough Warlpiri text (community newsletters, Bible translations, linguistic field notes), train an n-gram language model and use it to rescore Wav2Vec2 beam search candidates:

```bash
pip install pyctcdecode kenlm
```

```python
from pyctcdecode import build_ctcdecoder

# vocab must match the processor vocab
vocab_list = [v for v, _ in sorted(processor.tokenizer.get_vocab().items(), key=lambda x: x[1])]
decoder = build_ctcdecoder(
    vocab_list,
    kenlm_model="data/warlpiri_asr/warlpiri_5gram.arpa",  # trained KenLM model
    alpha=0.5,   # LM weight
    beta=1.0,    # word insertion penalty
)

# Replace torch.argmax decoding in warlpiri_stt.py:
logits_np = logits[0].cpu().numpy()
text = decoder.decode(logits_np)
```

A 3-gram or 5-gram KenLM model trained on even 500 KB of Warlpiri text will measurably improve WER on unseen clinical phrases.

---

## 12. Minimum viable dataset targets

| Milestone | Audio hours | Unique speakers | Expected WER | Clinical readiness |
|---|---|---|---|---|
| Proof of concept | 1 h | 5+ | ~50% | Internal testing only |
| Gated clinical pilot | 3 h | 15+ | ~30% | Human-reviewed triage |
| Supervised deployment | 8 h | 25+ | ~18% | High-severity auto-escalation safe |
| Full deployment | 20 h+ | 40+ | ~10% | All triage levels |

Start recording as soon as community consent is in place. Even a proof-of-concept model validates the pipeline and gives the community something tangible to evaluate before committing to a larger recording effort.

---

## Quick reference — file paths in SACA

| File | Role in fine-tuning |
|---|---|
| `api/bridge/warlpiri_stt.py` | Model loading, inference — update `_ensure_mms_model_and_device` |
| `api/bridge/config.py` | Add `mms_is_finetuned` env var |
| `api/bridge/warlpiri_dict.py` | Post-processing — still active after fine-tuning to normalise clinical terms |
| `archive/warlpiri_finetune/prepare_audio.py` | (new) Audio segmentation |
| `archive/warlpiri_finetune/build_vocab.py` | (new) Character vocabulary |
| `archive/warlpiri_finetune/build_processor.py` | (new) Processor setup |
| `archive/warlpiri_finetune/dataset_loader.py` | (new) HF Dataset pipeline |
| `archive/warlpiri_finetune/train.py` | (new) Training loop |
| `archive/warlpiri_finetune/evaluate_warlpiri.py` | (new) WER/CER evaluation |
| `data/warlpiri_asr/` | (new) All audio data, metadata, checkpoints |
