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

poll_for_response <- function(thread_id, interval = 5, max_attempts = 5) {
  attempt <- 1
  repeat {
    Sys.sleep(interval)
    cat("Checking for message...\n")
    messages <- perform_get_request(paste0("https://api.openai.com/v1/threads/", thread_id, "/messages"))
    
    # Check for assistant's message
    has_response <- FALSE
    for (message in messages$data) {
      if (message$role == "assistant" && 
          !is.null(message$content) && 
          length(message$content) >= 1 && 
          !is.null(message$content[[1]]$text) &&
          !is.null(message$content[[1]]$text$value)) {
        has_response <- TRUE
        break
      }
    }
    
    if (has_response) {
      break
    }
    
    if (attempt >= max_attempts) {
      stop("Max attempts reached without receiving a complete response from the assistant.")
    }
    
    attempt <- attempt + 1
  }
  messages
}


# Function to create a run for the assistant to process the thread
create_run_for_thread <- function(assistant_id, thread_id) {
  create_run_body <- list(
    assistant_id = assistant_id
  )
  perform_post_request(paste0("https://api.openai.com/v1/threads/", thread_id, "/runs"), create_run_body)
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

start_thread_with_question <- function(question) {
  thread_response <- perform_post_request("https://api.openai.com/v1/threads", list(
    messages = list(
      list(
        role = "user",
        content = question
      )
    )
  ))
  thread_response$id
}
