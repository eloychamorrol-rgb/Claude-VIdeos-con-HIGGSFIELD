import React from "react";
import { AbsoluteFill, interpolate, random, useCurrentFrame } from "remotion";
import {
  BigTitle,
  Card,
  DarkPill,
  K,
  LightPill,
  PX,
  Pixel,
  RedCircle,
  clamp,
  count,
  fmt,
  mono,
  pop,
  prog,
  sans,
} from "./ui";

type P = { dur: number };

/* ------------------------------------------------------------------ */
/* Shared bits                                                         */
/* ------------------------------------------------------------------ */

export const TopLabel: React.FC = () => (
  <div
    style={{
      position: "absolute",
      top: 112,
      left: 86,
      fontFamily: mono,
      fontWeight: 700,
      fontSize: 26,
      color: "#9C9A95",
      letterSpacing: 1,
    }}
  >
    ▣ economía chilena · nov 2026
  </div>
);

const Stamp: React.FC<{ text: string; at: number; top: number; color?: string; rotate?: number }> = ({
  text,
  at,
  top,
  color = K.red,
  rotate = -8,
}) => {
  const f = useCurrentFrame();
  const s = interpolate(f, [at, at + 6], [1.8, 1], { ...clamp });
  const o = interpolate(f, [at, at + 3], [0, 1], clamp);
  return (
    <div style={{ position: "absolute", top, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: o }}>
      <div
        style={{
          border: `7px solid ${color}`,
          color,
          fontFamily: mono,
          fontWeight: 800,
          fontSize: 58,
          padding: "6px 26px",
          borderRadius: 14,
          rotate: `${rotate}deg`,
          scale: String(s),
          background: "rgba(18,18,20,0.85)",
          letterSpacing: 2,
        }}
      >
        {text}
      </div>
    </div>
  );
};

/** Night pixel city with Andes, used for the hook and the central bank. */
const NightCity: React.FC<{ seed: string; children?: React.ReactNode }> = ({ seed, children }) => {
  const f = useCurrentFrame();
  const cols = 54;
  const cw = 20;
  const mountain = new Array(cols).fill(0).map((_, i) => {
    const x = i / cols;
    const h =
      120 +
      110 * Math.max(0, 1 - Math.abs(x - 0.25) * 4.5) +
      150 * Math.max(0, 1 - Math.abs(x - 0.62) * 3.6) +
      80 * Math.max(0, 1 - Math.abs(x - 0.9) * 6);
    return Math.round(h / cw) * cw;
  });
  const buildings: { x: number; w: number; h: number }[] = [];
  let x = -20;
  let i = 0;
  while (x < 1100) {
    const w = 80 + Math.floor(random(`${seed}w${i}`) * 4) * 20;
    const h = 140 + Math.floor(random(`${seed}h${i}`) * 9) * 20;
    buildings.push({ x, w, h });
    x += w + 10;
    i++;
  }
  return (
    <AbsoluteFill style={{ height: 760, overflow: "hidden" }}>
      <AbsoluteFill style={{ background: "linear-gradient(180deg,#141A33 0%,#272744 45%,#5C3C4C 78%,#8E5446 100%)", height: 650 }} />
      {new Array(40).fill(0).map((_, s) => (
        <div
          key={s}
          style={{
            position: "absolute",
            left: random(`${seed}sx${s}`) * 1080,
            top: 20 + random(`${seed}sy${s}`) * 330,
            width: 6,
            height: 6,
            background: "#FFF",
            opacity: 0.35 + 0.5 * Math.abs(Math.sin(f / 9 + s)),
          }}
        />
      ))}
      {mountain.map((h, c) => (
        <React.Fragment key={c}>
          <div style={{ position: "absolute", left: c * cw, width: cw, bottom: 110, height: h + 140, background: "#3A3D5C" }} />
          {h > 220 ? (
            <div style={{ position: "absolute", left: c * cw, width: cw, bottom: 110 + h + 100, height: 40, background: "#D9DCEB" }} />
          ) : null}
        </React.Fragment>
      ))}
      {buildings.map((b, j) => (
        <div key={j} style={{ position: "absolute", left: b.x, width: b.w, bottom: 110, height: b.h, background: j % 2 ? "#232846" : "#2C3260" }}>
          {new Array(Math.floor(b.h / 40)).fill(0).map((__, r) =>
            new Array(Math.floor((b.w - 20) / 26)).fill(0).map((___, q) => {
              const lit = random(`${seed}l${j}-${r}-${q}`) > 0.45;
              return (
                <div
                  key={`${r}-${q}`}
                  style={{
                    position: "absolute",
                    left: 14 + q * 26,
                    top: 16 + r * 40,
                    width: 14,
                    height: 18,
                    background: lit ? K.yellow : "#1A1D33",
                    opacity: lit ? 0.9 : 1,
                  }}
                />
              );
            })
          )}
        </div>
      ))}
      {/* road */}
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 110, background: "#3B3B42" }}>
        {new Array(12).fill(0).map((_, d) => (
          <div
            key={d}
            style={{
              position: "absolute",
              top: 50,
              left: ((d * 120 - f * 6) % 1440) - 120,
              width: 66,
              height: 12,
              background: K.yellow,
            }}
          />
        ))}
      </div>
      {children}
    </AbsoluteFill>
  );
};

