# Analyst's Notes — Market Share Shift Analysis

## Scope and source audit

The analysis uses the supplied `vgsales.csv` file from the Kaggle Video Game Sales dataset. The file contains 16,598 records and 11 columns. Global and regional sales are reported in millions of copies.

The requested period is 1980–2019, divided into four calendar decades. The latest year represented in the valid source records is 2017. The 2010s results therefore cover 2010–2017 rather than the full decade.

### Row-drop report

| Stage | Rows |
|---|---:|
| Original source rows | 16,598 |
| Missing or non-numeric `Year` | 271 |
| Non-integer `Year` | 0 |
| Integer `Year` outside 1980–2019 | 1 |
| Missing `Global_Sales` within valid years | 0 |
| **Rows retained for analysis** | **16,326** |

The single out-of-range record is dated 2020. The total exclusion count is 272 rows.

There are 58 missing `Publisher` values. These rows remain in the analysis as `(unknown)` so their sales continue to contribute to the decade totals. Platform and genre labels are present in the supplied file.

### Records by decade

| Decade | Game rows | Global sales (millions) |
|---|---:|---:|
| 1980s | 205 | 376.58 |
| 1990s | 1,769 | 1,278.91 |
| 2000s | 9,208 | 4,644.02 |
| 2010s | 5,144 | 2,520.56 |

The 2000s contain the largest number of records and the highest total global sales in this dataset.

## SQL design and execution notes

The notebook creates an in-memory SQLite table named `games`. The decade field is derived in SQL as `cast((Year / 10) * 10 as integer)`. The executed SQLite version is 3.46.1.

### Window-function patterns

- **Grouped aggregate versus window aggregate:** `GROUP BY` first reduces the source to one row per platform-decade or genre-decade. `SUM(...) OVER (PARTITION BY decade)` then adds the decade denominator while preserving each segment row. Q1 and Q6 use this pattern for share of total.
- **Ranking:** Q2 applies `rank()` to platform sales within each decade and `row_number()` to create a deterministic five-row selection. The rank filter is in the outer query because the window result is not available to the same query's `WHERE` clause.
- **RANK versus DENSE_RANK versus ROW_NUMBER:** Q3 uses individual game sales. In the 1980s, Mahjong and R.C. Pro-Am both have 2.14 million sales. Both receive `rank = 34` and `dense_rank = 33`, while `row_number` assigns 34 and 35. The next sales position is `RANK = 36` and `DENSE_RANK = 34`.
- **LAG:** Q4 creates a complete platform-by-decade grid before calculating the previous share. Missing platform-decade combinations are zero, so the lag always compares consecutive calendar decades.
- **Running total:** Q5 aggregates sales by platform and year, then applies `SUM()` with `rows between unbounded preceding and current row`.
- **First and final values:** Q7 and bonus query B3 use explicit full-partition frames with `first_value()` and `last_value()`.
- **Regional shares:** Q8 uses separate North American and Japanese sales denominators. The difference is expressed in percentage points.
- **Quartiles:** B1 applies `NTILE(4)` to publishers ordered by lifetime global sales, from highest to lowest.
- **Moving average:** B2 creates a 1980–2019 calendar grid for each platform. The three-row frame therefore represents three consecutive calendar years, including zero-sales years. The first two calendar positions naturally have shorter available frames.
- **Platform lifecycle:** B3 defines meaningful sales as annual global sales greater than zero and returns each platform's first and last year meeting that condition.

### Query result sizes

| Query | Rows returned |
|---|---:|
| Q1 — Platform share | 48 |
| Q2 — Top five platforms | 20 |
| Q3 — Ranking comparison | 40 |
| Q4 — Platform share change | 93 |
| Q5 — Cumulative platform sales | 240 |
| Q6 — Genre share | 47 |
| Q7 — Genre gain and loss | 2 |
| Q8 — Regional genre share | 47 |
| Q9 — Top-three concentration | 4 |
| Q10 — Leading publisher | 4 |
| B1 — Publisher quartiles | 4 |
| B2 — Three-year moving average | 1,240 |
| B3 — Platform lifecycle | 31 |

The `-- output:` comments beneath each SQL statement contain compact summaries of the actual query results. Full result tables are retained in the notebook DataFrames.

## Market-shift findings

### Platform leadership

The leading platform changed in every decade:

| Decade | Leading platform | Sales (millions) | Share |
|---|---|---:|---:|
| 1980s | NES | 223.52 | 59.36% |
| 1990s | PS | 586.85 | 45.89% |
| 2000s | PS2 | 1,227.36 | 26.43% |
| 2010s | PS3 | 602.44 | 23.90% |

The first two transitions show substantial platform turnover. PS gained 45.89 percentage points moving into the 1990s, while NES lost 57.20 percentage points. In the 2000s, PS2 became the largest platform by decade sales. In the 2010s, PS3 led X360 by 1.80 percentage points (23.90% versus 22.10%).

The all-time platform totals from Q5 place PS2 first at 1,233.46 million sales, followed by X360 (969.61m), PS3 (949.35m), Wii (909.81m), and DS (818.67m).

### Genre transition

The genre mix changed substantially between the first and final decades.

