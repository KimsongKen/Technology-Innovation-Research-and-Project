"""
SACA — Text Input Modality
Project  : Swin Smart Adaptive Clinical Assistant (SACA)
Community: Warlpiri Yuendumu, NT, Australia
Dataset  : saca_final_dataset_self.csv (29,995 rows x 256 columns)
Task     : Classify patient symptoms -> Mild / Moderate / Severe
Model    : Random Forest + HistGradientBoosting (soft-vote ensemble)
"""

# =============================================================
# Step 1 — Import Libraries
# =============================================================
# pip install scikit-learn pandas numpy matplotlib seaborn joblib skl2onnx onnx onnxruntime

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
import warnings
warnings.filterwarnings('ignore')

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.ensemble import (
    RandomForestClassifier,
    HistGradientBoostingClassifier,
    VotingClassifier,
)
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    recall_score,
    confusion_matrix,
    precision_score,
    f1_score,
)

print('Libraries imported successfully')

# =============================================================
# Step 2 — Load Dataset
# =============================================================
# Make sure saca_final_dataset_self.csv is in the same folder

df = pd.read_csv('saca_final_dataset_self.csv')

print(f'Shape     : {df.shape}')
print(f'Missing   : {df.isnull().sum().sum()}')
print(f'Duplicates: {df.duplicated().sum()}')
print(df.head())

# =============================================================
# Step 3 — Exploratory Data Analysis (EDA)
# =============================================================

# 3a. Severity distribution
print('\n=== Severity Distribution ===')
print(df['Severity'].value_counts())

colors = ['#2ecc71', '#f39c12', '#e74c3c']
plt.figure(figsize=(7, 4))
df['Severity'].value_counts().reindex(['Mild', 'Moderate', 'Severe']).plot(
    kind='bar', color=colors, edgecolor='white'
)
plt.title('Severity Class Distribution')
plt.xlabel('Severity')
plt.ylabel('Count')
plt.xticks(rotation=0)
plt.tight_layout()
plt.savefig('severity_distribution.png', dpi=150)
plt.show()

# 3b. Top 20 most frequent symptoms
sym_cols = [c for c in df.columns if c not in ['diseases', 'Severity']]
sym_freq = df[sym_cols].sum().sort_values(ascending=False)

print(f'\nTotal symptom features: {len(sym_cols)}')
print(f'\nTop 10 symptoms:')
print(sym_freq.head(10))

plt.figure(figsize=(14, 5))
sym_freq.head(20).plot(kind='bar', color='steelblue')
plt.title('Top 20 Most Frequent Symptoms')
plt.xlabel('Symptom')
plt.ylabel('Count')
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.savefig('top20_symptoms.png', dpi=150)
plt.show()

# 3c. Symptoms per row distribution
df['symptom_count'] = df[sym_cols].sum(axis=1)

print('\n=== Symptoms per Row ===')
print(df['symptom_count'].describe().round(2))

plt.figure(figsize=(8, 4))
df['symptom_count'].hist(bins=12, color='steelblue', edgecolor='white')
plt.title('Number of Symptoms per Patient Record')
plt.xlabel('Symptom Count')
plt.ylabel('Frequency')
plt.tight_layout()
plt.savefig('symptom_count_distribution.png', dpi=150)
plt.show()

df = df.drop(columns=['symptom_count'])

# 3d. Disease distribution (top 15)
print('\n=== Top 15 Diseases ===')
print(df['diseases'].value_counts().head(15))
print(f'\nTotal unique diseases: {df["diseases"].nunique()}')

# =============================================================
# Step 4 — Feature & Label Preparation
# =============================================================

# Feature matrix X: 254 symptom one-hot columns
sym_cols = [c for c in df.columns if c not in ['diseases', 'Severity']]
X = df[sym_cols].values.astype(np.float32)

# Target y: Mild=0, Moderate=1, Severe=2
le = LabelEncoder()
y  = le.fit_transform(df['Severity'])

print(f'\nFeature matrix : {X.shape}')
print(f'Label map      : {dict(zip(le.classes_, le.transform(le.classes_)))}')
print(f'Class counts   : {dict(zip(*np.unique(y, return_counts=True)))}')

# =============================================================
# Step 5 — Train / Test Split
# NOTE: Always split before training.
#       Test set uses real data only — no augmentation.
# =============================================================

X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y        # preserve class ratio in both splits
)

print(f'\nTraining set : {X_train.shape}')
print(f'Test set     : {X_test.shape}')
print('\nTest set class distribution:')
for cls, idx in zip(le.classes_, range(3)):
    print(f'  {cls}: {(y_test == idx).sum()}')

