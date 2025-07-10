# R/app_server.R

#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {

  library(ShortRead)
  library(ggplot2)
  library(reshape2)
  library(DT)

  values <- reactiveValues(
    overlap_matrix = NULL,
    overlap_df = NULL,
    gex_files = NULL,
    adt_files = NULL,
    plot = NULL,
    analysis_complete = FALSE
  )

  output$status <- renderText({
    if (values$analysis_complete) {
      "Analysis complete!"
    } else {
      "Ready to run analysis..."
    }
  })

  observeEvent(input$run_analysis, {

    if (!dir.exists(input$base_dir)) {
      showNotification("Base directory does not exist!", type = "error")
      return()
    }

    withProgress(message = "Running barcode analysis...", {

      incProgress(0.1, detail = paste("Finding FASTQ files for", input$prefix1, "and", input$prefix2, "..."))

      tryCatch({
        values$gex_files <- find_fastq_files(input$base_dir, input$prefix1)
        values$adt_files <- find_fastq_files(input$base_dir, input$prefix2)

        if (length(values$gex_files) == 0 || length(values$adt_files) == 0) {
          showNotification("No FASTQ files found for one or both selected prefixes!", type = "error")
          return()
        }

        incProgress(0.3, detail = paste("Extracting", input$prefix1, "barcodes..."))
        gex_barcodes_list <- lapply(values$gex_files, function(file) {
          extract_barcodes(file, input$barcode_length, input$subsample_size)
        })

        incProgress(0.5, detail = paste("Extracting", input$prefix2, "barcodes..."))
        adt_barcodes_list <- lapply(values$adt_files, function(file) {
          extract_barcodes(file, input$barcode_length, input$subsample_size)
        })

        incProgress(0.7, detail = "Calculating overlaps...")
        overlap_matrix <- matrix(0,
                                 nrow = length(values$gex_files),
                                 ncol = length(values$adt_files))
        rownames(overlap_matrix) <- basename(dirname(values$gex_files))
        colnames(overlap_matrix) <- basename(dirname(values$adt_files))

        for (i in seq_along(values$gex_files)) {
          for (j in seq_along(values$adt_files)) {
            overlap_matrix[i, j] <- calculate_overlap(gex_barcodes_list[[i]], adt_barcodes_list[[j]])
          }
        }

        values$overlap_matrix <- overlap_matrix
        values$overlap_df <- melt(overlap_matrix, varnames = c(input$prefix1, input$prefix2), value.name = "Overlap")

        incProgress(0.9, detail = "Creating plot...")
        values$plot <- ggplot(values$overlap_df, aes_string(x = input$prefix2, y = input$prefix1, fill = "Overlap")) +
          geom_tile(color = "white") +
          scale_fill_gradient(low = "white", high = "blue") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
          labs(
            title = paste("Barcode Overlap Between", input$prefix1, "and", input$prefix2),
            x = paste(input$prefix2, "Sample"),
            y = paste(input$prefix1, "Sample"),
            fill = "Overlap"
          )

        values$analysis_complete <- TRUE
        showNotification("Analysis completed successfully!", type = "success")

      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })

  output$heatmap_plot <- renderPlot({
    req(values$plot)
    values$plot
  })

  output$overlap_table <- DT::renderDataTable({
    req(values$overlap_df)
    DT::datatable(values$overlap_df, options = list(pageLength = 25, scrollX = TRUE), filter = "top")
  })

  output$summary_stats <- renderText({
    req(values$overlap_matrix)
    paste(
      "Summary Statistics:",
      paste("Number of", input$prefix1, "samples:", nrow(values$overlap_matrix)),
      paste("Number of", input$prefix2, "samples:", ncol(values$overlap_matrix)),
      paste("Total overlaps calculated:", length(values$overlap_matrix)),
      paste("Maximum overlap:", max(values$overlap_matrix)),
      paste("Minimum overlap:", min(values$overlap_matrix)),
      paste("Mean overlap:", round(mean(values$overlap_matrix), 2)),
      paste("Median overlap:", median(values$overlap_matrix)),
      sep = "\n"
    )
  })

  output$file_info <- renderText({
    req(values$gex_files, values$adt_files)
    paste(
      "File Information:",
      "",
      paste(input$prefix1, "Files:"),
      paste(basename(values$gex_files), collapse = "\n"),
      "",
      paste(input$prefix2, "Files:"),
      paste(basename(values$adt_files), collapse = "\n"),
      sep = "\n"
    )
  })

  output$download_plot <- downloadHandler(
    filename = function() {
      paste("barcode_overlap_heatmap_", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      req(values$plot)
      ggsave(file, plot = values$plot, width = 12, height = 8, dpi = 300)
    }
  )

  output$download_data <- downloadHandler(
    filename = function() {
      paste("barcode_overlap_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(values$overlap_df)
      write.csv(values$overlap_df, file, row.names = FALSE)
    }
  )
}
