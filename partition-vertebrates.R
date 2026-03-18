library(arrow)
library(dplyr)

# Open database
gbif_dir <- "/data/db/gbif/2026-01-01"
partition_dir <- file.path(dirname(gbif_dir), "prefiltered")
df <- open_dataset(gbif_dir, format = "parquet")

# Columns to keep
cols <- c(
  "class", "taxonkey", "scientificname", 
  "year", "decimallongitude", "decimallatitude", "coordinateuncertaintyinmeters"
)
valid_ranks <- c("SPECIES", "SUBSPECIES", "FORM", "VARIETY")

# Partition function
write_class_partition <- function(dataset, class_filter, name) {

  message(toupper(name))
  
  dataset |>
    filter(
      class %in% class_filter,
      occurrencestatus == "PRESENT",
      taxonrank %in% valid_ranks
    ) |>
    select(all_of(cols)) |>
    write_dataset(
      file.path(partition_dir, paste(basename(gbif_dir), name, sep = "_")),
      format = "parquet",
      existing_data_behavior = "overwrite",
      max_rows_per_file = 1e6
    )
}

# Apply partitions
write_class_partition(df, "Amphibia", "amphibia")
write_class_partition(df, "Aves", "aves")
write_class_partition(df, "Mammalia", "mammalia")
write_class_partition(df, c("Testudines", "Squamata", "Crocodylia", "Sphenodontia"), "reptilia")

