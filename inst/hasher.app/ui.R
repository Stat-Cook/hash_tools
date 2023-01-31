library(shiny)
library(shinyjs)
library(shinyWidgets)
library(shinyalert)

ui <- fluidPage(
  
  # Application title
  titlePanel("Data Hasher"),

  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      actionButton("button_data", "Load Data"),
      actionButton("button_select_config", "Select Config"),
      actionButton("button_gen_config", "Generate New Config"),
      pickerInput("picker_to_hash", "To Hash:", c(), multiple=T),
      actionButton("button_hash", "Hash Data"),
      textAreaInput("text_file_name", "File name", "hashed"),
      actionButton("button_save_hash", "Save Hashed Data")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      shinyjs::useShinyjs(),
      fluidPage(
        fluidRow(
          column(2, "Seed Status:"), 
          column(2, textOutput("SEED_status"))
        ),
        fluidRow(
          column(12, tableOutput("hashed"))
        )
      )
    )
  )
)
