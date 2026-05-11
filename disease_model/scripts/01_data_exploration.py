import pandas as pd

# Load cleaned dataset
df = pd.read_csv("data/processed/cleaned_dataset.csv")

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