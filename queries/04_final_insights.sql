-- ============================================================================
-- ANÁLISIS DE EMBUDO Y RETENCIÓN PARA MERCADOLIBRE
-- 04_final_insights.sql
-- Consultas para obtener insights accionables
-- ============================================================================

-- INSIGHT 1: Identificar el punto de mayor fricción en el embudo
WITH funnel_conversions AS (
    SELECT 
        'Visita → Seleccionar' AS conversion_step,
        -- Lógica para calcular tasa
        SUM(CASE WHEN e2.event_type = 'select_item' THEN 1 ELSE 0 END)::NUMERIC / 
        SUM(CASE WHEN e1.event_type = 'first_visit' THEN 1 ELSE 0 END) * 100 AS conversion_rate
    FROM events e1
    LEFT JOIN events e2 ON e1.user_id = e2.user_id 
        AND e2.event_type = 'select_item'
    
    UNION ALL
    
    SELECT 
        'Seleccionar → Carrito' AS conversion_step,
        SUM(CASE WHEN e3.event_type = 'add_to_cart' THEN 1 ELSE 0 END)::NUMERIC / 
        SUM(CASE WHEN e2.event_type = 'select_item' THEN 1 ELSE 0 END) * 100 AS conversion_rate
    FROM events e2
    LEFT JOIN events e3 ON e2.user_id = e3.user_id 
        AND e3.event_type = 'add_to_cart'
    
    UNION ALL
    
    SELECT 
        'Carrito → Compra' AS conversion_step,
        COUNT(DISTINCT CASE WHEN p.purchase_id IS NOT NULL THEN e3.user_id END)::NUMERIC / 
        COUNT(DISTINCT e3.user_id) * 100 AS conversion_rate
    FROM events e3
    LEFT JOIN purchases p ON e3.user_id = p.user_id
    WHERE e3.event_type = 'add_to_cart'
)

SELECT *
FROM funnel_conversions
ORDER BY conversion_rate ASC;

-- INSIGHT 2: Usuarios en riesgo (agregaron al carrito pero no compraron)
SELECT 
    u.user_id,
    u.country,
    MAX(e.event_date) AS ultima_actividad,
    CURRENT_DATE - MAX(e.event_date) AS dias_sin_actividad
FROM users u
JOIN events e ON u.user_id = e.user_id
WHERE e.event_type = 'add_to_cart'
    AND NOT EXISTS (
        SELECT 1 FROM purchases p WHERE p.user_id = u.user_id
    )
GROUP BY u.user_id, u.country
ORDER BY dias_sin_actividad DESC
LIMIT 20;

-- INSIGHT 3: Usuarios de alto valor (compraron múltiples veces)
SELECT 
    u.user_id,
    u.country,
    COUNT(DISTINCT p.purchase_id) AS numero_compras,
    SUM(p.amount) AS total_gastado,
    ROUND(AVG(p.amount), 2) AS promedio_por_compra,
    MIN(p.purchase_date) AS primera_compra,
    MAX(p.purchase_date) AS ultima_compra
FROM users u
JOIN purchases p ON u.user_id = p.user_id
GROUP BY u.user_id, u.country
HAVING COUNT(DISTINCT p.purchase_id) > 1
ORDER BY total_gastado DESC
LIMIT 20;

-- INSIGHT 4: Comparación de patrones por país
SELECT 
    u.country,
    COUNT(DISTINCT u.user_id) AS total_usuarios,
    ROUND(COUNT(DISTINCT p.purchase_id)::NUMERIC / COUNT(DISTINCT u.user_id), 2) AS compras_por_usuario,
    ROUND(AVG(p.amount), 2) AS ticket_promedio,
    COUNT(DISTINCT CASE WHEN p.purchase_date >= CURRENT_DATE - INTERVAL '7 days' THEN p.user_id END) AS usuarios_activos_7d,
    ROUND(
        COUNT(DISTINCT CASE WHEN p.purchase_date >= CURRENT_DATE - INTERVAL '7 days' THEN p.user_id END)::NUMERIC / 
        COUNT(DISTINCT p.user_id) * 100, 
        2
    ) AS porcentaje_activos_7d
FROM users u
LEFT JOIN purchases p ON u.user_id = p.user_id
GROUP BY u.country
ORDER BY compras_por_usuario DESC;

-- INSIGHT 5: Velocidad de compra (cuánto tiempo toma convertir)
WITH user_first_event AS (
    SELECT 
        user_id,
        MIN(event_date) AS primer_evento
    FROM events
    GROUP BY user_id
),

conversion_time AS (
    SELECT 
        ufe.user_id,
        p.purchase_date - ufe.primer_evento AS dias_hasta_compra
    FROM user_first_event ufe
    JOIN purchases p ON ufe.user_id = p.user_id
)

SELECT 
    CASE 
        WHEN dias_hasta_compra <= 0 THEN '0 días (misma visita)'
        WHEN dias_hasta_compra <= 1 THEN '1 día'
        WHEN dias_hasta_compra <= 7 THEN '2-7 días'
        WHEN dias_hasta_compra <= 30 THEN '8-30 días'
        ELSE '30+ días'
    END AS rango_conversion,
    COUNT(*) AS numero_usuarios,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) AS porcentaje
FROM conversion_time
GROUP BY rango_conversion
ORDER BY numero_usuarios DESC;

-- INSIGHT 6: Estacionalidad - Patrones por mes
SELECT 
    DATE_TRUNC('month', e.event_date)::DATE AS mes,
    e.event_type,
    COUNT(DISTINCT e.user_id) AS usuarios_unicos,
    COUNT(*) AS total_eventos
FROM events e
GROUP BY DATE_TRUNC('month', e.event_date), e.event_type
ORDER BY mes DESC, usuarios_unicos DESC;
