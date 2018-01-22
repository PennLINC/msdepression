library(MASS)
library(Matching)
library(tidyr)
library(readr)
library(effsize)
library(dplyr)

###Loading Data
alldata<-read.csv("OlfactionFromStata_2017_06-19.csv") %>% 
  group_by(group) %>%
  arrange(group,bblid)
View(alldata)
str(alldata)
colnames(alldata)

#Cleaning up variables
alldata$anyspectrum<-as.factor(alldata$anyspectrum)

###Calculating and Z-transforming CNB Categories 
# Creating normalized summary variables
zacexe <- as.vector(
  scale(
    rowMeans(
      data.frame(alldata$zaclnb, alldata$zacpcet, alldata$zacpcpt), na.rm = TRUE)
  ))

zacmem <- as.vector(
  scale(
    rowMeans(
      data.frame(alldata$zaccpf, alldata$zaccpw, alldata$zacvolt), na.rm = TRUE)
  ))

zaccog <- as.vector(
  scale(
    rowMeans(
      data.frame(alldata$zacpvrt, alldata$zacpmat, alldata$zacplot), na.rm = TRUE)
  ))

zacsoc <- as.vector(
  scale(
    rowMeans(
      data.frame(alldata$zacadt, alldata$zacer, alldata$zacedf), na.rm = TRUE)
  ))

zacall <- as.vector(
  scale(
    rowMeans(
      data.frame(zacexe, zacmem, zaccog, zacsoc), na.rm = TRUE)
  ))

#Merging with existing data
alldata$zacexe = zacexe
alldata$zacmem = zacmem
alldata$zaccog = zaccog
alldata$zacsoc = zacsoc
alldata$zacall = zacall

alldata<-data.frame(alldata,zacall)
alldata$zacall.1 <- NULL

#Checking
colnames(alldata)
summary(alldata$zacall)
sd(alldata$zacall, na.rm = TRUE)

###Selecting Important Variables for Analysis
dat <- select(alldata, bblid, group, sex, race, age, edu, avgedu, hand, smoker, anysmoke,
              id, disc, lyral, cit, 
              zacexe, zacmem, zaccog, zacsoc, zacall, wratstd, gafc, comtgenotype,
              positive, negative, sipstot, anyspectrum, psyscale)

View(dat)
table(dat$group)

###Matching 22q and ND
#Creating 0/1 vs. T/F variable for groups
dat<-mutate(dat, Tr=as.logical(dat$group=="22q"))

#Alternative method
new <- dat$group
new[as.matrix(new)="22q"] <- 1
new[as.matrix(new)="NC/LR"] <- 0
data.frame(dat, new)

#Match
matchstats<-Match(Tr=dat$Tr, X=as.matrix(cbind(dat$sex,dat$age)), replace=FALSE, ties=FALSE)
str(matchstats)

#Stiching together matched rows
matchq22<-dat[matchstats$index.treated,]
matchcontrol<-dat[matchstats$index.control,]

match<-rbind(matchq22, matchcontrol)
match<-group_by(match, group)
str(match)
View(match)
View(matchq22)
View(matchcontrol)

save(match, file="/Users/ericwpetersen/Desktop/Olfaction R Files/match.R")
save(matchq22, file="/Users/ericwpetersen/Desktop/Olfaction R Files/matchq22.R")
save(matchcontrol, file="/Users/ericwpetersen/Desktop/Olfaction R Files/matchcontrol.R")

###Matched Sample Description
#Demographics
summary(match[,2:5])
summary(matchq22[,2:5])
summary(matchcontrol[,2:5])

t.test(matchq22$age, y=matchcontrol$age)

###Unmatched Sample Description ...
q22<-filter(dat, group=="22q")
control<-filter(dat, group=="NC/LR")

save(dat, file="/Users/ericwpetersen/Desktop/Olfaction R Files/dat.R")
save(q22, file="/Users/ericwpetersen/Desktop/Olfaction R Files/q22.R")
save(control, file="/Users/ericwpetersen/Desktop/Olfaction R Files/control.R")

#Demographics
table(q22$psyscale)
table(dat$group, dat$smoker)

summary(q22[,2:5])
summary(control[,2:5])

table(dat$sex, dat$group)
fisher.test(table(dat$sex, dat$group))

