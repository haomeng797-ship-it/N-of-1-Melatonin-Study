"""
03_state_space.py
Local-level (random-walk-plus-noise) state-space model fit via Kalman filter
on the day-level mood series.

  Observation:  y_t = x_t + v_t,        v_t ~ N(0, sigma_v^2)
  State (LL):   x_t = x_{t-1} + w_t,    w_t ~ N(0, sigma_w^2)

Writes the smoothed latent trajectory + 95% CI band to outputs/.

Run from repo root:
    python src/analysis/03_state_space.py
"""
from pathlib import Path
import numpy as np
import pandas as pd
from statsmodels.tsa.statespace.structural import UnobservedComponents

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR   = REPO_ROOT / "outputs"

day = pd.read_csv(OUT_DIR / "clean_day.csv")
y = day["mood"].values

m = UnobservedComponents(y, level="local level").fit(disp=False)
sigma_v2 = m.params[0]    # observation variance
sigma_w2 = m.params[1]    # state innovation variance

print(f"sigma_v^2 (obs noise)        = {sigma_v2:.3f}")
print(f"sigma_w^2 (state innovation) = {sigma_w2:.3f}")
print(f"Signal-to-noise              = {sigma_w2/sigma_v2:.3f}")
print(f"Log-likelihood               = {m.llf:.2f}")
print(f"AIC                          = {m.aic:.2f}")

filt_state  = m.filtered_state[0]
smoothed    = m.smoothed_state[0]
smoothed_se = np.sqrt(m.smoothed_state_cov[0, 0])

ssm = pd.DataFrame({
    "study_day":   day["study_day"].values,
    "date":        day["date"].values,
    "y":           y,
    "filtered":    filt_state,
    "smoothed":    smoothed,
    "smoothed_se": smoothed_se,
    "ci_lo":       smoothed - 1.96 * smoothed_se,
    "ci_hi":       smoothed + 1.96 * smoothed_se,
    "condition":   day["condition"].values,
})
ssm.to_csv(OUT_DIR / "kalman_trajectory.csv", index=False)

pd.DataFrame({
    "model":   ["Local level"],
    "sigma_v2":[sigma_v2],  "sigma_w2":[sigma_w2],
    "snr":     [sigma_w2/sigma_v2],
    "loglik":  [m.llf],     "AIC":[m.aic],
}).to_csv(OUT_DIR / "kalman_fit_summary.csv", index=False)
