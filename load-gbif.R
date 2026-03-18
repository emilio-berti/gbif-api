library(arrow)
library(dplyr)

# Open database
gbif_dir <- "/data/db/gbif/2026-01-01"
df <- open_dataset(gbif_dir)

# Show the database schema, including column names
schema(df)

# Count the number of mammal records per year
df |>
  select( # an early select can drastically improve performance
    decimallongitude,
    decimallatitude,
    coordinateuncertaintyinmeters,
    year,
    class
  ) |>
  filter(class == "Mammalia") |>
  count(year) |>
  collect() |>
  arrange(desc(year))

# Subset the database retaining only mammal records with valid 
# coordinates, year, and spatial uncertainty < 10 km.
df |>
  select( # an early select can drastically improve performance
    decimallongitude,
    decimallatitude,
    coordinateuncertaintyinmeters,
    year,
    class
  ) |>
  filter(
    coordinateuncertaintyinmeters < 1e4,
    !is.na(decimallatitude),
    !is.na(decimallongitude),
    !is.na(year),
    class == "Mammalia"
  ) |>
  mutate(
    lon = decimallongitude,
    lat = decimallatitude,
    year,
    .keep = "none"
  ) |>
  collect()
