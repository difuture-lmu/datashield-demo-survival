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
remotes::install_github("difuture-lmu/dsPredictBase", upgrade = "never")
#> Skipping install of 'dsPredictBase' from a github remote, the SHA1 (ed79fd17) has not changed since last install.
#>   Use `force = TRUE` to force installation
remotes::install_github("difuture-lmu/dsCalibration", upgrade = "never")
#> Skipping install of 'dsCalibration' from a github remote, the SHA1 (1805632c) has not changed since last install.
#>   Use `force = TRUE` to force installation
remotes::install_github("difuture-lmu/dsROCGLM", upgrade = "never")
#> Skipping install of 'dsROCGLM' from a github remote, the SHA1 (be780590) has not changed since last install.
#>   Use `force = TRUE` to force installation
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
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Login ds1 [============>---------------------------------------------------------------]  17% / 0s  Login ds2 [========================>---------------------------------------------------]  33% / 0s  Login ds3 [=====================================>--------------------------------------]  50% / 1s  Login ds4 [==================================================>-------------------------]  67% / 1s  Login ds5 [==============================================================>-------------]  83% / 2s  Logged in all servers [================================================================] 100% / 2s
#> 
#>   No variables have been specified. 
#>   All the variables in the table 
#>   (the whole dataset) will be assigned to R!
#> 
#> Assigning table data...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Assigning ds1 (DIFUTURE-TEST.SRV1) [=======>-------------------------------------------]  17% / 2s  Assigning ds2 (DIFUTURE-TEST.SRV2) [================>----------------------------------]  33% / 2s  Assigning ds3 (DIFUTURE-TEST.SRV3) [=========================>-------------------------]  50% / 2s  Assigning ds4 (DIFUTURE-TEST.SRV4) [=================================>-----------------]  67% / 3s  Assigning ds5 (DIFUTURE-TEST.SRV5) [=========================================>---------]  83% / 3s  Assigned all tables [==================================================================] 100% / 3s
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
ds.dim("D")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 1s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 1s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#> $`dimensions of D in ds1`
#> [1] 51 11
#> 
#> $`dimensions of D in ds2`
#> [1] 46 11
#> 
#> $`dimensions of D in ds3`
#> [1] 55 11
#> 
#> $`dimensions of D in ds4`
#> [1] 59 11
#> 
#> $`dimensions of D in ds5`
#> [1] 63 11
#> 
#> $`dimensions of D in combined studies`
#> [1] 274  11
```

### Push and predict

``` r
## Load the pre-calculated logistic regression:
load(here::here("data/mod.Rda"))

