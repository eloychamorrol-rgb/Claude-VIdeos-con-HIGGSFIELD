# Reel: Economía chilena hoy (noviembre 2026)

Proyecto de edición en [Remotion](https://remotion.dev) del reel educativo.

- `scripts/chunks.py`: detecta los tramos con voz y los transcribe con Whisper para encontrar errores y repeticiones.
- `scripts/cut.py`: plan de edición (qué tomas se quedan) y corte del video crudo en `public/cut.mp4`.
- `src/data/segments.json` y `src/data/words.json`: los tramos del corte y el tiempo de cada palabra (para subtítulos y animaciones).
- `src/components/Graphics.tsx`: gráficos animados (desempleo, inflación, PIB, cobre, tasa, dólar, megarreforma, proyección).
- `src/Reel.tsx`: composición final (pantalla dividida, zooms, subtítulos, efectos de sonido y barra de progreso).

`public/cut.mp4` no se versiona por su peso. Para regenerarlo, sigue los pasos de `scripts/`.

```bash
npx remotion studio
```

```bash
npx remotion render EconomiaChile out/render.mp4 --codec=h264 --crf=18
```