const Marquee: React.FC<{ text: string; top: number }> = ({ text, top }) => {
  const f = useCurrentFrame();
  const p = pop(f, 0, 12);
  const blink = Math.floor(f / 8) % 2 === 0;
  return (
    <div style={{ position: "absolute", top, left: 0, right: 0, display: "flex", justifyContent: "center", scale: String(p) }}>
      <div
        style={{
          background: K.inner,
          border: `8px solid ${K.orange}`,
          outline: "6px solid #7A3B26",
          padding: "10px 34px",
          fontFamily: mono,
          fontWeight: 800,
          fontSize: 56,
          letterSpacing: 4,
          color: blink ? "#FF6B4A" : "#E8743B",
        }}
      >
        {text}
      </div>
    </div>
  );
};

const Win: React.FC<{ left?: number; right?: number; top: number; w: number; h: number; at?: number; children: React.ReactNode }> = ({
  left,
  right,
  top,
  w,
  h,
  at = 0,
  children,
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
        width: w,
        height: h,
        background: K.inner,
        borderRadius: 18,
        border: "3px solid #3A3A40",
        boxShadow: "0 16px 40px rgba(0,0,0,0.45)",
        scale: String(p),
        opacity: Math.min(1, p * 1.5),
        fontFamily: mono,
        color: K.white,
        overflow: "hidden",
      }}
    >
      <div style={{ position: "absolute", top: 16, left: 18, display: "flex", gap: 10 }}>
        {[K.red, K.yellow, K.green].map((c) => (
          <div key={c} style={{ width: 16, height: 16, borderRadius: 8, background: c }} />
        ))}
      </div>
      {children}
    </div>
  );
};

/** Animated polyline chart in a box. */
const Line: React.FC<{ pts: number[]; w: number; h: number; color: string; p: number; style?: React.CSSProperties }> = ({
  pts,
  w,
  h,
  color,
  p,
  style,
}) => {
  const max = Math.max(...pts);
  const min = Math.min(...pts);
  const d = pts
    .map((v, i) => `${(i / (pts.length - 1)) * w},${h - ((v - min) / (max - min || 1)) * h}`)
    .join(" ");
  const len = w * 1.6;
  return (
    <svg width={w} height={h + 10} style={{ overflow: "visible", ...style }}>
      <polyline
        points={d}
        fill="none"
        stroke={color}
        strokeWidth={6}
        strokeLinejoin="round"
        strokeDasharray={len}
        strokeDashoffset={len * (1 - p)}
      />
    </svg>
  );
};

/* ------------------------------------------------------------------ */
/* Scenes                                                              */
/* ------------------------------------------------------------------ */

export const SHook: React.FC<P & { secondAt: number }> = ({ secondAt }) => {
  const f = useCurrentFrame();
  return (
    <NightCity seed="hook">
      <Marquee text="ECONOMÍA CHILENA HOY" top={175} />
      <Win left={36} top={330} w={470} h={260} at={6}>
        <div style={{ position: "absolute", top: 54, left: 22, fontSize: 30, fontWeight: 700 }}>
          <span style={{ color: K.orange }}>❯</span> cobre --precio
        </div>
        <div style={{ position: "absolute", top: 100, left: 22, fontSize: 52, fontWeight: 800, color: K.green }}>
          ▲ US$6,35<span style={{ fontSize: 26, color: K.grey }}>/lb</span>
        </div>
        <Line pts={[2, 3, 2.6, 4, 3.6, 5, 4.8, 6]} w={420} h={70} color={K.green} p={prog(f, 10, 40)} style={{ position: "absolute", left: 22, top: 170 }} />
      </Win>
      <Win right={36} top={330} w={470} h={260} at={secondAt}>
        <div style={{ position: "absolute", top: 54, left: 22, fontSize: 30, fontWeight: 700 }}>
          <span style={{ color: K.orange }}>❯</span> sin trabajo
        </div>
        <div style={{ position: "absolute", top: 100, left: 22, fontSize: 52, fontWeight: 800, color: K.red }}>
          ▲ +{fmt(Math.round(count(f, secondAt, secondAt + 30, 1000000)))}
        </div>
        <Line pts={[2, 2.2, 2.1, 2.8, 3.2, 3.1, 3.9, 4.4]} w={420} h={70} color={K.red} p={prog(f, secondAt + 4, secondAt + 34)} style={{ position: "absolute", left: 22, top: 170 }} />
      </Win>
    </NightCity>
  );
};

