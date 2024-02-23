library(shiny)
library(DT)

ui <- fluidPage(
  titlePanel("Data Team (beta)"),
  sidebarLayout(
    sidebarPanel(
      textInput("question", "Enter your question:"),
      actionButton("submit", "Submit")
    ),
    mainPanel(
      verbatimTextOutput("questionOutput"),
      verbatimTextOutput("sqlOutput"),
      DT::dataTableOutput("resultOutput")
    )
  )
)