table(dat$race, dat$group)
fisher.test(table(dat$race, dat$group))

t.test(x=q22$age, y=control$age)

fisher.test(table(dat$group, dat$smoker))

#Olfactory measures
hist(q22$id)
hist(q22$disc)
hist(q22$age)
hist(q22$cit)
hist(q22$lyral)
hist(control$id)
hist(control$disc)
hist(control$age)
hist(control$cit)
hist(control$lyral)

plot(q22$age, q22$id)
plot(q22$age, q22$disc)
plot(q22$age, q22$cit)
plot(q22$age, q22$lyral)
plot(control$age, control$id)
plot(control$age, control$disc)
plot(control$age, control$cit)
plot(control$age, control$lyral)

cor.test(q22$age, y=q22$id, method="spearman")
cor.test(q22$age, y=q22$disc, method="spearman")
cor.test(q22$age, y=q22$cit, method="spearman")
cor.test(q22$age, y=q22$lyral, method="spearman")
cor.test(control$age, y=control$id, method="spearman")
cor.test(control$age, y=control$disc, method="spearman")
cor.test(control$age, y=control$cit, method="spearman")
cor.test(control$age, y=control$lyral, method="spearman")

###Calculating residuals for olfactory measures and age
#Updating data frame with z-transformed age variables
zage<-(dat$age - mean(dat$age))/sd(dat$age)
hist(zage)

zagesquared <- zage^2
zagecubed <- zage^3

dat<-data.frame(dat, zage, zagesquared, zagecubed)
View(dat)

#Calculating residuals
idz<-scale(lm(id ~ zage + zagesquared + zagecubed, data=dat)$residuals)
plot(dat$id, idz)

discz<-scale(
  residuals(
    lm(disc ~ zage + zagesquared + zagecubed, data=dat, na.action=na.exclude)
  ))
plot(dat$disc, discz)

citz<-scale(
  residuals(
    lm(cit ~ zage + zagesquared + zagecubed, data=dat, na.action = na.exclude)
  ))
citz<- 0-citz
plot(dat$cit, citz)

lyralz<-scale(
  residuals(
    lm(lyral ~ zage + zagesquared + zagecubed, data=dat, na.action = na.exclude)
  ))
lyralz<- 0-lyralz
plot(dat$lyral, lyralz)

#Integration into dataframe
dat<-data.frame(dat,idz, discz)

dat$citz<-NULL
dat$lyralz<-NULL
dat<-data.frame(dat,citz, lyralz)

View(dat)

q22<-filter(dat, group=="22q")
control<-filter(dat, group=="NC/LR")

save(dat, file="/Users/ericwpetersen/Desktop/Olfaction R Files/dat.R")
save(q22, file="/Users/ericwpetersen/Desktop/Olfaction R Files/q22.R")
save(control, file="/Users/ericwpetersen/Desktop/Olfaction R Files/control.R")

### Comparing olfaction measures between groups

#Characterizing data
hist(q22$idz)
hist(control$idz)
hist(q22$discz)
hist(control$discz)
hist(q22$citz)
hist(control$citz)
hist(q22$lyralz)
hist(control$lyralz)

#Comparisons with ttests
t.test(x=q22$idz, y=control$idz)
cohen.d(q22$idz, f=control$idz, na.rm=TRUE)
boxplot(q22$idz, control$idz, names = c("22q", "Control"), main="ID")

t.test(x=q22$discz, y=control$discz)
cohen.d(q22$discz, f=control$discz, na.rm = TRUE)
boxplot(q22$discz, control$discz, names = c("22q", "Control"), main="DISC")

t.test(x=q22$citz, y=control$citz)
cohen.d(q22$citz, f=control$citz, na.rm = TRUE)
boxplot(q22$citz, control$citz, names = c("22q", "Control"), main="Citralva")

t.test(x=q22$lyralz, y=control$lyralz)
cohen.d(q22$lyralz, f=control$lyralz, na.rm = TRUE)
boxplot(q22$lyralz, control$lyralz, names = c("22q", "Control"), main="Lyral")

###Sex effect
t.test(q22$idz~q22$sex)
t.test(control$idz~control$sex)

t.test(q22$discz~q22$sex)
t.test(control$discz~control$sex)

