# AI Interaction Log

Document: `CSC3107_GrpAssgmt3.qmd`
Team: SteelBlue
AI tool: ChatGPT Desktop App
Date: 2026-05-19

Team roles recorded for this submission:

- Joshua - Coder / AI Liaison
- Benjamin - Navigator
- MeiYuen - Verifier
- Dannon - Constructive Critic / Reporter
- Joshua - Packaging / Submission Lead



## Section 3.3 Prompt

```text
Write the solution using tidyverse R code.
-Transform meat_raw into a tidy tibble named meat_tidy.
-Before tidying, remove the aggregate ASEAN data and remove the Total meat production data because they are summary values and should not be included in tidy data.
-The final tibble must have exactly four columns in this order: country, year, animal, production.
-The animal values must be lower-case and must match exactly: "beef and buffalo", "mutton and goat", "pig", and "poultry".
The production column contains values in thousands of metric tons.
-Sort the rows in descending order by year, from 2021 to 2018.
-Break ties in ascending alphabetical order, first by animal and then by country.
-The first row of meat_tidy must represent Brunei Darussalam's 2021 beef-and-buffalo production, 4.26741.
-Show the first and last six rows of meat_tidy to confirm the sorting is correct.
```

Response:

Here is one tidyverse approach. The main idea is to keep the year labels as a real variable, fill them down to the animal rows, drop summary values, and then pivot the country columns into one country column.

```r
meat_tidy <- meat_raw |>
  rename(animal = `Animal Type`) |>
  select(-ASEAN) |>
  mutate(year = as.numeric(str_extract(animal, "^\\d{4}$"))) |>
  fill(year) |>
  filter(animal %in% c(
    "Beef and Buffalo Meat",
    "Mutton and Goat Meat",
    "Pig meat",
    "Poultry meat"
  )) |>
  pivot_longer(
    cols = -c(animal, year),
    names_to = "country",
    values_to = "production"
  ) |>
  mutate(
    animal = recode(
      animal,
      "Beef and Buffalo Meat" = "beef and buffalo",
      "Mutton and Goat Meat" = "mutton and goat",
      "Pig meat" = "pig",
      "Poultry meat" = "poultry"
    ),
    production = as.numeric(production)
  ) |>
  select(country, year, animal, production) |>
  arrange(desc(year), animal, country)

head(meat_tidy)
tail(meat_tidy)
```

This removes the ASEAN aggregate column and does not include the total meat production row because the `filter()` step keeps only the four detailed animal categories. The final ordering puts 2021 first, then sorts ties by animal and country, so the first row should be Brunei Darussalam's 2021 beef-and-buffalo value.

## Section 3.4 Prompt

```text
-Update meat_tidy so that production becomes NA only when:
country == "Cambodia",
animal == "mutton and goat",
and year is between 2018 and 2021.
-Do not overwrite any other zero values in the table.
-Use tidyverse R code and print all rows where country == "Cambodia" and animal == "mutton and goat" to confirm the values are now NA.
-Also write a short QMD justification explaining why this targeted replacement
```

Response:

Use a targeted `mutate()` so that only Cambodia's mutton-and-goat observations from 2018 to 2021 are changed to `NA`. Other zero values should be left as zero because they may represent real recorded zero production.

```r
meat_tidy <- meat_tidy |>
  mutate(
    production = if_else(
      country == "Cambodia" &
        animal == "mutton and goat" &
        between(year, 2018, 2021),
      NA_real_,
      production
    )
  )

meat_tidy |>
  filter(country == "Cambodia", animal == "mutton and goat")
```

QMD justification:

The replacement is targeted because the Cambodia mutton-and-goat entries for 2018 to 2021 are unavailable rather than confirmed zero values. Setting only these four observations to `NA` preserves the distinction between missing data and true zero production, while leaving all other zero values unchanged for later calculations.

## Section 3.6 Prompt

```text
-Write the solution using tidyverse R code.
-Import sheet I.1, "Number of Population in ASEAN, 2013-2022", as pop_raw.
-Remove the ASEAN aggregate row.
-Tidy pop_raw into a tibble named pop_tidy with exactly three columns, in this order:
country, year, population.
-The population values are in thousands.
-Sort the rows in descending order by year.
-Break ties in ascending alphabetical order by country.
-The first row of pop_tidy must be Brunei Darussalam's 2022 population, 445.4.
-Show the first and last six rows of pop_tidy to confirm the sorting is correct.
```

Response:

The population table can be tidied by removing the ASEAN aggregate row, pivoting the year columns into a single `year` column, and converting the population values to numeric.

```r
pop_raw <- read_xlsx(
  "ASEAN-Statistical-Yearbook-2023.xlsx",
  sheet = "I.1",
  range = "A5:K16"
)

pop_tidy <- pop_raw |>
  rename(country = Country) |>
  filter(country != "ASEAN") |>
  pivot_longer(
    cols = -country,
    names_to = "year",
    values_to = "population"
  ) |>
  mutate(
    year = as.numeric(year),
    population = as.numeric(population)
  ) |>
  select(country, year, population) |>
  arrange(desc(year), country)

head(pop_tidy)
tail(pop_tidy)
```

Since the years are sorted in descending order and countries are sorted alphabetically within each year, the first row should be Brunei Darussalam in 2022 with a population value of 445.4.

## Section 3.8 Prompt

```text
Write the tidyverse R code and briefly explain why left_join() is the correct
-meat_tidy has these columns:
country, year, animal, production
-pop_tidy has these columns:
country, year, population
-Create a new tibble named merged by joining pop_tidy onto meat_tidy.
-Use left_join() because meat_tidy is the main table and every row from meat_tidy must be kept.
-Join using both country and year as the matching keys:
by = c("country", "year")
-After joining, rename the population column to pop.
-The final merged tibble must have columns in this exact order:
country, animal, year, production, pop
-Do not change the row order from meat_tidy.
```

Response:

Use `left_join()` with `meat_tidy` on the left because `meat_tidy` is the main analysis table. This keeps every country, animal, and year row from `meat_tidy` and only adds the matching population value where the same `country` and `year` are found in `pop_tidy`.

```r
merged <- meat_tidy |>
  left_join(pop_tidy, by = c("country", "year")) |>
  rename(pop = population) |>
  select(country, animal, year, production, pop)

merged
```

Joining by both `country` and `year` is necessary because each country has several years of population data. A `left_join()` is appropriate here because it preserves the row order and full set of rows from `meat_tidy`, which is the table being extended with population.

## Section 3.9 Prompt

```text
Write the solution using tidyverse R code.
Show the first and last six rows to check the result.
-Add a new column named meat_per_cap to merged.
-meat_per_cap should represent meat production in kilograms per person.
-Use this formula:
meat_per_cap = production / pop * 1000
-Rows where production is NA, such as Cambodia mutton and goat, should remain NA in meat_per_cap.
```

Response:

Because production is measured in thousands of metric tons and population is measured in thousands of people, the thousands cancel out when dividing production by population. The result is metric tons per person, so multiplying by 1000 converts it to kilograms per person.

```r
merged <- merged |>
  mutate(
    meat_per_cap = production / pop * 1000
  )

head(merged)
tail(merged)
```

Rows with missing production values will automatically produce `NA` for `meat_per_cap`, so the Cambodia mutton-and-goat rows remain missing rather than being converted to zero.
