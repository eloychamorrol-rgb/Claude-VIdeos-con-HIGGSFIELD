# Reel: Economía chilena hoy (noviembre 2026)

Proyecto de edición en [Remotion](https://remotion.dev) del reel educativo.

- `scripts/chunks.py`: detecta los tramos con voz y los transcribe con Whisper para encontrar errores y repeticiones.
- `scripts/cut.py`: plan de edición (qué tomas se quedan) y corte del video crudo en `public/cut.mp4`.
- `src/data/segments.json` y `src/data/words.json`: los tramos del corte y el tiempo de cada palabra (para subtítulos y animaciones).
- `src/v2/ui.tsx`: sistema visual (tarjetas tipo app, títulos naranjos, pastillas, círculo rojo, pixel art).
- `src/v2/scenes.tsx`: una escena por cada parte del guion.
- `src/v2/Captions.tsx`: subtítulos en caja oscura en la unión panel/video, palabra clave en naranjo.
- `src/Reel.tsx`: composición final: panel crema arriba, tú abajo, escenas a pantalla completa y efectos de sonido.

`public/cut.mp4` no se versiona por su peso. Para regenerarlo, sigue los pasos de `scripts/`.

```bash
npx remotion studio
```

```bash
npx remotion render EconomiaChile out/render.mp4 --codec=h264 --crf=18
```
