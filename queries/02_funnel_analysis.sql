-- ============================================================================
-- ANÁLISIS DE EMBUDO Y RETENCIÓN PARA MERCADOLIBRE
-- 02_funnel_analysis.sql
-- Cálculo del embudo de compra por etapas
-- ============================================================================

-- ANÁLISIS DEL EMBUDO DE COMPRA
-- Identificar cada etapa del journey del usuario y calcular conversión

WITH funnel_stages AS (
    -- Para cada usuario, identificar si alcanzó cada etapa del embudo
    SELECT 
        u.user_id,
        u.country,
        -- Etapa 1: Primera Visita
        CASE 
            WHEN e1.event_type = 'first_visit' THEN 1 
            ELSE 0 
        END AS first_visit,
        -- Etapa 2: Seleccionar Artículo
        CASE 
            WHEN e2.event_type = 'select_item' THEN 1 
            ELSE 0 
        END AS selected_item,
        -- Etapa 3: Agregar al Carrito
        CASE 
            WHEN e3.event_type = 'add_to_cart' THEN 1 
            ELSE 0 
        END AS added_to_cart,
        -- Etapa 4: Compra Completada
        CASE 
            WHEN p.purchase_id IS NOT NULL THEN 1 
            ELSE 0 
        END AS purchased
    FROM users u
    LEFT JOIN (
        SELECT DISTINCT user_id 
        FROM events 
        WHERE event_type = 'first_visit'
    ) e1 ON u.user_id = e1.user_id
    LEFT JOIN (
        SELECT DISTINCT user_id 
        FROM events 
        WHERE event_type = 'select_item'
    ) e2 ON u.user_id = e2.user_id
    LEFT JOIN (
        SELECT DISTINCT user_id 
        FROM events 
        WHERE event_type = 'add_to_cart'
    ) e3 ON u.user_id = e3.user_id
    LEFT JOIN purchases p ON u.user_id = p.user_id
    WHERE DATE_TRUNC('month', u.created_at) >= '2025-01-01'
),

funnel_summary AS (
    -- Contar usuarios en cada etapa
    SELECT 
        COUNT(*) AS total_usuarios,
        SUM(first_visit) AS etapa_1_visita,
        SUM(selected_item) AS etapa_2_seleccionar,
        SUM(added_to_cart) AS etapa_3_carrito,
        SUM(purchased) AS etapa_4_compra
    FROM funnel_stages
)

-- RESULTADOS DEL EMBUDO
SELECT 
    'Primera Visita' AS etapa,
    etapa_1_visita AS usuarios,
    ROUND(etapa_1_visita::NUMERIC / total_usuarios * 100, 2) AS porcentaje,
    NULL::VARCHAR AS tasa_conversion
FROM funnel_summary

UNION ALL

SELECT 
    'Seleccionar Artículo' AS etapa,
    etapa_2_seleccionar AS usuarios,
    ROUND(etapa_2_seleccionar::NUMERIC / total_usuarios * 100, 2) AS porcentaje,
    ROUND(etapa_2_seleccionar::NUMERIC / NULLIF(etapa_1_visita, 0) * 100, 2) || '%' AS tasa_conversion
FROM funnel_summary

UNION ALL

SELECT 
    'Agregar al Carrito' AS etapa,
    etapa_3_carrito AS usuarios,
    ROUND(etapa_3_carrito::NUMERIC / total_usuarios * 100, 2) AS porcentaje,
    ROUND(etapa_3_carrito::NUMERIC / NULLIF(etapa_2_seleccionar, 0) * 100, 2) || '%' AS tasa_conversion
FROM funnel_summary

UNION ALL

SELECT 
    'Compra Completada' AS etapa,
    etapa_4_compra AS usuarios,
    ROUND(etapa_4_compra::NUMERIC / total_usuarios * 100, 2) AS porcentaje,
    ROUND(etapa_4_compra::NUMERIC / NULLIF(etapa_3_carrito, 0) * 100, 2) || '%' AS tasa_conversion
FROM funnel_summary

ORDER BY 
    CASE 
        WHEN etapa = 'Primera Visita' THEN 1
        WHEN etapa = 'Seleccionar Artículo' THEN 2
        WHEN etapa = 'Agregar al Carrito' THEN 3
        WHEN etapa = 'Compra Completada' THEN 4
    END;

-- ANÁLISIS DEL EMBUDO POR PAÍS
SELECT 
    country,
    COUNT(DISTINCT user_id) AS total_usuarios,
    SUM(CASE WHEN first_visit = 1 THEN 1 ELSE 0 END) AS visitantes,
    SUM(CASE WHEN selected_item = 1 THEN 1 ELSE 0 END) AS seleccionaron,
    SUM(CASE WHEN added_to_cart = 1 THEN 1 ELSE 0 END) AS carrito,
    SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END) AS compraron,
    ROUND(SUM(CASE WHEN purchased = 1 THEN 1 ELSE 0 END)::NUMERIC / COUNT(DISTINCT user_id) * 100, 2) AS tasa_conversion_total
FROM funnel_stages
GROUP BY country
ORDER BY tasa_conversion_total DESC;
