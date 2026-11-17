/**
 * ESTILO DE EDICIÓN — configuración central.
 *
 * Todo el look del video sale de aquí: colores, tipografías, bordes, sombras,
 * subtítulos y la etiqueta de la serie. Para ajustar el estilo, cambia estos
 * valores; las escenas no tienen colores ni fuentes escritos a mano.
 *
 * Reglas del estilo (ver STYLE.md):
 *  - Identidad propia: editorial, chilena, con bordes negros y sombras duras.
 *  - Nada que delate edición con IA: sin asteriscos/destellos, sin "/comandos",
 *    sin terminales, sin pixel art, sin tipografía de código.
 *  - Datos siempre con fuente (INE, Banco Central) en letra chica.
 */
import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";

for (const w of ["700", "800"]) {
  loadFont({ family: "Bricolage Grotesque", url: staticFile(`fonts/Bricolage-${w}.woff2`), weight: w });
}
for (const w of ["500", "600", "700"]) {
  loadFont({ family: "Inter", url: staticFile(`fonts/Inter-${w}.woff2`), weight: w });
}

export const STYLE = {
  /** Etiqueta de la serie (arriba a la izquierda). Cambia "label" por tu @usuario si quieres. */
  series: { label: "CHILE ESTE MES", date: "NOV 2026" },

  font: {
    display: "'Bricolage Grotesque', sans-serif", // títulos, cifras y subtítulos
    body: "Inter, sans-serif", // textos chicos y etiquetas
  },

  color: {
    bg: "#F4F0E8", // crema del panel
    bgTop: "#E9E4DA",
    paper: "#FFFFFF", // tarjetas
    ink: "#16181D", // texto y bordes
    muted: "#6B6F7A",
    faint: "#E7E3DA",
    blue: "#2347D9", // color de marca
    yellow: "#FFD23F", // resaltador
    red: "#E63946", // malo / sube un costo
    green: "#1FA971", // bueno
    copper: "#C8693A", // cobre (solo para el cobre)
  },

  /** Bordes negros y sombras duras: la firma visual del canal. */
  stroke: 4,
  radius: 26,
  shadow: (px = 8) => `${px}px ${px}px 0 #16181D`,

  caption: {
    size: 60,
    maxWords: 3,
    maxChars: 18,
    unspoken: "#A3A6AE",
  },

  layout: {
    panel: 760, // alto del panel de gráficos en pantalla dividida
    speakerOffset: 560, // cuánto baja tu video para que tu cara quede bajo el panel
  },
} as const;

export const C = STYLE.color;
export const F = STYLE.font;