# =============================================================
# Step 6 — Model Training
# Random Forest + HistGradientBoosting soft-vote ensemble
# - Random Forest   : robust with high-dimensional one-hot features
# - HistGradientBoosting : equivalent to XGBoost, ONNX-compatible
# - Soft voting     : outputs probability vectors for multi-modal fusion
# =============================================================

# Random Forest
rf = RandomForestClassifier(
    n_estimators=100,
    class_weight='balanced',   # handles class imbalance automatically
    max_depth=20,
    random_state=42,
    n_jobs=-1,                 # use all CPU cores
)

# HistGradientBoosting (sklearn's XGBoost equivalent)
hgbm = HistGradientBoostingClassifier(
    max_iter=100,
    learning_rate=0.1,
    max_depth=6,
    random_state=42,
)

# Soft-voting ensemble
# voting='soft' outputs probability vectors
# -> used for multi-modal fusion (Text + Voice + Image)
ensemble = VotingClassifier(
    estimators=[('rf', rf), ('hgbm', hgbm)],
    voting='soft',
    weights=np.array([1, 1]),
)

print('\nTraining Random Forest + HistGBM ensemble...')
ensemble.fit(X_train, y_train)
print('Training complete!')

# =============================================================
# Step 7 — Evaluation
# =============================================================

y_pred     = ensemble.predict(X_test)
severe_idx = list(le.classes_).index('Severe')

sr  = recall_score(y_test, y_pred, labels=[severe_idx], average=None)[0]
acc = accuracy_score(y_test, y_pred)

print('\n=== Classification Report ===')
print(classification_report(y_test, y_pred, target_names=le.classes_))
print(f'Severe Recall   : {sr:.4f}  (target >= 0.90)')
print(f'Overall Accuracy: {acc:.4f}')
print(f'Target met: {"YES" if sr >= 0.90 else "NO — needs tuning"}')

# Confusion Matrix heatmap
cm = confusion_matrix(y_test, y_pred)

plt.figure(figsize=(7, 5))
sns.heatmap(
    cm,
    annot=True, fmt='d',
    xticklabels=le.classes_,
    yticklabels=le.classes_,
    cmap='Blues'
)
plt.title('Confusion Matrix — SACA Text Modality')
plt.xlabel('Predicted Label')
plt.ylabel('True Label')
plt.tight_layout()
plt.savefig('confusion_matrix.png', dpi=150)
plt.show()

# Per-class metrics bar chart
summary = pd.DataFrame({
    'Precision': precision_score(y_test, y_pred, average=None),
    'Recall'   : recall_score(y_test, y_pred, average=None),
    'F1-Score' : f1_score(y_test, y_pred, average=None),
}, index=le.classes_).round(4)

print('\n=== Per-Class Metrics ===')
print(summary)

summary.plot(kind='bar', figsize=(8, 4), colormap='Set2', edgecolor='white')
plt.title('Precision / Recall / F1 by Severity Class')
plt.xlabel('Severity')
plt.xticks(rotation=0)
plt.ylim(0.8, 1.0)
plt.legend(loc='lower right')
plt.tight_layout()
plt.savefig('per_class_metrics.png', dpi=150)
plt.show()

# =============================================================
# Step 8 — Save Model (.pkl)
# =============================================================

joblib.dump(ensemble, 'saca_text_model.pkl')
joblib.dump(le,       'label_encoder.pkl')
joblib.dump(sym_cols, 'symptom_columns.pkl')

print('\nSaved:')
print('   saca_text_model.pkl   — trained RF + HistGBM ensemble')
print('   label_encoder.pkl     — Mild / Moderate / Severe decoder')
print('   symptom_columns.pkl   — 254 symptom column names & order')

# =============================================================
# Step 9 — ONNX Export (Flutter Offline Deployment)
# Exports two separate ONNX files (VotingClassifier not directly
# supported by skl2onnx — export each model individually)
# =============================================================

try:
    from skl2onnx import convert_sklearn
    from skl2onnx.common.data_types import FloatTensorType

    n_features   = X_train.shape[1]
    initial_type = [('symptom_input', FloatTensorType([None, n_features]))]

    # Export Random Forest model
    rf_model = ensemble.estimators_[0]
    onnx_rf  = convert_sklearn(
        rf_model,
        initial_types=initial_type,
        options={'zipmap': False},
    )
    with open('saca_rf_model.onnx', 'wb') as f:
        f.write(onnx_rf.SerializeToString())
    print('RF ONNX exported: saca_rf_model.onnx')

    # Export HistGradientBoosting model
    hgbm_model = ensemble.estimators_[1]
    onnx_hgbm  = convert_sklearn(
        hgbm_model,
        initial_types=initial_type,
        options={'zipmap': False},
    )
    with open('saca_hgbm_model.onnx', 'wb') as f:
        f.write(onnx_hgbm.SerializeToString())
    print('HGBM ONNX exported: saca_hgbm_model.onnx')

    print(f'\n   Input  : [batch, {n_features}]  — symptom one-hot vector')
    print(f'   Output : [batch, 3]             — Mild / Moderate / Severe')
    print(f'\n   Flutter: average probabilities from both models')

