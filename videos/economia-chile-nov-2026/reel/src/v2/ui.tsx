import React from "react";
import { loadFont } from "@remotion/fonts";
import { Easing, interpolate, staticFile, useCurrentFrame } from "remotion";

for (const w of ["700", "800"]) {
  loadFont({ family: "JetBrains Mono", url: staticFile(`fonts/JetBrainsMono-${w}.woff2`), weight: w });
}
for (const w of ["500", "600", "700"]) {
  loadFont({ family: "Inter", url: staticFile(`fonts/Inter-${w}.woff2`), weight: w });
}

export const mono = "'JetBrains Mono', monospace";
export const sans = "Inter, sans-serif";

export const K = {
  cream: "#EFECE6",
  creamTop: "#D8D5CF",
  ink: "#141416",
  frame: "#2C3163",
  inner: "#121214",
  orange: "#E8743B",
  orangeHi: "#F28C3A",
  red: "#E5484D",
  green: "#34C77B",
  grey: "#8B8B8B",
  line: "#2A2A2E",
  white: "#FFFFFF",
  copper: "#C8693A",
  blue: "#4C8DF6",
  yellow: "#F2C94C",
};

export const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;
const easeOut = Easing.bezier(0.16, 1, 0.3, 1);
const back = Easing.bezier(0.34, 1.56, 0.64, 1);

export const prog = (f: number, a: number, b: number) =>
  interpolate(f, [a, b], [0, 1], { ...clamp, easing: easeOut });
export const pop = (f: number, a: number, d = 12) =>
  interpolate(f, [a, a + d], [0, 1], { ...clamp, easing: back });
export const count = (f: number, a: number, b: number, to: number, from = 0) =>
  interpolate(f, [a, b], [from, to], { ...clamp, easing: Easing.bezier(0.22, 1, 0.36, 1) });
export const fmt = (n: number, d = 0) =>
  n.toLocaleString("es-CL", { minimumFractionDigits: d, maximumFractionDigits: d });

/* ------------------------------------------------------------------ */
/* App-window card: navy frame, black inside, header with ✳ + /slug   */
/* ------------------------------------------------------------------ */

export const Card: React.FC<{
  title: string;
  slug: string;
  right?: React.ReactNode;
  tag?: string;
  top?: number;
  height?: number;
  children: React.ReactNode;
  at?: number;
}> = ({ title, slug, right, tag, top = 215, height = 470, children, at = 0 }) => {
  const f = useCurrentFrame();
  const p = pop(f, at, 14);
  return (
    <div
      style={{
        position: "absolute",
        left: 70,
        right: 70,
        top,
        height,
        background: K.frame,
        borderRadius: 38,
        padding: 20,
        boxShadow: "0 22px 50px rgba(20,20,40,0.28)",
        scale: String(0.9 + 0.1 * p),
        opacity: Math.min(1, p * 1.6),
        translate: `0px ${(1 - p) * 30}px`,
      }}
    >
      <div
        style={{
          position: "relative",
          width: "100%",
          height: "100%",
          background: K.inner,
          borderRadius: 24,
          overflow: "hidden",
          fontFamily: sans,
          color: K.white,
        }}
      >
        <div style={{ position: "absolute", top: 26, left: 30, right: 30, display: "flex", alignItems: "center", gap: 14 }}>
          <span style={{ color: K.orange, fontSize: 40, fontWeight: 700, lineHeight: 1 }}>✳</span>
          <span style={{ fontWeight: 700, fontSize: 36 }}>{title}</span>
          <span style={{ fontFamily: mono, fontWeight: 700, fontSize: 24, color: K.grey }}>{slug}</span>
          <span style={{ flex: 1 }} />
          {right}
        </div>
        {children}
        {tag ? (
          <div
            style={{
              position: "absolute",
              right: 22,
              bottom: 20,
              background: "#ECECEC",
              color: K.ink,
              fontFamily: mono,
              fontWeight: 800,
              fontSize: 24,
              padding: "6px 16px",
              borderRadius: 999,
            }}
          >
            {tag}
          </div>
        ) : null}
      </div>
    </div>
  );
};

/* Big orange monospace title with hard shadow ("LA MEJOR" look). */
export const BigTitle: React.FC<{ text: string; top: number; at?: number; size?: number; color?: string }> = ({
  text,
  top,
  at = 0,
  size = 120,
  color = K.orange,
}) => {
  const f = useCurrentFrame();
  const p = pop(f, at, 12);
  return (
    <div
      style={{
        position: "absolute",
        top,
        left: 40,
        right: 40,
        textAlign: "center",
        fontFamily: mono,
        fontWeight: 800,
        fontSize: size,
        letterSpacing: 2,
        lineHeight: 1.05,
        color,
        textShadow: "0 7px 0 #3A2A22",
        scale: String(0.7 + 0.3 * p),
        opacity: Math.min(1, p * 1.5),
      }}
    >
      {text}
    </div>
  );
};

