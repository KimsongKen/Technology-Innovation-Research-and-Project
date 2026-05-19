# Where to Get Warlpiri Speech Data — Round by Round

**The honest starting point:** There is no ready-to-download Warlpiri ASR dataset.  
This is a genuinely low-resource language. Every team working on Warlpiri NLP has faced this same wall.  
This document maps out every real avenue — what exists, who holds it, how to access it, and what you  
can generate synthetically to stretch small datasets further.

---

## The reality of Warlpiri digital resources

| Resource type | What exists | Publicly accessible? |
|---|---|---|
| Linguistic fieldwork recordings | Thousands of hours — held in archives | Restricted (community consent required) |
| Community radio broadcasts | Regular Warlpiri-language programming | Contact CAAMA/WMA directly |
| Bible / scripture text | Full NT translated to Warlpiri (text only, no audio) | Yes — text only |
| School language materials | Primers, story books (text + some audio) | Partly — contact NT Dept of Education |
| Dictionary audio | Some entries in the online Warlpiri dictionary | Limited, short clips |
| Academic ASR dataset | None published | Does not exist yet |

You will need to build your dataset. The question is who already has recordings you can partner with  
rather than starting from zero microphone time.

---

## Round 1 — Bootstrap (target: 1–3 hours)

### Source A: AIATSIS archive (most important first contact)

**What it is:** The Australian Institute of Aboriginal and Torres Strait Islander Studies holds the  
largest collection of Warlpiri recordings in existence — hours of linguistic fieldwork, oral histories,  
song, and conversation recorded since the 1960s.

**How to access:**
1. Go to the AIATSIS catalogue: `aiatsis.gov.au/collections/aiatsis-catalogue`
2. Search for "Warlpiri" — you will find hundreds of items
3. Most items are access-restricted (Indigenous Cultural and Intellectual Property rules)
4. You must submit a **formal access application** explaining:
   - What the recordings will be used for (clinical ASR)
   - Who will have access to the data
   - How the model and data will be stored and governed
   - Evidence of community consultation (see the ethics section in the fine-tune guide)
5. AIATSIS will refer your application to community representatives for approval
6. Processing time: 4–12 weeks

**Key contact:** collections@aiatsis.gov.au — explain it is a health application, this is prioritised.

**What you can realistically get:** 2–5 hours of usable speech in the first batch, subject to community  
approval. This is enough for Round 1.

---

### Source B: PARADISEC (Pacific and Regional Archive for Digital Sources in Endangered Cultures)

**What it is:** A Sydney-based digital archive with extensive Australian language recordings.  
Warlpiri recordings deposited by researchers (Ken Hale, Mary Laughren, Patrick McConvell and others).

**How to access:**
- Catalogue: `catalog.paradisec.org.au` — search "Warlpiri"
- Many items are open-access; others require a data agreement
- Contact: paradisec@paradisec.org.au
- Turnaround is typically faster than AIATSIS (1–3 weeks for open items)

**What you can realistically get:** 30 minutes–2 hours of elicited word-list and sentence recordings.  
Audio quality varies (older recordings may need noise reduction). Good for vocabulary coverage.

---

### Source C: Contact the key Warlpiri linguists directly

These researchers have decades of fieldwork recordings and are generally willing to collaborate on  
health-focused applications:

| Researcher | Institution | Specialisation |
|---|---|---|
| Professor Mary Laughren | University of Queensland | Warlpiri grammar, dictionary |
| Professor Jane Simpson | Australian National University | Warlpiri syntax, documentation |
| Dr Patrick McConvell | ANU / AIATSIS | Warlpiri and Gurindji |

Email them explaining the SACA project. Academic researchers often have recordings they cannot  
publish themselves but can share under a data agreement for a specific applied purpose like clinical care.  
Attach the ethics section from your community consent documentation.

**What you can realistically get:** Varies widely — possibly 1–4 hours of well-transcribed fieldwork data.

---

### Source D: Warlpiri community radio — CAAMA and Warlpiri Media Association

**What it is:**
- **CAAMA Radio** (caama.com.au) broadcasts from Alice Springs including Warlpiri-language programs
- **Warlpiri Media Association** (WMA) is community-owned media based in Yuendumu producing Warlpiri content

**How to access:**
- Contact WMA directly at Yuendumu: warlpirimediaassociation@gmail.com
- Explain the clinical purpose; ask whether archival radio recordings can be licensed for ASR training
- CAAMA: info@caama.com.au

