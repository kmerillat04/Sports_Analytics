---
title: "Cincinnati Reds Player Evaluation Report"
author: "Karissa Merillat"
date: "`r Sys.Date()`"
output: pdf_document
editor_options: 
  markdown: 
    wrap: 72
---

# Introduction

In this report, I present an analysis of whether the Cincinnati Reds 
should have signed or released players based on their Runs Above Average (RAA) 
during the 2024 MLB season. RAA is a valuable metric because it estimates how many 
runs a player contributes relative to an average MLB player, while adjusting for 
opportunities. Teams use many statistics—batted-ball data, defensive metrics, age 
curves, contract value—but RAA provides a clean, model-based lens for estimating 
net run contribution, which directly correlates with wins.

Understanding RAA matters because MLB teams operate under roster constraints. 
A player who produces +5 RAA contributes roughly half a win**, while  
–5 RAA may cost the team competitive value** over a season.

Here, I use R and statistical modeling to compare each Reds player's estimated 
offensive contribution to the league average.

This report is organized as follows:

- **Section 2:** Packages and data  
- **Section 3:** Modeling procedure (team averages, scaling, regression)  
- **Section 4:** Player RAA predictions  
- **Section 5:** Conclusion and limitations  

---

# Setup

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)

library(dplyr)
library(baseballr)
library(broom)
library(ggplot2)
library(ggcorrplot)
library(Lahman)
library(lubridate)
library(mgcv)

pkg_table <- tibble::tibble(
Package = c("dplyr", "baseballr", "broom", "ggplot2", "ggcorrplot",
"Lahman", "lubridate", "mgcv"),
Purpose = c(
"Data manipulation",
"Accessing MLB data and statistics",
"Tidying model outputs",
"Creating visualizations",
"Correlation heatmaps",
"Historical MLB data",
"Handling dates",
"Generalized additive modeling"
)
)

knitr::kable(pkg_table, caption = "Packages Used in the Analysis")

# Data Analysis

For this analysis, I use publicly available Cincinnati Reds data, including
the 2024 roster.
Roster source: https://www.mlb.com/reds/roster

To compare Reds hitters against MLB norms, I create a league-average dataset
from 2010–2024.

df_teams <- Teams %>%
filter(yearID >= 2010) %>%
mutate(
X1B = H - X2B - X3B - HR,
BB_HBP = BB + HBP
) %>%
select(yearID, R, X1B, X2B, X3B, HR, BB_HBP)

2024 league-average team statistics:
avg_team <- df_teams %>%
filter(yearID == 2024) %>%
summarise(across(everything(), mean))

Average out recorded:
avg_outs <- Teams %>%
filter(yearID == 2024) %>%
summarise(outs = mean(IPouts))

# Player-Level Data
To retrieve player IDs, I used:
playerInfo(nameLast = "Benson")

Example: Benson's MLB playerID = "bensonwi01"

benson <- Batting %>%
filter(playerID == "bensowi01", yearID == 2024) %>%
mutate(
X1B = H - X2B - X3B - HR,
BB_HBP = BB + IBB + HBP,
Outs = .982 * AB - H + GIDP + SF + SH + CS
) %>%
select(yearID, R, X1B, X2B, X3B, HR, BB_HBP, Outs)

Scale factor comparing Benson's outs to MLB average:
benson_scale <- (avg_outs$outs - benson$Outs) / avg_outs$outs

Weighted average team with Benson's adjusted opportunities:
avg_team_w_benson <- (avg_team * benson_scale) %>%
bind_cols(
benson %>% select(yearID, R, X1B, X2B, X3B, HR, BB_HBP)
)

Regression model estimating runs produced from offensive stats:
lm_runs <- lm(R ~ . - yearID, data = df_teams)

Runs Above Average for Benson
raa_benson <- predict(lm_runs, newdata = avg_team_w_benson) -
predict(lm_runs, newdata = avg_team)

raa_benson

# Player Predictions Table
library(readxl)
library(kableExtra)

pred_table <- read_excel("Baseball Data.xlsx", sheet = 1) %>%
select(FirstName, LastName, Prediction) %>%
mutate(Prediction = round(Prediction, 3))

kable(pred_table, caption = "Cincinnati Reds Player Predictions") %>%
kable_styling(latex_options = c("striped", "hold_position"))

# Conclusion
Using this procedure, I was able to estimate Runs Above Average (RAA) for each Cincinnati Reds player based on 2024 performance.
These predictions represent only one analytical lens through which to evaluate players. A complete front office decision also considers defense, baserunning, contract cost, injury history, and player development projections.
In future analyses, I would like to 
- Incorporate Statcast expected metrics
- Compare RAA to other defensive stats
This project demonstrates how data-driven evaluation can support decision-making in professional baseball.
