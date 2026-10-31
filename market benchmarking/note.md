# Reading the Market: Cleaning Decisions & Product Insights

*Separating market reach from user satisfaction to understand what app-store metrics really reveal.*

## The Question Behind the Numbers

High download counts, strong ratings, and large review volumes are often treated as signs of a successful app. However, these metrics describe different aspects of market performance.

An app may attract a large audience without receiving exceptional ratings. Another may maintain high ratings while reaching a much smaller market. Category-level averages can also hide the influence of a small number of breakout applications.

This project examines these differences using the Google Play Store Apps dataset. The objective is to prepare reliable analytical data, identify unusual engagement patterns, compare categories using robust statistics, and translate the results into practical considerations for app developers and product teams.

## Dataset & Scope

**Source:** [Google Play Store Apps — Kaggle](https://www.kaggle.com/datasets/lava18/google-play-store-apps)

**Original dataset:** 10,841 rows × 13 columns.

The dataset contains application-level information, including category, rating, review count, size, installation volume, application type, and price.

It represents a historical snapshot rather than a live market feed. Install counts are recorded in rounded listing buckets, so values such as `50,000,000+` should not be interpreted as exact download counts, current active users, or revenue.

The analysis focuses on three complementary dimensions:

- **User satisfaction:** ratings assigned to applications.
- **Market reach:** reported installation volume.
- **Engagement visibility:** the volume of user reviews.

These measures are useful together, but they are not interchangeable.

## From Raw Listings to Analytical Data

### Handling inconsistent values

The original file contains mixed formats, missing values, and records that require special treatment before numerical comparisons become meaningful.

| Field | Transformation | Analytical purpose |
|---|---|---|
| `Installs` | Remove commas and plus signs; convert to a nullable integer | Make installation buckets comparable numerically |
| `Reviews` | Convert review counts to numeric values | Quantify engagement and identify extreme observations |
| `Size` | Convert MB and KB-labelled values to a common MB scale | Support size-based analysis without mixed units |
| `Price` | Remove currency symbols and convert to a numeric value | Separate free and paid pricing information |
| `Rating` | Treat values outside the valid 1–5 range as missing | Preserve the rating scale |
| `Type` | Standardize the free/paid classification | Enable consistent monetization comparisons |

`Varies with device` is treated as missing because it does not represent one fixed numerical size. KB-labelled values are converted using a decimal scale, where 1 KB equals 0.001 MB.

### Handling missing values

Missing `Rating` and `Size` values are imputed using the corresponding category median, with the overall median as a fallback when a category has no usable value.

Category-level imputation preserves more of the differences between app segments than applying one global value to every missing observation. However, imputed values are estimates, not newly observed measurements.

The original dataset contains 1,474 missing ratings before imputation.

### Resolving duplicate applications

Duplicate app listings can distort category counts and performance summaries. Where an app appears multiple times, the record with the highest `Reviews` value is retained, with `Installs` used to resolve ties.

The initial inspection identified 1,181 duplicate rows. This rule provides a consistent way to consolidate repeated listings, although it does not establish which record was published most recently.

## Detecting Unusual Market Performance

### The IQR approach

The Interquartile Range (IQR) method is applied independently to `Reviews` and `Installs`.

\[
IQR = Q_3 - Q_1
\]

The conventional outlier fences are:

\[
Q_1 - 1.5(IQR), \qquad Q_3 + 1.5(IQR)
\]

Observations outside these bounds are flagged rather than automatically removed.

This distinction matters. An unusually large review count may represent a genuine breakout product rather than a data-quality problem. Similarly, an installation value above the upper fence may reflect exceptional reach within a particular market segment.

Outlier counts are examined by category. Outlier rates provide additional context because a category with many applications may naturally contain more outliers than a much smaller category.

## Benchmarking Categories

Category benchmarking uses medians as the primary comparison statistic.

The median is less sensitive to extreme observations than the mean, making it useful when app engagement is concentrated among a relatively small number of popular applications.

The benchmark table combines:

- Median rating, installs, and reviews.
- Number of applications in each category.
- Free/paid composition.
- Category-level outlier counts and rates.

### Defining over-performance

A category is considered a candidate over-performer when both its median rating and median installs exceed their respective cross-category median benchmarks.

The screening also requires at least 20 listings to reduce the influence of very small categories.

This is a relative ranking rule, not proof that a category guarantees successful launches. Competition, distribution, product quality, acquisition costs, and market demand are not fully captured by these metrics.

### Comparing free and paid applications

Free and paid applications are compared using median rating, installs, and reviews. Mean rating is retained as supplementary context rather than the primary measure.

The paid-rating screen highlights categories with at least 10 apps in each group where the paid median rating is at least 0.15 points higher than the free median.

This threshold identifies candidates for further investigation. It is not a statistical significance test and does not establish that charging for an app causes better ratings.

## What the Results Suggest

The preliminary descriptive figures recorded for this dataset point to several useful patterns. They should be interpreted alongside the notebook's calculated tables, particularly the median-based comparisons.

### Reach and satisfaction are different signals

The recorded correlation between `Rating` and `Reviews` is approximately \(r = 0.06\), indicating a very weak positive linear relationship.

A large review count should therefore not be treated as a reliable proxy for user satisfaction. Review volume is more useful as a measure of visible engagement and exposure, while ratings provide a separate perspective on user feedback.

### Category-level reach can be highly uneven

`Communication` was recorded as the category with the highest median installation bucket, at 50 million or more installs.

Because install values are supplied in rounded buckets, this represents a reported threshold rather than an exact count. Strong typical reach also does not establish that a new application would achieve similar results.

### Review outliers deserve investigation

The preliminary analysis recorded 847 review-count outliers, with the upper threshold above approximately 3.7 million reviews. The `GAME` category was noted for having many such observations.

This pattern is consistent with highly uneven review volume, where a limited number of applications can attract exceptional attention. Category-level outlier rates are important for determining whether the pattern is concentrated or simply reflects category size.

### App size does not explain rating differences well

The recorded correlation between `Size` and `Rating` is approximately \(r = 0.01\), indicating almost no linear relationship in this dataset.

App size alone is therefore a weak basis for predicting rating. Performance may depend on factors that this dataset does not measure, including usability, reliability, functionality, and the relevance of the app to its audience.

### Free and paid ratings require a careful comparison

The preliminary summary reports mean ratings of 4.18 for free apps and 4.26 for paid apps, a difference of 0.08 points.

This small mean difference is descriptive context, not the primary conclusion. The median-rating comparison, together with median installs, median reviews, and group sizes, provides a more appropriate basis for assessing how the two groups differ.

A higher rating among paid apps does not, by itself, demonstrate that paid pricing improves user satisfaction or that a paid business model is more commercially successful.

## Five Product-Team Takeaways

### 01 — Benchmark the intersection of satisfaction and reach

Use the over-performing category table to identify segments where both median rating and median installs exceed the cross-category benchmarks.

**Product implication:** shortlist categories that demonstrate both audience reach and user satisfaction, then investigate their competitive intensity before selecting a market.

### 02 — Investigate breakout products instead of relying on averages

The recorded review outliers and the concentration observed in `GAME` suggest that engagement can vary substantially within a category.

**Product implication:** examine successful applications individually to understand their audience, positioning, and product proposition. A category-wide average may conceal important differences between typical and exceptional apps.

### 03 — Evaluate monetization alongside audience reach

The preliminary mean-rating figures show only a modest difference between free and paid apps. The more important question is whether rating differences persist when median installs, reviews, and sample sizes are considered together.

**Product implication:** compare business models using several performance indicators rather than assuming that a higher rating makes paid distribution the better strategy.

### 04 — Treat visibility and satisfaction as separate outcomes

The very weak recorded correlation between ratings and review counts indicates that these measures capture different aspects of app performance.

**Product implication:** monitor user feedback alongside adoption metrics. High exposure may create opportunities for growth, but it should not be used as a substitute for understanding user satisfaction.

### 05 — Do not mistake a category benchmark for a launch forecast

The recorded reach of `Communication` and the near-zero relationship between app size and rating illustrate why individual metrics should be interpreted within their market context.

**Product implication:** use category benchmarks to formulate hypotheses, then investigate product differentiation, usability, reliability, and audience needs. Retention, acquisition costs, and revenue require additional data before they can be evaluated directly.

## Final Perspective

The value of this analysis lies not in producing a single ranking of app categories, but in showing why different measures of performance must be considered together.

Ratings provide one view of user satisfaction. Installs indicate reported reach. Reviews reveal visible engagement. Outliers show where performance departs substantially from the broader distribution.

Together, these measures offer a structured starting point for market exploration. They can identify promising categories and useful questions for product teams, but they cannot replace current market research or establish the causes of application success.

The central question remains:

**Which categories combine meaningful audience reach with strong user feedback, and what additional evidence would explain why some applications outperform their peers?**