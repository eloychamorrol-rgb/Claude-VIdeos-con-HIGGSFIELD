import React from "react";
import { AbsoluteFill, interpolate, random } from "remotion";
import { Avatar, LOOKS } from "./Avatar";
import { Icon } from "./icons";
import { C, F, STYLE } from "./theme";
import { Card, Pill, SeriesTag, Title, clamp, count, fmt, pop, prog, useF } from "./ui";

/* Escenas avanzadas del video "Recesión y estanflación".
   Beats en unidades de 30 fps, relativos al inicio de la escena. */

type P = { dur: number };
const sw = STYLE.stroke;

const Bubble: React.FC<{ text: string; at?: number; typing?: boolean; width?: number; size?: number; tail?: "left" | "right"; style?: React.CSSProperties }> = ({
  text,
  at = 0,
  typing = true,
  width = 560,
  size = 44,
  tail = "left",
  style,
}) => {
  const f = useF();
  const n = typing ? Math.floor(interpolate(f, [at, at + text.length * 0.9], [0, text.length], clamp)) : text.length;
  return (
    <div
      style={{
        position: "relative",
        width,
        background: C.paper,
        border: `${sw}px solid ${C.ink}`,
        borderRadius: 26,
        boxShadow: STYLE.shadow(8),
        padding: "22px 28px",
        fontFamily: F.display,
        fontWeight: 800,
        fontSize: size,
        lineHeight: 1.12,
        letterSpacing: -0.5,
        color: C.ink,
        opacity: f >= at ? 1 : 0,
        scale: String(0.85 + 0.15 * pop(f, at, 10)),
        ...style,
      }}
    >
      <span>{text.slice(0, n)}</span>
      <span style={{ opacity: 0 }}>{text.slice(n)}</span>
      <div
        style={{
          position: "absolute",
          [tail]: -26,
          top: 44,
          width: 0,
          height: 0,
          borderTop: "16px solid transparent",
          borderBottom: "16px solid transparent",
          [tail === "left" ? "borderRight" : "borderLeft"]: `26px solid ${C.ink}`,
        }}
      />
    </div>
  );
};

/* 1 · Gancho tipo noticia, con avatar del ministro */
export const SNewsHook: React.FC<P> = ({ dur }) => {
  const f = useF();
  const ticker = "MINISTRO DE HACIENDA RECONOCE RECESIÓN TÉCNICA  ·  PIB CAYÓ DOS TRIMESTRES SEGUIDOS  ·  ";
  return (
    <AbsoluteFill>
      <SeriesTag />
      <div style={{ position: "absolute", top: 185, left: 64, display: "flex", alignItems: "center", gap: 14, scale: String(pop(f, 0, 10)) }}>
        <span
          style={{
            background: C.red,
            color: C.paper,
            fontFamily: F.display,
            fontWeight: 800,
            fontSize: 30,
            padding: "6px 16px",
            borderRadius: 8,
            border: `3px solid ${C.ink}`,
            opacity: 0.75 + 0.25 * Math.abs(Math.sin(f / 5)),
          }}
        >
          ● ÚLTIMA HORA
        </span>
        <span style={{ fontFamily: F.body, fontWeight: 700, fontSize: 24, color: C.muted }}>11 de noviembre</span>
      </div>
      <div style={{ position: "absolute", top: 270, left: 52, scale: String(pop(f, 4, 12)) }}>
        <Avatar look={LOOKS.quiroz} size={300} talking={f < dur / 2 - 10} bg={C.yellow} />
        <div style={{ textAlign: "center", marginTop: -10 }}>
          <Pill text="Jorge Quiroz · Hacienda" bg={C.paper} size={22} />
        </div>
      </div>
      <div style={{ position: "absolute", top: 300, left: 400, right: 50 }}>
        <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 70, lineHeight: 0.98, letterSpacing: -2, color: C.ink, opacity: prog(f, 8, 16) }}>
          Chile está en
        </div>
        <div
          style={{
            display: "inline-block",
            marginTop: 12,
            background: C.red,
            color: C.paper,
            fontFamily: F.display,
            fontWeight: 800,
            fontSize: 74,
            letterSpacing: -2,
            lineHeight: 1,
            padding: "10px 20px 14px",
            borderRadius: 14,
            border: `${sw}px solid ${C.ink}`,
            boxShadow: STYLE.shadow(8),
            rotate: "-2deg",
            scale: String(pop(f, 14, 12)),
          }}
        >
          recesión técnica
        </div>
      </div>
      <div style={{ position: "absolute", left: 0, right: 0, top: 655, height: 60, background: C.ink, overflow: "hidden", borderTop: `${sw}px solid ${C.ink}` }}>
        <div style={{ whiteSpace: "nowrap", fontFamily: F.display, fontWeight: 800, fontSize: 32, color: C.yellow, lineHeight: "56px", translate: `${-((f * 6) % 1600)}px 0px` }}>
          {ticker.repeat(4)}
        </div>
      </div>
    </AbsoluteFill>
  );
};

