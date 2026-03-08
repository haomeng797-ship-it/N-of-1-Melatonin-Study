# ============================================================
# MIURA N-of-1 STUDY: Bayesian Analysis Pipeline
# Affect as a Dynamical System: A Control-Theoretic N-of-1 Self-Experiment
# Version 2.0 | 2026-03-08
# ============================================================
#
# USAGE:
# 1. Place Miura_Data.csv and schedule.json in your working directory
# 2. Run the script from top to bottom
# 3. Figures saved to miura_figures/
#
# DATA FORMAT (Miura_Data.csv):
#   Formatted Date, Mood, agency, metacognition, melatonin_taken, override_reason
#
# Dependencies: brms, tidyverse, lubridate, jsonlite, bayesplot, bsts, tidybayes
# ============================================================

# ---- 0. Load packages ----------------------------------------

packages <- c("brms", "tidyverse", "lubridate", "jsonlite",
               "bayesplot", "bsts", "tidybayes")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
invisible(lapply(packages, install_if_missing))
invisible(lapply(packages, library, character.only = TRUE))

options(mc.cores = parallel::detectCores())


# ---- 1. Load data --------------------------------------------

study_start <- as.Date("2026-02-18")

# Load EMA data
df_raw <- read_csv("Miura_Data.csv")

# Load melatonin schedule and derive daily assignment
schedule_json <- fromJSON("schedule.json")
schedule_vec  <- unlist(schedule_json)  # named vector, keys "1" to "70"


# ---- 2. Data cleaning ----------------------------------------

df <- df_raw %>%
  rename(
    timestamp = `Formatted Date`,
    mood      = Mood
  ) %>%
  mutate(
    timestamp       = ymd_hms(timestamp),
    date            = as_date(timestamp),
    study_day       = as.integer(date - study_start) + 1,
    obs_within_day  = row_number() %% 3,
    obs_within_day  = ifelse(obs_within_day == 0, 3, obs_within_day),
    phase           = ifelse(study_day <= 30, "identification", "perturbation"),
    phase           = factor(phase, levels = c("identification", "perturbation")),
    across(c(mood, agency, metacognition), as.numeric),
    mood_z          = scale(mood)[,1],
    agency_z        = scale(agency)[,1],
    metacognition_z = scale(metacognition)[,1],
    melatonin       = as.integer(schedule_vec[as.character(study_day)])
  ) %>%
  arrange(timestamp) %>%
  mutate(
    mood_lag1   = lag(mood),
    mood_lag1_z = lag(mood_z)
  ) %>%
  filter(!is.na(mood_lag1))

cat("Data overview:\n")
cat("Total observations:", nrow(df), "\n")
cat("Study days:", n_distinct(df$study_day), "\n")
cat("Missing values:\n")
print(colSums(is.na(df[, c("mood","agency","metacognition","melatonin")])))


# ---- 3. Descriptive visualization ----------------------------

# 3.1 Time series
p_ts <- df %>%
  pivot_longer(cols = c(mood, agency, metacognition),
               names_to = "variable", values_to = "value") %>%
  mutate(variable = factor(variable,
                           levels = c("mood","agency","metacognition"),
                           labels = c("Mood","Agency","Metacognition"))) %>%
  ggplot(aes(x = timestamp, y = value, color = variable)) +
  geom_line(alpha = 0.7) +
  geom_point(size = 0.8, alpha = 0.5) +
  geom_vline(xintercept = as.POSIXct(study_start + 30),
             linetype = "dashed", color = "gray40") +
  annotate("text", x = as.POSIXct(study_start + 15), y = 102,
           label = "Phase 1", size = 3, color = "gray40") +
  annotate("text", x = as.POSIXct(study_start + 50), y = 102,
           label = "Phase 2", size = 3, color = "gray40") +
  facet_wrap(~variable, ncol = 1) +
  scale_color_manual(values = c("#2E86AB","#A23B72","#F18F01")) +
  labs(title = "Daily EMA Time Series",
       x = "Date", y = "Score (0-100)") +
  theme_minimal() +
  theme(legend.position = "none")

# 3.2 Mood distribution by melatonin condition
p_mel_dist <- df %>%
  mutate(Melatonin = ifelse(melatonin == 1, "Active", "Control")) %>%
  ggplot(aes(x = mood, fill = Melatonin)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("#2E86AB","#F18F01")) +
  labs(title = "Mood Distribution by Melatonin Condition",
       x = "Mood Score", y = "Density") +
  theme_minimal()

