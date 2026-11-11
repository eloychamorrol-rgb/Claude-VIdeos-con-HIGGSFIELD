import React from "react";
import {
  AbsoluteFill,
  Easing,
  interpolate,
  random,
  useCurrentFrame,
} from "remotion";
import { C, body, clamp, display, ease, fmtCL, outro, pop, prog } from "../theme";

/* ------------------------------------------------------------------ */
/* Shared building blocks                                              */
/* ------------------------------------------------------------------ */

type G = { dur: number };

/** Region used by every split-screen graphic: top 1000px of the frame. */
export const Panel: React.FC<{ children: React.ReactNode; dur: number }> = ({
  children,
  dur,
}) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill
      style={{
        height: 1000,
        opacity: outro(f, dur, 6),
        fontFamily: body,
        color: C.white,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

export const Kicker: React.FC<{ text: string; color: string; at?: number }> = ({
  text,
  color,
  at = 0,
}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + 12);
  return (
    <div
      style={{
        position: "absolute",
        top: 170,
        left: 0,
        right: 0,
        display: "flex",
        justifyContent: "center",
        opacity: p,
        translate: `0px ${(1 - p) * -30}px`,
      }}
    >
      <div
        style={{
          fontFamily: display,
          fontWeight: 800,
          fontSize: 40,
          letterSpacing: 4,
          textTransform: "uppercase",
          color: C.ink,
          background: color,
          padding: "10px 28px",
          borderRadius: 999,
        }}
      >
        {text}
      </div>
    </div>
  );
};

const Big: React.FC<{
  children: React.ReactNode;
  color?: string;
  size?: number;
  top: number;
  at?: number;
}> = ({ children, color = C.white, size = 190, top, at = 0 }) => {
  const f = useCurrentFrame();
  const s = pop(f, at, 14);
  return (
    <div
      style={{
        position: "absolute",
        top,
        left: 0,
        right: 0,
        textAlign: "center",
        fontFamily: display,
        fontWeight: 900,
        fontSize: size,
        lineHeight: 1,
        color,
        scale: String(0.6 + 0.4 * s),
        opacity: Math.min(1, s * 1.5),
        textShadow: "0 8px 40px rgba(0,0,0,0.45)",
        fontVariantNumeric: "tabular-nums",
      }}
    >
      {children}
    </div>
  );
};

const Sub: React.FC<{ children: React.ReactNode; top: number; at?: number; color?: string; size?: number }> = ({
  children,
  top,
  at = 0,
  color = C.muted,
  size = 46,
}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, at + 14);
  return (
    <div
      style={{
        position: "absolute",
        top,
        left: 90,
        right: 90,
        textAlign: "center",
        fontFamily: body,
        fontWeight: 600,
        fontSize: size,
        lineHeight: 1.2,
        color,
        opacity: p,
        translate: `0px ${(1 - p) * 24}px`,
      }}
    >
      {children}
    </div>
  );
};

const countUp = (f: number, a: number, b: number, to: number, from = 0) =>
  interpolate(f, [a, b], [from, to], {
    ...clamp,
    easing: Easing.bezier(0.22, 1, 0.36, 1),
  });

/* ------------------------------------------------------------------ */
/* 1. Hook — copper expensive vs 1 million unemployed (full screen)    */
/* ------------------------------------------------------------------ */