**What you can realistically get:** Radio speech has good microphone quality but the domain is  
general conversation rather than clinical vocabulary. Useful for Round 1 prosody and fluency,  
less useful for domain-matched clinical terms.

---

### Source E: Data augmentation to multiply what you have

While you are waiting for archive access, you can augment a small seed dataset (even 30 minutes)  
to train a rough first model. This is not a substitute for real data, but it makes Round 1 possible  
faster.

Install:
```bash
pip install audiomentations torch-audiomentations
```

Augmentation script — `archive/warlpiri_finetune/augment.py`:

```python
"""
Augment a small Warlpiri seed corpus to increase training variety.
Each original clip produces 5–8 augmented versions.
Only apply to training split — never to validation or test.
"""
from __future__ import annotations

import csv
import hashlib
import numpy as np
import soundfile as sf
from pathlib import Path
from audiomentations import (
    Compose, AddGaussianNoise, TimeStretch, PitchShift,
    RoomSimulator, Gain, LowPassFilter, HighPassFilter,
)

TRAIN_META = "data/warlpiri_asr/metadata.csv"
AUG_OUT    = Path("data/warlpiri_asr/processed/train_augmented")
AUG_OUT.mkdir(parents=True, exist_ok=True)

# Clinical recording conditions vary — simulate them
augment_mild = Compose([
    AddGaussianNoise(min_amplitude=0.002, max_amplitude=0.010, p=0.5),
    Gain(min_gain_db=-3, max_gain_db=3, p=0.5),
    HighPassFilter(min_cutoff_freq=60, max_cutoff_freq=120, p=0.3),
])

augment_room = Compose([
    RoomSimulator(p=1.0),   # simulates clinic room acoustics
    AddGaussianNoise(min_amplitude=0.001, max_amplitude=0.005, p=0.3),
])

augment_speed = Compose([
    TimeStretch(min_rate=0.88, max_rate=1.12, p=1.0),  # speaker speed variation
    AddGaussianNoise(min_amplitude=0.001, max_amplitude=0.005, p=0.3),
])

augment_phone = Compose([
    LowPassFilter(min_cutoff_freq=3000, max_cutoff_freq=4000, p=1.0),  # phone/tablet mic
    AddGaussianNoise(min_amplitude=0.005, max_amplitude=0.020, p=0.5),
])

AUGMENTERS = [
    ("mild",  augment_mild),
    ("room",  augment_room),
    ("fast",  augment_speed),
    ("phone", augment_phone),
]

new_rows = []
for row in csv.DictReader(open(TRAIN_META, encoding="utf-8")):
    if row["split"] != "train":
        continue
    waveform, sr = sf.read(row["path"])
    waveform = waveform.astype(np.float32)
    for tag, aug in AUGMENTERS:
        augmented = aug(samples=waveform, sample_rate=sr)
        uid = hashlib.sha1(f"{row['path']}_{tag}".encode()).hexdigest()[:12]
        out_path = AUG_OUT / f"{uid}_{tag}.wav"
        sf.write(str(out_path), augmented, sr)
        new_rows.append({
            "path": str(out_path),
            "speaker_id": f"{row['speaker_id']}_aug_{tag}",
            "duration_s": row["duration_s"],
            "transcript": row["transcript"],
            "split": "train",
        })

# Append augmented rows to metadata
with open(TRAIN_META, "a", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["path", "speaker_id", "duration_s", "transcript", "split"])
    writer.writerows(new_rows)

print(f"Added {len(new_rows)} augmented clips")
```

**What augmentation gives you:**
- 30 minutes of real speech → ~2 hours of training data after augmentation
- Simulates room acoustics, phone mic quality, fast/slow speakers
- Does NOT invent new vocabulary — it only makes the model more robust to acoustic variation

---

### Source F: Warlpiri Bible text for language model rescoring (text only, no audio)

The Warlpiri New Testament (Palja Kurlangu Yimi) is available in digital text.  
This cannot be used to train the acoustic model but can train a character/word n-gram language model  
that rescores ASR hypotheses (see the KenLM section in `warlpiri_finetune_guide.md`).

**How to get it:**
- SIL International (sil.org) — Warlpiri language resources
- YouVersion Bible app has Warlpiri NT: bible.com (search "Warlpiri")
- Scripture Earth: scriptureearthly.org/Warlpiri

Download the text, clean it, and use it to train a 3-gram KenLM model. Even this small text corpus  
measurably improves WER by 3–8 percentage points on top of acoustic model output.

---

## Round 2 — Active learning (target: +3–7 hours on top of Round 1)