t.test(q22$citz~q22$sex)
t.test(control$citz~control$sex)

t.test(q22$lyralz~q22$sex)
t.test(control$lyralz~control$sex)

###Relation to cognition
#ID vs. cognitive domains (Sig: cog in controls, mem in 22q)
summary(lm(idz ~ sex + zacall, data=q22, na.action=na.exclude))
summary(lm(idz ~ sex + zacall, data=control, na.action=na.exclude))

summary(lm(idz ~ sex + zacexe, data=q22, na.action=na.exclude))
summary(lm(idz ~ sex + zacexe, data=control, na.action=na.exclude))

summary(lm(idz ~ sex + zacmem, data=q22, na.action=na.exclude))
summary(lm(idz ~ sex + zacmem, data=control, na.action=na.exclude))

summary(lm(idz ~ sex + zaccog, data=q22, na.action=na.exclude))
summary(lm(idz ~ sex + zaccog, data=control, na.action=na.exclude))

summary(lm(idz ~ sex + zacsoc, data=q22, na.action=na.exclude))
summary(lm(idz ~ sex + zacsoc, data=control, na.action=na.exclude))

#DISC vs. cognitive domains (NONE sig)
summary(lm(discz ~ sex + zacall, data=q22, na.action=na.exclude))
summary(lm(discz ~ sex + zacall, data=control, na.action=na.exclude))

summary(lm(discz ~ sex + zacexe, data=q22, na.action=na.exclude))
summary(lm(discz ~ sex + zacexe, data=control, na.action=na.exclude))

summary(lm(discz ~ sex + zacmem, data=q22, na.action=na.exclude))
summary(lm(discz ~ sex + zacmem, data=control, na.action=na.exclude))

summary(lm(discz ~ sex + zaccog, data=q22, na.action=na.exclude))
summary(lm(discz ~ sex + zaccog, data=control, na.action=na.exclude))

summary(lm(discz ~ sex + zacsoc, data=q22, na.action=na.exclude))
summary(lm(discz ~ sex + zacsoc, data=control, na.action=na.exclude))

#Citralva threshold vs. cognitive domains (NONE sig)
summary(lm(citz ~ sex + zacall, data=q22, na.action=na.exclude))
summary(lm(citz ~ sex + zacall, data=control, na.action=na.exclude))

summary(lm(citz ~ sex + zacexe, data=q22, na.action=na.exclude))
summary(lm(citz ~ sex + zacexe, data=control, na.action=na.exclude))

summary(lm(citz ~ sex + zacmem, data=q22, na.action=na.exclude))
summary(lm(citz ~ sex + zacmem, data=control, na.action=na.exclude))

summary(lm(citz ~ sex + zaccog, data=q22, na.action=na.exclude))
summary(lm(citz ~ sex + zaccog, data=control, na.action=na.exclude))

summary(lm(citz ~ sex + zacsoc, data=q22, na.action=na.exclude))
summary(lm(citz ~ sex + zacsoc, data=control, na.action=na.exclude))

#Lyral threshold vs. cognitive domains (Sig: overall in 22q, soc in 22q)
summary(lm(lyralz ~ sex + zacall, data=q22, na.action=na.exclude))
summary(lm(lyralz ~ sex + zacall, data=control, na.action=na.exclude))

summary(lm(lyralz ~ sex + zacexe, data=q22, na.action=na.exclude))
summary(lm(lyralz ~ sex + zacexe, data=control, na.action=na.exclude))

summary(lm(lyralz ~ sex + zacmem, data=q22, na.action=na.exclude))
summary(lm(lyralz ~ sex + zacmem, data=control, na.action=na.exclude))

summary(lm(lyralz ~ sex + zaccog, data=q22, na.action=na.exclude))
summary(lm(lyralz ~ sex + zaccog, data=control, na.action=na.exclude))

summary(lm(lyralz ~ sex + zacsoc, data=q22, na.action=na.exclude))
summary(lm(lyralz ~ sex + zacsoc, data=control, na.action=na.exclude))

#Group effect controlling for cognition
summary(lm(idz ~ sex + group, data=dat, na.action=na.exclude))
summary(lm(idz ~ sex + group + zacall, data=dat, na.action=na.exclude))

