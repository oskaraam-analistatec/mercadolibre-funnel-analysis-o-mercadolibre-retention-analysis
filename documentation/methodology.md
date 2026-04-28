Metodología del Análisis
📌 Pregunta de Investigación Principal
> **¿Cuáles son los puntos de fricción en el viaje de compra de MercadoLibre y cómo mejorar la retención de usuarios?**
---
🎯 Preguntas Secundarias
¿Dónde abandonan los usuarios el proceso de compra?
Identificar la etapa con mayor caída de conversión
¿Cuál es el patrón de retención real después de la primera compra?
Entender si los usuarios son compradores únicos o recurrentes
¿Existen diferencias significativas por país?
Validar si el comportamiento varía por región
¿Cuánto tiempo toma convertir a un usuario de visitante a comprador?
Entender la velocidad del ciclo de compra
---
🔍 Definiciones Operacionales
Embudo de Compra (Sales Funnel)
Secuencia de etapas que un usuario atraviesa desde su llegada hasta la compra.
4 Etapas Definidas:
Primera Visita (First Visit)
Usuario accede por primera vez a la plataforma
Evento: `first_visit`
Base de comparación: 100% de usuarios activos
Seleccionar Artículo (Browse/Select Item)
Usuario visualiza o interactúa con artículos específicos
Evento: `select_item`
Tasa de conversión vs Primera Visita
Agregar al Carrito (Add to Cart)
Usuario expresa intención de comprar agregando artículos
Evento: `add_to_cart`
Tasa de conversión vs Seleccionar Artículo (máximo fricción aquí)
Compra Completada (Purchase)
Usuario completa la transacción exitosamente
Registro: tabla `purchases`
Tasa de conversión vs Agregar al Carrito
Retención (Retention)
Capacidad de traer de vuelta a usuarios que ya han comprado.
Métricas Específicas:
D7: ¿Volvió el usuario dentro de 7 días?
D14: ¿Volvió el usuario dentro de 14 días?
D21: ¿Volvió el usuario dentro de 21 días?
D28: ¿Volvió el usuario dentro de 28 días?
Definición Técnica:
```
Usuario en retención = Existe otro purchase_date después de first_purchase_date
                       en el rango de días especificado
```
Cohorte (Cohort)
Grupo de usuarios agrupados por una característica temporal común.
En este análisis: Cohorte Mensual = Usuarios que realizaron su primera compra en el mismo mes
---
🛠️ Técnicas SQL Utilizadas
1. Common Table Expressions (CTEs)
Propósito: Estructurar análisis complejos en pasos lógicos y reutilizables.
Ejemplo:
```sql
WITH funnel_stages AS (
  -- Paso 1: Identificar etapas
  SELECT ...
),
funnel_summary AS (
  -- Paso 2: Agregar etapas
  SELECT ...
)
-- Paso 3: Resultado final
SELECT * FROM funnel_summary;
```
Ventajas:
Claridad y legibilidad
Fácil depuración
Reducción de repetición de código
2. Window Functions
Propósito: Cálculos sobre subconjuntos de datos sin colapsarlos.
Ejemplo Usado:
```sql
ROW_NUMBER() OVER (PARTITION BY cohort_month ORDER BY days_since_purchase)
```
Casos de Uso:
Ranking de usuarios por valor
Cálculos de diferencia entre períodos
Análisis de series de tiempo
3. CASE WHEN
Propósito: Crear indicadores binarios para identificar si un usuario alcanzó una etapa.
Ejemplo:
```sql
CASE 
  WHEN event_type = 'first_visit' THEN 1 
  ELSE 0 
END AS first_visit_flag
```
4. LEFT JOIN
Propósito: Preservar todos los registros de la tabla izquierda incluso si no hay coincidencia.
Aplicación:
Identificar usuarios que NO alcanzaron una etapa
Análisis de abandono
5. GROUP BY + HAVING
Propósito: Agregar datos y filtrar después de la agregación.
Ejemplo:
```sql
GROUP BY cohort_month, country
HAVING COUNT(*) > 100  -- Solo cohortes con 100+ usuarios
```
6. CROSS JOIN + Subqueries
Propósito: Conectar múltiples tablas derivadas sin condiciones de unión.
```sql
SELECT 
  cs.cohort_month,
  COALESCE(rc_d7.returning_users, 0) AS d7_users
FROM cohort_sizes cs
LEFT JOIN retention_by_cohort rc_d7 ON cs.cohort_month = rc_d7.cohort_month
```
---
📊 Flujo del Análisis
Fase 1: Exploración (01_data_exploration.sql)
✓ Verificar estructura de datos
✓ Entender rangos y distribuciones
✓ Validar calidad de datos
✓ Identificar patrones iniciales
Salidas:
Cantidad de registros por tabla
Tipos de eventos únicos
Distribución por país
Rangos de fechas
Fase 2: Análisis del Embudo (02_funnel_analysis.sql)
✓ Calcular usuarios en cada etapa
✓ Determinar tasas de conversión
✓ Segmentar por país
✓ Identificar puntos de máxima fricción
Salidas:
Tabla de embudo general
Tasas de conversión por etapa
Análisis segmentado por país
Fase 3: Análisis de Retención (03_retention_cohorts.sql)
✓ Crear cohortes mensuales
✓ Rastrear retención en D7, D14, D21, D28
✓ Comparar patrones por país
✓ Identificar cohortes de mayor/menor retención
Salidas:
Tabla de retención por cohortes
Porcentajes de retención por período
Comparativa por país
Fase 4: Insights Accionables (04_final_insights.sql)
✓ Identificar usuarios en riesgo
✓ Destacar usuarios de alto valor
✓ Comparar comportamientos regionales
✓ Analizar velocidad de conversión
✓ Detectar patrones estacionales
Salidas:
Listas de usuarios específicos por categoría
Segmentaciones de valor
Patrones temporales
---
⚠️ Limitaciones del Análisis
Datos
Período limitado: Solo análisis de enero 2025 en adelante
Datos históricos: Sin información de años anteriores para comparación
Eventos incompletos: Algunos eventos pueden no ser registrados perfectamente
Metodología
No causualidad: El análisis es correlacional, no causal
Factores externos: No se consideran campañas, promociones, estacionalidades
Datos faltantes: Usuarios sin eventos o sin compras se excluyen del análisis
Técnica
Window functions: Pueden ser computacionalmente intensivas con millones de registros
Redondeos: Algunos porcentajes se redondean a 2 decimales
Timezone: Todos los timestamps se consideran en UTC
---
🎯 Próximos Pasos Recomendados
Validación Externa
Comparar resultados con datos de herramientas analíticas (Google Analytics, Mixpanel)
Entrevistas con equipos de Producto y Marketing
Análisis Más Profundos
Análisis de cohortes ampliado (6-12 meses)
Análisis de causas raíz de abandono
Segmentación por dispositivo, fuente de tráfico, etc.
Experimentación
A/B testing en puntos de fricción (especialmente carrito)
Test de mejoras post-compra
Variaciones por país
Monitoreo
Dashboard en tiempo real de métricas de embudo
Alertas de cambios anormales
Trackeo de impacto de cambios implementados
---
📚 Referencias y Recursos
SQL Window Functions - PostgreSQL Docs
Cohort Analysis - Best Practices
Funnel Analysis - Product Management
