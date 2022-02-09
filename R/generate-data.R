## SETUP
## ---------------------------------------------------------------- #

FTRAIN  = 0.6
NSERVER = 5L

# install.packages("TH.data")
dat = TH.data::GBSG2

IDX_ALL = seq_len(nrow(dat))

set.seed(314)
IDX_TRAIN  = sample(x = IDX_ALL, size = FTRAIN * nrow(dat))
IDX_TEST   = setdiff(IDX_ALL, IDX_TRAIN)

set.seed(316)
IDX_SERVER = sample(x = seq_len(NSERVER), size = length(IDX_TEST), replace = TRUE)

## GENERATE DICTIONARY
## ---------------------------------------------------------------- #

#ll_vars = list()
#ll_cats = list()
#for (i in seq_along(dat)) {
#  label = names(dat)[i]
#  if (is.integer(dat[[i]])) {
#    ll_vars = c(ll_vars, list(tibble::tribble(
#      ~name, ~valueType, ~`label:en`,
#      label, "integer", label
#    )))
#  }
#  if (is.double(dat[[i]])) {
#    ll_vars = c(ll_vars, list(tibble::tribble(
#      ~name, ~valueType, ~`label:en`,
#      label, "decimal", label
#    )))
#
#  }
#  if (is.factor(dat[[i]]) | is.character(dat[[i]])) {
#    ll_vars = c(ll_vars, list(tibble::tribble(
#      ~name, ~valueType, ~`label:en`,
#      label, "text", label
#    )))
#    tmp = as.factor(dat[[i]])
#    labels = levels(tmp)
#    ll_labs = list()
#    for (j in seq_along(labels)) {
#      ll_labs = c(ll_labs, list(tibble::tribble(
#        ~variable, ~name, ~missing, ~`label:en`,
#        label, labels[j], sum(is.na(tmp[tmp == labels[j]])), labels[j]
#      )))
#    }
#    ll_cats = c(ll_cats, list(do.call(rbind, ll_labs)))
#  }
#}
#variables = do.call(rbind, ll_vars)
#categories = do.call(rbind, ll_cats)
#
#d = opalr::dictionary.apply(dat, variables, categories)


## SPLIT DATA AND SAVE
## ---------------------------------------------------------------- #

dat_train = dat[IDX_TRAIN, ]
dat_test  = dat[setdiff(IDX_ALL, IDX_TRAIN), ]

write.csv(dat_train, here::here("data/data-train.csv"), row.names = FALSE)
write.csv(dat_test, here::here("data/data-test.csv"), row.names = FALSE)

dat_test$id = seq_len(nrow(dat_test))
for (i in seq_len(NSERVER)) {
  tmp = dat_test[IDX_SERVER == i, ]
  dname = paste0("SRV", i, ".csv")
  write.csv(tmp, file = here::here("data", dname), row.names = FALSE)
}
rm(list = ls())
