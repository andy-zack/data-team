library(DBI)
library(RSQLite)
library(httr)
library(jsonlite)
library(here) 

server <- function(input, output, session) {
  cat("\n")
  cat("got input...")
  
  source(here::here("code", "api_helpers.R"))
  assistant_id <- "asst_xWnXfPj1aNLlCXF1nZXAAd7p" # Replace with your assistant's ID

  observeEvent(input$submit, {

    # Test if API call can be made
    thread_id <- start_thread_with_question(input$question)
    cat("started thread...")
    create_run_for_thread(assistant_id, thread_id)
    cat("started run...")
    messages <- poll_for_response(thread_id)
    cat("got messages...")
    
    if (!startsWith(messages$data[[1]]$content[[1]]$text$value, "ERROR:")) {
      
      cat("no error found...")
      sql_query <- extract_sql_query_from_messages(messages)
      cat("extracted sql...")
      
      # Connect to database
      con <- dbConnect(SQLite(), dbname = here("data-team-beta", "my_database.sqlite"))
      
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
}