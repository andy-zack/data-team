library(shiny)
library(RSQLite)
library(httr)
library(jsonlite)
library(here)
library(DT)

server <- function(input, output, session) {

  source(here::here("api_helpers.R"))
  assistant_id <- "asst_xWnXfPj1aNLlCXF1nZXAAd7p" # Replace with your assistant's ID
  cat("got source code...")
  
  observeEvent(input$submit, {
    
    cat("got input...")
    # Test if API call can be made
    thread_id <- start_thread_with_question(input$question)
    cat("started thread...")
    run_id <- create_run_for_thread(assistant_id, thread_id)
    cat("started run...")
    messages <- poll_for_response(run_id, thread_id)
    cat("got messages...")
    
    if (!startsWith(messages$data[[1]]$content[[1]]$text$value, "ERROR:")) {
      
      cat("no error found...")
      sql_query <- extract_sql_query_from_messages(messages)
      cat("extracted sql...")
      
      # Connect to database
      con <- dbConnect(SQLite(), dbname = here("Chinook_Sqlite.sqlite"))
      
      # Execute the SQL query and fetch results
      result <- dbGetQuery(con, sql_query)
      
      # Disconnect from the database
      dbDisconnect(con)
      
      # Output the query results
      output$resultOutput <- DT::renderDataTable({
        result
      })
      
      output$sqlOutput <- renderText({
        sql_query
      })
      
    } else {
      
      cat("did not return SQL...")
      # Output the query results
      output$resultOutput <- DT::renderDataTable({
        data.frame()
      })
      
      output$sqlOutput <- renderText({
        messages$data[[1]]$content[[1]]$text$value
      })
      
    }
    
    # Output the SQL query
    output$questionOutput <- renderText({
      input$question
    })
    
  })
  observeEvent(input$submit_graph, {
    
    cat("got graph input...")
    # add new message to existing thread
    add_message_to_thread(input$question, thread_id)
    cat("added message to thread...")
    run_id <- create_run_for_thread(assistant_id, thread_id)
    cat("started run...")
    messages <- poll_for_response(run_id, thread_id)
    cat("got messages...")
    # extract_r_code_from_messages() needs to be created too
    r_code <- extract_r_code_from_messages(messages)
    plot_expr <- parse(text = paste("disp_plot <-", r_code))
    eval(plot_expr)
  })
}