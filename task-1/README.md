# The Distance Between Interest and Purchase

**DevLab / Week 6 — E-commerce funnel analysis**  
*Python · pandas · matplotlib · seaborn · customer journey analytics*

A product can be viewed repeatedly, saved to a cart, and still never purchased. This investigation follows the evidence from raw event logs to an observed **view → cart → purchase** journey, then asks a more useful question: **where should a growth team investigate friction first?**

Rather than presenting click totals as conversion rates, the analysis separates event volume from distinct users and chronological progression. That distinction shapes every chart and recommendation.

![The ordered customer journey](visuals/funnel_user_journey.png)

## Start here

For the simplest experience, **open `Open_Report.html` in any browser**. It contains the full analysis, tables and charts, works offline, and requires no Python setup. For editable code, open **`Funnel_Analysis.ipynb`**, which is **already fully executed** with the January and February 2020 dataset. To reproduce its results, select **Run → Run All Cells** in JupyterLab.

The required two-month source archive is included at `data/source_data.zip`. There is **nothing to extract or manually rename**. It contains only the two months used by the assignment, not the other three months in the original download.

If Jupyter is not installed, run `pip install -r requirements.txt` once. On Windows you can start JupyterLab from this folder by double-clicking `open_notebook.bat` (Python and the packages must already be available).

## What the data actually showed

Across **8,421,434 recorded events**, the ordered user-month funnel has **777,021 viewers**, **147,684 eligible carts**, and **48,528 qualifying purchasers**. Overall ordered conversion is **6.25%**; February is **0.30 percentage points below January**, not above it. Category labels appear in fewer than **2%** of events, so category conclusions are explicitly treated as limited evidence. These measurements are derived from the supplied CSVs and do not borrow the example percentages from the task description.

## What the project answers

| Lens | Real question | Measurement |
|---|---|---|
| Source integrity | Are we measuring what the event log contains? | Event counts, null-label coverage, timestamp checks |
| Observed journeys | How far do viewers actually progress? | Chronologically ordered user-month funnel |
| Conversion leakage | Which transition loses the most eligible customers? | Stage-to-stage drop-off in users and percent |
| Category context | Which tagged categories show more cross-stage activity? | Label-matched user overlaps for the top eight categories |
| Month-on-month change | Did observed conversion move in February? | Monthly funnel rates and percentage-point deltas |
| Brand scale | Do big purchase brands also convert viewers? | Top ten brands by purchase events and brand overlap |
| Product friction | Which visible products deserve investigation? | High exposure / low purchase-event ratio candidates |
| Price and speed | Are extreme amounts and long delays distorting averages? | IQR outliers; observed time to purchase |
| Cart removal | What else might indicate friction? | Removal event-volume diagnostic, **not** an abandonment rate |

## Explore the visuals

Seven full-resolution PNGs live in [`visuals/`](visuals/) and also appear inside the notebook. They are named by the business question they answer, rather than by chart numbers.

- [`funnel_user_journey.png`](visuals/funnel_user_journey.png) — who reached each eligible stage.
- [`transition_dropoff.png`](visuals/transition_dropoff.png) — how much progress was lost between stages.
- [`category_conversion.png`](visuals/category_conversion.png) — overlap conversion for the best-observed categories.
- [`monthly_conversion.png`](visuals/monthly_conversion.png) — January versus February, using consistent denominators.
- [`brand_purchase_ranking.png`](visuals/brand_purchase_ranking.png) — purchasing-event concentration across brands.
- [`product_friction.png`](visuals/product_friction.png) — high-exposure products with weak purchase event signals.
- [`price_and_purchase_latency.png`](visuals/price_and_purchase_latency.png) — purchase-price tails and buying-time distributions.

## What these results cannot claim

The primary funnel is built from **unique user-month observations**. It requires an observed view, then a qualifying cart, then a purchase; the products may differ. A customer active in both months can contribute two journeys. Category and brand rates measure users who interacted with the **same category/brand** within the reporting window, but not necessarily in order. Missing category labels limit how far these findings generalise.

Recorded purchase prices are item-event prices, **not basket totals**. The `remove_from_cart / cart` event ratio is **not** an abandonment rate. January–February differences are observational and should not be attributed to any intervention without a controlled study.

The companion [`note.md`](note.md) explains numerator/denominator choices, dataset quality, the product shortlist, outlier logic, and business follow-up actions.

## Folder structure

```text
task 1/
├── Open_Report.html     # double-click browser report; no Python needed
├── Funnel_Analysis.ipynb
├── README.md
├── note.md
├── requirements.txt
├── open_notebook.bat
├── visuals/
│   ├── funnel_user_journey.png
│   ├── transition_dropoff.png
│   ├── category_conversion.png
│   ├── monthly_conversion.png
│   ├── brand_purchase_ranking.png
│   ├── product_friction.png
│   └── price_and_purchase_latency.png
└── data/
    └── source_data.zip      # only 2020-Jan.csv + 2020-Feb.csv
```

**Dataset:** [Kaggle · E-commerce events history in a cosmetics shop](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop). The original archive supplied for this assignment is reduced to the two required months for straightforward reproducibility.

The objective is a defensible growth hypothesis supported by traceable measurements—not simply a complete set of charts.