export const HookCopperVsJobs: React.FC<G & { secondAt: number }> = ({ dur, secondAt }) => {
  const f = useCurrentFrame();
  const left = prog(f, 0, 12);
  const right = prog(f, secondAt, secondAt + 12);
  const vs = pop(f, secondAt + 8, 12);
  const Half: React.FC<{
    p: number;
    from: number;
    bg: string;
    emoji: string;
    big: string;
    label: string;
    arrow: string;
    arrowColor: string;
    grow: number;
  }> = ({ p, from, bg, emoji, big, label, arrow, arrowColor, grow }) => (
    <div
      style={{
        flex: grow,
        minWidth: 0,
        overflow: "hidden",
        whiteSpace: "nowrap",
        background: bg,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        translate: `${(1 - p) * from}px 0px`,
        opacity: p,
        gap: 18,
      }}
    >
      <div style={{ fontSize: 150 }}>{emoji}</div>
      <div
        style={{
          fontFamily: display,
          fontWeight: 900,
          fontSize: 92,
          color: C.white,
          lineHeight: 1,
        }}
      >
        {big}
      </div>
      <div style={{ fontFamily: body, fontWeight: 600, fontSize: 40, color: C.white, opacity: 0.9 }}>
        {label}
      </div>
      <div
        style={{
          fontSize: 110,
          fontWeight: 900,
          color: arrowColor,
          translate: `0px ${Math.sin(f / 5) * 8}px`,
        }}
      >
        {arrow}
      </div>
    </div>
  );
  return (
    <Panel dur={dur}>
      <div style={{ display: "flex", height: 1000 }}>
        <Half
          p={left}
          grow={1 + (1 - right) * 6}
          from={-540}
          bg="linear-gradient(160deg,#B4532A,#7A2E12)"
          emoji="⛏️"
          big="Cobre"
          label="precio muy alto"
          arrow="▲"
          arrowColor={C.green}
        />
        <Half
          p={Math.max(0.001, right)}
          grow={Math.max(0.001, right)}
          from={0}
          bg="linear-gradient(160deg,#22305E,#0B1020)"
          emoji="👥"
          big="+1 millón"
          label="sin trabajo"
          arrow="▲"
          arrowColor={C.red}
        />
      </div>
      <div style={{ position: "absolute", top: 150, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: left }}>
        <div style={{ background: "rgba(0,0,0,0.45)", borderRadius: 999, padding: "10px 30px", fontFamily: display, fontWeight: 800, fontSize: 38, letterSpacing: 2 }}>
          🇨🇱 ECONOMÍA CHILENA HOY
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          top: 790,
          left: 465,
          width: 150,
          height: 150,
          borderRadius: 75,
          background: C.yellow,
          color: C.ink,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: display,
          fontWeight: 900,
          fontSize: 60,
          scale: String(vs),
          rotate: `${(1 - vs) * -40}deg`,
          boxShadow: "0 10px 40px rgba(0,0,0,0.5)",
        }}
      >
        ¿?
      </div>
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 2. Unemployment — 8.5% → 9.8% bars                                  */
/* ------------------------------------------------------------------ */

export const UnemploymentBars: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const maxH = 520;
  const scale = (v: number) => (v / 10.5) * maxH;
  const b1 = prog(f, 6, 26);
  const b2 = prog(f, 18, 44);
  const v2 = countUp(f, 18, 44, 9.8, 0);
  const Bar: React.FC<{ x: number; p: number; v: number; label: string; color: string; text: string }> = ({
    x,
    p,
    v,
    label,
    color,
    text,
  }) => (
    <div
      style={{
        position: "absolute",
        left: x,
        bottom: 1000 - 900,
        width: 230,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
      }}
    >
      <div
        style={{
          fontFamily: display,
          fontWeight: 900,
          fontSize: 70,
          color,
          opacity: p,
          marginBottom: 12,
        }}
      >
        {text}
      </div>
      <div
        style={{
          width: 230,
          height: scale(v) * p,
          background: `linear-gradient(180deg, ${color}, ${color}88)`,
          borderRadius: "22px 22px 6px 6px",
        }}
      />
      <div style={{ fontFamily: body, fontWeight: 700, fontSize: 38, color: C.muted, marginTop: 14 }}>
        {label}
      </div>
    </div>
  );
  const arrow = prog(f, 40, 56);
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#151E3D)" }} />
      <Kicker text="Desempleo" color={C.red} />
      <Bar x={190} p={b1} v={8.5} label="2025" color={C.muted} text="8,5%" />
      <Bar x={660} p={b2} v={9.8} label="2026" color={C.red} text={`${fmtCL(v2, 1)}%`} />
      <div
        style={{
          position: "absolute",
          left: 450,
          top: 470,
          fontFamily: display,
          fontWeight: 900,
          fontSize: 44,
          color: C.yellow,
          opacity: arrow,
          translate: `${(1 - arrow) * -40}px 0px`,
          textAlign: "center",
          width: 180,
        }}
      >
        +1,3 pts
        <div style={{ fontSize: 80, lineHeight: 1 }}>➚</div>
      </div>
      <Sub top={930} at={30} size={34}>
        jul–sep · INE
      </Sub>
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 3. One million people — counter + people grid                       */
/* ------------------------------------------------------------------ */

