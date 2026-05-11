"""
04_metacontrol.py
Metacontrol interaction: does metacognitive awareness moderate the system's
responsiveness to melatonin?

  mood_t ~ mood_lag1 + melatonin * metacognition_centered

Run from repo root:
    python src/analysis/04_metacontrol.py
"""
from pathlib import Path
import numpy as np
import pandas as pd
import statsmodels.api as sm

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR   = REPO_ROOT / "outputs"

day = pd.read_csv(OUT_DIR / "clean_day.csv")
day["mood_lag1"] = day["mood"].shift(1)
sub = day.dropna(subset=["mood", "mood_lag1", "metacognition", "melatonin"]).copy()

sub["meta_c"]     = sub["metacognition"] - sub["metacognition"].mean()
sub["mel_x_meta"] = sub["melatonin"] * sub["meta_c"]

X = sm.add_constant(sub[["mood_lag1", "melatonin", "meta_c", "mel_x_meta"]])
m = sm.OLS(sub["mood"].values, X).fit()
ci = m.conf_int(alpha=0.05)

print(f"Sample n = {int(m.nobs)},  R^2 = {m.rsquared:.3f}\n")
out = pd.DataFrame({
    "term": m.params.index, "estimate": m.params.values,
    "std_err": m.bse.values, "t": m.tvalues, "p": m.pvalues,
    "ci_lo": ci[0].values, "ci_hi": ci[1].values,
}).round(4)
print(out.to_string(index=False))
out.to_csv(OUT_DIR / "metacontrol_table.csv", index=False)

# Simple slopes
sd_meta = sub["metacognition"].std()
b_mel = m.params["melatonin"]
b_int = m.params["mel_x_meta"]
print("\nSimple melatonin slopes:")
for offset, label in [(-sd_meta, "-1 SD metacog"), (0, "mean metacog"), (sd_meta, "+1 SD metacog")]:
    print(f"  at {label:>14}: {b_mel + b_int * offset:+.3f}")
