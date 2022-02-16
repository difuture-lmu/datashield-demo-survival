DataSHIELD Use-case
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

<!-- README.md is generated from README.Rmd. Please edit that file -->

## About the repository

This repository contains a short use-case base on the three packages
`dsPredictBase`, `dsCalibration`, and `dsROCGLM`. The main intend is to
have a use-case to demonstrate how to distributively evaluate a model
using the distributed ROC-GLM.

The following contains the preparation of test data and a test model as
“setup” while the second part is the analysis. .

### Structure of the repository

TODO

## Setup

### Install packages

Install all packages locally and also on the DataSHIELD test machine:

``` r
remotes::install_github("difuture-lmu/dsPredictBase")
#> Using github PAT from envvar GITHUB_PAT
#> Downloading GitHub repo difuture-lmu/dsPredictBase@HEAD
#> dsBaseClient (NA -> d22ba5140...) [GitHub]
#> backports    (NA -> 1.4.1       ) [CRAN]
#> DSI          (NA -> 1.3.0       ) [CRAN]
#> checkmate    (NA -> 2.0.0       ) [CRAN]
#> DSOpal       (NA -> 1.3.1       ) [CRAN]
#> Downloading GitHub repo datashield/dsBaseClient@HEAD
#> gridExtra    (NA -> 2.3   ) [CRAN]
#> dotCall64    (NA -> 1.0-1 ) [CRAN]
#> data.table   (NA -> 1.14.2) [CRAN]
#> pbapply      (NA -> 1.5-0 ) [CRAN]
#> mathjaxr     (NA -> 1.4-0 ) [CRAN]
#> maps         (NA -> 3.4.0 ) [CRAN]
#> viridis      (NA -> 0.6.2 ) [CRAN]
#> spam         (NA -> 2.8-0 ) [CRAN]
#> panelaggr... (NA -> 0.1.1 ) [CRAN]
#> metafor      (NA -> 3.0-2 ) [CRAN]
#> fields       (NA -> 13.3  ) [CRAN]
#> DSI          (NA -> 1.3.0 ) [CRAN]
#> Installing 12 packages: gridExtra, dotCall64, data.table, pbapply, mathjaxr, maps, viridis, spam, panelaggregation, metafor, fields, DSI
#> Installing packages into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
#> * checking for file ‘/tmp/RtmpVk0D7b/remotes8efe96e199d/datashield-dsBaseClient-d22ba51/DESCRIPTION’ ... OK
#> * preparing ‘dsBaseClient’:
#> * checking DESCRIPTION meta-information ... OK
#> * checking for LF line-endings in source and make files and shell scripts
#> * checking for empty or unneeded directories
#> * building ‘dsBaseClient_6.1.1.tar.gz’
#> Installing package into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
#> Installing 4 packages: backports, DSI, checkmate, DSOpal
#> Installing packages into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
#> Skipping install of 'dsBaseClient' from a github remote, the SHA1 (d22ba514) has not changed since last install.
#>   Use `force = TRUE` to force installation
#> * checking for file ‘/tmp/RtmpVk0D7b/remotes8efe761eadf8/difuture-lmu-dsPredictBase-aab7c2d/DESCRIPTION’ ... OK
#> * preparing ‘dsPredictBase’:
#> * checking DESCRIPTION meta-information ... OK
#> * checking for LF line-endings in source and make files and shell scripts
#> * checking for empty or unneeded directories
#>   NB: this package now depends on R (>= 3.5.0)
#>   WARNING: Added dependency on R >= 3.5.0 because serialized objects in
#>   serialize/load version 3 cannot be read in older versions of R.
#>   File(s) containing such objects:
#>     ‘dsPredictBase/inst/extdata/mod.Rda’
#> * building ‘dsPredictBase_0.0.1.tar.gz’
#> Installing package into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
remotes::install_github("difuture-lmu/dsCalibration")
#> Using github PAT from envvar GITHUB_PAT
#> Downloading GitHub repo difuture-lmu/dsCalibration@HEAD
#> 
#> * checking for file ‘/tmp/RtmpVk0D7b/remotes8efe1a68b4a/difuture-lmu-dsCalibration-1805632/DESCRIPTION’ ... OK
#> * preparing ‘dsCalibration’:
#> * checking DESCRIPTION meta-information ... OK
#> * checking for LF line-endings in source and make files and shell scripts
#> * checking for empty or unneeded directories
#> * building ‘dsCalibration_0.0.1.tar.gz’
#> Installing package into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
remotes::install_github("difuture-lmu/dsROCGLM")
#> Using github PAT from envvar GITHUB_PAT
#> Downloading GitHub repo difuture-lmu/dsROCGLM@HEAD
#> 
#> * checking for file ‘/tmp/RtmpVk0D7b/remotes8efe48b45dba/difuture-lmu-dsROCGLM-2d76f54/DESCRIPTION’ ... OK
#> * preparing ‘dsROCGLM’:
#> * checking DESCRIPTION meta-information ... OK
#> * checking for LF line-endings in source and make files and shell scripts
#> * checking for empty or unneeded directories
#> * building ‘dsROCGLM_0.0.1.tar.gz’
#> Installing package into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
```

