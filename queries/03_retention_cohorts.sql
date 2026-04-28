-- ============================================================================
-- ANÁLISIS DE EMBUDO Y RETENCIÓN PARA MERCADOLIBRE
-- 03_retention_cohorts.sql
-- Análisis de retención de usuarios por cohortes mensuales
-- ============================================================================

WITH first_purchase AS (
    -- Identificar la primera compra de cada usuario
    SELECT 
        user_id,
        MIN(purchase_date) AS first_purchase_date,
        DATE_TRUNC('month', MIN(purchase_date))::DATE AS cohort_month
    FROM purchases
    GROUP BY user_id
),

all_purchases AS (
    -- Todas las compras de los usuarios
    SELECT 
        fp.user_id,
        fp.cohort_month,
        p.purchase_date,
        -- Calcular días desde la primera compra
        (p.purchase_date - fp.first_purchase_date) AS days_since_first_purchase,
        -- Categorizar en buckets de retención
        CASE 
            WHEN (p.purchase_date - fp.first_purchase_date) <= 7 THEN 'D7'
            WHEN (p.purchase_date - fp.first_purchase_date) <= 14 THEN 'D14'
            WHEN (p.purchase_date - fp.first_purchase_date) <= 21 THEN 'D21'
            WHEN (p.purchase_date - fp.first_purchase_date) <= 28 THEN 'D28'
            ELSE 'D28+'
        END AS retention_bucket
    FROM first_purchase fp
    INNER JOIN purchases p ON fp.user_id = p.user_id
),

retention_by_cohort AS (
    -- Contar usuarios únicos que regresaron en cada período
    SELECT 
        cohort_month,
        retention_bucket,
        COUNT(DISTINCT user_id) AS returning_users
    FROM all_purchases
    WHERE days_since_first_purchase > 0  -- Excluir la primera compra
    GROUP BY cohort_month, retention_bucket
),

cohort_sizes AS (
    -- Tamaño de cada cohorte (usuarios en su primera compra)
    SELECT 
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
)

-- TABLA DE RETENCIÓN POR COHORTES
SELECT 
    cs.cohort_month,
    cs.cohort_size,
    COALESCE(rc_d7.returning_users, 0) AS d7_users,
    ROUND(COALESCE(rc_d7.returning_users, 0)::NUMERIC / cs.cohort_size * 100, 2) AS d7_retention_pct,
    COALESCE(rc_d14.returning_users, 0) AS d14_users,
    ROUND(COALESCE(rc_d14.returning_users, 0)::NUMERIC / cs.cohort_size * 100, 2) AS d14_retention_pct,
    COALESCE(rc_d21.returning_users, 0) AS d21_users,
    ROUND(COALESCE(rc_d21.returning_users, 0)::NUMERIC / cs.cohort_size * 100, 2) AS d21_retention_pct,
    COALESCE(rc_d28.returning_users, 0) AS d28_users,
    ROUND(COALESCE(rc_d28.returning_users, 0)::NUMERIC / cs.cohort_size * 100, 2) AS d28_retention_pct
FROM cohort_sizes cs
LEFT JOIN (
    SELECT cohort_month, returning_users 
    FROM retention_by_cohort 
    WHERE retention_bucket = 'D7'
) rc_d7 ON cs.cohort_month = rc_d7.cohort_month
LEFT JOIN (
    SELECT cohort_month, returning_users 
    FROM retention_by_cohort 
    WHERE retention_bucket = 'D14'
) rc_d14 ON cs.cohort_month = rc_d14.cohort_month
LEFT JOIN (
    SELECT cohort_month, returning_users 
    FROM retention_by_cohort 
    WHERE retention_bucket = 'D21'
) rc_d21 ON cs.cohort_month = rc_d21.cohort_month
LEFT JOIN (
    SELECT cohort_month, returning_users 
    FROM retention_by_cohort 
    WHERE retention_bucket = 'D28'
) rc_d28 ON cs.cohort_month = rc_d28.cohort_month
ORDER BY cs.cohort_month DESC;

-- ANÁLISIS DE RETENCIÓN POR PAÍS
WITH user_country AS (
    SELECT 
        p.user_id,
        u.country,
        MIN(p.purchase_date) AS first_purchase_date
    FROM purchases p
    JOIN users u ON p.user_id = u.user_id
    GROUP BY p.user_id, u.country
),

retention_by_country AS (
    SELECT 
        uc.country,
        COUNT(DISTINCT uc.user_id) AS total_customers,
        SUM(CASE 
            WHEN EXISTS (
                SELECT 1 FROM purchases p 
                WHERE p.user_id = uc.user_id 
                AND p.purchase_date > uc.first_purchase_date
                AND (p.purchase_date - uc.first_purchase_date) <= 7
            ) THEN 1 
            ELSE 0 
        END) AS d7_returning,
        SUM(CASE 
            WHEN EXISTS (
                SELECT 1 FROM purchases p 
                WHERE p.user_id = uc.user_id 
                AND p.purchase_date > uc.first_purchase_date
                AND (p.purchase_date - uc.first_purchase_date) <= 28
            ) THEN 1 
            ELSE 0 
        END) AS d28_returning
    FROM user_country uc
    GROUP BY uc.country
)

SELECT 
    country,
    total_customers,
    d7_returning,
    ROUND(d7_returning::NUMERIC / total_customers * 100, 2) AS d7_retention_pct,
    d28_returning,
    ROUND(d28_returning::NUMERIC / total_customers * 100, 2) AS d28_retention_pct
FROM retention_by_country
ORDER BY d7_retention_pct DESC;
