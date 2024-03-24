# DataSHIELD Use-case: Distributed non-disclosive validation of predictive models by a modified ROC-GLM

<!-- README.md is generated from README.Rmd. Please edit that file -->

- [About the repository](#about-the-repository) 
  - [Structure of the repository](#structure-of-the-repository)
- [Setup](#setup) 
  - [Install packages](#install-packages)
  - [Generate data and fit model](#generate-data-and-fit-model)
  - [Install package on DataSHIELD and upload data](#install-package-on-datashield-and-upload-data)
- [Analysis](#analysis) 
  - [Log into DataSHIELD test server](#log-into-datashield-test-server)
  - [Push and predict](#push-and-predict)
  - [Analyse calibration of the predictions](#analyse-calibration-of-the-predictions)
  - [Evaluate the model using ROC analysis](#evaluate-the-model-using-roc-analysis)
  - [Cross check on pooled test data](#cross-check-on-pooled-test-data)
- [Log out from DataSHIELD servers](#log-out-from-datashield-servers)
- [Session Info](#session-info)

<!-- README.md is generated from README.Rmd. Please edit that file -->

## About the repository

This repository contains a short use-case base on the three packages
`dsPredictBase`, `dsCalibration`, and `dsROCGLM`. The main intend is to
have a use-case to demonstrate how to distributively evaluate a model
using the distributed
[ROC-GLM](https://pubmed.ncbi.nlm.nih.gov/10877289/).

The following contains the preparation of test data and a test model as
[setup](#setup) while the second part is the [analysis](#analysis).

Last time rendered: 18:56 - 22. Mär 2024 by user rrehms

Autobuild: ![Render
README](https://github.com/difuture-lmu/datashield-demo-survival/actions/workflows/render-readme.yaml/badge.svg)

### Structure of the repository

- `R`: 
  - `create-model.R`: Creates a `ranger` used for the use-case based on the data in `generate-data.R`
  - `generate-data.R`: Takes the data set `GBSG2` (see `?GBSG2` for a description) from the `TH.data`, splits it into trian and test using 60 - 40 % of the data, and furhter splits the 40 % for testing into 5 parts for the distributed setup.
  - `helper.R`: Helper functions to locally calculate the [ROC-GLM](https://pubmed.ncbi.nlm.nih.gov/10877289/) and compute confidence intervals etc.
  - `install-ds-packages.R`: Install the necessary packages (`ranger`, `dsPredictBase`, `dsCalibration`, and `dsROCGLM`) **at the DataSHIELD servers**.
  - `install-packages.R`: Install ncessary packages locally.
  - `upload-data.R` Creates a project at the DataSHIELD server and uploads the data created by `generate-data.R`.
- `data`: All data is stored here: 
  - Train and test split of the GBSG2 data set (`data-train.csv` and `data-test.csv`).
  - The 5 splits of the `data-test.csv` for the servers (`SRV1.csv`, `SRV2.csv`, `SRV3.csv`, `SRV4.csv`, and `SRV5.csv`).
  - The model created by `create-model.R` (`mod.Rda`).
  - `log.csv`: A csv file for logging each rendering. This file can be used to get an overview about the important values and when each rendering was conducted. The main purpose is to show that the results are reproduced at each rendering.
  - The ROC-GLM of the last rendering (`roc-glm.Rda`).
- `figures`: Figures created by the rendering are placed here. These are the `.pdf` fuiles used in the publication but also the `.png` files of the README.
- `tables`: Tables created by the rendering are placed here.

## Setup

### Install packages

Install all packages locally:

```r
remotes::install_github("difuture-lmu/dsPredictBase", upgrade = "never")
#> Skipping install of 'dsPredictBase' from a github remote, the SHA1 (8266effc) has not changed since last install.
#>   Use `force = TRUE` to force installation
remotes::install_github("difuture-lmu/dsCalibration", upgrade = "never")
#> Skipping install of 'dsCalibration' from a github remote, the SHA1 (1805632c) has not changed since last install.
#>   Use `force = TRUE` to force installation
remotes::install_github("difuture-lmu/dsROCGLM", upgrade = "never")
#> Skipping install of 'dsROCGLM' from a github remote, the SHA1 (d144b32e) has not changed since last install.
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

```r
source(here::here("R/generate-data.R"))
source(here::here("R/create-model.R"))
```

### Install package on DataSHIELD and upload data

```r
source(here::here("R/upload-data.R"))
source(here::here("R/install-ds-packages.R"))
```

## Analysis

### Log into DataSHIELD test server

```r
library(DSI)
#> Lade nötiges Paket: progress
#> Lade nötiges Paket: R6
library(DSOpal)
library(dsBaseClient)

library(dsPredictBase)
library(dsCalibration)
library(dsROCGLM)
#> 
#> Attache Paket: 'dsROCGLM'
#> Die folgenden Objekte sind maskiert von 'package:dsCalibration':
#> 
#>     brierScore, calibrationCurve, dsBrierScore, dsCalibrationCurve,
#>     plotCalibrationCurve
#> Die folgenden Objekte sind maskiert von 'package:dsPredictBase':
#> 
#>     assignPredictModel, decodeBinary, encodeObject, predictModel,
#>     pushObject, removeMissings

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
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Login ds1 [============>---------------------------------------------------------------]  17% / 0s  Login ds2 [========================>---------------------------------------------------]  33% / 0s  Login ds3 [=====================================>--------------------------------------]  50% / 1s  Login ds4 [==================================================>-------------------------]  67% / 1s  Login ds5 [==============================================================>-------------]  83% / 1s  Logged in all servers [================================================================] 100% / 1s
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

## Data dimensions per server:
(ddim = ds.dim("D"))
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Checking ds2 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Checking ds3 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Checking ds4 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Checking ds5 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Waiting...  (dimDS("D")) [-------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Checking ds2 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Checking ds3 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Checking ds4 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds5 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Waiting...  (dimDS("D")) [-------------------------------------------------------------]   0% / 1s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds2 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds3 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds4 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds5 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Waiting...  (dimDS("D")) [-------------------------------------------------------------]   0% / 1s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds2 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds3 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds4 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds5 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Waiting...  (dimDS("D")) [-------------------------------------------------------------]   0% / 1s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds2 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds3 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds4 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Checking ds5 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Waiting...  (dimDS("D")) [-------------------------------------------------------------]   0% / 1s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 1s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 1s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 1s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 2s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 2s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 2s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 2s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 2s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 2s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 2s  Aggregated (dimDS("D")) [==============================================================] 100% / 2s
#> $`dimensions of D in ds1`
#> [1] 51 11
#> 
#> $`dimensions of D in ds2`
#> [1] 45 11
#> 
#> $`dimensions of D in ds3`
#> [1] 55 11
#> 
#> $`dimensions of D in ds4`
#> [1] 46 11
#> 
#> $`dimensions of D in ds5`
#> [1] 53 11
#> 
#> $`dimensions of D in combined studies`
#> [1] 250  11
```

### Push and predict

```r
## Load the pre-calculated logistic regression:
load(here::here("data/mod.Rda"))

## Push the model to the servers (upload takes ~11 Minutes):
t0 = proc.time()
pushObject(conn, obj = mod)
#> [2024-03-22 18:57:03] Your object is bigger than 1 MB (6.6 MB). Uploading larger objects may take some time.
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (mod <- decodeBinary("580a000000030004020200030500000000055554462d3800000313000000...  Finalizing assignment ds1 (mod <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds2 (mod <- decodeBinary("580a000000030004020200030500000000055554462d3800000313000000...  Finalizing assignment ds2 (mod <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds3 (mod <- decodeBinary("580a000000030004020200030500000000055554462d3800000313000000...  Finalizing assignment ds3 (mod <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds4 (mod <- decodeBinary("580a000000030004020200030500000000055554462d3800000313000000...  Finalizing assignment ds4 (mod <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds5 (mod <- decodeBinary("580a000000030004020200030500000000055554462d3800000313000000...  Finalizing assignment ds5 (mod <- decodeBinary("580a000000030004020200030500000000055554462d380...  Assigned expr. (mod <- decodeBinary("580a000000030004020200030500000000055554462d38000003130000...
(t0 = proc.time() - t0)
#>        User      System verstrichen 
#>      27.070       7.425     123.224
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
(tpoint = which(ranger::timepoints(mod) >= 730)[1])
#> [1] 97

## Predict the model on the data sets located at the servers:
pfun = paste0("ranger:::predict.ranger(mod, data = D)$survival[, ", tpoint, "]")
predictModel(conn, mod, "probs", predict_fun = pfun, package = "ranger")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (probs <- assignPredictModel("580a000000030004020200030500000000055554462d38000000...  Finalizing assignment ds1 (probs <- assignPredictModel("580a00000003000402020003050000000005555...  Checking ds2 (probs <- assignPredictModel("580a000000030004020200030500000000055554462d38000000...  Finalizing assignment ds2 (probs <- assignPredictModel("580a00000003000402020003050000000005555...  Checking ds3 (probs <- assignPredictModel("580a000000030004020200030500000000055554462d38000000...  Finalizing assignment ds3 (probs <- assignPredictModel("580a00000003000402020003050000000005555...  Checking ds4 (probs <- assignPredictModel("580a000000030004020200030500000000055554462d38000000...  Finalizing assignment ds4 (probs <- assignPredictModel("580a00000003000402020003050000000005555...  Checking ds5 (probs <- assignPredictModel("580a000000030004020200030500000000055554462d38000000...  Finalizing assignment ds5 (probs <- assignPredictModel("580a00000003000402020003050000000005555...  Assigned expr. (probs <- assignPredictModel("580a000000030004020200030500000000055554462d380000...
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
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (pinv <- 1 - probs) [-----------------------------------------------------]   0% / 0s  Finalizing assignment ds1 (pinv <- 1 - probs) [======>---------------------------------]  17% / 0s  Checking ds2 (pinv <- 1 - probs) [========>--------------------------------------------]  17% / 0s  Finalizing assignment ds2 (pinv <- 1 - probs) [============>---------------------------]  33% / 0s  Checking ds3 (pinv <- 1 - probs) [=================>-----------------------------------]  33% / 0s  Finalizing assignment ds3 (pinv <- 1 - probs) [===================>--------------------]  50% / 0s  Checking ds4 (pinv <- 1 - probs) [=========================>---------------------------]  50% / 1s  Finalizing assignment ds4 (pinv <- 1 - probs) [==========================>-------------]  67% / 1s  Checking ds5 (pinv <- 1 - probs) [==================================>------------------]  67% / 1s  Finalizing assignment ds5 (pinv <- 1 - probs) [================================>-------]  83% / 1s  Assigned expr. (pinv <- 1 - probs) [===================================================] 100% / 1s
```

### Analyse calibration of the predictions

#### Figure 7, Section 6.3

```r
brier = dsBrierScore(conn, "D$valid", "pinv")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (brierScore("D$valid", "pinv")) [-----------------------------------------]   0% / 0s  Getting aggregate ds1 (brierScore("D$valid", "pinv")) [====>---------------------------]  17% / 0s  Checking ds2 (brierScore("D$valid", "pinv")) [======>----------------------------------]  17% / 0s  Getting aggregate ds2 (brierScore("D$valid", "pinv")) [==========>---------------------]  33% / 0s  Checking ds3 (brierScore("D$valid", "pinv")) [=============>---------------------------]  33% / 0s  Getting aggregate ds3 (brierScore("D$valid", "pinv")) [===============>----------------]  50% / 0s  Checking ds4 (brierScore("D$valid", "pinv")) [===================>---------------------]  50% / 1s  Getting aggregate ds4 (brierScore("D$valid", "pinv")) [====================>-----------]  67% / 1s  Checking ds5 (brierScore("D$valid", "pinv")) [==========================>--------------]  67% / 1s  Getting aggregate ds5 (brierScore("D$valid", "pinv")) [==========================>-----]  83% / 1s  Aggregated (brierScore("D$valid", "pinv")) [===========================================] 100% / 1s
brier
#> [1] 0.1843399

cc = dsCalibrationCurve(conn, "D$valid", "pinv")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [=======>-----------------]  33% / 0s  Getting aggregate ds3 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [=======>--------]  50% / 0s  Checking ds4 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (calibrationCurve("D$valid", "pinv", 10, TRUE)) [============>---]  83% / 1s  Aggregated (calibrationCurve("D$valid", "pinv", 10, TRUE)) [===========================] 100% / 1s
cc
#> $individuals
#> $individuals$ds1
#>          bin  n lower upper     truth       prob
#> 1    (0,0.1]  6   0.0   0.1 0.3333333 0.03649882
#> 2  (0.1,0.2] 13   0.1   0.2 0.3846154 0.14406762
#> 3  (0.2,0.3]  9   0.2   0.3 0.2222222 0.24489753
#> 4  (0.3,0.4]  4   0.3   0.4        NA         NA
#> 5  (0.4,0.5]  3   0.4   0.5        NA         NA
#> 6  (0.5,0.6]  7   0.5   0.6 0.5714286 0.54546151
#> 7  (0.6,0.7]  7   0.6   0.7 0.4285714 0.62812935
#> 8  (0.7,0.8]  1   0.7   0.8        NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9        NA         NA
#> 10   (0.9,1]  0   0.9   1.0        NA         NA
#> 
#> $individuals$ds2
#>          bin  n lower upper     truth      prob
#> 1    (0,0.1] 10   0.0   0.1 0.1000000 0.0651384
#> 2  (0.1,0.2] 11   0.1   0.2 0.2727273 0.1556037
#> 3  (0.2,0.3]  6   0.2   0.3 0.1666667 0.2277947
#> 4  (0.3,0.4]  2   0.3   0.4        NA        NA
#> 5  (0.4,0.5]  4   0.4   0.5        NA        NA
#> 6  (0.5,0.6]  5   0.5   0.6 0.6000000 0.5697076
#> 7  (0.6,0.7]  5   0.6   0.7 0.6000000 0.6308913
#> 8  (0.7,0.8]  0   0.7   0.8        NA        NA
#> 9  (0.8,0.9]  0   0.8   0.9        NA        NA
#> 10   (0.9,1]  0   0.9   1.0        NA        NA
#> 
#> $individuals$ds3
#>          bin  n lower upper      truth       prob
#> 1    (0,0.1] 14   0.0   0.1 0.07142857 0.06101983
#> 2  (0.1,0.2]  9   0.1   0.2 0.11111111 0.14254825
#> 3  (0.2,0.3] 13   0.2   0.3 0.38461538 0.25056013
#> 4  (0.3,0.4]  3   0.3   0.4         NA         NA
#> 5  (0.4,0.5]  4   0.4   0.5         NA         NA
#> 6  (0.5,0.6]  6   0.5   0.6 0.33333333 0.54432573
#> 7  (0.6,0.7]  4   0.6   0.7         NA         NA
#> 8  (0.7,0.8]  1   0.7   0.8         NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9         NA         NA
#> 10   (0.9,1]  0   0.9   1.0         NA         NA
#> 
#> $individuals$ds4
#>          bin  n lower upper     truth       prob
#> 1    (0,0.1] 12   0.0   0.1 0.1666667 0.04255948
#> 2  (0.1,0.2] 11   0.1   0.2 0.1818182 0.15399899
#> 3  (0.2,0.3]  5   0.2   0.3 0.2000000 0.24454535
#> 4  (0.3,0.4]  1   0.3   0.4        NA         NA
#> 5  (0.4,0.5]  8   0.4   0.5 0.3750000 0.42963662
#> 6  (0.5,0.6]  2   0.5   0.6        NA         NA
#> 7  (0.6,0.7]  7   0.6   0.7 0.5714286 0.63744509
#> 8  (0.7,0.8]  0   0.7   0.8        NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9        NA         NA
#> 10   (0.9,1]  0   0.9   1.0        NA         NA
#> 
#> $individuals$ds5
#>          bin  n lower upper      truth       prob
#> 1    (0,0.1] 11   0.0   0.1 0.00000000 0.05308893
#> 2  (0.1,0.2] 13   0.1   0.2 0.07692308 0.15078135
#> 3  (0.2,0.3] 11   0.2   0.3 0.09090909 0.23788672
#> 4  (0.3,0.4]  2   0.3   0.4         NA         NA
#> 5  (0.4,0.5]  4   0.4   0.5         NA         NA
#> 6  (0.5,0.6]  4   0.5   0.6         NA         NA
#> 7  (0.6,0.7]  5   0.6   0.7 0.60000000 0.62158732
#> 8  (0.7,0.8]  1   0.7   0.8         NA         NA
#> 9  (0.8,0.9]  0   0.8   0.9         NA         NA
#> 10   (0.9,1]  0   0.9   1.0         NA         NA
#> 
#> 
#> $aggregated
#>          bin lower upper     truth       prob missing_ratio
#> 1    (0,0.1]   0.0   0.1 0.1132075 0.05319522     0.0000000
#> 2  (0.1,0.2]   0.1   0.2 0.2105263 0.14950177     0.0000000
#> 3  (0.2,0.3]   0.2   0.3 0.2272727 0.24244564     0.0000000
#> 4  (0.3,0.4]   0.3   0.4 0.0000000 0.00000000     1.0000000
#> 5  (0.4,0.5]   0.4   0.5 0.1304348 0.14943882     0.6521739
#> 6  (0.5,0.6]   0.5   0.6 0.3750000 0.41386345     0.2500000
#> 7  (0.6,0.7]   0.6   0.7 0.4642857 0.54005051     0.1428571
#> 8  (0.7,0.8]   0.7   0.8 0.0000000 0.00000000     1.0000000
#> 9  (0.8,0.9]   0.8   0.9       NaN        NaN           NaN
#> 10   (0.9,1]   0.9   1.0       NaN        NaN           NaN
#> 
#> attr(,"class")
#> [1] "calibration.curve"

gg_cal = plotCalibrationCurve(cc, size = 1)
gg_cal
#> Warning: Removed 27 rows containing missing values (geom_point).
#> Warning: Removed 27 row(s) containing missing values (geom_path).
#> Warning: Removed 2 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-7-1.png)<!-- -->

### Evaluate the model using ROC analysis

#### Figure 6, Section 6.2

```r
# Get the l2 sensitivity
(l2s = dsL2Sens(conn, "D", "pinv"))
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 0s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 0s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 0s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 0s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds1 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds2 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds2 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds3 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds3 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds4 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds4 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds5 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds5 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Assigned expr. (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe"...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [=======>-----------------]  33% / 0s  Getting aggregate ds3 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [=======>--------]  50% / 0s  Checking ds4 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [============>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (rmDS("xXcols")) [--------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (rmDS("xXcols")) [=======>---------------------------------------]  17% / 0s  Checking ds2 (rmDS("xXcols")) [========>-----------------------------------------------]  17% / 0s  Getting aggregate ds2 (rmDS("xXcols")) [===============>-------------------------------]  33% / 0s  Checking ds3 (rmDS("xXcols")) [==================>-------------------------------------]  33% / 0s  Getting aggregate ds3 (rmDS("xXcols")) [=======================>-----------------------]  50% / 0s  Checking ds4 (rmDS("xXcols")) [===========================>----------------------------]  50% / 1s  Getting aggregate ds4 (rmDS("xXcols")) [==============================>----------------]  67% / 1s  Checking ds5 (rmDS("xXcols")) [====================================>-------------------]  67% / 1s  Getting aggregate ds5 (rmDS("xXcols")) [======================================>--------]  83% / 1s  Aggregated (rmDS("xXcols")) [==========================================================] 100% / 1s
#> [1] 0.177211
epsilon = 5
delta = 0.01

# Amount of noise added:
analyticGaussianMechanism(5, 0.01, l2s)
#> [1] 0.1009003

# Calculate ROC-GLM
roc_glm = dsROCGLM(conn, "D$valid", "pinv", dat_name = "D", seed_object = "l2s")
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 0s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 0s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds1 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds2 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds2 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds3 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds3 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds4 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds4 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Checking ds5 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe", ...  Finalizing assignment ds5 (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d...  Assigned expr. (xXcols <- decodeBinary("580a000000030004020200030500000000055554462d38000000fe"...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [-------------------------]   0% / 0s  Getting aggregate ds1 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [==>-------------]  17% / 0s  Checking ds2 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [===>---------------------]  17% / 0s  Getting aggregate ds2 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [====>-----------]  33% / 0s  Checking ds3 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [=======>-----------------]  33% / 0s  Getting aggregate ds3 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [=======>--------]  50% / 0s  Checking ds4 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [===========>-------------]  50% / 1s  Getting aggregate ds4 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [==========>-----]  67% / 1s  Checking ds5 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [================>--------]  67% / 1s  Getting aggregate ds5 (l2sens("D", "pinv", 83, "xXcols", diff, TRUE)) [============>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (rmDS("xXcols")) [--------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (rmDS("xXcols")) [=======>---------------------------------------]  17% / 0s  Checking ds2 (rmDS("xXcols")) [========>-----------------------------------------------]  17% / 0s  Getting aggregate ds2 (rmDS("xXcols")) [===============>-------------------------------]  33% / 0s  Checking ds3 (rmDS("xXcols")) [==================>-------------------------------------]  33% / 0s  Getting aggregate ds3 (rmDS("xXcols")) [=======================>-----------------------]  50% / 0s  Checking ds4 (rmDS("xXcols")) [===========================>----------------------------]  50% / 1s  Getting aggregate ds4 (rmDS("xXcols")) [==============================>----------------]  67% / 1s  Checking ds5 (rmDS("xXcols")) [====================================>-------------------]  67% / 1s  Getting aggregate ds5 (rmDS("xXcols")) [======================================>--------]  83% / 1s  Aggregated (rmDS("xXcols")) [==========================================================] 100% / 1s
#> 
#> [2024-03-22 18:59:16] L2 sensitivity is: 0.1772
#> 
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380000000e000000...  Finalizing assignment ds1 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds2 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380000000e000000...  Finalizing assignment ds2 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds3 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380000000e000000...  Finalizing assignment ds3 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds4 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380000000e000000...  Finalizing assignment ds4 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380...  Checking ds5 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380000000e000000...  Finalizing assignment ds5 (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380...  Assigned expr. (l2s <- decodeBinary("580a000000030004020200030500000000055554462d380000000e0000...
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (dimDS("D")) [------------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (dimDS("D")) [=======>-------------------------------------------]  17% / 0s  Checking ds2 (dimDS("D")) [=========>--------------------------------------------------]  17% / 0s  Getting aggregate ds2 (dimDS("D")) [================>----------------------------------]  33% / 0s  Checking ds3 (dimDS("D")) [===================>----------------------------------------]  33% / 0s  Getting aggregate ds3 (dimDS("D")) [=========================>-------------------------]  50% / 1s  Checking ds4 (dimDS("D")) [=============================>------------------------------]  50% / 1s  Getting aggregate ds4 (dimDS("D")) [=================================>-----------------]  67% / 1s  Checking ds5 (dimDS("D")) [=======================================>--------------------]  67% / 1s  Getting aggregate ds5 (dimDS("D")) [=========================================>---------]  83% / 1s  Aggregated (dimDS("D")) [==============================================================] 100% / 1s
#> 
#> [2024-03-22 18:59:18] Setting: epsilon = 5 and delta = 0.01
#> 
#> 
#> [2024-03-22 18:59:18] Initializing ROC-GLM
#> 
#> [2024-03-22 18:59:18] Host: Received scores of negative response
#> 
#> [2024-03-22 18:59:18] Receiving negative scores
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [------------]   0% / 0s  Getting aggregate ds1 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [---]  17% / 0s  Checking ds2 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>----------]  17% / 0s  Getting aggregate ds2 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [>--]  33% / 0s  Checking ds3 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [===>--------]  33% / 0s  Getting aggregate ds3 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  50% / 0s  Checking ds4 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=====>------]  50% / 1s  Getting aggregate ds4 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  67% / 1s  Checking ds5 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=======>----]  67% / 1s  Getting aggregate ds5 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#> [2024-03-22 18:59:18] Host: Pushing pooled scores
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055554462d380000...  Finalizing assignment ds1 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055...  Checking ds2 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055554462d380000...  Finalizing assignment ds2 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055...  Checking ds3 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055554462d380000...  Finalizing assignment ds3 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055...  Checking ds4 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055554462d380000...  Finalizing assignment ds4 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055...  Checking ds5 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055554462d380000...  Finalizing assignment ds5 (pooled_scores <- decodeBinary("580a000000030004020200030500000000055...  Assigned expr. (pooled_scores <- decodeBinary("580a000000030004020200030500000000055554462d3800...
#> [2024-03-22 18:59:19] Server: Calculating placement values and parts for ROC-GLM
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [-----------]   0% / 0s  Finalizing assignment ds1 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  17%...  Checking ds2 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=>---------]  17% / 0s  Finalizing assignment ds2 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  33%...  Checking ds3 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [===>-------]  33% / 0s  Finalizing assignment ds3 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  50%...  Checking ds4 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=====>-----]  50% / 1s  Finalizing assignment ds4 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  67%...  Checking ds5 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [======>----]  67% / 1s  Finalizing assignment ds5 (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) []  83%...  Assigned expr. (roc_data <- rocGLMFrame("D$valid", "pinv", "pooled_scores")) [=========] 100% / 1s
#> [2024-03-22 18:59:20] Server: Calculating probit regression to obtain ROC-GLM
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2024-03-22 18:59:21] Deviance of iter1=22.1651
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2024-03-22 18:59:22] Deviance of iter2=14.4388
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2024-03-22 18:59:22] Deviance of iter3=14.4797
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2024-03-22 18:59:23] Deviance of iter4=14.4896
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2024-03-22 18:59:24] Deviance of iter5=14.4897
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]   0% / 0s  Getting aggregate ds1 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [--]  17% / 0s  Getting aggregate ds2 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  33% / 0s  Getting aggregate ds3 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  50% / 1s  Getting aggregate ds4 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Checking ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [>-]  67% / 1s  Getting aggregate ds5 (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) []...  Aggregated (calculateDistrGLMParts(formula = y ~ x, data = "roc_data", w = "w", ) [====] 100% / 1s
#> [2024-03-22 18:59:25] Deviance of iter6=14.4897
#> [2024-03-22 18:59:25] Host: Finished calculating ROC-GLM
#> [2024-03-22 18:59:25] Host: Cleaning data on server
#> [2024-03-22 18:59:27] Host: Calculating AUC and CI
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (meanDS(D$valid)) [-------------------------------------------------------]   0% / 0s  Getting aggregate ds1 (meanDS(D$valid)) [=======>--------------------------------------]  17% / 0s  Checking ds2 (meanDS(D$valid)) [========>----------------------------------------------]  17% / 0s  Getting aggregate ds2 (meanDS(D$valid)) [==============>-------------------------------]  33% / 0s  Checking ds3 (meanDS(D$valid)) [=================>-------------------------------------]  33% / 0s  Getting aggregate ds3 (meanDS(D$valid)) [======================>-----------------------]  50% / 1s  Checking ds4 (meanDS(D$valid)) [===========================>---------------------------]  50% / 1s  Getting aggregate ds4 (meanDS(D$valid)) [==============================>---------------]  67% / 1s  Checking ds5 (meanDS(D$valid)) [====================================>------------------]  67% / 1s  Getting aggregate ds5 (meanDS(D$valid)) [=====================================>--------]  83% / 1s  Aggregated (meanDS(D$valid)) [=========================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [------------]   0% / 0s  Getting aggregate ds1 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [---]  17% / 0s  Checking ds2 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>----------]  17% / 0s  Getting aggregate ds2 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [>--]  33% / 0s  Checking ds3 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [===>--------]  33% / 0s  Getting aggregate ds3 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>-]  50% / 1s  Checking ds4 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [=====>------]  50% / 1s  Getting aggregate ds4 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>-]  67% / 1s  Checking ds5 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [=======>----]  67% / 1s  Getting aggregate ds5 (getNegativeScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [------------]   0% / 0s  Getting aggregate ds1 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [---]  17% / 0s  Checking ds2 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>----------]  17% / 0s  Getting aggregate ds2 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [>--]  33% / 0s  Checking ds3 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [===>--------]  33% / 0s  Getting aggregate ds3 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>-]  50% / 0s  Checking ds4 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [=====>------]  50% / 1s  Getting aggregate ds4 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>-]  67% / 1s  Checking ds5 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [=======>----]  67% / 1s  Getting aggregate ds5 (getPositiveScoresVar("D$valid", "pinv", return_sum = TRUE)) [=>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [------------------------]   0% / 0s  Getting aggregate ds1 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [=>-------------]  17% / 0s  Checking ds2 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [===>--------------------]  17% / 0s  Getting aggregate ds2 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [====>----------]  33% / 0s  Checking ds3 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [=======>----------------]  33% / 0s  Getting aggregate ds3 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [=======>-------]  50% / 0s  Checking ds4 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [===========>------------]  50% / 1s  Getting aggregate ds4 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [=========>-----]  67% / 1s  Checking ds5 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [===============>--------]  67% / 1s  Getting aggregate ds5 (getNegativeScoresVar("D$valid", "pinv", m = 1)) [===========>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [------------------------]   0% / 0s  Getting aggregate ds1 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [=>-------------]  17% / 0s  Checking ds2 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [===>--------------------]  17% / 0s  Getting aggregate ds2 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [====>----------]  33% / 0s  Checking ds3 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [=======>----------------]  33% / 0s  Getting aggregate ds3 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [=======>-------]  50% / 0s  Checking ds4 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [===========>------------]  50% / 1s  Getting aggregate ds4 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [=========>-----]  67% / 1s  Checking ds5 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [===============>--------]  67% / 1s  Getting aggregate ds5 (getPositiveScoresVar("D$valid", "pinv", m = 1)) [===========>---]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [------------]   0% / 0s  Getting aggregate ds1 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [---]  17% / 0s  Checking ds2 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>----------]  17% / 0s  Getting aggregate ds2 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [>--]  33% / 0s  Checking ds3 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [===>--------]  33% / 0s  Getting aggregate ds3 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  50% / 0s  Checking ds4 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=====>------]  50% / 1s  Getting aggregate ds4 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  67% / 1s  Checking ds5 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=======>----]  67% / 1s  Getting aggregate ds5 (getNegativeScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Checking ds1 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [------------]   0% / 0s  Getting aggregate ds1 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [---]  17% / 0s  Checking ds2 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>----------]  17% / 0s  Getting aggregate ds2 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [>--]  33% / 0s  Checking ds3 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [===>--------]  33% / 0s  Getting aggregate ds3 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  50% / 0s  Checking ds4 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=====>------]  50% / 1s  Getting aggregate ds4 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  67% / 1s  Checking ds5 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=======>----]  67% / 1s  Getting aggregate ds5 (getPositiveScores("D$valid", "pinv", 5, 0.01, "l2s", TRUE)) [=>-]  83% / 1s  Aggregated (...) [=====================================================================] 100% / 1s
#> [2024-03-22 18:59:33] Finished!

roc_glm
#> 
#> ROC-GLM after Pepe:
#> 
#>  Binormal form: pnorm(0.79 + 1.16*qnorm(t))
#> 
#>  AUC and 0.95 CI: [0.61----0.7----0.77]
roc_glm$auc
#> [1] 0.697301
roc_glm$ci
#> [1] 0.6145837 0.7689399

gg_distr_roc = plot(roc_glm)
gg_distr_roc
```

![](figures/unnamed-chunk-9-1.png)<!-- -->

## Cross check on pooled test data

#### Comparison of AUC values and CI on pooled data

```r
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
probs = ranger:::predict.ranger(mod, data = dat_test)$survival[, tpoint]

# Calculate empirical AUC and compare with distributed ROC-GLM
auc = pROC::auc(dat_test$valid, 1 - probs)
#> Setting levels: control = 0, case = 1
#> Setting direction: controls < cases

source(here::here("R/helper.R"))
ci_emp = logitToAUC(pepeCI(toLogit(auc), 0.05, deLongVar(1 - probs, dat_test$valid)))

knitr::kable(data.frame(
  lower = c(ci_emp[1], roc_glm$ci[1]),
  auc   = c(auc, roc_glm$auc),
  upper = c(ci_emp[2], roc_glm$ci[2]),
  method = c("Pooled empirical", "Distribued ROC-GLM")))
```

|     lower |       auc |     upper | method             |
|----------:|----------:|----------:|:-------------------|
| 0\.5984631 | 0\.6793935 | 0\.7508043 | Pooled empirical   |
| 0\.6145837 | 0\.6973010 | 0\.7689399 | Distribued ROC-GLM |

#### ROC curve on pooled data vs. distributed ROC-GLM, Figure 8 (left), Section 6.4

```r
# Calculate TPR and FPR values and add to distributed ROC-GLM plot
plt_emp_roc_data = simpleROC(dat_test$valid, 1 - probs)

gg_roc_pooled = plot(roc_glm) +
  geom_line(data = plt_emp_roc_data, aes(x = FPR, y = TPR), color = "red")
gg_roc_pooled
```

![](figures/unnamed-chunk-12-1.png)<!-- -->

#### ROC curve on pooled data vs. distributed ROC-GLM, Figure 8 (right), Section 6.4

```r
# Calculate pooled brier score and calibration curve
brier_pooled = mean((dat_test$valid - (1 - probs))^2)
c(brier_pooled = brier_pooled, brier_distr = brier)
#> brier_pooled  brier_distr 
#>    0.1843399    0.1843399

cc_pooled = calibrationCurve("dat_test$valid", "1 - probs", nbins = 10)

# Visualize distributed calibration curve vs. pooled one:
gg_cal_pooled = plotCalibrationCurve(cc, size = 1.5, individuals = FALSE) +
    geom_line(data = cc_pooled, aes(x = prob, y = truth), color = "red")
gg_cal_pooled
#> Warning: Removed 2 rows containing missing values (geom_point).
#> Warning: Removed 2 row(s) containing missing values (geom_path).
#> Warning: Removed 3 row(s) containing missing values (geom_path).
```

![](figures/unnamed-chunk-13-1.png)<!-- -->

#### Table of number of observations per bin, Table 2, Appendix A.3

```r
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
|-------:|--------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|--------:|
|      1 |       6 |        13 |         9 |         4 |         3 |         7 |         7 |         1 |         0 |       0 |
|      2 |      10 |        11 |         6 |         2 |         4 |         5 |         5 |         0 |         0 |       0 |
|      3 |      14 |         9 |        13 |         3 |         4 |         6 |         4 |         1 |         0 |       0 |
|      4 |      12 |        11 |         5 |         1 |         8 |         2 |         7 |         0 |         0 |       0 |
|      5 |      11 |        13 |        11 |         2 |         4 |         4 |         5 |         1 |         0 |       0 |
|     15 |      53 |        57 |        44 |        12 |        23 |        24 |        28 |         3 |         0 |       0 |

```r
# Summary of the results used in the paper:
tex_results = rbind(
  data.frame(command = "\\cidistlower", value = round(roc_glm$ci[1], 4)),
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
  data.frame(command = "\\privparOne", value = epsilon),
  data.frame(command = "\\privparTwo", value = delta),
  data.frame(command = "\\ltwosensUC", value = round(l2s, 4)),
  data.frame(command = "\\AUCdiffusecase", value = round(abs(auc - roc_glm$auc), 4)),
  data.frame(command = "\\CIdiffusecase", value = round(sum(abs(ci_emp - roc_glm$ci)), 4))
)
writeLines(paste0("\\newcommand{", tex_results[[1]], "}{", tex_results[[2]], "}"),
  here::here("tables/tab-results.tex"))
```

## Log out from DataSHIELD servers

```r
datashield.logout(conn)
#>    [-------------------------------------------------------------------------------------]   0% / 0s  Logout ds1 [===========>---------------------------------------------------------------]  17% / 0s  Logout ds2 [========================>--------------------------------------------------]  33% / 0s  Logout ds3 [=====================================>-------------------------------------]  50% / 0s  Logout ds4 [=================================================>-------------------------]  67% / 1s  Logout ds5 [=============================================================>-------------]  83% / 1s  Logged out from all servers [==========================================================] 100% / 1s
```

## Session Info

```r
sessionInfo()
#> R version 4.2.2 Patched (2022-11-10 r83330)
#> Platform: x86_64-pc-linux-gnu (64-bit)
#> Running under: Debian GNU/Linux 12 (bookworm)
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.21.so
#> 
#> locale:
#>  [1] LC_CTYPE=de_DE.UTF-8       LC_NUMERIC=C              
#>  [3] LC_TIME=de_DE.UTF-8        LC_COLLATE=de_DE.UTF-8    
#>  [5] LC_MONETARY=de_DE.UTF-8    LC_MESSAGES=de_DE.UTF-8   
#>  [7] LC_PAPER=de_DE.UTF-8       LC_NAME=C                 
#>  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
#> [11] LC_MEASUREMENT=de_DE.UTF-8 LC_IDENTIFICATION=C       
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#>  [1] dsROCGLM_1.0.0      dsCalibration_0.0.1 dsPredictBase_0.0.1
#>  [4] dsBaseClient_6.3.0  DSOpal_1.4.0        DSI_1.5.0          
#>  [7] R6_2.5.1            progress_1.2.2      ggsci_2.9          
#> [10] ggplot2_3.3.5       opalr_3.4.0         httr_1.4.5         
#> 
#> loaded via a namespace (and not attached):
#>  [1] jsonlite_1.7.3    splines_4.2.2     here_0.1          assertthat_0.2.1 
#>  [5] highr_0.10        yaml_2.3.7        remotes_2.5.0     Rttf2pt1_1.3.12  
#>  [9] pillar_1.9.0      backports_1.4.1   lattice_0.20-45   glue_1.6.2       
#> [13] pROC_1.18.0       extrafontdb_1.0   digest_0.6.31     checkmate_2.0.0  
#> [17] colorspace_2.1-0  htmltools_0.5.4   Matrix_1.5-3      plyr_1.8.8       
#> [21] pkgconfig_2.0.3   labelled_2.12.0   haven_2.5.1       sysfonts_0.8.1   
#> [25] scales_1.2.1      ranger_0.16.0     tzdb_0.3.0        tibble_3.2.1     
#> [29] generics_0.1.3    farver_2.1.1      ellipsis_0.3.2    TH.data_1.1-1    
#> [33] withr_2.5.0       cli_3.6.0         survival_3.5-3    magrittr_2.0.3   
#> [37] crayon_1.5.2      mime_0.12         evaluate_0.20     fansi_1.0.4      
#> [41] MASS_7.3-58.2     forcats_1.0.0     textshaping_0.3.6 tools_4.2.2      
#> [45] data.table_1.14.8 prettyunits_1.1.1 hms_1.1.2         lifecycle_1.0.3  
#> [49] stringr_1.5.0     munsell_0.5.0     compiler_4.2.2    systemfonts_1.0.4
#> [53] rlang_1.1.2       grid_4.2.2        labeling_0.4.2    rmarkdown_2.11   
#> [57] gtable_0.3.1      DBI_1.1.3         curl_5.0.0        markdown_1.5     
#> [61] knitr_1.36        dplyr_1.0.7       fastmap_1.1.1     extrafont_0.17   
#> [65] utf8_1.2.3        rprojroot_2.0.3   ragg_1.2.5        readr_2.1.4      
#> [69] stringi_1.7.12    Rcpp_1.0.10       vctrs_0.6.4       tidyselect_1.2.0 
#> [73] xfun_0.41
```