/* 2 · Gráfico a pantalla completa: qué es una recesión técnica (ejemplo) */
export const SRecessionChart: React.FC<P & { zoneAt: number }> = ({ zoneAt }) => {
  const f = useF();
  const vals = [100, 102, 103.5, 105, 106.5, 105.3, 104.2];
  const X0 = 110,
    X1 = 970,
    Y0 = 1260,
    Y1 = 700;
  const min = 98,
    max = 108;
  const x = (i: number) => X0 + (i / (vals.length - 1)) * (X1 - X0);
  const y = (v: number) => Y0 - ((v - min) / (max - min)) * (Y0 - Y1);
  const d = vals.map((v, i) => `${i ? "L" : "M"}${x(i)} ${y(v)}`).join(" ");
  const len = 1400;
  const p = prog(f, 4, 40);
  const zone = prog(f, zoneAt, zoneAt + 12);
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Title text="¿CUÁNDO HAY" top={250} size={96} />
      <Title text="RECESIÓN TÉCNICA?" top={350} size={96} color={C.red} at={4} />
      <div style={{ position: "absolute", top: 520, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
        <Pill text="EJEMPLO · lo que produce un país, trimestre a trimestre" bg={C.faint} size={24} />
      </div>
      <svg width={1080} height={1920} style={{ position: "absolute", left: 0, top: 0 }}>
        <rect
          x={x(4) + 4}
          y={Y1 - 40}
          width={(x(6) - x(4) + 40) * zone}
          height={Y0 - Y1 + 80}
          fill={C.red}
          opacity={0.14}
          stroke={C.red}
          strokeWidth={zone > 0.01 ? 4 : 0}
          strokeDasharray="14 10"
          rx={18}
        />
        <line x1={X0 - 30} y1={Y0 + 40} x2={X1 + 40} y2={Y0 + 40} stroke={C.ink} strokeWidth={sw} />
        <path d={d} fill="none" stroke={C.blue} strokeWidth={12} strokeLinejoin="round" strokeLinecap="round" strokeDasharray={len} strokeDashoffset={len * (1 - p)} />
        {vals.map((v, i) => {
          const s = pop(f, 4 + (i / (vals.length - 1)) * 36, 8);
          const down = i >= 5;
          return (
            <g key={i}>
              <circle cx={x(i)} cy={y(v)} r={18 * s} fill={down ? C.red : C.paper} stroke={C.ink} strokeWidth={sw} />
              <text x={x(i)} y={Y0 + 95} textAnchor="middle" fontFamily={F.display} fontWeight={800} fontSize={30} fill={C.muted} opacity={s}>
                T{i + 1}
              </text>
              {down ? (
                <text x={x(i)} y={y(v) - 40} textAnchor="middle" fontFamily={F.display} fontWeight={800} fontSize={56} fill={C.red} opacity={s}>
                  ▼
                </text>
              ) : null}
            </g>
          );
        })}
      </svg>
      <div style={{ position: "absolute", top: 1440, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: zone, scale: String(0.8 + 0.2 * pop(f, zoneAt + 6, 12)) }}>
        <div
          style={{
            background: C.red,
            color: C.paper,
            fontFamily: F.display,
            fontWeight: 800,
            fontSize: 60,
            letterSpacing: -1,
            padding: "14px 30px 18px",
            borderRadius: 16,
            border: `${sw}px solid ${C.ink}`,
            boxShadow: STYLE.shadow(10),
            textAlign: "center",
            lineHeight: 1.05,
          }}
        >
          2 trimestres de caída
          <br />= recesión técnica
        </div>
      </div>
    </AbsoluteFill>
  );
};

/* 3 · PIB de Chile con lupa sobre los decimales */
export const SMagnifier: React.FC<P & { t2At: number; lensAt: number; twoAt: number }> = ({ t2At, lensAt, twoAt }) => {
  const f = useF();
  const lx = interpolate(f, [lensAt, lensAt + 14], [1000, 640], { ...clamp, easing: (t) => 1 - Math.pow(1 - t, 3) });
  const lensOn = f >= lensAt;
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="PIB de Chile 2026" accent={C.red} right={<Pill text="vs. trimestre anterior" bg={C.faint} size={22} />} source="Banco Central · prensa (decimales)">
        <div style={{ position: "absolute", top: 120, left: 60, width: 360, textAlign: "center" }}>
          <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 26, color: C.muted }}>ENE–MAR</div>
          <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 110, color: C.red, letterSpacing: -3, scale: String(pop(f, 2, 12)) }}>-0,3%</div>
          <Icon name="down" size={60} color={C.red} />
        </div>
        <div style={{ position: "absolute", top: 120, left: 470, width: 400, textAlign: "center", opacity: f >= t2At ? 1 : 0 }}>
          <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 26, color: C.muted }}>ABR–JUN</div>
          <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 110, color: "#9A9AA2", letterSpacing: -3, scale: String(pop(f, t2At, 12)) }}>0,0%</div>
          <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 24, color: C.muted }}>cifra oficial</div>
        </div>
        {lensOn ? (
          <div style={{ position: "absolute", left: lx - 150, top: 70, width: 300, height: 300 }}>
            <div
              style={{
                position: "absolute",
                inset: 0,
                borderRadius: "50%",
                background: "#FFF8E1",
                border: `10px solid ${C.ink}`,
                boxShadow: STYLE.shadow(8),
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                overflow: "hidden",
              }}
            >
              <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 92, color: C.red, letterSpacing: -3 }}>-0,02%</div>
              <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 22, color: C.muted }}>todos los decimales</div>
            </div>
            <div style={{ position: "absolute", left: 230, top: 250, width: 40, height: 130, background: C.ink, borderRadius: 14, rotate: "-40deg", transformOrigin: "top center" }} />
          </div>
        ) : null}
        <div style={{ position: "absolute", top: 400, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: f >= twoAt ? 1 : 0, scale: String(pop(f, twoAt, 12)) }}>
          <Pill text="2 CAÍDAS SEGUIDAS = RECESIÓN TÉCNICA" bg={C.red} color={C.paper} size={30} />
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 4 · Cita con avatar y globo */
export const SAvatarQuote: React.FC<P & { look: keyof typeof LOOKS; quote: string; who: string; role: string; source: string; chips?: { at: number; text: string; bg: string; color?: string }[]; talkUntil?: number }> = ({
  look,
  quote,
  who,
  role,
  source,
  chips = [],
  talkUntil = 60,
}) => {
  const f = useF();
  return (
    <AbsoluteFill>
      <SeriesTag />
      <div style={{ position: "absolute", top: 210, left: 46, scale: String(pop(f, 0, 12)) }}>
        <Avatar look={LOOKS[look]} size={290} talking={f < talkUntil} bg={C.yellow} />
      </div>
      <div style={{ position: "absolute", top: 210, left: 380 }}>
        <Bubble text={`“${quote}”`} at={6} width={630} size={50} />
      </div>
      <div style={{ position: "absolute", top: 520, left: 46, opacity: prog(f, 10, 18) }}>
        <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 40 }}>{who}</div>
        <div style={{ fontFamily: F.body, fontWeight: 600, fontSize: 24, color: C.muted }}>
          {role} · {source}
        </div>
      </div>
      <div style={{ position: "absolute", top: 640, left: 46, display: "flex", gap: 14 }}>
        {chips.map((c) => (
          <div key={c.text} style={{ scale: String(pop(f, c.at, 10)), opacity: f >= c.at ? 1 : 0 }}>
            <Pill text={c.text} bg={c.bg} color={c.color ?? C.ink} size={28} />
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};

/* 5 · Pantalla completa: auto en pana en la carretera + bencina que sube */
export const SCarRoad: React.FC<P & { b2: number }> = ({ b2 }) => {
  const f = useF();
  const price = Math.round(count(f, b2, b2 + 30, 1390, 1290));
  const smoke = (i: number) => ((f + i * 9) % 27) / 27;
  return (
    <AbsoluteFill style={{ background: "linear-gradient(180deg,#FCE9CF 0%,#F4F0E8 55%)" }}>
      <SeriesTag />
      <Title text="LA ECONOMÍA NO AVANZA…" top={230} size={72} />
      <Title text="…PERO LOS PRECIOS SUBEN" top={320} size={72} color={C.red} at={b2} />
      {/* bencinera */}
      <div style={{ position: "absolute", right: 70, top: 520, opacity: f >= b2 - 4 ? 1 : 0.35, scale: String(0.9 + 0.1 * pop(f, b2, 12)) }}>
        <div
          style={{
            width: 360,
            background: C.ink,
            border: `${sw}px solid ${C.ink}`,
            borderRadius: 20,
            padding: "18px 20px",
            boxShadow: STYLE.shadow(10),
            textAlign: "center",
          }}
        >
          <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 30, color: C.yellow, letterSpacing: 2 }}>BENCINA 95</div>
          <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 96, color: "#7CFF9B", letterSpacing: 2, fontVariantNumeric: "tabular-nums" }}>
            ${fmt(price)}
          </div>
          <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 20, color: "#BBB" }}>por litro · ejemplo</div>
        </div>
        <div style={{ width: 24, height: 360, background: C.ink, margin: "0 auto" }} />
      </div>
      <div style={{ position: "absolute", right: 190, top: 395, opacity: f >= b2 ? 1 : 0, translate: `0px ${-Math.abs(Math.sin(f / 5)) * 22}px` }}>
        <Icon name="up" size={120} color={C.red} />
      </div>
      {/* carretera */}
      <div style={{ position: "absolute", left: 0, right: 0, top: 1250, height: 300, background: "#3B3B42", borderTop: `${sw}px solid ${C.ink}`, borderBottom: `${sw}px solid ${C.ink}` }}>
        {new Array(8).fill(0).map((_, i) => (
          <div key={i} style={{ position: "absolute", top: 140, left: i * 160 + 20, width: 90, height: 16, background: C.yellow }} />
        ))}
      </div>
      {/* auto detenido con humo */}
      <div style={{ position: "absolute", left: 50, top: 900 }}>
        {[0, 1, 2, 3].map((i) => (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 290 + i * 20,
              top: 40 - smoke(i) * 200,
              width: 70 - smoke(i) * 30,
              height: 70 - smoke(i) * 30,
              borderRadius: 999,
              background: "#9A9DA6",
              border: `3px solid ${C.ink}`,
              opacity: 1 - smoke(i),
            }}
          />
        ))}
        <div style={{ rotate: `${Math.sin(f / 1.5) * 1.2}deg` }}>
          <Icon name="car" size={500} color={C.red} />
        </div>
        <div style={{ position: "absolute", left: 150, top: 420 }}>
          <Pill text="EN PANA" bg={C.yellow} size={40} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