except ImportError:
    print('Run: pip install skl2onnx onnx')
except Exception as e:
    print(f'ONNX export failed: {e}')

# =============================================================
# Step 10 — Inference Demo
# =============================================================

# Synonym mapping table
# Maps common user input terms to dataset column names
SYNONYM_MAP = {
    # Chest
    'chest pain'            : 'sharp chest pain',
    'chest hurt'            : 'sharp chest pain',
    'chest hurts'           : 'sharp chest pain',
    'heart pain'            : 'sharp chest pain',
    'chest discomfort'      : 'chest tightness',

    # Vision
    'blurred vision'        : 'diminished vision',
    'blurry vision'         : 'diminished vision',
    'cant see clearly'      : 'diminished vision',
    "can't see clearly"     : 'diminished vision',
    'vision problems'       : 'diminished vision',
    'seeing double'         : 'double vision',

    # Breathing
    'breathless'            : 'shortness of breath',
    "can't breathe"         : 'shortness of breath',
    'cant breathe'          : 'shortness of breath',
    'difficulty breathing'  : 'shortness of breath',
    'hard to breathe'       : 'shortness of breath',
    'breathing difficulty'  : 'shortness of breath',

    # Stomach / Abdomen
    'stomach pain'          : 'sharp abdominal pain',
    'stomach ache'          : 'sharp abdominal pain',
    'stomachache'           : 'sharp abdominal pain',
    'tummy ache'            : 'sharp abdominal pain',
    'belly pain'            : 'sharp abdominal pain',
    'abdominal pain'        : 'sharp abdominal pain',

    # Nausea / Vomiting
    'feel sick'             : 'nausea',
    'feeling sick'          : 'nausea',
    'throwing up'           : 'vomiting',
    'threw up'              : 'vomiting',
    'puking'                : 'vomiting',

    # Heart
    'heart racing'          : 'increased heart rate',
    'racing heart'          : 'increased heart rate',
    'fast heartbeat'        : 'increased heart rate',
    'heart pounding'        : 'palpitations',
    'pounding heart'        : 'palpitations',
    'heart fluttering'      : 'irregular heartbeat',
    'slow heartbeat'        : 'decreased heart rate',

    # Head
    'head pain'             : 'headache',
    'migraine'              : 'headache',
    'head hurts'            : 'headache',

    # Throat / Nose
    'runny nose'            : 'nasal congestion',
    'blocked nose'          : 'nasal congestion',
    'stuffy nose'           : 'nasal congestion',
    'throat pain'           : 'sore throat',
    'throat hurts'          : 'sore throat',

    # Skin
    'skin rash'             : 'skin rash',
    'rash'                  : 'skin rash',
    'itchy skin'            : 'itching of skin',
    'skin itching'          : 'itching of skin',

    # General
    'tired'                 : 'fatigue',
    'exhausted'             : 'fatigue',
    'weak'                  : 'weakness',
    'dizzy'                 : 'dizziness',
    'lightheaded'           : 'dizziness',
    'sweat'                 : 'sweating',
    'chills'                : 'chills',
    'shivering'             : 'chills',
    'no appetite'           : 'decreased appetite',
    'loss of appetite'      : 'decreased appetite',
    'weight loss'           : 'recent weight loss',
    'losing weight'         : 'recent weight loss',
    'swollen'               : 'skin swelling',
    'swelling'              : 'skin swelling',
    'back pain'             : 'back pain',
    'joint pain'            : 'joint pain',
    'muscle pain'           : 'muscle pain',
    'muscle ache'           : 'muscle pain',
    'body ache'             : 'ache all over',
    'constipation'          : 'constipation',
    'diarrhea'              : 'diarrhea',
    'loose stool'           : 'diarrhea',
    'frequent urination'    : 'frequent urination',
    'painful urination'     : 'painful urination',
    'burning urination'     : 'painful urination',
    'cant sleep'            : 'insomnia',
    "can't sleep"           : 'insomnia',
    'nervous'               : 'anxiety and nervousness',
    'anxiety'               : 'anxiety and nervousness',
    'depressed'             : 'depression',
    'seizure'               : 'seizures',
    'fit'                   : 'seizures',
    'confused'              : 'altered sensorium',
    'confusion'             : 'altered sensorium',
    'memory loss'           : 'disturbance of memory',
    'forgetful'             : 'disturbance of memory',
    'numb'                  : 'loss of sensation',
    'numbness'              : 'loss of sensation',
}

