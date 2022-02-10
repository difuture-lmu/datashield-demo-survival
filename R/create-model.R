dat_train = read.csv(here::here("data/data-train.csv"), stringsAsFactors = TRUE)

# ### Example: Personalised Medicine Using Partitioned and Aggregated Cox-Models
# ### A combination of <DOI:10.1177/0962280217693034> and <arXiv:1701.02110>
# ### based on infrastructure in the mlt R add-on package described in
# ### https://cran.r-project.org/web/packages/mlt.docreg/vignettes/mlt.pdf
#
# library(trtf)
# library(survival)
#
# ### German Breast Cancer Study Group 2 data set
# ### set-up Cox model with overall treatment effect in hormonal therapy
# yvar = numeric_var("y", support = c(100, 2000), bounds = c(0, Inf))
# By = Bernstein_basis(yvar, order = 5, ui = "incre")
# dat_train$y = with(dat_train, Surv(time, cens))
#
# m = ctm(response = By, shifting = ~ horTh, todistr = "MinExt", data = dat_train)
#
# ### estimate Cox models
# ctrl = ctree_control(minsplit = 20, minbucket = 10, mincriterion = 0, testtype = "Bonferroni")
#
# set.seed(1618)
# mod = traforest(m, formula = y ~ horTh | age + tsize + tgrade + pnodes + progrec + estrec,
#   control = ctrl, ntree = 100, mtry = 4, trace = TRUE, data = dat_train)

set.seed(1618)
mod = ranger::ranger(cens ~ horTh + age + tsize + tgrade + pnodes + progrec + estrec, data = dat_train)

object.size(mod) / 1024^2

save(mod, file = here::here("data/mod.Rda"))

## Just for testing:
if (FALSE) {
  dat_test = read.csv(here::here("data/data-test.csv"), stringsAsFactors = TRUE)

  #pred2000 = diag(do.call(rbind, predict(mod, newdata = dat_test, mnewdata = dat_test, type = "survivor", q = 2000)))
  #pred100 = diag(do.call(rbind, predict(mod, newdata = dat_test, mnewdata = dat_test, type = "survivor", q = 100)))

  #probs = 1 - pred2000 / pred100

  probs = predict(mod, data = dat_test)$predictions
  (auc = pROC::auc(dat_test$cens, probs))
}
rm(list = ls())
