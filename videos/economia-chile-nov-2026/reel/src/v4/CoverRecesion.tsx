import React from "react";
import { AbsoluteFill } from "remotion";
import { Avatar, LOOKS } from "./Avatar";
import { Icon } from "./icons";
import { C, F, STYLE } from "./theme";
import { SeriesCtx, SeriesTag } from "./ui";

/** Portada del video "Recesión y estanflación" (estática; se renderiza un cuadro ya asentado). */
const sw = STYLE.stroke;

const Sticker: React.FC<{ children: React.ReactNode; bg: string; color?: string; rotate?: number; size?: number; style?: React.CSSProperties }> = ({
  children,
  bg,
  color = C.ink,
  rotate = 0,
  size = 40,
  style,
}) => (
  <div
    style={{
      display: "inline-flex",
      alignItems: "center",
      gap: 12,
      background: bg,
      color,
      fontFamily: F.display,
      fontWeight: 800,
      fontSize: size,
      letterSpacing: -0.5,
      lineHeight: 1,
      padding: "12px 22px 14px",
      borderRadius: 16,
      border: `${sw}px solid ${C.ink}`,
      boxShadow: STYLE.shadow(8),
      rotate: `${rotate}deg`,
      whiteSpace: "nowrap",
      ...style,
    }}
  >
    {children}
  </div>
);

