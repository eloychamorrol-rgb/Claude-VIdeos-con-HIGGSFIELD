import React from "react";
import { Audio, Video } from "@remotion/media";
import {
  AbsoluteFill,
  Easing,
  interpolate,
  Sequence,
  staticFile,
  useCurrentFrame,
} from "remotion";
import segmentsJson from "./data/segments.json";
import wordsJson from "./data/words.json";
import { Captions, Word } from "./components/Captions";
import {
  Chip,
  CityCompare,
  CopperParadox,
  DollarMeter,
  EmojiRain,
  FactoryAnalogy,
  Forecast,
  HookCopperVsJobs,
  LunchPrice,
  MillionPeople,
  RateDilemma,
  RateHike,
  Recap,
  Speedometer,
  TaxCut,
  UnemploymentBars,
  WhatRose,
} from "./components/Graphics";
import { C, body, clamp, display, pop } from "./theme";

export const FPS = 30;

type Seg = { from: number; dur: number; text: string };
const SEGS = segmentsJson as Seg[];
const WORDS = wordsJson as Word[];
export const TOTAL = SEGS[SEGS.length - 1].from + SEGS[SEGS.length - 1].dur;

/** Start frame of segment i. */
const S = (i: number) => SEGS[i].from;
/** End frame (exclusive) of segment i. */
const E = (i: number) => SEGS[i].from + SEGS[i].dur;
/** Frame where a word (matching regex) is spoken inside segment i. */
const W = (i: number, re: RegExp) => {
  const a = S(i) / FPS;
  const b = E(i) / FPS;
  const w = WORDS.find((x) => x.s >= a - 0.05 && x.s < b && re.test(x.w));
  return w ? Math.round(w.s * FPS) : S(i);
};

/* ------------------------------------------------------------------ */
/* Split-screen windows: graphic on top, speaker pushed down.          */
/* ------------------------------------------------------------------ */

type Win = { a: number; b: number; el: (dur: number) => React.ReactNode; name: string };

const WINDOWS: Win[] = [
  { name: "Gancho cobre vs empleo", a: 0, b: E(1), el: (d) => <HookCopperVsJobs dur={d} secondAt={S(1) + 4} /> },
  { name: "Barras desempleo", a: S(3), b: E(3), el: (d) => <UnemploymentBars dur={d} /> },
  { name: "Millón de personas", a: S(4), b: E(4), el: (d) => <MillionPeople dur={d} /> },
  { name: "Puente Alto + Maipú", a: S(5), b: E(5), el: (d) => <CityCompare dur={d} /> },
  { name: "Almuerzo", a: S(9), b: E(10), el: (d) => <LunchPrice dur={d} /> },
  { name: "Lo que más subió", a: S(11), b: E(11), el: (d) => <WhatRose dur={d} /> },
  { name: "Velocímetro PIB", a: S(13), b: E(14), el: (d) => <Speedometer dur={d} /> },
  { name: "Paradoja cobre", a: S(16), b: E(17), el: (d) => <CopperParadox dur={d} secondAt={S(17) - S(16)} /> },
  { name: "Fábrica", a: S(18), b: E(19), el: (d) => <FactoryAnalogy dur={d} secondAt={S(19) - S(18)} /> },
  {
    name: "Dilema tasa",
    a: S(21),
    b: E(23),
    el: (d) => <RateDilemma dur={d} beats={[W(21, /precios/i) - S(21), W(22, /créditos/i) - S(21), W(23, /4,5/) - S(21)]} />,
  },
  { name: "Subir tasa", a: S(24), b: E(24) + 10, el: (d) => <RateHike dur={d} /> },
  {
    name: "Dólar",
    a: S(26),
    b: E(29),
    el: (d) => (
      <DollarMeter
        dur={d}
        iconsAt={[W(28, /celular/i) - S(26), W(28, /auto/i) - S(26), W(28, /bencina/i) - S(26)]}
      />
    ),
  },
  { name: "Megarreforma", a: S(31), b: E(32), el: (d) => <TaxCut dur={d} /> },
  { name: "Proyección", a: S(33), b: E(34), el: (d) => <Forecast dur={d} secondAt={W(33, /^2$/) - S(33)} /> },
  {
    name: "Resumen",
    a: S(35),
    b: E(35),
    el: (d) => <Recap dur={d} beats={[W(35, /precios/i) - S(35), W(35, /empleo/i) - S(35), W(35, /economía/i) - S(35)]} />,
  },
];