export const SQuestion: React.FC<P & { a: string; b: string; full?: boolean; pixel?: string[] }> = ({ a, b, full, pixel }) => {
  const f = useCurrentFrame();
  if (!full) {
    return (
      <AbsoluteFill>
        <TopLabel />
        {pixel ? (
          <div style={{ position: "absolute", top: 180, left: 0, right: 0, display: "flex", justifyContent: "center", scale: String(pop(f, 0, 12)) }}>
            <Pixel grid={pixel} size={14} />
          </div>
        ) : null}
        <BigTitle text={a} top={pixel ? 345 : 270} size={110} />
        <DarkPill text={b} top={pixel ? 490 : 420} at={5} />
      </AbsoluteFill>
    );
  }
  const people = [K.orange, K.blue, "#7C5CE0", K.yellow, K.green];
  return (
    <AbsoluteFill>
      <TopLabel />
      <BigTitle text={a} top={330} size={130} />
      <DarkPill text={b} top={490} at={4} size={80} />
      <div
        style={{
          position: "absolute",
          left: 290,
          top: 700,
          width: 500,
          height: 500,
          borderRadius: 30,
          border: "10px solid #FFF",
          background: `repeating-linear-gradient(135deg, ${K.orange} 0 26px, #D9662F 26px 52px)`,
          boxShadow: "0 20px 50px rgba(232,116,59,0.35)",
          scale: String(pop(f, 6, 14)),
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontFamily: sans,
          fontWeight: 800,
          fontSize: 340,
          color: "#FFF",
        }}
      >
        ?
      </div>
      <RedCircle cx={540} cy={950} rx={340} ry={330} at={14} />
      <div style={{ position: "absolute", top: 1430, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 70 }}>
        {people.map((c, i) => (
          <div key={i} style={{ translate: `0px ${Math.sin((f + i * 6) / 4) * 8}px` }}>
            <Pixel grid={PX.person} size={16} palette={{ k: c }} />
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
  const H = 165;
  const bar = (val: number, p: number) => (val / 10) * H * p;
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Desempleo" slug="/ine" right={<span style={{ fontFamily: mono, fontSize: 26, color: K.grey }}>jul–sep</span>} tag="FUENTE: INE">
        <div style={{ position: "absolute", left: 80, bottom: 70, display: "flex", gap: 90, alignItems: "flex-end" }}>
          {[
            { y: "2025", v: 8.5, p: p1, c: "#6A6A74", t: "8,5%" },
            { y: "2026", v: 9.8, p: p2, c: K.red, t: `${fmt(v, 1)}%` },
          ].map((b) => (
            <div key={b.y} style={{ display: "flex", flexDirection: "column", alignItems: "center", width: 200 }}>
              <div style={{ fontFamily: mono, fontWeight: 800, fontSize: 48, color: b.c === K.red ? K.red : "#CFCFD6", marginBottom: 10, opacity: b.p }}>{b.t}</div>
              <div style={{ width: 200, height: bar(b.v, b.p), background: b.c, borderRadius: "10px 10px 0 0" }} />
              <div style={{ fontFamily: mono, fontWeight: 700, fontSize: 28, color: K.grey, marginTop: 10 }}>{b.y}</div>
            </div>
          ))}
        </div>
        <div style={{ position: "absolute", right: 50, top: 170, scale: String(pop(f, 38, 12)) }}>
          <LightPill text="+1,3 pts ▲" bg={K.red} color="#FFF" size={30} />
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SMillion: React.FC<P> = () => {
  const f = useCurrentFrame();
  const n = count(f, 4, 46, 1007976);
  const cols = 15;
  const rows = 3;
  const total = cols * rows;
  const lit = Math.floor(interpolate(f, [4, 46], [0, total], clamp));
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Sin trabajo" slug="/ine" tag="PERSONAS">
        <div style={{ position: "absolute", top: 92, left: 0, right: 0, textAlign: "center", fontFamily: mono, fontWeight: 800, fontSize: 104, color: K.white }}>
          {fmt(Math.round(n))}
        </div>
        <div style={{ position: "absolute", top: 230, left: 40, right: 40, display: "grid", gridTemplateColumns: `repeat(${cols}, 1fr)`, rowGap: 14, justifyItems: "center" }}>
          {new Array(total).fill(0).map((_, i) => (
            <Pixel key={i} grid={PX.person} size={6} palette={{ k: i < lit ? K.orange : "#33333A" }} />
          ))}
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SCompare: React.FC<P> = () => {
  const f = useCurrentFrame();
  const Block: React.FC<{ name: string; at: number; color: string }> = ({ name, at, color }) => (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14, scale: String(pop(f, at, 12)) }}>
      <div style={{ display: "flex", alignItems: "flex-end", gap: 6 }}>
        {[90, 140, 110, 160, 80].map((h, i) => (
          <div key={i} style={{ width: 34, height: h, background: color, opacity: 0.6 + (i % 2) * 0.4 }} />
        ))}
      </div>
      <LightPill text={name} size={30} />
    </div>
  );
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Para dimensionar" slug="/comunas">
        <div style={{ position: "absolute", top: 110, left: 0, right: 0, display: "flex", justifyContent: "center", alignItems: "center", gap: 60 }}>
          <Block name="PUENTE ALTO" at={2} color={K.blue} />
          <div style={{ fontFamily: mono, fontWeight: 800, fontSize: 80, color: K.white, opacity: prog(f, 10, 16) }}>+</div>
          <Block name="MAIPÚ" at={12} color={K.green} />
        </div>
        <div style={{ position: "absolute", top: 370, left: 0, right: 0, textAlign: "center", fontFamily: mono, fontWeight: 800, fontSize: 46, color: K.orangeHi, opacity: prog(f, 26, 36) }}>
          ≈ 1 MILLÓN DE PERSONAS
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SRecord: React.FC<P> = () => (
  <AbsoluteFill>
    <TopLabel />
    <BigTitle text="LA MÁS ALTA" top={250} size={112} />
    <DarkPill text="DESDE 2021" top={420} at={8} size={76} />
    <RedCircle cx={540} cy={466} rx={260} ry={95} at={18} />
  </AbsoluteFill>
);

export const SAllUp: React.FC<P> = () => {
  const f = useCurrentFrame();
  return (
    <AbsoluteFill>
      <TopLabel />
      <BigTitle text="TODO SUBE" top={230} size={120} color={K.red} />
      <div style={{ position: "absolute", top: 420, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 70 }}>
        {[0, 1, 2, 3, 4].map((i) => (
          <div key={i} style={{ translate: `0px ${-Math.abs(Math.sin((f + i * 5) / 5)) * 40}px`, opacity: prog(f, i * 3, i * 3 + 8) }}>
            <Pixel grid={PX.arrowUp} size={16} />
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};

export const SInflation: React.FC<P> = () => {
  const f = useCurrentFrame();
  const v = count(f, 8, 36, 4.5);
  const W = 780;
  const x = (val: number) => (val / 6) * W;
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card
        title="Inflación"
        slug="/ipc-octubre"
        right={<span style={{ fontFamily: mono, fontWeight: 800, fontSize: 44, color: K.orange }}>{fmt(v, 1)}%</span>}
        tag="FUENTE: INE"
      >
        <div style={{ position: "absolute", top: 150, left: 50, width: W }}>
          <div style={{ fontFamily: mono, fontWeight: 700, fontSize: 26, color: K.grey, marginBottom: 14 }}>últimos 12 meses</div>
          <div style={{ position: "relative", height: 70, background: "#26262C", borderRadius: 12 }}>
            <div style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: x(v), background: `linear-gradient(90deg, ${K.orange}, ${K.red})`, borderRadius: 12 }} />
            <div style={{ position: "absolute", left: x(3), top: -14, bottom: -14, width: 0, borderLeft: `5px dashed ${K.green}`, opacity: prog(f, 30, 38) }} />
          </div>
          <div style={{ position: "relative", height: 90 }}>
            <div style={{ position: "absolute", left: x(3) - 110, top: 24, width: 220, textAlign: "center", fontFamily: mono, fontWeight: 800, fontSize: 30, color: K.green, opacity: prog(f, 30, 38) }}>
              META: 3%
            </div>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: mono, fontSize: 22, color: K.grey }}>
            <span>0%</span>
            <span>6%</span>
          </div>
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SLunch: React.FC<P & { secondAt: number }> = ({ secondAt }) => {
  const f = useCurrentFrame();
  const v = count(f, secondAt, secondAt + 26, 5225, 5000);
  const strike = prog(f, secondAt - 4, secondAt + 4);
  const row = (label: string, value: React.ReactNode, color = K.white) => (
    <div style={{ display: "flex", alignItems: "baseline", fontFamily: mono, fontWeight: 700, fontSize: 38, color, gap: 10 }}>
      <span>{label}</span>
      <span style={{ flex: 1, borderBottom: "4px dotted #4A4A52", translate: "0px -10px" }} />
      <span style={{ fontWeight: 800 }}>{value}</span>
    </div>
  );
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Tu almuerzo" slug="/ipc" tag="EJEMPLO">
        <div style={{ position: "absolute", top: 120, left: 50, right: 50, display: "flex", flexDirection: "column", gap: 34 }}>
          <div style={{ position: "relative", opacity: 1 - strike * 0.5 }}>
            {row("ALMUERZO · 2025", "$5.000")}
            <div style={{ position: "absolute", left: 0, top: "50%", height: 6, width: `${strike * 100}%`, background: K.red }} />
          </div>
          <div style={{ opacity: prog(f, secondAt - 2, secondAt + 6) }}>{row("ALMUERZO · HOY", `$${fmt(Math.round(v))}`, K.orangeHi)}</div>
          <div style={{ display: "flex", justifyContent: "center", scale: String(pop(f, secondAt + 28, 12)) }}>
            <LightPill text="+$225 · +4,5%" bg={K.red} color="#FFF" size={34} />
          </div>
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SWhatRose: React.FC<P> = () => {
  const f = useCurrentFrame();
  const cart = ["k.........", ".kooooooo.", ".kooooooo.", "..ooooooo.", "..kkkkkkk.", "...k...k..", "...k...k.."];
  const rows = [
    { icon: <Pixel grid={PX.pump} size={6} />, t: "Transporte", v: 2.0, c: K.red },
    { icon: <Pixel grid={cart} size={8} palette={{ k: "#CFCFD6" }} />, t: "Alimentos", v: 1.0, c: K.orange },
  ];
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Lo que más subió" slug="/octubre" tag="FUENTE: INE">
        {rows.map((r, i) => {
          const p = prog(f, 4 + i * 8, 26 + i * 8);
          return (
            <div key={r.t} style={{ position: "absolute", top: 120 + i * 140, left: 50, right: 50 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 20, fontFamily: sans, fontWeight: 700, fontSize: 38 }}>
                <div style={{ width: 70, display: "flex", justifyContent: "center" }}>{r.icon}</div>
                <span style={{ flex: 1 }}>{r.t}</span>
                <span style={{ fontFamily: mono, fontWeight: 800, fontSize: 46, color: r.c }}>+{fmt(r.v * p, 1)}%</span>
              </div>
              <div style={{ height: 22, background: "#26262C", borderRadius: 11, marginTop: 14 }}>
                <div style={{ height: 22, width: `${(r.v / 2.2) * 100 * p}%`, background: r.c, borderRadius: 11 }} />
              </div>
            </div>
          );
        })}
      </Card>
    </AbsoluteFill>
  );
};

export const SGrowth: React.FC<P & { stampAt: number }> = ({ stampAt }) => {
  const f = useCurrentFrame();
  const v = interpolate(f, [6, 20, 32], [0, 1.4, 0.2], clamp);
  const W = 780;
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card
        title="Crecimiento"
        slug="/imacec-sep"
        right={<span style={{ fontFamily: mono, fontWeight: 800, fontSize: 44, color: K.yellow }}>+{fmt(Math.max(0, v), 1)}%</span>}
        tag="FUENTE: BANCO CENTRAL"
      >
        <div style={{ position: "absolute", top: 170, left: 50, width: W }}>
          <div style={{ position: "relative", height: 60, borderRadius: 30, background: `linear-gradient(90deg, ${K.red}, ${K.yellow} 45%, ${K.green})` }}>
            <div
              style={{
                position: "absolute",
                left: (Math.max(0, v) / 5) * W - 14,
                top: -26,
                width: 28,
                height: 112,
                background: "#FFF",
                borderRadius: 6,
                boxShadow: "0 0 0 5px #121214",
              }}
            />
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: mono, fontWeight: 700, fontSize: 26, color: K.grey, marginTop: 30 }}>
            <span>0%</span>
            <span>anual</span>
            <span>5%</span>
          </div>
        </div>
        <Stamp text="PRÁCTICAMENTE NADA" at={stampAt} top={300} />
      </Card>
    </AbsoluteFill>
  );
};

export const SCopper: React.FC<P & { secondAt: number }> = ({ secondAt }) => {
  const f = useCurrentFrame();
  const prod = count(f, secondAt + 2, secondAt + 24, -12.1);
  const Col: React.FC<{ at: number; label: string; big: string; color: string; children: React.ReactNode }> = ({ at, label, big, color, children }) => (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 16, opacity: prog(f, at, at + 8), scale: String(0.85 + 0.15 * pop(f, at, 12)) }}>
      <span style={{ fontFamily: mono, fontWeight: 800, fontSize: 28, color: K.grey, letterSpacing: 2 }}>{label}</span>
      <div style={{ height: 110, display: "flex", alignItems: "center" }}>{children}</div>
      <span style={{ fontFamily: mono, fontWeight: 800, fontSize: 56, color }}>{big}</span>
    </div>
  );
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Cobre" slug="/mercado" tag="SEPTIEMBRE">
        <div style={{ position: "absolute", top: 110, left: 30, right: 30, display: "flex" }}>
          <Col at={2} label="PRECIO" big="▲ US$6,35" color={K.green}>
            <Pixel grid={PX.coin} size={12} />
          </Col>
          <div style={{ width: 3, background: "#2A2A30", margin: "10px 0" }} />
          <Col at={secondAt} label="PRODUCCIÓN" big={`▼ ${fmt(prod, 1)}%`} color={K.red}>
            <Pixel grid={PX.factory} size={7} />
          </Col>
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SAnalogy: React.FC<P & { secondAt: number }> = ({ secondAt }) => {
  const f = useCurrentFrame();
  const smoke = (i: number) => ((f + i * 10) % 30) / 30;
  return (
    <AbsoluteFill>
      <TopLabel />
      <div style={{ position: "absolute", top: 220, left: 0, right: 0, display: "flex", justifyContent: "space-around", alignItems: "flex-end" }}>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 24, scale: String(pop(f, 0, 12)) }}>
          <Pixel grid={PX.tag} size={18} />
          <LightPill text="MEJOR PRECIO ✓" bg={K.green} color="#FFF" size={30} />
        </div>
        <div style={{ position: "relative", display: "flex", flexDirection: "column", alignItems: "center", gap: 24, scale: String(pop(f, secondAt, 12)) }}>
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                left: 30 + i * 30,
                top: -30 - smoke(i) * 110,
                width: 34 - smoke(i) * 10,
                height: 34 - smoke(i) * 10,
                background: "#7A7A80",
                opacity: 1 - smoke(i),
              }}
            />
          ))}
          <div style={{ rotate: `${Math.sin(f / 2) * 2}deg` }}>
            <Pixel grid={PX.factory} size={18} />
          </div>
          <LightPill text="FÁBRICA EN PANA ✗" bg={K.red} color="#FFF" size={30} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

