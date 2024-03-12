library(shiny)
library(DT)

ui <- fluidPage(
  titlePanel("Data Team (beta)"),
  sidebarLayout(
    sidebarPanel(
      textInput("question", "Enter your question:"),
      actionButton("submit", "Submit Question"),
      br(),
      br(),
      br(),
      textInput("graph_question", "\nDescribe how to graph it:"),
      actionButton("submit_graph", "Submit Graph")
    ),
    mainPanel(
      verbatimTextOutput("questionOutput"),
      verbatimTextOutput("sqlOutput"),
      dataTableOutput("resultOutput"),
      plotOutput("plotOutput")
    )
  )
)