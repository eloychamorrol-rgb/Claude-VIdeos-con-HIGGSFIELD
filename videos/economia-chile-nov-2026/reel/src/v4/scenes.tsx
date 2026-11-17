import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Icon } from "./icons";
import { C, F, STYLE } from "./theme";
import { Block, Card, Pill, Scribble, SeriesTag, Title, clamp, count, fmt, pop, prog } from "./ui";

type P = { dur: number };

/* ------------------------------------------------------------------ */
/* Santiago plano: cordillera + skyline con la Costanera               */
/* ------------------------------------------------------------------ */

const Santiago: React.FC = () => {
  const f = useCurrentFrame();
  const sw = STYLE.stroke;
  const towers = [
    { x: 40, w: 90, h: 120 },
    { x: 140, w: 70, h: 170 },
    { x: 220, w: 110, h: 140 },
    { x: 340, w: 80, h: 200 },
    { x: 520, w: 90, h: 150 },
    { x: 620, w: 120, h: 190 },
    { x: 750, w: 80, h: 130 },
    { x: 840, w: 100, h: 170 },
    { x: 950, w: 90, h: 120 },
  ];
  return (
    <svg width={1080} height={760} style={{ position: "absolute", left: 0, top: 0 }}>
      {/* cordillera */}
      <path d="M-20 600 L120 420 L210 500 L360 330 L470 450 L600 300 L720 440 L830 360 L960 470 L1100 400 L1100 760 L-20 760 Z" fill="#9FB3F2" stroke={C.ink} strokeWidth={sw} strokeLinejoin="round" />
      <path d="M318 378 L360 330 L404 382 L384 372 L362 390 L340 372 Z" fill={C.paper} stroke={C.ink} strokeWidth={3} strokeLinejoin="round" />
      <path d="M556 350 L600 300 L646 352 L624 342 L600 362 L578 342 Z" fill={C.paper} stroke={C.ink} strokeWidth={3} strokeLinejoin="round" />
      <path d="M796 398 L830 360 L866 400 L848 392 L830 408 L812 392 Z" fill={C.paper} stroke={C.ink} strokeWidth={3} strokeLinejoin="round" />
      {/* edificios */}
      {towers.map((t, i) => (
        <g key={i}>
          <rect x={t.x} y={680 - t.h} width={t.w} height={t.h + 10} fill={i % 2 ? "#2B2F3A" : C.ink} stroke={C.ink} strokeWidth={sw} />
          {new Array(Math.floor(t.h / 34)).fill(0).map((_, r) =>
            new Array(Math.floor((t.w - 16) / 24)).fill(0).map((__, q) => (
              <rect
                key={`${r}-${q}`}
                x={t.x + 12 + q * 24}
                y={680 - t.h + 14 + r * 34}
                width={12}
                height={16}
                fill={(i + r + q) % 3 === 0 ? "#3A3F4D" : C.yellow}
              />
            ))
          )}
        </g>
      ))}
      {/* Costanera Center */}
      <path d="M430 680 L446 250 L494 250 L510 680 Z" fill="#3B4A6B" stroke={C.ink} strokeWidth={sw} strokeLinejoin="round" />
      <path d="M446 250 L452 214 L488 214 L494 250" fill="#3B4A6B" stroke={C.ink} strokeWidth={sw} strokeLinejoin="round" />
      {new Array(12).fill(0).map((_, r) => (
        <line key={r} x1={448 + r * 0.6} y1={290 + r * 32} x2={492 - r * 0.6} y2={290 + r * 32} stroke="#7FA0D9" strokeWidth={3} />
      ))}
      <circle cx={470} cy={206} r={6} fill={C.red} opacity={0.5 + 0.5 * Math.abs(Math.sin(f / 6))} />
      {/* calle */}
      <rect x={-10} y={680} width={1100} height={90} fill="#3B3B42" stroke={C.ink} strokeWidth={sw} />
      {new Array(12).fill(0).map((_, d) => (
        <rect key={d} x={((d * 120 - f * 6) % 1440) - 120} y={716} width={66} height={12} fill={C.yellow} />
      ))}
    </svg>
  );
};

