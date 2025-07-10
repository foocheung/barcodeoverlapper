# R/fct_barcode_analysis.R

#' Extract barcodes from a fastq file
#'
#' @param fastq_path Path to the fastq file
#' @param barcode_length Length of barcode to extract
#' @param subsample_size Number of reads to sample
#'
#' @return Character vector of unique barcodes
#' @export
extract_barcodes <- function(fastq_path, barcode_length = 16, subsample_size = 1e6) {
  # Create a FastqStreamer object to stream the FASTQ file
  streamer <- ShortRead::FastqStreamer(fastq_path, n = subsample_size)
  
  # Initialize a vector to store barcodes
  barcodes <- character(0)
  
  # Stream the fastq file in chunks
  while (length(fastq_chunk <- ShortRead::yield(streamer)) > 0) {
    # Extract sequences from the chunk
    sequences <- ShortRead::sread(fastq_chunk)
    
    # Extract the barcodes (first `barcode_length` bases of each sequence)
    chunk_barcodes <- Biostrings::subseq(sequences, start = 1, end = barcode_length)
    
    # Convert to character vector and combine with previously extracted barcodes
    barcodes <- c(barcodes, as.character(chunk_barcodes))
    
    # Stop if we have enough barcodes
    if (length(barcodes) >= subsample_size) {
      barcodes <- barcodes[1:subsample_size]
      break
    }
  }
  
  # Close the streamer
  close(streamer)
  
  # Remove duplicates
  unique(barcodes)
}

#' Calculate barcode overlap between two sets
#'
#' @param gex_barcodes Character vector of GEX barcodes
#' @param adt_barcodes Character vector of ADT barcodes
#'
#' @return Integer count of overlapping barcodes
#' @export
calculate_overlap <- function(gex_barcodes, adt_barcodes) {
  length(intersect(gex_barcodes, adt_barcodes))
}

#' Find all R1 fastq files in specified folders
#'
#' @param base_dir Base directory to search in
#' @param prefix Prefix pattern to match (e.g., "GEX" or "ADT")
#'
#' @return Character vector of fastq file paths
#' @export
find_fastq_files <- function(base_dir, prefix) {
  dirs <- list.dirs(base_dir, full.names = TRUE, recursive = FALSE)
  target_dirs <- dirs[grepl(paste0("^", prefix, "\\d+$"), basename(dirs))]
  
  if (length(target_dirs) == 0) {
    warning(paste("No directories found with prefix:", prefix))
    return(character(0))
  }
  
  fastq_files <- list.files(target_dirs, 
                           pattern = ".*_R1_001.fastq.gz$", 
                           recursive = TRUE, 
                           full.names = TRUE)
  
  if (length(fastq_files) == 0) {
    warning(paste("No R1 fastq files found in", prefix, "directories"))
  }
  
  return(fastq_files)
}

#' Validate directory structure
#'
#' @param base_dir Base directory path
#'
#' @return List with validation results
#' @export
validate_directory <- function(base_dir) {
  if (!dir.exists(base_dir)) {
    return(list(valid = FALSE, message = "Base directory does not exist"))
  }
  
  gex_files <- find_fastq_files(base_dir, "GEX")
  adt_files <- find_fastq_files(base_dir, "ADT")
  
  if (length(gex_files) == 0) {
    return(list(valid = FALSE, message = "No GEX files found"))
  }
  
  if (length(adt_files) == 0) {
    return(list(valid = FALSE, message = "No ADT files found"))
  }
  
  return(list(
    valid = TRUE, 
    message = "Directory structure is valid",
    gex_count = length(gex_files),
    adt_count = length(adt_files)
  ))
}