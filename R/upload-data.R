library(opalr)

surl     = "https://opal-demo.obiba.org/"
username = "administrator"
password = "password"

opal = opal.login(username = username, password = password, url = surl)

opal.project_delete(opal, project = "DIFUTURE-TEST")
opal.project_create(opal, project = "DIFUTURE-TEST", database = "mongodb")

datasets = list.files(here::here("data"))
datasets = gsub(".csv", "", datasets[grepl("SRV", datasets)], perl = TRUE)

for (d in datasets) {

  ftest_data = here::here("data", paste0(d, ".csv"))

  opal.table_save(opal,
    tibble = tibble::as_tibble(read.csv(ftest_data)),
    project = "DIFUTURE-TEST",
    table = d,
    overwrite = TRUE,
    force = TRUE)
}
opal.logout(opal)

rm(list = ls())
