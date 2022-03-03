## SETUP
## ---------------------------------------------------------------- #

FTRAIN  = 0.6
NSERVER = 5L

# install.packages("TH.data")
dat = TH.data::GBSG2


# 3 Years for validation. Sampling test data must have a time >= t0.
T0VAL   = 2 * 365

# Add column for validation:
dat$valid = ifelse((dat$time <= T0VAL) & (dat$cens == 1), 1, 0)

# Sample indices:
IDX_TO  = which(dat$time > T0VAL)
IDX_ALL = seq_len(nrow(dat))
IDX_TO  = IDX_ALL

set.seed(314)
IDX_TEST   = sample(x = IDX_TO, size = (1 - FTRAIN) * nrow(dat))
IDX_TRAIN  = setdiff(IDX_ALL, IDX_TEST)

set.seed(316)
IDX_SERVER = sample(x = seq_len(NSERVER), size = length(IDX_TEST), replace = TRUE)



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
