# run this once to create a GitHub action for deploying the app
# usethis::use_github_action(url="https://github.com/posit-dev/r-shinylive/blob/actions-v1/examples/deploy-app.yaml")


## emulate the gh action locally (make sure destdir is in .gitignore)
shinylive::export(appdir = "./", destdir = "site/")
httpuv::runStaticServer("site/")