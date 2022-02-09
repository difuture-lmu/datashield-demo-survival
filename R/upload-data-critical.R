library(opalr)
library(magrittr)

surl     = "https://opal-demo.obiba.org/"
username = "administrator"
password = "password"

opal = opal.login(username = username, password = password, url = surl)

opal.project_delete(opal, project = "DIFUTURE-TEST")
opal.project_create(opal, project = "DIFUTURE-TEST", database = "mongodb")

datasets = c("KUM", "MRI", "UKA", "UKT")
for (d in datasets) {

  ftest_data = paste0("data/", d, ".csv")
  fdict_test_data = paste0("data/dictionary_", d, ".xls")

  dict_test_data = fdict_test_data %>%
    readxl::excel_sheets() %>%
    purrr::set_names() %>%
    purrr::map(readxl::read_excel, path = fdict_test_data)

  test_data = dictionary.apply(read.csv(ftest_data), dict_test_data[[1]], dict_test_data[[2]])

  opal.table_save(opal,
    tibble = tibble::as_tibble(test_data[sample(seq_len(nrow(test_data)), 3), ]),
    project = "DIFUTURE-TEST",
    table = d,
    overwrite = TRUE,
    force = TRUE)
}
opal.logout(opal)
