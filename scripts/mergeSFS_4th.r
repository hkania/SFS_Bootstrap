#!/usr/bin/env Rscript

# Usage: Rscript merge_obs.R sfs_chr*/...obs

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop("❌ Please provide a list of input .obs files to merge")
}

sfs_matrix <- NULL
expected_ncol <- NULL
row_names <- NULL
col_names <- NULL

for (f in args) {
  cat("🔍 Reading", f, "...\n")
  result <- tryCatch({
    # Skip first line ("1 observation"), then read table with row and column names
    dat <- read.table(f, skip = 1, header = TRUE, row.names = 1, fill = TRUE, check.names = FALSE)

    # Convert to numeric matrix
    mat <- as.matrix(dat)
    storage.mode(mat) <- "numeric"

    # Save row/col names from first file
    if (is.null(sfs_matrix)) {
      sfs_matrix <- mat
      expected_ncol <- ncol(mat)
      row_names <- rownames(dat)
      col_names <- colnames(dat)
    } else {
      if (ncol(mat) != expected_ncol) {
        stop(sprintf("Column mismatch in %s: got %d, expected %d", f, ncol(mat), expected_ncol))
      }
      sfs_matrix <- sfs_matrix + mat
    }
    NULL
  }, error = function(e) {
    cat("⚠️  Skipping", f, "—", e$message, "\n")
    return(e)
  })

  if (!is.null(result)) next
}

# Restore row and column names
rownames(sfs_matrix) <- row_names
colnames(sfs_matrix) <- col_names

# Output
output_file <- "merged_jointDAFpop1_0.obs"
writeLines(c("1 observations. No. of demes and sample sizes are on next line.", ""), output_file)
write.table(sfs_matrix, file = output_file, sep = "\t", quote = FALSE, col.names = NA)

cat("✅ Merged matrix with headers written to:", output_file, "\n")
