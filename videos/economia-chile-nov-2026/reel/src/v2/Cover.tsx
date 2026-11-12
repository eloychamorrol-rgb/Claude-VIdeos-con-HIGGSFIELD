import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { K, mono, sans } from "./ui";

/** Reel cover (1080x1920). Key content stays inside the 4:5 / 3:4 grid crops (y 285–1635). */
const Stat: React.FC<{ label: string; value: string; color: string }> = ({ label, value, color }) => (
  <div
    style={{
      flex: 1,
      background: K.frame,
      borderRadius: 26,
      padding: 10,
      boxShadow: "0 14px 30px rgba(20,20,40,0.25)",
    }}
  >
    <div style={{ background: K.inner, borderRadius: 18, padding: "16px 10px", textAlign: "center" }}>
      <div style={{ fontFamily: mono, fontWeight: 800, fontSize: 58, color }}>{value}</div>
      <div style={{ fontFamily: sans, fontWeight: 700, fontSize: 24, color: "#CFCFD6", marginTop: 4, letterSpacing: 1 }}>{label}</div>
    </div>
  </div>
);

export const Cover: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: "#111" }}>
      {/* speaker, native size, face around y≈1300 */}
      <AbsoluteFill style={{ translate: "0px 640px" }}>
        <Img src={staticFile("portada_frame.png")} style={{ width: 1080, height: 1920 }} />
      </AbsoluteFill>
      {/* cream panel */}
      <AbsoluteFill
        style={{
          height: 960,
          background: `linear-gradient(180deg, ${K.creamTop} 0px, ${K.cream} 320px, ${K.cream} 100%)`,
        }}
      >
        <div style={{ position: "absolute", top: 300, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
          <div style={{ fontFamily: mono, fontWeight: 800, fontSize: 30, color: "#6A6862", letterSpacing: 3 }}>
            🇨🇱 NOVIEMBRE 2026
          </div>
        </div>
        <div
          style={{
            position: "absolute",
            top: 360,
            left: 30,
            right: 30,
            textAlign: "center",
            fontFamily: mono,
            fontWeight: 800,
            fontSize: 112,
            lineHeight: 1.05,
            color: K.orange,
            textShadow: "0 8px 0 #3A2A22",
            letterSpacing: 1,
          }}
        >
          LA ECONOMÍA
          <br />
          CHILENA
        </div>
        <div style={{ position: "absolute", top: 625, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
          <div
            style={{
              background: "#2B2B2B",
              borderRadius: 14,
              padding: "8px 34px",
              fontFamily: mono,
              fontWeight: 800,
              fontSize: 78,
              color: K.orangeHi,
              letterSpacing: 2,
              boxShadow: "0 10px 24px rgba(0,0,0,0.25)",
              rotate: "-2deg",
            }}
          >
            EN 1 MINUTO
          </div>
        </div>
        <div style={{ position: "absolute", top: 775, left: 70, right: 70, display: "flex", gap: 22 }}>
          <Stat label="DESEMPLEO" value="9,8%" color={K.red} />
          <Stat label="INFLACIÓN" value="4,5%" color={K.orange} />
          <Stat label="DÓLAR" value="$984" color={K.green} />
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
