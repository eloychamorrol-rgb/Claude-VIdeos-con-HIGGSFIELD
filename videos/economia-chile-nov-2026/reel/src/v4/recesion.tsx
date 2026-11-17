import React from "react";
import { AbsoluteFill, interpolate } from "remotion";
import { Icon, IconName } from "./icons";
import { C, F, STYLE } from "./theme";
import { Block, Card, Pill, Scribble, SeriesTag, Stamp, Title, clamp, count, fmt, pop, prog, useF } from "./ui";

/* Escenas del video "Recesión y estanflación". Todos los tiempos (beats) son
   cuadros relativos al inicio de la escena. */

type P = { dur: number };

const Row: React.FC<{ at: number; icon: IconName; color: string; label: string; value: React.ReactNode; valueColor?: string; top: number }> = ({
  at,
  icon,
  color,
  label,
  value,
  valueColor = C.ink,
  top,
}) => {
  const f = useF();
  const p = pop(f, at, 12);
  return (
    <div
      style={{
        position: "absolute",
        top,
        left: 36,
        right: 36,
        height: 96,
        display: "flex",
        alignItems: "center",
        gap: 22,
        opacity: Math.min(1, p * 1.6),
        translate: `${(1 - p) * -40}px 0px`,
      }}
    >
      <Icon name={icon} size={76} color={color} />
      <span style={{ flex: 1, fontFamily: F.display, fontWeight: 800, fontSize: 44, letterSpacing: -0.5 }}>{label}</span>
      <span style={{ fontFamily: F.display, fontWeight: 800, fontSize: 52, color: valueColor, letterSpacing: -1 }}>{value}</span>
    </div>
  );
};

/* 1 · Gancho: "Chile en recesión técnica" */
export const SHookRecession: React.FC<P> = () => (
  <AbsoluteFill>
    <SeriesTag />
    <Title text="CHILE ESTÁ EN" top={250} size={96} />
    <Block text="RECESIÓN TÉCNICA" top={380} at={6} size={96} bg={C.red} />
    <div style={{ position: "absolute", top: 560, left: 0, right: 0, display: "flex", justifyContent: "center" }}>
      <div style={{ scale: String(pop(useF(), 16, 12)) }}>
        <Pill text="lo reconoció el ministro de Hacienda" bg={C.paper} size={30} />
      </div>
    </div>
  </AbsoluteFill>
);

/* 2 · "Pero hay algo peor… estanflación" (pantalla completa) */
export const SWorse: React.FC<P & { revealAt: number }> = ({ revealAt }) => {
  const f = useF();
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Title text="HAY ALGO" top={430} size={140} />
      <Block text="PEOR" top={590} at={4} size={150} bg={C.yellow} color={C.ink} />
      <div style={{ position: "absolute", top: 900, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: f >= revealAt ? 1 : 0 }}>
        <div
          style={{
            background: C.blue,
            color: C.paper,
            fontFamily: F.display,
            fontWeight: 800,
            fontSize: 118,
            letterSpacing: -2,
            padding: "22px 44px 28px",
            borderRadius: 22,
            border: `${STYLE.stroke + 2}px solid ${C.ink}`,
            boxShadow: STYLE.shadow(14),
            rotate: `${interpolate(f, [revealAt, revealAt + 8], [-10, 2], clamp)}deg`,
            scale: String(interpolate(f, [revealAt, revealAt + 7], [1.8, 1], clamp)),
          }}
        >
          ESTANFLACIÓN
        </div>
      </div>
      <Scribble x={200} y={1140} w={680} at={revealAt + 10} />
    </AbsoluteFill>
  );
};