summary(lm(discz ~ sex + group, data=dat, na.action=na.exclude))
summary(lm(discz ~ sex + group + zacall, data=dat, na.action=na.exclude))

summary(lm(citz ~ sex + group, data=dat, na.action=na.exclude))
summary(lm(citz ~ sex + group + zacall, data=dat, na.action=na.exclude))

summary(lm(lyralz ~ sex + group, data=dat, na.action=na.exclude))
summary(lm(lyralz ~ sex + group + zacall, data=dat, na.action=na.exclude))

#Group effect controlling for cognition (not controlling for sex - same results)
summary(lm(idz ~ group, data=dat, na.action=na.exclude))
summary(lm(idz ~ group + zacall, data=dat, na.action=na.exclude))

summary(lm(discz ~ group, data=dat, na.action=na.exclude))
summary(lm(discz ~ group + zacall, data=dat, na.action=na.exclude))

summary(lm(citz ~ group, data=dat, na.action=na.exclude))
summary(lm(citz ~ group + zacall, data=dat, na.action=na.exclude))

summary(lm(lyralz ~ group, data=dat, na.action=na.exclude))
summary(lm(lyralz ~ group + zacall, data=dat, na.action=na.exclude))


###Association with COMT genotype
comtrevised <- factor(x=q22$comtgenotype, levels = c("Met", "Val"), exclude = "")
q22<-data.frame(q22,comtrevised)
save(q22, file="/Users/ericwpetersen/Desktop/Olfaction R Files/q22.R")

t.test(q22$idz~q22$comtrevised)
t.test(q22$discz~q22$comtrevised)
t.test(q22$citz~q22$comtrevised)
t.test(q22$lyralz~q22$comtrevised)

###Relationship to SIPS and negative symptoms
#SIPS total (disc significantly related to total sips)
summary(lm(idz ~ sipstot + group, data=dat, na.action = na.exclude))
summary(lm(discz ~ sipstot + group, data=dat, na.action = na.exclude))
summary(lm(citz ~ sipstot + group, data=dat, na.action = na.exclude))
summary(lm(lyralz ~ sipstot + group, data=dat, na.action = na.exclude))

#Negative symptoms (citralva threshold and disc significantly related to neg s/s, opposite directions)
summary(lm(idz ~ negative + group, data=dat, na.action = na.exclude))
summary(lm(discz ~ negative + group, data=dat, na.action = na.exclude))
summary(lm(citz ~ negative + group, data=dat, na.action = na.exclude))
summary(lm(lyralz ~ negative + group, data=dat, na.action = na.exclude))

###Midline defects
midline<-read.csv("JustMidline_2017_07_11.csv")
q22<-merge(q22, midline, by = "bblid")
q22$midlinedefect <- as.factor(q22$midlinedefect)

t.test(q22$idz ~ q22$midlinedefect)
boxplot(q22$idz ~ q22$midlinedefect, xlab="Midline Defects", ylab="ID")

t.test(q22$discz ~ q22$midlinedefect)
t.test(q22$citz ~ q22$midlinedefect)
t.test(q22$lyralz ~ q22$midlinedefect)

###Olfactory sulcus depth
sulci<-read.csv("Olfactory_Sulci_2017_07-11.csv")
sulci$psychosis<-as.factor(sulci$psychosis)
str(sulci)
View(sulci)

match(sulci$bblid, q22$bblid)
#4 matches for 22q

match(sulci$bblid, control$bblid)
#18 matches for controls

anova(lm(left_sulcus_length_DF ~ group, data=sulci))
boxplot(sulci$left_sulcus_length_DF ~ sulci$group)

anova(lm(right_sulcus_length_DF ~ group, data=sulci))
boxplot(sulci$right_sulcus_length_DF ~ sulci$group)

anova(lm(mean_sulcus_length_DF ~ group, data=sulci))
boxplot(sulci$mean_sulcus_length_DF ~ sulci$group)

###END
save(dat, file="/Users/ericwpetersen/Desktop/Olfaction R Files/dat.R")
save(q22, file="/Users/ericwpetersen/Desktop/Olfaction R Files/q22.R")
save(control, file="/Users/ericwpetersen/Desktop/Olfaction R Files/control.R")
save(sulci, file="/Users/ericwpetersen/Desktop/Olfaction R Files/sulci.R")