# run for shinylive to export the app as a site
shinylive::export(appdir = "app", destdir = "docs/")

# test
httpuv::runStaticServer("docs/")

# run this to create a GitHub action for deploying the app
usethis::use_github_action(url="https://github.com/posit-dev/r-shinylive/blob/actions-v1/examples/deploy-app.yaml")
