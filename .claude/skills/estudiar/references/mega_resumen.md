# Mega resumen — especificación ("como siempre")

Se hace **al terminar de estudiar una prueba**. Siempre la misma estructura y estilo, para que cada
resumen se vea igual que los anteriores.

## Formato

- Página HTML visual, a partir de `templates/mega_resumen.html` (copiar y rellenar).
- Guardar en `estudio/<ramo>/<evaluacion>/mega_resumen.html`.
- Publicarla con la herramienta Artifact (cargar antes la skill `artifact-design`) para abrirla
  en el navegador o el celular. Si Artifact no está disponible, entregar el archivo HTML.
- Fórmulas **siempre** como ecuaciones LaTeX (se renderizan con KaTeX): `\( ... \)` en línea,
  `\[ ... \]` destacadas.
- Gráficos **cuando sirvan**: curvas de oferta/demanda, funciones y sus derivadas, regiones de
  optimización, etc. Usar SVG en línea o Chart.js (ya incluido en la plantilla). Ejes rotulados.
- Claro antes que bonito: frases cortas, viñetas, nada de párrafos largos.

## Secciones (en este orden)

1. **Encabezado** — ramo, evaluación, fecha, contenidos que entran.
2. **Mapa de la prueba** — los temas en orden y cómo se conectan (3–8 tarjetas).
3. **Conceptos clave** — por tema: definición corta + intuición en una línea.
4. **Fórmulas** — cada una como ecuación, con qué es cada variable y cuándo se usa.
5. **Gráficos** — los que ayuden a entender o que suelen preguntar, con una línea de lectura.
6. **Ejemplos tipo** — 1–3 ejercicios representativos con los pasos clave (no todo el desarrollo).
7. **Mis errores de la sesión** — sacados del registro `sesion.md`: qué respondí, lo correcto, y cómo
   no repetirlo. Esta sección es obligatoria y va destacada.
8. **Tips para la prueba** — trampas típicas, qué revisar al final, manejo del tiempo, qué suele
   preguntar ese ramo.
9. **Checklist final** — 5–10 cosas que debe saber hacer sin mirar.
