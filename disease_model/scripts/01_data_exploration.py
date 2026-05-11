import pandas as pd

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