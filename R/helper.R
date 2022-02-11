# ============================================================================ #
#                              DATA GENERATION
# ============================================================================ #

#' Simulate score and truth values
#'
#' The simulation randomly generates scores and true values of size n which is
#' randomly drawn between 100 and 2500. The generation is based on randomly
#' flipping values to get AUC values on the full range between 0.5 and 1 when
#' using the simulated data.
#'
#' @param i (`integer(1)`) The repetition (> 0) or basically an integer number to
#'   shift the seed.
#' @param seed (`integer(1)`) The base seed (> 0) used for the simulation. Note that
#'   the actual seed used for simulation is `seed + i`.
#' @return (`data.frame()`) Data frame containing columns `score` and `truth`. The
#'   score represents the predicted scores (e.g. from a statistical or prediction model).
generateROCData = function(i, seed) {
  checkmate::assertCount(i, len = 1L)
  checkmate::assertCount(seed, len = 1L)

  # Used seed:
  seed_k = seed + i

  # Simulate data:

  set.seed(seed_k)
  nsim = sample(x = seq(from = 100L, to = 2500L), size = 1L)
  npos = nsim

  set.seed(seed_k)
  scores = runif(n = nsim, min = 0, max = 1)
  truth = ifelse(scores > 0.5, 1, 0)

  # Sometimes, the simulation produces a too unbalanced data situation.
  # We catch this by checking if the number of positives divided by the
  # number of negatives is in [0.1, 0.9]. But, when a simulation falls
  # outside of this range, we have to increase the seed by one to not
  # get the same values again.
  seed_add_gamma = 0L
  while ((npos / nsim > 0.9) || (npos / nsim < 0.1)) {

    set.seed(seed_k + seed_add_gamma)
    shuffle = runif(n = 1L, min = 0, max = 1)
    nshuffle = trunc(nsim * shuffle)

    set.seed(seed_k + seed_add_gamma)
    idx_shuffle = sample(x = seq_len(nsim), size = nshuffle)

    set.seed(seed_k + seed_add_gamma)
    truth[idx_shuffle] = sample(x = c(0,1), size = nshuffle, replace = TRUE)
    npos = sum(truth)

    seed_add_gamma = seed_add_gamma + 1L
  }
  return(data.frame(score = scores, truth = truth))
}

#' Generate ROC data (tpr and fpr) from scores and labels
#'
#' @param score (`numeric()`) Scores of the respective label.
#' @param truth (`integer()`) True labels coded a 0 and 1.
#' @return (`data.frame()`) Data frame containing columns `tpr` and `fpr`.
rocData = function(score, truth) {

  checkmate::assertNumeric(x = score, any.missing = FALSE, len = length(truth))
  checkmate::assertIntegerish(x = truth, lower = 0, upper = 1, any.missing = FALSE)

  label = truth[order(score, decreasing = TRUE)]

  n_pos = sum(label == 1)
  n_neg = sum(label == 0)

  tpr = c(0, cumsum(label == 1) / n_pos)
  fpr = c(0, cumsum(label == 0) / n_neg)

  return(list(tpr = tpr, fpr = fpr))
}


# ============================================================================ #
#                                  AUC + CI
# ============================================================================ #

#' Calculate empirical AUC
#'
#' @param data (`data.frame()`) Data frame containing columns `score` and `truth`.
#' @param ind (`integer()`) Indices for subsetting the data.
#' @param unlogit (`logical(1)`) If `TRUE` the AUC is given as it is on the [0,1]
#'   scale. If `FALSE`, the AUC is transformed with log(AUC / (1 - AUC)).
#' @return (`numeric(1)`) The value of AUC either with or without logit transformation.
logitAUC = function(data, ind = NULL, unlogit = FALSE) {
  checkmate::assertDataFrame(x = data)
  nuisance = lapply(colnames(data), function(nm)
    checkmate::assertChoice(x = nm, choices = c("score", "truth")))
  checkmate::assertIntegerish(ind, lower = 1, null.ok = TRUE)

  if (is.null(ind[1])) ind = seq_len(nrow(data))
  scores = data$score[ind]
  truth = data$truth[ind]
  emp_auc = pROC::auc(truth, probabilities)
  #emp_auc = mlr::measureAUC(probabilities = scores, truth = truth, negative = 0, positive = 1)
  if (unlogit) return(emp_auc)
  return(toLogit(emp_auc))
}