export const MillionPeople: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const n = countUp(f, 4, 50, 1007976);
  const cols = 16;
  const rows = 7;
  const total = cols * rows;
  const lit = Math.floor(interpolate(f, [4, 50], [0, total], clamp));
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#1A1030)" }} />
      <Kicker text="Personas sin trabajo" color={C.yellow} />
      <Big top={270} size={150} color={C.white}>
        {fmtCL(Math.round(n))}
      </Big>
      <div
        style={{
          position: "absolute",
          top: 470,
          left: 110,
          width: 860,
          display: "grid",
          gridTemplateColumns: `repeat(${cols}, 1fr)`,
          rowGap: 10,
        }}
      >
        {new Array(total).fill(0).map((_, i) => {
          const on = i < lit;
          return (
            <div
              key={i}
              style={{
                fontSize: 40,
                textAlign: "center",
                opacity: on ? 1 : 0.15,
                filter: on ? "none" : "grayscale(1)",
                scale: on ? String(interpolate(f - i * (46 / total), [4, 10], [1.4, 1], clamp)) : "1",
              }}
            >
              🧍
            </div>
          );
        })}
      </div>
    </Panel>
  );
};

/* Comparison: Puente Alto + Maipú */
export const CityCompare: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const a = pop(f, 2, 14);
  const b = pop(f, 10, 14);
  const eq = pop(f, 20, 14);
  const Pill: React.FC<{ s: number; name: string; color: string }> = ({ s, name, color }) => (
    <div
      style={{
        scale: String(s),
        background: color,
        borderRadius: 40,
        padding: "34px 44px",
        fontFamily: display,
        fontWeight: 900,
        fontSize: 64,
        color: C.ink,
        boxShadow: "0 12px 40px rgba(0,0,0,0.4)",
      }}
    >
      🏙️ {name}
    </div>
  );
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#14213D)" }} />
      <div
        style={{
          position: "absolute",
          top: 210,
          left: 0,
          right: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 26,
        }}
      >
        <Pill s={a} name="Puente Alto" color={C.blue} />
        <div style={{ fontFamily: display, fontWeight: 900, fontSize: 80, opacity: b }}>+</div>
        <Pill s={b} name="Maipú" color={C.green} />
        <div style={{ fontFamily: display, fontWeight: 900, fontSize: 60, color: C.yellow, scale: String(eq), marginTop: 10 }}>
          ≈ 1 millón de personas
        </div>
      </div>
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 4. Inflation — lunch price tag $5.000 → $5.225                      */
/* ------------------------------------------------------------------ */