const Mini: React.FC<{ left?: number; right?: number; top: number; at: number; label: string; value: string; color: string; icon: React.ReactNode }> = ({
  left,
  right,
  top,
  at,
  label,
  value,
  color,
  icon,
}) => {
  const f = useCurrentFrame();
  const p = pop(f, at, 12);
  return (
    <div
      style={{
        position: "absolute",
        left,
        right,
        top,
        width: 450,
        background: C.paper,
        border: `${STYLE.stroke}px solid ${C.ink}`,
        borderRadius: 20,
        boxShadow: STYLE.shadow(8),
        padding: "18px 22px",
        display: "flex",
        alignItems: "center",
        gap: 18,
        scale: String(p),
        opacity: Math.min(1, p * 1.5),
      }}
    >
      {icon}
      <div>
        <div style={{ fontFamily: F.body, fontWeight: 700, fontSize: 24, color: C.muted, letterSpacing: 1 }}>{label}</div>
        <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 48, color, letterSpacing: -1, lineHeight: 1.05, whiteSpace: "nowrap" }}>{value}</div>
      </div>
    </div>
  );
};

export const SHook: React.FC<P & { secondAt: number }> = ({ secondAt }) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill style={{ background: "linear-gradient(180deg,#FCE9CF 0%,#F4F0E8 60%)" }}>
      <Santiago />
      <SeriesTag />
      <Block text="ECONOMÍA CHILENA HOY" top={170} size={60} bg={C.yellow} color={C.ink} rotate={-1.5} />
      <Mini left={40} top={330} at={8} label="COBRE" value="▲ US$6,35" color={C.green} icon={<Icon name="coin" size={74} color={C.copper} />} />
      <Mini
        right={40}
        top={460}
        at={secondAt}
        label="SIN TRABAJO"
        value={`▲ +${fmt(Math.round(count(f, secondAt, secondAt + 30, 1000000)))}`}
        color={C.red}
        icon={<Icon name="person" size={70} color={C.red} />}
      />
    </AbsoluteFill>
  );
};

export const SQuestion: React.FC<P & { a: string; b: string; icon?: Parameters<typeof Icon>[0]["name"]; bg?: string; color?: string }> = ({
  a,
  b,
  icon,
  bg = C.blue,
  color = C.paper,
}) => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill>
      <SeriesTag />
      {icon ? (
        <div style={{ position: "absolute", top: 180, left: 0, right: 0, display: "flex", justifyContent: "center", scale: String(pop(f, 0, 12)) }}>
          <Icon name={icon} size={130} color={C.yellow} />
        </div>
      ) : null}
      <Title text={a} top={icon ? 345 : 270} size={120} />
      <Block text={b} top={icon ? 470 : 410} at={5} size={104} bg={bg} color={color} />
    </AbsoluteFill>
  );
};

