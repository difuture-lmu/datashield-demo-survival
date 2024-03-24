## SETUP
## ---------------------------------------------------------------- #

FTRAIN  = 0.6
NSERVER = 5L

# install.packages("TH.data")
dat = TH.data::GBSG2


# 2 Years for validation. Sampling test data must have a time >= t0.
T0VAL   = 2 * 365

# Add column for validation:
dat$valid = ifelse((dat$time <= T0VAL) & (dat$cens == 1), 1, 0)


# Sample indices:
IDX_ALL = seq_len(nrow(dat))
IDX_TO  = IDX_ALL

set.seed(1234)
IDX_TEST   = sample(x = IDX_TO, size = (1 - FTRAIN) * nrow(dat))
IDX_TRAIN  = setdiff(IDX_ALL, IDX_TEST)


dat_train = dat[IDX_TRAIN, ]
dat_test  = dat[setdiff(IDX_ALL, IDX_TRAIN), ]

### Note RR:
### Just consider data where censoring is 1, data where censoring is 0 AND T0VAL <=2*365 should be thrown out as they will bias the result
dat_test <- dat_test[!((dat_test$time <= T0VAL) & (dat_test$cens == 0)),]


write.csv(dat_train, here::here("data/data-train.csv"), row.names = FALSE)
write.csv(dat_test, here::here("data/data-test.csv"), row.names = FALSE)

# write NSERVER datasets
IDX_SERVER = sample(x = seq_len(NSERVER), size = nrow(dat_test), replace = TRUE)

dat_test$id = seq_len(nrow(dat_test))
for (i in seq_len(NSERVER)) {
  tmp = dat_test[IDX_SERVER == i, ]
  dname = paste0("SRV", i, ".csv")
  write.csv(na.omit(tmp), file = here::here("data", dname), row.names = FALSE)
  write.csv(tmp, file = here::here("data", dname), row.names = FALSE)
}
rm(list = ls())
