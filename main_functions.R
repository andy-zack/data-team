get_and_run_sql <- function(q, assistant_id, shared_vars) {
  
  cat("got input...")
  shared_vars$thread_id <- start_thread_with_question(q)
  thread_id <- shared_vars$thread_id
  
  cat(paste0("started thread (", thread_id, ")..."))
  run_id <- create_run_for_thread(assistant_id, thread_id)
  
  cat("started run...")
  messages <- poll_for_response(run_id, thread_id)
  
  cat("got messages...")
  
  if (!startsWith(messages$data[[1]]$content[[1]]$text$value, "ERROR:")) {
    
    cat("no error found...")
    sql_query <- extract_sql_query_from_messages(messages)
    cat("extracted sql...")
    cat("\n")
    cat(sql_query)
    cat("\n")
    
    # Connect to database
    con <- dbConnect(SQLite(), dbname = here("Chinook_Sqlite.sqlite"))
    
    # Execute the SQL query and fetch results
    result <- dbGetQuery(con, sql_query)
    shared_vars$result <- result
    
    # Disconnect from the database
    dbDisconnect(con)
    
  } else {
 
    cat("did not return SQL...")
    result <- data.frame()
    sql_query <- messages$data[[1]]$content[[1]]$text$value
   
  }
  
  return(list(result = result,
              sql_query = sql_query))
}

get_and_run_r <- function(q, assistant_id, thread_id, shared_vars) {
  thread_id <- shared_vars$thread_id
  result <- shared_vars$result
  
  cat(thread_id)
  add_message_to_thread(thread_id, q)
  cat("added message to thread...")
  
  run_id <- create_run_for_thread(assistant_id, thread_id)
  cat("started run...")
  
  messages <- poll_for_response(run_id, thread_id)
  cat("got messages...")

  message <- get_most_recent_assistant_text(messages)
  cat(message)
  cat("got most recent...")

  r_code <- extract_r_from_message(message)
  cat("got r code...")
  cat(r_code)
  
  plot_expr <- parse(text = paste("disp_plot <-", r_code))
  cat("parsed r code")
  
  eval(plot_expr)
  cat("evaluated r code...")
  
  return(disp_plot)
}