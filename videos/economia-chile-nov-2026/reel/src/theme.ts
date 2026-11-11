import { loadFont } from "@remotion/fonts";
import { staticFile } from "remotion";

for (const w of ["700", "800", "900"]) {
  loadFont({ family: "Montserrat", url: staticFile(`fonts/Montserrat-${w}.woff2`), weight: w });
}
for (const w of ["500", "600", "700"]) {
  loadFont({ family: "Inter", url: staticFile(`fonts/Inter-${w}.woff2`), weight: w });
}

export const display = "Montserrat, sans-serif";
export const body = "Inter, sans-serif";

import { Easing, interpolate } from "remotion";

export const C = {
  ink: "#0B1020",
  panel: "rgba(11, 16, 32, 0.86)",
  panelSolid: "#111933",
  line: "rgba(255,255,255,0.14)",
  white: "#FFFFFF",
  muted: "#AEB8D6",
  yellow: "#FFD23F",
  red: "#FF4D5E",
  green: "#2EE59D",
  blue: "#4DA3FF",
  copper: "#E8834A",
  orange: "#FF9F1C",
};

export const ease = Easing.bezier(0.16, 1, 0.3, 1);
export const clamp = {
  extrapolateLeft: "clamp",
  extrapolateRight: "clamp",
} as const;

/** 0 → 1 over [a, b] frames with a smooth ease-out. */
export const prog = (frame: number, a: number, b: number) =>
  interpolate(frame, [a, b], [0, 1], { ...clamp, easing: ease });

/** Springy pop 0 → 1 (slight overshoot). */
export const pop = (frame: number, start: number, dur = 12) =>
  interpolate(frame, [start, start + dur], [0, 1], {
    ...clamp,
    easing: Easing.bezier(0.34, 1.56, 0.64, 1),
  });

/** Fade the whole element out over the last `n` frames of a sequence. */
export const outro = (frame: number, total: number, n = 8) =>
  interpolate(frame, [total - n, total], [1, 0], clamp);

export const fmtCL = (n: number, decimals = 0) =>
  n.toLocaleString("es-CL", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
