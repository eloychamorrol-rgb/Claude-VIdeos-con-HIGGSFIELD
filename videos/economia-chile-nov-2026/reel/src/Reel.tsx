import React from "react";
import { Audio, Video } from "@remotion/media";
import { AbsoluteFill, Easing, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import segmentsJson from "./data/segments.json";
import wordsJson from "./data/words.json";
import { Captions, Word } from "./v2/Captions";
import { K, PX, clamp } from "./v2/ui";
import {
  SAllUp,
  SAnalogy,
  SBank,
  SCompare,
  SCopper,
  SCta,
  SDilemma,
  SDollar,
  SForecast,
  SGrowth,
  SHike,
  SHook,
  SInflation,
  SLunch,
  SMillion,
  SQuestion,
  SRecap,
  SRecord,
  STerminal,
  SUnemployment,
  SWhatRose,
} from "./v2/scenes";

export const FPS = 30;

type Seg = { from: number; dur: number; text: string };
const SEGS = segmentsJson as Seg[];
const WORDS = wordsJson as Word[];
export const TOTAL = SEGS[SEGS.length - 1].from + SEGS[SEGS.length - 1].dur;

const S = (i: number) => SEGS[i].from;
const E = (i: number) => SEGS[i].from + SEGS[i].dur;
/** Frame at which a word matching `re` is spoken inside segment i. */
const W = (i: number, re: RegExp) => {
  const a = S(i) / FPS;
  const b = E(i) / FPS;
  const w = WORDS.find((x) => x.s >= a - 0.05 && x.s < b && re.test(x.w));
  return w ? Math.round(w.s * FPS) : S(i);
};

const PANEL = 760; // height of the top graphics panel in split mode

type Scene = { name: string; a: number; b: number; full?: boolean; el: (d: number) => React.ReactNode };

const SCENES: Scene[] = [
  { name: "Gancho", a: 0, b: E(1), el: (d) => <SHook dur={d} secondAt={S(1) + 4} /> },
  { name: "¿Cómo se explica?", a: S(2), b: E(2), full: true, el: (d) => <SQuestion dur={d} a="¿CÓMO SE" b="EXPLICA?" full /> },
  { name: "Desempleo", a: S(3), b: E(3), el: (d) => <SUnemployment dur={d} /> },
  { name: "Millón", a: S(4), b: E(4), el: (d) => <SMillion dur={d} /> },
  { name: "Puente Alto + Maipú", a: S(5), b: E(5), el: (d) => <SCompare dur={d} /> },
  { name: "Récord 2021", a: S(6), b: E(6), el: (d) => <SRecord dur={d} /> },
  { name: "Todo sube", a: S(7), b: E(7), el: (d) => <SAllUp dur={d} /> },
  { name: "Inflación", a: S(8), b: E(8), el: (d) => <SInflation dur={d} /> },
  { name: "Almuerzo", a: S(9), b: E(10), el: (d) => <SLunch dur={d} secondAt={S(10) - S(9)} /> },
  { name: "Lo que más subió", a: S(11), b: E(11), el: (d) => <SWhatRose dur={d} /> },
  { name: "¿Y la economía?", a: S(12), b: E(12), el: (d) => <SQuestion dur={d} a="¿Y LA" b="ECONOMÍA?" /> },
  { name: "Crecimiento", a: S(13), b: E(14), el: (d) => <SGrowth dur={d} stampAt={S(14) - S(13) + 3} /> },
  { name: "¿El problema?", a: S(15), b: E(15), el: (d) => <SQuestion dur={d} a="¿EL" b="PROBLEMA?" /> },
  { name: "Cobre", a: S(16), b: E(17), el: (d) => <SCopper dur={d} secondAt={S(17) - S(16)} /> },
  { name: "Analogía fábrica", a: S(18), b: E(19), el: (d) => <SAnalogy dur={d} secondAt={W(19, /fábrica/i) - S(18)} /> },
  { name: "Banco Central", a: S(20), b: E(20), el: (d) => <SBank dur={d} /> },
  {
    name: "Dilema tasa",
    a: S(21),
    b: E(23),
    el: (d) => <SDilemma dur={d} b1={8} b2={S(22) - S(21) + 8} b3={W(23, /mantiene/i) - S(21)} />,
  },
  { name: "Minuta", a: S(24), b: E(24), el: (d) => <SHike dur={d} /> },
  { name: "¿Y el dólar?", a: S(25), b: E(25), el: (d) => <SQuestion dur={d} a="¿Y EL" b="DÓLAR?" /> },
  {
    name: "Dólar",
    a: S(26),
    b: E(29),
    el: (d) => <SDollar dur={d} icons={[W(28, /celular/i) - S(26), W(28, /auto/i) - S(26), W(28, /bencina/i) - S(26)]} />,
  },
  { name: "¿Luz al final?", a: S(30), b: E(30), el: (d) => <SQuestion dur={d} a="¿HAY LUZ" b="AL FINAL?" pixel={PX.bulb} /> },
  { name: "Megarreforma", a: S(31), b: E(32), el: (d) => <STerminal dur={d} secondAt={S(32) - S(31)} /> },
  {
    name: "Proyección",
    a: S(33),
    b: E(34),
    el: (d) => <SForecast dur={d} secondAt={W(33, /^2$/) - S(33)} stampAt={S(34) - S(33) + 4} />,
  },
  {
    name: "Resumen",
    a: S(35),
    b: E(35),
    full: true,
    el: (d) => <SRecap dur={d} beats={[W(35, /precios/i) - S(35), W(35, /empleo/i) - S(35), W(35, /economía/i) - S(35)]} />,
  },
  { name: "¿Lo sientes?", a: S(36), b: E(36), el: (d) => <SQuestion dur={d} a="¿LO SIENTES" b="EN TU BOLSILLO?" pixel={PX.wallet} /> },
  { name: "Cierre", a: S(37), b: E(37), el: (d) => <SCta dur={d} /> },
];

const T = 6;
const fullAmount = (f: number) => {
  let v = 0;
  for (const s of SCENES) {
    if (!s.full) continue;
    v = Math.max(v, interpolate(f, [s.a - T, s.a, s.b - T, s.b], [0, 1, 1, 0], clamp));
  }
  return Easing.bezier(0.65, 0, 0.35, 1)(v);
};

const segAt = (f: number) => {
  let i = 0;
  while (i < SEGS.length - 1 && f >= E(i)) i++;
  return i;
};

const Speaker: React.FC = () => {
  const f = useCurrentFrame();
  const i = segAt(f);
  const local = f - S(i);
  const scale = (i % 2 ? 1.4 : 1.3) + local * 0.0005;
  return (
    <AbsoluteFill style={{ backgroundColor: "#111" }}>
      <AbsoluteFill style={{ scale: String(scale), transformOrigin: "540px 640px", translate: "0px 600px" }}>
        <Video src={staticFile("cut.mp4")} style={{ width: 1080, height: 1920 }} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const Panel: React.FC = () => {
  const f = useCurrentFrame();
  const h = PANEL + (1920 - PANEL) * fullAmount(f);
  return (
    <AbsoluteFill
      style={{
        height: h,
        overflow: "hidden",
        background: `linear-gradient(180deg, ${K.creamTop} 0px, ${K.cream} 300px, ${K.cream} 100%)`,
      }}
    >
      {SCENES.map((s) => {
        const d = s.b - s.a;
        return (
          <Sequence key={s.name} name={s.name} from={s.a} durationInFrames={d}>
            <SceneIn>{s.el(d)}</SceneIn>
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

const SceneIn: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ opacity: interpolate(f, [0, 4], [0, 1], clamp), translate: `0px ${interpolate(f, [0, 6], [24, 0], clamp)}px` }}>
      {children}
    </AbsoluteFill>
  );
};

const CaptionLayer: React.FC = () => {
  const f = useCurrentFrame();
  const full = fullAmount(f);
  return <Captions words={WORDS} centerY={PANEL} visible={1 - full} />;
};

/* Sound design: subtle, so music can sit on top later. */
const SFX: { at: number; file: string; vol: number }[] = [
  ...SCENES.filter((s) => s.a > 0).map((s) => ({ at: s.a - 3, file: "whoosh.wav", vol: 0.18 })),
  { at: 0, file: "boom.wav", vol: 0.45 },
  { at: S(1) + 4, file: "boom.wav", vol: 0.35 },
  { at: S(2) + 14, file: "pop.wav", vol: 0.35 },
  { at: S(6) + 18, file: "pop.wav", vol: 0.3 },
  { at: S(14) + 3, file: "boom.wav", vol: 0.3 },
  { at: S(21) + 8, file: "tick.wav", vol: 0.6 },
  { at: S(22) + 8, file: "tick.wav", vol: 0.6 },
  { at: W(23, /mantiene/i), file: "ding.wav", vol: 0.18 },
  { at: S(34) + 4, file: "boom.wav", vol: 0.3 },
  { at: S(37) + 44, file: "tick.wav", vol: 0.6 },
  ...[0, 4, 8, 12, 16, 20].map((k) => ({ at: S(31) + 2 + k, file: "tick.wav", vol: 0.25 })),
];

export const Reel: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: "#111" }}>
      <Speaker />
      <Panel />
      <CaptionLayer />
      {SFX.map((s, i) => (
        <Sequence key={i} from={Math.max(0, s.at)} durationInFrames={40} layout="none">
          <Audio src={staticFile(`sfx/${s.file}`)} volume={s.vol} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