#' Transform a logit value to original scale
#'
#' @param x (`numeric()`) The logit value x.
#' @return (`numeric()`) The transformed value (1 + exp(-x))^(-1).
logitToAUC = function(x) 1 / (1 + exp(-x))

#' Logit transformation
#'
#' @param x (`numeric()`) The value x.
#' @return (`numeric()`) The transformed value log(x / (1 - x)).
toLogit = function(x) log(x / (1 - x))

#' Calculate the variance of the logit AUC based on DeLong
#'
#' @param scores (`numeric()`) Scores of the respective label.
#' @param truth (`integer()`) True labels coded a 0 and 1.
#' @return (`numeric(1)`) Variance of the AUC based on DeLong.
deLongVar = function(scores, truth) {
  checkmate::assertNumeric(x = scores, any.missing = FALSE, len = length(truth))
  checkmate::assertIntegerish(x = truth, lower = 0, upper = 1, any.missing = FALSE)

  # survivor functions for diseased and non diseased:
  s_d = function(x) 1 - ecdf(scores[truth == 1])(x)
  s_nond = function(x) 1 - ecdf(scores[truth == 0])(x)

  # Variance of empirical AUC after DeLong:
  var_auc = var(s_d(scores[truth == 0])) / sum(truth == 0) +
    var(s_nond(scores[truth == 1])) / sum(truth == 1)

  return(var_auc)
}

#' Calculate the confidence interval (CI) after Pepe
#'
#' @param logit_auc (`numeric(1)`) The AUC on the logit scale.
#' @param alpha (`numeric(1)`) The significance level.
#' @param var_auc (`numeric(1)`) The variance of the logit AUC.
#' @return (`numeric(2)`) Lower and upper CI of the logit AUC.
pepeCI = function(logit_auc, alpha, var_auc) {
  checkmate::assertNumeric(x = logit_auc, len = 1L)
  checkmate::assertNumeric(x = alpha, len = 1L, lower = 0, upper = 1)
  checkmate::assertNumeric(x = var_auc, len = 1L, lower = 0)
  quant = qnorm(1 - alpha / 2) * sqrt(var_auc) /
    (logitToAUC(logit_auc) * (1 - logitToAUC(logit_auc)))
  return(logit_auc + c(-1, 1) * quant)
}

# ============================================================================ #
#                              PROBIT REGRESSION
# ============================================================================ #

#' Calculate Fisher scoring parameter updates
#'
#' The updates here are based on a transformation to use a simpler
#' updating rule in the case of the Probit regression. The used
#' form is (XWX)^{-1} * lambda where lambda contains the Probit
#' regression specific information used for the update.
#'
#' @param beta (`numeric()`) Current parameter vector.
#' @param X (`matrix()`) Data matrix.
#' @param lambda (`numeric()`) Vector of values containing the Probit information.
#' @param w (`numeric()`) Weights.
#' @return (`numeric()`) New parameter value.
updateParam = function(beta, X, lambda, w = NULL) {
  checkmate::assertNumeric(x = beta, len = ncol(X))
  checkmate::assertMatrix(x = X, mode = "numeric")
  checkmate::assertNumeric(x = lambda, len = nrow(X))
  checkmate::assertNumeric(x = w, len = nrow(X), null.ok = TRUE)

  W = diag(as.vector(lambda * (X %*% beta + lambda)))
  if (! is.null(w[1])) {
    X = diag(sqrt(w)) %*% X
    lambda = diag(sqrt(w)) %*% lambda
  }
  return(beta + solve(t(X) %*% W %*% X) %*% t(X) %*% lambda)
}

