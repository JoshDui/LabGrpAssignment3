# Verification Report

Date: 2026-05-19

Command run:

```r
Rscript verification_checks.R
```

Scope:

- Rebuilt `meat_tidy` independently from workbook sheet `X.14`, range `A4:L36`.
- Rebuilt `pop_tidy` independently from workbook sheet `I.1`, range `A5:K15`.
- Rebuilt `merged` with `left_join()` on `country` and `year`, then `meat_per_cap = production / pop * 1000`.
- Used only `tidyverse`, `readxl`, and `waldo`.

Checks passed:

- `meat_tidy`: dimensions, column classes, row order, and `waldo::compare()` checkpoint.
- `pop_tidy`: dimensions, column classes, row order, and `waldo::compare()` checkpoint.
- `merged`: dimensions, column classes, row order, and `waldo::compare()` checkpoint.
- Cambodia correction: `Cambodia` / `mutton and goat` production is `NA` for 2018, 2019, 2020, and 2021.

Note:

- The `waldo::compare()` checkpoint uses `tolerance = 1e-10` to avoid false failures from Excel-versus-CSV floating-point representation while keeping structure, classes, and row order exact.

Result:

All independent verification checks passed.