/* Chips over the talking head (full-screen moments) */
type ChipDef = { a: number; b: number; emoji: string; text: string; color: string };
const CHIPS: ChipDef[] = [
  { a: S(2), b: E(2), emoji: "🤔", text: "¿Cómo se explica?", color: C.yellow },
  { a: S(6), b: E(6), emoji: "📈", text: "Máximo desde 2021", color: C.red },
  { a: S(7), b: E(7), emoji: "🔥", text: "Todo sube", color: C.orange },
  { a: S(8), b: E(8), emoji: "💸", text: "Inflación 4,5%", color: C.orange },
  { a: S(12), b: E(12), emoji: "📊", text: "¿Y la economía?", color: C.blue },
  { a: S(15), b: E(15), emoji: "⚠️", text: "¿El problema?", color: C.yellow },
  { a: S(20), b: E(20), emoji: "🏦", text: "Banco Central", color: C.blue },
  { a: S(25), b: E(25), emoji: "💵", text: "¿Y el dólar?", color: C.green },
  { a: S(30), b: E(30), emoji: "💡", text: "¿Luz al final?", color: C.yellow },
  { a: S(36), b: E(36), emoji: "👛", text: "¿Lo sientes?", color: C.yellow },
];

/** Talking-head punch-in per segment (hides jump cuts). */
const ZOOM: Record<number, number> = {
  2: 1.28, 6: 1.12, 7: 1.22, 8: 1.12, 12: 1.3, 15: 1.3, 20: 1.15, 25: 1.3, 30: 1.2, 36: 1.18, 37: 1.08,
};

const T = 7; // transition frames

const splitAmount = (f: number) => {
  let v = 0;
  for (const w of WINDOWS) {
    const x = interpolate(f, [w.a - T, w.a, w.b - T / 2, w.b + T / 2], [0, 1, 1, 0], clamp);
    // Hard start at frame 0 for the hook
    const y = w.a === 0 ? interpolate(f, [w.b - T / 2, w.b + T / 2], [1, 0], clamp) : x;
    v = Math.max(v, y);
  }
  return Easing.bezier(0.65, 0, 0.35, 1)(v);
};

const segIndexAt = (f: number) => {
  let i = 0;
  while (i < SEGS.length - 1 && f >= E(i)) i++;
  return i;
};

/* ------------------------------------------------------------------ */

const Speaker: React.FC = () => {
  const f = useCurrentFrame();
  const amt = splitAmount(f);
  const i = segIndexAt(f);
  const local = f - S(i);
  const full = (ZOOM[i] ?? (i % 2 ? 1.08 : 1.0)) + local * 0.0006;
  const scale = full + (1.0 - full) * amt;
  return (
    <AbsoluteFill style={{ backgroundColor: C.ink }}>
      <AbsoluteFill
        style={{
          scale: String(scale),
          transformOrigin: "540px 640px",
          translate: `0px ${amt * 560}px`,
        }}
      >
        <Video src={staticFile("cut.mp4")} style={{ width: 1080, height: 1920 }} />
      </AbsoluteFill>
      {/* soft vignette */}
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(ellipse at 50% 40%, rgba(0,0,0,0) 55%, rgba(0,0,0,0.35) 100%)",
        }}
      />
    </AbsoluteFill>
  );
};

