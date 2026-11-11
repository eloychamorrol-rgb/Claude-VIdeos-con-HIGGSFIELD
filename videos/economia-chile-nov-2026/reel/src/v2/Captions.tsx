import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { K, clamp, mono } from "./ui";

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
    if (cur.length && (cur.length >= 3 || chars + w.w.length > 16 || gap > 0.35 || brk)) {
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
  // highlight only the first "key" word of the page (one orange word, like the reference)
  const keyIdx = page.findIndex((w) => KEY.test(w.w));
  const start = Math.round(page[0].s * fps);
  const enter = interpolate(f, [start - 1, start + 3], [0.92, 1], clamp);
  return (
    <div style={{ position: "absolute", top: centerY - 46, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: visible }}>
      <div
        style={{
          background: "rgba(38,38,38,0.95)",
          borderRadius: 10,
          padding: "8px 26px 10px",
          display: "flex",
          gap: 24,
          scale: String(enter),
          boxShadow: "0 10px 26px rgba(0,0,0,0.3)",
        }}
      >
        {page.map((w, i) => {
          const spoken = t >= w.s - 0.03;
          const color = !spoken ? "#9A9A9A" : i === keyIdx ? K.orangeHi : "#FFFFFF";
          return (
            <span
              key={i}
              style={{
                fontFamily: mono,
                fontWeight: 800,
                fontSize: 66,
                lineHeight: 1.15,
                letterSpacing: 1,
                color,
                textTransform: "uppercase",
                whiteSpace: "nowrap",
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