/* 3 · El almacén gigante */
export const SStore: React.FC<P & { goodsAt: number }> = ({ goodsAt }) => {
  const f = useF();
  const goods: { n: IconName; c: string }[] = [
    { n: "coin", c: C.copper },
    { n: "car", c: C.red },
    { n: "phone", c: C.blue },
    { n: "cart", c: C.yellow },
  ];
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="La economía = un almacén" accent={C.blue}>
        <div style={{ position: "absolute", top: 120, left: 0, right: 0, display: "flex", justifyContent: "center", scale: String(pop(f, 4, 14)) }}>
          <Icon name="store" size={170} color={C.blue} />
        </div>
        <div style={{ position: "absolute", top: 320, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 40 }}>
          {goods.map((g, i) => (
            <div key={g.n} style={{ scale: String(pop(f, goodsAt + i * 4, 10)) }}>
              <Icon name={g.n} size={84} color={g.c} />
            </div>
          ))}
        </div>
        <div style={{ position: "absolute", top: 428, left: 0, right: 0, textAlign: "center", fontFamily: F.body, fontWeight: 700, fontSize: 26, color: C.muted, opacity: prog(f, goodsAt, goodsAt + 10) }}>
          todo lo que Chile produce y vende
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 4 · Dos trimestres seguidos de caída = recesión técnica */
export const SBarsRecession: React.FC<P & { stampAt: number }> = ({ stampAt }) => {
  const f = useF();
  const bars = [
    { t: "T1", h: 200, at: 4, c: "#CFCAC0" },
    { t: "T2", h: 160, at: 14, c: C.red },
    { t: "T3", h: 120, at: 24, c: C.red },
  ];
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="Ventas del almacén" accent={C.red} right={<Pill text="vs. trimestre anterior" bg={C.faint} size={22} />}>
        <div style={{ position: "absolute", left: 120, right: 120, bottom: 60, display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
          {bars.map((b, i) => {
            const p = prog(f, b.at, b.at + 14);
            return (
              <div key={b.t} style={{ display: "flex", flexDirection: "column", alignItems: "center", width: 160 }}>
                <div style={{ height: 70, display: "flex", alignItems: "flex-end" }}>
                  {i > 0 ? (
                    <div style={{ scale: String(pop(f, b.at + 8, 10)) }}>
                      <Icon name="down" size={60} color={C.red} />
                    </div>
                  ) : null}
                </div>
                <div style={{ width: 160, height: b.h * p, background: b.c, border: `${STYLE.stroke}px solid ${C.ink}`, borderBottom: "none", borderRadius: "12px 12px 0 0" }} />
                <div style={{ width: 200, height: STYLE.stroke, background: C.ink }} />
                <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 30, color: C.muted, marginTop: 6 }}>{b.t}</div>
              </div>
            );
          })}
        </div>
        <Stamp text="RECESIÓN TÉCNICA" at={stampAt} top={150} />
      </Card>
    </AbsoluteFill>
  );
};

/* 5 · Consecuencias */
export const SConsequences: React.FC<P & { beats: number[] }> = ({ beats }) => (
  <AbsoluteFill>
    <SeriesTag />
    <Card title="Cuando se vende menos…" accent={C.red}>
      <Row at={beats[0]} top={120} icon="cart" color={C.yellow} label="Ventas" value="▼" valueColor={C.red} />
      <Row at={beats[1]} top={230} icon="factory" color={C.blue} label="Inversión" value="▼" valueColor={C.red} />
      <Row at={beats[2]} top={340} icon="person" color={C.green} label="Empleo" value="▼" valueColor={C.red} />
    </Card>
  </AbsoluteFill>
);

