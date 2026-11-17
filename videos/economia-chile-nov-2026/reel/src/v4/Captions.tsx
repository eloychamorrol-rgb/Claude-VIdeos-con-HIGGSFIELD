import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { C, F, STYLE } from "./theme";
import { clamp } from "./ui";

export type Word = { w: string; s: number; e: number };

const KEY =
  /[0-9]|mill[oó]n|cobre|desempleo|inflaci[oó]n|d[oó]lar|tasa|bencina|comida|nada|caro|carísimo|megarreforma|central|pega|cesantes|sube|almuerzo|problema|fábrica|precio|precios|dilema|créditos|impuestos|empresas|resumen|pausa|bolsillo|economía|sígueme|túnel|trabajo|perder|subirla/i;

const paginate = (words: Word[]) => {
  const pages: Word[][] = [];
  let cur: Word[] = [];
  let chars = 0;
  words.forEach((w, i) => {
    const prev = words[i - 1];
    const gap = prev ? w.s - prev.e : 0;
    const brk = prev && /[.?!,:…]$/.test(prev.w);
    if (cur.length && (cur.length >= STYLE.caption.maxWords || chars + w.w.length > STYLE.caption.maxChars || gap > 0.35 || brk)) {
      pages.push(cur);
      cur = [];
      chars = 0;
    }
    cur.push(w);
    chars += w.w.length + 1;
  });
  if (cur.length) pages.push(cur);
  return pages;
};

/** Subtítulo en etiqueta blanca con borde y sombra dura; la palabra clave va con resaltador amarillo. */
export const Captions: React.FC<{ words: Word[]; centerY: number; visible: number }> = ({ words, centerY, visible }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = f / fps;
  const pages = React.useMemo(() => paginate(words), [words]);
  const page = pages.find((p, i) => {
    const next = pages[i + 1];
    const end = next ? Math.min(next[0].s, p[p.length - 1].e + 0.5) : p[p.length - 1].e + 0.5;
    return t >= p[0].s - 0.04 && t < end;
  });
  if (!page || visible <= 0.01) return null;
  const keyIdx = page.findIndex((w) => KEY.test(w.w));
  const start = Math.round(page[0].s * fps);
  const enter = interpolate(f, [start - 1, start + 3], [0.92, 1], clamp);
  return (
    <div style={{ position: "absolute", top: centerY - 48, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: visible }}>
      <div
        style={{
          background: C.paper,
          border: `${STYLE.stroke}px solid ${C.ink}`,
          borderRadius: 14,
          boxShadow: STYLE.shadow(7),
          padding: "8px 22px 10px",
          display: "flex",
          gap: 18,
          scale: String(enter),
        }}
      >
        {page.map((w, i) => {
          const spoken = t >= w.s - 0.03;
          const isKey = i === keyIdx && spoken;
          return (
            <span
              key={i}
              style={{
                fontFamily: F.display,
                fontWeight: 800,
                fontSize: STYLE.caption.size,
                lineHeight: 1.12,
                letterSpacing: -0.5,
                color: spoken ? C.ink : STYLE.caption.unspoken,
                textTransform: "uppercase",
                whiteSpace: "nowrap",
                background: isKey ? C.yellow : "transparent",
                borderRadius: 8,
                padding: isKey ? "0 10px" : "0",
                margin: isKey ? "0 -6px" : "0",
              }}
            >
              {w.w.replace(/[,.:…]$/, "")}
            </span>
          );
        })}
      </div>
    </div>
  );
};

/** Caption estático para la tabla de estilos. */
export const CaptionSample: React.FC<{ words: string[]; keyIdx: number; spokenUpTo: number; centerY: number }> = ({ words, keyIdx, spokenUpTo, centerY }) => (
  <div style={{ position: "absolute", top: centerY - 48, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
    <div style={{ background: C.paper, border: `${STYLE.stroke}px solid ${C.ink}`, borderRadius: 14, boxShadow: STYLE.shadow(7), padding: "8px 22px 10px", display: "flex", gap: 18 }}>
      {words.map((w, i) => (
        <span
          key={i}
          style={{
            fontFamily: F.display,
            fontWeight: 800,
            fontSize: STYLE.caption.size,
            lineHeight: 1.12,
            letterSpacing: -0.5,
            color: i <= spokenUpTo ? C.ink : STYLE.caption.unspoken,
            textTransform: "uppercase",
            background: i === keyIdx ? C.yellow : "transparent",
            borderRadius: 8,
            padding: i === keyIdx ? "0 10px" : "0",
            margin: i === keyIdx ? "0 -6px" : "0",
          }}
        >
          {w}
        </span>
      ))}
    </div>
  </div>
);