export const LunchPrice: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const plate = pop(f, 0, 14);
  const price = countUp(f, 22, 46, 5225, 5000);
  const strike = prog(f, 18, 26);
  const shake = f > 46 && f < 56 ? Math.sin(f * 2.4) * 6 : 0;
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#1B1206,#0B1020)" }} />
      <Kicker text="Inflación: 4,5% en un año" color={C.orange} />
      <div
        style={{
          position: "absolute",
          top: 280,
          left: 0,
          right: 0,
          textAlign: "center",
          fontSize: 230,
          scale: String(plate),
        }}
      >
        🍛
      </div>
      <div style={{ position: "absolute", top: 560, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 50, alignItems: "center" }}>
        <div style={{ position: "relative", fontFamily: display, fontWeight: 800, fontSize: 80, color: C.muted }}>
          $5.000
          <div
            style={{
              position: "absolute",
              left: -6,
              top: "50%",
              height: 8,
              width: `${strike * 104}%`,
              background: C.red,
              borderRadius: 4,
              rotate: "-6deg",
            }}
          />
          <div style={{ fontFamily: body, fontSize: 32, fontWeight: 600, textAlign: "center" }}>hace un año</div>
        </div>
        <div style={{ fontSize: 80, opacity: strike }}>➜</div>
        <div
          style={{
            fontFamily: display,
            fontWeight: 900,
            fontSize: 110,
            color: C.yellow,
            opacity: prog(f, 20, 28),
            translate: `${shake}px 0px`,
            fontVariantNumeric: "tabular-nums",
          }}
        >
          ${fmtCL(Math.round(price))}
          <div style={{ fontFamily: body, fontSize: 32, fontWeight: 600, textAlign: "center", color: C.white }}>hoy</div>
        </div>
      </div>
    </Panel>
  );
};

/* What rose the most in October */
export const WhatRose: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const rows = [
    { e: "⛽", t: "Transporte / bencina", v: 2.0, c: C.red },
    { e: "🛒", t: "Alimentos", v: 1.0, c: C.orange },
  ];
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#1B1206,#0B1020)" }} />
      <Kicker text="Lo que más subió en octubre" color={C.orange} />
      {rows.map((r, i) => {
        const p = prog(f, 6 + i * 10, 30 + i * 10);
        return (
          <div key={r.t} style={{ position: "absolute", top: 330 + i * 250, left: 90, right: 90, opacity: Math.min(1, p * 2) }}>
            <div style={{ display: "flex", alignItems: "center", gap: 24, fontFamily: display, fontWeight: 800, fontSize: 52 }}>
              <span style={{ fontSize: 80 }}>{r.e}</span>
              <span style={{ flex: 1 }}>{r.t}</span>
              <span style={{ color: r.c, fontWeight: 900, fontSize: 70 }}>+{fmtCL(r.v * p, 1)}%</span>
            </div>
            <div style={{ height: 34, background: "rgba(255,255,255,0.1)", borderRadius: 17, marginTop: 18 }}>
              <div style={{ height: 34, width: `${(r.v / 2.2) * 100 * p}%`, background: r.c, borderRadius: 17 }} />
            </div>
          </div>
        );
      })}
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 5. Growth — speedometer almost at zero                              */
/* ------------------------------------------------------------------ */

export const Speedometer: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const cx = 540;
  const cy = 700;
  const r = 340;
  // angle: -180deg (0%) → 0deg (5%)
  const target = 0.2;
  const jitter = f > 34 ? Math.sin(f / 2.2) * 1.2 : 0;
  const val = interpolate(f, [8, 22, 34], [0, 1.6, target], { ...clamp, easing: ease });
  const ang = -180 + (val / 5) * 180 + jitter;
  const arc = (a0: number, a1: number) => {
    const p0 = [cx + r * Math.cos((a0 * Math.PI) / 180), cy + r * Math.sin((a0 * Math.PI) / 180)];
    const p1 = [cx + r * Math.cos((a1 * Math.PI) / 180), cy + r * Math.sin((a1 * Math.PI) / 180)];
    return `M ${p0[0]} ${p0[1]} A ${r} ${r} 0 0 1 ${p1[0]} ${p1[1]}`;
  };
  const shown = interpolate(f, [8, 22, 34], [0, 1.6, target], clamp);
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#0F1A33)" }} />
      <Kicker text="Crecimiento (septiembre)" color={C.blue} />
      <svg width={1080} height={1000} style={{ position: "absolute", top: 0, left: 0 }}>
        <path d={arc(-180, -120)} stroke={C.red} strokeWidth={44} fill="none" strokeLinecap="round" />
        <path d={arc(-116, -64)} stroke={C.orange} strokeWidth={44} fill="none" />
        <path d={arc(-60, 0)} stroke={C.green} strokeWidth={44} fill="none" strokeLinecap="round" />
        <g transform={`rotate(${ang} ${cx} ${cy})`}>
          <line x1={cx} y1={cy} x2={cx + r - 70} y2={cy} stroke={C.white} strokeWidth={16} strokeLinecap="round" />
        </g>
        <circle cx={cx} cy={cy} r={34} fill={C.white} />
        <text x={cx - r - 10} y={cy + 70} fill={C.muted} fontSize={36} fontFamily={body} fontWeight={700}>
          0%
        </text>
        <text x={cx + r - 70} y={cy + 70} fill={C.muted} fontSize={36} fontFamily={body} fontWeight={700}>
          5%
        </text>
      </svg>
      <Big top={770} size={130} color={C.yellow} at={30}>
        +{fmtCL(shown, 1)}%
      </Big>
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 6. Copper — price up, production down                               */
/* ------------------------------------------------------------------ */

