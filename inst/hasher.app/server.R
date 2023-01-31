library(shiny)
library(rstudioapi)
library(shinyWidgets)
library(openssl)
library(tidyverse)



# install.packages("shinyWidgets")

path_join <- function(..., append=".csv"){
  string <- paste(..., sep=.Platform$file.sep)
  paste(string, append, sep="")
}

hash_data <- function(data, columns, SEED){
  hasher <- function(values){
    chars <- as.character(values)
    sha256(chars, SEED)
  }
  
  data %>% mutate(
    across(all_of(columns), hasher)
  )
}


generate_config <- function(){
  basis <- c(letters, LETTERS, 0:9)
  SEED <- paste(sample(basis, 200, T), collapse = "")
  writeLines(SEED, "config.txt")
  SEED
}

read_config <- function(){
  exists <- file.exists("config.txt")
  
  if (!exists) {
    generate_config()
  }
  
  readLines(SEED, "config.txt")
}

readers <- list(
  "csv" = read.csv,
  "xls" = openxlsx::read.xlsx,
  "xlsx" = openxlsx::read.xlsx  
)

read_data <- function(file_path){
  ext <- tools::file_ext(file_path)
  implemented_extensions <- names(readers)
  
  if (!ext %in% implemented_extensions){
    
    shinyalert(
      glue::glue(
        "Data type '{ext}' not implemented for hasing.  \\
      Please convert to {paste(implemented_extensions, collapse='/ ')}"
      ), 
      type = "error")
    return(data.frame())
  }
  
  reader <- readers[[ext]]
  
  reader(file_path)
}

server <- function(input, output, session) {

  data <- NA
  SEED <- NA
  hashed <- NA

  shinyjs::disable("button_hash")
  shinyjs::disable("button_save_hash")
  
  # Load data
  observeEvent(
    input$button_data,
    {
      file_data <- rstudioapi::selectFile(caption = "Select data file")
      if (!is.null(file_data)){
        data <<- read_data(file_data)
        updatePickerInput(session, "picker_to_hash", 
                          choices=colnames(data))
      }
    }
  )

  # Load config  
  observeEvent(
    input$button_select_config,
    {
      file_config <- rstudioapi::selectFile(caption = "Select config file")
      re <- regexpr("config.txt$", file_config)

      if (re[1] > 1){
        SEED <<- readLines(file_config)  
      }
      else {
        shinyalert(
          glue::glue("Expected 'config.txt' as file - found '{file_config}'")
        )
      }
    }
  )
  
  # Generate new config
  observeEvent(
    input$button_gen_config,
    {
      SEED <<- generate_config()
      print(SEED)
    }
  )
  
  # Hash data
  observeEvent(
    input$button_hash,
    {
      hashed <<- hash_data(data, input$picker_to_hash, SEED)
      output$hashed <- renderTable(hashed)
    }
  )
  
  # Track config load status
  observe({
    input$button_gen_config
    input$button_select_config
    SEED_status <- ifelse(is.na(SEED), "Undef", "Defined")
    output$SEED_status <- renderText({SEED_status})
    
    if (class(data) == "data.frame" && !is.na(SEED)){
      shinyjs::enable("button_hash")
    }
  })

  # Enable saving of  hashed data
  observe({
    input$button_hash

    if (class(hashed) == "data.frame"){
      shinyjs::enable("button_save_hash")
    }
  })
  
  # Save hashed data
  observeEvent(
    input$button_save_hash,
    {
      
      dir_output <- rstudioapi::selectDirectory(
        caption = "Select location to save new data"
      )
      if (!is.null(dir_output)){
        path_output <- path_join(dir_output, input$text_file_name)
        write.csv(hashed, path_output)
        shinyalert(glue::glue("Data saved to {path_output}"))
      }
    }
  )
}
