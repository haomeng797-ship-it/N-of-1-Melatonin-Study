"""
01_data_prep.py
Load cleaned EMA dataset and produce obs-level and day-level frames.

The repository ships with the cleaned dataset (data/miura_ema_70day.csv).
This script verifies and re-derives the day-level aggregates for downstream
analyses. It also records the Day-18 protocol amendment (agency and
metacognition items added on 2026-03-07) by reporting when those columns
first contain values.

Run from repo root:
    python src/analysis/01_data_prep.py
"""
from pathlib import Path
import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = REPO_ROOT / "data"
OUT_DIR  = REPO_ROOT / "outputs"
OUT_DIR.mkdir(parents=True, exist_ok=True)

obs = pd.read_csv(DATA_DIR / "miura_ema_70day.csv")
obs["datetime"] = pd.to_datetime(obs["datetime"])
obs["date"]     = pd.to_datetime(obs["date"])

# Day-18 protocol amendment marker
first_agency_day = int(obs.dropna(subset=["agency"]).iloc[0]["study_day"])
first_agency_date = obs[obs.study_day == first_agency_day]["date"].iloc[0].date()
print(f"First day with agency/metacognition: Day {first_agency_day} ({first_agency_date})")

# Day-level frame
day = (obs.groupby(["date", "study_day", "condition", "melatonin"], as_index=False)
          .agg(mood=("mood", "mean"),
               agency=("agency", "mean"),
               metacognition=("metacognition", "mean"),
               n_obs=("mood", "size"))
          .sort_values("study_day").reset_index(drop=True))

# Save for downstream scripts
obs.to_csv(OUT_DIR / "clean_obs.csv", index=False)
day.to_csv(OUT_DIR / "clean_day.csv", index=False)

print(f"\nObs-level n   = {len(obs)} (planned 210, compliance = {len(obs)/210*100:.1f}%)")
print(f"Day-level n   = {len(day)} calendar partitions over 70 study days")
print(f"  control     = {(day.condition == 'control').sum()}")
print(f"  melatonin   = {(day.condition == 'melatonin').sum()}")
print(f"  days with agency/metacog = {day['agency'].notna().sum()}")