export const CopperParadox: React.FC<G & { secondAt: number }> = ({ dur, secondAt }) => {
  const f = useCurrentFrame();
  const l = pop(f, 2, 14);
  const r = pop(f, secondAt, 14);
  const prod = countUp(f, secondAt + 2, secondAt + 24, -12.1);
  const Col: React.FC<{ s: number; title: string; big: string; color: string; arrow: string; note: string }> = ({
    s,
    title,
    big,
    color,
    arrow,
    note,
  }) => (
    <div
      style={{
        width: 430,
        height: 600,
        borderRadius: 40,
        background: "rgba(255,255,255,0.06)",
        border: `3px solid ${color}`,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 10,
        scale: String(s),
        opacity: Math.min(1, s * 1.5),
      }}
    >
      <div style={{ fontFamily: body, fontWeight: 700, fontSize: 42, color: C.muted }}>{title}</div>
      <div style={{ fontSize: 150, color, fontWeight: 900, lineHeight: 1, translate: `0px ${Math.sin(f / 6) * 6}px` }}>{arrow}</div>
      <div style={{ fontFamily: display, fontWeight: 900, fontSize: 78, color }}>{big}</div>
      <div style={{ fontFamily: body, fontWeight: 600, fontSize: 32, color: C.muted, textAlign: "center", padding: "0 20px" }}>{note}</div>
    </div>
  );
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#2A1408,#0B1020)" }} />
      <Kicker text="La paradoja del cobre" color={C.copper} />
      <div style={{ position: "absolute", top: 290, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 60 }}>
        <Col s={l} title="Precio" big="US$6,35" color={C.green} arrow="▲" note="por libra" />
        <Col s={r} title="Producción" big={`${fmtCL(prod, 1)}%`} color={C.red} arrow="▼" note="minería, sept." />
      </div>
    </Panel>
  );
};

/* Store vs broken factory analogy */
export const FactoryAnalogy: React.FC<G & { secondAt: number }> = ({ dur, secondAt }) => {
  const f = useCurrentFrame();
  const a = pop(f, 0, 14);
  const b = pop(f, secondAt, 14);
  const smoke = (i: number) => interpolate((f + i * 12) % 40, [0, 40], [0, 1]);
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#1C1330)" }} />
      <div style={{ position: "absolute", top: 220, left: 0, right: 0, display: "flex", justifyContent: "space-around", alignItems: "flex-end" }}>
        <div style={{ textAlign: "center", scale: String(a) }}>
          <div style={{ fontSize: 210 }}>🏷️</div>
          <div style={{ fontFamily: display, fontWeight: 900, fontSize: 56, color: C.green }}>Mejor precio</div>
        </div>
        <div style={{ textAlign: "center", scale: String(b), position: "relative" }}>
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                left: 60 + i * 40,
                top: -40 - smoke(i) * 160,
                fontSize: 70,
                opacity: 1 - smoke(i),
              }}
            >
              💨
            </div>
          ))}
          <div style={{ fontSize: 210, rotate: `${Math.sin(f / 3) * 3}deg` }}>🏭</div>
          <div style={{ fontFamily: display, fontWeight: 900, fontSize: 56, color: C.red }}>Fábrica en pana</div>
        </div>
      </div>
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 7. Central bank dilemma — seesaw                                    */
/* ------------------------------------------------------------------ */