### Generate data and fit model

The used data is the `GBSG2` from the `TH.data` packages. For further
details see the help page `?TH.data::GBSG2`. The task is to predict
whether hormonal therapy shows an improvement w.r.t. survival time. The
model we are using is a random forest from the `ranger` package. The
following code uses the `GBSG2` data, splits it into train and test data
with 60 % for training and 40 % for testing. The test data is further
split into 5 parts that are uploaded to DataSHIELD and used to simulate
the distributed setup.

``` r
source(here::here("R/generate-data.R"))
source(here::here("R/create-model.R"))
```

### Install package on DataSHIELD and upload data

``` r
source(here::here("R/upload-data.R"))
source(here::here("R/install-ds-packages.R"))
```

## Analysis

### Log into DataSHIELD test server

``` r
library(DSI)
#> Loading required package: progress
#> Loading required package: R6
library(DSOpal)
library(dsBaseClient)

library(dsPredictBase)
library(dsCalibration)
library(dsROCGLM)

library(ggplot2)

builder = newDSLoginBuilder()

surl     = "https://opal-demo.obiba.org/"
username = "administrator"
password = "password"

datasets = paste0("SRV", seq_len(5L))
for (i in seq_along(datasets)) {
  builder$append(
    server   = paste0("ds", i),
    url      = surl,
    user     = username,
    password = password,
    table    = paste0("DIFUTURE-TEST.", datasets[i])
  )
}

## Get data of the servers:
conn = datashield.login(logins = builder$build(), assign = TRUE)
#> 
#> Logging into the collaborating servers
#> 
#>   No variables have been specified. 
#>   All the variables in the table 
#>   (the whole dataset) will be assigned to R!
#> 
#> Assigning table data...
datashield.symbols(conn)
#> $ds1
#> [1] "D"
#> 
#> $ds2
#> [1] "D"
#> 
#> $ds3
#> [1] "D"
#> 
#> $ds4
#> [1] "D"
#> 
#> $ds5
#> [1] "D"
ds.summary("D")
#> $ds1
#> $ds1$class
#> [1] "data.frame"
#> 
#> $ds1$`number of rows`
#> [1] 52
#> 
#> $ds1$`number of columns`
#> [1] 10
#> 
#> $ds1$`variables held`
#>  [1] "horTh"    "age"      "menostat" "tsize"    "tgrade"   "pnodes"  
#>  [7] "progrec"  "estrec"   "time"     "cens"    
#> 
#> 
#> $ds2
#> $ds2$class
#> [1] "data.frame"
#> 
#> $ds2$`number of rows`
#> [1] 46
#> 
#> $ds2$`number of columns`
#> [1] 10
#> 
#> $ds2$`variables held`
#>  [1] "horTh"    "age"      "menostat" "tsize"    "tgrade"   "pnodes"  
#>  [7] "progrec"  "estrec"   "time"     "cens"    
#> 
#> 
#> $ds3
#> $ds3$class
#> [1] "data.frame"
#> 
#> $ds3$`number of rows`
#> [1] 55
#> 
#> $ds3$`number of columns`
#> [1] 10
#> 
#> $ds3$`variables held`
#>  [1] "horTh"    "age"      "menostat" "tsize"    "tgrade"   "pnodes"  
#>  [7] "progrec"  "estrec"   "time"     "cens"    
#> 
#> 
#> $ds4
#> $ds4$class
#> [1] "data.frame"
#> 
#> $ds4$`number of rows`
#> [1] 59
#> 
#> $ds4$`number of columns`
#> [1] 10
#> 
#> $ds4$`variables held`
#>  [1] "horTh"    "age"      "menostat" "tsize"    "tgrade"   "pnodes"  
#>  [7] "progrec"  "estrec"   "time"     "cens"    
#> 
#> 
#> $ds5
#> $ds5$class
#> [1] "data.frame"
#> 
#> $ds5$`number of rows`
#> [1] 63
#> 
#> $ds5$`number of columns`
#> [1] 10
#> 
#> $ds5$`variables held`
#>  [1] "horTh"    "age"      "menostat" "tsize"    "tgrade"   "pnodes"  
#>  [7] "progrec"  "estrec"   "time"     "cens"
```

