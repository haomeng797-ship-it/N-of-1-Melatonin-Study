# N-of-1 Melatonin × Mood Study
### 70-day randomized self-experiment | Individual behavioral system analysis

---

## Research Question

Does melatonin meaningfully improve momentary emotional valence in a single individual — and relative to what?

The study goes beyond a simple intervention test. By simultaneously tracking **agency** and **metacognition** alongside melatonin, it compares the explanatory power of an external intervention against internal behavioral drivers.

---

## Design

| Parameter | Value |
|---|---|
| Design | N-of-1, A-B randomized |
| Duration | 70 days (2026-02-18 → 2026-04-29) |
| Sampling | 3× daily EMA |
| Primary outcome | Momentary emotional valence (0–100) |
| Intervention | Melatonin (randomized 50/50 schedule) |
| Background condition | Hormonal stabilization (continuous, fixed) |

---

## Variables

| Variable | Role |
|---|---|
| `mood` | Primary outcome |
| `melatonin_taken` | Intervention |
| `agency` | Internal driver — task progress |
| `metacognition` | Internal driver — state awareness |

---

## Analytic Models

**1. AR(1) with external inputs**
```
mood_t = φ · mood_{t-1} + β₁·melatonin + β₂·agency + β₃·metacognition + ε
```
Estimates each variable's contribution above the system's own momentum.

**2. State-Space Model (Kalman Filter)**
Separates latent affective state from measurement noise. Tracks the true underlying emotional trajectory across 70 days.

**3. Explanatory Power Comparison**
Incremental R² for each predictor above the AR(1) baseline:
```
ΔR²(melatonin) vs. ΔR²(agency) vs. ΔR²(metacognition)
```

**4. Impulse Response Function**
How long does a single perturbation persist in the system?
```
IRF(h) = φʰ     Half-life = log(0.5) / log(φ)
```

**5. Metacontrol Interaction**
Does metacognitive awareness buffer the system against external perturbation?
```
mood_t ~ melatonin × metacognition + mood_{t-1}
```

---

## Repository Structure

```
N-of-1-Melatonin-Study/
├── README.md
├── analysis_pipeline.R        ← primary analysis (R / brms)
└── analysis/
    └── miura_analysis.py      ← state-space & IRF pipeline (Python)
```

Data collection pipeline: [protocol-](https://github.com/haomeng797-ship-it/protocol-)

---

*COMM 8590 | Diversity and the End of Average | 2026*
