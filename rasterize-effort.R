library(arrow)
library(dplyr)
library(terra)

gbif_dir <- "/data/db/gbif/prefiltered"
classes <- c("amphibia", "aves", "mammalia", "reptilia")

# Grid template
grid <- rast("/home/berti/gbif/era5-land-template.tif")

for (cl in classes) {

  message("\n==============================")
  message("Processing: ", toupper(cl))
  message("==============================")

  # Open database
  ds <- sprintf("%s/2026-01-01_%s", gbif_dir, cl)
  df <- open_dataset(ds, format = "parquet") |>
    filter(
      year >= 1995,
      year <= 2025,
      !is.na(decimallongitude),
      !is.na(decimallatitude)
    ) |>
    select(decimallongitude, decimallatitude)

  # Initialize empty effort vector
  effort_vals <- rep(0, ncell(grid))
  df |>
    arrow::map_batches(function(batch) {
      df_chunk <- as.data.frame(batch)
      # Extract cell (pixel ID) and count
      cells <- cellFromXY(grid, df_chunk)
      cells <- cells[!is.na(cells)]
      if (length(cells) > 0) {
        tab <- table(cells)
        cell_id <- as.integer(names(tab))
        effort_vals[cell_id] <<- effort_vals[cell_id] + as.integer(tab)
      }
      # Garbage 
      gc(full = FALSE)
      return(data.frame())
    }, .lazy = FALSE)

  # Combine chunks
  effort <- setValues(grid, effort_vals)
  effort <- effort * grid

  # Write to file
  target <- sprintf("/home/berti/gbif/effort-%s.tif", cl)
  writeRaster(effort, filename = target, overwrite = TRUE, datatype = "INT4U")

}

