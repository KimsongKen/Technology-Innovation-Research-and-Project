# =============================================================================
# SACA Disease Model - Test Setup
# Run from anywhere: python test_setup.py
# =============================================================================
 
import os
import sys
 
# Always resolve paths relative to THIS script's location (project root)
BASE       = os.path.dirname(os.path.abspath(__file__))
DATA_DIR   = os.path.join(BASE, "data")
MODELS_DIR = os.path.join(BASE, "models")
 
PASS = 0
FAIL = 0
 
def test(name, fn):
    global PASS, FAIL
    try:
        fn()
        print(f"  [PASS] {name}")
        PASS += 1
    except Exception as e:
        print(f"  [FAIL] {name} --> {e}")
        FAIL += 1
 
 
# ==========================
# 1. Library Import Tests
# ==========================
print("\n== 1. Library Imports ==")
 
def test_pandas():
    import pandas as pd
    print(f"         pandas           {pd.__version__}", end=" ")
 
def test_numpy():
    import numpy as np
    print(f"         numpy            {np.__version__}", end=" ")
 
def test_sklearn():
    import sklearn
    print(f"         scikit-learn     {sklearn.__version__}", end=" ")
 
def test_lightgbm():
    import lightgbm as lgb
    print(f"         lightgbm         {lgb.__version__}", end=" ")
 
def test_catboost():
    import catboost as cb
    print(f"         catboost         {cb.__version__}", end=" ")
 
def test_imblearn():
    import imblearn
    print(f"         imbalanced-learn {imblearn.__version__}", end=" ")
 
def test_joblib():
    import joblib
    print(f"         joblib           {joblib.__version__}", end=" ")
 
test("pandas",           test_pandas)
test("numpy",            test_numpy)
test("scikit-learn",     test_sklearn)
test("lightgbm",         test_lightgbm)
test("catboost",         test_catboost)
test("imbalanced-learn", test_imblearn)
test("joblib",           test_joblib)
 
 
# ==========================
# 2. File & Folder Structure Tests
# ==========================
print("\n== 2. Project File Structure ==")
 
REQUIRED_PATHS = [
    os.path.join(DATA_DIR,   "saca_final_dataset_self.csv"),
    os.path.join(MODELS_DIR, "decision_tree.pkl"),
    os.path.join(MODELS_DIR, "lightgbm_model.pkl"),
    os.path.join(MODELS_DIR, "catboost_model.cbm"),
    os.path.join(MODELS_DIR, "label_encoder.pkl"),
    os.path.join(DATA_DIR,   "test_results.json"),
]
 
for path in REQUIRED_PATHS:
    test(f"exists: {os.path.relpath(path, BASE)}", lambda p=path: (
        (_ for _ in ()).throw(FileNotFoundError(f"Not found: {p}"))
        if not os.path.exists(p) else None
    ))
 
 
# ==========================
# 3. Dataset Load Test
# ==========================
print("\n== 3. Dataset ==")
 
def test_dataset_load():
    import pandas as pd
    df = pd.read_csv(os.path.join(DATA_DIR, "saca_final_dataset_self.csv"))
    assert df.shape[0] > 0,          "Dataset is empty"
    assert "diseases" in df.columns, "Missing 'diseases' column"
    assert "Severity" in df.columns, "Missing 'Severity' column"
    print(f"         rows={df.shape[0]:,}  cols={df.shape[1]}  "
          f"diseases={df['diseases'].nunique()}", end=" ")
 
test("CSV loads correctly", test_dataset_load)
 
 
# ==========================
# 4. Model Load Tests
# ==========================
print("\n== 4. Model Loading ==")
 
def test_load_dt():
    import joblib
    model = joblib.load(os.path.join(MODELS_DIR, "decision_tree.pkl"))
    assert hasattr(model, "predict"), "DT has no predict()"
 
def test_load_lgb():
    import joblib
    model = joblib.load(os.path.join(MODELS_DIR, "lightgbm_model.pkl"))
    assert hasattr(model, "predict"), "LGB has no predict()"
 
def test_load_cb():
    import catboost as cb
    model = cb.CatBoostClassifier()
    model.load_model(os.path.join(MODELS_DIR, "catboost_model.cbm"))
    assert hasattr(model, "predict"), "CB has no predict()"
 
def test_load_le():
    import joblib
    le = joblib.load(os.path.join(MODELS_DIR, "label_encoder.pkl"))
    assert hasattr(le, "classes_"), "LabelEncoder missing classes_"
    print(f"         {len(le.classes_)} disease classes loaded", end=" ")
 
test("Decision Tree loads",  test_load_dt)
test("LightGBM loads",       test_load_lgb)
test("CatBoost loads",       test_load_cb)
test("LabelEncoder loads",   test_load_le)
 
 
# ==========================
# 5. Prediction Smoke Test
# ==========================
print("\n== 5. Prediction Smoke Test ==")
 
def test_prediction():
    import joblib, numpy as np, catboost as cb, re
    import pandas as pd
 
    le        = joblib.load(os.path.join(MODELS_DIR, "label_encoder.pkl"))
    model_lgb = joblib.load(os.path.join(MODELS_DIR, "lightgbm_model.pkl"))
    model_cb  = cb.CatBoostClassifier()
    model_cb.load_model(os.path.join(MODELS_DIR, "catboost_model.cbm"))
 
    df = pd.read_csv(os.path.join(DATA_DIR, "saca_final_dataset_self.csv"))
    X  = df.drop(["diseases", "Severity"], axis=1)
    X.columns = [re.sub(r"[^A-Za-z0-9_]", "_", str(c)) for c in X.columns]
 
    sample = X.iloc[[0]]
 
    lgb_prob = np.asarray(model_lgb.predict(sample))
    lgb_pred = le.inverse_transform([np.argmax(lgb_prob)])[0]
 
    cb_pred = le.inverse_transform(
        model_cb.predict(sample).flatten()
    )[0]
 
    print(f"         LightGBM → {lgb_pred} | CatBoost → {cb_pred}", end=" ")
    assert isinstance(lgb_pred, str), "LGB prediction not a string"
    assert isinstance(cb_pred,  str), "CB  prediction not a string"
 
test("Models can predict on real sample", test_prediction)
 
 
# ==========================
# 6. JSON Output Test
# ==========================
print("\n== 6. JSON Test Results ==")
 
def test_json_output():
    import json
    with open(os.path.join(DATA_DIR, "test_results.json")) as f:
        data = json.load(f)
    assert len(data) > 0,                             "JSON is empty"
    assert "true_disease"  in data[0],                "Missing 'true_disease'"
    assert "predictions"   in data[0],                "Missing 'predictions'"
    assert "lightgbm"      in data[0]["predictions"], "Missing LGB prediction"
    assert "catboost"      in data[0]["predictions"], "Missing CB prediction"
    correct_lgb = sum(1 for d in data if d["correct"]["lightgbm"])
    correct_cb  = sum(1 for d in data if d["correct"]["catboost"])
    print(f"         {len(data)} samples | LGB {correct_lgb}/{len(data)} correct | "
          f"CB {correct_cb}/{len(data)} correct", end=" ")
 
test("test_results.json is valid", test_json_output)
 
 
# ==========================
# Summary
# ==========================
total = PASS + FAIL
print(f"\n{'='*45}")
print(f"  Results: {PASS}/{total} passed", end="  ")
print(f"{'ALL GOOD! ✓' if FAIL == 0 else f'{FAIL} FAILED ✗'}")
print(f"{'='*45}\n")
 
sys.exit(0 if FAIL == 0 else 1)