### Push and predict

``` r
## Load the pre-calculated logistic regression:
load(here::here("data/mod.Rda"))

## Push the model to the servers:
pushObject(conn, obj = mod)
#> [2022-02-16 08:51:59] Your object is bigger than 1 MB (7.2 MB). Uploading larger objects may take some time.
datashield.symbols(conn)
#> $ds1
#> [1] "D"   "mod"
#> 
#> $ds2
#> [1] "D"   "mod"
#> 
#> $ds3
#> [1] "D"   "mod"
#> 
#> $ds4
#> [1] "D"   "mod"
#> 
#> $ds5
#> [1] "D"   "mod"

## Predict the model on the data sets located at the servers:
predictModel(conn, mod, "probs", predict_fun = "ranger:::predict.ranger(mod, data = D)$predictions")
datashield.symbols(conn)
#> $ds1
#> [1] "D"     "mod"   "probs"
#> 
#> $ds2
#> [1] "D"     "mod"   "probs"
#> 
#> $ds3
#> [1] "D"     "mod"   "probs"
#> 
#> $ds4
#> [1] "D"     "mod"   "probs"
#> 
#> $ds5
#> [1] "D"     "mod"   "probs"
```

### Analyse calibration of the predictions

``` r
brier = dsBrierScore(conn, "D$cens", "probs")
brier
#> [1] 0.2263843

cc = dsCalibrationCurve(conn, "D$cens", "probs")
cc
#> $individuals
#> $individuals$ds1
#>          bin  n lower upper     truth      prob
#> 1    (0,0.1]  0   0.0   0.1        NA        NA
#> 2  (0.1,0.2]  5   0.1   0.2 0.6000000 0.1311465
#> 3  (0.2,0.3] 12   0.2   0.3 0.2500000 0.2428933
#> 4  (0.3,0.4] 12   0.3   0.4 0.2500000 0.3453467
#> 5  (0.4,0.5]  7   0.4   0.5 0.4285714 0.4428137
#> 6  (0.5,0.6]  5   0.5   0.6 0.6000000 0.5422724
#> 7  (0.6,0.7]  9   0.6   0.7 0.7777778 0.6504166
#> 8  (0.7,0.8]  1   0.7   0.8        NA        NA
#> 9  (0.8,0.9]  1   0.8   0.9        NA        NA
#> 10   (0.9,1]  0   0.9   1.0        NA        NA
#> 
#> $individuals$ds2
#>          bin  n lower upper     truth      prob
#> 1    (0,0.1]  0   0.0   0.1        NA        NA
#> 2  (0.1,0.2]  7   0.1   0.2 0.1428571 0.1722572
#> 3  (0.2,0.3]  7   0.2   0.3 0.2857143 0.2375414
#> 4  (0.3,0.4] 10   0.3   0.4 0.3000000 0.3517808
#> 5  (0.4,0.5] 10   0.4   0.5 0.7000000 0.4385546
#> 6  (0.5,0.6]  7   0.5   0.6 0.5714286 0.5392888
#> 7  (0.6,0.7]  2   0.6   0.7        NA        NA
#> 8  (0.7,0.8]  3   0.7   0.8        NA        NA
#> 9  (0.8,0.9]  0   0.8   0.9        NA        NA
#> 10   (0.9,1]  0   0.9   1.0        NA        NA
#> 
#> $individuals$ds3
#>          bin  n lower upper     truth      prob
#> 1    (0,0.1]  1   0.0   0.1        NA        NA
#> 2  (0.1,0.2]  4   0.1   0.2        NA        NA
#> 3  (0.2,0.3]  9   0.2   0.3 0.3333333 0.2360727
#> 4  (0.3,0.4]  7   0.3   0.4 0.2857143 0.3609350
#> 5  (0.4,0.5] 14   0.4   0.5 0.3571429 0.4513132
#> 6  (0.5,0.6] 10   0.5   0.6 0.6000000 0.5455135
#> 7  (0.6,0.7]  5   0.6   0.7 0.8000000 0.6481305
#> 8  (0.7,0.8]  4   0.7   0.8        NA        NA
#> 9  (0.8,0.9]  1   0.8   0.9        NA        NA
#> 10   (0.9,1]  0   0.9   1.0        NA        NA
#> 
#> $individuals$ds4
#>          bin  n lower upper     truth      prob
#> 1    (0,0.1]  2   0.0   0.1        NA        NA
#> 2  (0.1,0.2]  9   0.1   0.2 0.1111111 0.1508689
#> 3  (0.2,0.3]  4   0.2   0.3        NA        NA
#> 4  (0.3,0.4] 16   0.3   0.4 0.4375000 0.3469428
#> 5  (0.4,0.5] 10   0.4   0.5 0.5000000 0.4732906
#> 6  (0.5,0.6]  6   0.5   0.6 0.6666667 0.5543423
#> 7  (0.6,0.7]  7   0.6   0.7 0.7142857 0.6399625
#> 8  (0.7,0.8]  5   0.7   0.8 0.8000000 0.7561251
#> 9  (0.8,0.9]  0   0.8   0.9        NA        NA
#> 10   (0.9,1]  0   0.9   1.0        NA        NA
#> 
#> $individuals$ds5
#>          bin  n lower upper     truth      prob
#> 1    (0,0.1]  0   0.0   0.1        NA        NA
#> 2  (0.1,0.2]  4   0.1   0.2        NA        NA
#> 3  (0.2,0.3]  7   0.2   0.3 0.2857143 0.2500613
#> 4  (0.3,0.4] 15   0.3   0.4 0.3333333 0.3529974
#> 5  (0.4,0.5] 14   0.4   0.5 0.4285714 0.4463042
#> 6  (0.5,0.6]  5   0.5   0.6 0.6000000 0.5260634
#> 7  (0.6,0.7]  8   0.6   0.7 0.3750000 0.6171521
#> 8  (0.7,0.8]  7   0.7   0.8 0.4285714 0.7324551
#> 9  (0.8,0.9]  3   0.8   0.9        NA        NA
#> 10   (0.9,1]  0   0.9   1.0        NA        NA
#> 
#> 
#> $aggregated
#>          bin lower upper     truth      prob missing_ratio
#> 1    (0,0.1]   0.0   0.1 0.0000000 0.0000000    1.00000000
#> 2  (0.1,0.2]   0.1   0.2 0.1724138 0.1110122    0.27586207
#> 3  (0.2,0.3]   0.2   0.3 0.2564103 0.2167331    0.10256410
#> 4  (0.3,0.4]   0.3   0.4 0.3333333 0.3505760    0.00000000
#> 5  (0.4,0.5]   0.4   0.5 0.4727273 0.4506326    0.00000000
#> 6  (0.5,0.6]   0.5   0.6 0.6060606 0.5423603    0.00000000
#> 7  (0.6,0.7]   0.6   0.7 0.6129032 0.5971405    0.06451613
#> 8  (0.7,0.8]   0.7   0.8 0.3500000 0.4453905    0.40000000
#> 9  (0.8,0.9]   0.8   0.9 0.0000000 0.0000000    1.00000000
#> 10   (0.9,1]   0.9   1.0       NaN       NaN           NaN

ll_tab = list()
for (i in seq_along(cc$individuals)) {
  ll_tab[[i]] = c(i, cc$individuals[[i]]$n)
}
tab = do.call(rbind, ll_tab)
tab = as.data.frame(rbind(tab, colSums(tab)))
colnames(tab) = c("Server", cc$individuals[[1]]$bin)
knitr::kable(tab, format = "latex")
```

