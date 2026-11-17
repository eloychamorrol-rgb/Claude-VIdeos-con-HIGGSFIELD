import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { CaptionSample } from "./Captions";
import { SDollar, SFullQuestion, SHook, SQuestion, SUnemployment } from "./scenes";
import { C, STYLE } from "./theme";

/** Fotogramas de muestra del estilo nuevo, para comparar con la versión anterior. */
export type BoardProps = { scene: "hook" | "unemp" | "question" | "full" | "dollar" };

const SPEAKER: Record<BoardProps["scene"], string> = {
  hook: "board/sp_2.0.png",
  unemp: "board/sp_9.0.png",
  question: "board/sp_52.7.png",
  full: "board/sp_9.0.png",
  dollar: "board/sp_57.5.png",
};

const CAPTION: Record<BoardProps["scene"], { w: string[]; k: number; s: number }> = {
  hook: { w: ["ESTÁ", "CARÍSIMO"], k: 1, s: 1 },
  unemp: { w: ["LLEGÓ", "A", "9,8%"], k: 2, s: 2 },
  question: { w: ["¿Y", "EL", "DÓLAR?"], k: 2, s: 2 },
  full: { w: [], k: -1, s: -1 },
  dollar: { w: ["TU", "AUTO,", "LA"], k: -1, s: 1 },
};

export const StyleBoard: React.FC<BoardProps> = ({ scene }) => {
  const full = scene === "full";
  const panelH = full ? 1920 : STYLE.layout.panel;
  const cap = CAPTION[scene];
  return (
    <AbsoluteFill style={{ backgroundColor: "#111" }}>
      <AbsoluteFill style={{ translate: `0px ${STYLE.layout.speakerOffset}px` }}>
        <Img src={staticFile(SPEAKER[scene])} style={{ width: 1080, height: 1920 }} />
      </AbsoluteFill>
      <AbsoluteFill style={{ height: panelH, overflow: "hidden", background: `linear-gradient(180deg, ${C.bgTop} 0px, ${C.bg} 300px, ${C.bg} 100%)` }}>
        {scene === "hook" && <SHook dur={90} secondAt={20} />}
        {scene === "unemp" && <SUnemployment dur={90} />}
        {scene === "question" && <SQuestion dur={90} a="¿Y EL" b="DÓLAR?" bg={C.green} />}
        {scene === "full" && <SFullQuestion dur={90} a="¿CÓMO SE" b="EXPLICA?" />}
        {scene === "dollar" && <SDollar dur={90} icons={[10, 20, 30]} />}
      </AbsoluteFill>
      {!full && cap.w.length ? <CaptionSample words={cap.w} keyIdx={cap.k} spokenUpTo={cap.s} centerY={STYLE.layout.panel} /> : null}
    </AbsoluteFill>
  );
};
