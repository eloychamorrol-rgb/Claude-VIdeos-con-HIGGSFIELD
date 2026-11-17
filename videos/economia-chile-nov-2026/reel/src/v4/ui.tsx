import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import { C, F, STYLE } from "./theme";

export const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;
const easeOut = Easing.bezier(0.16, 1, 0.3, 1);
const back = Easing.bezier(0.34, 1.56, 0.64, 1);

export const prog = (f: number, a: number, b: number) => interpolate(f, [a, b], [0, 1], { ...clamp, easing: easeOut });
export const pop = (f: number, a: number, d = 12) => interpolate(f, [a, a + d], [0, 1], { ...clamp, easing: back });
export const count = (f: number, a: number, b: number, to: number, from = 0) =>
  interpolate(f, [a, b], [from, to], { ...clamp, easing: Easing.bezier(0.22, 1, 0.36, 1) });
export const fmt = (n: number, d = 0) => n.toLocaleString("es-CL", { minimumFractionDigits: d, maximumFractionDigits: d });

/** Etiqueta de la serie, arriba a la izquierda. */
export const SeriesTag: React.FC = () => (
  <div style={{ position: "absolute", top: 104, left: 70, display: "flex", alignItems: "center", gap: 14 }}>
    <span
      style={{
        background: C.blue,
        color: C.paper,
        fontFamily: F.display,
        fontWeight: 800,
        fontSize: 26,
        letterSpacing: 1.5,
        padding: "6px 16px",
        borderRadius: 8,
        border: `3px solid ${C.ink}`,
      }}
    >
      {STYLE.series.label}
    </span>
    <span style={{ fontFamily: F.body, fontWeight: 700, fontSize: 24, color: C.muted, letterSpacing: 1 }}>{STYLE.series.date}</span>
  </div>
);

/** Tarjeta de datos: papel blanco, borde negro, sombra dura. */
export const Card: React.FC<{
  title: string;
  right?: React.ReactNode;
  source?: string;
  accent?: string;
  top?: number;
  height?: number;
  children: React.ReactNode;
  at?: number;
}> = ({ title, right, source, accent = C.blue, top = 200, height = 490, children, at = 0 }) => {
  const f = useCurrentFrame();
  const p = pop(f, at, 14);
  return (
    <div
      style={{
        position: "absolute",
        left: 64,
        right: 74,
        top,
        height,
        background: C.paper,
        border: `${STYLE.stroke}px solid ${C.ink}`,
        borderRadius: STYLE.radius,
        boxShadow: STYLE.shadow(10),
        overflow: "hidden",
        scale: String(0.9 + 0.1 * p),
        opacity: Math.min(1, p * 1.6),
        translate: `0px ${(1 - p) * 30}px`,
        color: C.ink,
        fontFamily: F.body,
      }}
    >
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 14, background: accent, borderBottom: `${STYLE.stroke}px solid ${C.ink}` }} />
      <div style={{ position: "absolute", top: 40, left: 36, right: 36, display: "flex", alignItems: "center" }}>
        <span style={{ fontFamily: F.display, fontWeight: 800, fontSize: 44, letterSpacing: -0.5 }}>{title}</span>
        <span style={{ flex: 1 }} />
        {right}
      </div>
      {children}
      {source ? (
        <div style={{ position: "absolute", left: 36, bottom: 20, fontFamily: F.body, fontWeight: 600, fontSize: 22, color: C.muted }}>
          Fuente: {source}
        </div>
      ) : null}
    </div>
  );
};

/** Título grande en tinta. */
export const Title: React.FC<{ text: string; top: number; at?: number; size?: number; color?: string }> = ({
  text,
  top,
  at = 0,
  size = 116,
  color = C.ink,
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
        fontFamily: F.display,
        fontWeight: 800,
        fontSize: size,
        letterSpacing: -2,
        lineHeight: 1,
        color,
        scale: String(0.75 + 0.25 * p),
        opacity: Math.min(1, p * 1.5),
      }}
    >
      {text}
    </div>
  );
};

/** Palabra destacada en bloque de color con borde y sombra dura (reemplaza la "pastilla oscura"). */
export const Block: React.FC<{ text: string; top: number; at?: number; size?: number; bg?: string; color?: string; rotate?: number }> = ({
  text,
  top,
  at = 0,
  size = 96,
  bg = C.blue,
  color = C.paper,
  rotate = -2,
}) => {
  const f = useCurrentFrame();
  const p = pop(f, at, 12);
  return (
    <div style={{ position: "absolute", top, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
      <div
        style={{
          background: bg,
          color,
          fontFamily: F.display,
          fontWeight: 800,
          fontSize: size,
          letterSpacing: -1.5,
          lineHeight: 1,
          padding: "14px 34px 18px",
          borderRadius: 16,
          border: `${STYLE.stroke}px solid ${C.ink}`,
          boxShadow: STYLE.shadow(8),
          rotate: `${rotate}deg`,
          scale: String(p),
        }}
      >
        {text}
      </div>
    </div>
  );
};

/** Etiqueta chica (pill) con borde. */
export const Pill: React.FC<{ text: string; bg?: string; color?: string; size?: number }> = ({ text, bg = C.yellow, color = C.ink, size = 28 }) => (
  <span
    style={{
      background: bg,
      color,
      fontFamily: F.display,
      fontWeight: 800,
      fontSize: size,
      padding: "6px 16px",
      borderRadius: 999,
      border: `3px solid ${C.ink}`,
      whiteSpace: "nowrap",
    }}
  >
    {text}
  </span>
);

/** Subrayado a mano que se dibuja solo (reemplaza el círculo rojo). */
export const Scribble: React.FC<{ x: number; y: number; w: number; at?: number; color?: string }> = ({ x, y, w, at = 0, color = C.red }) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + 12);
  const d = `M ${x} ${y} Q ${x + w * 0.25} ${y - 10} ${x + w * 0.5} ${y + 2} T ${x + w} ${y - 4}`;
  const len = w * 1.2;
  return (
    <svg width={1080} height={1920} style={{ position: "absolute", left: 0, top: 0, pointerEvents: "none" }}>
      <path d={d} fill="none" stroke={color} strokeWidth={10} strokeLinecap="round" strokeDasharray={len} strokeDashoffset={len * (1 - p)} />
    </svg>
  );
};

/** Sello que cae sobre la tarjeta. */
export const Stamp: React.FC<{ text: string; at: number; top: number; bg?: string; color?: string; rotate?: number }> = ({
  text,
  at,
  top,
  bg = C.red,
  color = C.paper,
  rotate = -6,
}) => {
  const f = useCurrentFrame();
  const s = interpolate(f, [at, at + 6], [1.7, 1], clamp);
  const o = interpolate(f, [at, at + 3], [0, 1], clamp);
  return (
    <div style={{ position: "absolute", top, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: o }}>
      <div
        style={{
          background: bg,
          color,
          fontFamily: F.display,
          fontWeight: 800,
          fontSize: 56,
          letterSpacing: -0.5,
          padding: "10px 30px",
          borderRadius: 14,
          border: `${STYLE.stroke}px solid ${C.ink}`,
          boxShadow: STYLE.shadow(8),
          rotate: `${rotate}deg`,
          scale: String(s),
        }}
      >
        {text}
      </div>
    </div>
  );
};
