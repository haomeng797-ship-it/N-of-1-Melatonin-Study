# N-of-1 Melatonin Study

A 70-day single-subject self-experiment testing whether melatonin administration
predicts daily affective state in one individual, framed within a control-theoretic
account of affect dynamics. Internal behavioral drivers (perceived agency and
metacognitive awareness) jointly accounted for **51.6%** of the daily-mood variance
over and above an AR(1) baseline, while the melatonin probe contributed **0.01%**.
A heteroskedasticity analysis suggested smaller residual variance on melatonin days
(α₁ = −1.21, *p* = .044), consistent with melatonin's chronobiotic rather than
antidepressant function.

## Author

**Miura Meng** &nbsp; · &nbsp; meng10@upenn.edu &nbsp; · &nbsp; ORCID: [0009-0004-1522-1997](https://orcid.org/0009-0004-1522-1997)

## Paper
See [`paper/`](paper/) for all manuscript versions (latest: v4).

## Repository structure

```
N-of-1-Melatonin-Study/
├── README.md                            ← this file
├── requirements.txt                     ← Python dependencies
├── LICENSE                              ← CC-BY 4.0
├── randomization/
│   ├── Protocol_.md                     ← data-collection protocol
│   └── schedule.json                    ← pre-registered 70-day randomization
├── data/
│   ├── miura_ema_70day.csv              ← cleaned obs-level EMA data (n = 195)
│   └── miura_ema_70day_daily.csv        ← cleaned day-level aggregates (n = 70)
├── src/
│   ├── data_logger.py                   ← iOS Shortcuts entry validation
│   └── analysis/
│       ├── 01_data_prep.py              ← load + verify cleaned dataset
│       ├── 02_ar1_models.py             ← nested AR(1) M0/M1/M2 + ΔR²
│       ├── 02b_ar1_obslevel.py          ← obs-level + full-sample AR(1) + half-life
│       ├── 03_state_space.py            ← local-level Kalman filter
│       ├── 04_metacontrol.py            ← melatonin × metacog interaction
│       ├── 05_variability_and_interactions.py    ← variability + agency × mel + state-dependent
│       ├── 06_make_figures.py           ← regenerate all seven figures
│       ├── 07_bayesian_robustness.R     ← supplementary Bayesian AR(1) robustness (brms)
│       └── 08_results_table.py          ← assemble outputs/results_table.csv
├── figures/
│   └── fig1–fig7 (PNGs)
├── outputs/
│   ├── clean_obs.csv, clean_day.csv     ← intermediate cleaned frames
│   ├── ar1_coefficients.csv, ar1_fit_table.csv, delta_r2.csv
│   ├── phi_halflife.csv
│   ├── kalman_trajectory.csv, kalman_fit_summary.csv
│   ├── metacontrol_table.csv, variability_table.csv
│   └── results_table.csv                ← every number reported in the manuscript (built by 08)
└── paper/
    └── Miura_*_Affect_Paper_v2…v4.docx  ← manuscript versions (latest: v4)
```

## How to reproduce

```bash
# 1. Install dependencies (Python 3.10+)
pip install -r requirements.txt

# 2. Run the analysis pipeline from the repo root, in order
python src/analysis/01_data_prep.py
python src/analysis/02_ar1_models.py
python src/analysis/02b_ar1_obslevel.py
python src/analysis/03_state_space.py
python src/analysis/04_metacontrol.py
python src/analysis/05_variability_and_interactions.py

# 3. Assemble the master results table (reads the CSVs written by 02–05)
python src/analysis/08_results_table.py

# 4. Regenerate figures
python src/analysis/06_make_figures.py
```

Each script writes its outputs to `outputs/` (cleaned data, model coefficients,
fit summaries) and `figures/` (PNG plots). All numbers reported in the
manuscript can be recovered from the contents of `outputs/`.

**Note on fig1–fig4:** the PNGs shipped in `figures/` for fig1–fig4 are the
author's polished originals. Running `06_make_figures.py` regenerates them
from the data using `matplotlib` with similar styling; visual rendering may
differ slightly from the canonical PNGs (the underlying statistical content
is identical).

## Method summary

- **Design.** 70-day intensive longitudinal N-of-1 alternating-treatment study.
  Each day randomly assigned to active (melatonin) or control (no melatonin)
  according to a pre-registered schedule with no runs longer than two consecutive
  days in either condition.
- **Measures.** Ecological momentary assessment (EMA) three times per day
  (~10:00, ~16:00, ~22:00) via automated iOS Shortcuts. Items:
  *mood* (current emotional state, 0–100 slider), *agency* (sense of task
  progress and forward motion, 0–100 slider), *metacognition* (awareness of
  current internal state, 0–100 slider), *melatonin* taken last night (0/1).
- **Day-18 protocol amendment.** Agency and metacognition items were added on
  Day 18 (2026-03-07) after an interim review; analyses involving these
  variables are restricted to Days 18–70.
- **Sample.** 195 EMA observations across 70 study days (92.9% compliance);
  35 control and 36 melatonin daily aggregates, partitioned across 71 calendar
  dates due to the protocol's evening-start convention.

## Data and code availability

Data and code in this repository are released under [CC-BY 4.0](LICENSE).

## Citation

If you use this code or dataset, please cite the manuscript:

> Meng, M. (2026). *Affect as a Dynamical System: A Control-Theoretic N-of-1
> Self-Experiment*. Manuscript in preparation.
> https://github.com/haomeng797-ship-it/N-of-1-Melatonin-Study
