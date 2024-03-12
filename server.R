library(shiny)
library(RSQLite)
library(httr)
library(jsonlite)
library(here)
library(DT)
library(ggplot2)
library(dplyr)

server <- function(input, output, session) {

  source(here::here("api_helpers.R"))
  source(here::here("main_functions.R"))
  assistant_id <- "asst_xWnXfPj1aNLlCXF1nZXAAd7p" # Replace with your assistant's ID
  shared_vars <- reactiveValues(thread_id = NULL,result = NULL)

  observeEvent(input$submit, {
    result_list <- get_and_run_sql(q = input$question,
                    assistant_id = assistant_id,
                    shared_vars = shared_vars)
    output$resultOutput <- DT::renderDataTable({result_list$result})
    output$sqlOutput <- renderText({result_list$sql_query})
    output$questionOutput <- renderText({input$question})
  })
  
  observeEvent(input$submit_graph, {
    disp_plot <- get_and_run_r(q = input$graph_question, 
                               assistant_id = assistant_id, 
                               thread_id = thread_id,
                               shared_vars = shared_vars)
      
    output$plotOutput <- renderPlot({
      disp_plot
    })
  })
}