/* 6 · PIB de Chile vs. trimestre anterior */
export const SPib: React.FC<P & { t2At: number; decAt: number; twoAt: number }> = ({ t2At, decAt, twoAt }) => {
  const f = useF();
  const showDec = f >= decAt;
  const Col: React.FC<{ label: string; at: number; value: string; color: string; h: number; note?: React.ReactNode }> = ({ label, at, value, color, h, note }) => {
    const p = prog(f, at, at + 12);
    return (
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", width: 300, opacity: Math.min(1, p * 2) }}>
        <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 62, color, letterSpacing: -1 }}>{value}</div>
        <div style={{ height: 30 }}>{note}</div>
        <div style={{ width: 200, height: Math.max(10, h * p), background: color, border: `${STYLE.stroke}px solid ${C.ink}`, borderRadius: "0 0 12px 12px" }} />
        <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 30, color: C.muted, marginTop: 10 }}>{label}</div>
      </div>
    );
  };
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="PIB de Chile 2026" accent={C.red} right={<Pill text="vs. trimestre anterior" bg={C.faint} size={22} />} source="Banco Central">
        <div style={{ position: "absolute", top: 120, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 70 }}>
          <Col label="ENE–MAR" at={2} value="-0,3%" color={C.red} h={120} />
          <Col
            label="ABR–JUN"
            at={t2At}
            value={showDec ? "-0,02%" : "0,0%"}
            color={showDec ? C.red : "#CFCAC0"}
            h={showDec ? 14 : 10}
            note={showDec ? <Pill text="con todos los decimales" bg={C.yellow} size={20} /> : null}
          />
        </div>
        <div style={{ position: "absolute", top: 395, left: 0, right: 0, display: "flex", justifyContent: "center", opacity: f >= twoAt ? 1 : 0, scale: String(pop(f, twoAt, 12)) }}>
          <Pill text="2 CAÍDAS SEGUIDAS" bg={C.red} color={C.paper} size={32} />
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 7 · Cita textual */
export const SQuote: React.FC<P & { quote: string; who: string; role: string; source: string; accent?: string; chips?: { at: number; text: string; bg: string; color?: string }[] }> = ({
  quote,
  who,
  role,
  source,
  accent = C.blue,
  chips = [],
}) => {
  const f = useF();
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="" accent={accent} source={source}>
        <div style={{ position: "absolute", top: 34, left: 40, fontFamily: F.display, fontWeight: 800, fontSize: 150, lineHeight: 1, color: accent }}>“</div>
        <div style={{ position: "absolute", top: 120, left: 60, right: 60, fontFamily: F.display, fontWeight: 800, fontSize: 52, lineHeight: 1.12, letterSpacing: -1 }}>
          {quote}
        </div>
        <div style={{ position: "absolute", top: 300, left: 60, right: 60, opacity: prog(f, 10, 20) }}>
          <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 34 }}>{who}</div>
          <div style={{ fontFamily: F.body, fontWeight: 600, fontSize: 26, color: C.muted }}>{role}</div>
        </div>
        <div style={{ position: "absolute", top: 395, left: 60, right: 40, display: "flex", gap: 14 }}>
          {chips.map((c) => (
            <div key={c.text} style={{ scale: String(pop(f, c.at, 10)), opacity: f >= c.at ? 1 : 0 }}>
              <Pill text={c.text} bg={c.bg} color={c.color ?? C.ink} size={26} />
            </div>
          ))}
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 8 · Estancamiento + inflación = estanflación */
export const SEquation: React.FC<P & { b1: number; b2: number; b3: number }> = ({ b1, b2, b3 }) => {
  const f = useF();
  const piece = (text: string, at: number, bg: string, color: string, size = 62) => (
    <div
      style={{
        background: bg,
        color,
        fontFamily: F.display,
        fontWeight: 800,
        fontSize: size,
        letterSpacing: -1,
        padding: "10px 24px 14px",
        borderRadius: 14,
        border: `${STYLE.stroke}px solid ${C.ink}`,
        boxShadow: STYLE.shadow(6),
        scale: String(pop(f, at, 12)),
        opacity: f >= at ? 1 : 0,
      }}
    >
      {text}
    </div>
  );
  const op = (t: string, at: number) => (
    <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 70, opacity: f >= at ? 1 : 0, lineHeight: 1 }}>{t}</div>
  );
  return (
    <AbsoluteFill>
      <SeriesTag />
      <div style={{ position: "absolute", top: 190, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 18 }}>
        {piece("ESTANCAMIENTO", b1, C.paper, C.ink)}
        {op("+", b2)}
        {piece("INFLACIÓN", b2, C.red, C.paper)}
        {op("=", b3)}
        {piece("ESTANFLACIÓN", b3, C.blue, C.paper, 72)}
      </div>
    </AbsoluteFill>
  );
};

