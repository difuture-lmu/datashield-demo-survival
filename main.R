source(here::here("R/generate-data.R"))
source(here::here("R/create-model.R"))
source(here::here("R/upload-data.R"))
source(here::here("R/install-ds-packages.R"))

remotes::install_github("difuture-lmu/ds.predict.base")
remotes::install_github("difuture-lmu/ds.calibration")
remotes::install_github("difuture-lmu/ds.roc.glm")

library(DSI)
library(DSOpal)
library(dsBaseClient)

library(ds.predict.base)
library(ds.calibration)
library(ds.roc.glm)

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
datashield.symbols(conn)
ds.summary("D")

## Load the pre-calculated logistic regression:
load(here::here("data/mod.Rda"))

## Push the model to the servers:
pushObject(conn, obj = mod)
datashield.symbols(conn)

## Predict the model on the data sets located at the servers:
predictModel(conn, mod, "probs", predict_fun = "ranger:::predict.ranger(mod, data = D)$predictions")
datashield.symbols(conn)

# Get the l2 sensitivity
(l2s = dsL2Sens(conn, "D", "probs"))

#l2sens("dat_test", "probs", cols = cols)

# Calculate ROC-GLM
roc_glm2 = dsROCGLM(conn, "D$cens", "probs", epsilon = 0.2, delta = 0.2, dat_name = "D",
  seed = 123, seed_object = "D")

gg_distr_roc = plot(roc_glm)
gg_distr_roc

roc_glm$auc
roc_glm1$auc
roc_glm2$auc

roc_glm$parameter
roc_glm1$parameter
roc_glm2$parameter


datashield.logout(conn)

