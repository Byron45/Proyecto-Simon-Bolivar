# Simulación de Siniestralidad Vial en Quito: Avenida Simón Bolívar

> **Proyecto de Sistemas Colaborativos**
> Simulación basada en agentes (ABM) para analizar el impacto del clima y factores sociales en el tráfico de Quito.

![GAMA Platform](https://img.shields.io/badge/Platform-GAMA%201.9-blue)
![Status](https://img.shields.io/badge/Status-En%20Desarrollo-green)

## Descripción del Proyecto

Este proyecto busca simular y visualizar la dinámica de tráfico y accidentalidad en la **Avenida Simón Bolívar (Quito, Ecuador)**, una de las vías con mayor índice de siniestralidad del país.

Utilizando la plataforma **GAMA** y datos geográficos reales (GIS), hemos creado un entorno virtual donde agentes autónomos (vehículos) interactúan bajo reglas probabilísticas basadas en datos reales de tránsito. El objetivo es observar cómo variables externas (lluvia, horario nocturno) y factores humanos (consumo de alcohol) disparan la tasa de accidentes.

## Funcionalidades Principales

### Entorno Geográfico Real
- Integración de archivos **Shapefile (.shp)** de la red vial de Quito y sus barrios.
- Visualización dinámica con **Ciclo Día/Noche**: El mapa cambia de iluminación según la hora simulada (00:00 - 24:00).

### Agentes Inteligentes
Simulación de tres tipos de vehículos con comportamientos y físicas distintas:
- **Autos:** Comportamiento estándar.
- **Motos:** Mayor velocidad y riesgo base.
- **Camiones:** Menor velocidad pero mayor tamaño.

### Variables de Entorno (Interactividad)
El usuario puede modificar la simulación en tiempo real mediante sliders e interruptores:
- **Clima (Lluvia):** Reduce la velocidad global y aumenta la fricción/riesgo de choque.
- **Factor Social (Alcohol):** Permite inyectar un porcentaje de conductores en estado etílico, quienes conducen a exceso de velocidad y con patrones erráticos.

### Análisis de Datos en Tiempo Real
Panel de estadísticas integrado que muestra:
- **Gráfica de Serie Temporal:** Evolución del número de accidentes acumulados.
- **Gráfica de Pastel (Pie Chart):** Clasificación de las causas del accidente (Alcohol, Clima, Azar).

## Tecnologías Utilizadas

*   **Lenguaje:** GAML (GAMA Modeling Language).
*   **Plataforma:** GAMA Platform (versión 2024/2025).
*   **Datos GIS:** OpenStreetMap / Datos Abiertos Quito (Shapefiles).

## Estructura del Proyecto

```text
Sistemas-Colaborativos/
├── includes/              # Archivos de Mapas (GIS)
│   ├── Barrios_Final.shp  # Polígonos de los barrios de Quito
│   └── red_vial_unificada.shp # Líneas de carreteras y avenidas
├── models/                # Código Fuente
│   └── simulacion.gaml    # Lógica principal de la simulación
└── README.md              # Documentación
