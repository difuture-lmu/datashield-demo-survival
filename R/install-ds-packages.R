surl     = "https://opal-demo.obiba.org/"
username = "administrator"
password = "password"

opal = opalr::opal.login(username = username, password = password, url = surl)

cat("Install package ranger\n")
tmp = opalr::dsadmin.install_package(opal = opal, pkg = "ranger")

#cat("Install package trtf\n")
#tmp = opalr::dsadmin.install_package(opal = opal, pkg = "trtf")
#cat("Install package tram\n")
#tmp = opalr::dsadmin.install_package(opal = opal, pkg = "tram")
#cat("Install package partykit\n")
#tmp = opalr::dsadmin.install_package(opal = opal, pkg = "partykit")


pkgs = c("dsPredictBase", "dsCalibration", "dsROCGLM")#, "rmmodeldata")
for (pkg in pkgs) {
  cat("Install package", pkg, "\n")
  check1 = opalr::dsadmin.install_github_package(opal = opal, pkg = pkg, username = "difuture-lmu", ref = "main")
  if (! check1)
    stop("[", Sys.time(), "] Was not able to install ", pkg, "!")

  check2 = opalr::dsadmin.publish_package(opal = opal, pkg = pkg)
  if (! check2)
    stop("[", Sys.time(), "] Was not able to publish methods of ", pkg, "!")

  cat("  Done!\n")
}

opalr::opal.logout(opal)
rm(list = ls())