#' Conduct Probit regression
#'
#' Note that the values for this custom Probit regression are the
#' same as when calling the `glm` function.
#'
#' @param y (`numeric()`) Response vector with 0-1 entries.
#' @param X (`matrix()`) Data matrix.
#' @param w (`numeric()`) Weights.
#' @param beta_start (`numeric()`) Initial parameter value (default = 0).
#' @param stop_tol (`numeric(1)`) Value used to stop the Fisher scoring (default = 1e-8).
#' @param iter_max (`integer(1)`) Maximal number of Fisher scoring iterations.
#' @param trace (`logical(1)`) Flag to indicate whether to print fitting information of not.
#' @return (`numeric()`) Parameter estimates.
probitRegr = function(y, X, w = NULL, beta_start = 0, stop_tol = 1e-8, iter_max = 25L, trace = FALSE) {
  checkmate::assertIntegerish(x = y, lower = 0, upper = 1, any.missing = FALSE, len = nrow(X))
  checkmate::assertMatrix(x = X, mode = "numeric")
  checkmate::assertNumeric(x = w, len = length(y), null.ok = TRUE)
  checkmate::assertNumeric(x = beta_start, len = ncol(X))
  checkmate::assertNumeric(x = stop_tol, len = 1L, lower = 0)
  checkmate::assertCount(x = iter_max)
  checkmate::assertLogical(x = trace, len = 1L)

  if (length(beta_start) == 1) beta_start = rep(beta_start, ncol(X))
  if (is.vector(beta_start)) beta_start = cbind(beta_start)

  beta = beta_start
  iter = 0L

  deviance = numeric(iter_max)
  deviance[1] = probitDeviance(y, X, beta)

  if (trace) cat("\n")

  while (iter <= iter_max) {

    beta_start = beta
    beta = updateParam(beta_start, X = X, lambda = calculateLambda(y = y, X = X, beta = beta_start), w = w)

    iter = iter + 1L
    deviance[iter + 1L] = probitDeviance(y, X, beta)

    if (trace) cat("Deviance of iter", iter, "=", round(deviance[iter + 1L], digits = 4L), "\n")

    if (probitDevianceStop(y = y, X = X, beta = beta, beta_old = beta_start) < stop_tol) {
      if (trace) { cat("\n"); break; }
    }
  }
  out = list(iter = iter, parameter = beta, deviance = deviance[seq_len(iter + 1L)])
  return(out)
}

#' Predict the estimated Probit regression on a regular grid between 0 and 1.
#'
#' @param mod (Object returned from `probitRegr`) Estimated Probit regression parameter.
#' @return (`numeric()`) Predicted values on the regular grid using the binormal form.
predictProbit = function(mod) {
  x = seq(0, 1, 0.01)
  y = pnorm(mod$parameter[1] + mod$parameter[2] * qnorm(x))

  return(list(x = x, y = y))
}

#' Calculate the stopping criteria of the Probit regression based on the deviance
#'
#' @param y (`numeric()`) Response vector with 0-1 entries.
#' @param X (`matrix()`) Data matrix.
#' @param beta (`numeric()`) New parameter value.
#' @param beta_old (`numeric()`) Old parameter value.
#' @return (`numeric(1)`) Deviance stop criteria.
probitDevianceStop = function(y, X, beta, beta_old) {
  checkmate::assertIntegerish(x = y, lower = 0, upper = 1, any.missing = FALSE, len = nrow(X))
  checkmate::assertMatrix(x = X, mode = "numeric")
  checkmate::assertNumeric(x = beta, len = ncol(X))
  checkmate::assertNumeric(x = beta_old, len = ncol(X))

  dev = -2 * log(probitLikelihood(y, X, beta))
  dev_old = -2 * log(probitLikelihood(y, X, beta_old))

  # from ?glm.control:
  out = abs(dev - dev_old) / (abs(dev) + 0.1)
  return(out)
}