# 3.3 Lag scatter plot
p_lag <- df %>%
  ggplot(aes(x = mood_lag1, y = mood)) +
  geom_point(alpha = 0.4, color = "#2E86AB") +
  geom_smooth(method = "lm", color = "#A23B72", se = TRUE) +
  labs(title = "Affective Inertia (Lag-1 Autocorrelation)",
       x = "Mood (t-1)", y = "Mood (t)") +
  theme_minimal()

print(p_ts)
print(p_mel_dist)
print(p_lag)


# ---- 4. Bayesian AR(1) main model ----------------------------

cat("\nFitting main model (AR1 + all predictors)...\n")

prior_main <- c(
  prior(normal(0, 1),   class = b),
  prior(normal(0, 0.5), class = b, coef = mood_lag1),
  prior(normal(0, 10),  class = Intercept),
  prior(exponential(1), class = sigma)
)

fit_main <- brm(
  mood ~ mood_lag1 + melatonin + agency + metacognition,
  data   = df,
  family = gaussian(),
  prior  = prior_main,
  chains = 4, iter = 4000, warmup = 1000,
  seed   = 42,
  file   = "fit_main"
)

cat("\nMain model summary:\n")
print(summary(fit_main))


# ---- 5. Incremental R² comparison ----------------------------

cat("\nFitting comparison models...\n")

fit_ar1 <- brm(
  mood ~ mood_lag1,
  data = df, family = gaussian(),
  prior = c(prior(normal(0, 0.5), class = b),
            prior(normal(0, 10),  class = Intercept),
            prior(exponential(1), class = sigma)),
  chains = 4, iter = 4000, warmup = 1000,
  seed = 42, file = "fit_ar1"
)

fit_mel <- brm(
  mood ~ mood_lag1 + melatonin,
  data = df, family = gaussian(), prior = prior_main,
  chains = 4, iter = 4000, warmup = 1000,
  seed = 42, file = "fit_mel"
)

fit_age <- brm(
  mood ~ mood_lag1 + agency,
  data = df, family = gaussian(), prior = prior_main,
  chains = 4, iter = 4000, warmup = 1000,
  seed = 42, file = "fit_age"
)

fit_met <- brm(
  mood ~ mood_lag1 + metacognition,
  data = df, family = gaussian(), prior = prior_main,
  chains = 4, iter = 4000, warmup = 1000,
  seed = 42, file = "fit_met"
)

# LOO comparison
cat("\nLOO model comparison (lower = better):\n")
print(loo_compare(loo(fit_ar1), loo(fit_mel), loo(fit_age),
                  loo(fit_met), loo(fit_main)))

# Posterior R² and Delta R²
r2_ar1  <- bayes_R2(fit_ar1)
r2_mel  <- bayes_R2(fit_mel)
r2_age  <- bayes_R2(fit_age)
r2_met  <- bayes_R2(fit_met)
r2_main <- bayes_R2(fit_main)

baseline_r2 <- r2_ar1[,"Estimate"]

delta_r2 <- tibble(
  Model    = c("AR(1) baseline", "+Melatonin", "+Agency", "+Metacognition", "Full model"),
  R2_mean  = c(r2_ar1[,"Estimate"], r2_mel[,"Estimate"],
               r2_age[,"Estimate"], r2_met[,"Estimate"], r2_main[,"Estimate"]),
  R2_lower = c(r2_ar1[,"Q2.5"],  r2_mel[,"Q2.5"],
               r2_age[,"Q2.5"],  r2_met[,"Q2.5"],  r2_main[,"Q2.5"]),
  R2_upper = c(r2_ar1[,"Q97.5"], r2_mel[,"Q97.5"],
               r2_age[,"Q97.5"], r2_met[,"Q97.5"], r2_main[,"Q97.5"])
) %>%
  mutate(
    Delta_R2       = R2_mean  - baseline_r2,
    Delta_R2_lower = R2_lower - baseline_r2,
    Delta_R2_upper = R2_upper - baseline_r2
  )

cat("\nDelta R² (agency hypothesis test):\n")
print(delta_r2)

p_r2 <- delta_r2 %>%
  filter(Model != "AR(1) baseline") %>%
  ggplot(aes(x = reorder(Model, Delta_R2), y = Delta_R2)) +
  geom_col(fill = c("#2E86AB","#A23B72","#F18F01","#4CAF50")) +
  geom_errorbar(aes(ymin = Delta_R2_lower, ymax = Delta_R2_upper), width = 0.2) +
  coord_flip() +
  labs(title = "Incremental Explanatory Power (ΔR²)",
       subtitle = "Above AR(1) baseline",
       x = "", y = "ΔR²") +
  theme_minimal()

print(p_r2)


# ---- 6. Metacontrol interaction model ------------------------

