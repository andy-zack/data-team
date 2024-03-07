library(shiny)
library(RSQLite)
library(httr)
library(jsonlite)
library(here)
library(DT)
library(ggplot2)

server <- function(input, output, session) {

  source(here::here("api_helpers.R"))
  assistant_id <- "asst_xWnXfPj1aNLlCXF1nZXAAd7p" # Replace with your assistant's ID
  cat("got source code...")
  
  observeEvent(input$submit, {
    
    cat("got input...")
    # Test if API call can be made
    thread_id <- start_thread_with_question(input$question)
    cat(paste0("started thread (", thread_id, ")..."))
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
    add_message_to_thread(thread_id, input$graph_question)
    cat("added message to thread...")
    run_id <- create_run_for_thread(assistant_id, thread_id)
    cat("started run...")
    messages <- poll_for_response(run_id, thread_id)
    cat("got messages...")
    # get most recent message
    message <- get_most_recent_assistant_text(messages)
    cat(message)
    cat("got most recent...")
    # extract the R code
    r_code <- extract_r_from_message(message)
    cat("got r code...")
    cat(r_code)
    plot_expr <- parse(text = paste("disp_plot <-", r_code))
    cat("parsed r code")
    eval(plot_expr)
    cat("evaluated r code...")
    #output plot
    output$plotOutput <- renderPlot({
      disp_plot
    })
  })
}