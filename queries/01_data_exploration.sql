-- ============================================================================
-- ANÁLISIS DE EMBUDO Y RETENCIÓN PARA MERCADOLIBRE
-- 01_data_exploration.sql
-- Exploración inicial de las tablas disponibles y datos
-- ============================================================================

-- Explorar estructura de tabla de usuarios
SELECT 
    user_id,
    country,
    created_at
FROM users
LIMIT 10;

-- Explorar estructura de tabla de eventos
SELECT 
    event_id,
    user_id,
    event_type,
    event_date,
    timestamp
FROM events
LIMIT 10;

-- Explorar estructura de tabla de compras
SELECT 
    purchase_id,
    user_id,
    purchase_date,
    amount
FROM purchases
LIMIT 10;

-- Contar total de registros por tabla
SELECT 'users' AS tabla, COUNT(*) AS total_registros FROM users
UNION ALL
SELECT 'events' AS tabla, COUNT(*) AS total_registros FROM events
UNION ALL
SELECT 'purchases' AS tabla, COUNT(*) AS total_registros FROM purchases;

-- Verificar tipos de eventos disponibles
SELECT DISTINCT event_type, COUNT(*) AS cantidad
FROM events
GROUP BY event_type
ORDER BY cantidad DESC;

-- Verificar países disponibles
SELECT DISTINCT country, COUNT(*) AS cantidad_usuarios
FROM users
GROUP BY country
ORDER BY cantidad_usuarios DESC;

-- Verificar rango de fechas en los datos
SELECT 
    MIN(event_date) AS fecha_inicio_eventos,
    MAX(event_date) AS fecha_fin_eventos,
    MIN(purchase_date) AS fecha_inicio_compras,
    MAX(purchase_date) AS fecha_fin_compras
FROM (
    SELECT event_date AS fecha_inicio, NULL AS purchase_date FROM events
    UNION ALL
    SELECT NULL, purchase_date FROM purchases
);

-- Verificar usuarios con compras
SELECT 
    COUNT(DISTINCT u.user_id) AS total_usuarios,
    COUNT(DISTINCT p.user_id) AS usuarios_con_compras,
    ROUND(COUNT(DISTINCT p.user_id)::NUMERIC / COUNT(DISTINCT u.user_id) * 100, 2) AS porcentaje_conversion_total
FROM users u
LEFT JOIN purchases p ON u.user_id = p.user_id;