/* 6 · Años 70: el petróleo se cuadruplicó (aprox. US$3 → US$12) */
export const SOil70: React.FC<P & { b2: number; b3: number }> = ({ b2, b3 }) => {
  const f = useF();
  const p = prog(f, b2 - 6, b2 + 18);
  const W = 560,
    H = 190;
  const pts = [3, 3, 3.1, 5, 11.6, 11.7];
  const path = pts.map((v, i) => `${i ? "L" : "M"}${(i / (pts.length - 1)) * W} ${H - (v / 12) * H}`).join(" ");
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="1973: crisis del petróleo" accent={C.copper} source="precio aprox. del barril, oct 1973 → ene 1974">
        <div style={{ position: "absolute", top: 120, left: 40, scale: String(pop(f, 2, 12)) }}>
          <Icon name="barrel" size={150} color={C.copper} />
        </div>
        <svg width={W + 60} height={H + 60} style={{ position: "absolute", left: 230, top: 120, overflow: "visible" }}>
          <line x1={0} y1={H} x2={W} y2={H} stroke={C.ink} strokeWidth={4} />
          <path d={path} fill="none" stroke={C.red} strokeWidth={10} strokeLinejoin="round" strokeDasharray={900} strokeDashoffset={900 * (1 - p)} />
          <text x={0} y={H - 24} fontFamily={F.display} fontWeight={800} fontSize={30} fill={C.muted}>
            ≈US$3
          </text>
          <text x={W - 190} y={-14} fontFamily={F.display} fontWeight={800} fontSize={34} fill={C.red} opacity={p}>
            ≈US$12
          </text>
        </svg>
        <div style={{ position: "absolute", top: 150, right: 60, fontFamily: F.display, fontWeight: 800, fontSize: 120, color: C.red, letterSpacing: -4, opacity: f >= b2 + 12 ? 1 : 0, scale: String(pop(f, b2 + 12, 12)), rotate: "-6deg" }}>
          ×4
        </div>
        <div style={{ position: "absolute", top: 345, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 16, opacity: f >= b3 ? 1 : 0, scale: String(pop(f, b3, 12)) }}>
          <Pill text="▲ INFLACIÓN" bg={C.red} color={C.paper} size={30} />
          <Pill text="▲ DESEMPLEO" bg={C.red} color={C.paper} size={30} />
          <Pill text="al mismo tiempo" bg={C.yellow} size={30} />
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 7 · Pantalla completa: la "receta" de la estanflación */
export const SPot: React.FC<P & { beats: number[]; doneAt: number }> = ({ beats, doneAt }) => {
  const f = useF();
  const items = [
    { t: "CRECIMIENTO ≈0%", bg: C.paper, c: C.ink, icon: "pause" as const, ic: C.yellow },
    { t: "INFLACIÓN 4,5%", bg: C.red, c: C.paper, icon: "up" as const, ic: C.paper },
    { t: "DESEMPLEO 9,8%", bg: C.blue, c: C.paper, icon: "person" as const, ic: C.yellow },
  ];
  const done = f >= doneAt;
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Title text="LA RECETA DE LA" top={220} size={92} />
      <Title text="ESTANFLACIÓN" top={315} size={110} color={C.blue} at={4} />
      {items.map((it, i) => {
        const a = beats[i];
        const fall = interpolate(f, [a, a + 16, a + 30], [-300, 640, 1080], { ...clamp, easing: (t) => t * t });
        const inPot = f > a + 30;
        const shown = f >= a && !inPot;
        const parked = interpolate(f, [a + 30, a + 40], [0, 1], clamp);
        return (
          <React.Fragment key={it.t}>
            <div
              style={{
                position: "absolute",
                left: 0,
                right: 0,
                top: fall,
                display: shown ? "flex" : "none",
                justifyContent: "center",
                rotate: `${Math.sin((f + i * 20) / 6) * 6}deg`,
              }}
            >
              <div style={{ display: "flex", alignItems: "center", gap: 12, background: it.bg, color: it.c, border: `${sw}px solid ${C.ink}`, borderRadius: 16, boxShadow: STYLE.shadow(8), padding: "12px 22px", fontFamily: F.display, fontWeight: 800, fontSize: 52 }}>
                <Icon name={it.icon} size={56} color={it.ic} />
                {it.t}
              </div>
            </div>
            {/* lista de ingredientes ya agregados */}
            <div style={{ position: "absolute", left: 80, top: 520 + i * 70, opacity: parked, display: "flex", alignItems: "center", gap: 12 }}>
              <Icon name="check" size={48} color={C.green} />
              <span style={{ fontFamily: F.display, fontWeight: 800, fontSize: 38 }}>{it.t}</span>
            </div>
          </React.Fragment>
        );
      })}
      {/* vapor */}
      {new Array(6).fill(0).map((_, i) => {
        const t = ((f + i * 11) % 60) / 60;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: 400 + random(`st${i}`) * 260,
              top: 1080 - t * 260,
              width: 60 - t * 30,
              height: 60 - t * 30,
              borderRadius: 999,
              background: done ? "#C9D4FF" : "#E2DED6",
              border: `3px solid ${C.ink}`,
              opacity: (1 - t) * 0.9,
            }}
          />
        );
      })}
      {/* olla */}
      <svg width={1080} height={700} style={{ position: "absolute", left: 0, top: 1060 }}>
        <rect x={250} y={60} width={580} height={60} rx={20} fill={C.muted} stroke={C.ink} strokeWidth={sw} />
        <path d="M280 120 L800 120 L770 420 Q760 470 700 470 L380 470 Q320 470 310 420 Z" fill="#2B2F3A" stroke={C.ink} strokeWidth={sw} strokeLinejoin="round" />
        <rect x={190} y={150} width={90} height={30} rx={12} fill="#2B2F3A" stroke={C.ink} strokeWidth={sw} />
        <rect x={800} y={150} width={90} height={30} rx={12} fill="#2B2F3A" stroke={C.ink} strokeWidth={sw} />
        <ellipse cx={540} cy={90} rx={260} ry={22} fill={done ? C.blue : "#5A6072"} stroke={C.ink} strokeWidth={4} />
      </svg>
      <div style={{ position: "absolute", top: 1300, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: done ? 1 : 0, scale: String(pop(f, doneAt, 12)) }}>
        <Pill text="3 DE 3 INGREDIENTES" bg={C.yellow} size={44} />
      </div>
    </AbsoluteFill>
  );
};

