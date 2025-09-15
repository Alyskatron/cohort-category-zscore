-- ============================================
-- Cohort Analysis: Category Spend Normalization
-- ============================================
-- This script:
-- 1. Calculates category spend proportions per facility
-- 2. Normalizes spend using z-scores (per category)
-- 3. Assigns facilities into quartiles based on total spend
-- 4. Produces a cohort-level heatmap showing category emphasis
--
-- IMPORTANT: Replace generic table and column names (purchase_data, category_reference, etc.)
-- with your actual dataset/table/column names before running.

-- --------------------------
-- STEP 1: Raw Category Spend
-- --------------------------
WITH facility_category AS (
    SELECT
        p.FacilityID,
        p.FacilityName,
        c.ItemCategory AS Contract_Category,
        SUM(p.SpendAmount) AS category_spend
    FROM purchase_data p
    JOIN category_reference c 
        ON c.SKU = p.SKU
    -- Replace date filter as needed
    WHERE p.InvoiceDate >= DATE('2024-01-01')
    GROUP BY p.FacilityID, p.FacilityName, c.ItemCategory
),

-- --------------------------
-- STEP 2: Facility Totals
-- --------------------------
totals AS (
    SELECT
        FacilityID,
        SUM(category_spend) AS total_spend
    FROM facility_category
    GROUP BY FacilityID
),

-- --------------------------
-- STEP 3: Category Proportions
-- --------------------------
proportions AS (
    SELECT
        fc.FacilityID,
        fc.FacilityName,
        fc.Contract_Category,
        CASE WHEN t.total_spend = 0 THEN 0 ELSE fc.category_spend / t.total_spend END AS spend_pct
    FROM facility_category fc
    JOIN totals t 
        ON fc.FacilityID = t.FacilityID
),

-- --------------------------
-- STEP 4: Category-Level Stats
-- --------------------------
category_stats AS (
    SELECT
        Contract_Category,
        AVG(spend_pct) AS avg_pct,
        STDDEV(spend_pct) AS std_pct
    FROM proportions
    GROUP BY Contract_Category
),

-- --------------------------
-- STEP 5: Normalize with Z-Scores
-- --------------------------
zscores AS (
    SELECT
        p.FacilityID,
        p.FacilityName,
        p.Contract_Category,
        CASE WHEN s.std_pct IS NULL OR s.std_pct = 0 THEN 0
             ELSE (p.spend_pct - s.avg_pct) / s.std_pct END AS zscore
    FROM proportions p
    JOIN category_stats s
        ON p.Contract_Category = s.Contract_Category
),

-- --------------------------
-- STEP 6: Facility Quartiles
-- --------------------------
facility_totals AS (
    SELECT
        FacilityID,
        SUM(SpendAmount) AS total_spend
    FROM purchase_data
    -- Optional: filter to particular data source
    -- WHERE DataSource = 'APFeed File'
    GROUP BY FacilityID
),
ranked AS (
    SELECT
        FacilityID,
        total_spend,
        NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile
    FROM facility_totals
),
quartiles AS (
    SELECT
        FacilityID,
        CASE spend_quartile
            WHEN 1 THEN 'Top 25%'
            WHEN 2 THEN 'Upper-Mid'
            WHEN 3 THEN 'Lower-Mid'
            WHEN 4 THEN 'Bottom 25%'
        END AS spend_cohort
    FROM ranked
)

-- --------------------------
-- STEP 7: Heatmap Output
-- --------------------------
SELECT
    z.Contract_Category,
    AVG(CASE WHEN q.spend_cohort = 'Top 25%'   THEN z.zscore END) AS top25_avg_z,
    AVG(CASE WHEN q.spend_cohort = 'Upper-Mid' THEN z.zscore END) AS upper_mid_avg_z,
    AVG(CASE WHEN q.spend_cohort = 'Lower-Mid' THEN z.zscore END) AS lower_mid_avg_z,
    AVG(CASE WHEN q.spend_cohort = 'Bottom 25%' THEN z.zscore END) AS bottom25_avg_z
FROM zscores z
JOIN quartiles q 
    ON z.FacilityID = q.FacilityID
GROUP BY z.Contract_Category
ORDER BY z.Contract_Category;
