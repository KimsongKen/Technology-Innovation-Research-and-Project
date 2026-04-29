## Severity Classification Model

### Purpose

This script trains and evaluates the severity classification support model for the SACA project.

The model classifies symptom-based inputs into:

- Mild
- Moderate
- Severe

This supports the broader disease prediction model by estimating how serious a patient-reported case may be.

### Role

Sovandara — ML Engineer #2: Data + Core ML Models

Main responsibility:

- Disease prediction model

Supporting responsibility:

- Severity classification model

Key tasks:

- data cleaning and preprocessing;
- feature preparation;
- train/validation/test split;
- LightGBM and CatBoost model training;
- model comparison;
- evaluation using weighted F1-score and Severe-class recall;
- generation of evaluation reports and visual outputs.

### How to Run

Create and activate the Python virtual environment:

```powershell
python -m venv .venv
.\.venv\Scripts\activate