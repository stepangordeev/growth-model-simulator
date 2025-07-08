# run for shinylive to export the app as a site to root dir
shinylive::export(appdir = "app", destdir = "shinylive_output/")

# test
httpuv::runStaticServer("shinylive_output/")
