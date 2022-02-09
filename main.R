if (FALSE) {
  remotes::install_github("difuture-lmu/ds.predict.base")
  remotes::install_github("difuture-lmu/ds.calibration")
  remotes::install_github("difuture-lmu/ds.roc.glm")

  source(here::here("R/generate-data.R"))
  source(here::here("R/create-model.R"))
}

## Prepare DataSHIELD test server:
source(here::here("R/install-ds-packages.R"))
source(here::here("R/upload-data.R"))

library(DSI)
library(DSOpal)
library(dsBaseClient)

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

connections = datashield.login(logins = builder$build(), assign = TRUE)

datashield.symbols(connections)
ds.dim("D")
load(here::here("data/mod.Rda"))
summary(mod)

# Takes 12 Min for ranger with 500 trees:
ds.predict.base::pushObject(connections, obj = mod)
datashield.symbols(connections)

#pred_fun = "diag(do.call(rbind, predict(mod, newdata = D, mnewdata = D, type = 'survivor', q = 2000)))"
pred_fun = "ranger:::predict.ranger(mod, data = D)$predictions"

ds.predict.base::predictModel(connections, mod, "probs", predict_fun = pred_fun)
datashield.symbols(connections)

ds.calibration::dsBrierScore(connections, "D$cens", "probs")
cc = ds.calibration::dsCalibrationCurve(connections, "D$cens", "probs", nbins = 10)
ds.calibration::plotCalibrationCurve(cc, size = 1.5)

roc_glm    = ds.roc.glm::dsROCGLM(connections, "D$cens", "probs")

plot(roc_glm) +
  ggplot2::theme_minimal()



## Check on pooled data:
if (FALSE) {
  library(ggplot2)

  simpleROC = function(labels, scores) {
    labels = labels[order(scores, decreasing = TRUE)]
    data.frame(
      TPR = cumsum(labels) / sum(labels),
      FPR = cumsum(! labels) / sum(! labels), labels)
  }
  dat_test = read.csv(here::here("data/data-test.csv"), stringsAsFactors = TRUE)
  probs = predict(mod, data = dat_test)$predictions
  (auc = pROC::auc(dat_test$cens, probs))

  plt_emp_roc_data = simpleROC(dat_test$cens, probs)
  plot(roc_glm) +
    geom_line(data = plt_emp_roc_data, aes(x = FPR, y = TPR, color = "Empirical"))

  brier_pooled = mean((dat_test$cens - probs)^2)
  cc_pooled = ds.calibration::calibrationCurve("dat_test$cens", "probs", nbins = 10)

  ds.calibration::plotCalibrationCurve(cc, size = 1.5, individuals = FALSE) +
    geom_line(data = cc_pooled, aes(x = prob, y = truth), color = "red")
}



datashield.logout(connections)
