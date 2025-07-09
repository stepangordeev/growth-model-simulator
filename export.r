# run for shinylive to export the app as a site
shinylive::export(appdir = "app", destdir = "docs/")

# test
httpuv::runStaticServer("docs/")
