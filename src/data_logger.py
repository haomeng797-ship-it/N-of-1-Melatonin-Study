"""
data_logger.py
Validation layer for the iOS Shortcuts EMA data pipeline.

Run after each new entry to verify range, completeness, and uniqueness:

    python src/data_logger.py validate

Or, to validate the cleaned 70-day dataset:

    python src/data_logger.py validate data/miura_ema_70day.csv
"""
import sys
from pathlib import Path
import pandas as pd

REPO_ROOT  = Path(__file__).resolve().parents[1]
DEFAULT    = REPO_ROOT / "data" / "miura_ema_70day.csv"
NUMERIC    = ["mood", "agency", "metacognition"]
REQUIRED   = ["datetime", "mood"]


def validate(path: Path) -> int:
    df = pd.read_csv(path)
    errors = []

    # Range check
    for col in NUMERIC:
        if col in df.columns:
            bad = df[(df[col].notna()) & ((df[col] < 0) | (df[col] > 100))]
            if len(bad) > 0:
                errors.append(f"{col}: {len(bad)} row(s) outside [0, 100]")

    # Completeness check
    for col in REQUIRED:
        if col not in df.columns:
            errors.append(f"missing required column: {col}")
        else:
            n_missing = df[col].isna().sum()
            if n_missing > 0:
                errors.append(f"{col}: {n_missing} missing value(s)")

    # Duplicate-timestamp check
    if "datetime" in df.columns:
        n_dup = df["datetime"].duplicated().sum()
        if n_dup > 0:
            errors.append(f"datetime: {n_dup} duplicate timestamp(s)")

    if errors:
        print(f"VALIDATION FAILED ({path.name}):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"VALIDATION PASSED  ({path.name}, {len(df)} rows).")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] != "validate":
        print(__doc__)
        sys.exit(1)
    path = Path(sys.argv[2]) if len(sys.argv) >= 3 else DEFAULT
    sys.exit(validate(path))