``` r

gg_cal = plotCalibrationCurve(cc, size = 1)
gg_cal
#> Warning: Removed 22 rows containing missing values (geom_point).
#> Warning: Removed 22 row(s) containing missing values (geom_path).
#> Warning: Removed 1 rows containing missing values (geom_point).
#> Warning: Removed 1 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-7-1.png)<!-- -->

### Evaluate the model using ROC analysis

``` r
# Get the l2 sensitivity
(l2s = dsL2Sens(conn, "D", "probs"))
#> [1] 0.01599175
epsilon = 0.3
delta = 0.2

# Amount of noise added:
sqrt(2 * log(1.25 / delta)) * l2s / epsilon
#> [1] 0.1020519


# Calculate ROC-GLM
roc_glm = dsROCGLM(conn, "D$cens", "probs", epsilon = epsilon,
  delta = delta, dat_name = "D", seed_object = "D$cens")
#> 
#> [2022-02-16 08:56:29] L2 sensitivity is: 0.016
#> 
#> [2022-02-16 08:56:32] Initializing ROC-GLM
#> 
#> [2022-02-16 08:56:32] Host: Received scores of negative response
#> [2022-02-16 08:56:32] Receiving negative scores
#> [2022-02-16 08:56:35] Host: Pushing pooled scores
#> [2022-02-16 08:56:39] Server: Calculating placement values and parts for ROC-GLM
#> [2022-02-16 08:56:42] Server: Calculating probit regression to obtain ROC-GLM
#> [2022-02-16 08:56:45] Deviance of iter1=52.6631
#> [2022-02-16 08:56:49] Deviance of iter2=74.2983
#> [2022-02-16 08:56:52] Deviance of iter3=88.1869
#> [2022-02-16 08:56:55] Deviance of iter4=89.6172
#> [2022-02-16 08:56:58] Deviance of iter5=89.6298
#> [2022-02-16 08:57:02] Deviance of iter6=89.6298
#> [2022-02-16 08:57:05] Deviance of iter7=89.6298
#> [2022-02-16 08:57:05] Host: Finished calculating ROC-GLM
#> [2022-02-16 08:57:05] Host: Cleaning data on server
#> [2022-02-16 08:57:08] Host: Calculating AUC and CI
#> [2022-02-16 08:57:24] Finished!
roc_glm
#> 
#> ROC-GLM after Pepe:
#> 
#>  Binormal form: pnorm(0.71 + 1.38*qnorm(t))
#> 
#>  AUC and 0.95 CI: [0.58----0.66----0.74]
roc_glm$ci
#> [1] 0.5753081 0.7367395

