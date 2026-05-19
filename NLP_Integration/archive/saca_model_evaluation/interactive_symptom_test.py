from __future__ import annotations

from data_prep import create_standardized_test_set
from model_a_extrang_wrapper import load_predictor, predict_from_symptoms as predict_extra
from model_b_catboost_wrapper import (
    get_feature_columns,
    predict_from_symptoms as predict_cat,
    train_models,
)


def _parse_symptoms(user_input: str) -> list[str]:
    return [s.strip() for s in user_input.split(",") if s.strip()]


def _choose_model() -> str:
    while True:
        choice = input(
            "\nChoose model [extra | catboost | both] (or 'q' to quit): "
        ).strip().lower()
        if choice in {"extra", "catboost", "both", "q"}:
            return choice
        print("Invalid choice. Please enter: extra, catboost, both, or q.")


def main() -> None:
    # Ensures split metadata exists for CatBoost training data isolation.
    create_standardized_test_set()

    print("Loading models...")
    extra_predictor = load_predictor()
    cat_artifacts = train_models()
    cat_feature_columns = get_feature_columns()
    print("Ready. Enter symptoms as comma-separated text.")
    print("Example: chest pain, shortness of breath, fever")

    while True:
        model_choice = _choose_model()
        if model_choice == "q":
            print("Goodbye.")
            break

        symptom_text = input("\nEnter your symptoms (comma-separated): ").strip()
        symptoms = _parse_symptoms(symptom_text)
        if not symptoms:
            print("No symptoms detected. Please try again.")
            continue

        print(f"\nInput symptoms: {symptoms}")

        if model_choice in {"extra", "both"}:
            res_extra = predict_extra(symptoms, predictor_module=extra_predictor)
            print("\n[ExtraNGvboost]")
            print(f"Disease : {res_extra['disease']}")
            print(f"Severity: {res_extra['severity']}")
            print(f"Disease confidence : {res_extra['disease_confidence']}")
            print(f"Severity confidence: {res_extra['severity_confidence']}")

        if model_choice in {"catboost", "both"}:
            res_cat = predict_cat(
                symptoms,
                artifacts=cat_artifacts,
                feature_columns=cat_feature_columns,
            )
            print("\n[CatBoost]")
            print(f"Disease : {res_cat['disease']}")
            print(f"Severity: {res_cat['severity']}")
            print(f"Disease confidence : {res_cat['disease_confidence']}")
            print(f"Severity confidence: {res_cat['severity_confidence']}")
            print(f"Severity probabilities: {res_cat['severity_probs']}")

        print("\n" + "-" * 60)


if __name__ == "__main__":
    main()
