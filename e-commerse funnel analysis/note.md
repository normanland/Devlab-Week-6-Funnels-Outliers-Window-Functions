# Reading a funnel without confusing exposure for intent

*A measurement memo for product, growth, and analytics stakeholders*

## Before discussing conversion

The dataset is an event log. Each row is an action, not a user, an order, a cart, or a session. A busy shopper can generate many views. Calling `purchase events ÷ view events` a *user conversion rate* would therefore answer the wrong question.

For the primary funnel, the unit is a **user-month journey**. January and February are deliberately evaluated independently: users present in both months may be counted once in each. This is **not** a claim about globally distinct users across both months.

The evidence hierarchy in this analysis is: **event audit → ordered user journey → segment comparisons → opportunity screening → experiment design**. Each step is bound by the quality and granularity of its input data.

## Reconstructing an observed path

The pipeline searches the month-specific record of each user for their earliest observed `view`, then for the earliest `cart` at or after that view, then for a `purchase` at or after the eligible cart. The archive's timestamps resolve only to seconds, so equal-second occurrences are permitted. Chronological matching is independent of the physical CSV row order.

The event objects need not refer to the same product. This tracks **progression of the user's shopping behaviour**, not a matched-product conversion or checkout of one specific SKU. A purchase with no qualifying earlier view and cart remains in event participation but cannot enter the completed **ordered** path. Cross-month journeys are intentionally excluded.

| Metric | Numerator | Denominator |
|---|---|---|
| Ordered view → cart | User-month journeys reaching a qualifying cart | User-month journeys with an observed view |
| Ordered cart → purchase | User-month journeys reaching a purchase after the eligible cart | Journeys reaching a qualifying cart |
| Ordered view → purchase | Completed ordered journeys | User-month journeys with an observed view |
| Category view → purchase | Viewers who also purchased under the same `category_code` | Distinct viewers of that `category_code` |
| Brand view → purchase | Viewers who also purchased under the same `brand` | Distinct viewers of that `brand` |
| Cart-removal signal | `remove_from_cart` event count | `cart` event count |

The category and brand metrics use **unordered overlap**, unlike the primary funnel. They cannot be substituted into its transition rates, and a customer can appear in several categories or brands. The cart-removal measure is a volume ratio, never a customer-level abandonment probability.

## Where data quality changes the answer

The notebook checks category and brand tagging coverage, missing IDs, invalid timestamps and nonpositive event prices. **Unlabelled events remain in the overall funnel**. Category and brand comparisons operate only on rows with the corresponding label, with the coverage visible in the audit.

- The eight categories are selected by **raw view-event volume**, not user count.
- The ten brands are selected by **raw purchase-event volume**, not transaction value.
- The five-brand concentration ratio uses **all purchase events** as its denominator, including unlabelled brands.
- An event-price outlier is not necessarily erroneous or fraudulent; no record is deleted for being expensive.

**Why this matters:** aggressively filling absent labels with a guessed category—or ranking only labelled purchases while ignoring missing-label volume—would exaggerate confidence and bias the prioritisation of marketing budget.

## Screening products without overstating the evidence

The product shortlist begins with items at or above the 90th percentile of view-event volume. Among these higher-exposure items, it highlights those in the bottom quartile of the **purchase-event / view-event ratio**. This flags an interesting contrast between attention and recorded buying actions, **not an estimate of each visitor's probability of purchasing**. Event ratios can be skewed by returning visitors, repeat views and observation-window truncation.

The follow-up review should first test product availability, descriptions, photography, delivery promises, price positioning, reviews and search relevance. These competing explanations require information not present in the supplied CSVs.

## Prices, outliers, and buying speed

Purchase-event prices are treated as **item-event amounts**. Without order IDs and basket reconstruction, calling the mean price an *average order value* would be incorrect. The IQR fence follows `Q1 − 1.5 × IQR` and `Q3 + 1.5 × IQR`; the notebook reports the flagged share and retains the original prices. The paired chart uses a log price axis to show the long tail without hiding the main distribution.

The latency sample includes only customers with a qualifying **ordered path**. Time is computed from their first observed view to the first eligible purchase within the same month, potentially across different products. This is not a universal time-to-buy estimate, and it excludes users for whom earlier activity was not observed. Median and upper quantiles are highlighted because long journeys can distort the arithmetic mean.

## Interpretation guide for the growth team