const PanelFrame: React.FC = () => {
  const f = useCurrentFrame();
  const amt = splitAmount(f);
  return (
    <AbsoluteFill
      style={{
        height: 1000,
        translate: `0px ${(amt - 1) * 1010}px`,
        borderRadius: "0 0 56px 56px",
        overflow: "hidden",
        boxShadow: "0 20px 60px rgba(0,0,0,0.55)",
        borderBottom: `6px solid ${C.yellow}`,
        backgroundColor: C.ink,
      }}
    >
      {WINDOWS.map((w) => (
        <Sequence key={w.name} name={w.name} from={w.a} durationInFrames={w.b - w.a + T} layout="none">
          {w.el(w.b - w.a + T)}
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const ProgressBar: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 10, background: "rgba(255,255,255,0.15)" }}>
      <div style={{ height: 10, width: `${(f / TOTAL) * 100}%`, background: C.yellow }} />
    </div>
  );
};

const CTA: React.FC<{ dur: number }> = ({ dur }) => {
  const f = useCurrentFrame();
  const s = pop(f, 4, 14);
  const press = interpolate(f, [40, 46, 52], [1, 0.9, 1], clamp);
  const done = f > 46;
  return (
    <AbsoluteFill>
      <EmojiRain emoji={["💬", "📊", "🇨🇱", "💸", "📈"]} count={16} />
      <div style={{ position: "absolute", top: 210, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 24 }}>
        <div
          style={{
            scale: String(s * press),
            background: done ? C.white : C.red,
            color: done ? C.ink : C.white,
            fontFamily: display,
            fontWeight: 900,
            fontSize: 64,
            padding: "22px 60px",
            borderRadius: 999,
            boxShadow: "0 12px 40px rgba(0,0,0,0.45)",
          }}
        >
          {done ? "✓ Siguiendo" : "＋ Seguir"}
        </div>
        <div
          style={{
            opacity: interpolate(f, [10, 20], [0, 1], clamp),
            background: C.panel,
            borderRadius: 24,
            padding: "14px 30px",
            fontFamily: body,
            fontWeight: 700,
            fontSize: 40,
            color: C.white,
          }}
        >
          💬 Cuéntame en los comentarios
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          top: 1640,
          left: 0,
          right: 0,
          textAlign: "center",
          fontFamily: body,
          fontWeight: 600,
          fontSize: 28,
          color: "rgba(255,255,255,0.8)",
          opacity: interpolate(f, [10, 20, dur - 4, dur], [0, 1, 1, 0], clamp),
        }}
      >
        Fuentes: INE · Banco Central de Chile · datos a nov. 2026
      </div>
    </AbsoluteFill>
  );
};

/* ------------------------------------------------------------------ */
/* Sound design (synthesized, low volume so music can go on top)       */
/* ------------------------------------------------------------------ */

const sfx: { at: number; file: string; vol: number }[] = [
  ...WINDOWS.filter((w) => w.a > 0).map((w) => ({ at: w.a - 4, file: "whoosh.wav", vol: 0.35 })),
  ...CHIPS.map((c) => ({ at: c.a, file: "pop.wav", vol: 0.35 })),
  { at: 0, file: "boom.wav", vol: 0.5 },
  { at: S(1) + 4, file: "boom.wav", vol: 0.4 },
  { at: S(4) + 50, file: "ding.wav", vol: 0.22 },
  { at: S(9) + 46, file: "ding.wav", vol: 0.22 },
  { at: S(23) + 6, file: "tick.wav", vol: 0.5 },
  { at: E(36) + 46, file: "pop.wav", vol: 0.5 },
];

export const Reel: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: C.ink }}>
      <Speaker />
      {CHIPS.map((c) => (
        <Sequence key={c.text} name={`Chip ${c.text}`} from={c.a} durationInFrames={c.b - c.a}>
          <Chip dur={c.b - c.a} emoji={c.emoji} text={c.text} color={c.color} />
        </Sequence>
      ))}
      <Sequence name="CTA" from={S(37)} durationInFrames={E(37) - S(37)}>
        <CTA dur={E(37) - S(37)} />
      </Sequence>
      <PanelFrame />
      <Captions words={WORDS} top={1400} />
      <ProgressBar />
      {sfx.map((s, i) => (
        <Sequence key={i} from={Math.max(0, s.at)} durationInFrames={40} layout="none">
          <Audio src={staticFile(`sfx/${s.file}`)} volume={s.vol} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
