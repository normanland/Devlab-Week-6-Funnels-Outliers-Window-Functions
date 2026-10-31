-- market share shift analysis | sqlite 3.25+
-- sales are measured in millions of copies, as provided by the source dataset.
-- analysis window: 1980-2019, grouped into the 1980s, 1990s, 2000s, and 2010s.
-- setup dependency: the notebook loads vgsales.csv into a table named games and adds decade.
-- each output comment records results from executing the query against the supplied dataset.

-- q1 | platform sales and share of decade total
with platform_decade_sales as (
    select
        decade,
        coalesce(Platform, '(unknown)') as platform,
        sum(Global_Sales) as platform_sales
    from games
    group by decade, coalesce(Platform, '(unknown)')
),
platform_shares as (
    select
        decade,
        platform,
        platform_sales,
        sum(platform_sales) over (partition by decade) as decade_total,
        100.0 * platform_sales
            / nullif(sum(platform_sales) over (partition by decade), 0) as market_share_pct
    from platform_decade_sales
)
select
    decade,
    platform,
    round(platform_sales, 2) as platform_sales_m,
    round(decade_total, 2) as decade_total_m,
    round(market_share_pct, 2) as market_share_pct
from platform_shares
order by decade, platform_sales desc, platform;
-- output: 48 rows. Decade leaders by platform share:
-- 1980s NES 223.52m / 376.58m = 59.36%; 1990s PS 586.85m / 1,278.91m = 45.89%;
-- 2000s PS2 1,227.36m / 4,644.02m = 26.43%; 2010s PS3 602.44m / 2,520.56m = 23.90%.

-- q2 | top five platforms per decade with rank and row number
with platform_decade_sales as (
    select
        decade,
        coalesce(Platform, '(unknown)') as platform,
        sum(Global_Sales) as platform_sales
    from games
    group by decade, coalesce(Platform, '(unknown)')
),
ranked_platforms as (
    select
        decade,
        platform,
        platform_sales,
        rank() over (
            partition by decade
            order by platform_sales desc
        ) as sales_rank,
        row_number() over (
            partition by decade
            order by platform_sales desc, platform
        ) as selection_order
    from platform_decade_sales
)
select
    decade,
    platform,
    round(platform_sales, 2) as platform_sales_m,
    sales_rank,
    selection_order
from ranked_platforms
where sales_rank <= 5
  and selection_order <= 5
order by decade, selection_order;
-- output: 20 rows, five platforms per decade. 1980s: NES, 2600, GB, PC, DS;
-- 1990s: PS, SNES, N64, GB, PC; 2000s: PS2, DS, Wii, X360, PS3;
-- 2010s: PS3, X360, PS4, 3DS, Wii.

-- q3 | demonstration of rank, dense_rank, and row_number
-- rank assigns equal positions to ties and leaves gaps after them.
-- dense_rank assigns equal positions to ties without leaving gaps.
-- row_number assigns a unique sequential position to every row.
-- rank_gap shows how many positions were skipped because of previous ties.

with ranked_games as (
    select
        decade,
        Name as game_name,
        coalesce(Platform, '(unknown)') as platform,
        Global_Sales as global_sales,

        count(*) over (
            partition by decade, Global_Sales
        ) as games_with_same_sales,

        rank() over (
            partition by decade
            order by Global_Sales desc
        ) as rank_position,

        dense_rank() over (
            partition by decade
            order by Global_Sales desc
        ) as dense_rank_position,

        row_number() over (
            partition by decade
            order by Global_Sales desc, Name, coalesce(Platform, '(unknown)')
        ) as row_number_position

    from games
)

select
    decade,
    game_name,
    platform,
    round(global_sales, 2) as global_sales_m,
    games_with_same_sales,
    rank_position,
    dense_rank_position,
    rank_position - dense_rank_position as rank_gap,
    row_number_position

from ranked_games
where rank_position <> dense_rank_position
order by decade, rank_position, row_number_position
limit 40;
-- output: 40 rows. Example: in the 1980s, Mahjong and R.C. Pro-Am both have 2.14m sales;
-- both receive rank 34 and dense_rank 33, while row_number assigns 34 and 35.
-- The next sales position is RANK 36 and DENSE_rank 34, demonstrating the rank gap.