export const RateDilemma: React.FC<G & { beats: number[] }> = ({ dur, beats }) => {
  const f = useCurrentFrame();
  const [b1, b2, b3] = beats;
  const tilt = interpolate(f, [0, b1, b1 + 14, b2, b2 + 14, b3, b3 + 14], [0, 0, -12, -12, 12, 12, 0], { ...clamp, easing: ease });
  const lock = pop(f, b3, 14);
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#10233A)" }} />
      <Kicker text="El dilema del Banco Central" color={C.blue} />
      <div style={{ position: "absolute", top: 330, left: 90, width: 900, height: 400 }}>
        <div style={{ position: "absolute", left: 0, right: 0, top: 160, height: 22, background: C.white, borderRadius: 11, rotate: `${tilt}deg` }}>
          <div style={{ position: "absolute", left: -10, top: -170, width: 300, textAlign: "center" }}>
            <div style={{ fontSize: 110 }}>🔥</div>
            <div style={{ fontFamily: display, fontWeight: 800, fontSize: 40, color: C.orange }}>Precios</div>
          </div>
          <div style={{ position: "absolute", right: -10, top: -170, width: 300, textAlign: "center" }}>
            <div style={{ fontSize: 110 }}>🏦</div>
            <div style={{ fontFamily: display, fontWeight: 800, fontSize: 40, color: C.blue }}>Créditos</div>
          </div>
        </div>
        <div
          style={{
            position: "absolute",
            left: 390,
            top: 182,
            width: 0,
            height: 0,
            borderLeft: "60px solid transparent",
            borderRight: "60px solid transparent",
            borderBottom: `120px solid ${C.muted}`,
          }}
        />
      </div>
      <div style={{ position: "absolute", top: 720, left: 0, right: 0, display: "flex", justifyContent: "center", scale: String(lock), opacity: lock }}>
        <div style={{ background: C.yellow, color: C.ink, borderRadius: 30, padding: "18px 40px", fontFamily: display, fontWeight: 900, fontSize: 90 }}>
          🔒 Tasa 4,5%
        </div>
      </div>
    </Panel>
  );
};

/* "Hasta pensó en subirla" — 4,5 → 4,75 */
export const RateHike: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const p = pop(f, 4, 14);
  const v = countUp(f, 10, 30, 4.75, 4.5);
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#10233A)" }} />
      <Kicker text="Minuta de octubre" color={C.blue} />
      <Big top={300} size={200} color={C.yellow}>
        {fmtCL(v, 2)}%
      </Big>
      <Sub top={540} at={12} color={C.white} size={52}>
        Los 5 consejeros evaluaron <b style={{ color: C.red }}>subir</b> la tasa
      </Sub>
      <div style={{ position: "absolute", top: 700, left: 0, right: 0, textAlign: "center", fontSize: 100, opacity: p }}>
        🤔🤔🤔🤔🤔
      </div>
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 8. Dollar near $1.000                                               */
/* ------------------------------------------------------------------ */

