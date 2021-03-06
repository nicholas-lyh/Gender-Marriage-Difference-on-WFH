### Load Packages
library(foreign)
library(stargazer)
library(haven)
library(ggplot2)
library(Hmisc)
library(chron)
library(lattice)
library(dummies)
library(lfe)
library(sandwich)
library(lmtest)
library(miceadds)
library(multiwayvcov)
library(RCurl)
library(gdata) 
library(zoo)
library(plm)
library(margins)
library(multcomp)
library(corrplot)

### set directory
setwd("C:/Users/leeye/Desktop")


### import data
performance <- na.omit(data.frame(read_dta("Performance.dta")))


### Create additional variables
performance<-within(performance,{D_group<-ifelse(expgroup==1, "Experiment Group", "Control Group")})
performance<-within(performance,{gender<-ifelse(men==1, "Man", "Women")})
performance<-within(performance,{relationship<-ifelse(married==1, "Married", "Not Married")})
performance<-within(performance,{ET<-ifelse(experiment_treatment==1, "Treated", "Not-treated")})
performance<-within(performance,{treatment<-ave(experiment_treatment,year_week,FUN=max)})
performance<-within(performance,{period<-ifelse(treatment==1, "During Treatment", "Before Treatment")})


### correlation 
cor(performance$logdaysworked, performance$perform1, method = "pearson")
cor(performance$grosswage, performance$perform1, method = "pearson")
cor(performance$tenure, performance$perform1, method = "pearson")
cor(performance$age, performance$perform1, method = "pearson")


###### Data exploration with graphs
fig5 <- ggplot(performance, aes(x = logdaysworked, y = perform1)) + 
  geom_point(size = 0.3) + theme_classic() +
  geom_smooth(method = "lm", color = "red", size = 1, se = TRUE,
              formula = y ~ poly(x,2)) +
  labs(title = "Figure 5: Relationship of Days Worked and Performance", 
       x = "Normalized Days Worked", 
       y = "Normalized Performance") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5), 
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14))
   

fig6 <- ggplot(performance, aes(x = grosswage, y = perform1)) + 
  geom_point(size = 0.3) + theme_classic() + 
  geom_smooth(method = "lm", color = "red", size = 1, se = TRUE,
              formula = y ~ poly(x, 2)) + 
  labs(title = "Figure 6: Relationship of Gross Wages and Performance", 
       x = "Normalized Gross Wages", 
       y = "Normalized Performance") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5), 
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14))


fig3 <- ggplot(performance, aes(x = tenure, y = perform1)) + 
  geom_point(size = 0.3) + theme_classic() + 
  geom_smooth(method = "lm", color = "red", size = 1, se = TRUE,
              formula = y ~ poly(x, 2)) +
  labs(title = "Figure 3: Relationship of Staff Tenure and Performance", 
       x = "Staff Tenure", 
       y = "Normalized Performance") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5), 
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14))
  

fig4 <- ggplot(performance, aes(x = age, y = perform1)) + 
  geom_point(size = 0.3) + theme_classic() + 
  geom_smooth(method = "lm", color = "red", size = 1, se = TRUE,
              formula = y ~ poly(x, 2)) +
  labs(title = "Figure 4: Relationship of Staff Age and Performance", 
       x = "Staff Age", 
       y = "Normalized Performance") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5), 
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14))


fig1 <- densityplot(~perform1 | D_group + period,data=performance,
            groups=relationship,
            par.settings = list(superpose.line = list(col = c("blue","red"))),
            xlab="Normalized Performance",
            main="Figure 1: Performance Comparison by Marital Status",
            plot.points=FALSE,
            layout = c(2,2), 
            key = list(space = "bottom", 
                       lines = list(col=c("blue","red"), lwd = 8),  
                       text = list(c("Married", "Not Married"))))


fig2 <- densityplot(~perform1 | D_group + period,data=performance,
            groups=gender,
            par.settings = list(superpose.line = list(col = c("blue","red"))),
            xlab="Normalized Performance",
            main="Figure 2: Performance Comparison by Gender",
            plot.points=FALSE,
            layout = c(2,2),
            key = list(space = "bottom", 
                       lines = list(col=c("blue","red"), lwd = 8),  
                       text = list(c("Men", "Women"))))