/* 9 · La economía no avanza, los precios suben */
export const SNoAdvance: React.FC<P & { b2: number }> = ({ b2 }) => (
  <AbsoluteFill>
    <SeriesTag />
    <Card title="Estanflación" accent={C.blue}>
      <Row at={4} top={150} icon="pause" color={C.yellow} label="La economía" value="no avanza" valueColor={C.muted} />
      <Row at={b2} top={290} icon="up" color={C.red} label="Los precios" value="siguen subiendo" valueColor={C.red} />
    </Card>
  </AbsoluteFill>
);

/* 10 · Auto en pana, bencina sube */
export const SCarPump: React.FC<P & { b2: number }> = ({ b2 }) => {
  const f = useF();
  const smoke = (i: number) => ((f + i * 10) % 30) / 30;
  return (
    <AbsoluteFill>
      <SeriesTag />
      <div style={{ position: "absolute", top: 230, left: 0, right: 0, display: "flex", justifyContent: "space-around", alignItems: "flex-end" }}>
        <div style={{ position: "relative", display: "flex", flexDirection: "column", alignItems: "center", gap: 20, scale: String(pop(f, 0, 12)) }}>
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                left: 150 + i * 26,
                top: 20 - smoke(i) * 110,
                width: 40 - smoke(i) * 14,
                height: 40 - smoke(i) * 14,
                borderRadius: 999,
                background: "#8A8D96",
                border: `3px solid ${C.ink}`,
                opacity: 1 - smoke(i),
              }}
            />
          ))}
          <div style={{ rotate: `${Math.sin(f / 2) * 1.5}deg` }}>
            <Icon name="car" size={260} color={C.red} />
          </div>
          <Pill text="EN PANA" bg={C.paper} size={32} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 20, scale: String(pop(f, b2, 12)), opacity: f >= b2 ? 1 : 0 }}>
          <div style={{ display: "flex", alignItems: "flex-start" }}>
            <Icon name="pump" size={220} color={C.yellow} />
            <div style={{ translate: `0px ${-Math.abs(Math.sin(f / 5)) * 20}px` }}>
              <Icon name="up" size={90} color={C.red} />
            </div>
          </div>
          <Pill text="BENCINA ▲" bg={C.red} color={C.paper} size={32} />
        </div>
      </div>
    </AbsoluteFill>
  );
};