cat("\nFitting metacontrol interaction model...\n")

fit_interaction <- brm(
  mood_z ~ mood_lag1_z + melatonin * metacognition_z,
  data   = df,
  family = gaussian(),
  prior  = c(prior(normal(0, 1),  class = b),
             prior(normal(0, 10), class = Intercept),
             prior(exponential(1), class = sigma)),
  chains = 4, iter = 4000, warmup = 1000,
  seed   = 42, file = "fit_interaction"
)

cat("\nMetacontrol interaction summary:\n")
print(summary(fit_interaction))

p_interaction <- df %>%
  mutate(Metacognition_group = ifelse(
    metacognition > median(metacognition),
    "High Metacognition", "Low Metacognition")) %>%
  group_by(melatonin, Metacognition_group) %>%
  summarise(mood_mean = mean(mood),
            mood_se   = sd(mood) / sqrt(n()),
            .groups = "drop") %>%
  mutate(Melatonin = ifelse(melatonin == 1, "Active", "Control")) %>%
  ggplot(aes(x = Melatonin, y = mood_mean,
             color = Metacognition_group, group = Metacognition_group)) +
  geom_line() +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mood_mean - mood_se,
                    ymax = mood_mean + mood_se), width = 0.1) +
  scale_color_manual(values = c("#2E86AB","#F18F01")) +
  labs(title = "Metacontrol Interaction",
       subtitle = "Does metacognition buffer against melatonin perturbation?",
       x = "Melatonin Condition", y = "Mean Mood Score", color = "") +
  theme_minimal()

print(p_interaction)


# ---- 7. Impulse Response Function ----------------------------

phi_posterior <- as_draws_df(fit_main)$b_mood_lag1
phi_mean  <- mean(phi_posterior)
phi_lower <- quantile(phi_posterior, 0.025)
phi_upper <- quantile(phi_posterior, 0.975)

half_life_mean  <- log(0.5) / log(phi_mean)
half_life_lower <- log(0.5) / log(phi_upper)
half_life_upper <- log(0.5) / log(phi_lower)

cat(sprintf("\nphi = %.3f [%.3f, %.3f]\n", phi_mean, phi_lower, phi_upper))
cat(sprintf("Half-life = %.1f observations (~%.1f hours)\n",
            half_life_mean, half_life_mean * 8))

p_irf <- tibble(
  h     = 0:18,
  irf   = phi_mean^(0:18),
  lower = phi_lower^(0:18),
  upper = phi_upper^(0:18)
) %>%
  ggplot(aes(x = h, y = irf)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, fill = "#2E86AB") +
  geom_line(color = "#2E86AB", linewidth = 1) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50") +
  annotate("text", x = 13, y = 0.52,
           label = "Half-life threshold", size = 3, color = "gray50") +
  labs(title = "Impulse Response Function",
       subtitle = sprintf("Half-life = %.1f observations (%.1f hours)",
                          half_life_mean, half_life_mean * 8),
       x = "Time steps (observations)", y = "IRF(h) = phi^h") +
  theme_minimal()

print(p_irf)


# ---- 8. State-space model ------------------------------------

cat("\nFitting state-space model...\n")

fit_ss <- bsts(
  df$mood,
  state.specification = AddLocalLevel(list(), df$mood),
  niter = 2000,
  seed  = 42
)

state_mean  <- colMeans(fit_ss$state.contributions[,1,])
state_lower <- apply(fit_ss$state.contributions[,1,], 2, quantile, 0.025)
state_upper <- apply(fit_ss$state.contributions[,1,], 2, quantile, 0.975)

p_ss <- tibble(
  timestamp = df$timestamp,
  observed  = df$mood,
  latent    = state_mean,
  lower     = state_lower,
  upper     = state_upper
) %>%
  ggplot(aes(x = timestamp)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, fill = "#A23B72") +
  geom_line(aes(y = latent), color = "#A23B72", linewidth = 1) +
  geom_point(aes(y = observed), alpha = 0.4, size = 0.8, color = "gray40") +
  labs(title = "State-Space Model: Latent Affective Trajectory",
       subtitle = "Line = filtered latent state; Points = observed mood",
       x = "Date", y = "Mood Score") +
  theme_minimal()

print(p_ss)


# ---- 9. Phase 1 vs Phase 2 prediction deviation --------------

df_p1 <- df %>% filter(phase == "identification")
df_p2 <- df %>% filter(phase == "perturbation")

fit_p1 <- brm(
  mood ~ mood_lag1 + agency + metacognition,
  data = df_p1, family = gaussian(), prior = prior_main,
  chains = 4, iter = 4000, warmup = 1000,
  seed = 42, file = "fit_p1"
)

