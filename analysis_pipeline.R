# ==============================================================================
# N-of-1 Melatonin Study: Data Analysis Pipeline
# Description: R script for data cleaning, visualization, and Bayesian modeling.
# ==============================================================================

# --- 1. Load Required Libraries ---
library(dplyr)
library(ggplot2)
library(lubridate)
library(brms)

# --- 2. Load and Preprocess Initial Data ---
# Prompts user to select the CSV file. 
# skip = 1 is used to bypass the custom table header in the CSV.
data <- read.csv(file.choose(), skip = 1, stringsAsFactors = FALSE)

# Calculate daily mean and format date
data <- data %>%
  mutate(daily_mean = (morning + afternoon + night) / 3) %>%
  mutate(date = ymd(date)) %>%
  mutate(melatonin_factor = factor(melatonin, levels = c(0, 1), labels = c("Control", "Melatonin")))

# Initial plot without temporal alignment (for reference only)
ggplot(data, aes(x = date, y = daily_mean)) +
  geom_line(color = "gray50", size = 0.8) +
  geom_point(aes(color = melatonin_factor), size = 4) +
  scale_color_manual(values = c("Control" = "#F8766D", "Melatonin" = "#00BFC4")) +
  labs(
    title = "Initial Data: Melatonin vs Daily Mood (Unadjusted)",
    x = "Date",
    y = "Daily Mean Mood",
    color = "Condition"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# --- 3. Temporal Alignment (Crucial Step) ---
# Shift the melatonin intervention by 1 day (lag) to predict the following day's mood.
data_fixed <- data %>%
  mutate(melatonin_last_night = lag(melatonin, n = 1)) %>%
  filter(!is.na(melatonin_last_night)) %>%
  mutate(daily_mean = (morning + afternoon + night) / 3) %>%
  mutate(date = ymd(date)) %>%
  mutate(melatonin_factor = factor(melatonin_last_night, levels = c(0, 1), labels = c("Control (No Melatonin)", "Melatonin (Taken)")))

# --- 4. Plot Temporally Aligned Data (Intervention Plot) ---
ggplot(data_fixed, aes(x = date, y = daily_mean)) +
  geom_line(color = "#E0E0E0", size = 0.8) +
  geom_point(aes(color = melatonin_factor), size = 4) +
  scale_color_manual(values = c("Control (No Melatonin)" = "#9AB8C2", "Melatonin (Taken)" = "#1B365D")) +
  labs(
    title = "Adjusted: Effect of Last Night's Melatonin on Today's Mood",
    x = "Date",
    y = "Today's Daily Mean Mood",
    color = "Last Night's Condition"
  ) +
  theme_classic() +  
  theme(
    legend.position = "bottom",
    text = element_text(color = "#333333"), 
    axis.title = element_text(face = "bold"), 
    plot.title = element_text(face = "bold", hjust = 0.5)
  )

# --- 5. Bayesian Regression Models ---

# Model 1: Base Bayesian Regression
# Formula: Today's mood predicted by last night's melatonin
model_base <- brm(
  formula = daily_mean ~ melatonin_last_night,
  data = data_fixed,
  family = gaussian(),
  prior = c(
    prior(normal(70, 20), class = Intercept), 
    prior(normal(0, 10), class = b)
  ),
  chains = 4,   
  iter = 4000,  
  seed = 1234   
)

print("--- Summary of Base Model ---")
summary(model_base)

# Model 2: Advanced Bayesian Regression with AR(1) Autocorrelation
# Controls for mood inertia (temporal dependence)
model_ar1 <- brm(
  formula = daily_mean ~ melatonin_last_night,
  data = data_fixed,
  autocor = cor_ar(~ date, p = 1),
  chains = 4,
  iter = 4000,
  seed = 1234
)

print("--- Summary of AR(1) Model ---")
summary(model_ar1)
