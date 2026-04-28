## 📊 Descripción del Proyecto
Análisis completo del viaje del usuario en MercadoLibre utilizando **SQL avanzado** para 
identificar puntos de fricción en el embudo de compra y patrones de retención de usuarios 
mediante análisis de cohortes.

## 🎯 Objetivos
- Mapear el journey completo del usuario (first visit → purchase)
- Identificar dónde ocurren los abandonos principales
- Analizar retención por cohortes mensuales (D7, D14, D21, D28)
- Segmentar por país para identificar patrones regionales

## 🔑 Hallazgos Principales

### Embudo de Compra
| Etapa | % Conversión | Usuarios |
|-------|------------|----------|
| Primera Visita | 100% | 50,000 |
| Seleccionar Artículo | 76.9% | 38,450 |
| Agregar al Carrito | 11.0% | 4,230 |
| Compra Completada | 2-3% | 85-127 |

### Retención por Día
- **D7:** ~86% de retención
- **D14:** ~15-20%
- **D21:** ~5-10%
- **D28:** ~2-3%

### Insights por País
- ✅ **Perú y México:** Retención más estable
- ⚠️ **Argentina:** Mayor volatilidad en retención

## 🛠️ Tecnologías Utilizadas
- **SQL:** CTEs (Common Table Expressions), Window Functions, Análisis de Cohortes
- **Base de Datos:** PostgreSQL / MySQL / SQL Server
- **Exportación:** Python + Pandas para CSV

## 📁 Estructura del Repositorio

### `/queries`
Consultas SQL organizadas por propósito:
- `01_data_exploration.sql` - Exploración de tablas y datos disponibles
- `02_funnel_analysis.sql` - Cálculo de embudo por etapa
- `03_retention_cohorts.sql` - Análisis de retención por cohortes
- `04_final_insights.sql` - Consultas de insights finales

### `/results`
Resultados exportados como CSV para análisis posterior:
- `funnel_metrics.csv` - Métricas del embudo por etapa
- `retention_data.csv` - Datos de retención por cohorte y país

### `/documentation`
Documentación técnica y hallazgos:
- `data_dictionary.md` - Descripción de tablas y columnas usadas
- `methodology.md` - Explicación del enfoque analítico
- `findings_report.md` - Reporte ejecutivo de hallazgos

## 🔍 Metodología

### Paso 1: Exploración de Datos
```sql
-- Ver estructura de tablas
SELECT * FROM users LIMIT 10;
SELECT * FROM events LIMIT 10;
```

### Paso 2: Construir el Embudo
```sql
WITH funnel_stages AS (
  SELECT 
    user_id,
    MAX(CASE WHEN event_type = 'first_visit' THEN 1 ELSE 0 END) as visited,
    MAX(CASE WHEN event_type = 'select_item' THEN 1 ELSE 0 END) as browsed,
    MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) as carted,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) as purchased
  FROM events
  WHERE event_date >= '2025-01-01'
  GROUP BY user_id
)
SELECT 
  COUNT(*) as total_users,
  SUM(visited) as visitors,
  SUM(browsed) as browsers,
  SUM(carted) as cart_users,
  SUM(purchased) as purchasers
FROM funnel_stages;
```

### Paso 3: Análisis de Retención por Cohortes
```sql
WITH cohorts AS (
  SELECT 
    user_id,
    DATE_TRUNC('month', first_purchase_date)::DATE as cohort_month,
    EXTRACT(DAY FROM current_date - first_purchase_date) as days_since_first_purchase
  FROM purchases
)
SELECT 
  cohort_month,
  days_since_first_purchase,
  COUNT(DISTINCT user_id) as returning_users
FROM cohorts
GROUP BY cohort_month, days_since_first_purchase
ORDER BY cohort_month, days_since_first_purchase;
```

## 📊 Cómo Ejecutar los Análisis

### Opción 1: Ejecutar directamente en tu BD
```bash
# Ejecutar cada archivo SQL en orden
1. psql -U username -d database < queries/01_data_exploration.sql
2. psql -U username -d database < queries/02_funnel_analysis.sql
3. psql -U username -d database < queries/03_retention_cohorts.sql
```

### Opción 2: Usar el script Python para exportar resultados
```bash
python scripts/export_results.py
```
# 📊 Resultados del Análisis - MercadoLibre Funnel & Retention

## 📌 Datos Analizados

**Período:** 01/01/2025 - 08/31/2025
**Países:** Argentina, Brasil, Chile, Colombia, México, Perú
**Métrica:** Análisis de embudo de compra y retención de usuarios

---

## 🔍 Hallazgos Principales

### 1️⃣ **Fricción Crítica en el Embudo**

**La mayor caída ocurre entre: Select Item → Add to Cart**

| Etapa | % Conversión |
|-------|--------------|
| Select Item | 76.90% |
| **Add to Cart** | **11.01%** ⚠️ **MÁXIMA FRICCIÓN** |
| Begin Checkout | 4.00% |
| Add Shipping Info | 2.42% |
| Add Payment Info | 2.09% |
| Purchase | 1.25% |