-- q4 | platform share change between consecutive decades using lag
with decades as (
    select distinct decade from games
),
platforms as (
    select distinct coalesce(Platform, '(unknown)') as platform from games
),
platform_decade_sales as (
    select
        decade,
        coalesce(Platform, '(unknown)') as platform,
        sum(Global_Sales) as platform_sales
    from games
    group by decade, coalesce(Platform, '(unknown)')
),
complete_grid as (
    select
        d.decade,
        p.platform,
        coalesce(s.platform_sales, 0.0) as platform_sales
    from decades d
    cross join platforms p
    left join platform_decade_sales s
        on s.decade = d.decade
       and s.platform = p.platform
),
platform_shares as (
    select
        decade,
        platform,
        platform_sales,
        100.0 * platform_sales
            / nullif(sum(platform_sales) over (partition by decade), 0) as share_now
    from complete_grid
),
share_lags as (
    select
        decade,
        platform,
        share_now,
        lag(decade) over (partition by platform order by decade) as previous_decade,
        lag(share_now) over (partition by platform order by decade) as share_previous
    from platform_shares
)
select
    decade,
    previous_decade,
    platform,
    round(share_now, 2) as share_now_pct,
    round(share_previous, 2) as share_previous_pct,
    round(share_now - share_previous, 2) as share_change_pp
from share_lags
where previous_decade is not null
order by decade, share_change_pp desc, platform;
-- output: 93 rows across 31 platforms and three consecutive-decade transitions.
-- Largest gain: PS rose from 0.00% to 45.89% (+45.89 pp) into the 1990s.
-- Largest loss: NES fell from 59.36% to 2.15% (-57.20 pp) into the 1990s.

-- q5 | cumulative sales per platform by year
with platform_year_sales as (
    select
        Year as year,
        coalesce(Platform, '(unknown)') as platform,
        sum(Global_Sales) as annual_sales
    from games
    group by Year, coalesce(Platform, '(unknown)')
),
running_sales as (
    select
        year,
        platform,
        annual_sales,
        sum(annual_sales) over (
            partition by platform
            order by year
            rows between unbounded preceding and current row
        ) as cumulative_sales
    from platform_year_sales
)
select
    year,
    platform,
    round(annual_sales, 2) as annual_sales_m,
    round(cumulative_sales, 2) as cumulative_sales_m
from running_sales
order by platform, year;
-- output: 240 platform-year rows. Final cumulative leaders: PS2 1,233.46m, X360 969.61m,
-- PS3 949.35m, Wii 909.81m, and DS 818.67m.

-- q6 | genre share of global sales by decade
with genre_decade_sales as (
    select
        decade,
        coalesce(Genre, '(unknown)') as genre,
        sum(Global_Sales) as genre_sales
    from games
    group by decade, coalesce(Genre, '(unknown)')
),
genre_shares as (
    select
        decade,
        genre,
        genre_sales,
        sum(genre_sales) over (partition by decade) as decade_total,
        100.0 * genre_sales
            / nullif(sum(genre_sales) over (partition by decade), 0) as genre_share_pct
    from genre_decade_sales
)
select
    decade,
    genre,
    round(genre_sales, 2) as genre_sales_m,
    round(decade_total, 2) as decade_total_m,
    round(genre_share_pct, 2) as genre_share_pct
from genre_shares
order by decade, genre_sales desc, genre;
-- output: 47 genre-decade rows. Leading genres: Platform 32.47% in the 1980s,
-- Platform 16.34% in the 1990s, Action 18.49% in the 2000s, and Action 26.72% in the 2010s.
-- From the first to final decade, Action gained 13.13 pp and Platform lost 27.68 pp.