gg_distr_roc = plot(roc_glm)
gg_distr_roc
```

![](figures/unnamed-chunk-9-1.png)<!-- -->

## Cross check on pooled test data

``` r
#' Calculate TPR and FPRs to plot the empirical ROC curve
#'
#' @param labels (`integer()`) True labels as 0-1-coded vector.
#' @param scores (`numeric()`) Score values.
#' @return (`data.frame()`) of the TPR and FPRs.
simpleROC = function(labels, scores) {
  labels = labels[order(scores, decreasing = TRUE)]
  data.frame(
    TPR = cumsum(labels) / sum(labels),
    FPR = cumsum(! labels) / sum(! labels), labels)
}

# Load pooled test data and predict:
dat_test = read.csv(here::here("data/data-test.csv"), stringsAsFactors = TRUE)
probs = ranger:::predict.ranger(mod, data = dat_test)$predictions

# Calculate empirical AUC and compare with distributed ROC-GLM
auc = pROC::auc(dat_test$cens, probs)
#> Setting levels: control = 0, case = 1
#> Setting direction: controls < cases
c(auc_emp = auc, auc_distr_roc_glm = roc_glm$auc)
#>           auc_emp auc_distr_roc_glm 
#>         0.6724603         0.6606778

source(here::here("R/helper.R"))
logitToAUC(pepeCI(toLogit(auc), 0.05, deLongVar(probs, dat_test$cens)))
#> [1] 0.6055192 0.7330499


# Calculate TPR and FPR values and add to distributed ROC-GLM plot
plt_emp_roc_data = simpleROC(dat_test$cens, probs)

gg_roc_pooled = plot(roc_glm) +
  geom_line(data = plt_emp_roc_data, aes(x = FPR, y = TPR), color = "red")
gg_roc_pooled
```

![](figures/unnamed-chunk-11-1.png)<!-- -->

``` r

# Calculate pooled brier score and calibration curve
brier_pooled = mean((dat_test$cens - probs)^2)
c(brier_pooled = brier_pooled, brier_distr = brier)
#> brier_pooled  brier_distr 
#>    0.2263843    0.2263843

cc_pooled = calibrationCurve("dat_test$cens", "probs", nbins = 10)

# Visualize distributed calibration curve vs. pooled one:

gg_cal_pooled = plotCalibrationCurve(cc, size = 1.5, individuals = FALSE) +
    geom_line(data = cc_pooled, aes(x = prob, y = truth), color = "red")
gg_cal_pooled
#> Warning: Removed 1 rows containing missing values (geom_point).
#> Warning: Removed 1 row(s) containing missing values (geom_path).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-11-2.png)<!-- -->

## Log out from DataSHIELD servers

``` r
datashield.logout(conn)
```