export const DollarMeter: React.FC<G & { iconsAt: number[] }> = ({ dur, iconsAt }) => {
  const f = useCurrentFrame();
  const v = countUp(f, 4, 34, 984, 900);
  const fill = (v - 800) / 200;
  const icons = ["📱", "🚗", "⛽"];
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#06210F,#0B1020)" }} />
      <Kicker text="Dólar" color={C.green} />
      <Big top={270} size={170} color={C.white}>
        ${fmtCL(Math.round(v))}
      </Big>
      <div style={{ position: "absolute", top: 480, left: 110, right: 110 }}>
        <div style={{ height: 44, background: "rgba(255,255,255,0.12)", borderRadius: 22, overflow: "hidden" }}>
          <div style={{ height: 44, width: `${fill * 100}%`, background: `linear-gradient(90deg, ${C.green}, ${C.yellow}, ${C.red})`, borderRadius: 22 }} />
        </div>
        <div style={{ display: "flex", justifyContent: "space-between", fontFamily: body, fontWeight: 700, fontSize: 34, color: C.muted, marginTop: 12 }}>
          <span>$800</span>
          <span style={{ color: C.red }}>$1.000</span>
        </div>
      </div>
      <div style={{ position: "absolute", top: 650, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 70 }}>
        {icons.map((ic, i) => {
          const s = pop(f, iconsAt[i] ?? 30 + i * 8, 12);
          return (
            <div key={ic} style={{ textAlign: "center", scale: String(s) }}>
              <div style={{ fontSize: 120 }}>{ic}</div>
              <div style={{ fontFamily: display, fontWeight: 900, fontSize: 44, color: C.red }}>▲ $$</div>
            </div>
          );
        })}
      </div>
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 9. Megarreforma + forecast                                          */
/* ------------------------------------------------------------------ */

export const TaxCut: React.FC<G> = ({ dur }) => {
  const f = useCurrentFrame();
  const v = countUp(f, 10, 40, 23, 27);
  const doc = pop(f, 0, 14);
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#162447)" }} />
      <Kicker text="Megarreforma · Ley 21.850" color={C.green} />
      <div style={{ position: "absolute", top: 270, left: 0, right: 0, textAlign: "center", fontSize: 150, scale: String(doc) }}>📜</div>
      <Sub top={460} at={6} color={C.white} size={48}>
        Impuesto a las empresas
      </Sub>
      <Big top={540} size={180} color={C.green} at={8}>
        {Math.round(v)}%
      </Big>
      <Sub top={760} at={30} size={44}>
        27% ➜ 23% de forma gradual · para que inviertan y contraten 🏗️
      </Sub>
    </Panel>
  );
};

export const Forecast: React.FC<G & { secondAt: number }> = ({ dur, secondAt }) => {
  const f = useCurrentFrame();
  const maxH = 440;
  const s = (v: number) => (v / 3.4) * maxH;
  const p1 = prog(f, 6, 26);
  const p2 = prog(f, secondAt, secondAt + 24);
  const Range: React.FC<{ x: number; lo: number; hi: number; p: number; label: string; color: string; text: string }> = ({
    x,
    lo,
    hi,
    p,
    label,
    color,
    text,
  }) => (
    <div style={{ position: "absolute", left: x, top: 260, width: 260, height: 600 }}>
      <div style={{ position: "absolute", bottom: 80, left: 0, right: 0, height: maxH }}>
        <div
          style={{
            position: "absolute",
            bottom: s(lo) * p,
            left: 0,
            right: 0,
            height: Math.max(14, (s(hi) - s(lo)) * p),
            background: color,
            borderRadius: 18,
            opacity: 0.95,
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: s(hi) * p + 18,
            left: -40,
            right: -40,
            textAlign: "center",
            fontFamily: display,
            fontWeight: 900,
            fontSize: 56,
            color,
            opacity: p,
          }}
        >
          {text}
        </div>
      </div>
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, textAlign: "center", fontFamily: display, fontWeight: 800, fontSize: 52 }}>
        {label}
      </div>
    </div>
  );
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#0F2A24)" }} />
      <Kicker text="Proyección Banco Central" color={C.green} />
      <div style={{ position: "absolute", left: 120, right: 120, top: 780, height: 4, background: C.line }} />
      <Range x={200} lo={0.25} hi={0.75} p={p1} label="2026" color={C.orange} text="0,25–0,75%" />
      <Range x={620} lo={2} hi={3} p={p2} label="2027" color={C.green} text="2–3% 🤞" />
    </Panel>
  );
};