| Genre | 1980s share | 1990s share | 2000s share | 2010s share |
|---|---:|---:|---:|---:|
| Action | 13.59% | 10.89% | 18.49% | 26.72% |
| Platform | 32.47% | 16.34% | 8.12% | 4.79% |
| Puzzle | 16.66% | 3.05% | 2.57% | 0.84% |
| Shooter | 15.88% | 5.39% | 9.36% | 18.36% |

Action recorded the largest full-period gain: +13.13 percentage points. Platform recorded the largest full-period loss: −27.68 percentage points. Puzzle also declined markedly, from 16.66% in the 1980s to 0.84% in the 2010s. Shooter recovered after its lower 1990s share and reached 18.36% in the final observed decade.

### Regional genre preferences

Regional genre shares show a persistent difference in the composition of sales.

- **1990s Role-Playing:** 8.10% of North American sales versus 26.59% of Japanese sales, a −18.49 pp NA-minus-JP difference.
- **2010s Role-Playing:** 9.67% in North America versus 33.62% in Japan, a −23.95 pp difference.
- **2010s Shooter:** 20.46% in North America versus 4.53% in Japan, a +15.93 pp difference.
- **2010s Sports:** 13.88% in North America versus 5.13% in Japan, a +8.75 pp difference.

The regional comparison uses each region's own sales total. These percentages are therefore comparisons of genre composition, not comparisons of absolute sales volume between regions.

### Market concentration

| Decade | Share held by top three platforms |
|---|---:|
| 1980s | 99.98% |
| 1990s | 75.67% |
| 2000s | 55.86% |
| 2010s | 57.03% |

The top-three share declined by 44.12 percentage points from the 1980s to the 2000s. It then increased by 1.17 points in the 2010s. Across the full first-to-final comparison, the decline was 42.95 percentage points. The 1980s market is especially concentrated in the supplied data, while the 2000s and 2010s show a broader distribution among platforms.

### Publisher leadership and sales distribution

| Decade | Leading publisher | Sales (millions) | Share of decade sales |
|---|---|---:|---:|
| 1980s | Nintendo | 234.92 | 62.38% |
| 1990s | Nintendo | 364.56 | 28.51% |
| 2000s | Nintendo | 883.89 | 19.03% |
| 2010s | Electronic Arts | 360.92 | 14.32% |

Nintendo led publisher sales in the first three decades. Its share of decade sales decreased from 62.38% in the 1980s to 11.94% in the 2010s. Electronic Arts became the leading publisher in the 2010s with a 14.32% share.

B1's quartile split contains 577 publisher groups:

| Sales quartile | Publishers | Combined sales (millions) | Average per publisher (millions) |
|---|---:|---:|---:|
| Q1 — highest sales | 145 | 8,672.50 | 59.81 |
| Q2 | 144 | 117.88 | 0.82 |
| Q3 | 144 | 24.66 | 0.17 |
| Q4 — lowest sales | 144 | 5.03 | 0.03 |

The quartile totals show a strongly uneven publisher sales distribution. Q1 contains most of the observed publisher sales, while the remaining three quartiles together account for a comparatively small share.

### Moving averages and platform lifecycles

Among the five highest-selling platforms, the largest three-calendar-year moving average values were:

| Platform | Peak year | Three-year moving average (millions) |
|---|---:|---:|
| PS2 | 2004 | 200.49 |
| Wii | 2009 | 179.86 |
| X360 | 2011 | 145.67 |
| PS3 | 2011 | 145.38 |
| DS | 2009 | 139.75 |

The lifecycle query identifies PS2 sales from 2000 through 2011, X360 from 2005 through 2016, PS3 from 2006 through 2016, Wii from 2006 through 2015, and DS from 1985 through 2014. These are the first and last years with positive sales in the filtered dataset, not necessarily the full commercial lifetimes of the platforms.

## Reconciliation with preliminary notes

Several preliminary figures differ from the executed dataset results. The SQL outputs support the following values:

- The leading 1980s genre is Platform at 32.47%, not Action at approximately 29%.
- Nintendo's 1980s publisher share is 62.38%, not 78%.
- PS2's 2000s platform share is 26.43%, not 11.8%.
- PS3 leads the 2010s at 23.90%; X360 follows at 22.10%.
- Puzzle share moves from 16.66% in the 1980s to 0.84% in the 2010s.

These figures are based on the exact supplied CSV and the decade scope described above.

## Five-point interpretation

1. **Platform turnover:** The sales leader changes from NES to PS, then PS2 and PS3. The movement is consistent with successive platform generations, although the dataset alone cannot isolate hardware launches, exclusive titles, pricing, or consumer adoption as causal factors.
2. **Genre mix:** Action becomes more prominent, while Platform and Puzzle lose share. Shooter also recovers after its lower 1990s share.
3. **Regional differences:** Role-Playing has a much larger share in Japan, while Shooter and Sports have larger shares in North America in the 2010s.
4. **Market structure:** The top-three platform share falls sharply from the highly concentrated 1980s market, reaching its lowest point in the 2000s before a modest increase in the 2010s.
5. **Publisher structure:** Nintendo leads the first three decades, but its share declines as the market becomes more distributed. Electronic Arts leads the 2010s.

## Interpretation limits

The dataset contains unit sales, not revenue, profitability, hardware prices, active users, or retention. The 2010s are incomplete because the source ends in 2017. The source also does not provide enough variables to establish causal explanations for the observed market shifts. The results describe the records in this dataset and should not be generalized to unobserved sales or the missing 2018–2019 period.
