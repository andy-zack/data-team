library(shiny)
library(DT)
library(shinydashboard)

ui <- dashboardPage(
  dashboardHeader(title = "Data Team (beta version)"),
  dashboardSidebar(
    textInput("question", "Enter your question:"),
    actionButton("submit", "Submit Question"),
    br(),
    textInput("graph_question", "\nDescribe how to graph it:"),
    actionButton("submit_graph", "Submit Graph")
  ),
  dashboardBody(
    verbatimTextOutput("questionOutput"),
    verbatimTextOutput("sqlOutput"),
    dataTableOutput("resultOutput"),
    plotOutput("plotOutput")
  )
)