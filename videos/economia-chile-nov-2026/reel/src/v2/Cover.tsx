import React from "react";
import { AbsoluteFill } from "remotion";
import { K, PX, Pixel, mono, sans } from "./ui";

/**
 * Reel cover (1080x1920), graphics only, same visual system as the video.
 * All key content sits inside the 4:5 profile-grid crop (y 285–1635).
 * Static by design: no frame-based animation, so it renders fully at frame 0.
 */

const Row: React.FC<{
  icon: React.ReactNode;
  label: string;
  value: string;
  color: string;
  fill: number;
  note: string;
}> = ({ icon, label, value, color, fill, note }) => (
  <div style={{ display: "flex", alignItems: "center", gap: 26, height: 118 }}>
    <div style={{ width: 84, display: "flex", justifyContent: "center" }}>{icon}</div>
    <div style={{ flex: 1 }}>
      <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between" }}>
        <span style={{ fontFamily: sans, fontWeight: 700, fontSize: 38, color: "#E8E8EE" }}>{label}</span>
        <span style={{ fontFamily: mono, fontWeight: 800, fontSize: 54, color }}>{value}</span>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 16, marginTop: 10 }}>
        <div style={{ flex: 1, height: 16, background: "#26262C", borderRadius: 8 }}>
          <div style={{ height: 16, width: `${fill * 100}%`, background: color, borderRadius: 8 }} />
        </div>
        <span style={{ fontFamily: mono, fontWeight: 700, fontSize: 22, color: K.grey, width: 120, textAlign: "right" }}>{note}</span>
      </div>
    </div>
  </div>
);

export const Cover: React.FC = () => {
  const cart = ["k.........", ".kooooooo.", ".kooooooo.", "..ooooooo.", "..kkkkkkk.", "...k...k..", "...k...k.."];
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(180deg, ${K.creamTop} 0px, ${K.cream} 380px, ${K.cream} 1500px, #E2DED6 100%)`,
      }}
    >
      {/* kicker */}
      <div style={{ position: "absolute", top: 318, left: 0, right: 0, textAlign: "center", fontFamily: mono, fontWeight: 800, fontSize: 30, letterSpacing: 4, color: "#7A776F" }}>
        🇨🇱 NOVIEMBRE 2026
      </div>

      {/* title */}
      <div
        style={{
          position: "absolute",
          top: 372,
          left: 30,
          right: 30,
          textAlign: "center",
          fontFamily: mono,
          fontWeight: 800,
          fontSize: 118,
          lineHeight: 1.04,
          letterSpacing: 1,
          color: K.orange,
          textShadow: "0 8px 0 #3A2A22",
        }}
      >
        LA ECONOMÍA
        <br />
        CHILENA
      </div>
      <div style={{ position: "absolute", top: 640, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
        <div
          style={{
            background: "#2B2B2B",
            borderRadius: 14,
            padding: "8px 34px",
            fontFamily: mono,
            fontWeight: 800,
            fontSize: 74,
            letterSpacing: 2,
            color: K.orangeHi,
            rotate: "-2deg",
            boxShadow: "0 12px 26px rgba(0,0,0,0.22)",
          }}
        >
          EN 1 MINUTO
        </div>
      </div>

      {/* dashboard card */}
      <div
        style={{
          position: "absolute",
          top: 810,
          left: 70,
          right: 70,
          height: 690,
          background: K.frame,
          borderRadius: 40,
          padding: 20,
          boxShadow: "0 26px 60px rgba(20,20,40,0.28)",
        }}
      >
        <div style={{ position: "relative", height: "100%", background: K.inner, borderRadius: 26, padding: "28px 38px", boxSizing: "border-box" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14, marginBottom: 22 }}>
            <span style={{ color: K.orange, fontSize: 40, fontWeight: 700, lineHeight: 1, fontFamily: sans }}>✳</span>
            <span style={{ fontFamily: sans, fontWeight: 700, fontSize: 38, color: K.white }}>Chile hoy</span>
            <span style={{ fontFamily: mono, fontWeight: 700, fontSize: 24, color: K.grey }}>/resumen</span>
            <span style={{ flex: 1 }} />
            <span style={{ background: K.orange, color: "#FFF", fontFamily: mono, fontWeight: 800, fontSize: 22, padding: "6px 14px", borderRadius: 999 }}>4 DATOS</span>
          </div>
          <Row icon={<Pixel grid={PX.person} size={11} palette={{ k: K.red }} />} label="Desempleo" value="9,8%" color={K.red} fill={0.82} note="+1 MILLÓN" />
          <Row icon={<Pixel grid={cart} size={8} palette={{ k: "#CFCFD6" }} />} label="Inflación" value="4,5%" color={K.orange} fill={0.6} note="META 3%" />
          <Row icon={<Pixel grid={PX.coin} size={9} />} label="Crecimiento" value="0,2%" color={K.yellow} fill={0.06} note="SEPT." />
          <Row icon={<Pixel grid={PX.phone} size={8} />} label="Dólar" value="$984" color={K.green} fill={0.92} note="≈ $1.000" />
          <div
            style={{
              position: "absolute",
              right: 22,
              bottom: 18,
              background: "#ECECEC",
              color: K.ink,
              fontFamily: mono,
              fontWeight: 800,
              fontSize: 22,
              padding: "6px 16px",
              borderRadius: 999,
            }}
          >
            FUENTE: INE · BCCH
          </div>
        </div>
      </div>

      {/* hand-drawn red circle around the unemployment value */}
      <svg width={1080} height={1920} style={{ position: "absolute", left: 0, top: 0 }}>
        <ellipse cx={862} cy={960} rx={122} ry={48} fill="none" stroke={K.red} strokeWidth={8} transform="rotate(-6 862 960)" strokeLinecap="round" />
      </svg>

      {/* pixel icons strip */}
      <div style={{ position: "absolute", top: 1545, left: 0, right: 0, display: "flex", justifyContent: "center", alignItems: "flex-end", gap: 58 }}>
        <Pixel grid={PX.factory} size={6} />
        <Pixel grid={PX.coin} size={8} />
        <Pixel grid={PX.car} size={6} />
        <Pixel grid={PX.pump} size={7} />
        <Pixel grid={PX.lock} size={8} />
      </div>
    </AbsoluteFill>
  );
};
