
#### libraries ----

library(tidyverse)
library(childsds)
library(config)
library(DT)
library(glue)
library(lubridate)
library(scales)
library(shiny)
library(shinydashboard)
library(shinyjs)
library(jsonlite)
library(httr)

#### helper functions ----

source("99-helper.R")

#### UI ----

ui <- dashboardPage(

    dashboardHeader(title = "Year 1 Weight"),

    dashboardSidebar(disable = TRUE),

    dashboardBody(
        useShinyjs(),
        fluidRow(
            box(
                uiOutput('name'),
                uiOutput('age'),
                hidden(numericInput("refresher", "", value = 0)),
                width = 12
            )
        ),

        fluidRow(
            column(6,
                   valueBoxOutput("perc50"),
                   hidden(valueBoxOutput("target_volume")),
                   valueBoxOutput("perc"),
                   valueBoxOutput("weight_gain"),
                   actionButton("add_weight", "Add weight")),
            column(6, div(style = "margin: 15px",
                          tabsetPanel(type = "tabs",
                                      tabPanel("WHO Growth curve", plotOutput("plot1", height = 300)),
                                      tabPanel("Weight change", uiOutput("plot_change")),
                                      tabPanel("Weight table", dataTableOutput("tab_weights")))
            ))
        ),

        fluidRow(
            box(p("Formula volume targets are calculated
                  per NHMRC guidelines, EAT FOR HEALTH: Infant Feeding
                  Guidelines, Information for health workers (2012) Table 8.5
                  Approximate formula requirements for infants. WHO growth
                  curves were crated with the childsds
                  package in R (who.ref reference data). The 'Year 1 Weight' App was
                  prepared with R Shiny by Paul G. Stevenson (Oct-2020) for personal
                  use only."),
                width = 12)
        )
    )
)