**Discovery friction.** A weak transition between viewing and carting calls for examining the product-detail page, price transparency, search relevance and stock visibility. Start with high-volume placements to maximise impact, then use controlled tests to establish causality.

**Checkout friction.** Users who place something in a cart but never produce an observed purchase may be responding to shipping fees, payment UX, delivery uncertainty or simply a longer decision cycle. Instrument checkout stages before identifying the cause.

**Segment measurement.** A category with strong observed overlap is not necessarily the most attractive commercial segment when the bulk of the catalogue has no category label. The correct next move may be improving tagging completeness rather than buying media.

**Brand portfolio.** Separate raw scale from conversion efficiency. A brand can dominate purchase-event counts because it has high exposure, not because it is unusually effective at converting browsers into customers.

**Rescue opportunities.** The product shortlist gives merchandisers a place to investigate but does not justify instant discounts. Compare each candidate with matched alternatives in availability, price and content before changing the offer.

## The next measurement, not just the next dashboard

A defensible abandonment metric needs cart/session boundary definitions and a checkout lifecycle. An exact-product journey needs product-matched chronological sequences. Average order value needs an order or transaction ID. Marketing attribution needs channel or campaign IDs; causal inference needs experiment assignment or credible quasi-experimental design.

A February lift or decline, by itself, establishes **association with time**, not the impact of a specific decision.

## Observed evidence from this run

<!-- VERIFIED_METRICS_START -->

**Source and exposure.** The provided January file contains **4,264,752 events** and February contains **4,156,682**, a total of **8,421,434 events**. Category tagging covers only **1.75%** of January rows and **1.86%** of February rows. That is the first major warning for category-specific decisions: any observed category ranking covers a very small and likely nonrandom subset of activity.

**Where the journey narrows.** The ordered funnel includes **777,021 view-stage user-month journeys**, **147,684 eligible carts**, and **48,528 observed purchases**. Conversion is **19.01%** from view to cart, **32.86%** from eligible cart to purchase, and **6.25%** end-to-end. Approximately **629,337 viewer journeys (81.0%)** do not reach a qualifying cart—making product discovery and consideration the largest absolute recorded loss. This is not proof that page design caused the loss.

**Month-to-month direction.** End-to-end ordered conversion moved from approximately **6.39% in January** to **6.09% in February**, a **0.30 percentage-point decline**, not an improvement. Cohort composition, product mix, and incomplete observation can explain a movement even without changes to the user experience. The screenshot's illustrative percentages should not replace the recomputed values; its stated event volumes also differ from the actual supplied CSVs.

**Merchandising signal.** The top five labelled brands account for **25.3% of all purchase events**. Within the tagged top-eight category subset, `apparel.glove` has the strongest measured view-and-purchase user overlap at **18.4%**. Neither statistic alone establishes incremental profitability or an acquisition budget allocation. Product `5808664` has **17,194 view events and 23 purchase events**, a **0.13% purchase/view event ratio**, and warrants investigation for visibility, pricing, stock, or content issues—not an automatic markdown.

**Distribution matters.** Median purchase-event price is **$3.02**, while the IQR upper fence is **$11.52**. The method flags **34,947 purchase events (6.9%)** as possible outliers, without deleting them. Among **48,528** eligible converted journeys, median observed view-to-purchase delay is **3.35 hours**, while the mean is **77.65 hours**; slow journeys create a long tail. Use the median for a more typical timeline and the high quantiles for edge-case diagnostics.

**Additional signal.** Recorded cart-removal actions represent approximately **71% of cart-event volume** in each month. This is a behavioural volume comparison, *not* evidence that 71% of visitors abandoned checkout.

**Suggested experimental sequence:** strengthen category tagging and instrumentation first; investigate high-exposure items and product detail usability; instrument checkout as a separate journey; use a controlled test before attributing lifts to merchandising changes.

<!-- VERIFIED_METRICS_END -->

## Verification record

The final notebook was executed from top to bottom against the **bundled** two-month archive: all **13 code cells completed without errors**, all **seven PNG charts** were written, and its internal count/rate assertions passed. As an independent cross-check, a second event-by-event chronological state machine was compared against the vectorised aggregation on a **150,000-event sample from each month** (300,000 events total). View, eligible-cart and eligible-purchase counts matched in both months using the documented same-second tie rule. The cross-check verifies the sample-level matching logic; it is not a substitute for the full-file audit above.
