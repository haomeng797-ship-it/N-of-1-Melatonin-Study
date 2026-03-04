# N-of-1 Melatonin Intervention Study

## Project Overview
This repository contains the data analysis pipeline for an N-of-1 randomized self-experiment. The study is designed to evaluate the causal effect of nightly melatonin supplementation on the subsequent day's mean mood.

* **Investigator:** Miura
* **Study Design:** N-of-1 Randomized Controlled Trial (RCT)
* **Duration:** 70 Days
* **Intervention:** Melatonin (1 = Active, 0 = Control), allocated via a pre-generated randomized JSON schedule.

## Analytical Approach
To establish strict temporal precedence, the analysis employs a lagged-variable design. The melatonin intervention administered at day $t$ is modeled to predict the daily mean mood at day $t+1$. 

The primary statistical framework is Bayesian regression, implemented via the `brms` package in R. This approach provides robust posterior inference for high-variance, small-sample longitudinal data. An AR(1) autoregressive structure is optionally incorporated to control for temporal mood inertia.

## Execution
1. Clone this repository to your local machine.
2. Open `analysis_pipeline.R` in RStudio.
3. Verify that the following R dependencies are installed: `dplyr`, `ggplot2`, `lubridate`, `brms`.
4. Execute the script and select the formatted CSV dataset when prompted.