-- q7 | genre with the largest share gain and loss from the first to final decade
with decades as (
    select distinct decade from games
),
genres as (
    select distinct coalesce(Genre, '(unknown)') as genre from games
),
genre_decade_sales as (
    select
        decade,
        coalesce(Genre, '(unknown)') as genre,
        sum(Global_Sales) as genre_sales
    from games
    group by decade, coalesce(Genre, '(unknown)')
),
complete_grid as (
    select
        d.decade,
        g.genre,
        coalesce(s.genre_sales, 0.0) as genre_sales
    from decades d
    cross join genres g
    left join genre_decade_sales s
        on s.decade = d.decade
       and s.genre = g.genre
),
genre_shares as (
    select
        decade,
        genre,
        100.0 * genre_sales
            / nullif(sum(genre_sales) over (partition by decade), 0) as genre_share_pct
    from complete_grid
),
genre_endpoints as (
    select
        genre,
        first_value(genre_share_pct) over (
            partition by genre
            order by decade
            rows between unbounded preceding and unbounded following
        ) as first_decade_share,
        last_value(genre_share_pct) over (
            partition by genre
            order by decade
            rows between unbounded preceding and unbounded following
        ) as last_decade_share
    from genre_shares
),
unique_endpoints as (
    select distinct
        genre,
        first_decade_share,
        last_decade_share,
        last_decade_share - first_decade_share as share_change_pp
    from genre_endpoints
),
ranked_changes as (
    select
        genre,
        first_decade_share,
        last_decade_share,
        share_change_pp,
        row_number() over (order by share_change_pp desc, genre) as gain_order,
        row_number() over (order by share_change_pp asc, genre) as loss_order
    from unique_endpoints
)
select
    'largest gain' as shift_type,
    genre,
    round(first_decade_share, 2) as first_decade_share_pct,
    round(last_decade_share, 2) as final_decade_share_pct,
    round(share_change_pp, 2) as share_change_pp
from ranked_changes
where gain_order = 1
union all
select
    'largest loss' as shift_type,
    genre,
    round(first_decade_share, 2) as first_decade_share_pct,
    round(last_decade_share, 2) as final_decade_share_pct,
    round(share_change_pp, 2) as share_change_pp
from ranked_changes
where loss_order = 1;
-- output: Action gained the most (+13.13 pp, 13.59% to 26.72%);
-- Platform lost the most (-27.68 pp, 32.47% to 4.79%).

-- q8 | north american and japanese genre shares side by side
with genre_region_sales as (
    select
        decade,
        coalesce(Genre, '(unknown)') as genre,
        sum(NA_Sales) as na_sales,
        sum(JP_Sales) as jp_sales
    from games
    group by decade, coalesce(Genre, '(unknown)')
),
regional_shares as (
    select
        decade,
        genre,
        na_sales,
        jp_sales,
        100.0 * na_sales
            / nullif(sum(na_sales) over (partition by decade), 0) as na_share_pct,
        100.0 * jp_sales
            / nullif(sum(jp_sales) over (partition by decade), 0) as jp_share_pct
    from genre_region_sales
)
select
    decade,
    genre,
    round(na_share_pct, 2) as na_share_pct,
    round(jp_share_pct, 2) as jp_share_pct,
    round(na_share_pct - jp_share_pct, 2) as na_minus_jp_pp
from regional_shares
order by decade, abs(na_share_pct - jp_share_pct) desc, genre;
-- output: 47 genre-decade rows. In the 1990s, Role-Playing was 8.10% of NA sales vs 26.59% of JP sales
-- (-18.49 pp NA minus JP). In the 2010s, Role-Playing was 9.67% vs 33.62% (-23.95 pp),
-- while Shooter was 20.46% in NA vs 4.53% in JP (+15.93 pp).

-- q9 | top three platform concentration by decade
with platform_decade_sales as (
    select
        decade,
        coalesce(Platform, '(unknown)') as platform,
        sum(Global_Sales) as platform_sales
    from games
    group by decade, coalesce(Platform, '(unknown)')
),
ranked_platforms as (
    select
        decade,
        platform,
        platform_sales,
        row_number() over (
            partition by decade
            order by platform_sales desc, platform
        ) as platform_order
    from platform_decade_sales
),
top_three as (
    select
        decade,
        sum(platform_sales) as top_three_sales
    from ranked_platforms
    where platform_order <= 3
    group by decade
),
decade_totals as (
    select decade, sum(Global_Sales) as decade_total
    from games
    group by decade
)
select
    t.decade,
    round(t.top_three_sales, 2) as top_three_sales_m,
    round(d.decade_total, 2) as decade_total_m,
    round(100.0 * t.top_three_sales / nullif(d.decade_total, 0), 2) as top_three_share_pct
from top_three t
join decade_totals d using (decade)
order by t.decade;
-- output: top-three platform concentration was 99.98% (1980s), 75.67% (1990s),
-- 55.86% (2000s), and 57.03% (2010s), a net decline of 42.95 pp.

