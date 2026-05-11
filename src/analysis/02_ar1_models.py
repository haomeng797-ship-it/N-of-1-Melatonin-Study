"""
02_ar1_models.py
Three nested AR(1)-with-exogenous-inputs specifications, fit on day-level mood:

  M0:  mood_t = phi*mood_{t-1}                                  [baseline]
  M1:  + b1 * melatonin_t                                        [+external]
  M2:  + b2 * agency_t + b3 * metacognition_t                    [+internal]

All three are fit on the Day 18-70 subsample (n=53) so they share data
and incremental R^2 is comparable. Writes coefficient tables and delta-R^2
to outputs/.

Run from repo root:
    python src/analysis/02_ar1_models.py
"""
from pathlib import Path
import numpy as np
import pandas as pd
import statsmodels.api as sm

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR   = REPO_ROOT / "outputs"

day = pd.read_csv(OUT_DIR / "clean_day.csv")
day["mood_lag1"] = day["mood"].shift(1)

sub = day.dropna(subset=["mood", "mood_lag1", "agency", "metacognition", "melatonin"]).copy()
sub = sub.reset_index(drop=True)
print(f"Nested-model subsample n = {len(sub)} days "
      f"(study_day {int(sub['study_day'].min())} - {int(sub['study_day'].max())})")

def fit(y, X, label):
    X = sm.add_constant(X)
    m = sm.OLS(y, X).fit()
    ci = m.conf_int(alpha=0.05)
    out = pd.DataFrame({
        "model": label, "term": m.params.index,
        "estimate": m.params.values, "std_err": m.bse.values,
        "t": m.tvalues, "p": m.pvalues,
        "ci_lo": ci[0].values, "ci_hi": ci[1].values,
    })
    return m, out

y = sub["mood"].values
m0, t0 = fit(y, sub[["mood_lag1"]], "M0_AR1")
m1, t1 = fit(y, sub[["mood_lag1", "melatonin"]], "M1_AR1+mel")
m2, t2 = fit(y, sub[["mood_lag1", "melatonin", "agency", "metacognition"]], "M2_full")

# Incremental R^2 via drop-one
def _drop1_R2(full_model, full_X_cols, drop_col):
    keep = [c for c in full_X_cols if c != drop_col]
    sub_m = sm.OLS(y, sm.add_constant(sub[keep])).fit()
    return full_model.rsquared - sub_m.rsquared

dR2 = {
    "melatonin":     _drop1_R2(m2, ["mood_lag1","melatonin","agency","metacognition"], "melatonin"),
    "agency":        _drop1_R2(m2, ["mood_lag1","melatonin","agency","metacognition"], "agency"),
    "metacognition": _drop1_R2(m2, ["mood_lag1","melatonin","agency","metacognition"], "metacognition"),
    "internal_block (agency + metacognition)": m2.rsquared - m1.rsquared,
}

# Save
pd.concat([t0, t1, t2], ignore_index=True).to_csv(OUT_DIR / "ar1_coefficients.csv", index=False)
pd.DataFrame({
    "model":  ["M0_AR1", "M1_AR1+mel", "M2_full"],
    "n":      [int(m0.nobs)]*3,
    "R2":     [m0.rsquared, m1.rsquared, m2.rsquared],
    "adj_R2": [m0.rsquared_adj, m1.rsquared_adj, m2.rsquared_adj],
}).to_csv(OUT_DIR / "ar1_fit_table.csv", index=False)
pd.DataFrame([{"predictor": k, "deltaR2": v} for k, v in dR2.items()]).to_csv(OUT_DIR / "delta_r2.csv", index=False)

print("\n=== M0 baseline AR(1) ===")
print(t0.to_string(index=False))
print(f"R^2 = {m0.rsquared:.3f}")

print("\n=== M1 + melatonin ===")
print(t1.to_string(index=False))
print(f"R^2 = {m1.rsquared:.3f}")

print("\n=== M2 full ===")
print(t2.to_string(index=False))
print(f"R^2 = {m2.rsquared:.3f}, adj R^2 = {m2.rsquared_adj:.3f}")

print("\n=== Incremental Delta R^2 (drop-one within M2) ===")
for k, v in dR2.items():
    print(f"  {k:48s} {v:.4f}")

# Residual diagnostics
from statsmodels.stats.diagnostic import acorr_ljungbox
from scipy import stats
lb = acorr_ljungbox(m2.resid, lags=[1, 5, 10], return_df=True)
sw_W, sw_p = stats.shapiro(m2.resid)
print(f"\nM2 residuals — Ljung-Box p (lags 1,5,10): {lb['lb_pvalue'].values}")
print(f"M2 residuals — Shapiro-Wilk W = {sw_W:.3f}, p = {sw_p:.3f}")