# Load saved model files
loaded_model    = joblib.load('saca_text_model.pkl')
loaded_le       = joblib.load('label_encoder.pkl')
loaded_sym_cols = joblib.load('symptom_columns.pkl')


def predict_severity(symptom_list: list) -> dict:
    """
    Predict severity from a list of symptom strings.
    Applies synonym mapping before matching to dataset columns.

    Args:
        symptom_list: e.g. ['chest pain', 'fever', 'shortness of breath']

    Returns:
        dict with severity, confidence, suggestion, and probabilities
    """
    # Build one-hot input vector
    x       = np.zeros((1, len(loaded_sym_cols)), dtype=np.float32)
    matched = []
    unmatch = []

    for sym in symptom_list:
        sym_clean  = sym.strip().lower()
        # Apply synonym mapping — convert user input to dataset column name
        sym_mapped = SYNONYM_MAP.get(sym_clean, sym_clean)
        if sym_mapped in loaded_sym_cols:
            x[0, loaded_sym_cols.index(sym_mapped)] = 1.0
            matched.append(sym_mapped)
        else:
            unmatch.append(sym_clean)

    # Run model prediction
    proba      = loaded_model.predict_proba(x)[0]
    label      = loaded_le.classes_[np.argmax(proba)]
    confidence = float(np.max(proba))

    # Confidence-based suggestion for the user
    if confidence >= 0.80:
        suggestion = 'High confidence — result is reliable'
    elif confidence >= 0.60:
        suggestion = 'Moderate confidence — consider adding more symptoms'
    else:
        suggestion = 'Low confidence — please add more symptoms (recommended: 5-6)'

    # Symptom count hint to guide user input
    n_symptoms = len(matched)
    if n_symptoms < 3:
        symptom_hint = f'Only {n_symptoms} symptom(s) matched — more symptoms will improve accuracy'
    elif n_symptoms < 4:
        symptom_hint = f'{n_symptoms} symptoms matched — adding 1-2 more may increase confidence'
    else:
        symptom_hint = f'{n_symptoms} symptoms matched — sufficient for reliable prediction'

    return {
        'severity'      : label,
        'confidence'    : round(confidence, 3),
        'matched_syms'  : matched,
        'unmatched_syms': unmatch,
        'probabilities' : {
            cls: round(float(p), 3)
            for cls, p in zip(loaded_le.classes_, proba)
        },
        'suggestion'    : suggestion,
        'symptom_hint'  : symptom_hint,
    }


# Test cases — different symptom counts
test_cases = [
    # Few symptoms -> low confidence
    ['sharp chest pain'],
    # Medium symptoms
    ['shortness of breath', 'sharp chest pain', 'fever'],
    # Sufficient symptoms -> high confidence
    ['sharp chest pain', 'shortness of breath', 'fever',
     'increased heart rate', 'sweating', 'weakness'],
    # Mild case
    ['sore throat', 'cough', 'nasal congestion', 'sneezing'],
    # All synonyms input
    ["can't breathe", 'chest pain', 'heart racing', 'dizzy', 'sweating'],
]

for symptoms in test_cases:
    result = predict_severity(symptoms)
    print(f"Input       : {', '.join(symptoms)}")
    print(f"Severity    : {result['severity']}  (confidence: {result['confidence']})")
    print(f"Suggestion  : {result['suggestion']}")
    print(f"Symptom hint: {result['symptom_hint']}")
    print(f"Probs       : {result['probabilities']}")
    print()

# =============================================================
# Step 11 — Verify ONNX Files
# =============================================================

import onnx
import onnxruntime as ort

# Verify RF model
rf_onnx = onnx.load('saca_rf_model.onnx')
onnx.checker.check_model(rf_onnx)
print('RF model valid')

sess_rf = ort.InferenceSession('saca_rf_model.onnx')
x_test  = np.zeros((1, 254), dtype=np.float32)
out_rf  = sess_rf.run(None, {'symptom_input': x_test})
print(f'RF output shape: {out_rf[1].shape}')
print(f'RF sample probs: {out_rf[1][0]}')

# Verify HGBM model
hgbm_onnx = onnx.load('saca_hgbm_model.onnx')
onnx.checker.check_model(hgbm_onnx)
print('\nHGBM model valid')

sess_hgbm = ort.InferenceSession('saca_hgbm_model.onnx')
out_hgbm  = sess_hgbm.run(None, {'symptom_input': x_test})
print(f'HGBM output shape: {out_hgbm[1].shape}')
print(f'HGBM sample probs: {out_hgbm[1][0]}')
