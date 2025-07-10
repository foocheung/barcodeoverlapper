# R/app_ui.R

#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    # Your application UI logic
    fluidPage(
      titlePanel("Barcode Overlap Analysis"),

      sidebarLayout(
        sidebarPanel(
          width = 3,
          h4("Input Parameters"),

          # Directory selection
          textInput("base_dir",
                   "Base Directory Path:",
                   value = "/Volumes/chi/PROJECTS_Archive/2022_CHI_PROPOSALS/Manthiram_Covid-tonsil_CHI-306/306_4_MERGED_RUN/RUN/RUN1"),

          # Barcode length
          numericInput("barcode_length",
                      "Barcode Length:",
                      value = 16,
                      min = 1,
                      max = 50),

          # Subsample size
          numericInput("subsample_size",
                      "Subsample Size:",
                      value = 1e6,
                      min = 1000,
                      max = 1e7),
          selectInput("prefix1", "Select First Prefix:", choices = c("GEX", "ADT", "CSP", "BCR", "TCR"), selected = "GEX"),
          selectInput("prefix2", "Select Second Prefix:", choices = c("GEX", "ADT", "CSP", "BCR", "TCR"), selected = "CSP"),

          # Action button
          actionButton("run_analysis",
                      "Run Analysis",
                      class = "btn-primary"),

          br(), br(),

          # Status and progress
          verbatimTextOutput("status"),

          # Download buttons
          downloadButton("download_plot",
                        "Download Plot",
                        class = "btn-success"),

          br(), br(),

          downloadButton("download_data",
                        "Download Data",
                        class = "btn-info")
        ),

        mainPanel(
          width = 9,

          # Tabs for different outputs
          tabsetPanel(
            id = "main_tabs",

            tabPanel("Heatmap",
                    plotOutput("heatmap_plot", height = "600px")),

            tabPanel("Overlap Matrix",
                    DT::dataTableOutput("overlap_table")),

            tabPanel("Summary",
                    verbatimTextOutput("summary_stats")),

            tabPanel("File Information",
                    verbatimTextOutput("file_info"))
          )
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "barcodeOverlapper"
    ),
    # Custom CSS
    tags$style(HTML("
      .btn-primary {
        background-color: #007bff;
        border-color: #007bff;
      }
      .btn-success {
        background-color: #28a745;
        border-color: #28a745;
      }
      .btn-info {
        background-color: #17a2b8;
        border-color: #17a2b8;
      }
      .content-wrapper {
        padding: 20px;
      }
      .status-box {
        background-color: #f8f9fa;
        border: 1px solid #dee2e6;
        border-radius: 4px;
        padding: 10px;
        margin: 10px 0;
      }
    "))
  )
}
