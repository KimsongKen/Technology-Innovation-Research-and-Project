import pandas as pd
import numpy as np

# Load dataset - matches notebook
df = pd.read_csv("data/raw/saca_final_dataset_self.csv")

print("\n===== DATASET HEAD =====")
print(df.head())

print("\n===== DATASET SHAPE =====")
print(df.shape)

print("\n===== DATASET INFO =====")
df.info()

print("\n===== MISSING VALUES =====")
print(df.isnull().sum())

print("\n===== DUPLICATE ROWS =====")
print(df.duplicated().sum())

print("\n===== COLUMN NAMES =====")
print(df.columns.tolist())

print("\n===== DISEASE TARGET =====")
print("Target column:", "diseases")
print("Number of disease classes:", df["diseases"].nunique())
print(df["diseases"].value_counts().head(20))

print("\n===== SEVERITY TARGET =====")
print("Target column:", "Severity")
print(df["Severity"].value_counts())

# ===== EDA matching notebook =====
symptom_cols = [col for col in df.columns if col not in ['diseases', 'Severity']]

sparsity = (df[symptom_cols] == 0).mean().mean() * 100
print(f"\nSparsity (percentage of zeros in symptoms): {sparsity:.2f}%")

symptom_counts = df[symptom_cols].sum().sort_values(ascending=False)
print("\nTop 10 most common symptoms:")
print(symptom_counts.head(10))

print("\n10 rarest symptoms:")
print(symptom_counts.tail(10))

print("\n===== CLASS IMBALANCE CHECK =====")
counts = df['diseases'].value_counts()
print(f"Min samples per disease:        {counts.min()}")
print(f"Max samples per disease:        {counts.max()}")
print(f"Mean samples per disease:       {counts.mean():.1f}")
print(f"Diseases with < 10 samples:     {(counts < 10).sum()}")
print(f"Diseases with only 1 sample:    {(counts == 1).sum()}")

print("\n===== ZERO SYMPTOM PATIENTS =====")
symptoms_per_row = df[symptom_cols].sum(axis=1)
print(f"Avg symptoms per patient:   {symptoms_per_row.mean():.2f}")
print(f"Min symptoms per patient:   {symptoms_per_row.min()}")
print(f"Patients with 0 symptoms:   {(symptoms_per_row == 0).sum()}")

print("\n===== SEVERITY ORDER CHECK =====")
severity_map = {'Mild': 0, 'Moderate': 1, 'Severe': 2}
print(df['Severity'].map(severity_map).value_counts().sort_index())
print("Order confirmed: Mild=0, Moderate=1, Severe=2")

print("\n===== HIGH CORRELATION CHECK =====")
corr_matrix = df[symptom_cols].corr().abs()
upper = corr_matrix.where(
    np.triu(np.ones(corr_matrix.shape), k=1).astype(bool)
)
high_corr_count = (upper > 0.95).sum().sum()
print(f"Symptom pairs with >95% correlation: {high_corr_count}")

print("\n===== BINARY FEATURE CHECK =====")
non_binary = [col for col in symptom_cols
              if not df[col].isin([0, 1]).all()]
print(f"Non-binary symptom columns: {len(non_binary)}")
if non_binary:
    print("Columns with unexpected values:", non_binary)