By this point you have a deployed model writing transcripts to `temp/transcript_audit/`.  
The most valuable data you can collect is the recordings where the model is wrong.

### Source A: Your own audit log

`temp/transcript_audit/transcript_audit.jsonl` contains every transcript the system has produced.  
Use this to find systematic errors:

```python
# archive/warlpiri_finetune/mine_errors.py
"""
Find audit log entries where raw_transcript and verified_transcript diverge significantly.
These are high-value correction candidates for Round 2 training.
"""
import json
import difflib
from pathlib import Path

AUDIT_DIR = Path("temp/transcript_audit")
MIN_ERROR_THRESHOLD = 0.3  # similarity below this = likely wrong

candidates = []
for jsonl in sorted(AUDIT_DIR.rglob("*.jsonl")):
    for line in jsonl.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        raw = record.get("raw_transcript", "")
        verified = record.get("verified_transcript", "")
        if not raw or not verified:
            continue
        similarity = difflib.SequenceMatcher(None, raw, verified).ratio()
        if similarity < MIN_ERROR_THRESHOLD:
            candidates.append({
                "audio_path": record.get("audio_path"),
                "raw": raw,
                "verified": verified,
                "similarity": round(similarity, 3),
                "timestamp": record.get("timestamp"),
            })

candidates.sort(key=lambda x: x["similarity"])
print(f"Found {len(candidates)} high-error transcripts")
for c in candidates[:20]:
    print(f"  {c['similarity']:.2f}  RAW: {c['raw'][:60]}")
    print(f"          VER: {c['verified'][:60]}")
```

Send the audio files for those high-error entries to community linguists for re-transcription.  
These corrected examples are gold — they target exactly where the model fails.

---

### Source B: Structured recording sessions with health workers

By Round 2 you have clinical partners (the health workers using SACA). Organise monthly  
30-minute recording sessions with Warlpiri health workers or interpreters:

**Session structure:**
- 10 minutes: read the clinical prompted phrases (same list as Round 1, different speakers)
- 10 minutes: describe symptoms in their own words (spontaneous)
- 10 minutes: role-play a triage conversation with a colleague

This is the highest-value data you can collect because it is domain-matched, naturally paced,  
and comes from speakers who actually use the system.

**Equipment needed:** A decent USB microphone (Audio-Technica AT2020 ~$100 AUD) and a laptop.  
No special studio required — a quiet office room works.

**Logistics:** Pay speakers at AHP (Aboriginal Health Practitioner) rates (~$45–60/hour AUD).  
Budget approximately $500–800 AUD for 10 recording sessions across Round 2.

---

### Source C: NT Department of Education — Warlpiri language programs

The NT Dept of Education runs Two-Way Learning programs in Warlpiri schools (Yuendumu,  
Lajamanu, Willowra). These programs have produced:
- Recorded Warlpiri story books read aloud
- Classroom audio with child and adult speakers
- Some digitised oral literature

**Contact:** NT Department of Education, Indigenous Languages and Culture unit  
education.nt.gov.au — request partnership for health-technology application.  
Children's speech has different acoustics from adult clinical speech; use it only for  
vocabulary coverage augmentation, not as the primary training set.

---

## Round 3 — Dialect expansion (target: +10–30 hours)

Warlpiri has four main dialect regions: Yuendumu, Lajamanu, Willowra, Nyirripi.  
The acoustic variation between them is significant enough that a model trained only on  
Yuendumu speakers will underperform on Lajamanu patients.

### Source A: Community-run recording drives

By Round 3 you should have a working model and demonstrated clinical value.  
This makes it easier to fund structured recording across all four communities.

**Funding avenues:**
- NHMRC (National Health and Medical Research Council) — digital health grants
- Medical Research Future Fund (MRFF) — Indigenous health priority stream
- NT PHN (Primary Health Network) — digital health innovation grants
- Lowitja Institute — Aboriginal and Torres Strait Islander health research

A grant application for Rounds 2–3 recording ($30,000–$80,000 AUD) is realistic once you  
have Round 1 results showing the model works.

### Source B: FRINGE (Field Recordings of Indigenous Languages for NLP and General Evaluation)

An emerging academic initiative collecting low-resource language data with community consent.  
Contact ANU's School of Literature, Languages and Linguistics to check if Warlpiri is in scope:  
linguistics.anu.edu.au

### Source C: Existing video content — Warlpiri Media Association

WMA produces documentary films and community news in Warlpiri.  
If they agree to license transcribed audio:
- Extract audio tracks
- Send to community linguists for timestamped transcription
- This gives you natural speech with good microphone quality

