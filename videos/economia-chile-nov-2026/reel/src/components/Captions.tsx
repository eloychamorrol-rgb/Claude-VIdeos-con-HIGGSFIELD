import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import { C, clamp, display } from "../theme";

export type Word = { w: string; s: number; e: number }; // seconds, on the edited timeline

const HIGHLIGHT = /[0-9%$]|mill[oó]n|cobre|desempleo|inflaci[oó]n|d[oó]lar|tasa|bencina|comida|nada|caro|megarreforma|banco|central/i;

/** Group words into short pages (max 3 words or a pause > 0.35s). */
const paginate = (words: Word[]) => {
  const pages: Word[][] = [];
  let cur: Word[] = [];
  words.forEach((w, i) => {
    const prev = words[i - 1];
    const gap = prev ? w.s - prev.e : 0;
    const endsSentence = prev && /[.?!,]$/.test(prev.w);
    if (cur.length && (cur.length >= 3 || gap > 0.35 || endsSentence)) {
      pages.push(cur);
      cur = [];
    }
    cur.push(w);
  });
  if (cur.length) pages.push(cur);
  return pages;
};

export const Captions: React.FC<{ words: Word[]; top: number }> = ({ words, top }) => {
  const f = useCurrentFrame();
  const { fps } = useVideoConfig();
  const t = f / fps;
  const pages = React.useMemo(() => paginate(words), [words]);
  const page = pages.find((p, i) => {
    const next = pages[i + 1];
    const end = next ? Math.min(next[0].s, p[p.length - 1].e + 0.6) : p[p.length - 1].e + 0.6;
    return t >= p[0].s - 0.05 && t < end;
  });
  if (!page) return null;
  const pageStart = Math.round(page[0].s * fps);
  const enter = interpolate(f, [pageStart - 2, pageStart + 4], [0.85, 1], clamp);
  return (
    <div
      style={{
        position: "absolute",
        top,
        left: 70,
        right: 70,
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        gap: "0 30px",
        scale: String(enter),
      }}
    >
      {page.map((w, i) => {
        const active = t >= w.s - 0.03;
        const hot = HIGHLIGHT.test(w.w);
        const ws = Math.round(w.s * fps);
        const bump = interpolate(f, [ws - 1, ws + 3, ws + 7], [1, 1.12, 1], clamp);
        const clean = w.w.replace(/[,.]$/, "");
        return (
          <span
            key={i}
            style={{
              fontFamily: display,
              fontWeight: 900,
              fontSize: 82,
              lineHeight: 1.12,
              textTransform: "uppercase",
              color: active ? (hot ? C.yellow : C.white) : "rgba(255,255,255,0.55)",
              scale: active ? String(bump) : "1",
              WebkitTextStroke: "12px #000",
              paintOrder: "stroke fill",
              textShadow: "0 6px 18px rgba(0,0,0,0.55)",
              display: "inline-block",
            }}
          >
            {clean}
          </span>
        );
      })}
    </div>
  );
};
