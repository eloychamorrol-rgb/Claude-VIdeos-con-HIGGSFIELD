# Prompt mejorado — "Cuadra", finanzas personales para iPhone (Chile)

> Versión refinada del pedido original. Es la especificación con la que se construyó este repositorio.

## 1. Objetivo

Construir una app nativa para **iPhone** que conecte las cuentas bancarias del usuario en **Chile**
(Santander Chile como prioridad, y el resto de bancos e instituciones que operan en Chile, sean de
capital nacional o extranjero), registre automáticamente sus **ingresos y gastos**, los **clasifique por
categoría**, genere **estadísticas completas** para cualquier rango de tiempo y entregue
**conclusiones y recomendaciones** como lo haría un asesor financiero, personalizadas para cada usuario.

## 2. Conexión con bancos (realista y segura)

- Los bancos chilenos **no ofrecen una API pública para personas**. La conexión se hace mediante un
  **agregador financiero regulado/autorizado** (implementado: **Fintoc**, que cubre Santander,
  Banco de Chile, BancoEstado, BCI, Itaú, Scotiabank, Security, BICE, Falabella, entre otros).
  El Sistema de Finanzas Abiertas de la Ley Fintec (Ley 21.521, NCG 514 CMF) se irá implementando por
  fases; la arquitectura queda preparada para cambiar de proveedor sin tocar la app.
- La app **nunca ve ni guarda la clave del banco**: el usuario la ingresa en el widget del agregador.
- La **llave secreta** del agregador vive solo en un **backend propio** (nunca dentro de la app). El
  backend guarda los `link_token` **cifrados (AES-256-GCM)** y la app se autentica con un token propio
  guardado en el **Llavero (Keychain)** de iOS.
- Alternativas sin conexión: **importar cartola** (CSV exportado desde el banco, detección automática de
  columnas y formatos chilenos `1.234.567`, `dd/mm/aaaa`) y **registro manual** (incluye efectivo).
- Múltiples bancos y cuentas a la vez (corriente, vista/RUT, ahorro, tarjeta de crédito, línea de crédito).
- Sincronización **incremental** (solo movimientos nuevos), sin duplicados, y reemplazando movimientos
  "pendientes" cuando el banco los contabiliza.

## 3. Clasificación de movimientos

- Categorías por defecto pensadas para Chile, agrupadas en **Necesidades / Deseos / Ahorro / Ingresos /
  Movimientos internos**: vivienda (arriendo, dividendo, gastos comunes), cuentas básicas (luz, agua, gas,
  internet, telefonía), supermercado, transporte (Metro, Red, Uber, DiDi, Cabify), auto (bencina, TAG,
  estacionamiento), salud (isapre, Fonasa, farmacias), educación, seguros, créditos e intereses,
  comisiones bancarias, impuestos y trámites, restaurantes, delivery, suscripciones, compras, hogar,
  entretención, viajes, cuidado personal, deporte, mascotas, regalos, efectivo, transferencias, etc.
- Motor de reglas con **cientos de comercios chilenos** (Líder, Jumbo, Copec, Enel, Aguas Andinas,
  Entel, Netflix, Rappi, Cruz Verde, Falabella, Mercado Libre…) y **nombre de comercio limpio**.
- **Aprende del usuario**: al re-categorizar un movimiento puede aplicarse a todos los del mismo comercio.
- Detecta **transferencias entre cuentas propias** y **pagos de tarjeta** para no contar dos veces el gasto.
- Categorías personalizadas.

## 4. Períodos y estadísticas

- Períodos: **día, semana, mes, trimestre, año y rango personalizado**, con navegación hacia atrás/adelante
  y **comparación con el período anterior**.
- Métricas: ingresos, gastos, ahorro, flujo neto, **tasa de ahorro**, gasto promedio diario,
  **proyección a fin de período**, distribución por categoría (monto, % y cantidad), **por día de la
  semana**, **por hora del día** (cuando el banco entrega la hora), por día, **tendencia de 6 meses**,
  principales comercios, gastos más grandes, **gastos hormiga** y **gastos fuera de lo normal**.
- **Gastos recurrentes**: detección automática de suscripciones y cuentas (semanal, quincenal, mensual,
  anual), costo mensual/anual y **próximo cobro estimado**.
- Detalle diario / semanal / mensual de cada categoría (ej.: transporte, suscripciones, cuentas por pagar).

## 5. Asesor financiero

- **Perfil personalizado**: ingreso mensual (o estimado automáticamente), objetivo principal (ahorrar,
  salir de deudas, fondo de emergencia, invertir, controlar gastos), vivienda, dependientes y regla de
  distribución (**50/30/20**, 70/20/10, 60/30/10 o personalizada).
- **Puntaje de salud financiera (0–100)** desglosado: tasa de ahorro, peso de necesidades, fondo de
  emergencia, carga de deuda y comisiones, cumplimiento de presupuestos.
- **Conclusiones automáticas** priorizadas (alertas, advertencias, logros): déficit proyectado,
  distribución real vs. ideal, suscripciones acumuladas, gastos hormiga anualizados, alzas por
  categoría, comisiones bancarias, carga financiera, fondo de emergencia, gasto de fin de semana,
  próximos cobros, movimientos inusuales y consejos según el objetivo.
- **Plan de presupuesto sugerido** por categoría a partir del historial y la regla elegida, aplicable con
  un toque, con **alertas al 80 % y 100 %** (notificaciones locales).
- **Metas de ahorro** con progreso y aporte mensual necesario.
- Aviso claro: son recomendaciones educativas, no asesoría financiera regulada.

## 6. Diseño

- Nativo iOS (SwiftUI, iOS 17+), **minimalista**, estilo apps de Apple: tipografía del sistema,
  números redondeados con transición numérica, tarjetas sobre fondo agrupado, SF Symbols, modo claro y
  oscuro, Dynamic Type, háptica sutil y gráficos con Swift Charts. Nada de estética "genérica de IA".
- Todo en **español de Chile** y montos en **CLP** (`$1.234.567`).

## 7. Privacidad y seguridad

- Datos guardados **solo en el iPhone**, con protección de archivos de iOS; bloqueo con **Face ID**.
- Exportar a CSV y borrar todos los datos en cualquier momento.
- Modo **demo** con datos de ejemplo para probar sin conectar el banco.

## 8. Calidad

- Lógica (categorización, períodos, estadísticas, recurrentes, asesor, importador) en un paquete Swift
  independiente **con pruebas automatizadas**; backend con pruebas.
- Manejo explícito de errores de red, de credenciales vencidas del banco y de formatos inválidos.
