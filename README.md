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

Last time rendered: 19:08 - 03. Mar 2022

### Structure of the repository

TODO

## Setup

### Install packages

Install all packages locally and also on the DataSHIELD test machine:

``` r
remotes::install_github("difuture-lmu/dsPredictBase", upgrade = "never")
#> Using github PAT from envvar GITHUB_PAT
#> Downloading GitHub repo difuture-lmu/dsPredictBase@HEAD
#> Downloading GitHub repo datashield/dsBaseClient@HEAD
#> Installing 12 packages: gridExtra, dotCall64, data.table, pbapply, mathjaxr, maps, viridis, spam, panelaggregation, metafor, fields, DSI
#> Installing packages into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
#> * checking for file ‘/tmp/Rtmpo84ccU/remotes90bcf43a780/datashield-dsBaseClient-d22ba51/DESCRIPTION’ ... OK
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
#> * checking for file ‘/tmp/Rtmpo84ccU/remotes90bc239d7f13/difuture-lmu-dsPredictBase-ed79fd1/DESCRIPTION’ ... OK
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
remotes::install_github("difuture-lmu/dsCalibration", upgrade = "never")
#> Using github PAT from envvar GITHUB_PAT
#> Downloading GitHub repo difuture-lmu/dsCalibration@HEAD
#> * checking for file ‘/tmp/Rtmpo84ccU/remotes90bc79b85b9f/difuture-lmu-dsCalibration-1805632/DESCRIPTION’ ... OK
#> * preparing ‘dsCalibration’:
#> * checking DESCRIPTION meta-information ... OK
#> * checking for LF line-endings in source and make files and shell scripts
#> * checking for empty or unneeded directories
#> * building ‘dsCalibration_0.0.1.tar.gz’
#> Installing package into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
remotes::install_github("difuture-lmu/dsROCGLM", upgrade = "never")
<<<<<<< HEAD
#> Skipping install of 'dsROCGLM' from a github remote, the SHA1 (0c7475ce) has not changed since last install.
#>   Use `force = TRUE` to force installation
=======
#> Using github PAT from envvar GITHUB_PAT
#> Downloading GitHub repo difuture-lmu/dsROCGLM@HEAD
#> * checking for file ‘/tmp/Rtmpo84ccU/remotes90bc7eea1861/difuture-lmu-dsROCGLM-be78059/DESCRIPTION’ ... OK
#> * preparing ‘dsROCGLM’:
#> * checking DESCRIPTION meta-information ... OK
#> * checking for LF line-endings in source and make files and shell scripts
#> * checking for empty or unneeded directories
#> * building ‘dsROCGLM_0.0.1.tar.gz’
#> Installing package into '/home/runner/work/_temp/Library'
#> (as 'lib' is unspecified)
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
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
<<<<<<< HEAD
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Login ds1 [============>---------------------------------------------------------------]  17% / 0s  Login ds2 [========================>---------------------------------------------------]  33% / 0s  Login ds3 [=====================================>--------------------------------------]  50% / 1s  Login ds4 [==================================================>-------------------------]  67% / 1s  Login ds5 [==============================================================>-------------]  83% / 1s  Logged in all servers [================================================================] 100% / 2s
=======
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
#> 
#>   No variables have been specified. 
#>   All the variables in the table 
#>   (the whole dataset) will be assigned to R!
#> 
#> Assigning table data...
<<<<<<< HEAD
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Assigning ds1 (DIFUTURE-TEST.SRV1) [=======>-------------------------------------------]  17% / 2s  Assigning ds2 (DIFUTURE-TEST.SRV2) [================>----------------------------------]  33% / 2s  Assigning ds3 (DIFUTURE-TEST.SRV3) [=========================>-------------------------]  50% / 3s  Assigning ds4 (DIFUTURE-TEST.SRV4) [=================================>-----------------]  67% / 3s  Assigning ds5 (DIFUTURE-TEST.SRV5) [=========================================>---------]  83% / 3s  Assigned all tables [==================================================================] 100% / 4s
=======
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
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
<<<<<<< HEAD
(ddim = ds.dim("D"))
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 1s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 1s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
=======
ds.dim("D")
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
#> $`dimensions of D in ds1`
#> [1] 56 11
#> 
#> $`dimensions of D in ds2`
#> [1] 49 11
#> 
#> $`dimensions of D in ds3`
#> [1] 60 11
#> 
#> $`dimensions of D in ds4`
#> [1] 49 11
#> 
#> $`dimensions of D in ds5`
#> [1] 60 11
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
<<<<<<< HEAD
#> [2022-03-03 19:08:12] Your object is bigger than 1 MB (14.4 MB). Uploading larger objects may take some time.
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds1 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds2 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds2 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds3 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds3 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds4 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds4 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Checking ds5 (mod <- decodeBinary("580a000000030004010200030500000000055554462d3800000313000000...  Finalizing assignment ds5 (mod <- decodeBinary("580a000000030004010200030500000000055554462d380...  Assigned expr. (mod <- decodeBinary("580a000000030004010200030500000000055554462d38000003130000...
(t0 = proc.time() - t0)
#>    user  system elapsed 
#>  33.317   0.603 685.013
=======
#> [2022-03-03 08:05:01] Your object is bigger than 1 MB (14.3 MB). Uploading larger objects may take some time.
(t0 = proc.time() - t0)
#>    user  system elapsed 
#> 107.294  53.673 988.597
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
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
#> [1] 134

## Predict the model on the data sets located at the servers:
pfun = "ranger:::predict.ranger(mod, data = D)$survival[, 127]"
predictModel(conn, mod, "probs", predict_fun = pfun, package = "ranger")
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
<<<<<<< HEAD
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (pinv <- 1 - probs) [-----------------------------------------------------]   0% / 0s  Finalizing assignment ds1 (pinv <- 1 - probs) [======>---------------------------------]  17% / 0s  Checking ds2 (pinv <- 1 - probs) [========>--------------------------------------------]  17% / 0s  Finalizing assignment ds2 (pinv <- 1 - probs) [============>---------------------------]  33% / 0s  Checking ds3 (pinv <- 1 - probs) [=================>-----------------------------------]  33% / 1s  Finalizing assignment ds3 (pinv <- 1 - probs) [===================>--------------------]  50% / 1s  Checking ds4 (pinv <- 1 - probs) [=========================>---------------------------]  50% / 1s  Finalizing assignment ds4 (pinv <- 1 - probs) [==========================>-------------]  67% / 1s  Checking ds5 (pinv <- 1 - probs) [==================================>------------------]  67% / 1s  Finalizing assignment ds5 (pinv <- 1 - probs) [================================>-------]  83% / 1s  Assigned expr. (pinv <- 1 - probs) [===================================================] 100% / 1s
=======
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
```

