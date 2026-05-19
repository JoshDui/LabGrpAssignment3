suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(waldo)
})

workbook_path <- "ASEAN-Statistical-Yearbook-2023.xlsx"

expected_countries <- c(
  "Brunei Darussalam", "Cambodia", "Indonesia", "Lao PDR", "Malaysia",
  "Myanmar", "Philippines", "Singapore", "Thailand", "Viet Nam"
)

expected_animals <- c(
  "beef and buffalo",
  "mutton and goat",
  "pig",
  "poultry"
)

numeric_tolerance <- 1e-10

expect_no_diff <- function(label, actual, expected) {
  diff <- compare(actual, expected, tolerance = numeric_tolerance)
  if (length(diff) > 0) {
    cat("\n", label, " waldo diff:\n", sep = "")
    print(diff)
    stop(label, " did not match reference", call. = FALSE)
  }
  cat("[PASS] ", label, " waldo compare matched reference\n", sep = "")
}

expect_identical_value <- function(label, actual, expected) {
  if (!identical(actual, expected)) {
    cat("\n", label, " actual:\n", sep = "")
    print(actual)
    cat(label, " expected:\n", sep = "")
    print(expected)
    stop(label, " failed", call. = FALSE)
  }
  cat("[PASS] ", label, "\n", sep = "")
}

meat_raw <- suppressMessages(
  read_excel(
    workbook_path,
    sheet = "X.14",
    range = "A4:L36",
    col_names = FALSE,
    .name_repair = "unique"
  )
)

meat_country_cols <- meat_raw |>
  slice(1) |>
  select(2:11) |>
  unlist(use.names = FALSE) |>
  as.character()

meat_tidy <- meat_raw |>
  select(1:11) |>
  set_names(c("animal_type", meat_country_cols)) |>
  mutate(
    year = suppressWarnings(as.numeric(animal_type))
  ) |>
  fill(year) |>
  filter(animal_type %in% c(
    "Beef and Buffalo Meat",
    "Mutton and Goat Meat",
    "Pig meat",
    "Poultry meat"
  )) |>
  mutate(
    animal = recode(
      animal_type,
      "Beef and Buffalo Meat" = "beef and buffalo",
      "Mutton and Goat Meat" = "mutton and goat",
      "Pig meat" = "pig",
      "Poultry meat" = "poultry"
    )
  ) |>
  select(animal, year, all_of(expected_countries)) |>
  mutate(across(all_of(expected_countries), as.character)) |>
  pivot_longer(
    cols = all_of(expected_countries),
    names_to = "country",
    values_to = "production"
  ) |>
  mutate(
    production = as.numeric(production),
    production = if_else(
      country == "Cambodia" & animal == "mutton and goat",
      NA_real_,
      production
    )
  ) |>
  select(country, animal, year, production) |>
  arrange(
    desc(year),
    factor(animal, levels = expected_animals),
    factor(country, levels = expected_countries)
  )

pop_raw <- suppressMessages(
  read_excel(
    workbook_path,
    sheet = "I.1",
    range = "A5:K15",
    col_names = FALSE,
    .name_repair = "unique"
  )
)

pop_year_cols <- pop_raw |>
  slice(1) |>
  select(-1) |>
  unlist(use.names = FALSE) |>
  as.character()

pop_tidy <- pop_raw |>
  slice(-1) |>
  set_names(c("country", pop_year_cols)) |>
  mutate(across(all_of(pop_year_cols), as.character)) |>
  pivot_longer(
    cols = all_of(pop_year_cols),
    names_to = "year",
    values_to = "pop"
  ) |>
  mutate(
    year = as.numeric(year),
    pop = as.numeric(pop)
  ) |>
  select(country, year, pop) |>
  arrange(desc(year), factor(country, levels = expected_countries))

merged <- meat_tidy |>
  left_join(pop_tidy, by = c("country", "year")) |>
  mutate(meat_per_cap = production / pop * 1000)

meat_ref <- read_csv("meat_tidy_reference.csv", show_col_types = FALSE)
pop_ref <- read_csv("population_tidy_reference.csv", show_col_types = FALSE)
merged_ref <- read_csv("merged_reference.csv", show_col_types = FALSE)

expect_identical_value(
  "meat_tidy dimensions",
  dim(meat_tidy),
  c(160L, 4L)
)
expect_identical_value(
  "pop_tidy dimensions",
  dim(pop_tidy),
  c(100L, 3L)
)
expect_identical_value(
  "merged dimensions",
  dim(merged),
  c(160L, 6L)
)

expect_identical_value(
  "meat_tidy classes",
  map_chr(meat_tidy, ~ class(.x)[1]),
  c(country = "character", animal = "character", year = "numeric", production = "numeric")
)
expect_identical_value(
  "pop_tidy classes",
  map_chr(pop_tidy, ~ class(.x)[1]),
  c(country = "character", year = "numeric", pop = "numeric")
)
expect_identical_value(
  "merged classes",
  map_chr(merged, ~ class(.x)[1]),
  c(
    country = "character",
    animal = "character",
    year = "numeric",
    production = "numeric",
    pop = "numeric",
    meat_per_cap = "numeric"
  )
)

cambodia_na_check <- meat_tidy |>
  filter(country == "Cambodia", animal == "mutton and goat") |>
  summarise(
    years = str_c(sort(year), collapse = ","),
    all_na = all(is.na(production)),
    n = n(),
    .groups = "drop"
  )

expect_identical_value(
  "Cambodia mutton/goat production corrected to NA for 2018-2021",
  cambodia_na_check,
  tibble(years = "2018,2019,2020,2021", all_na = TRUE, n = 4L)
)

expect_identical_value(
  "meat_tidy row order",
  meat_tidy |> select(country, animal, year),
  meat_ref |> select(country, animal, year)
)
expect_identical_value(
  "pop_tidy row order",
  pop_tidy |> select(country, year),
  pop_ref |> select(country, year)
)
expect_identical_value(
  "merged row order",
  merged |> select(country, animal, year),
  merged_ref |> select(country, animal, year)
)

expect_no_diff("meat_tidy", meat_tidy, meat_ref)
expect_no_diff("pop_tidy", pop_tidy, pop_ref)
expect_no_diff("merged", merged, merged_ref)

cat("\nAll independent verification checks passed.\n")