/* Dark pill with orange text ("TODAS" look). */
export const DarkPill: React.FC<{ text: string; top: number; at?: number; size?: number; color?: string }> = ({
  text,
  top,
  at = 0,
  size = 70,
  color = K.orangeHi,
}) => {
  const f = useCurrentFrame();
  const p = pop(f, at, 12);
  return (
    <div style={{ position: "absolute", top, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
      <div
        style={{
          background: "#2B2B2B",
          borderRadius: 12,
          padding: "6px 28px",
          fontFamily: mono,
          fontWeight: 800,
          fontSize: size,
          color,
          letterSpacing: 2,
          boxShadow: "0 8px 20px rgba(0,0,0,0.25)",
          scale: String(p),
        }}
      >
        {text}
      </div>
    </div>
  );
};

/* Light pill tag (e.g. "FUENTE: INE"). */
export const LightPill: React.FC<{ text: string; color?: string; bg?: string; size?: number }> = ({
  text,
  color = K.ink,
  bg = "#ECECEC",
  size = 24,
}) => (
  <span
    style={{
      background: bg,
      color,
      fontFamily: mono,
      fontWeight: 800,
      fontSize: size,
      padding: "6px 16px",
      borderRadius: 999,
      whiteSpace: "nowrap",
    }}
  >
    {text}
  </span>
);

/* Hand-drawn style red circle that draws itself. */
export const RedCircle: React.FC<{ cx: number; cy: number; rx: number; ry: number; at?: number }> = ({
  cx,
  cy,
  rx,
  ry,
  at = 0,
}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + 14);
  const len = 2 * Math.PI * Math.sqrt((rx * rx + ry * ry) / 2);
  return (
    <svg width={1080} height={1920} style={{ position: "absolute", left: 0, top: 0, pointerEvents: "none" }}>
      <ellipse
        cx={cx}
        cy={cy}
        rx={rx}
        ry={ry}
        fill="none"
        stroke={K.red}
        strokeWidth={9}
        strokeDasharray={len}
        strokeDashoffset={len * (1 - p)}
        transform={`rotate(-8 ${cx} ${cy})`}
        strokeLinecap="round"
      />
    </svg>
  );
};

/* Pixel art from a character grid. */
const PAL: Record<string, string> = {
  k: "#1E1E22",
  w: "#FFFFFF",
  o: K.orange,
  r: K.red,
  g: K.green,
  y: K.yellow,
  b: K.blue,
  c: K.copper,
  s: "#9A9AA2",
  d: "#5A5A66",
  n: K.frame,
  p: "#F2E3C9",
};
export const Pixel: React.FC<{ grid: string[]; size: number; style?: React.CSSProperties; palette?: Record<string, string> }> = ({
  grid,
  size,
  style,
  palette,
}) => {
  const h = grid.length;
  const w = Math.max(...grid.map((r) => r.length));
  const pal = { ...PAL, ...(palette ?? {}) };
  return (
    <svg width={w * size} height={h * size} style={{ imageRendering: "pixelated", ...style }} shapeRendering="crispEdges">
      {grid.flatMap((row, y) =>
        row.split("").map((ch, x) =>
          ch === "." ? null : <rect key={`${x}-${y}`} x={x * size} y={y * size} width={size} height={size} fill={pal[ch] ?? ch} />
        )
      )}
    </svg>
  );
};

export const PX = {
  person: ["..kk..", ".kkkk.", ".kkkk.", "..kk..", "kkkkkk", "kkkkkk", ".kkkk.", ".k..k.", ".k..k."],
  phone: ["kkkkkkk", "kbbbbbk", "kbbbbbk", "kbwbbbk", "kbbbbbk", "kbbbbbk", "kbbbbbk", "kbbbbbk", "kkkkkkk", "kkkwkkk", "kkkkkkk"],
  car: ["....kkkkkk....", "...kbbkbbbk...", "..kbbbkbbbbk..", "rrrrrrrrrrrrrr", "rrwrrrrrrrrryr", "rrrrrrrrrrrrrr", "rkkkrrrrrrkkkr", "..kk......kk.."],
  pump: ["rrrrrr...", "rwwwwr...", "rwwwwr.k.", "rrrrrr..k", "rrrrrrk.k", "rrrrrr.kk", "rrrrrr..k", "rrrrrr..k", "rrrrrrkkk", "rrrrrr...", "kkkkkkk..", "kkkkkkk.."],
  factory: [
    "..ss............",
    "..kk......ss....",
    "..kk......kk....",
    "..kk.k....kk.k..",
    "..kkkk...kkkkk..",
    "..kkkkk.kkkkkkk.",
    "kkkkkkkkkkkkkkkk",
    "kyykyykyykyykyyk",
    "kyykyykyykyykyyk",
    "kkkkkkkkkkkkkkkk",
    "kkkkkkkoookkkkkk",
    "kkkkkkkoookkkkkk",
  ],
  tag: ["....gggggggggg", "...ggggggggggg", "..gggggggggggg", ".ggwwggggggggg", "gggwwggggggggg", ".ggggggggggggg", "..gggggggggggg", "...ggggggggggg", "....gggggggggg"],
  arrowUp: ["...rr...", "..rrrr..", ".rrrrrr.", "rrrrrrrr", "...rr...", "...rr...", "...rr...", "...rr..."],
  arrowDown: ["...gg...", "...gg...", "...gg...", "...gg...", "gggggggg", ".gggggg.", "..gggg..", "...gg..."],
  coin: ["..cccc..", ".cyyyyc.", "cyycyyyc", "cyycyyyc", "cyycyyyc", "cyycyyyc", ".cyyyyc.", "..cccc.."],
  lock: ["..kkkk..", ".k....k.", ".k....k.", "yyyyyyyy", "yyyyyyyy", "yyykkyyy", "yyykkyyy", "yyyyyyyy"],
  wallet: ["..oooooooooo", ".ooooooooooo", "kkkkkkkkkkkk", "kooooooooooo", "koooooooyyyo", "koooooooyyyo", "kooooooooooo", "kkkkkkkkkkkk"],
  bulb: ["..yyyy..", ".yyyyyy.", "yyyyyyyy", "yyywyyyy", "yyyyyyyy", ".yyyyyy.", "..yyyy..", "..ssss..", "..ssss..", "...ss..."],
  doc: ["wwwwwwww.", "wkkkkkkww", "wwwwwwwww", "wkkkkkwww", "wwwwwwwww", "wkkkkkkkw", "wwwwwwwww", "wkkkkwwww", "wwwwwwgww", "wwwwwgggw", "wwwwwwgww"],
};