const Bank: React.FC = () => {
  const f = useCurrentFrame();
  const p = pop(f, 0, 14);
  return (
    <div style={{ position: "absolute", left: 190, bottom: 110, width: 700, height: 470, scale: String(0.9 + 0.1 * p) }}>
      {/* stepped pediment */}
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <div key={i} style={{ position: "absolute", bottom: 330 + i * 20, left: 20 + i * 54, right: 20 + i * 54, height: 20, background: "#E8E2D6" }} />
      ))}
      <div style={{ position: "absolute", bottom: 300, left: 0, right: 0, height: 34, background: "#D9D2C4" }} />
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <div key={i} style={{ position: "absolute", bottom: 40, left: 50 + i * 112, width: 44, height: 260, background: "#E8E2D6" }} />
      ))}
      <div style={{ position: "absolute", bottom: 40, left: 0, right: 0, height: 260, background: "#4A4658", zIndex: -1 }} />
      <div style={{ position: "absolute", bottom: 0, left: -30, right: -30, height: 40, background: "#D9D2C4" }} />
    </div>
  );
};

export const SBank: React.FC<P> = () => (
  <NightCity seed="bank">
    <Bank />
    <Marquee text="BANCO CENTRAL" top={200} />
  </NightCity>
);

export const SDilemma: React.FC<P & { b1: number; b2: number; b3: number }> = ({ b1, b2, b3 }) => {
  const f = useCurrentFrame();
  const press = (at: number) => interpolate(f, [at, at + 4, at + 9], [1, 0.88, 1], clamp);
  const yes = f >= b1 && f < b2;
  const no = f >= b2 && f < b3;
  const locked = f >= b3;
  const Btn: React.FC<{ t: string; active: boolean; at: number; primary?: boolean }> = ({ t, active, at, primary }) => (
    <div
      style={{
        width: 190,
        padding: "16px 0",
        textAlign: "center",
        borderRadius: 14,
        fontFamily: sans,
        fontWeight: 700,
        fontSize: 40,
        background: primary ? K.orange : "#ECECEC",
        color: primary ? "#FFF" : K.ink,
        outline: active ? `6px solid ${K.yellow}` : "none",
        scale: String(press(at)),
      }}
    >
      {t}
    </div>
  );
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Tasa de interés" slug="/bcch" right={<span style={{ fontFamily: mono, fontWeight: 800, fontSize: 40, color: K.orange }}>4,5%</span>} tag="FUENTE: BANCO CENTRAL">
        {!locked ? (
          <div
            style={{
              position: "absolute",
              top: 110,
              left: 150,
              right: 150,
              background: "#FFF",
              borderRadius: 22,
              padding: "26px 30px",
              color: K.ink,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 20,
              boxShadow: "0 18px 40px rgba(0,0,0,0.45)",
              scale: String(pop(f, 0, 12)),
            }}
          >
            <div style={{ fontFamily: sans, fontWeight: 700, fontSize: 44 }}>¿Bajar la tasa?</div>
            <div style={{ display: "flex", gap: 24 }}>
              <Btn t="No" active={no} at={b2} />
              <Btn t="Sí" active={yes} at={b1} primary />
            </div>
          </div>
        ) : (
          <div style={{ position: "absolute", top: 110, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 18, scale: String(pop(f, b3, 12)) }}>
            <Pixel grid={PX.lock} size={14} />
            <div style={{ fontFamily: mono, fontWeight: 800, fontSize: 52, color: K.white }}>SE MANTIENE EN 4,5%</div>
          </div>
        )}
        <div style={{ position: "absolute", top: 312, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
          {yes ? (
            <div style={{ scale: String(pop(f, b1 + 4, 10)) }}>
              <LightPill text="▲ LOS PRECIOS SUBEN MÁS" bg={K.red} color="#FFF" size={32} />
            </div>
          ) : no ? (
            <div style={{ scale: String(pop(f, b2 + 4, 10)) }}>
              <LightPill text="▲ CRÉDITOS SIGUEN CAROS" bg={K.red} color="#FFF" size={32} />
            </div>
          ) : null}
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SHike: React.FC<P> = () => {
  const f = useCurrentFrame();
  const v = count(f, 8, 26, 4.75, 4.5);
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Minuta de octubre" slug="/rpm" tag="EVALUADO · NO APLICADO">
        <div style={{ position: "absolute", top: 110, left: 0, right: 0, textAlign: "center", fontFamily: mono, fontWeight: 800, fontSize: 120, color: K.yellow }}>
          {fmt(v, 2)}%
        </div>
        <div style={{ position: "absolute", top: 280, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 18 }}>
          {[0, 1, 2, 3, 4].map((i) => (
            <div key={i} style={{ scale: String(pop(f, 14 + i * 3, 10)) }}>
              <Pixel grid={PX.person} size={9} palette={{ k: K.orange }} />
            </div>
          ))}
        </div>
        <div style={{ position: "absolute", top: 380, left: 0, right: 0, textAlign: "center", fontFamily: sans, fontWeight: 600, fontSize: 30, color: "#CFCFD6", opacity: prog(f, 22, 30) }}>
          los 5 consejeros evaluaron subirla
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SDollar: React.FC<P & { icons: number[] }> = ({ icons }) => {
  const f = useCurrentFrame();
  const v = count(f, 4, 30, 984, 930);
  const items = [
    { g: PX.phone, s: 9, t: "CELULAR" },
    { g: PX.car, s: 7, t: "AUTO" },
    { g: PX.pump, s: 8, t: "BENCINA" },
  ];
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Dólar" slug="/usd-clp" right={<span style={{ fontFamily: mono, fontWeight: 800, fontSize: 40, color: K.red }}>▲ ${fmt(Math.round(v))}</span>} tag="11 NOV">
        <div style={{ position: "absolute", top: 110, left: 50, right: 50 }}>
          <div style={{ position: "relative", height: 34, background: "#26262C", borderRadius: 17 }}>
            <div style={{ height: 34, width: `${((v - 800) / 200) * 100}%`, background: `linear-gradient(90deg, ${K.green}, ${K.yellow}, ${K.red})`, borderRadius: 17 }} />
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: mono, fontWeight: 700, fontSize: 24, color: K.grey, marginTop: 10 }}>
            <span>$800</span>
            <span style={{ color: K.red }}>$1.000</span>
          </div>
        </div>
        <div style={{ position: "absolute", top: 240, left: 0, right: 0, display: "flex", justifyContent: "space-around", alignItems: "flex-end" }}>
          {items.map((it, i) => (
            <div key={it.t} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10, scale: String(pop(f, icons[i], 12)), opacity: f >= icons[i] ? 1 : 0 }}>
              <Pixel grid={it.g} size={it.s} />
              <span style={{ fontFamily: mono, fontWeight: 800, fontSize: 26, color: K.red }}>{it.t} ▲</span>
            </div>
          ))}
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const STerminal: React.FC<P & { secondAt: number }> = ({ secondAt }) => {
  const f = useCurrentFrame();
  const cmd = "aprobar --megarreforma";
  const typed = cmd.slice(0, Math.floor(interpolate(f, [2, 22], [0, cmd.length], clamp)));
  const lines = [
    { at: 26, t: "✓ Ley 21.850 publicada · 17 oct", c: K.green },
    { at: 38, t: "impuesto a empresas: 27% → 23%", c: K.white },
    { at: secondAt, t: "objetivo: + inversión + empleo", c: K.orangeHi },
  ];
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Megarreforma" slug="/ley-21850" tag="GRADUAL">
        <div style={{ position: "absolute", top: 120, left: 44, right: 44, fontFamily: mono, fontWeight: 700, fontSize: 36, color: K.white }}>
          <div>
            <span style={{ color: K.orange }}>❯ </span>
            {typed}
            <span style={{ color: K.orange, opacity: Math.floor(f / 8) % 2 ? 1 : 0 }}>▌</span>
          </div>
          {lines.map((l) => (
            <div key={l.t} style={{ marginTop: 26, color: l.c, opacity: prog(f, l.at, l.at + 6), translate: `${(1 - prog(f, l.at, l.at + 6)) * -20}px 0px` }}>
              {l.t}
            </div>
          ))}
        </div>
      </Card>
    </AbsoluteFill>
  );
};