#' Calculate likelihood for the Probit regression
#'
#' @param y (`numeric()`) Response vector with 0-1 entries.
#' @param X (`matrix()`) Data matrix.
#' @param beta (`numeric()`) Parameter value.
#' @param w (`numeric()`) Weights.
#' @return (`numeric(1)`) Log-likelihood.
probitLikelihood = function(y, X, beta, w = NULL) {
  checkmate::assertIntegerish(x = y, lower = 0, upper = 1, any.missing = FALSE, len = nrow(X))
  checkmate::assertMatrix(x = X, mode = "numeric")
  checkmate::assertNumeric(x = beta, len = ncol(X))
  checkmate::assertNumeric(x = w, len = length(y), null.ok = TRUE)

  eta = X %*% beta

  if (is.null(w)) {
    w = rep(1, times = nrow(X))
  }
  lh = pnorm(eta)^y * (1 - pnorm(eta))^(1 - y)
  return(prod(lh^w))
}

#' Calculate the deviance for the Probit regression
#'
#' @param y (`numeric()`) Response vector with 0-1 entries.
#' @param X (`matrix()`) Data matrix.
#' @param beta (`numeric()`) Parameter value.
#' @return (`numeric(1)`) Deviance.
probitDeviance = function(y, X, beta) {
  checkmate::assertIntegerish(x = y, lower = 0, upper = 1, any.missing = FALSE, len = nrow(X))
  checkmate::assertMatrix(x = X, mode = "numeric")
  checkmate::assertNumeric(x = beta, len = ncol(X))

  return(-2 * log(probitLikelihood(y, X, beta)))
}

#' Calculate the lambda for the Probit regression
#'
#' @param y (`numeric()`) Response vector with 0-1 entries.
#' @param X (`matrix()`) Data matrix.
#' @param beta (`numeric()`) Parameter value.
#' @return (`numeric()`) Vector of lambda values.
calculateLambda = function(y, X, beta) {
  checkmate::assertIntegerish(x = y, lower = 0, upper = 1, any.missing = FALSE, len = nrow(X))
  checkmate::assertMatrix(x = X, mode = "numeric")
  checkmate::assertNumeric(x = beta, len = ncol(X))

  eta = X %*% beta
  q = 2 * y - 1
  qeta = q * eta

  return((dnorm(qeta) * q) / (pnorm(qeta)))
}

# ============================================================================ #
#                                  ROC GLM
# ============================================================================ #

#' Calculate the U matrix for the ROC-GLM
#'
#' The U matrix is the response used for the Probit regression to
#' fit the ROG-GLM.
#'
#' @param tset (`numeric()`) Threshold values.
#' @param placement_values (`numeric()`) Placement values.
#' @return (`matrix()`) 0-1-matrix containing the response for the Probit regression.
calcU = function(tset, placement_values) {
  tset_sorted = sort(tset)
  out = vapply(X = tset, FUN.VALUE = integer(length(placement_values)),
    FUN = function(t) { ifelse(placement_values <= t, 1L, 0L) })
    return(out)
}

#' Create the data matrix for the Probit regression
#'
#' The ROC-GLM is basically a Probit regression on specific data. This
#' function creates this data frame.
#'
#' @param U (`matrix()`) 0-1-matrix of response values.
#' @param tset (`numeric()`) Threshold values.
#' @return (`data.frame()`) Data frame with columns `y` (response) `x` (covariate
#'   based on the binormal form), and `w` (weights).
dataRocGLM = function(U, tset) {
  roc_glm_data = data.frame(
    y = rep(c(0, 1), times = length(tset)),
    x = rep(qnorm(tset), each = 2L),
    w = as.vector(apply(U, 2, function(x) c(sum(x == 0), sum(x == 1)))))
  return(roc_glm_data)
}

#' Integrate over the binormal form to get AUC estimate
#'
#' @param mod (Object returned from `probitRegr`) Estimated Probit regression parameter.
#' @return (`numeric(1)`) Estimated AUC based on the ROC-GLM.
integrateBinormal = function(params) {
  temp = function(x) pnorm(params[1] + params[2] * qnorm(x))
  int = integrate(f = temp, lower = 0, upper = 1)
  return(int$value)
}