## Push the model to the servers (upload takes ~11 Minutes):
t0 = proc.time()
pushObject(conn, obj = mod)
#> [2022-03-03 08:26:20] Your object is bigger than 1 MB (14.4 MB). Uploading larger objects may take some time.
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds1 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds2 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds2 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds3 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds3 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds4 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds4 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds5 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds5 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Assigned expr. (mod <- decodeBinary("580a000000030004010200030500000000055554462d38000003130000...
(t0 = proc.time() - t0)
#>    user  system elapsed 
#>  33.354   0.597 673.110
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

## Time point:
which(ranger::timepoints(mod) >= 730)[1]
#> [1] 127

## Predict the model on the data sets located at the servers:
pfun = "ranger:::predict.ranger(mod, data = D)$survival[, 127]"
predictModel(conn, mod, "probs", predict_fun = pfun, package = "ranger")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds2 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds3 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds4 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds5 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Waiting...  (probs <- assignPredictModel("580a000000030004010200030500000000055554462d380000001...  Checking ds1 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds2 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds3 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds4 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Checking ds5 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Waiting...  (probs <- assignPredictModel("580a000000030004010200030500000000055554462d380000001...  Checking ds1 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Finalizing assignment ds1 (probs <- assignPredictModel("580a00000003000401020003050000000005555...  Checking ds2 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Finalizing assignment ds2 (probs <- assignPredictModel("580a00000003000401020003050000000005555...  Checking ds3 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Finalizing assignment ds3 (probs <- assignPredictModel("580a00000003000401020003050000000005555...  Checking ds4 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Finalizing assignment ds4 (probs <- assignPredictModel("580a00000003000401020003050000000005555...  Checking ds5 (probs <- assignPredictModel("580a000000030004010200030500000000055554462d38000000...  Finalizing assignment ds5 (probs <- assignPredictModel("580a00000003000401020003050000000005555...  Assigned expr. (probs <- assignPredictModel("580a000000030004010200030500000000055554462d380000...
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

# Because labels are flipped for the 0-1-setting we also calculate
# 1 - probs:
datashield.assign(conn, "pinv", quote(1 - probs))
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (pinv <- 1 - probs) [-----------------------------------------------------]   0% / 0s  Finalizing assignment ds1 (pinv <- 1 - probs) [======>---------------------------------]  17% / 0s  Checking ds2 (pinv <- 1 - probs) [========>--------------------------------------------]  17% / 0s  Finalizing assignment ds2 (pinv <- 1 - probs) [============>---------------------------]  33% / 0s  Checking ds3 (pinv <- 1 - probs) [=================>-----------------------------------]  33% / 0s  Finalizing assignment ds3 (pinv <- 1 - probs) [===================>--------------------]  50% / 1s  Checking ds4 (pinv <- 1 - probs) [=========================>---------------------------]  50% / 1s  Finalizing assignment ds4 (pinv <- 1 - probs) [==========================>-------------]  67% / 1s  Checking ds5 (pinv <- 1 - probs) [==================================>------------------]  67% / 1s  Finalizing assignment ds5 (pinv <- 1 - probs) [================================>-------]  83% / 1s  Assigned expr. (pinv <- 1 - probs) [===================================================] 100% / 1s
```

### Analyse calibration of the predictions

``` r
brier = dsBrierScore(conn, "D$valid", "pinv")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (brierScore("D$valid", "pinv")) [-----------------------------------------]   0% / 0s  Getting aggregate ds1 (brierScore("D$valid", "pinv")) [====>---------------------------]  17% / 0s  Checking ds2 (brierScore("D$valid", "pinv")) [======>----------------------------------]  17% / 0s  Getting aggregate ds2 (brierScore("D$valid", "pinv")) [==========>---------------------]  33% / 0s  Checking ds3 (brierScore("D$valid", "pinv")) [=============>---------------------------]  33% / 0s  Getting aggregate ds3 (brierScore("D$valid", "pinv")) [===============>----------------]  50% / 1s  Checking ds4 (brierScore("D$valid", "pinv")) [===================>---------------------]  50% / 1s  Getting aggregate ds4 (brierScore("D$valid", "pinv")) [====================>-----------]  67% / 1s  Checking ds5 (brierScore("D$valid", "pinv")) [==========================>--------------]  67% / 1s  Getting aggregate ds5 (brierScore("D$valid", "pinv")) [==========================>-----]  83% / 1s  Aggregated (brierScore("D$valid", "pinv")) [===========================================] 100% / 1s
brier
#> [1] 0.1631

cc = dsCalibrationCurve(conn, "D$valid", "pinv")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [=======>-----------------]  33% / 0s  Getting aggregate ds3 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [=======>--------]  50% / 1s  Checking ds4 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [============>---]  83% / 1s  Aggregated (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===========================] 100% / 1s
cc
#> $individuals
#> $individuals$ds1
#>          bin  n lower upper  truth    prob
#> 1    (0,0.1]  9   0.0   0.1 0.0000 0.06813
#> 2  (0.1,0.2] 14   0.1   0.2 0.4286 0.14990
#> 3  (0.2,0.3]  7   0.2   0.3 0.1429 0.24517
#> 4  (0.3,0.4]  4   0.3   0.4     NA      NA
#> 5  (0.4,0.5]  4   0.4   0.5     NA      NA
#> 6  (0.5,0.6]  4   0.5   0.6     NA      NA
#> 7  (0.6,0.7]  7   0.6   0.7 0.8571 0.63102
#> 8  (0.7,0.8]  0   0.7   0.8     NA      NA
#> 9  (0.8,0.9]  0   0.8   0.9     NA      NA
#> 10   (0.9,1]  0   0.9   1.0     NA      NA
#> 
#> $individuals$ds2
#>          bin  n lower upper  truth   prob
#> 1    (0,0.1]  5   0.0   0.1 0.0000 0.0381
#> 2  (0.1,0.2]  9   0.1   0.2 0.1111 0.1681
#> 3  (0.2,0.3]  3   0.2   0.3     NA     NA
#> 4  (0.3,0.4]  6   0.3   0.4 0.1667 0.3556
#> 5  (0.4,0.5] 10   0.4   0.5 0.3000 0.4434
#> 6  (0.5,0.6]  6   0.5   0.6 0.6667 0.5455
#> 7  (0.6,0.7]  5   0.6   0.7 0.4000 0.6208
#> 8  (0.7,0.8]  1   0.7   0.8     NA     NA
#> 9  (0.8,0.9]  0   0.8   0.9     NA     NA
#> 10   (0.9,1]  0   0.9   1.0     NA     NA
#> 
#> $individuals$ds3
#>          bin  n lower upper   truth    prob
#> 1    (0,0.1]  7   0.0   0.1 0.00000 0.06026
#> 2  (0.1,0.2] 14   0.1   0.2 0.00000 0.13163
#> 3  (0.2,0.3] 12   0.2   0.3 0.08333 0.25095
#> 4  (0.3,0.4]  9   0.3   0.4 0.33333 0.33507
#> 5  (0.4,0.5]  6   0.4   0.5 0.16667 0.44588
#> 6  (0.5,0.6]  4   0.5   0.6      NA      NA
#> 7  (0.6,0.7]  2   0.6   0.7      NA      NA
#> 8  (0.7,0.8]  0   0.7   0.8      NA      NA
#> 9  (0.8,0.9]  0   0.8   0.9      NA      NA
#> 10   (0.9,1]  0   0.9   1.0      NA      NA
#> 
#> $individuals$ds4
#>          bin  n lower upper  truth    prob
#> 1    (0,0.1]  9   0.0   0.1 0.1111 0.04154
#> 2  (0.1,0.2] 14   0.1   0.2 0.3571 0.15712
#> 3  (0.2,0.3] 11   0.2   0.3 0.0000 0.23769
#> 4  (0.3,0.4]  8   0.3   0.4 0.0000 0.35362
#> 5  (0.4,0.5]  9   0.4   0.5 0.2222 0.43458
#> 6  (0.5,0.6]  3   0.5   0.6     NA      NA
#> 7  (0.6,0.7]  4   0.6   0.7     NA      NA
#> 8  (0.7,0.8]  0   0.7   0.8     NA      NA
#> 9  (0.8,0.9]  0   0.8   0.9     NA      NA
#> 10   (0.9,1]  0   0.9   1.0     NA      NA
#> 
#> $individuals$ds5
#>          bin  n lower upper   truth    prob
#> 1    (0,0.1] 14   0.0   0.1 0.07143 0.05121
#> 2  (0.1,0.2] 12   0.1   0.2 0.08333 0.14103
#> 3  (0.2,0.3]  6   0.2   0.3 0.16667 0.24425
#> 4  (0.3,0.4]  9   0.3   0.4 0.33333 0.36701
#> 5  (0.4,0.5]  9   0.4   0.5 0.22222 0.44725
#> 6  (0.5,0.6]  6   0.5   0.6 0.16667 0.55144
#> 7  (0.6,0.7]  5   0.6   0.7 0.60000 0.63888
#> 8  (0.7,0.8]  0   0.7   0.8      NA      NA
#> 9  (0.8,0.9]  0   0.8   0.9      NA      NA
#> 10   (0.9,1]  0   0.9   1.0      NA      NA
#> 
#> 
#> $aggregated
#>          bin lower upper   truth    prob missing_ratio
#> 1    (0,0.1]   0.0   0.1 0.04545 0.05264       0.00000
#> 2  (0.1,0.2]   0.1   0.2 0.20635 0.14836       0.00000
#> 3  (0.2,0.3]   0.2   0.3 0.07692 0.22584       0.07692
#> 4  (0.3,0.4]   0.3   0.4 0.19444 0.31337       0.11111
#> 5  (0.4,0.5]   0.4   0.5 0.21053 0.39595       0.10526
#> 6  (0.5,0.6]   0.5   0.6 0.21739 0.28616       0.47826
#> 7  (0.6,0.7]   0.6   0.7 0.47826 0.46589       0.26087
#> 8  (0.7,0.8]   0.7   0.8 0.00000 0.00000       1.00000
#> 9  (0.8,0.9]   0.8   0.9     NaN     NaN           NaN
#> 10   (0.9,1]   0.9   1.0     NaN     NaN           NaN

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
#> Warning: Removed 23 rows containing missing values (geom_point).
#> Warning: Removed 23 row(s) containing missing values (geom_path).
#> Warning: Removed 2 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-7-1.png)<!-- -->

### Evaluate the model using ROC analysis

``` r
# Get the l2 sensitivity
(l2s = dsL2Sens(conn, "D", "pinv"))
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 0s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 0s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Assigned expr. (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe"...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>-----------------]  33% / 0s  Getting aggregate ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>--------]  50% / 1s  Checking ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [============>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (rmDS("xXcols")) [--------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (rmDS("xXcols")) [=======>---------------------------------------]  17% / 0s  Checking ds2 (rmDS("xXcols")) [========>-----------------------------------------------]  17% / 0s  Getting aggregate ds2 (rmDS("xXcols")) [===============>-------------------------------]  33% / 0s  Checking ds3 (rmDS("xXcols")) [==================>-------------------------------------]  33% / 0s  Getting aggregate ds3 (rmDS("xXcols")) [=======================>-----------------------]  50% / 1s  Checking ds4 (rmDS("xXcols")) [===========================>----------------------------]  50% / 1s  Getting aggregate ds4 (rmDS("xXcols")) [==============================>----------------]  67% / 1s  Checking ds5 (rmDS("xXcols")) [====================================>-------------------]  67% / 1s  Getting aggregate ds5 (rmDS("xXcols")) [======================================>--------]  83% / 1s  Aggregated (rmDS("xXcols")) [==========================================================] 100% / 1s
#> [1] 0.03717
epsilon = 0.4
delta = 0.2

# Amount of noise added:
sqrt(2 * log(1.25 / delta)) * l2s / epsilon
#> [1] 0.1779

# Calculate ROC-GLM
roc_glm = dsROCGLM(conn, "D$valid", "pinv", epsilon = epsilon,
  delta = delta, dat_name = "D", seed_object = "D$valid")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 0s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 0s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Assigned expr. (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe"...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>-----------------]  33% / 0s  Getting aggregate ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>--------]  50% / 1s  Checking ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [============>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (rmDS("xXcols")) [--------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (rmDS("xXcols")) [=======>---------------------------------------]  17% / 0s  Checking ds2 (rmDS("xXcols")) [========>-----------------------------------------------]  17% / 0s  Getting aggregate ds2 (rmDS("xXcols")) [===============>-------------------------------]  33% / 0s  Checking ds3 (rmDS("xXcols")) [==================>-------------------------------------]  33% / 0s  Getting aggregate ds3 (rmDS("xXcols")) [=======================>-----------------------]  50% / 1s  Checking ds4 (rmDS("xXcols")) [===========================>----------------------------]  50% / 1s  Getting aggregate ds4 (rmDS("xXcols")) [==============================>----------------]  67% / 1s  Checking ds5 (rmDS("xXcols")) [====================================>-------------------]  67% / 1s  Getting aggregate ds5 (rmDS("xXcols")) [======================================>--------]  83% / 1s  Aggregated (rmDS("xXcols")) [==========================================================] 100% / 1s
#> 
#> [2022-03-03 08:37:43] L2 sensitivity is: 0.0372
#> 
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380000000e000000...  Finalizing assignment ds1 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds2 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380000000e000000...  Finalizing assignment ds2 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds3 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380000000e000000...  Finalizing assignment ds3 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds4 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380000000e000000...  Finalizing assignment ds4 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds5 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380000000e000000...  Finalizing assignment ds5 (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380...  Assigned expr. (l2s <- decodeBinary("580a000000030004010200030500000000055554462d380000000e0000...
#> 
#> [2022-03-03 08:37:44] Initializing ROC-GLM
#> 
#> [2022-03-03 08:37:44] Host: Received scores of negative response
#> 
#> [2022-03-03 08:37:44] Receiving negative scores
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [-------------]   0% / 0s  Getting aggregate ds1 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [>---]  17% / 0s  Checking ds2 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=>-----------]  17% / 0s  Getting aggregate ds2 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [>---]  33% / 0s  Checking ds3 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [===>---------]  33% / 0s  Getting aggregate ds3 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=>--]  50% / 1s  Checking ds4 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=====>-------]  50% / 1s  Getting aggregate ds4 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [==>-]  67% / 1s  Checking ds5 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [========>----]  67% / 1s  Getting aggregate ds5 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [==>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#> [2022-03-03 08:37:45] Host: Pushing pooled scores
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds1 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds2 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds2 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds3 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds3 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds4 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds4 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds5 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds5 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Assigned expr. (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d3800...
#> [2022-03-03 08:37:46] Server: Calculating placement values and parts for ROC-GLM
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [-----------]   0% / 0s  Finalizing assignment ds1 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  17%...  Checking ds2 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=>---------]  17% / 0s  Finalizing assignment ds2 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  33%...  Checking ds3 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [===>-------]  33% / 0s  Finalizing assignment ds3 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  50%...  Checking ds4 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=====>-----]  50% / 1s  Finalizing assignment ds4 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  67%...  Checking ds5 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [======>----]  67% / 1s  Finalizing assignment ds5 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  83%...  Assigned expr. (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=========] 100% / 1s
#> [2022-03-03 08:37:47] Server: Calculating probit regression to obtain ROC-GLM
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 08:37:48] Deviance of iter1=19.3983
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 08:37:48] Deviance of iter2=17.3077
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 08:37:49] Deviance of iter3=17.3665
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 1s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 08:37:50] Deviance of iter4=17.3672
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 08:37:51] Deviance of iter5=17.3672
#> [2022-03-03 08:37:51] Host: Finished calculating ROC-GLM
#> [2022-03-03 08:37:51] Host: Cleaning data on server
#> [2022-03-03 08:37:53] Host: Calculating AUC and CI
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (meanDS(D$valid)) [-------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (meanDS(D$valid)) [=======>--------------------------------------]  17% / 0s  Checking ds2 (meanDS(D$valid)) [========>----------------------------------------------]  17% / 0s  Getting aggregate ds2 (meanDS(D$valid)) [==============>-------------------------------]  33% / 0s  Checking ds3 (meanDS(D$valid)) [=================>-------------------------------------]  33% / 0s  Getting aggregate ds3 (meanDS(D$valid)) [======================>-----------------------]  50% / 1s  Checking ds4 (meanDS(D$valid)) [===========================>---------------------------]  50% / 1s  Getting aggregate ds4 (meanDS(D$valid)) [==============================>---------------]  67% / 1s  Checking ds5 (meanDS(D$valid)) [====================================>------------------]  67% / 1s  Getting aggregate ds5 (meanDS(D$valid)) [=====================================>--------]  83% / 1s  Aggregated (meanDS(D$valid)) [=========================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScoresVar("D$valid", "pinv")) [-------------------------------]   0% / 0s  Getting aggregate ds1 (getNegativeScoresVar("D$valid", "pinv")) [===>------------------]  17% / 0s  Checking ds2 (getNegativeScoresVar("D$valid", "pinv")) [====>--------------------------]  17% / 0s  Getting aggregate ds2 (getNegativeScoresVar("D$valid", "pinv")) [======>---------------]  33% / 0s  Checking ds3 (getNegativeScoresVar("D$valid", "pinv")) [=========>---------------------]  33% / 0s  Getting aggregate ds3 (getNegativeScoresVar("D$valid", "pinv")) [==========>-----------]  50% / 0s  Checking ds4 (getNegativeScoresVar("D$valid", "pinv")) [===============>---------------]  50% / 1s  Getting aggregate ds4 (getNegativeScoresVar("D$valid", "pinv")) [==============>-------]  67% / 1s  Checking ds5 (getNegativeScoresVar("D$valid", "pinv")) [====================>----------]  67% / 1s  Getting aggregate ds5 (getNegativeScoresVar("D$valid", "pinv")) [=================>----]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getPositiveScoresVar("D$valid", "pinv")) [-------------------------------]   0% / 0s  Getting aggregate ds1 (getPositiveScoresVar("D$valid", "pinv")) [===>------------------]  17% / 0s  Checking ds2 (getPositiveScoresVar("D$valid", "pinv")) [====>--------------------------]  17% / 0s  Getting aggregate ds2 (getPositiveScoresVar("D$valid", "pinv")) [======>---------------]  33% / 0s  Checking ds3 (getPositiveScoresVar("D$valid", "pinv")) [=========>---------------------]  33% / 0s  Getting aggregate ds3 (getPositiveScoresVar("D$valid", "pinv")) [==========>-----------]  50% / 1s  Checking ds4 (getPositiveScoresVar("D$valid", "pinv")) [===============>---------------]  50% / 1s  Getting aggregate ds4 (getPositiveScoresVar("D$valid", "pinv")) [==============>-------]  67% / 1s  Checking ds5 (getPositiveScoresVar("D$valid", "pinv")) [====================>----------]  67% / 1s  Getting aggregate ds5 (getPositiveScoresVar("D$valid", "pinv")) [=================>----]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [-------------]   0% / 0s  Getting aggregate ds1 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [>---]  17% / 0s  Checking ds2 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=>-----------]  17% / 0s  Getting aggregate ds2 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [>---]  33% / 0s  Checking ds3 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [===>---------]  33% / 0s  Getting aggregate ds3 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=>--]  50% / 0s  Checking ds4 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=====>-------]  50% / 1s  Getting aggregate ds4 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [==>-]  67% / 1s  Checking ds5 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [========>----]  67% / 1s  Getting aggregate ds5 (getNegativeScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [==>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [-------------]   0% / 0s  Getting aggregate ds1 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [>---]  17% / 0s  Checking ds2 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=>-----------]  17% / 0s  Getting aggregate ds2 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [>---]  33% / 0s  Checking ds3 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [===>---------]  33% / 0s  Getting aggregate ds3 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=>--]  50% / 1s  Checking ds4 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [=====>-------]  50% / 1s  Getting aggregate ds4 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [==>-]  67% / 1s  Checking ds5 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [========>----]  67% / 1s  Getting aggregate ds5 (getPositiveScores("D$valid", "pinv", 0.4, 0.2, "D$valid")) [==>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#> [2022-03-03 08:37:57] Finished!
roc_glm
#> 
#> ROC-GLM after Pepe:
#> 
#>  Binormal form: pnorm(0.49 + 0.76*qnorm(t))
#> 
#>  AUC and 0.95 CI: [0.51----0.65----0.77]
roc_glm$ci
#> [1] 0.5150 0.7662

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
probs = ranger:::predict.ranger(mod, data = dat_test)$survival[, 127]

# Calculate empirical AUC and compare with distributed ROC-GLM
auc = pROC::auc(dat_test$valid, 1 - probs)
#> Setting levels: control = 0, case = 1
#> Setting direction: controls < cases
c(auc_emp = auc, auc_distr_roc_glm = roc_glm$auc)
#>           auc_emp auc_distr_roc_glm 
#>            0.6884            0.6510

source(here::here("R/helper.R"))
logitToAUC(pepeCI(toLogit(auc), 0.05, deLongVar(1 - probs, dat_test$valid)))
#> [1] 0.6012 0.7640


# Calculate TPR and FPR values and add to distributed ROC-GLM plot
plt_emp_roc_data = simpleROC(dat_test$valid, 1 - probs)

gg_roc_pooled = plot(roc_glm) +
  geom_line(data = plt_emp_roc_data, aes(x = FPR, y = TPR), color = "red")
gg_roc_pooled
```

![](figures/unnamed-chunk-11-1.png)<!-- -->

``` r

# Calculate pooled brier score and calibration curve
brier_pooled = mean((dat_test$valid - (1 - probs))^2)
c(brier_pooled = brier_pooled, brier_distr = brier)
#> brier_pooled  brier_distr 
#>       0.1631       0.1631

cc_pooled = calibrationCurve("dat_test$valid", "1 - probs", nbins = 10)

# Visualize distributed calibration curve vs. pooled one:

gg_cal_pooled = plotCalibrationCurve(cc, size = 1.5, individuals = FALSE) +
    geom_line(data = cc_pooled, aes(x = prob, y = truth), color = "red")
gg_cal_pooled
#> Warning: Removed 2 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
#> Warning: Removed 3 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-11-2.png)<!-- -->

## Log out from DataSHIELD servers

``` r
datashield.logout(conn)
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Logout ds1 [===========>---------------------------------------------------------------]  17% / 0s  Logout ds2 [========================>--------------------------------------------------]  33% / 0s  Logout ds3 [=====================================>-------------------------------------]  50% / 0s  Logout ds4 [=================================================>-------------------------]  67% / 0s  Logout ds5 [=============================================================>-------------]  83% / 1s  Logged out from all servers [==========================================================] 100% / 1s
```