###### Hypothesis 1
# Marriage affects the mean of performance when it comes to treatment
# Splitting data into 2^3 = 8 groups. 
# Splitting between control group, experiment group
# between During treatment, before treatment 
# between married, not married. 
# Group naming: B = Before (treatment = 0), D = During Treatment (treatment = 1), 
# E = Experiment Group (expgroup = 1), C= Control Group (expgroup = 0), 
# M = Married (married = 1), N = Not married (married = 0)
# for example: DEM = During experiment, Experiment group and Married;
# BCN = Before experiment, Control group, and Not-married
performance <- within(performance,{H1group <- 
    ifelse(performance$treatment==1 & performance$expgroup==1 & performance$married==1, "DEM", 
           ifelse(performance$treatment==0 & performance$expgroup==1 & performance$married==1, "BEM",
                  ifelse(performance$treatment==1 & performance$expgroup==0 & performance$married==1, "DCM",
                         ifelse(performance$treatment==0 & performance$expgroup==0 & performance$married==1, "BCM",
                                ifelse(performance$treatment==1 & performance$expgroup==1 & performance$married==0, "DEN",
                                       ifelse(performance$treatment==0 & performance$expgroup==1 & performance$married==0, "BEN",
                                              ifelse(performance$treatment==1 & performance$expgroup==0 & performance$married==0, "DCN",
                                                     ifelse(performance$treatment==0 & performance$expgroup==0 & performance$married==0, "BCN",""))))))))})

performance$H1group <- factor(performance$H1group)


# using the glht function from the multcomp package 
# finding the difference of means among different groups with respective T values and p-value
Hypo1 <- summary(glht(aov(perform1 ~ H1group, data=performance), linfct = mcp(H1group = "Tukey")))
Hypo1result <- tidy(Hypo1, conf.int = TRUE, conf.level = 0.95)
options(tibble.print_max = Inf)
Hypo1result

###### Hypothesis 2
# Gender affects the mean of performance when it comes to treatment
# Mostly same as the previous hypothesis. 
# Splitting between gender. 
# Group naming: M = Male (men = 1), F = Female (men = 0)
# for example: DEM = During experiment, Experiment group and Male;
# BCF = Before experiment, Control group, and Female
performance <- within(performance,{H2group <- 
  ifelse(performance$treatment==1 & performance$expgroup==1 & performance$men==1, "DEM", 
         ifelse(performance$treatment==0 & performance$expgroup==1 & performance$men==1, "BEM",
                ifelse(performance$treatment==1 & performance$expgroup==0 & performance$men==1, "DCM",
                       ifelse(performance$treatment==0 & performance$expgroup==0 & performance$men==1, "BCM",
                              ifelse(performance$treatment==1 & performance$expgroup==1 & performance$men==0, "DEF",
                                     ifelse(performance$treatment==0 & performance$expgroup==1 & performance$men==0, "BEF",
                                            ifelse(performance$treatment==1 & performance$expgroup==0 & performance$men==0, "DCF",
                                                   ifelse(performance$treatment==0 & performance$expgroup==0 & performance$men==0, "BCF",""))))))))})

performance$H2group <- factor(performance$H2group)


# using the glht function from the multcomp package 
# finding the difference of means among different groups with respective T values and p-value
Hypo2 <- summary(glht(aov(perform1 ~ H2group, data=performance), linfct = mcp(H2group = "Tukey")))
Hypo2result <- tidy(Hypo2, conf.int = TRUE, conf.level = 0.95)
options(tibble.print_max = Inf)
Hypo2result


###### Regression
performancepanel <- pdata.frame(na.omit(performance), index=c("personid","year_week"))

### Pooled OLS Estimator
POLS <- plm(perform1 ~ experiment_treatment + men + married + men*married,
            data = performancepanel, model= "pooling")

### First Differences Estimator
FD <- plm(perform1 ~ experiment_treatment + men + married + men*married,
          data = performancepanel, model= "fd")

### Fixed Effects Estimator
FE <- plm(perform1 ~ experiment_treatment + men + married + men*married,
          data = performancepanel, model= "within", effect = "twoway")

### Random Effects Estimator
RANDOM <- plm(perform1 ~ experiment_treatment + men + married + men*married,
              data = performancepanel, model= "random")

stargazer(POLS, FD, FE, RANDOM, 
          type="text",align=TRUE,omit=c("year_week", "personid"), out="table1.html")


### LM test for random effects versus POLS
plmtest(POLS, type = c("bp"))
# Null hypothesis is the variances across entities = zero.
# p-value < 0.05, null hypothesis is rejected
# Random Effect is appropriate


### Serial Correlation
pbgtest(FE)
# p-value < 0.05, null hypothesis is rejected
# There is serial correlation
# Indicating First Differencing could not be an appropriate model


### LM test for Fixed Effects versus POLS
pFtest(FE, POLS)
# p-value < 0.05, null hypothesis is rejected
# Fixed Effect is a better choice than POLS


### Hausman test for Fixed versus Random Effects model
phtest(RANDOM, FE)
# p-value > 0.05, null hypothesis is not rejected
# Random Effect should be used


##########
performance <- within(performance,{Rgroup <- 
  ifelse(performance$married==1 & performance$men==1, "MarriedMan", 
         ifelse(performance$married==0 & performance$men==1, "NotMarriedMan",
                ifelse(performance$married==1 & performance$men==0, "MariedWomen",
                       ifelse(performance$married==0 & performance$men==0, "Not-MarriedWomen",""))))})


  