/* 11 · Años 70 */
export const SHistory: React.FC<P & { b2: number; b3: number }> = ({ b2, b3 }) => {
  const f = useF();
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="Años 70" accent={C.copper} right={<Pill text="crisis del petróleo" bg={C.faint} size={22} />}>
        <div style={{ position: "absolute", top: 120, left: 0, right: 0, display: "flex", justifyContent: "center", alignItems: "center", gap: 40 }}>
          <div style={{ scale: String(pop(f, 2, 12)) }}>
            <Icon name="barrel" size={170} color={C.copper} />
          </div>
          <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 150, color: C.red, letterSpacing: -4, scale: String(pop(f, b2, 12)), opacity: f >= b2 ? 1 : 0 }}>×4</div>
        </div>
        <div style={{ position: "absolute", top: 340, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 16, opacity: f >= b3 ? 1 : 0, scale: String(pop(f, b3, 12)) }}>
          <Pill text="▲ INFLACIÓN" bg={C.red} color={C.paper} size={30} />
          <Pill text="▲ DESEMPLEO" bg={C.red} color={C.paper} size={30} />
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 12 · Los 3 ingredientes en Chile */
export const SIngredients: React.FC<P & { beats: number[]; allAt: number }> = ({ beats, allAt }) => {
  const f = useF();
  const check = (at: number) => (
    <div style={{ scale: String(pop(f, at + 6, 10)), opacity: f >= at + 6 ? 1 : 0 }}>
      <Icon name="check" size={56} color={C.green} />
    </div>
  );
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="Chile hoy" accent={C.blue} source="Banco Central · INE">
        <Row at={beats[0]} top={110} icon="pause" color={C.yellow} label="Crecimiento" value={<span style={{ display: "flex", gap: 14, alignItems: "center" }}>≈0% {check(beats[0])}</span>} />
        <Row
          at={beats[1]}
          top={210}
          icon="up"
          color={C.red}
          label="Inflación"
          valueColor={C.red}
          value={<span style={{ display: "flex", gap: 14, alignItems: "center" }}>4,5% {check(beats[1])}</span>}
        />
        <Row
          at={beats[2]}
          top={310}
          icon="person"
          color={C.red}
          label="Desempleo"
          valueColor={C.red}
          value={<span style={{ display: "flex", gap: 14, alignItems: "center" }}>9,8% {check(beats[2])}</span>}
        />
        <div style={{ position: "absolute", top: 120, right: 40, opacity: f >= allAt ? 1 : 0 }}>
          <Stamp text="3 DE 3" at={allAt} top={0} bg={C.yellow} color={C.ink} rotate={8} />
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 13 · El dilema del Banco Central */
export const SDilemma: React.FC<P & { b1: number; b2: number; b3: number }> = ({ b1, b2, b3 }) => {
  const f = useF();
  const Opt: React.FC<{ at: number; q: string; a: string; top: number }> = ({ at, q, a, top }) => (
    <div style={{ position: "absolute", top, left: 40, right: 40, display: "flex", alignItems: "center", gap: 20, opacity: f >= at ? 1 : 0, scale: String(0.9 + 0.1 * pop(f, at, 12)) }}>
      <div style={{ background: C.paper, border: `${STYLE.stroke}px solid ${C.ink}`, borderRadius: 14, padding: "10px 18px", fontFamily: F.display, fontWeight: 800, fontSize: 36, boxShadow: STYLE.shadow(5) }}>{q}</div>
      <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 44 }}>→</div>
      <div style={{ opacity: f >= at + 12 ? 1 : 0, scale: String(pop(f, at + 12, 10)) }}>
        <Pill text={a} bg={C.red} color={C.paper} size={32} />
      </div>
    </div>
  );
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="El Banco Central, amarrado" accent={C.blue}>
        <div style={{ position: "absolute", top: 120, left: 40, scale: String(pop(f, 0, 12)) }}>
          <Icon name="bank" size={110} color={C.blue} />
        </div>
        <Opt at={b1} q="Sube la tasa" a="▼ frena la economía" top={b2 > 0 ? 250 : 250} />
        <Opt at={b3} q="Baja la tasa" a="▲ suben los precios" top={360} />
      </Card>
    </AbsoluteFill>
  );
};

/* 14 · ¿Estamos o no? */
export const SVerdict: React.FC<P & { b2: number }> = ({ b2 }) => {
  const f = useF();
  const Side: React.FC<{ at: number; head: string; body: string; who: string; color: string; left: number }> = ({ at, head, body, who, color, left }) => (
    <div
      style={{
        position: "absolute",
        top: 200,
        left,
        width: 450,
        height: 460,
        background: C.paper,
        border: `${STYLE.stroke}px solid ${C.ink}`,
        borderRadius: STYLE.radius,
        boxShadow: STYLE.shadow(10),
        padding: 30,
        boxSizing: "border-box",
        opacity: f >= at ? 1 : 0,
        scale: String(0.85 + 0.15 * pop(f, at, 12)),
        rotate: left < 300 ? "-1.5deg" : "1.5deg",
      }}
    >
      <div style={{ height: 12, background: color, border: `3px solid ${C.ink}`, borderRadius: 6, marginBottom: 20 }} />
      <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 56, letterSpacing: -1, lineHeight: 1, color }}>{head}</div>
      <div style={{ fontFamily: F.display, fontWeight: 700, fontSize: 32, lineHeight: 1.15, marginTop: 18 }}>{body}</div>
      <div style={{ position: "absolute", bottom: 26, left: 30, right: 30, fontFamily: F.body, fontWeight: 600, fontSize: 22, color: C.muted }}>{who}</div>
    </div>
  );
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Side at={2} left={50} color={C.green} head="Por ahora, no" body="La descartó: dice que la estanflación es algo que dura en el tiempo." who="Rosanna Costa · presidenta del Banco Central (sept.)" />
      <Side at={b2} left={580} color={C.red} head="“Virtualmente”" body="“…se encuentra en una estanflación.”" who="Juan Ortiz · economista, OCEC-UDP (sept.)" />
    </AbsoluteFill>
  );
};

