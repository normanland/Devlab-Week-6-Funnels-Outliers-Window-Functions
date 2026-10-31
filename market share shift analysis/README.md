# Market Share Shift Analysis with SQL Window Functions

## Overview

This project examines how the video game market changed across the 1980s, 1990s, 2000s, and 2010s. The analysis focuses on platform and genre market share, period-over-period movement, platform concentration, regional genre preferences, publisher leadership, and platform sales lifecycles.

SQLite window functions are the primary analytical method. Python prepares the source data, executes the SQL statements, checks the result tables, and builds the visualizations. The calculations for market share, ranking, `lag()` comparisons, cumulative sales, and moving averages are performed in SQL.

## Dataset

**Source:** [Video Game Sales — Kaggle](https://www.kaggle.com/datasets/gregorut/videogamesales)

The supplied `vgsales.csv` contains 16,598 game records and 11 columns. It includes platform, genre, publisher, release year, regional sales, and global sales. Sales are expressed in millions of copies, not monetary revenue.

### Data preparation

| Data-quality step | Rows |
|---|---:|
| Original source rows | 16,598 |
| Missing or non-numeric year | 271 |
| Non-integer year | 0 |
| Integer year outside 1980–2019 | 1 |
| Missing global sales among valid-year rows | 0 |
| **Final analysis rows** | **16,326** |

The excluded out-of-range record is from 2020. The valid source years run from 1980 through 2017. As a result, the 2010s decade contains 2010–2017 observations only; 2018 and 2019 are not represented in the supplied file.

There are 58 missing publisher labels. Those records remain in the analysis under the `(unknown)` publisher category rather than being removed.

## Technology

- **Python 3**
- **Jupyter Notebook**
- **pandas** for data preparation and query-result handling
- **SQLite 3.25+** for CTEs and window functions
- **matplotlib** for the charts

The notebook uses an in-memory SQLite database. No separate database file is required.

## Project files

| File | Purpose |
|---|---|
| `vgsales.csv` | Source dataset |
| `queries.sql` | Ten required SQL queries and three bonus queries, each followed by its executed output summary |
| `Market Share Shift Analysis.ipynb` | Data preparation, SQLite setup, SQL execution, result checks, narrative, and seven charts |
| `note.md` | Detailed analytical findings, technical decisions, and interpretation boundaries |
| `README.md` | Project overview and run instructions |

All files are designed to remain in the same project directory.

## Analysis coverage

### Required SQL analysis

- **Q1 — Platform share:** platform sales and decade totals with `sum() over (partition by decade)`.
- **Q2 — Platform ranking:** `rank()` and `row_number()` in a CTE, with top-five filtering in the outer query.
- **Q3 — Ranking semantics:** a real tied-sales example comparing `rank()`, `dense_rank()`, and `row_number()`.
- **Q4 — Share movement:** `lag()` compares each platform's share with the previous decade. A complete platform-decade grid represents missing combinations as zero.
- **Q5 — Running totals:** cumulative platform sales by year with an explicit `rows between unbounded preceding and current row` frame.
- **Q6 — Genre share:** genre-level share of global sales by decade.
- **Q7 — Genre gain and loss:** `first_value()` and `last_value()` compare first- and final-decade genre shares.
- **Q8 — Regional mix:** North American and Japanese genre shares use separate regional denominators.
- **Q9 — Concentration:** `row_number()` selects the three leading platforms before their combined share is calculated.
- **Q10 — Publisher leadership:** `row_number()` selects the leading publisher in each decade.

### Bonus analysis

- `NTILE(4)` divides publishers into lifetime-sales quartiles.
- A recursive calendar-year grid supports a three-calendar-year moving average with `rows between 2 preceding and current row`.
- The top-three platform share tracks market concentration over time.
- `first_value()` and `last_value()` identify each platform's first and final year of positive sales.

## Main findings

- Platform leadership changed from **NES (59.36%)** in the 1980s to **PS (45.89%)** in the 1990s, **PS2 (26.43%)** in the 2000s, and **PS3 (23.90%)** in the 2010s.
- The largest single-transition platform gain was **PS: +45.89 percentage points** into the 1990s. The largest loss was **NES: −57.20 percentage points** over the same transition.
- The **Action** genre gained the most share between the first and final decades, rising from **13.59% to 26.72% (+13.13 pp)**. The **Platform** genre recorded the largest loss, falling from **32.47% to 4.79% (−27.68 pp)**.
- In the 2010s, Role-Playing accounted for **33.62% of Japanese sales** and **9.67% of North American sales**. Shooter showed the opposite regional pattern: **20.46% in North America** and **4.53% in Japan**.
- The top-three platform share fell from **99.98%** in the 1980s to **55.86%** in the 2000s, then edged up to **57.03%** in the 2010s.
- Nintendo led publisher sales in the first three decades. Electronic Arts led in the 2010s.

The full numerical evidence and interpretation boundaries are documented in `note.md`.

## Visualizations

The notebook contains seven charts, each with a separate analytical purpose:

1. Stacked area chart of platform share, with the leading platforms from each decade shown separately.
2. Heatmap of platform share changes between consecutive decades.
3. Grouped bar chart of genre share by decade.
4. Cumulative sales curves for the five highest-selling platforms.
5. North American versus Japanese genre-share comparison for the 2010s.
6. Top-three platform concentration by decade.
7. Publisher average sales by `ntile()` quartile, displayed on a logarithmic scale.

## Running the project

The project files are expected to be in one directory.

```bash
python -m pip install pandas matplotlib jupyter
jupyter lab
```

Open `Market Share Shift Analysis.ipynb` from that directory and execute the notebook from top to bottom. The notebook loads `vgsales.csv`, creates the in-memory `games` table, derives the decade field, and reads the statements from `queries.sql`.

SQLite is included with Python through the `sqlite3` standard-library module. The notebook checks the SQLite version before executing the window-function queries.

## Methodological boundaries

The dataset measures reported unit sales. It does not contain revenue, profit, active users, player retention, hardware pricing, or enough information to isolate the causes of platform adoption and genre preference. Market-share changes are descriptive patterns in this dataset, not proof of causation.

The 2010s comparison is incomplete because the supplied data ends in 2017. Any interpretation of that decade should retain this limitation.