/* 8 · Pantalla completa: el dilema del Banco Central (balancín) */
export const SSeesaw: React.FC<P & { b1: number; b2: number }> = ({ b1, b2 }) => {
  const f = useF();
  const tilt = interpolate(f, [0, b1, b1 + 14, b2, b2 + 14], [0, 0, 14, 14, -14], { ...clamp, easing: (t) => 1 - Math.pow(1 - t, 3) });
  const phase = f >= b2 ? 2 : f >= b1 ? 1 : 0;
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Title text="EL BANCO CENTRAL," top={220} size={84} />
      <Title text="AMARRADO" top={310} size={120} color={C.red} at={4} />
      <div style={{ position: "absolute", top: 480, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 20 }}>
        <div style={{ opacity: phase === 1 ? 1 : 0.35, scale: String(phase === 1 ? 1 : 0.9) }}>
          <Pill text="▲ SUBE LA TASA" bg={phase === 1 ? C.blue : C.paper} color={phase === 1 ? C.paper : C.ink} size={36} />
        </div>
        <div style={{ opacity: phase === 2 ? 1 : 0.35, scale: String(phase === 2 ? 1 : 0.9) }}>
          <Pill text="▼ BAJA LA TASA" bg={phase === 2 ? C.blue : C.paper} color={phase === 2 ? C.paper : C.ink} size={36} />
        </div>
      </div>
      <div style={{ position: "absolute", left: 90, right: 90, top: 1060, height: 26, background: C.ink, borderRadius: 13, rotate: `${tilt}deg` }}>
        {/* lado izquierdo: precios */}
        <div style={{ position: "absolute", left: 10, bottom: 30, width: 300, textAlign: "center" }}>
          <div style={{ scale: String(phase === 2 ? 1.25 + 0.05 * Math.sin(f / 3) : 1), transformOrigin: "bottom center" }}>
            <Icon name="tag" size={180} color={C.red} />
          </div>
          <Pill text={phase === 2 ? "▲ PRECIOS" : "PRECIOS"} bg={phase === 2 ? C.red : C.paper} color={phase === 2 ? C.paper : C.ink} size={34} />
        </div>
        {/* lado derecho: economía y empleo */}
        <div style={{ position: "absolute", right: 10, bottom: 30, width: 300, textAlign: "center" }}>
          <div style={{ display: "flex", justifyContent: "center", gap: 6, opacity: phase === 1 ? 0.55 : 1 }}>
            <Icon name="factory" size={130} color={C.blue} />
            <Icon name="person" size={110} color={C.green} />
          </div>
          <Pill text={phase === 1 ? "▼ ECONOMÍA Y EMPLEO" : "ECONOMÍA Y EMPLEO"} bg={phase === 1 ? C.red : C.paper} color={phase === 1 ? C.paper : C.ink} size={28} />
        </div>
      </div>
      {/* pivote con el banco */}
      <div style={{ position: "absolute", left: 465, top: 1090, width: 0, height: 0, borderLeft: "75px solid transparent", borderRight: "75px solid transparent", borderBottom: `150px solid ${C.ink}` }} />
      <div style={{ position: "absolute", left: 470, top: 1250 }}>
        <Icon name="bank" size={140} color={C.yellow} />
      </div>
    </AbsoluteFill>
  );
};