/* 15 · Riesgo: petróleo y dólar */
export const SRisk: React.FC<P & { iconsAt: number }> = ({ iconsAt }) => {
  const f = useF();
  const v = interpolate(f, [4, 30], [0, 0.68], { ...clamp });
  return (
    <AbsoluteFill>
      <SeriesTag />
      <Card title="Riesgo de estanflación" accent={C.yellow}>
        <div style={{ position: "absolute", top: 130, left: 40, right: 40 }}>
          <div style={{ position: "relative", height: 46, borderRadius: 23, border: `${STYLE.stroke}px solid ${C.ink}`, background: `linear-gradient(90deg, ${C.green}, ${C.yellow} 50%, ${C.red})` }}>
            <div style={{ position: "absolute", left: `calc(${v * 100}% - 12px)`, top: -18, width: 24, height: 74, background: C.ink, borderRadius: 6, border: `3px solid ${C.paper}` }} />
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontFamily: F.display, fontWeight: 800, fontSize: 26, color: C.muted, marginTop: 10 }}>
            <span>bajo</span>
            <span>alto</span>
          </div>
        </div>
        <div style={{ position: "absolute", top: 290, left: 0, right: 0, display: "flex", justifyContent: "center", gap: 90 }}>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8, scale: String(pop(f, iconsAt, 12)), opacity: f >= iconsAt ? 1 : 0 }}>
            <Icon name="barrel" size={100} color={C.copper} />
            <span style={{ fontFamily: F.display, fontWeight: 800, fontSize: 28 }}>PETRÓLEO</span>
          </div>
          <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8, scale: String(pop(f, iconsAt + 8, 12)), opacity: f >= iconsAt + 8 ? 1 : 0 }}>
            <Icon name="dollar" size={100} color={C.green} />
            <span style={{ fontFamily: F.display, fontWeight: 800, fontSize: 28 }}>DÓLAR</span>
          </div>
        </div>
      </Card>
    </AbsoluteFill>
  );
};

/* 16 · Cierre */
export const SCta: React.FC<P> = () => {
  const f = useF();
  const done = f > 60;
  const press = interpolate(f, [52, 57, 64], [1, 0.9, 1], clamp);
  return (
    <AbsoluteFill>
      <SeriesTag />
      <div style={{ position: "absolute", top: 220, left: 0, right: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 34 }}>
        <div
          style={{
            scale: String(pop(f, 4, 12) * press),
            background: done ? C.paper : C.blue,
            color: done ? C.ink : C.paper,
            fontFamily: F.display,
            fontWeight: 800,
            fontSize: 72,
            letterSpacing: -1,
            padding: "18px 64px 22px",
            borderRadius: 18,
            border: `${STYLE.stroke}px solid ${C.ink}`,
            boxShadow: STYLE.shadow(10),
          }}
        >
          {done ? "✓ Siguiendo" : "+ Seguir"}
        </div>
        <div style={{ fontFamily: F.display, fontWeight: 800, fontSize: 40, opacity: prog(f, 14, 24) }}>la economía, sin enredos</div>
        <div style={{ fontFamily: F.body, fontWeight: 600, fontSize: 22, color: C.muted, opacity: prog(f, 20, 30) }}>
          Fuentes: Banco Central · INE · Bloomberg · Emol
        </div>
      </div>
    </AbsoluteFill>
  );
};

export { count, fmt };
