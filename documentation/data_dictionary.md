Data Dictionary - Diccionario de Datos
Tablas Utilizadas en el Análisis
📊 Tabla: `users`
Contiene información demográfica de los usuarios de la plataforma.
Columna	Tipo de Dato	Descripción
`user_id`	INT PRIMARY KEY	Identificador único del usuario
`country`	VARCHAR(2)	Código de país (AR = Argentina, PE = Perú, MX = México)
`created_at`	TIMESTAMP	Fecha y hora de creación de la cuenta
Notas:
Cada usuario tiene un ID único e inmutable
Los códigos de país siguen el estándar ISO 3166-1 alpha-2
---
📋 Tabla: `events`
Registra todos los eventos/interacciones del usuario en la plataforma.
Columna	Tipo de Dato	Descripción
`event_id`	INT PRIMARY KEY	Identificador único del evento
`user_id`	INT FOREIGN KEY	Referencia a la tabla users
`event_type`	VARCHAR(50)	Tipo de evento realizado por el usuario
`event_date`	DATE	Fecha del evento
`timestamp`	TIMESTAMP	Fecha y hora exacta del evento
Tipos de Eventos Disponibles:
`first_visit` - Primera visita del usuario a la plataforma
`select_item` - Usuario visualiza/selecciona un artículo
`add_to_cart` - Usuario agrega un artículo al carrito de compras
`purchase` - Usuario completa una compra
`remove_from_cart` - Usuario quita un artículo del carrito
`checkout` - Usuario inicia el proceso de pago
Notas:
Un usuario puede generar múltiples eventos en diferentes fechas
Los eventos están ordenados por timestamp
---
💰 Tabla: `purchases`
Registro de todas las transacciones completadas en la plataforma.
Columna	Tipo de Dato	Descripción
`purchase_id`	INT PRIMARY KEY	Identificador único de la compra
`user_id`	INT FOREIGN KEY	Referencia a la tabla users
`purchase_date`	DATE	Fecha en que se completó la compra
`amount`	DECIMAL(10, 2)	Monto total de la compra en moneda local
`items_count`	INT	Número de artículos en la compra
`payment_method`	VARCHAR(50)	Método de pago utilizado
Notas:
Cada compra es única e inmutable
Un usuario puede tener múltiples compras
El monto está en la moneda local de cada país
---
Relaciones Entre Tablas
```
users ──┬──> events (user_id)
        └──> purchases (user_id)
```
`users.user_id` ← → `events.user_id` (1 a Muchos)
`users.user_id` ← → `purchases.user_id` (1 a Muchos)
---
Cálculos Derivados Utilizados
Embudo de Compra
Definición: Seguimiento del progreso del usuario a través de diferentes etapas hacia la compra.
Etapas:
Primera Visita - Usuario accede por primera vez (evento: `first_visit`)
Seleccionar Artículo - Usuario visualiza un artículo (evento: `select_item`)
Agregar al Carrito - Usuario agrega artículo al carrito (evento: `add_to_cart`)
Compra Completada - Usuario completa la transacción (tabla: `purchases`)
Cálculo de Tasa de Conversión:
```
Tasa de Conversión (%) = (Usuarios en Etapa N / Usuarios en Etapa N-1) × 100
```
Retención por Cohortes
Definición: Seguimiento de qué porcentaje de usuarios de una cohorte regresan en días específicos.
Métricas:
D7 Retention - % de usuarios que regresaron dentro de 7 días
D14 Retention - % de usuarios que regresaron dentro de 14 días
D21 Retention - % de usuarios que regresaron dentro de 21 días
D28 Retention - % de usuarios que regresaron dentro de 28 días
Cálculo:
```
Dn Retention (%) = (Usuarios que retornaron en n días / Total de usuarios en cohorte) × 100
```
Días Hasta Compra
Definición: Número de días entre la primera visita del usuario y su primera compra.
Cálculo:
```
Días Hasta Compra = purchase_date - primer_evento_date
```
---
Rangos de Datos
Aspecto	Valor
Período de Análisis	Enero 2025 - Presente
Países Cubiertos	Argentina (AR), Perú (PE), México (MX)
Usuarios Totales	~50,000 usuarios únicos
Total de Eventos	~500,000+ eventos registrados
Total de Compras	~5,000+ transacciones
---
Notas Importantes
Consistencia de Datos: Los datos son lo que reflejan la realidad operacional al momento de la exportación.
Identificadores Únicos: Todos los IDs (user_id, event_id, purchase_id) son únicos e inmutables.
Zonas Horarias: Los timestamps están en UTC. Convertir a zonas horarias locales según sea necesario.
Valores Nulos: Si falta información en eventos o compras, se interpreta como que el usuario NO completó esa acción.
Duplicados: No existen registros duplicados en ninguna tabla.
Auditoría: Las tablas no contienen información de eliminación (soft delete) - se considera que todos los datos presentes son válidos.
