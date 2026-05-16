import os
import json
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import joblib

# =========================
# 0. Output folder guard
# =========================

os.makedirs("reports", exist_ok=True)
os.makedirs("models", exist_ok=True)

print("\n===== SACA MODEL VISUALISATION =====")
print("Generating charts for report...\n")


# =========================
# 1. Disease Model Comparison Chart
# =========================

print("Generating Chart 1: Disease Model Comparison...")

models_disease  = ['Decision Tree\n(Baseline)', 'LightGBM', 'CatBoost']
f1_disease      = [0.72, 0.869, 0.902]
colors_disease  = ['#d9534f', '#f0ad4e', '#5cb85c']

fig, ax = plt.subplots(figsize=(9, 6))

bars = ax.bar(models_disease, f1_disease, color=colors_disease,
              edgecolor='white', linewidth=1.5, width=0.5)

# Add value labels on bars
for bar, val in zip(bars, f1_disease):
    ax.text(
        bar.get_x() + bar.get_width() / 2,
        bar.get_height() + 0.005,
        f'{val*100:.1f}%',
        ha='center', va='bottom',
        fontsize=13, fontweight='bold'
    )

# Highlight best model
bars[2].set_edgecolor('#2d6a2d')
bars[2].set_linewidth(3)

ax.set_title('Disease Prediction — Model Comparison\n(181 Disease Classes)',
             fontsize=14, fontweight='bold', pad=15)
ax.set_ylabel('Weighted F1-Score', fontsize=12)
ax.set_ylim(0, 1.05)
ax.set_yticks(np.arange(0, 1.1, 0.1))
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.0%}'))
ax.axhline(y=0.9, color='green', linestyle='--', linewidth=1, alpha=0.5,
           label='90% threshold')
ax.grid(axis='y', alpha=0.3, linestyle='--')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

best_patch = mpatches.Patch(color='#5cb85c', label='Best Model: CatBoost (90.2%)')
ax.legend(handles=[best_patch], loc='lower right', fontsize=10)

plt.tight_layout()
plt.savefig('reports/01_disease_model_comparison.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: reports/01_disease_model_comparison.png")


# =========================
# 2. Severity Model Comparison Chart
# =========================

print("Generating Chart 2: Severity Model Comparison...")

models_severity  = ['LightGBM', 'CatBoost']
f1_severity      = [0.9602, 0.9295]
recall_severity  = [0.9733, 0.9300]
colors_sev       = ['#5cb85c', '#f0ad4e']

x     = np.arange(len(models_severity))
width = 0.35

fig, ax = plt.subplots(figsize=(9, 6))

bars_f1     = ax.bar(x - width/2, f1_severity,     width,
                     label='Weighted F1',    color='#5b9bd5', edgecolor='white')
bars_recall = ax.bar(x + width/2, recall_severity, width,
                     label='Severe Recall',  color='#ed7d31', edgecolor='white')

# Value labels
for bar in bars_f1:
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.003,
            f'{bar.get_height()*100:.1f}%',
            ha='center', va='bottom', fontsize=11, fontweight='bold')

for bar in bars_recall:
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.003,
            f'{bar.get_height()*100:.1f}%',
            ha='center', va='bottom', fontsize=11, fontweight='bold')

ax.set_title('Severity Classification — Model Comparison\n(Mild / Moderate / Severe)',
             fontsize=14, fontweight='bold', pad=15)
ax.set_ylabel('Score', fontsize=12)
ax.set_xticks(x)
ax.set_xticklabels(models_severity, fontsize=12)
ax.set_ylim(0.85, 1.02)
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.0%}'))
ax.legend(fontsize=11)
ax.grid(axis='y', alpha=0.3, linestyle='--')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

# Annotation
ax.annotate('LightGBM selected:\nHighest Severe Recall (97.3%)\n= Safer triage decisions',
            xy=(0 + width/2, recall_severity[0]),
            xytext=(0.6, 0.91),
            fontsize=9, color='#c00000',
            arrowprops=dict(arrowstyle='->', color='#c00000'))

plt.tight_layout()
plt.savefig('reports/02_severity_model_comparison.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: reports/02_severity_model_comparison.png")


# =========================
# 3. Cross-Validation Fold Scores Chart
# =========================

print("Generating Chart 3: Cross-Validation Results...")

# Load CV results if available, otherwise use placeholder
cv_path = "models/cv_results.json"

if os.path.exists(cv_path):
    with open(cv_path) as f:
        cv_data = json.load(f)
    disease_folds  = cv_data["disease_prediction"]["fold_scores"]
    severity_folds = cv_data["severity_classification"]["fold_scores"]
    disease_mean   = cv_data["disease_prediction"]["mean_f1"]
    severity_mean  = cv_data["severity_classification"]["mean_f1"]
    disease_std    = cv_data["disease_prediction"]["std_dev"]
    severity_std   = cv_data["severity_classification"]["std_dev"]
    note = ""
else:
    # Placeholder until CV is run
    disease_folds  = [0.855, 0.871, 0.862, 0.868, 0.859]
    severity_folds = [0.941, 0.938, 0.943, 0.939, 0.942]
    disease_mean   = round(np.mean(disease_folds), 4)
    severity_mean  = round(np.mean(severity_folds), 4)
    disease_std    = round(np.std(disease_folds), 4)
    severity_std   = round(np.std(severity_folds), 4)
    note = "\n(Placeholder — run 04_cross_validation.py to update)"

folds = [f'Fold {i+1}' for i in range(5)]
x     = np.arange(5)
width = 0.35

fig, ax = plt.subplots(figsize=(10, 6))

bars_d = ax.bar(x - width/2, disease_folds,  width,
                label='Disease Prediction',      color='#5b9bd5', edgecolor='white')
bars_s = ax.bar(x + width/2, severity_folds, width,
                label='Severity Classification', color='#ed7d31', edgecolor='white')

# Mean lines
ax.axhline(y=disease_mean,  color='#2e75b6', linestyle='--', linewidth=1.5,
           label=f'Disease Mean: {disease_mean*100:.1f}% ± {disease_std:.3f}')
ax.axhline(y=severity_mean, color='#c55a11', linestyle='--', linewidth=1.5,
           label=f'Severity Mean: {severity_mean*100:.1f}% ± {severity_std:.3f}')

# Value labels
for bar in bars_d:
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.002,
            f'{bar.get_height()*100:.1f}%',
            ha='center', va='bottom', fontsize=9)

