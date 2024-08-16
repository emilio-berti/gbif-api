library(tidyverse)
library(terra)
options(readr.show_progress = FALSE)

set.seed(1234)

templ <- rast("templates/america.tif")
templ <- aggregate(templ, 5)
max_uncert <- res(templ)[1] / 2
templ <- project(templ, "EPSG:4326")


ff <- list.files(
  "downloads/occurrences", 
  pattern = "[.]tsv",
  full.names = TRUE
)

for (f in ff) {
  message(" - ", f)
  d <- read_tsv(f, show_col_types = FALSE) |> 
    filter(coordinateUncertaintyInMeters <= max_uncert) |> 
    transmute(
      x = as.numeric(decimalLongitude),
      y = as.numeric(decimalLatitude)
    ) |> 
    distinct_all()
  cells <- cellFromXY(templ, as.matrix(d))
  d[["cell"]] <- cells
  d <- d |> 
    group_by(cell) |> 
    slice_sample(n = 1) |> 
    ungroup()
  d |> write_csv(gsub("[.]tsv", ".csv", f))
}