Video transcription is labour-intensive (~4–6 hours of linguist time per 1 hour of audio)  
but produces high-quality aligned data. Budget $200–300 AUD per hour of transcribed video.

---

## What to do right now (before any data arrives)

While waiting for archive approvals and community contacts, these steps cost nothing and  
can start immediately:

### Step 1 — Transfer learning from a related language

There is no Warlpiri ASR model, but there are ASR models for other Australian and  
agglutinative languages that share some acoustic properties.  
Pre-training on a related language before fine-tuning on Warlpiri gives a better starting  
point than the English-biased MMS checkpoint.

Candidate pre-training sources (publicly available, no special access required):

| Dataset | Language | Where to get |
|---|---|---|
| Common Voice (Catalan, Basque) | Agglutinative, similar consonant inventory | commonvoice.mozilla.org |
| FLEURS (Hawaiian) | Pacific region, some phonetic similarity | huggingface.co/datasets/google/fleurs |
| VoxPopuli (any low-resource) | Domain: formal speech | huggingface.co/datasets/facebook/voxpopuli |

This does not replace Warlpiri data but it warms up the model's phoneme representations  
before you introduce the first Warlpiri recordings.

### Step 2 — Build the text language model now

The Warlpiri New Testament and any other text you can collect can be used immediately  
to train a KenLM n-gram model — no audio required.  
This is the lowest-effort highest-return step available right now.

```bash
# Install KenLM
pip install https://github.com/kpu/kenlm/archive/master.zip

# Collect text into a single file, one sentence per line
# Then train:
lmplz -o 5 < data/warlpiri_asr/text_corpus.txt > data/warlpiri_asr/warlpiri_5gram.arpa
build_binary data/warlpiri_asr/warlpiri_5gram.arpa data/warlpiri_asr/warlpiri_5gram.binary
```

### Step 3 — Write the AIATSIS access application

Draft the application before any other technical work. It is on the critical path — the  
archive review process is the longest lead time in Round 1, often 6–12 weeks.  
Every week you delay starting the application is a week added to your data gap.

Template email for the first contact:

---

> Subject: AIATSIS Access Application — Warlpiri Speech Data for Clinical ASR Research
>
> Dear AIATSIS Collections team,
>
> I am writing on behalf of [your institution/organisation] to request access to Warlpiri  
> language recordings in the AIATSIS archive for use in developing a clinical voice triage  
> system (SACA — Smart Adaptive Clinical Assistant).
>
> SACA is a bilingual English/Warlpiri speech recognition system designed to assist  
> Aboriginal Health Practitioners in the Northern Territory to triage patients presenting  
> with medical symptoms. Accurate Warlpiri speech recognition is critical to the clinical  
> safety of this system.
>
> We are seeking access to:
> - Recordings of natural Warlpiri speech (conversational and elicited)
> - Associated transcripts where available
> - Recordings that cover clinical vocabulary (symptoms, body parts, descriptions of pain)
>
> We commit to:
> - Community governance of all data under a formal data agreement
> - Restriction of access to named research team members only
> - No public publication of recordings or derived embeddings without community consent
> - Return of the fine-tuned model to community ownership
> - Compliance with the AIATSIS Code of Ethics (2020)
>
> We have [or: are in the process of establishing] community consultation with [Warlpiri  
> council / health organisation].
>
> Please advise on the application process and any additional requirements.
>
> [Your name, institution, contact]

---

## Summary: practical sequence

| Week | Action | Cost |
|---|---|---|
| Week 1 | Send AIATSIS application email | Free |
| Week 1 | Email Mary Laughren and Jane Simpson | Free |
| Week 1 | Download Warlpiri NT text, train KenLM | Free |
| Week 1–2 | Contact WMA and CAAMA | Free |
| Week 2 | Contact PARADISEC for open-access items | Free |
| Week 2 | Set up augmentation pipeline (for when seed data arrives) | Free |
| Week 6–12 | AIATSIS approval received, first recordings arrive | Archive access |
| Week 8+ | First community recording sessions with health workers | ~$500–800 AUD |
| Month 4+ | Round 1 model trained and in gated pilot | Training compute |
| Month 6+ | Active learning loop running from audit logs | Ongoing |
| Month 9+ | Grant application for Round 3 expansion | ~$50–80k AUD |

The most common mistake teams make is waiting until they have "enough data" before  
starting community conversations. Start the conversations in Week 1 — the data follows  
the relationships, not the other way around.
