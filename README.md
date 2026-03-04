# N-of-1 Melatonin × Mood Study (70-day randomized self-experiment)

## Overview
This repository contains a reproducible R pipeline for a 70-day N-of-1 randomized self-experiment testing whether **nightly melatonin** affects **next-day mean mood**.

- **Investigator:** Miura  
- **Design:** Randomized N-of-1 (50/50 allocation)  
- **Day 1 anchor:** 2026-02-18  
- **Condition:** `melatonin` (1 = active, 0 = control) assigned via a pre-generated JSON schedule  
- **Mood measurement:** 0–100 slider, collected ~3×/day (10:00, 16:00, 22:00)

## Data & preprocessing
Raw mood entries are cleaned and collapsed to **one row per day**:

`date | morning | afternoon | night | daily_mean | melatonin`

Key cleaning rules:
- Keep observations closest to the target times (~10:00 / ~16:00 / ~22:00)  
- Remove duplicate/extra entries from repeated shortcut triggers  
- Compute `daily_mean = (morning + afternoon + night) / 3`

## Temporal alignment (lag)
To match causal ordering, the model uses:
- **Exposure:** melatonin taken on **night t**  
- **Outcome:** mean mood on **day t+1**

(Implemented by shifting the mood outcome forward one day relative to the exposure schedule.)

## Models
Primary model (Bayesian Gaussian regression, `brms`):
- `daily_mean ~ melatonin`

Optional extension:
- AR(1) autocorrelation to account for day-to-day mood inertia

## How to run
1. Clone the repository.
2. Open `analysis_pipeline.R` in RStudio.
3. Install packages if needed: `tidyverse`, `lubridate`, `jsonlite`, `brms`
4. Run the script. It will prompt you to select the formatted CSV and (if applicable) the JSON schedule.

## Outputs
The pipeline generates:
- A cleaned daily dataset (1 row/day)
- An intervention time-series plot (colored by condition)
- Posterior summary and posterior plot for the melatonin effect (β)
- Optional boxplot comparing mood distributions by condition
