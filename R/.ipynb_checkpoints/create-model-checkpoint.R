dat_train = read.csv(here::here("data/data-train.csv"), stringsAsFactors = TRUE)

set.seed(1618)
mod = ranger::ranger(
  survival::Surv(time, cens) ~ horTh + age + tsize + tgrade + pnodes + progrec + estrec,
  data = dat_train,
  num.trees = 20L)

save(mod, file = here::here("data/mod.Rda"))

# dat_train <- titanic::titanic_train
# mod <- glm(Survived ~ Sex + Embarked, data=dat_train, family = binomial)
# # predict(mod, newdata = dat_test, type = "response")
# save(mod, file = here::here("data/mod.Rda"))



## Just for testing:
if (FALSE) {
  library(ggplot2)

  dat_test = read.csv(here::here("data/data-test.csv"), stringsAsFactors = TRUE)

  pps   = predict(mod, data = dat_test)#$survival

  t0 = 2 * 365
  idx_t = rep(which(pps$unique.death.times >= t0)[1], nrow(dat_test))

  p = numeric()
  for (i in seq_along(idx_t)) {
    p[i] = pps$survival[i, idx_t[i]]
  }
  (auc = pROC::auc(dat_test$valid, p))

  cc_pooled = dsCalibration::calibrationCurve("dat_test$valid", "p", nbins = 10)
  ggplot(data = cc_pooled, aes(x = 1 - prob, y = truth)) +
    geom_line() +
    geom_abline(slope = 1) +
    xlim(0, 1) +
    ylim(0, 1)


  source(here::here("R/generate-data.R"))
  source(here::here("R/create-model.R"))
  load(here::here("data", "mod.Rda"))
  l2ss = list()
  for (i in seq_len(5L)) {
    tmp = read.csv(here::here("data", paste0("SRV", i, ".csv")))
    tmp$id = NULL
    ptmp = ranger:::predict.ranger(mod, data = tmp)$survival[, 127]
    l2s  = dsROCGLM::l2sens(tmp, ptmp, nbreaks = 91)
    l2ss[[i]] = data.frame(l2s = l2s$l2sens, l1n = l2s$l1n, n = nrow(tmp), p = ncol(tmp))
  }
  df_l2s = do.call(rbind, l2ss)
  df_l2s
}
rm(list = ls())