**Interpretación:**
- 76.90% de usuarios exploran productos
- Solo 11.01% agregan al carrito
- **Pérdida de 88.6% entre visualización y decisión de compra**

**Causas Identificadas:**
- Precios o costos no competitivos
- Información del producto insuficiente
- Problemas de confianza del usuario
- Experiencia pobre en la página

---

### 2️⃣ **Retención por Períodos**

**Tendencia general de D7 a D28:**

| Período | Retención |
|---------|-----------|
| D7 | ~85-87% ✓ |
| D14 | ~40-50% |
| D21 | ~25% |
| **D28** | **~2-3%** ❌ |

**Hallazgo:** Caída dramática después de D21

---

### 3️⃣ **Retención por País**

#### 🥇 **Mejor Desempeño**
- **Perú:** 3.2% en D28 (la más alta)
- **México:** 3.1% en D28
- **Brasil:** 2.5% en D28

#### 🥉 **Menor Desempeño**
- **Argentina:** 1.8% en D28
- **Chile:** 1.7% en D28
- **Colombia:** 1.6% en D28

**Patrón:** México y Perú mantienen mejor retención a largo plazo

---

## 💡 Reflexiones y Aprendizajes

### ¿Qué Etapa Mejorarías Primero?

**Respuesta:** Las etapas iniciales del embudo

- La mayor caída porcentual ocurre entre visualización y agregar al carrito
- Existe una brecha significativa entre interés inicial y decisión de compra
- Este es el punto de máximo impacto para mejora

### ¿Qué Aprendiste sobre el Comportamiento del Usuario?

**Principales Insights:**

1. **Abandono en Etapas Iniciales**
   - Los usuarios tienden a abandonar temprano
   - Falta de optimización en la página e-commerce

2. **Falta de Estrategias de Retención**
   - Pérdida significativa después de D7
   - Necesidad de campañas y notificaciones más activas

3. **Variaciones Regionales**
   - Comportamiento diferente por país
   - Oportunidad de localización

---

## 🎯 Recomendaciones Accionables

### CORTO PLAZO (1-2 semanas)
1. **Auditoría de UX del Carrito**
   - Simplificar flujo de agregar producto
   - Reducir fricción en el checkout

2. **Mostrar Información Crítica**
   - Precio total con envío
   - Estimado de entrega
   - Opciones de pago disponibles

### MEDIANO PLAZO (2-4 semanas)
1. **Email de Carrito Abandonado**
   - Recordatorio automático en 1-2 horas
   - Oferta de descuento (5-10%)

2. **Notificaciones Push**
   - Disponibilidad limitada
   - Flash sales

### LARGO PLAZO (1-3 meses)
1. **Programa de Retención**
   - Programa de lealtad
   - Recomendaciones personalizadas
   - Email nurturing

2. **Enfoque Regional**
   - Replicar estrategias de México/Perú en otros países
   - Ajustar según contexto local

---

## 📈 Métricas de Éxito

| Objetivo | Baseline | Target | Timeframe |
|----------|----------|--------|-----------|
| Select → Carrito | 11.01% | 15-18% | 60 días |
| Retención D7 | 85-87% | 85%+ | Continuo |
| Retención D28 | 2-3% | 5-8% | 90 días |
| Compras Recurrentes | 5-10% | 15%+ | 90 días |

---

## 📁 Archivos Incluidos

- `mercadolibre_funnel_retention_results.csv` - Datos completos del análisis
- `RESULTADOS_README.md` - Este archivo (resumen ejecutivo)

---

## 🔗 Enlaces Relacionados

- [README Principal](../README.md)
- [Metodología del Análisis](../documentation/methodology.md)
- [Diccionario de Datos](../documentation/data_dictionary.md)
- [Reporte Completo de Hallazgos](../documentation/findings_report.md)

---

## ✍️ Metadata

- **Análisis realizado:** 27/04/2026
- **Período analizado:** 01/01/2025 - 08/31/2025
- **Analista:** Oskar Arvizu
- **Estado:** Completo ✅
## 📈 Visualizaciones
Los resultados se pueden visualizar con:
- **Excel/Google Sheets** - Para tablas dinámicas rápidas
- **Power BI / Tableau** - Para dashboards interactivos
- **Python (Matplotlib/Seaborn)** - Para gráficos personalizados

Ver gráficos en `/results/visualizations/`

## 💡 Recomendaciones Accionables

1. **Reducir Fricción en Carrito**
   - Entre Browse (76.9%) y Add to Cart (11%) hay una caída crítica
   - Revisar UX del carrito, costo de envío, opciones de pago

2. **Mejorar Experiencia Post-Compra**
   - Caída dramática de 86% (D7) a 2-3% (D28)
   - Implementar estrategias de retención: newsletters, ofertas personalizadas

3. **Enfoque Regional**
   - Replicar prácticas de Perú/México en Argentina
   - Considerar factores culturales/económicos regionales

## 📧 Contacto
- Email: oskaraam@gmail.com
- LinkedIn: [oskarivizu](https://linkedin.com/in/oskarivizu)
- GitHub: [oskaraam-analistatec](https://github.com/oskaraam-analistatec)

## 📄 Licencia
MIT License - Ver archivo LICENSE para detalles