for bar in bars_s:
    ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.002,
            f'{bar.get_height()*100:.1f}%',
            ha='center', va='bottom', fontsize=9)

ax.set_title(f'5-Fold Cross-Validation Results — Model Stability{note}',
             fontsize=13, fontweight='bold', pad=15)
ax.set_ylabel('Weighted F1-Score', fontsize=12)
ax.set_xticks(x)
ax.set_xticklabels(folds, fontsize=11)
ax.set_ylim(0.75, 1.02)
ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.0%}'))
ax.legend(fontsize=10, loc='lower right')
ax.grid(axis='y', alpha=0.3, linestyle='--')
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)

plt.tight_layout()
plt.savefig('reports/03_cross_validation_results.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: reports/03_cross_validation_results.png")


# =========================
# 4. Final Pipeline Summary Chart
# =========================

print("Generating Chart 4: Pipeline Summary...")

fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# --- Disease subplot ---
ax1 = axes[0]
categories = ['Disease\nPrediction\n(CatBoost)', 'Severity\nClassification\n(LightGBM)']
f1_final   = [0.902, 0.9602]
colors_f   = ['#5b9bd5', '#ed7d31']

bars = ax1.bar(categories, f1_final, color=colors_f,
               edgecolor='white', linewidth=1.5, width=0.4)

for bar, val in zip(bars, f1_final):
    ax1.text(bar.get_x() + bar.get_width()/2,
             bar.get_height() + 0.005,
             f'{val*100:.1f}%',
             ha='center', va='bottom', fontsize=14, fontweight='bold')

ax1.set_title('SACA Final Model Performance', fontsize=13, fontweight='bold')
ax1.set_ylabel('Weighted F1-Score', fontsize=11)
ax1.set_ylim(0, 1.1)
ax1.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.0%}'))
ax1.grid(axis='y', alpha=0.3, linestyle='--')
ax1.spines['top'].set_visible(False)
ax1.spines['right'].set_visible(False)

# --- Severe Recall subplot ---
ax2 = axes[1]
recall_labels = ['Mild\nRecall', 'Moderate\nRecall', 'Severe\nRecall']
recall_values = [0.96, 0.95, 0.9733]
recall_colors = ['#70ad47', '#ffc000', '#ff0000']

bars2 = ax2.bar(recall_labels, recall_values, color=recall_colors,
                edgecolor='white', linewidth=1.5, width=0.4)

for bar, val in zip(bars2, recall_values):
    ax2.text(bar.get_x() + bar.get_width()/2,
             bar.get_height() + 0.003,
             f'{val*100:.1f}%',
             ha='center', va='bottom', fontsize=13, fontweight='bold')

ax2.set_title('Severity Classification — Per-Class Recall\n(LightGBM)',
              fontsize=13, fontweight='bold')
ax2.set_ylabel('Recall Score', fontsize=11)
ax2.set_ylim(0.85, 1.05)
ax2.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.0%}'))
ax2.grid(axis='y', alpha=0.3, linestyle='--')
ax2.spines['top'].set_visible(False)
ax2.spines['right'].set_visible(False)

plt.suptitle('SACA — Adaptive Clinical Assistant\nML Pipeline Results Summary',
             fontsize=14, fontweight='bold', y=1.02)

plt.tight_layout()
plt.savefig('reports/04_pipeline_summary.png', dpi=150, bbox_inches='tight')
plt.close()
print("  Saved: reports/04_pipeline_summary.png")


# =========================
# Summary
# =========================

print("\n===== ALL CHARTS GENERATED =====")
print("Saved to reports/ folder:")
print("  01_disease_model_comparison.png  ← use in model selection section")
print("  02_severity_model_comparison.png ← use in severity section")
print("  03_cross_validation_results.png  ← use in evaluation section")
print("  04_pipeline_summary.png          ← use in conclusion/abstract")
if not os.path.exists(cv_path):
    print("\nNOTE: Chart 3 uses placeholder CV data.")
    print("      Run 04_cross_validation.py first, then re-run this script.")
print("\n===== VISUALISATION COMPLETE =====")