export const SFullQuestion: React.FC<P & { a: string; b: string }> = ({ a, b }) => {
  const f = useCurrentFrame();
  const people = [C.blue, C.red, C.yellow, C.green, C.copper];
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Title text={a} top={330} size={132} />
      <Block text={b} top={470} at={4} size={120} bg={C.yellow} color={C.ink} />
      <div
        style={{
          position: "absolute",
          left: 290,
          top: 720,
          width: 500,
          height: 500,
          borderRadius: 34,
          background: C.blue,
          border: `${STYLE.stroke + 2}px solid ${C.ink}`,
          boxShadow: STYLE.shadow(14),
          scale: String(pop(f, 6, 14)),
          rotate: `${interpolate(f, [6, 20], [-8, 3], clamp)}deg`,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: F.display,
          fontWeight: 800,
          fontSize: 380,
          color: C.paper,
          lineHeight: 1,
        }}
      >
        ?
      </div>
      <Scribble x={300} y={1290} w={480} at={16} />
      <div style={{ position: "absolute", top: 1400, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 60 }}>
        {people.map((c, i) => (
          <div key={i} style={{ translate: `0px ${Math.sin((f + i * 6) / 4) * 8}px`, scale: String(pop(f, 10 + i * 3, 10)) }}>
            <Icon name="person" size={110} color={c} />
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};

export const SUnemployment: React.FC<P> = () => {
  const f = useCurrentFrame();
  const v = count(f, 14, 40, 9.8);
  const p1 = prog(f, 6, 24);
  const p2 = prog(f, 14, 40);
  const H = 190;
  const bar = (val: number, p: number) => (val / 10) * H * p;
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="Desempleo" accent={C.red} right={<Pill text="jul–sep" bg={C.faint} size={24} />} source="INE">
        <div style={{ position: "absolute", left: 90, bottom: 66, display: "flex", gap: 90, alignItems: "flex-end" }}>
          {[
            { y: "2025", v: 8.5, p: p1, c: "#CFCAC0", t: "8,5%", tc: C.muted },
            { y: "2026", v: 9.8, p: p2, c: C.red, t: `${fmt(v, 1)}%`, tc: C.red },
          ].map((b) => (
            <div key={b.y} style={{ display: "flex", flexDirection: "column", alignItems: "center", width: 190 }}>
              <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 56, color: b.tc, marginBottom: 8, opacity: b.p, letterSpacing: -1 }}>{b.t}</div>
              <div style={{ width: 190, height: bar(b.v, b.p), background: b.c, border: `${STYLE.stroke}px solid ${C.ink}`, borderBottom: "none", borderRadius: "12px 12px 0 0" }} />
              <div style={{ width: 230, height: STYLE.stroke, background: C.ink }} />
              <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 30, color: C.muted, marginTop: 8 }}>{b.y}</div>
            </div>
          ))}
        </div>
        <div style={{ position: "absolute", right: 46, top: 190, scale: String(pop(f, 38, 12)), rotate: "4deg" }}>
          <Pill text="+1,3 pts ▲" bg={C.yellow} size={34} />
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SDollar: React.FC<P & { icons: number[] }> = ({ icons }) => {
  const f = useCurrentFrame();
  const v = count(f, 4, 30, 984, 930);
  const items: { n: Parameters<typeof Icon>[0]["name"]; t: string; c: string }[] = [
    { n: "phone", t: "CELULAR", c: C.blue },
    { n: "car", t: "AUTO", c: C.red },
    { n: "pump", t: "BENCINA", c: C.yellow },
  ];
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card
        title="Dólar"
        accent={C.green}
        right={<span style={{ fontFamily: F.display, fontWeight: 800, fontSize: 52, color: C.red, letterSpacing: -1 }}>▲ ${fmt(Math.round(v))}</span>}
        source="cierre 11 nov"
      >
        <div style={{ position: "absolute", top: 130, left: 40, right: 40 }}>
          <div style={{ position: "relative", height: 40, background: C.faint, border: `${STYLE.stroke}px solid ${C.ink}`, borderRadius: 20, overflow: "hidden" }}>
            <div style={{ height: "100%", width: `${((v - 800) / 200) * 100}%`, background: `linear-gradient(90deg, ${C.green}, ${C.yellow}, ${C.red})` }} />
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: F.display, fontWeight: 800, fontSize: 26, color: C.muted, marginTop: 8 }}>
            <span>$800</span>
            <span style={{ color: C.red }}>$1.000</span>
          </div>
        </div>
        <div style={{ position: "absolute", top: 250, left: 0, right: 0, display: "flex", justifyContent: "space-around", alignItems: "flex-end" }}>
          {items.map((it, i) => (
            <div key={it.t} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10, scale: String(pop(f, icons[i], 12)), opacity: f >= icons[i] ? 1 : 0 }}>
              <Icon name={it.n} size={110} color={it.c} />
              <span style={{ fontFamily: F.display, fontWeight: 800, fontSize: 28, color: C.red }}>{it.t} ▲</span>
            </div>
          ))}
        </div>
      </Card>
    </AbsoluteFill>
  );
};
