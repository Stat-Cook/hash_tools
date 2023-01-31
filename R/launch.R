launch.hasher <- function(){
  #' @export
  app_path <- system.file("hasher.app", package="hash.tools")
  shiny::runApp(appDir = app_path)
}