export const SForecast: React.FC<P & { secondAt: number; stampAt: number }> = ({ secondAt, stampAt }) => {
  const f = useCurrentFrame();
  const H = 230;
  const y = (v: number) => (v / 3.2) * H;
  const Range: React.FC<{ lo: number; hi: number; p: number; label: string; text: string; color: string }> = ({ lo, hi, p, label, text, color }) => (
    <div style={{ width: 240, height: H + 90, position: "relative", opacity: Math.min(1, p * 2) }}>
      <div style={{ position: "absolute", bottom: 50 + y(lo) * p, left: 0, right: 0, height: Math.max(16, (y(hi) - y(lo)) * p), background: color, borderRadius: 10 }} />
      <div style={{ position: "absolute", bottom: 60 + y(hi) * p + 10, left: -40, right: -40, textAlign: "center", fontFamily: mono, fontWeight: 800, fontSize: 40, color }}>{text}</div>
      <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, textAlign: "center", fontFamily: mono, fontWeight: 800, fontSize: 30, color: K.grey }}>{label}</div>
    </div>
  );
  return (
    <AbsoluteFill>
      <TopLabel />
      <Card title="Proyección del PIB" slug="/ipom-sep" tag="FUENTE: BANCO CENTRAL">
        <div style={{ position: "absolute", top: 90, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 160 }}>
          <Range lo={0.25} hi={0.75} p={prog(f, 4, 24)} label="2026" text="0,25–0,75%" color={K.orange} />
          <Range lo={2} hi={3} p={prog(f, secondAt, secondAt + 22)} label="2027" text="2–3%" color={K.green} />
        </div>
        <Stamp text="HAY QUE VERLO" at={stampAt} top={300} color={K.yellow} rotate={-4} />
      </Card>
    </AbsoluteFill>
  );
};

