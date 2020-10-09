rm(list = ls())

# Load data
#
# 	Description of data in data/icu.dat
#	Source of data described in README.md
icu.dat <- read.table(file="data/icu.dat", header=T)
colnames(icu.dat) <- c("ID", "sta", "age", "sex", "race", "ser",
	"can", "crn", "inf", "cpr", "sys", "hra", "pre", "typ", "fra",
	"po2", "ph", "pco", "bic", "cre", "loc")

# IMPORTANT:
#
#	All of the predictor variables will be dichotomous.
#	Easier to compare odds ratios in the resulting forest plot.

# ----------------------------------------------------------------
# lowLab and highLab need to be carefully written
#
#	IMPORTANT:
# 	Each string in lowLab describes the reference level of each factor
# 	Each string in highLab describes the other level of each factor
sex <- as.factor(icu.dat$sex)
sex_labels <- c("Male", "Female")

ser <- as.factor(icu.dat$ser)
ser_labels <- c("Surgery at admission (No)", "Surgery at admission (Yes)")

age <- as.factor(icu.dat$age >= median(icu.dat$age))
age_labels <- c("Below 60 years old", "60+ years old")

typ <- as.factor(icu.dat$typ)
typ_labels <- c("Elective admission", "Emergency admission")

lowLab <- c(sex_labels[1], ser_labels[1], age_labels[1], typ_labels[1])
highLab <- c(sex_labels[2], ser_labels[2], age_labels[2], typ_labels[2])

icu3.dat <- data.frame(sta=icu.dat$sta, sex=sex, ser=ser, age = age, typ=typ)


# ----------------------------------------------------------------
# Multivariate logistic regression using GLM
#
#	IMPORTANT:
#	Order of predictor variables matches order in lowLab and highLab
output <- glm(sta ~ sex + ser + age + typ, data=icu3.dat, family=binomial)

# ----------------------------------------------------------------
# Plot
source("forest_odds.R")
forest_odds(output, lowLab, highLab, "demo.png")

# Examples using some of the optional arguments:
#
# forest_odds(output, lowLab, highLab, "demo.png", font.size.x=20)
# forest_odds(output, lowLab, highLab, "demo.png", myColors=c("#2b8cbe","black"))

# END OF SCRIPT
# ----------------------------------------------------------------
# ----------------------------------------------------------------