/* 9 · ¿Estamos o no? Dos avatares con globos */
export const SVerdictAvatars: React.FC<P & { b2: number }> = ({ b2 }) => {
  const f = useF();
  return (
    <AbsoluteFill>
      <SeriesTag />
      <div style={{ position: "absolute", top: 180, left: 40, display: "flex", alignItems: "flex-start", gap: 30, scale: String(pop(f, 0, 12)) }}>
        <Avatar look={LOOKS.costa} size={190} talking={f < b2} bg={C.green} />
        <div>
          <Bubble text="Por ahora, no." at={4} width={600} size={50} typing={false} />
          <div style={{ fontFamily: F.body, fontWeight: 600, fontSize: 22, color: C.muted, marginTop: 10 }}>Rosanna Costa · presidenta del Banco Central (sept., paráfrasis)</div>
        </div>
      </div>
      <div style={{ position: "absolute", top: 440, right: 40, display: "flex", flexDirection: "row-reverse", alignItems: "flex-start", gap: 30, opacity: f >= b2 ? 1 : 0, scale: String(pop(f, b2, 12)) }}>
        <Avatar look={LOOKS.ortiz} size={190} talking={f >= b2} bg={C.red} />
        <div>
          <Bubble text="“Virtualmente… en una estanflación”" at={b2 + 2} width={600} size={42} tail="right" />
          <div style={{ fontFamily: F.body, fontWeight: 600, fontSize: 22, color: C.muted, marginTop: 10, textAlign: "right" }}>Juan Ortiz · economista OCEC-UDP (sept.)</div>
        </div>
      </div>
    </AbsoluteFill>
  );
};