export const CoverRecesion: React.FC = () => {
  return (
    <SeriesCtx.Provider value={{ label: "ECONOMÍA SIMPLE", date: "RECESIÓN Y ESTANFLACIÓN" }}>
      <AbsoluteFill style={{ background: `linear-gradient(180deg, ${C.bgTop} 0px, ${C.bg} 360px, ${C.bg} 1500px, #E6E1D7 100%)`, overflow: "hidden" }}>
        {/* fondo: líneas de gráfico suaves */}
        <svg width={1080} height={1920} style={{ position: "absolute", left: 0, top: 0, opacity: 0.12 }}>
          {[0, 1, 2, 3, 4, 5, 6, 7].map((i) => (
            <line key={i} x1={0} y1={420 + i * 160} x2={1080} y2={420 + i * 160} stroke={C.ink} strokeWidth={2} strokeDasharray="10 14" />
          ))}
        </svg>
        <SeriesTag />

        {/* título */}
        <div style={{ position: "absolute", top: 300, left: 0, right: 0, textAlign: "center", fontFamily: F.display, fontWeight: 800, fontSize: 64, letterSpacing: -1, color: C.ink }}>
          ¿Qué es peor?
        </div>
        <div style={{ position: "absolute", top: 395, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
          <Sticker bg={C.red} color={C.paper} size={128} rotate={-3}>
            RECESIÓN
          </Sticker>
        </div>
        <div
          style={{
            position: "absolute",
            top: 548,
            left: 470,
            width: 140,
            height: 140,
            borderRadius: 70,
            background: C.yellow,
            border: `${sw + 1}px solid ${C.ink}`,
            boxShadow: STYLE.shadow(6),
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontFamily: F.display,
            fontWeight: 800,
            fontSize: 62,
            color: C.ink,
            rotate: "8deg",
            zIndex: 2,
          }}
        >
          vs
        </div>
        <div style={{ position: "absolute", top: 640, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
          <Sticker bg={C.blue} color={C.paper} size={112} rotate={2}>
            ESTANFLACIÓN
          </Sticker>
        </div>

        {/* ilustración central: olla con los ingredientes */}
        {new Array(5).fill(0).map((_, i) => (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 410 + i * 50,
              top: 905 - (i % 2) * 50,
              width: 54 - i * 4,
              height: 54 - i * 4,
              borderRadius: 999,
              background: "#C9D4FF",
              border: `3px solid ${C.ink}`,
            }}
          />
        ))}
        <svg width={1080} height={520} style={{ position: "absolute", left: 0, top: 1010 }}>
          <rect x={300} y={40} width={480} height={50} rx={18} fill={C.muted} stroke={C.ink} strokeWidth={sw} />
          <path d="M325 90 L755 90 L730 330 Q722 370 672 370 L408 370 Q358 370 350 330 Z" fill="#2B2F3A" stroke={C.ink} strokeWidth={sw} strokeLinejoin="round" />
          <rect x={250} y={115} width={80} height={26} rx={10} fill="#2B2F3A" stroke={C.ink} strokeWidth={sw} />
          <rect x={750} y={115} width={80} height={26} rx={10} fill="#2B2F3A" stroke={C.ink} strokeWidth={sw} />
          <ellipse cx={540} cy={66} rx={218} ry={18} fill={C.blue} stroke={C.ink} strokeWidth={4} />
        </svg>
        <div style={{ position: "absolute", top: 1180, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
          <Sticker bg={C.yellow} size={34} rotate={-2}>
            la receta: 3 ingredientes
          </Sticker>
        </div>
        {/* ingredientes saliendo de la olla */}
        <div style={{ position: "absolute", top: 985, left: 255, rotate: "-12deg" }}>
          <Sticker bg={C.paper} size={30}>
            <Icon name="pause" size={34} color={C.yellow} /> crecimiento ≈0
          </Sticker>
        </div>
        <div style={{ position: "absolute", top: 945, left: 610, rotate: "10deg" }}>
          <Sticker bg={C.red} color={C.paper} size={30}>
            <Icon name="up" size={34} color={C.paper} /> precios
          </Sticker>
        </div>

        {/* izquierda: auto en pana */}
        <div style={{ position: "absolute", left: 30, top: 880 }}>
          {[0, 1, 2].map((i) => (
            <div key={i} style={{ position: "absolute", left: 200 + i * 34, top: 10 - i * 22, width: 44 - i * 8, height: 44 - i * 8, borderRadius: 999, background: "#9A9DA6", border: `3px solid ${C.ink}` }} />
          ))}
          <Icon name="car" size={240} color={C.red} />
        </div>
        <div style={{ position: "absolute", left: 50, top: 1090 }}>
          <Sticker bg={C.paper} size={28} rotate={-6}>
            en pana
          </Sticker>
        </div>

        {/* derecha: bencina sube */}
        <div style={{ position: "absolute", right: 40, top: 850, display: "flex", alignItems: "flex-start" }}>
          <Icon name="pump" size={200} color={C.yellow} />
          <div style={{ marginLeft: -20, marginTop: -20 }}>
            <Icon name="up" size={90} color={C.red} />
          </div>
        </div>
        <div style={{ position: "absolute", right: 40, top: 1060 }}>
          <Sticker bg={C.red} color={C.paper} size={28} rotate={5}>
            bencina ▲
          </Sticker>
        </div>

        {/* abajo: el ministro + Chile */}
        <div style={{ position: "absolute", left: 60, top: 1290, display: "flex", alignItems: "center", gap: 22 }}>
          <Avatar look={LOOKS.quiroz} size={210} bg={C.yellow} />
          <div
            style={{
              position: "relative",
              background: C.paper,
              border: `${sw}px solid ${C.ink}`,
              borderRadius: 24,
              boxShadow: STYLE.shadow(8),
              padding: "18px 24px",
              fontFamily: F.display,
              fontWeight: 800,
              fontSize: 44,
              lineHeight: 1.08,
              letterSpacing: -0.5,
              width: 620,
            }}
          >
            “técnicamente
            <br />
            una recesión”
            <div style={{ fontFamily: F.body, fontWeight: 600, fontSize: 22, color: C.muted, marginTop: 8 }}>Ministro de Hacienda, nov 2026</div>
            <div style={{ position: "absolute", left: -26, top: 50, width: 0, height: 0, borderTop: "16px solid transparent", borderBottom: "16px solid transparent", borderRight: `26px solid ${C.ink}` }} />
          </div>
        </div>
        <div style={{ position: "absolute", top: 1545, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
          <Sticker bg={C.blue} color={C.paper} size={42} rotate={-1}>
            🇨🇱 ¿Y Chile? Te lo explico simple
          </Sticker>
        </div>
      </AbsoluteFill>
    </SeriesCtx.Provider>
  );
};
