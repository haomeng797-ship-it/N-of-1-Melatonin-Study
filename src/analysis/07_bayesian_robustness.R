# 07_bayesian_robustness.R
#
# Supplementary Bayesian AR(1) robustness regression for the primary
# M2 model reported in Sections 2.5.1 and 3.2 of the manuscript.
#
# Two models are fit:
#   (1) Primary robustness:  mood ~ lag_mood + melatonin + agency + metacog
#   (2) Metacontrol:         mood ~ lag_mood + melatonin * metacog + agency
#
# Continuous variables are standardized (z-scored). Melatonin is 0/1.
#
# Priors (weakly informative):
#   coefficients b ~ Normal(0, 1)
#   intercept      ~ Student-t(3, 0, 2.5)
#   sigma          ~ Exponential(1)
#
# To run from the repo root (github_release/):
#   setwd("/path/to/github_release")
#   source("src/analysis/07_bayesian_robustness.R")

suppressPackageStartupMessages({
  library(brms)
  library(tidyverse)
  library(posterior)
})

# ---------- Load and prepare data ----------
df <- read.csv("outputs/clean_day.csv")

df_bayes <- df %>%
  arrange(study_day) %>%
  mutate(lag_mood = lag(mood)) %>%
  filter(!is.na(mood), !is.na(lag_mood),
         !is.na(agency), !is.na(metacognition), !is.na(melatonin)) %>%
  mutate(
    mood_z          = as.numeric(scale(mood)),
    lag_mood_z      = as.numeric(scale(lag_mood)),
    agency_z        = as.numeric(scale(agency)),
    metacognition_z = as.numeric(scale(metacognition)),
    melatonin       = as.integer(melatonin)
  )

cat(sprintf("Sample size: n = %d days (Day 18-70 subsample)\n", nrow(df_bayes)))

# ---------- Priors ----------
priors <- c(
  prior(normal(0, 1),         class = "b"),
  prior(student_t(3, 0, 2.5), class = "Intercept"),
  prior(exponential(1),       class = "sigma")
)

# ---------- Model 1: Primary Bayesian M2 robustness ----------
cat("\n===== Fitting Model 1: Bayesian M2 (primary robustness) =====\n")
fit_m2 <- brm(
  mood_z ~ lag_mood_z + melatonin + agency_z + metacognition_z,
  data    = df_bayes,
  family  = gaussian(),
  prior   = priors,
  chains  = 4,
  iter    = 4000,
  warmup  = 1000,
  cores   = 4,
  seed    = 20260511,
  control = list(adapt_delta = 0.95),
  refresh = 200
)

summary(fit_m2)

post_m2 <- as_draws_df(fit_m2)
summ_m2 <- summarise_draws(
  post_m2,
  mean, median, sd,
  ~quantile(.x, probs = c(0.025, 0.975)),
  rhat, ess_bulk, ess_tail,
  pr_gt_0 = ~mean(.x > 0)
)
print(summ_m2, n = Inf)

write.csv(summ_m2, "outputs/bayesian_m2_posterior_summary.csv", row.names = FALSE)
saveRDS(fit_m2, "outputs/bayesian_m2_fit.rds")

# ---------- Model 2: Metacontrol (secondary) ----------
cat("\n===== Fitting Model 2: Bayesian metacontrol (secondary) =====\n")
fit_meta <- brm(
  mood_z ~ lag_mood_z + melatonin * metacognition_z + agency_z,
  data    = df_bayes,
  family  = gaussian(),
  prior   = priors,
  chains  = 4,
  iter    = 4000,
  warmup  = 1000,
  cores   = 4,
  seed    = 20260511,
  control = list(adapt_delta = 0.95),
  refresh = 200
)

summary(fit_meta)

post_meta <- as_draws_df(fit_meta)
summ_meta <- summarise_draws(
  post_meta,
  mean, median, sd,
  ~quantile(.x, probs = c(0.025, 0.975)),
  rhat, ess_bulk, ess_tail,
  pr_gt_0 = ~mean(.x > 0)
)
print(summ_meta, n = Inf)

write.csv(summ_meta, "outputs/bayesian_metacontrol_posterior_summary.csv", row.names = FALSE)
saveRDS(fit_meta, "outputs/bayesian_metacontrol_fit.rds")

cat("\nDone. Output files written to outputs/:\n")
cat("  bayesian_m2_posterior_summary.csv\n")
cat("  bayesian_metacontrol_posterior_summary.csv\n")
cat("  bayesian_m2_fit.rds\n")
cat("  bayesian_metacontrol_fit.rds\n")