#' Calculate AUC based on the ROC-GLM
#'
#' @param data (`data.frame()`) Data frame containing columns `score` and `truth`.
#' @param ind (`integer()`) Indices for subsetting the data.
#' @param unlogit (`logical(1)`) If `TRUE` the AUC is given as it is on the [0,1]
#'   scale. If `FALSE`, the AUC is transformed with log(AUC / (1 - AUC)).
#' @return (`numeric(1)`) The value of AUC (based on the ROC-GLM) either with or
#'   without logit transformation.
rocGLMlogitAUC = function(data, ind = NULL, unlogit = FALSE) {
  if (is.null(ind[1])) ind = seq_len(nrow(data))

  scores = data$score[ind]
  truth = data$truth[ind]

  Fn_global = ecdf(scores[truth == 0])
  Sn_global = function(x) 1 - Fn_global(x)

  thresh_set = seq(0, 1, length.out = 30L)
  pv_global = Sn_global(scores[truth == 1])
  U_global = calcU(thresh_set, pv_global)

  roc_data_global = dataRocGLM(U = U_global, tset = thresh_set)
  roc_data_global = roc_data_global[is.finite(roc_data_global$x),]

  y_global = roc_data_global$y
  X_global = model.matrix(y ~ x, data = roc_data_global)
  w_global = roc_data_global$w

  my_roc_glm_global = tryCatch(
    expr = {probitRegr(y = y_global, X = X_global, w = w_global)},
    error = function(e) return("fail")
  )
  if (! is.character(my_roc_glm_global)) {
    auc = integrateBinormal(my_roc_glm_global$parameter)
    attr(auc, "params") = my_roc_glm_global$parameter
    if (unlogit) return(auc)
    return(log(auc / (1 - auc)))
  } else {
    return(NA)
  }
}