### Analyse calibration of the predictions

``` r
brier = dsBrierScore(conn, "D$valid", "pinv")
<<<<<<< HEAD
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (brierScore("D$valid", "pinv")) [-----------------------------------------]   0% / 0s  Getting aggregate ds1 (brierScore("D$valid", "pinv")) [====>---------------------------]  17% / 0s  Checking ds2 (brierScore("D$valid", "pinv")) [======>----------------------------------]  17% / 0s  Getting aggregate ds2 (brierScore("D$valid", "pinv")) [==========>---------------------]  33% / 0s  Checking ds3 (brierScore("D$valid", "pinv")) [=============>---------------------------]  33% / 1s  Getting aggregate ds3 (brierScore("D$valid", "pinv")) [===============>----------------]  50% / 1s  Checking ds4 (brierScore("D$valid", "pinv")) [===================>---------------------]  50% / 1s  Getting aggregate ds4 (brierScore("D$valid", "pinv")) [====================>-----------]  67% / 1s  Checking ds5 (brierScore("D$valid", "pinv")) [==========================>--------------]  67% / 1s  Getting aggregate ds5 (brierScore("D$valid", "pinv")) [==========================>-----]  83% / 1s  Aggregated (brierScore("D$valid", "pinv")) [===========================================] 100% / 1s
brier
#> [1] 0.1721

cc = dsCalibrationCurve(conn, "D$valid", "pinv")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [=======>-----------------]  33% / 1s  Getting aggregate ds3 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [=======>--------]  50% / 1s  Checking ds4 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [============>---]  83% / 1s  Aggregated (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===========================] 100% / 1s
cc
#> $individuals
#> $individuals$ds1
#>          bin  n lower upper   truth    prob
#> 1    (0,0.1] 12   0.0   0.1 0.08333 0.05574
#> 2  (0.1,0.2] 12   0.1   0.2 0.16667 0.15282
#> 3  (0.2,0.3] 14   0.2   0.3 0.14286 0.23769
#> 4  (0.3,0.4]  1   0.3   0.4      NA      NA
#> 5  (0.4,0.5]  4   0.4   0.5      NA      NA
#> 6  (0.5,0.6]  6   0.5   0.6 0.50000 0.56611
#> 7  (0.6,0.7]  4   0.6   0.7      NA      NA
#> 8  (0.7,0.8]  0   0.7   0.8      NA      NA
#> 9  (0.8,0.9]  0   0.8   0.9      NA      NA
#> 10   (0.9,1]  0   0.9   1.0      NA      NA
=======
brier
#> [1] 0.1630864

cc = dsCalibrationCurve(conn, "D$valid", "pinv")
cc
#> $individuals
#> $individuals$ds1
#>          bin  n lower upper     truth       prob
#> 1    (0,0.1]  9   0.0   0.1 0.0000000 0.06812542
#> 2  (0.1,0.2] 14   0.1   0.2 0.4285714 0.14989502
#> 3  (0.2,0.3]  7   0.2   0.3 0.1428571 0.24517335
#> 4  (0.3,0.4]  4   0.3   0.4        NA         NA
#> 5  (0.4,0.5]  4   0.4   0.5        NA         NA
#> 6  (0.5,0.6]  4   0.5   0.6        NA         NA
#> 7  (0.6,0.7]  7   0.6   0.7 0.8571429 0.63102002
#> 8  (0.7,0.8]  0   0.7   0.8        NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9        NA         NA
#> 10   (0.9,1]  0   0.9   1.0        NA         NA
#> 
#> $individuals$ds2
#>          bin  n lower upper     truth       prob
#> 1    (0,0.1]  5   0.0   0.1 0.0000000 0.03810452
#> 2  (0.1,0.2]  9   0.1   0.2 0.1111111 0.16811389
#> 3  (0.2,0.3]  3   0.2   0.3        NA         NA
#> 4  (0.3,0.4]  6   0.3   0.4 0.1666667 0.35562250
#> 5  (0.4,0.5] 10   0.4   0.5 0.3000000 0.44344677
#> 6  (0.5,0.6]  6   0.5   0.6 0.6666667 0.54551648
#> 7  (0.6,0.7]  5   0.6   0.7 0.4000000 0.62079850
#> 8  (0.7,0.8]  1   0.7   0.8        NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9        NA         NA
#> 10   (0.9,1]  0   0.9   1.0        NA         NA
#> 
#> $individuals$ds3
#>          bin  n lower upper      truth       prob
#> 1    (0,0.1]  7   0.0   0.1 0.00000000 0.06026412
#> 2  (0.1,0.2] 14   0.1   0.2 0.00000000 0.13163342
#> 3  (0.2,0.3] 12   0.2   0.3 0.08333333 0.25095399
#> 4  (0.3,0.4]  9   0.3   0.4 0.33333333 0.33507366
#> 5  (0.4,0.5]  6   0.4   0.5 0.16666667 0.44588458
#> 6  (0.5,0.6]  4   0.5   0.6         NA         NA
#> 7  (0.6,0.7]  2   0.6   0.7         NA         NA
#> 8  (0.7,0.8]  0   0.7   0.8         NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9         NA         NA
#> 10   (0.9,1]  0   0.9   1.0         NA         NA
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
#> 
#> $individuals$ds2
#>          bin  n lower upper   truth   prob
#> 1    (0,0.1] 12   0.0   0.1 0.08333 0.0616
#> 2  (0.1,0.2] 16   0.1   0.2 0.18750 0.1432
#> 3  (0.2,0.3]  6   0.2   0.3 0.16667 0.2350
#> 4  (0.3,0.4]  1   0.3   0.4      NA     NA
#> 5  (0.4,0.5]  6   0.4   0.5 0.33333 0.4663
#> 6  (0.5,0.6]  3   0.5   0.6      NA     NA
#> 7  (0.6,0.7]  2   0.6   0.7      NA     NA
#> 8  (0.7,0.8]  0   0.7   0.8      NA     NA
#> 9  (0.8,0.9]  0   0.8   0.9      NA     NA
#> 10   (0.9,1]  0   0.9   1.0      NA     NA
#> 
#> $individuals$ds3
#>          bin  n lower upper  truth   prob
#> 1    (0,0.1] 14   0.0   0.1 0.0000 0.0677
#> 2  (0.1,0.2] 13   0.1   0.2 0.3077 0.1390
#> 3  (0.2,0.3] 12   0.2   0.3 0.4167 0.2335
#> 4  (0.3,0.4]  4   0.3   0.4     NA     NA
#> 5  (0.4,0.5]  4   0.4   0.5     NA     NA
#> 6  (0.5,0.6]  3   0.5   0.6     NA     NA
#> 7  (0.6,0.7]  6   0.6   0.7 0.3333 0.6267
#> 8  (0.7,0.8]  1   0.7   0.8     NA     NA
#> 9  (0.8,0.9]  0   0.8   0.9     NA     NA
#> 10   (0.9,1]  0   0.9   1.0     NA     NA
#> 
#> $individuals$ds4
<<<<<<< HEAD
#>          bin n lower upper  truth    prob
#> 1    (0,0.1] 9   0.0   0.1 0.1111 0.03511
#> 2  (0.1,0.2] 7   0.1   0.2 0.2857 0.15901
#> 3  (0.2,0.3] 7   0.2   0.3 0.4286 0.25237
#> 4  (0.3,0.4] 7   0.3   0.4 0.2857 0.34306
#> 5  (0.4,0.5] 8   0.4   0.5 0.2500 0.44863
#> 6  (0.5,0.6] 6   0.5   0.6 0.1667 0.55148
#> 7  (0.6,0.7] 4   0.6   0.7     NA      NA
#> 8  (0.7,0.8] 0   0.7   0.8     NA      NA
#> 9  (0.8,0.9] 0   0.8   0.9     NA      NA
#> 10   (0.9,1] 0   0.9   1.0     NA      NA
#> 
#> $individuals$ds5
#>          bin  n lower upper   truth    prob
#> 1    (0,0.1] 13   0.0   0.1 0.07692 0.05047
#> 2  (0.1,0.2] 14   0.1   0.2 0.14286 0.14687
#> 3  (0.2,0.3] 10   0.2   0.3 0.00000 0.23573
#> 4  (0.3,0.4]  0   0.3   0.4      NA      NA
#> 5  (0.4,0.5]  6   0.4   0.5 0.16667 0.44664
#> 6  (0.5,0.6]  6   0.5   0.6 0.33333 0.52449
#> 7  (0.6,0.7]  8   0.6   0.7 0.75000 0.63736
#> 8  (0.7,0.8]  1   0.7   0.8      NA      NA
#> 9  (0.8,0.9]  0   0.8   0.9      NA      NA
#> 10   (0.9,1]  0   0.9   1.0      NA      NA
#> 
#> 
#> $aggregated
#>          bin lower upper   truth    prob missing_ratio
#> 1    (0,0.1]   0.0   0.1 0.06667 0.05547        0.0000
#> 2  (0.1,0.2]   0.1   0.2 0.20968 0.14679        0.0000
#> 3  (0.2,0.3]   0.2   0.3 0.22449 0.23802        0.0000
#> 4  (0.3,0.4]   0.3   0.4 0.15385 0.18473        0.4615
#> 5  (0.4,0.5]   0.4   0.5 0.17857 0.32381        0.2857
#> 6  (0.5,0.6]   0.5   0.6 0.25000 0.41052        0.2500
#> 7  (0.6,0.7]   0.6   0.7 0.33333 0.36913        0.4167
#> 8  (0.7,0.8]   0.7   0.8 0.00000 0.00000        1.0000
#> 9  (0.8,0.9]   0.8   0.9     NaN     NaN           NaN
#> 10   (0.9,1]   0.9   1.0     NaN     NaN           NaN

=======
#>          bin  n lower upper     truth       prob
#> 1    (0,0.1]  9   0.0   0.1 0.1111111 0.04153684
#> 2  (0.1,0.2] 14   0.1   0.2 0.3571429 0.15711567
#> 3  (0.2,0.3] 11   0.2   0.3 0.0000000 0.23769284
#> 4  (0.3,0.4]  8   0.3   0.4 0.0000000 0.35361835
#> 5  (0.4,0.5]  9   0.4   0.5 0.2222222 0.43457987
#> 6  (0.5,0.6]  3   0.5   0.6        NA         NA
#> 7  (0.6,0.7]  4   0.6   0.7        NA         NA
#> 8  (0.7,0.8]  0   0.7   0.8        NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9        NA         NA
#> 10   (0.9,1]  0   0.9   1.0        NA         NA
#> 
#> $individuals$ds5
#>          bin  n lower upper      truth       prob
#> 1    (0,0.1] 14   0.0   0.1 0.07142857 0.05121187
#> 2  (0.1,0.2] 12   0.1   0.2 0.08333333 0.14103015
#> 3  (0.2,0.3]  6   0.2   0.3 0.16666667 0.24424537
#> 4  (0.3,0.4]  9   0.3   0.4 0.33333333 0.36701224
#> 5  (0.4,0.5]  9   0.4   0.5 0.22222222 0.44725205
#> 6  (0.5,0.6]  6   0.5   0.6 0.16666667 0.55144358
#> 7  (0.6,0.7]  5   0.6   0.7 0.60000000 0.63888370
#> 8  (0.7,0.8]  0   0.7   0.8         NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9         NA         NA
#> 10   (0.9,1]  0   0.9   1.0         NA         NA
#> 
#> 
#> $aggregated
#>          bin lower upper      truth       prob missing_ratio
#> 1    (0,0.1]   0.0   0.1 0.04545455 0.05264313    0.00000000
#> 2  (0.1,0.2]   0.1   0.2 0.20634921 0.14835563    0.00000000
#> 3  (0.2,0.3]   0.2   0.3 0.07692308 0.22583987    0.07692308
#> 4  (0.3,0.4]   0.3   0.4 0.19444444 0.31337375    0.11111111
#> 5  (0.4,0.5]   0.4   0.5 0.21052632 0.39595427    0.10526316
#> 6  (0.5,0.6]   0.5   0.6 0.21739130 0.28616349    0.47826087
#> 7  (0.6,0.7]   0.6   0.7 0.47826087 0.46589353    0.26086957
#> 8  (0.7,0.8]   0.7   0.8 0.00000000 0.00000000    1.00000000
#> 9  (0.8,0.9]   0.8   0.9        NaN        NaN           NaN
#> 10   (0.9,1]   0.9   1.0        NaN        NaN           NaN

ll_tab = list()
for (i in seq_along(cc$individuals)) {
  ll_tab[[i]] = c(i, cc$individuals[[i]]$n)
}
tab = do.call(rbind, ll_tab)
tab = as.data.frame(rbind(tab, colSums(tab)))
colnames(tab) = c("Server", cc$individuals[[1]]$bin)
cat(knitr::kable(tab, format = "latex"))
#> 
#> \begin{tabular}{r|r|r|r|r|r|r|r|r|r|r}
#> \hline
#> Server & (0,0.1] & (0.1,0.2] & (0.2,0.3] & (0.3,0.4] & (0.4,0.5] & (0.5,0.6] & (0.6,0.7] & (0.7,0.8] & (0.8,0.9] & (0.9,1]\\
#> \hline
#> 1 & 9 & 14 & 7 & 4 & 4 & 4 & 7 & 0 & 0 & 0\\
#> \hline
#> 2 & 5 & 9 & 3 & 6 & 10 & 6 & 5 & 1 & 0 & 0\\
#> \hline
#> 3 & 7 & 14 & 12 & 9 & 6 & 4 & 2 & 0 & 0 & 0\\
#> \hline
#> 4 & 9 & 14 & 11 & 8 & 9 & 3 & 4 & 0 & 0 & 0\\
#> \hline
#> 5 & 14 & 12 & 6 & 9 & 9 & 6 & 5 & 0 & 0 & 0\\
#> \hline
#> 15 & 44 & 63 & 39 & 36 & 38 & 23 & 23 & 1 & 0 & 0\\
#> \hline
#> \end{tabular}

>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
gg_cal = plotCalibrationCurve(cc, size = 1)
gg_cal
#> Warning: Removed 26 rows containing missing values (geom_point).
#> Warning: Removed 26 row(s) containing missing values (geom_path).
#> Warning: Removed 2 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-7-1.png)<!-- -->

### Evaluate the model using ROC analysis

``` r
# Get the l2 sensitivity
(l2s = dsL2Sens(conn, "D", "pinv"))
<<<<<<< HEAD
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 0s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 1s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Assigned expr. (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe"...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>-----------------]  33% / 1s  Getting aggregate ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>--------]  50% / 1s  Checking ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [============>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (rmDS("xXcols")) [--------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (rmDS("xXcols")) [=======>---------------------------------------]  17% / 0s  Checking ds2 (rmDS("xXcols")) [========>-----------------------------------------------]  17% / 0s  Getting aggregate ds2 (rmDS("xXcols")) [===============>-------------------------------]  33% / 0s  Checking ds3 (rmDS("xXcols")) [==================>-------------------------------------]  33% / 1s  Getting aggregate ds3 (rmDS("xXcols")) [=======================>-----------------------]  50% / 1s  Checking ds4 (rmDS("xXcols")) [===========================>----------------------------]  50% / 1s  Getting aggregate ds4 (rmDS("xXcols")) [==============================>----------------]  67% / 1s  Checking ds5 (rmDS("xXcols")) [====================================>-------------------]  67% / 1s  Getting aggregate ds5 (rmDS("xXcols")) [======================================>--------]  83% / 1s  Aggregated (rmDS("xXcols")) [==========================================================] 100% / 1s
#> [1] 0.01599
epsilon = 0.3
=======
#> [1] 0.03717391
epsilon = 0.4
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
delta = 0.2

# Amount of noise added:
sqrt(2 * log(1.25 / delta)) * l2s / epsilon
<<<<<<< HEAD
#> [1] 0.102

# Calculate ROC-GLM
roc_glm = dsROCGLM(conn, "D$valid", "pinv", epsilon = epsilon,
  delta = delta, dat_name = "D", seed_object = "D$age")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 1s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 1s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds1 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds2 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds3 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds4 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Checking ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe", ...  Finalizing assignment ds5 (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d...  Assigned expr. (xXcols <- decodeBinary("580a000000030004010200030500000000055554462d38000000fe"...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>-----------------]  33% / 1s  Getting aggregate ds3 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [=======>--------]  50% / 1s  Checking ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (l2sens("D", "pinv", 91, "xXcols", diff, TRUE)) [============>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (rmDS("xXcols")) [--------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (rmDS("xXcols")) [=======>---------------------------------------]  17% / 0s  Checking ds2 (rmDS("xXcols")) [========>-----------------------------------------------]  17% / 0s  Getting aggregate ds2 (rmDS("xXcols")) [===============>-------------------------------]  33% / 0s  Checking ds3 (rmDS("xXcols")) [==================>-------------------------------------]  33% / 1s  Getting aggregate ds3 (rmDS("xXcols")) [=======================>-----------------------]  50% / 1s  Checking ds4 (rmDS("xXcols")) [===========================>----------------------------]  50% / 1s  Getting aggregate ds4 (rmDS("xXcols")) [==============================>----------------]  67% / 1s  Checking ds5 (rmDS("xXcols")) [====================================>-------------------]  67% / 1s  Getting aggregate ds5 (rmDS("xXcols")) [======================================>--------]  83% / 1s  Aggregated (rmDS("xXcols")) [==========================================================] 100% / 1s
#> 
#> [2022-03-03 19:19:48] L2 sensitivity is: 0.016
=======
#> [1] 0.17792

# Calculate ROC-GLM
roc_glm = dsROCGLM(conn, "D$valid", "pinv", epsilon = epsilon,
  delta = delta, dat_name = "D", seed_object = "D$valid")
#> 
#> [2022-03-03 08:22:12] L2 sensitivity is: 0.0372
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
#> 
#> [2022-03-03 08:22:16] Initializing ROC-GLM
#> 
<<<<<<< HEAD
#> [2022-03-03 19:19:49] Initializing ROC-GLM
#> 
#> [2022-03-03 19:19:49] Host: Received scores of negative response
#> 
#> [2022-03-03 19:19:49] Receiving negative scores
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [---------------]   0% / 0s  Getting aggregate ds1 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [>-----]  17% / 0s  Checking ds2 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=>-------------]  17% / 0s  Getting aggregate ds2 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=>----]  33% / 0s  Checking ds3 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [====>----------]  33% / 1s  Getting aggregate ds3 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [==>---]  50% / 1s  Checking ds4 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=======>-------]  50% / 1s  Getting aggregate ds4 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [===>--]  67% / 1s  Checking ds5 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=========>-----]  67% / 1s  Getting aggregate ds5 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [====>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#> [2022-03-03 19:19:50] Host: Pushing pooled scores
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds1 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds2 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds2 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds3 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds3 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds4 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds4 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Checking ds5 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d380000...  Finalizing assignment ds5 (pooled_scores <- decodeBinary("580a000000030004010200030500000000055...  Assigned expr. (pooled_scores <- decodeBinary("580a000000030004010200030500000000055554462d3800...
#> [2022-03-03 19:19:51] Server: Calculating placement values and parts for ROC-GLM
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [-----------]   0% / 0s  Finalizing assignment ds1 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  17%...  Checking ds2 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=>---------]  17% / 0s  Finalizing assignment ds2 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  33%...  Checking ds3 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [===>-------]  33% / 1s  Finalizing assignment ds3 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  50%...  Checking ds4 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=====>-----]  50% / 1s  Finalizing assignment ds4 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  67%...  Checking ds5 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [======>----]  67% / 1s  Finalizing assignment ds5 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  83%...  Assigned expr. (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=========] 100% / 1s
#> [2022-03-03 19:19:52] Server: Calculating probit regression to obtain ROC-GLM
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 1s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 19:19:53] Deviance of iter1=32.6342
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 19:19:54] Deviance of iter2=42.7685
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 1s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 19:19:55] Deviance of iter3=46.9368
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 1s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 19:19:56] Deviance of iter4=47.1534
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 1s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 19:19:57] Deviance of iter5=47.154
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 1s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2022-03-03 19:19:58] Deviance of iter6=47.154
#> [2022-03-03 19:19:58] Host: Finished calculating ROC-GLM
#> [2022-03-03 19:19:58] Host: Cleaning data on server
#> [2022-03-03 19:20:01] Host: Calculating AUC and CI
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (meanDS(D$valid)) [-------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (meanDS(D$valid)) [=======>--------------------------------------]  17% / 0s  Checking ds2 (meanDS(D$valid)) [========>----------------------------------------------]  17% / 0s  Getting aggregate ds2 (meanDS(D$valid)) [==============>-------------------------------]  33% / 1s  Checking ds3 (meanDS(D$valid)) [=================>-------------------------------------]  33% / 1s  Getting aggregate ds3 (meanDS(D$valid)) [======================>-----------------------]  50% / 1s  Checking ds4 (meanDS(D$valid)) [===========================>---------------------------]  50% / 1s  Getting aggregate ds4 (meanDS(D$valid)) [==============================>---------------]  67% / 1s  Checking ds5 (meanDS(D$valid)) [====================================>------------------]  67% / 1s  Getting aggregate ds5 (meanDS(D$valid)) [=====================================>--------]  83% / 1s  Aggregated (meanDS(D$valid)) [=========================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScoresVar("D$valid", "pinv")) [-------------------------------]   0% / 0s  Getting aggregate ds1 (getNegativeScoresVar("D$valid", "pinv")) [===>------------------]  17% / 0s  Checking ds2 (getNegativeScoresVar("D$valid", "pinv")) [====>--------------------------]  17% / 0s  Getting aggregate ds2 (getNegativeScoresVar("D$valid", "pinv")) [======>---------------]  33% / 0s  Checking ds3 (getNegativeScoresVar("D$valid", "pinv")) [=========>---------------------]  33% / 1s  Getting aggregate ds3 (getNegativeScoresVar("D$valid", "pinv")) [==========>-----------]  50% / 1s  Checking ds4 (getNegativeScoresVar("D$valid", "pinv")) [===============>---------------]  50% / 1s  Getting aggregate ds4 (getNegativeScoresVar("D$valid", "pinv")) [==============>-------]  67% / 1s  Checking ds5 (getNegativeScoresVar("D$valid", "pinv")) [====================>----------]  67% / 1s  Getting aggregate ds5 (getNegativeScoresVar("D$valid", "pinv")) [=================>----]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getPositiveScoresVar("D$valid", "pinv")) [-------------------------------]   0% / 0s  Getting aggregate ds1 (getPositiveScoresVar("D$valid", "pinv")) [===>------------------]  17% / 0s  Checking ds2 (getPositiveScoresVar("D$valid", "pinv")) [====>--------------------------]  17% / 0s  Getting aggregate ds2 (getPositiveScoresVar("D$valid", "pinv")) [======>---------------]  33% / 0s  Checking ds3 (getPositiveScoresVar("D$valid", "pinv")) [=========>---------------------]  33% / 1s  Getting aggregate ds3 (getPositiveScoresVar("D$valid", "pinv")) [==========>-----------]  50% / 1s  Checking ds4 (getPositiveScoresVar("D$valid", "pinv")) [===============>---------------]  50% / 1s  Getting aggregate ds4 (getPositiveScoresVar("D$valid", "pinv")) [==============>-------]  67% / 1s  Checking ds5 (getPositiveScoresVar("D$valid", "pinv")) [====================>----------]  67% / 1s  Getting aggregate ds5 (getPositiveScoresVar("D$valid", "pinv")) [=================>----]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [---------------]   0% / 0s  Getting aggregate ds1 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [>-----]  17% / 0s  Checking ds2 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=>-------------]  17% / 0s  Getting aggregate ds2 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=>----]  33% / 0s  Checking ds3 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [====>----------]  33% / 1s  Getting aggregate ds3 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [==>---]  50% / 1s  Checking ds4 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=======>-------]  50% / 1s  Getting aggregate ds4 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [===>--]  67% / 1s  Checking ds5 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=========>-----]  67% / 1s  Getting aggregate ds5 (getNegativeScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [====>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [---------------]   0% / 0s  Getting aggregate ds1 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [>-----]  17% / 0s  Checking ds2 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=>-------------]  17% / 0s  Getting aggregate ds2 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=>----]  33% / 0s  Checking ds3 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [====>----------]  33% / 1s  Getting aggregate ds3 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [==>---]  50% / 1s  Checking ds4 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=======>-------]  50% / 1s  Getting aggregate ds4 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [===>--]  67% / 1s  Checking ds5 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [=========>-----]  67% / 1s  Getting aggregate ds5 (getPositiveScores("D$valid", "pinv", 0.3, 0.2, "D$age")) [====>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#> [2022-03-03 19:20:06] Finished!
=======
#> [2022-03-03 08:22:16] Host: Received scores of negative response
#> [2022-03-03 08:22:16] Receiving negative scores
#> [2022-03-03 08:22:19] Host: Pushing pooled scores
#> [2022-03-03 08:22:23] Server: Calculating placement values and parts for ROC-GLM
#> [2022-03-03 08:22:26] Server: Calculating probit regression to obtain ROC-GLM
#> [2022-03-03 08:22:30] Deviance of iter1=19.3983
#> [2022-03-03 08:22:33] Deviance of iter2=16.4241
#> [2022-03-03 08:22:37] Deviance of iter3=16.4477
#> [2022-03-03 08:22:40] Deviance of iter4=16.4485
#> [2022-03-03 08:22:44] Deviance of iter5=16.4485
#> [2022-03-03 08:22:47] Deviance of iter6=16.4485
#> [2022-03-03 08:22:47] Host: Finished calculating ROC-GLM
#> [2022-03-03 08:22:47] Host: Cleaning data on server
#> [2022-03-03 08:22:51] Host: Calculating AUC and CI
#> [2022-03-03 08:23:08] Finished!
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
roc_glm
#> 
#> ROC-GLM after Pepe:
#> 
<<<<<<< HEAD
#>  Binormal form: pnorm(0.79 + 1.15*qnorm(t))
#> 
#>  AUC and 0.95 CI: [0.61----0.7----0.77]
roc_glm$ci
#> [1] 0.6137 0.7713
=======
#>  Binormal form: pnorm(0.56 + 0.86*qnorm(t))
#> 
#>  AUC and 0.95 CI: [0.53----0.66----0.78]
roc_glm$ci
#> [1] 0.5283211 0.7776434
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13

gg_distr_roc = plot(roc_glm)
gg_distr_roc
```

![](figures/unnamed-chunk-9-1.png)<!-- -->

**Simple check if old (model from the last rendering) and new ROC-GLM
are equal:**

``` r
# Check if roc_glm object is the same for the new and the last run:
if (! file.exists(here::here("data/roc-glm.Rda"))) {
  saveRDS(roc_glm, file = here::here("data/roc-glm.Rda"))
} else {
  roc_glm_last_run = readRDS(here::here("data/roc-glm.Rda"))
  if (! identical(roc_glm_last_run, roc_glm))
    warning("Old and new ROC-GLM are not equal!")

  saveRDS(roc_glm, file = here::here("data/roc-glm.Rda"))
}
```

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
<<<<<<< HEAD
#>            0.6887            0.6983

source(here::here("R/helper.R"))
(ci_emp = logitToAUC(pepeCI(toLogit(auc), 0.05, deLongVar(1 - probs, dat_test$valid))))
#> [1] 0.6100 0.7578
=======
#>         0.6884146         0.6643401

source(here::here("R/helper.R"))
logitToAUC(pepeCI(toLogit(auc), 0.05, deLongVar(1 - probs, dat_test$valid)))
#> [1] 0.6012050 0.7640381
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13


# Calculate TPR and FPR values and add to distributed ROC-GLM plot
plt_emp_roc_data = simpleROC(dat_test$valid, 1 - probs)

gg_roc_pooled = plot(roc_glm) +
  geom_line(data = plt_emp_roc_data, aes(x = FPR, y = TPR), color = "red")
gg_roc_pooled
```

![](figures/unnamed-chunk-12-1.png)<!-- -->

``` r

# Calculate pooled brier score and calibration curve
brier_pooled = mean((dat_test$valid - (1 - probs))^2)
c(brier_pooled = brier_pooled, brier_distr = brier)
#> brier_pooled  brier_distr 
<<<<<<< HEAD
#>       0.1721       0.1721
=======
#>    0.1630864    0.1630864
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13

cc_pooled = calibrationCurve("dat_test$valid", "1 - probs", nbins = 10)

# Table of elements per server for the calibration curve:
ll_tab = list()
for (i in seq_along(cc$individuals)) {
  ll_tab[[i]] = c(i, cc$individuals[[i]]$n)
}
tab = do.call(rbind, ll_tab)
tab = as.data.frame(rbind(tab, colSums(tab)))
colnames(tab) = c("Server", cc$individuals[[1]]$bin)
tab0 = tab
for (j in seq_along(tab)[-1]) {
  tab[[j]] = paste0("$", ifelse(tab[[j]] < 5, tab[[j]], paste0("\\bm{", tab[[j]], "}")), "$")
}
tab[[1]] = paste0("$", tab[[1]], "$")
tab[6, 1] = "$\\sum$"

# LaTeX Table:
writeLines(knitr::kable(tab, format = "latex", escape = FALSE),
  con = here::here("tables/tab-cc.tex"))

knitr::kable(tab0)
```

| Server | (0,0.1\] | (0.1,0.2\] | (0.2,0.3\] | (0.3,0.4\] | (0.4,0.5\] | (0.5,0.6\] | (0.6,0.7\] | (0.7,0.8\] | (0.8,0.9\] | (0.9,1\] |
| -----: | -------: | ---------: | ---------: | ---------: | ---------: | ---------: | ---------: | ---------: | ---------: | -------: |
|      1 |       12 |         12 |         14 |          1 |          4 |          6 |          4 |          0 |          0 |        0 |
|      2 |       12 |         16 |          6 |          1 |          6 |          3 |          2 |          0 |          0 |        0 |
|      3 |       14 |         13 |         12 |          4 |          4 |          3 |          6 |          1 |          0 |        0 |
|      4 |        9 |          7 |          7 |          7 |          8 |          6 |          4 |          0 |          0 |        0 |
|      5 |       13 |         14 |         10 |          0 |          6 |          6 |          8 |          1 |          0 |        0 |
|     15 |       60 |         62 |         49 |         13 |         28 |         24 |         24 |          2 |          0 |        0 |

``` r



# Visualize distributed calibration curve vs. pooled one:

gg_cal_pooled = plotCalibrationCurve(cc, size = 1.5, individuals = FALSE) +
    geom_line(data = cc_pooled, aes(x = prob, y = truth), color = "red")
gg_cal_pooled
#> Warning: Removed 2 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
#> Warning: Removed 3 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-12-2.png)<!-- -->

``` r
# Summary of the results used in the paper:
tex_results = rbind(
  data.frame(command = "\\cdistlower", value = round(roc_glm$ci[1], 4)),
  data.frame(command = "\\cidistupper", value = round(roc_glm$ci[2], 4)),
  data.frame(command = "\\ciemplower", value = round(ci_emp[1], 4)),
  data.frame(command = "\\ciempupper", value = round(ci_emp[2], 4)),
  data.frame(command = "\\aucdist", value = round(roc_glm$auc, 4)),
  data.frame(command = "\\aucpooled", value = round(auc, 4)),
  data.frame(command = "\\rocglmparamOne", value = round(roc_glm$parameter[1], 4)),
  data.frame(command = "\\rocglmparamTwo", value = round(roc_glm$parameter[2], 4)),
  data.frame(command = "\\bsemp", value = round(brier_pooled, 4)),
  data.frame(command = "\\ts", value = 2 * 365),
  data.frame(command = "\\nOne", value = ddim[[1]][1]),
  data.frame(command = "\\nTwo", value = ddim[[2]][1]),
  data.frame(command = "\\nThree", value = ddim[[3]][1]),
  data.frame(command = "\\nFour", value = ddim[[4]][1]),
  data.frame(command = "\\nFive", value = ddim[[5]][1]),
  data.frame(command = "\\privparOne", value = "0.4"),
  data.frame(command = "\\privparTwo", value = "0.2"),
  data.frame(command = "\\ltwosensUC", value = round(l2s, 4))
)
writeLines(paste0("\\newcommand{", tex_results[[1]], "}{", tex_results[[2]], "}"),
  here::here("tables/tab-results.tex"))
```

## Log out from DataSHIELD servers

``` r
datashield.logout(conn)
<<<<<<< HEAD
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Logout ds1 [===========>---------------------------------------------------------------]  17% / 0s  Logout ds2 [========================>--------------------------------------------------]  33% / 0s  Logout ds3 [=====================================>-------------------------------------]  50% / 0s  Logout ds4 [=================================================>-------------------------]  67% / 1s  Logout ds5 [=============================================================>-------------]  83% / 1s  Logged out from all servers [==========================================================] 100% / 1s
=======
>>>>>>> e2631404a7a7653f9ac98fb3c00c9e7ae9ce2e13
```