-- q10 | top publisher in each decade
with publisher_decade_sales as (
    select
        decade,
        coalesce(Publisher, '(unknown)') as publisher,
        sum(Global_Sales) as publisher_sales
    from games
    group by decade, coalesce(Publisher, '(unknown)')
),
ranked_publishers as (
    select
        decade,
        publisher,
        publisher_sales,
        row_number() over (
            partition by decade
            order by publisher_sales desc, publisher
        ) as publisher_order
    from publisher_decade_sales
)
select
    decade,
    publisher,
    round(publisher_sales, 2) as publisher_sales_m,
    publisher_order
from ranked_publishers
where publisher_order = 1
order by decade;
-- output: 1980s Nintendo 234.92m; 1990s Nintendo 364.56m;
-- 2000s Nintendo 883.89m; 2010s Electronic Arts 360.92m.

-- b1 | publisher sales quartiles using ntile
with publisher_totals as (
    select
        coalesce(Publisher, '(unknown)') as publisher,
        sum(Global_Sales) as lifetime_sales
    from games
    group by coalesce(Publisher, '(unknown)')
),
publisher_quartiles as (
    select
        publisher,
        lifetime_sales,
        ntile(4) over (order by lifetime_sales desc, publisher) as sales_quartile
    from publisher_totals
)
select
    sales_quartile,
    count(*) as publisher_count,
    round(sum(lifetime_sales), 2) as quartile_sales_m,
    round(avg(lifetime_sales), 2) as avg_publisher_sales_m,
    round(max(lifetime_sales), 2) as highest_publisher_sales_m
from publisher_quartiles
group by sales_quartile
order by sales_quartile;
-- output: quartile 1: 145 publishers, 8,672.50m total, 59.81m average;
-- quartile 2: 144 publishers, 117.88m total, 0.82m average;
-- quartile 3: 144 publishers, 24.66m total, 0.17m average;
-- quartile 4: 144 publishers, 5.03m total, 0.03m average.

-- b2 | three-calendar-year moving average of annual platform sales
with recursive calendar_year(year) as (
    select 1980
    union all
    select year + 1 from calendar_year where year < 2019
),
platforms as (
    select distinct coalesce(Platform, '(unknown)') as platform from games
),
platform_year_sales as (
    select
        Year as year,
        coalesce(Platform, '(unknown)') as platform,
        sum(Global_Sales) as annual_sales
    from games
    group by Year, coalesce(Platform, '(unknown)')
),
complete_year_grid as (
    select
        c.year,
        p.platform,
        coalesce(s.annual_sales, 0.0) as annual_sales
    from calendar_year c
    cross join platforms p
    left join platform_year_sales s
        on s.year = c.year
       and s.platform = p.platform
),
smoothed_sales as (
    select
        year,
        platform,
        annual_sales,
        avg(annual_sales) over (
            partition by platform
            order by year
            rows between 2 preceding and current row
        ) as moving_avg_3_calendar_years
    from complete_year_grid
)
select
    year,
    platform,
    round(annual_sales, 2) as annual_sales_m,
    round(moving_avg_3_calendar_years, 2) as moving_avg_3_years_m
from smoothed_sales
order by platform, year;
-- output: 1,240 platform-calendar-year rows (31 platforms × 40 years).
-- Highest three-year moving averages among the five lifetime leaders: PS2 200.49m in 2004,
-- Wii 179.86m in 2009, X360 145.67m in 2011, PS3 145.38m in 2011, and DS 139.75m in 2009.

-- b3 | first and last year of meaningful platform sales
with platform_year_sales as (
    select
        Year as year,
        coalesce(Platform, '(unknown)') as platform,
        sum(Global_Sales) as annual_sales
    from games
    group by Year, coalesce(Platform, '(unknown)')
    having sum(Global_Sales) > 0
),
platform_lifecycle as (
    select
        platform,
        first_value(year) over (
            partition by platform
            order by year
            rows between unbounded preceding and unbounded following
        ) as first_sales_year,
        last_value(year) over (
            partition by platform
            order by year
            rows between unbounded preceding and unbounded following
        ) as last_sales_year,
        sum(annual_sales) over (partition by platform) as lifetime_sales
    from platform_year_sales
)
select distinct
    platform,
    first_sales_year,
    last_sales_year,
    round(lifetime_sales, 2) as lifetime_sales_m
from platform_lifecycle
order by lifetime_sales desc, platform;
-- output: 31 platforms. Leading lifecycle records: PS2 2000–2011 (1,233.46m),
-- X360 2005–2016 (969.61m), PS3 2006–2016 (949.35m), Wii 2006–2015 (909.81m),
-- and DS 1985–2014 (818.67m).

