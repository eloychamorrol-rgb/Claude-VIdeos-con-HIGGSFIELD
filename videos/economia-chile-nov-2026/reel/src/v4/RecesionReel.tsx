import React from "react";
import { Audio, Video } from "@remotion/media";
import { AbsoluteFill, Easing, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import plan from "../data/recesion_plan.json";
import wordsJson from "../data/recesion_words.json";
import { Captions, Word } from "./Captions";
import {
  SBarsRecession,
  SCarPump,
  SConsequences,
  SCta,
  SDilemma,
  SEquation,
  SHistory,
  SHookRecession,
  SIngredients,
  SNoAdvance,
  SPib,
  SQuote,
  SRisk,
  SStore,
  SVerdict,
  SWorse,
} from "./recesion";
import { SQuestion } from "./scenes";
import { C, STYLE } from "./theme";
import { clamp, useF } from "./ui";

export const REC_FPS = 60;

type Piece = { src_from: number; src_to: number; from: number; dur: number; group: number };
type Group = { from: number; dur: number; text: string };
const PIECES = (plan as { pieces: Piece[]; groups: Group[] }).pieces;
const GROUPS = (plan as { pieces: Piece[]; groups: Group[] }).groups;
const WORDS = wordsJson as Word[];
export const REC_TOTAL = PIECES[PIECES.length - 1].from + PIECES[PIECES.length - 1].dur;

/** Inicio / fin (cuadros a 60 fps) de la frase g. */
const S = (g: number) => GROUPS[g].from;
const E = (g: number) => GROUPS[g].from + GROUPS[g].dur;
/** Cuadro en que se dice una palabra dentro de la frase g. */
const W = (g: number, re: RegExp) => {
  const a = S(g) / REC_FPS;
  const b = E(g) / REC_FPS;
  const w = WORDS.find((x) => x.s >= a - 0.05 && x.s < b && re.test(x.w));
  return w ? Math.round(w.s * REC_FPS) : S(g);
};
/** Convierte un instante absoluto (60 fps) en un "beat" relativo a la escena, en unidades de 30 fps. */
const B = (abs: number, sceneStart: number) => (abs - sceneStart) / 2;

const PANEL = STYLE.layout.panel;
const SPEAKER_OFFSET = 230; // en este video estás más abajo en el encuadre

type Scene = { name: string; a: number; b: number; full?: boolean; el: (d: number) => React.ReactNode };

const SCENES: Scene[] = [
  { name: "Gancho: recesión técnica", a: 0, b: E(0), el: (d) => <SHookRecession dur={d} /> },
  { name: "Algo peor: estanflación", a: S(1), b: E(3), full: true, el: (d) => <SWorse dur={d} revealAt={B(S(2), S(1)) + 4} /> },
  { name: "¿Qué es una recesión?", a: S(4), b: E(4), el: (d) => <SQuestion dur={d} a="¿QUÉ ES UNA" b="RECESIÓN?" bg={C.red} /> },
  { name: "El almacén", a: S(5), b: E(6), el: (d) => <SStore dur={d} goodsAt={B(S(6), S(5))} /> },
  { name: "Dos trimestres", a: S(7), b: E(8), el: (d) => <SBarsRecession dur={d} stampAt={B(W(8, /recesi/i), S(7))} /> },
  {
    name: "Consecuencias",
    a: S(9),
    b: E(10),
    el: (d) => <SConsequences dur={d} beats={[2, B(W(9, /invierte/i), S(9)), B(W(10, /contrata/i), S(9))]} />,
  },
  { name: "¿Y Chile?", a: S(11), b: E(11), el: (d) => <SQuestion dur={d} a="¿Y" b="CHILE?" bg={C.blue} /> },
  {
    name: "PIB Chile",
    a: S(12),
    b: E(16),
    el: (d) => <SPib dur={d} t2At={B(S(13), S(12))} decAt={B(W(14, /decimales/i), S(12))} twoAt={B(S(16), S(12))} />,
  },
  {
    name: "Cita ministro",
    a: S(17),
    b: E(19),
    el: (d) => (
      <SQuote
        dur={d}
        quote="Se le puede llamar técnicamente una recesión"
        who="Jorge Quiroz"
        role="Ministro de Hacienda"
        source="entrevista con Bloomberg, 11 nov 2026"
        accent={C.red}
        chips={[
          { at: B(W(19, /cobre/i), S(17)), text: "por la caída del cobre", bg: C.yellow },
          { at: B(W(19, /corta/i), S(17)), text: "“será corta”", bg: C.paper },
        ]}
      />
    ),
  },
  { name: "Ahora, la estanflación", a: S(20), b: E(20), el: (d) => <SQuestion dur={d} a="AHORA, LA" b="ESTANFLACIÓN" bg={C.blue} /> },
  {
    name: "Ecuación",
    a: S(21),
    b: E(21),
    el: (d) => <SEquation dur={d} b1={B(W(21, /estancamiento/i), S(21))} b2={B(W(21, /inflaci/i), S(21))} b3={B(W(21, /inflaci/i), S(21)) + 16} />,
  },
  { name: "No avanza / suben", a: S(22), b: E(22), el: (d) => <SNoAdvance dur={d} b2={B(W(22, /precios/i), S(22))} /> },
  { name: "Auto en pana", a: S(23), b: E(23), el: (d) => <SCarPump dur={d} b2={B(W(23, /bencina/i), S(23))} /> },
  { name: "Años 70", a: S(24), b: E(26), el: (d) => <SHistory dur={d} b2={B(W(25, /cuadrupl/i), S(24))} b3={B(S(26), S(24))} /> },
  { name: "Volvamos a Chile", a: S(27), b: E(27), el: (d) => <SQuestion dur={d} a="VOLVAMOS A" b="CHILE" bg={C.blue} /> },
  {
    name: "3 ingredientes",
    a: S(28),
    b: E(32),
    el: (d) => <SIngredients dur={d} beats={[2, B(S(29), S(28)), B(S(31), S(28))]} allAt={B(S(32), S(28)) + 8} />,
  },
  { name: "¿Por qué asusta?", a: S(33), b: E(33), el: (d) => <SQuestion dur={d} a="¿POR QUÉ" b="TANTO MIEDO?" bg={C.red} /> },
  { name: "Dilema", a: S(34), b: E(37), el: (d) => <SDilemma dur={d} b1={B(S(35), S(34))} b2={0} b3={B(S(37), S(34))} /> },
  { name: "¿Estamos?", a: S(38), b: E(38), el: (d) => <SQuestion dur={d} a="¿ESTAMOS EN" b="ESTANFLACIÓN?" bg={C.yellow} color={C.ink} /> },
  { name: "Veredicto", a: S(39), b: E(40), el: (d) => <SVerdict dur={d} b2={B(S(40), S(39))} /> },
  { name: "Riesgo", a: S(41), b: E(42), el: (d) => <SRisk dur={d} iconsAt={B(W(42, /petr/i), S(41))} /> },
  { name: "Cierre", a: S(43), b: E(43), el: (d) => <SCta dur={d} /> },
];

const T = 10; // cuadros de transición (60 fps)
const fullAmount = (f: number) => {
  let v = 0;
  for (const s of SCENES) {
    if (!s.full) continue;
    v = Math.max(v, interpolate(f, [s.a - T, s.a, s.b - T, s.b], [0, 1, 1, 0], clamp));
  }
  return Easing.bezier(0.65, 0, 0.35, 1)(v);
};

const pieceAt = (f: number) => {
  let i = 0;
  while (i < PIECES.length - 1 && f >= PIECES[i].from + PIECES[i].dur) i++;
  return i;
};

const Speaker: React.FC = () => {
  const f = useCurrentFrame();
  const i = pieceAt(f);
  const scale = i % 2 ? 1.05 : 1.0; // leve acercamiento en tomas alternadas para ocultar los cortes
  return (
    <AbsoluteFill style={{ backgroundColor: "#111" }}>
      <AbsoluteFill style={{ scale: String(scale), transformOrigin: "540px 1090px", translate: `0px ${SPEAKER_OFFSET}px` }}>
        <Video src={staticFile("recesion/cut.mp4")} style={{ width: 1080, height: 1920 }} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

const SceneIn: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const f = useF();
  return (
    <AbsoluteFill style={{ opacity: interpolate(f, [0, 4], [0, 1], clamp), translate: `0px ${interpolate(f, [0, 6], [24, 0], clamp)}px` }}>
      {children}
    </AbsoluteFill>
  );
};

const Panel: React.FC = () => {
  const f = useCurrentFrame();
  const h = PANEL + (1920 - PANEL) * fullAmount(f);
  return (
    <AbsoluteFill style={{ height: h, overflow: "hidden", background: `linear-gradient(180deg, ${C.bgTop} 0px, ${C.bg} 300px, ${C.bg} 100%)` }}>
      {SCENES.map((s) => (
        <Sequence key={s.name} name={s.name} from={s.a} durationInFrames={Math.max(1, s.b - s.a)}>
          <SceneIn>{s.el(s.b - s.a)}</SceneIn>
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};

const CaptionLayer: React.FC = () => {
  const f = useCurrentFrame();
  return <Captions words={WORDS} centerY={PANEL} visible={1 - fullAmount(f)} />;
};

const SFX: { at: number; file: string; vol: number }[] = [
  ...SCENES.filter((s) => s.a > 0).map((s) => ({ at: s.a - 6, file: "whoosh.wav", vol: 0.16 })),
  { at: 0, file: "boom.wav", vol: 0.4 },
  { at: S(2) + 8, file: "boom.wav", vol: 0.4 },
  { at: W(8, /recesi/i), file: "pop.wav", vol: 0.3 },
  { at: S(16), file: "pop.wav", vol: 0.3 },
  { at: S(32) + 16, file: "ding.wav", vol: 0.16 },
  { at: S(35) + 24, file: "tick.wav", vol: 0.5 },
  { at: S(37) + 24, file: "tick.wav", vol: 0.5 },
  { at: S(43) + 104, file: "tick.wav", vol: 0.6 },
];

export const RecesionReel: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: "#111" }}>
    <Speaker />
    <Panel />
    <CaptionLayer />
    {SFX.map((s, i) => (
      <Sequence key={i} from={Math.max(0, s.at)} durationInFrames={80} layout="none">
        <Audio src={staticFile(`sfx/${s.file}`)} volume={s.vol} />
      </Sequence>
    ))}
  </AbsoluteFill>
);
