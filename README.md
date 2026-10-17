# Cuadra — finanzas personales para iPhone (Chile)

App nativa para iPhone que conecta tus cuentas bancarias chilenas, clasifica automáticamente tus
ingresos y gastos, te muestra estadísticas por día, semana, mes, trimestre, año o rango libre, y actúa
como asesor financiero con conclusiones y un plan de presupuesto personalizado.

La especificación completa (el prompt mejorado) está en [`PROMPT.md`](PROMPT.md).

## Qué incluye

| Área | Funciones |
| --- | --- |
| **Conexión** | Bancos vía Fintoc (Santander, Banco de Chile, BancoEstado, BCI, Itaú, Scotiabank, Security, BICE, Falabella y otros), varias cuentas y bancos a la vez, sincronización incremental sin duplicados, importación de cartolas CSV, registro manual (efectivo). |
| **Clasificación** | 33 categorías chilenas en Necesidades / Deseos / Ahorro / Ingresos / Internos, más de 400 palabras clave de comercios locales, nombres de comercio limpios, reglas que aprenden de tus correcciones, detección de transferencias entre cuentas propias y pagos de tarjeta (no se cuentan dos veces), categorías personalizadas. |
| **Estadísticas** | Ingresos, gastos, flujo neto, tasa de ahorro, promedio diario, proyección al cierre (sin inflar por gastos fijos o compras puntuales), dona por categoría, gasto por día/semana/mes, por día de la semana, por hora, tendencia de 6 meses, comparación con el período anterior, comercios principales, gastos más grandes, gastos hormiga, gastos recurrentes y próximo cobro. |
| **Asesor** | Puntaje de salud financiera (0–100) explicado, distribución real vs. 50/30/20 (o la regla que elijas), hasta 15 tipos de conclusiones priorizadas, plan de presupuesto aplicable con un toque, alertas al 80 %/100 %, metas de ahorro con aporte mensual necesario. |
| **Privacidad** | Datos solo en el iPhone (protección de archivos de iOS), bloqueo con Face ID, token en el Llavero, la clave del banco nunca pasa por la app, exportación CSV y borrado total. |
| **Diseño** | SwiftUI nativo, minimalista, modo claro/oscuro, Swift Charts, SF Symbols, tipografía del sistema, háptica. Todo en español de Chile y montos `$1.234.567`. |

## Estructura

```
ios/
  Cuadra.xcodeproj        Proyecto listo para abrir en Xcode (generado con XcodeGen desde project.yml)
  Cuadra/                 App SwiftUI (pantallas, estado, diseño)
  CuadraCore/             Motor en Swift puro + 42 pruebas: categorización, períodos, estadísticas,
                          recurrentes, asesor, importador CSV, sincronización, cliente del backend
backend/                  Servidor Node.js sin dependencias que guarda la llave secreta de Fintoc
                          y cifra las conexiones (AES-256-GCM) + 8 pruebas
```

## 1. Probar la app (sin banco)

Requisitos: Mac con **Xcode 15 o superior** e iPhone con **iOS 17+**.

1. Abre `ios/Cuadra.xcodeproj`.
2. En *Signing & Capabilities* del target **Cuadra**, elige tu *Team* (sirve una cuenta Apple gratuita) y,
   si Xcode lo pide, cambia el *Bundle Identifier* (`cl.cuadra.app`) por uno propio.
3. Conecta tu iPhone, selecciónalo y presiona ▶︎. La primera vez, en el iPhone ve a
   *Ajustes › General › VPN y gestión de dispositivos* y confía en tu certificado de desarrollador.
4. En la bienvenida elige **"Probar con datos de ejemplo"** para recorrer todo con 6 meses de datos ficticios.

> Si modificas `ios/project.yml`, regenera el proyecto con `brew install xcodegen && cd ios && xcodegen`.

## 2. Conectar tus bancos reales

Los bancos chilenos no tienen una API pública para personas, así que la conexión se hace con un
agregador autorizado. Cuadra usa **[Fintoc](https://fintoc.com)**. La llave secreta del agregador
**no puede ir dentro de la app**, por eso existe el pequeño servidor de `backend/`.

1. **Crea una cuenta en Fintoc** y obtén tu llave pública (`pk_...`) y secreta (`sk_...`) en el dashboard.
   Revisa sus condiciones y costos: Fintoc está orientado a empresas y el acceso al producto de
   movimientos puede requerir activación.
2. **Configura el servidor**:
   ```bash
   cd backend
   cp .env.example .env
   node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"     # -> ENCRYPTION_KEY
   node -e "console.log(require('crypto').randomBytes(24).toString('base64url'))"  # -> APP_SECRET
   # completa .env con tus llaves de Fintoc y los dos valores anteriores
   npm test     # opcional: corre las pruebas
   npm start
   ```
3. **Publícalo con HTTPS** (iOS exige HTTPS). Cualquier servicio que ejecute Docker sirve
   (Render, Railway, Fly.io, un VPS): usa el `Dockerfile` incluido, define las variables de `.env.example`
   y monta un volumen persistente en `/data`. Define `PUBLIC_URL` con la dirección final.
4. **En la app**: *Ajustes › Conexión bancaria* → escribe la dirección del servidor y tu `APP_SECRET`
   → *Vincular este iPhone* → *Conectar un banco*. Se abre la ventana segura de Fintoc donde eliges
   tu banco (por ejemplo Santander) e ingresas tus credenciales allí, no en Cuadra.
5. La app sincroniza al conectar, al abrir la app (si pasaron más de 6 horas) y al deslizar hacia abajo
   en Inicio. La primera vez trae 12 meses de historia.

Si el banco pide volver a ingresar la clave (cambio de contraseña, bloqueo), la conexión aparece como
*Requiere reconectar*.

### Sin servidor: importar cartolas

En *Ajustes › Importar cartola (CSV)* puedes cargar el archivo de movimientos que descargas desde la
web de tu banco (guárdalo como CSV desde Excel o Numbers). Se detectan automáticamente las columnas
de fecha, descripción y monto o cargos/abonos, y los formatos chilenos (`1.234.567`, `dd/mm/aaaa`).
Reimportar la misma cartola no duplica movimientos.

## 3. Pruebas

```bash
cd ios/CuadraCore && swift test     # motor (macOS o Linux)
cd backend && npm test              # servidor (Node 20+)
```

## Notas y límites conocidos

- **Horas de los movimientos**: muchos bancos informan solo la fecha. Las estadísticas por hora usan
  los movimientos que sí la traen (y todos los ingresados a mano) y la app lo indica.
- **Tarjetas de crédito**: conecta también la tarjeta para ver en qué se usó; los pagos de tarjeta desde la
  cuenta corriente se marcan como movimiento interno para no contar el gasto dos veces.
- **Integración con Fintoc**: está aislada en `backend/src/fintoc.js` y `backend/public/connect.html`.
  Antes de usarla en producción verifica en la documentación de Fintoc que el flujo del widget
  (`onSuccess` → `exchange_token` → `GET /v1/links/exchange`) siga vigente; si cambia, solo esos dos
  archivos se ajustan. Con el Sistema de Finanzas Abiertas (Ley Fintec 21.521) podrán sumarse otros
  proveedores sin tocar la app.
- **Recomendaciones**: son educativas, basadas en reglas transparentes sobre tus datos; no son
  asesoría financiera regulada.
- La app se compiló a nivel de lógica (paquete `CuadraCore` y capa de estado) y sus pruebas se ejecutaron
  en este entorno; las vistas SwiftUI requieren Xcode para compilarse.
