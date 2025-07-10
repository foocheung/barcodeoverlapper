# Barcode Overlapper Shiny App

https://github.com/user-attachments/assets/28f044d7-1576-4472-ac60-f951c27ade33

The **Barcode Overlapper** is a Shiny application for computing and visualizing barcode overlap between single-cell sequencing libraries—typically between **gene expression (GEX)** and **antibody-derived tag (ADT)** data. It helps verify that samples are correctly matched across modalities in multi-omic experiments.

## What It Does




This app wraps around an R script that performs the following:

- **Streams FASTQ files** using `ShortRead::FastqStreamer` to extract a subsample of reads (e.g., 1 million).
- **Extracts cell barcodes** from the start of each R1 read (default: first 16 bp).
- **Searches for FASTQ files** in directories named `GEX###` and `ADT###` under a specified base path.
- **Calculates overlaps** between every pair of GEX and ADT barcode sets.
- **Generates a heatmap** showing the number of overlapping barcodes between each pair.

## Example Output

The app produces a barcode overlap heatmap with:

- **X-axis:** ADT samples
- **Y-axis:** GEX samples
- **Color scale:** Number of overlapping barcodes (white to blue gradient)

This visual helps you:

- Confirm matched GEX–ADT libraries
-️ Detect mislabeled or mispaired samples
- Estimate barcode recovery rates between sequencing libraries

## Typical Use Cases

- Quality control for multi-modal single-cell experiments (e.g., CITE-seq)
- Diagnosing sample swaps or contamination
- Estimating cross-library matching efficiency

## Dependencies

- R packages: `ShortRead`, `ggplot2`, `reshape2`

## File Structure

- `extract_compare_barcodes.R`: Core script to compute overlap from raw FASTQ
- `app_ui.R`, `app_server.R`: Shiny app interface and logic
- `www/`: Optional image output and static assets

---

  **Tip:** To speed up processing, the app subsamples from each FASTQ file rather than loading entire datasets.

