# Load required packages
library(httr)
library(jsonlite)
library(RSQLite)
library(DBI)
library(config)

cat("loaded packages...")

# Set OpenAI API key and headers globally. This has to be weird so that it pulls from the Renviron file first, but then checks the config file otherwise.
api_key <- tryCatch({
  key <- Sys.getenv("OPENAI_API_KEY")
  if (key == "") stop("API key not set")
  key
}, error = function(e) {
  # If an error occurs or the key is not set, this block will execute
  config <- config::get()
  config$OPENAI_API_KEY
})


cat("got api key...")

global_headers <- c(
  `Content-Type` = "application/json",
  `Authorization` = paste("Bearer", api_key),
  `OpenAI-Beta` = "assistants=v1"
)

# Function to perform API POST request with error handling
perform_post_request <- function(url, body, headers = global_headers, encode_type = "json") {
  response <- POST(url, add_headers(.headers = headers), body = body, encode = encode_type)
  if (http_status(response)$category != "Success") {
    stop(sprintf("API request failed with status %d: %s", http_status(response)$status, content(response, "text", encoding = "UTF-8")))
  }
  content(response, "parsed")
}

# Function to perform API GET request with error handling
perform_get_request <- function(url, headers = global_headers) {
  response <- GET(url, add_headers(.headers = headers))
  if (http_status(response)$category != "Success") {
    stop(sprintf("API request failed with status %d: %s", http_status(response)$status, content(response, "text", encoding = "UTF-8")))
  }
  content(response, "parsed")
}

# Function to execute SQL query
execute_sql_query <- function(sql_query, db_connection) {
  result <- tryCatch({
    dbGetQuery(db_connection, sql_query)
  }, error = function(e) {
    message("Error executing SQL query: ", e$message)
    NULL
  })
  result
}

# Function to check a thread for responses
poll_for_response <- function(run_id, thread_id, interval = 5, max_attempts = 5) {
  for(attempt in 1:max_attempts) {
    Sys.sleep(interval)
    cat("Checking if run is complete...\n")
    run_reply <- perform_get_request(paste0("https://api.openai.com/v1/threads/", 
                                             thread_id, 
                                             "/runs/", 
                                             run_id))
    run_status <- run_reply$status
    cat(run_status)
    # Check for run to be complete
    if (run_status == "completed") {
      messages <- perform_get_request(paste0("https://api.openai.com/v1/threads/", thread_id, "/messages"))
      break
    } else if (attempt == max_attempts) {
      stop("Max attempts reached without receiving a complete response from the assistant.")
    }
  }
  return(messages)

}

# Function to create a run for the assistant to process the thread
create_run_for_thread <- function(assistant_id, thread_id) {
  create_run_body <- list(
    assistant_id = assistant_id
  )
  create_run_reply <- perform_post_request(paste0("https://api.openai.com/v1/threads/", thread_id, "/runs"), create_run_body)
  run_id <- create_run_reply$id
  return(run_id)
}

# Function to extract SQL query from assistant's response
extract_sql_query_from_messages <- function(messages) {
  most_recent_assistant_message <- NULL
  most_recent_timestamp <- -Inf
  
  for (message in messages$data) {
    if (message$role == "assistant" && message$created_at > most_recent_timestamp) {
      most_recent_timestamp <- message$created_at
      most_recent_assistant_message <- message$content[[1]]$text$value
    }
  }
  
  if (!is.null(most_recent_assistant_message)) {
    sql_query <- gsub("^```sql|```$", "", most_recent_assistant_message)
    #sql_query <- gsub("\n", " ", sql_query)
    sql_query <- trimws(sql_query)
    return(sql_query)
  } else {
    stop("No message from the assistant found.")
  }
}

extract_r_from_message <- function(message) {
  r_code <- gsub("^```r|```$", "", message)
  r_code <- trimws(r_code)
  return(r_code)
}

start_thread_with_question <- function(question) {
  thread_response <- perform_post_request("https://api.openai.com/v1/threads", list(
    messages = list(
      list(
        role = "user",
        content = question
      )
    )
  )
  )
  thread_response$id
}

add_message_to_thread <- function(thread_id, question) {
  message_response <- perform_post_request(paste0("https://api.openai.com/v1/threads/", 
                                                  thread_id, 
                                                  "/messages"), 
                                           body = list(
                                             role = "user",
                                             content = question
                                           )
                                           )
  return(message_response)
}

get_most_recent_assistant_text <- function(message_object) {
  # Initialize variables to keep track of the most recent message details
  latest_timestamp <- -Inf
  latest_message_text <- ""
  
  # Loop through each message in the data list
  for (message in message_object$data) {
    # Check if the message is from the assistant
    if (message$role == "assistant" && message$created_at > latest_timestamp) {
      # Update the latest timestamp and message text if this message is more recent
      latest_timestamp <- message$created_at
      if (length(message$content) > 0 && !is.null(message$content[[1]]$text$value)) {
        latest_message_text <- message$content[[1]]$text$value
      }
    }
  }
  
  # Return the most recent message text, or NULL if none found
  if (latest_timestamp == -Inf) {
    return(NULL)
  } else {
    return(latest_message_text)
  }
}