#
#
#logitToAUC = function(x) 1 / (1 + exp(-x))
#toLogit = function(x) log(x / (1 - x))
#
#deLongVar = function(scores, truth) {
#  # survivor functions for diseased and non diseased:
#  s_d = function(x) 1 - ecdf(scores[truth == 1])(x)
#  s_nond = function(x) 1 - ecdf(scores[truth == 0])(x)
#
#  # Variance of empirical auc after DeLong:
#  var_auc = var(s_d(scores[truth == 0])) / sum(truth == 0) + var(s_nond(scores[truth == 1])) / sum(truth == 1)
#
#  return(var_auc)
#}
#
#pepeCI = function(logit_auc, alpha, var_auc) {
#  logit_auc + c(-1, 1) * qnorm(1 - alpha / 2) * sqrt(var_auc) / (logitToAUC(logit_auc) * (1 - logitToAUC(logit_auc)))
#}
#
#sim_multi <- function(n, p = 10){
#  m <- rep(0, p)
#  cvr <- NULL
#
#  for(i in 1:p){
#    for(j in 1:p){
#      cvr <- c(cvr, 0.5^(abs(i-j)))
#    }
#  }
#
#  s <- matrix(data = cvr, nrow = p)
#  dat <- MASS::mvrnorm(n, mu = m, Sigma = s)
#
#  return(dat)
#}
#
#
#sim_1 <- function(m=1800, dat = simdat, beta = b, lambda = 0.002, gamma = 1.3) {
#  dat = rbind(dat)
#  n <- nrow(dat)
#
#  # Function arguments:
#  # n - No. of random variables to generate
#  simtime <- event(n, dat, beta, lambda, gamma) #simulate 1 event time per patient (Weibull)
#
#  df_int <- interval(n, m, simtime) #create multiple rows for each patient to become intervals
#
#  sim_tbl <- censor(df_int) %>% #generate censoring time-points of intervals
#    filter(delta != 9) %>% #delete intervals after event
#    filter(max(right)==right) #keep only the last interval
#
#  ungroup(sim_tbl)
#
#  sim_tbl$left <- with(sim_tbl, ifelse (delta == 0, left, left))
#  sim_tbl$right <- with(sim_tbl, ifelse (delta == 0, Inf, right))
#  df <- data.frame(round(select(sim_tbl, id, left, right, simtime)), dat)
#  return(df)
#}
#
#event <- function(n, dat, beta, lambda, gamma) {
#  # generate uniform random numbers
#  u <- runif(n) #default min=0, max=1
#  linpred = eta(dat, beta)
#  #linpred = scale(linpred)
#  t <- (-log(u) / (lambda * exp(linpred)))^(1 / gamma)
#  # compute event times from u
#  return(t)
#}
#
#eta <- function(dat, beta) {
#  # log incidence rate
#  return(dat%*%beta)
#}
#
#interval <- function(n, m, simtime, mu = 2) {
#
#  #create ids for patients
#  id <- seq.int(1, by = 1, length.out = n)
#
#  y <- rnbinom(n = m, size = 2, mu = mu) #modeling the image process (not intervals)
#  y <- ifelse(y == 0, 1, y)
#  y <- y[y != 1] - 1 #eliminate 0 or 1 images & decrease by 1 for #of intervals
#
#  n_int <- sample(y, n)
#
#  df_bas <- data.frame(id = id,
#                       simtime = simtime,
#                       n_int = n_int)
#
#  df <- df_bas[rep(seq_len(nrow(df_bas)), df_bas$n_int), 1:2]
#
#  return(df)
#}
#
#censor <- function(x) {
#  x$right <- runif(length(x[,1]), min = 0, max = 156)
#
#  x <- x[order(x$id, x$right),] %>%
#    as_tibble() %>%
#    group_by(id) %>%
#    mutate(
#      left = lag(right),
#      left = ifelse(is.na(left), 0, left),
#      delta = ifelse(simtime < left, 9, #mark intervals after event
#                     ifelse(simtime > right,
#                            0, 1)
#      )
#    )
#  return(x)
#}
#
#constructBetas = function(dat, ntreat = 3L) {
#
#  X = model.matrix(~ ., data = dat)[,-1]
#  featmeans = apply(X, 2, mean)
#
#  betas = list()
#  for (i in seq_len(ntreat)) {
#    #idx_nonzero = sample(seq_len(ncol(X)), 3)
#    #betas[[i]]  = rep(0, ncol(X))
#    #betas[[i]][idx_nonzero] = sample(c(0.25, 0.5, 0.75, 1), 3, TRUE)
#    #betas[[i]] = betas[[i]] / featmeans
#
#    betas[[i]] = rbeta(ncol(X), 1, 1) / featmeans
#    idx_zero = sample(c(TRUE, FALSE), ncol(X), TRUE, prob = c(0.5, 0.5))
#    betas[[i]][idx_zero] = 0
#  }
#  return(betas)
#}
#
#generateSuvrivalResponse = function(dat, betas, ...) {
#  X      = model.matrix(~ ., data = dat)[, -1]
#  n      = nrow(X)
#  ntreat = length(betas)
#
#  llidx = list()
#  for (i in seq_len(ntreat)) {
#    if (i == 1) {
#      llidx[[i]] = sample(seq_len(n), size = n / ntreat)
#    } else {
#      if (i == ntreat)
#        llidx[[i]] = setdiff(seq_len(n), unlist(llidx))
#      else
#        llidx[[i]] = sample(setdiff(seq_len(n), unlist(llidx)), size = n / ntreat)
#    }
#  }
#
#  int_dat = do.call(rbind, lapply(seq_len(ntreat), function(i) {
#    cbind(sim_1(dat = X[llidx[[i]], ], beta = betas[[i]], ...), trt = i - 1)
#  }))
#
#  return(int_dat[, c("left", "right", "simtime", "trt"), ])
#}
#
#generateSingleSuvrivalResponse = function(dat, beta, ...) {
#  X      = model.matrix(~ ., data = dat)[, -1]
#  n      = nrow(X)
#
#  int_dat = sim_1(dat = X, beta = beta, ...)
#
#  return(int_dat[, c("left", "right", "simtime"), ])
#}
#
#generateROCData = function(i, seed) {
#  seed_k = seed + i
#
#  # Simulate data:
#
#  set.seed(seed_k)
#  nsim = sample(x = seq(from = 100L, to = 2500L), size = 1L)
#  npos = nsim
#
#  set.seed(seed_k)
#  scores = runif(n = nsim, min = 0, max = 1)
#  truth = ifelse(scores > 0.5, 1, 0)
#
#  seed_add_gamma = 0L
#  while ((npos / nsim > 0.9) || (npos / nsim < 0.1)) {
#
#    set.seed(seed_k + seed_add_gamma)
#    shuffle = runif(n = 1L, min = 0, max = 1)
#    nshuffle = trunc(nsim * shuffle)
#
#    set.seed(seed_k + seed_add_gamma)
#    idx_shuffle = sample(x = seq_len(nsim), size = nshuffle)
#
#    set.seed(seed_k + seed_add_gamma)
#    truth[idx_shuffle] = sample(x = c(0,1), size = nshuffle, replace = TRUE)
#    npos = sum(truth)
#
#    seed_add_gamma = seed_add_gamma + 1L
#  }
#
#  return(data.frame(score = scores, truth = truth))
#}
#
#
#probitDevianceStop = function (y, X, beta, beta_old)
#{
#
##   browser()
#  dev = -2 * log(probitLikelihood(y, X, beta))
#  dev_old = -2 * log(probitLikelihood(y, X, beta_old))
#
#  # from ?glm.control:
#  out = abs(dev - dev_old) / (abs(dev) + 0.1)
#  return (out)
#}
#
#probitLikelihood = function (y, X, beta, w = NULL)
#{
#  eta = X %*% beta
#
#  if (is.null(w)) {
#    w = rep(1, times = nrow(X))
#  }
#  lh = pnorm(eta)^y * (1 - pnorm(eta))^(1 - y)
#  prod(lh^w)
#}
#probitDeviance = function (y, X, beta)
#{
#  -2 * log(probitLikelihood(y, X, beta))
#}
#
#
#calculateLambda = function (y, X, beta)
#{
#  eta = X %*% beta
#  q = 2 * y - 1
#  qeta = q * eta
#
#  return ((dnorm(qeta) * q) / (pnorm(qeta)))
#}
#
#calcU = function (tset, placement_values)
#{
#  tset_sorted = sort(tset)
#  out = vapply(X = tset, FUN.VALUE = integer(length(placement_values)),
#    FUN = function (t) { ifelse(placement_values <= t, 1L, 0L) })
#    return (out)
#}
#
#dataRocGLM = function (U, tset)
#{
#  roc_glm_data = data.frame(
#    y = rep(c(0, 1), times = length(tset)),
#    x = rep(qnorm(tset), each = 2L),
#    w = as.vector(apply(U, 2, function (x) c(sum(x == 0), sum(x == 1)))))
#  return (roc_glm_data)
#}
#
#
#rocData = function (score, truth)
#{
#
#  checkmate::assertNumeric(x = score, any.missing = FALSE, len = length(truth))
#  checkmate::assertIntegerish(x = truth, lower = 0, upper = 1, any.missing = FALSE, len = length(score))
#
#  label = truth[order(score, decreasing = TRUE)]
#
#  n_pos = sum(label == 1)
#  n_neg = sum(label == 0)
#
#  tpr = c(0, cumsum(label == 1) / n_pos)
#  fpr = c(0, cumsum(label == 0) / n_neg)
#
#  return (list(tpr = tpr, fpr = fpr))
#}
#
#integrateBinormal = function (params)
#{
#  temp = function (x) pnorm(params[1] + params[2] * qnorm(x))
#  int = integrate(f = temp, lower = 0, upper = 1)
#  return (int$value)
#}
#
#rocGLMlogitAUC = function (data, ind = NULL, unlogit = FALSE)
#{
#  if (is.null(ind[1])) ind = seq_len(nrow(data))
#
#  scores = data$score[ind]
#  truth = data$truth[ind]
#
#  Fn_global = ecdf(scores[truth == 0])
#  Sn_global = function (x) 1 - Fn_global(x)
#
#  thresh_set = seq(0, 1, length.out = 30L)
#  pv_global = Sn_global(scores[truth == 1])
#  U_global = calcU(thresh_set, pv_global)
#
#  roc_data_global = dataRocGLM(U = U_global, tset = thresh_set)
#  roc_data_global = roc_data_global[is.finite(roc_data_global$x),]
#
#  y_global = roc_data_global$y
#  X_global = model.matrix(y ~ x, data = roc_data_global)
#  w_global = roc_data_global$w
#
#  my_roc_glm_global = tryCatch(
#    expr = {probitRegr(y = y_global, X = X_global, w = w_global)},
#    error = function (e) return ("fail")
#  )
#  if (! is.character(my_roc_glm_global)) {
#    auc = integrateBinormal(my_roc_glm_global$parameter)
#    attr(auc, "params") = my_roc_glm_global$parameter
#    if (unlogit) return (auc)
#    return(log(auc / (1 - auc)))
#  } else {
#    return (NA)
#  }
#}
#
#logitAUC = function (data, ind = NULL, unlogit = FALSE)
#{
#  if (is.null(ind[1])) ind = seq_len(nrow(data))
#  scores = data$score[ind]
#  truth = data$truth[ind]
#  emp_auc = mlr::measureAUC(probabilities = scores, truth = truth, negative = 0, positive = 1)
#  if (unlogit) (return (emp_auc))
#  return (log(emp_auc / (1 - emp_auc)))
#}
#
#logitToAUC = function (x) 1 / (1 + exp(-x))
#toLogit = function (x) log(x / (1 - x))
#
#deLongVar = function (scores, truth) {
#  # survivor functions for diseased and non diseased:
#  s_d = function (x) 1 - ecdf(scores[truth == 1])(x)
#  s_nond = function (x) 1 - ecdf(scores[truth == 0])(x)
#
#  # Variance of empirical auc after DeLong:
#  var_auc = var(s_d(scores[truth == 0])) / sum(truth == 0) + var(s_nond(scores[truth == 1])) / sum(truth == 1)
#
#  return (var_auc)
#}
#
#pepeCI = function (logit_auc, alpha, var_auc)
#{
#  logit_auc + c(-1, 1) * qnorm(1 - alpha/2) * sqrt(var_auc) / (logitToAUC(logit_auc) * (1 - logitToAUC(logit_auc)))
#}
#
#
#updateParam = function (beta, X, lambda, w = NULL)
#{
#  # browser()
#  W = diag(as.vector(lambda * (X %*% beta + lambda)))
#  if (! is.null(w[1])) {
#    X = diag(sqrt(w)) %*% X
#    lambda = diag(sqrt(w)) %*% lambda
#  }
#  return (beta + solve(t(X) %*% W %*% X) %*% t(X) %*% lambda)
#}
#
#probitRegr = function (y, X, w = NULL, beta_start = 0, stop_tol = 1e-8, iter_max = 25L, trace = FALSE)
#{
#  if (length(beta_start) == 1) beta_start = rep(beta_start, ncol(X))
#  if (is.vector(beta_start)) beta_start = cbind(beta_start)
#
#  beta = beta_start
#  iter = 0L
#
#  deviance = numeric(iter_max)
#  deviance[1] = probitDeviance(y, X, beta)
#
#  if (trace) cat("\n")
#
#  while (iter <= iter_max) {
#
#    beta_start = beta
#    beta = updateParam(beta_start, X = X, lambda = calculateLambda(y = y, X = X, beta = beta_start), w = w)
#
#    iter = iter + 1L
#    deviance[iter + 1L] = probitDeviance(y, X, beta)
#
#    if (trace) cat("Deviance of iter", iter, "=", round(deviance[iter + 1L], digits = 4L), "\n")
#
#    if (probitDevianceStop(y = y, X = X, beta = beta, beta_old = beta_start) < stop_tol) { if (trace) { cat("\n"); break; } }
#  }
#  out = list(iter = iter, parameter = beta, deviance = deviance[seq_len(iter + 1L)])
#  return (out)
#}
#
#predictProbit = function (mod)
#{
#  x = seq(0, 1, 0.01)
#  y = pnorm(mod$parameter[1] + mod$parameter[2] * qnorm(x))
#
#  return(list(x = x, y = y))
#}
#
