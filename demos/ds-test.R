## SETUP
## ===========================================================

remotes::install_github("difuture-lmu/ds.predict.base")
remotes::install_github("difuture-lmu/ds.calibration")
remotes::install_github("difuture-lmu/ds.roc.glm")

source(here::here("R/update-data.R"))
source(here::here("R/upload-data.R"))
source(here::here("R/create-log-reg.R"))
source(here::here("R/install-ds-packages.R"))
source(here::here("R/helper.R"))

library(DSI)
library(DSOpal)
library(dsBaseClient)

library(ds.predict.base)
library(ds.calibration)
library(ds.roc.glm)

builder = newDSLoginBuilder()

surl     = "https://opal-demo.obiba.org/"
username = "administrator"
password = "password"

datasets = c("KUM", "MRI", "UKA", "UKT")
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
datashield.symbols(conn)

## Load the pre-calculated logistic regression:
load(here::here("data/mod.Rda"))

## ds.predict.base
## ===========================================================


## Push the model to the servers:
pushObject(conn, obj = mod)
datashield.symbols(conn)

## Predict the model on the data sets located at the servers:
predictModel(conn, mod, "pred", predict_fun = "predict(mod, newdata = D, type = 'response')")
datashield.symbols(conn)

## ds.calibration
## ===========================================================

brier = dsBrierScore(conn, "D$binomial_1", "pred")
str(brier)
cc = dsCalibrationCurve(conn, "D$binomial_1", "pred")
str(cc)
plotCalibrationCurve(cc, size = 1.5)

m = numeric(10L)
for(i in 1:10) {
  a = do.call(rbind, lapply(cc$individuals, function(ind) data.frame(n = ind$n[i], missing = ind$truth[i])))
  m[i] = 1 - sum(a$n[is.na(a$missing)] / sum(a$n))
}
## ds.roc.glm
## ===========================================================

roc_glm = dsROCGLM(conn, "D$binomial_1", "pred", lag = 1, ntimes = 1)
plot(roc_glm) + ggplot2::theme_minimal()

datashield.logout(conn)