export const SRecap: React.FC<P & { beats: number[] }> = ({ beats }) => {
  const f = useCurrentFrame();
  const pause = ["yy..yy", "yy..yy", "yy..yy", "yy..yy", "yy..yy", "yy..yy"];
  const tiles = [
    { g: PX.arrowUp, t: "PRECIOS", s: "ARRIBA", c: K.red },
    { g: ["...rr...", "...rr...", "...rr...", "...rr...", "rrrrrrrr", ".rrrrrr.", "..rrrr..", "...rr..."], t: "EMPLEO", s: "ABAJO", c: K.red },
    { g: pause, t: "ECONOMÍA", s: "EN PAUSA", c: K.yellow },
  ];
  return (
    <AbsoluteFill>
      <TopLabel />
      <BigTitle text="EN RESUMEN" top={330} size={120} />
      <div style={{ position: "absolute", top: 600, left: 60, right: 60, display: "flex", flexDirection: "column", gap: 40 }}>
        {tiles.map((t, i) => {
          const s = pop(f, beats[i], 12);
          return (
            <div
              key={t.t}
              style={{
                height: 220,
                borderRadius: 30,
                background: "#F8F6F2",
                boxShadow: "0 12px 30px rgba(0,0,0,0.08)",
                display: "flex",
                alignItems: "center",
                padding: "0 60px",
                gap: 50,
                scale: String(0.8 + 0.2 * s),
                opacity: s,
              }}
            >
              <Pixel grid={t.g} size={14} />
              <div style={{ flex: 1, fontFamily: mono, fontWeight: 800, fontSize: 64, color: "#3A3A40" }}>{t.t}</div>
              <div style={{ fontFamily: mono, fontWeight: 800, fontSize: 48, color: t.c }}>{t.s}</div>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

export const SCta: React.FC<P> = () => {
  const f = useCurrentFrame();
  const done = f > 50;
  const press = interpolate(f, [44, 48, 54], [1, 0.9, 1], clamp);
  return (
    <AbsoluteFill>
      <TopLabel />
      <div style={{ position: "absolute", top: 200, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 30 }}>
        <div style={{ scale: String(pop(f, 0, 12)) }}>
          <Pixel grid={PX.wallet} size={14} />
        </div>
        <div
          style={{
            scale: String(pop(f, 6, 12) * press),
            background: done ? "#ECECEC" : K.orange,
            color: done ? K.ink : "#FFF",
            fontFamily: mono,
            fontWeight: 800,
            fontSize: 54,
            padding: "16px 60px",
            borderRadius: 16,
            boxShadow: "0 12px 30px rgba(232,116,59,0.35)",
          }}
        >
          {done ? "✓ SIGUIENDO" : "+ SEGUIR"}
        </div>
        <div style={{ fontFamily: mono, fontWeight: 700, fontSize: 30, color: "#5A5A60", opacity: prog(f, 14, 22) }}>
          💬 cuéntame en los comentarios
        </div>
        <div style={{ fontFamily: mono, fontWeight: 700, fontSize: 22, color: "#9C9A95", opacity: prog(f, 20, 28) }}>
          fuentes: INE · Banco Central de Chile
        </div>
      </div>
    </AbsoluteFill>
  );
};
