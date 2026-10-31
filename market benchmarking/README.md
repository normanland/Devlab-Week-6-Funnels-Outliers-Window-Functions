# App Store Market Benchmarking

*Beyond download counts: uncovering category leaders, statistical outliers, and free-versus-paid dynamics.*

## Project Overview

App performance cannot be understood through downloads or ratings alone. A large category may attract millions of installs while individual apps receive very different user ratings. Meanwhile, paid apps may earn slightly higher ratings without reaching the same audience as free alternatives.

This project explores the Google Play Store Apps dataset to examine these relationships, identify unusual engagement patterns, and benchmark app categories against one another.

The goal is to move beyond raw store metrics and uncover patterns that can inform product positioning, category selection, and competitive analysis.

## Research Questions

- Which app categories combine strong user ratings with high install volumes?
- How do free and paid apps compare in ratings, reviews, and installs?
- Which categories contain unusually high review counts or install volumes?
- Where do paid apps achieve higher median ratings than free apps?
- What patterns can product teams use to identify promising market segments?

## Dataset

**Source:** [Google Play Store Apps — Kaggle](https://www.kaggle.com/datasets/lava18/google-play-store-apps)

The dataset contains app-level information, including category, rating, review count, app size, installation volume, content rating, app type, and price.

The data represents a historical snapshot of the Google Play Store rather than a live view of current market conditions.

## Analytical Workflow

### 01 — Data Preparation

Raw store metrics are converted into analysis-ready fields:

- **Installs:** remove formatting characters and convert to numeric values.
- **Reviews:** convert review counts to numeric values.
- **Size:** standardize units into a common measurement scale.
- **Price:** remove currency symbols and convert to numeric values.
- **Rating and Size:** fill missing values using category-level medians.
- **Duplicate apps:** retain the record with the highest review count for each app.

These steps establish a consistent basis for category-level comparison.

### 02 — Outlier Detection

The Interquartile Range (IQR) method is used to identify unusually high or low values in review counts and installs.

Outlier counts are examined across app categories to explore where engagement is especially concentrated and where a small number of apps may stand apart from the broader market.

An outlier is treated as an analytical signal, not automatic proof of an incorrect record.

### 03 — Market Benchmarking

Categories are compared using median ratings and median install counts, alongside the distribution of free and paid apps.

The analysis also compares free and paid apps by median rating, installs, and reviews. Categories are assessed for strong performance across both user satisfaction and market reach, with the five most promising category benchmarks highlighted.

### 04 — Visual Analysis

The notebook uses visualizations to make category differences and distribution patterns easier to interpret:

- **Review outliers by category:** highlights variation in review volume and unusually high values.
- **Free vs. paid ratings:** compares rating distributions by app type.
- **Median installs by category:** shows differences in typical category reach.
- **Rating distributions before and after cleaning:** illustrates how data preparation affects the observed distribution.
- **Category positioning bubble chart:** compares median rating with log-scaled median installs, using bubble size to represent the number of apps in each category.

A further comparison identifies categories in which paid apps have notably higher median ratings than free apps.

## Key Takeaways for Product Teams

The findings can support five practical areas of decision-making:

1. **Category selection** — distinguish categories with strong ratings and substantial reach from those with only one of these advantages.
2. **Competitive positioning** — compare an app with relevant category benchmarks rather than store-wide averages.
3. **Monetization strategy** — examine whether paid apps differ from free alternatives in ratings, reviews, and installs.
4. **Market concentration** — investigate categories where a small number of apps account for unusually large engagement volumes.
5. **Opportunity discovery** — identify categories where user satisfaction and install potential align.

These are descriptive insights from the available dataset; they do not establish that one metric causes another.

## Project Files

- `App Store Market Benchmarking.ipynb` — data preparation, outlier detection, category benchmarking, comparisons, and visual analysis.
- `note.md` — explanation of the analytical choices and interpretation of the findings.
- `googleplaystore.csv` — the source dataset, downloaded separately from Kaggle.

## Getting Started

Install the required Python libraries:

```bash
pip install pandas numpy matplotlib seaborn jupyter
```

Download the dataset from Kaggle and place the CSV file in your Windows `Downloads` folder. The notebook's data-loading cell searches that folder and its subfolders for a filename containing `googleplaystore`.

Open `App Store Market Benchmarking.ipynb` in VS Code or Jupyter Notebook and run the cells in order.

## Final Perspective

The central question is not simply which category gets the most downloads. It is **which categories balance user satisfaction, market reach, and competitive opportunity — and what the differences between free and paid apps reveal about those markets.**