/* ------------------------------------------------------------------ */
/* 10. Recap + CTA (full-screen cards)                                 */
/* ------------------------------------------------------------------ */

export const Recap: React.FC<G & { beats: number[] }> = ({ dur, beats }) => {
  const f = useCurrentFrame();
  const rows = [
    { e: "💸", t: "Precios", a: "▲", c: C.red },
    { e: "💼", t: "Empleo", a: "▼", c: C.red },
    { e: "⏸️", t: "Economía", a: "en pausa", c: C.yellow },
  ];
  return (
    <Panel dur={dur}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#0B1020,#1A1440)" }} />
      <Kicker text="En resumen" color={C.yellow} />
      {rows.map((r, i) => {
        const s = pop(f, beats[i] ?? i * 12, 12);
        return (
          <div
            key={r.t}
            style={{
              position: "absolute",
              top: 300 + i * 210,
              left: 110,
              right: 110,
              height: 170,
              borderRadius: 34,
              background: "rgba(255,255,255,0.07)",
              border: `2px solid ${C.line}`,
              display: "flex",
              alignItems: "center",
              padding: "0 44px",
              gap: 30,
              scale: String(0.7 + 0.3 * s),
              opacity: s,
            }}
          >
            <span style={{ fontSize: 90 }}>{r.e}</span>
            <span style={{ flex: 1, fontFamily: display, fontWeight: 900, fontSize: 68 }}>{r.t}</span>
            <span style={{ fontFamily: display, fontWeight: 900, fontSize: 66, color: r.c }}>{r.a}</span>
          </div>
        );
      })}
    </Panel>
  );
};

/* Floating emoji burst used on the CTA */
export const EmojiRain: React.FC<{ emoji: string[]; count?: number }> = ({ emoji, count = 18 }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {new Array(count).fill(0).map((_, i) => {
        const r0 = random(`x${i}`);
        const x = r0 < 0.5 ? 20 + r0 * 2 * 220 : 820 + (r0 - 0.5) * 2 * 200;
        const delay = random(`d${i}`) * 30;
        const speed = 10 + random(`s${i}`) * 10;
        const y = 1950 - (f - delay) * speed;
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              fontSize: 60 + random(`z${i}`) * 50,
              opacity: f < delay ? 0 : 0.9,
              rotate: `${Math.sin((f + i * 10) / 8) * 15}deg`,
            }}
          >
            {emoji[i % emoji.length]}
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

/* ------------------------------------------------------------------ */
/* Small "chip" stat used in full-screen talking-head moments          */
/* ------------------------------------------------------------------ */

export const Chip: React.FC<{ dur: number; emoji: string; text: string; color: string; top?: number }> = ({
  dur,
  emoji,
  text,
  color,
  top = 190,
}) => {
  const f = useCurrentFrame();
  const s = pop(f, 0, 12);
  return (
    <div
      style={{
        position: "absolute",
        top,
        left: 0,
        right: 0,
        display: "flex",
        justifyContent: "center",
        opacity: outro(f, dur, 6),
      }}
    >
      <div
        style={{
          scale: String(s),
          rotate: `${(1 - s) * -8}deg`,
          background: C.panel,
          border: `3px solid ${color}`,
          borderRadius: 999,
          padding: "18px 40px",
          display: "flex",
          alignItems: "center",
          gap: 18,
          fontFamily: display,
          fontWeight: 900,
          fontSize: 62,
          color: C.white,
          boxShadow: "0 10px 40px rgba(0,0,0,0.45)",
        }}
      >
        <span style={{ fontSize: 66 }}>{emoji}</span>
        <span>{text}</span>
      </div>
    </div>
  );
};