pred_p2    <- posterior_predict(fit_p1, newdata = df_p2)
pred_mean  <- colMeans(pred_p2)
pred_lower <- apply(pred_p2, 2, quantile, 0.025)
pred_upper <- apply(pred_p2, 2, quantile, 0.975)

deviation_df <- df_p2 %>%
  mutate(
    pred_mean  = pred_mean,
    pred_lower = pred_lower,
    pred_upper = pred_upper,
    outside_ci = mood < pred_lower | mood > pred_upper
  )

pct_outside <- mean(deviation_df$outside_ci) * 100
cat(sprintf("\n%.1f%% of Phase 2 observations outside Phase 1 prediction interval\n",
            pct_outside))

p_deviation <- deviation_df %>%
  ggplot(aes(x = timestamp)) +
  geom_ribbon(aes(ymin = pred_lower, ymax = pred_upper),
              alpha = 0.2, fill = "#4CAF50") +
  geom_line(aes(y = pred_mean), color = "#4CAF50", linetype = "dashed") +
  geom_point(aes(y = mood, color = outside_ci), size = 1.5) +
  scale_color_manual(values = c("gray40","#E74C3C"),
                     labels = c("Within CI","Outside CI")) +
  labs(title = "Phase 2: Observed vs. Phase-1-Predicted Mood",
       subtitle = sprintf("%.1f%% of observations outside prediction interval",
                          pct_outside),
       x = "Date", y = "Mood Score", color = "") +
  theme_minimal()

print(p_deviation)


# ---- 10. Posterior distributions -----------------------------

p_posterior <- mcmc_areas(
  as_draws_df(fit_main),
  pars = c("b_melatonin","b_agency","b_metacognition","b_mood_lag1"),
  prob = 0.95
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  scale_y_discrete(labels = c(
    "b_mood_lag1"     = "Affective Inertia (phi)",
    "b_melatonin"     = "Melatonin (beta_1)",
    "b_agency"        = "Agency (beta_2)",
    "b_metacognition" = "Metacognition (beta_3)"
  )) +
  labs(title = "Posterior Distributions: Main Model Coefficients",
       subtitle = "Shaded region = 95% credible interval") +
  theme_minimal()

print(p_posterior)


# ---- 11. Save all figures ------------------------------------

plots <- list(
  p_ts, p_mel_dist, p_lag, p_r2,
  p_interaction, p_irf, p_ss, p_deviation, p_posterior
)

names(plots) <- c(
  "01_timeseries", "02_mood_distribution", "03_affective_inertia",
  "04_delta_r2", "05_metacontrol_interaction", "06_irf",
  "07_state_space", "08_phase_deviation", "09_posterior"
)

dir.create("miura_figures", showWarnings = FALSE)

for (name in names(plots)) {
  ggsave(
    filename = paste0("miura_figures/", name, ".png"),
    plot     = plots[[name]],
    width    = 8, height = 5, dpi = 300
  )
}

cat("All figures saved to miura_figures/\n")


# ---- 12. Results summary -------------------------------------

results_summary <- tibble(
  Analysis = c(
    "Affective Inertia (phi)",
    "Melatonin effect (beta_1)",
    "Agency effect (beta_2)",
    "Metacognition effect (beta_3)",
    "Delta R2 Melatonin",
    "Delta R2 Agency",
    "Delta R2 Metacognition",
    "Melatonin x Metacognition interaction",
    "IRF Half-life (observations)",
    "IRF Half-life (hours)",
    "% Phase 2 outside prediction CI"
  ),
  Value = c(
    sprintf("%.3f [%.3f, %.3f]", phi_mean, phi_lower, phi_upper),
    sprintf("%.3f", fixef(fit_main)["melatonin","Estimate"]),
    sprintf("%.3f", fixef(fit_main)["agency","Estimate"]),
    sprintf("%.3f", fixef(fit_main)["metacognition","Estimate"]),
    sprintf("%.4f", delta_r2$Delta_R2[2]),
    sprintf("%.4f", delta_r2$Delta_R2[3]),
    sprintf("%.4f", delta_r2$Delta_R2[4]),
    sprintf("%.3f", fixef(fit_interaction)["melatonin:metacognition_z","Estimate"]),
    sprintf("%.1f", half_life_mean),
    sprintf("%.1f", half_life_mean * 8),
    sprintf("%.1f%%", pct_outside)
  )
)

cat("\n============================================================\n")
cat("Results Summary\n")
cat("============================================================\n")
print(results_summary, n = Inf)

cat("\nAnalysis complete.\n")
