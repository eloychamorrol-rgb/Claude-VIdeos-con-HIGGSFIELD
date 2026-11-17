import React from "react";
import { C } from "./theme";

/**
 * Íconos planos con borde negro (mismo lenguaje que las tarjetas).
 * viewBox 0 0 100 100.
 */
export type IconName =
  | "person"
  | "phone"
  | "car"
  | "pump"
  | "factory"
  | "tag"
  | "coin"
  | "lock"
  | "wallet"
  | "bulb"
  | "cart"
  | "up"
  | "down"
  | "pause"
  | "doc"
  | "bank"
  | "plate"
  | "store"
  | "barrel"
  | "dollar"
  | "check";

const S = { stroke: C.ink, strokeWidth: 5, strokeLinejoin: "round" as const, strokeLinecap: "round" as const };

const paths: Record<IconName, (color: string) => React.ReactNode> = {
  person: (c) => (
    <>
      <circle cx={50} cy={28} r={15} fill={c} {...S} />
      <path d="M22 88 C22 60 34 50 50 50 C66 50 78 60 78 88 Z" fill={c} {...S} />
    </>
  ),
  phone: (c) => (
    <>
      <rect x={27} y={8} width={46} height={84} rx={9} fill={C.ink} {...S} />
      <rect x={33} y={18} width={34} height={58} rx={3} fill={c} />
      <circle cx={50} cy={84} r={3.5} fill={C.paper} />
    </>
  ),
  car: (c) => (
    <>
      <path d="M8 66 L14 46 Q16 40 22 40 L30 40 L38 26 Q40 24 44 24 L66 24 Q70 24 72 28 L80 40 Q90 41 92 50 L92 66 Z" fill={c} {...S} />
      <path d="M41 30 L37 40 L62 40 L62 30 Z" fill={C.paper} {...S} strokeWidth={3} />
      <circle cx={28} cy={68} r={10} fill={C.ink} />
      <circle cx={72} cy={68} r={10} fill={C.ink} />
      <circle cx={28} cy={68} r={4} fill={C.paper} />
      <circle cx={72} cy={68} r={4} fill={C.paper} />
    </>
  ),
  pump: (c) => (
    <>
      <rect x={18} y={14} width={42} height={74} rx={6} fill={c} {...S} />
      <rect x={26} y={24} width={26} height={18} rx={3} fill={C.paper} {...S} strokeWidth={3} />
      <path d="M60 34 L72 34 Q78 34 78 40 L78 70 Q78 76 84 76" fill="none" {...S} />
      <rect x={12} y={84} width={54} height={8} rx={2} fill={C.ink} />
    </>
  ),
  factory: (c) => (
    <>
      <rect x={66} y={10} width={12} height={34} fill={C.muted} {...S} />
      <path d="M8 90 L8 44 L30 58 L30 44 L52 58 L52 44 L74 58 L92 44 L92 90 Z" fill={c} {...S} />
      <rect x={18} y={68} width={12} height={10} fill={C.yellow} {...S} strokeWidth={3} />
      <rect x={44} y={68} width={12} height={10} fill={C.yellow} {...S} strokeWidth={3} />
      <rect x={70} y={68} width={12} height={10} fill={C.yellow} {...S} strokeWidth={3} />
    </>
  ),
  tag: (c) => (
    <>
      <path d="M50 10 L88 10 L88 48 L48 88 L12 52 Z" fill={c} {...S} />
      <circle cx={72} cy={26} r={6} fill={C.paper} {...S} strokeWidth={3} />
      <text x={50} y={62} textAnchor="middle" fontSize={30} fontWeight={800} fill={C.paper} fontFamily="'Bricolage Grotesque', sans-serif" transform="rotate(-45 50 52)">
        $
      </text>
    </>
  ),
  coin: (c) => (
    <>
      <circle cx={50} cy={50} r={38} fill={c} {...S} />
      <circle cx={50} cy={50} r={26} fill="none" stroke={C.ink} strokeWidth={3} opacity={0.5} />
      <text x={50} y={62} textAnchor="middle" fontSize={34} fontWeight={800} fill={C.ink} fontFamily="'Bricolage Grotesque', sans-serif">
        Cu
      </text>
    </>
  ),
  lock: (c) => (
    <>
      <path d="M32 46 L32 32 Q32 14 50 14 Q68 14 68 32 L68 46" fill="none" {...S} strokeWidth={8} />
      <rect x={20} y={44} width={60} height={46} rx={8} fill={c} {...S} />
      <circle cx={50} cy={64} r={6} fill={C.ink} />
      <rect x={47} y={64} width={6} height={14} fill={C.ink} />
    </>
  ),
  wallet: (c) => (
    <>
      <rect x={10} y={26} width={80} height={58} rx={10} fill={c} {...S} />
      <path d="M18 26 L66 12 L72 26" fill="none" {...S} />
      <rect x={58} y={46} width={32} height={20} rx={6} fill={C.yellow} {...S} />
      <circle cx={70} cy={56} r={3.5} fill={C.ink} />
    </>
  ),
  bulb: (c) => (
    <>
      <path d="M50 8 Q78 8 78 38 Q78 54 64 64 L64 74 L36 74 L36 64 Q22 54 22 38 Q22 8 50 8 Z" fill={c} {...S} />
      <rect x={36} y={74} width={28} height={14} rx={3} fill={C.muted} {...S} />
      <path d="M44 48 L50 40 L56 48" fill="none" {...S} strokeWidth={3} />
    </>
  ),
  cart: (c) => (
    <>
      <path d="M6 14 L20 14 L30 64 L80 64 L90 28 L24 28" fill="none" {...S} />
      <path d="M26 30 L86 30 L78 60 L31 60 Z" fill={c} {...S} />
      <circle cx={36} cy={80} r={8} fill={C.ink} />
      <circle cx={74} cy={80} r={8} fill={C.ink} />
    </>
  ),
  up: (c) => <path d="M50 8 L88 50 L64 50 L64 92 L36 92 L36 50 L12 50 Z" fill={c} {...S} />,
  down: (c) => <path d="M50 92 L88 50 L64 50 L64 8 L36 8 L36 50 L12 50 Z" fill={c} {...S} />,
  pause: (c) => (
    <>
      <rect x={18} y={12} width={24} height={76} rx={6} fill={c} {...S} />
      <rect x={58} y={12} width={24} height={76} rx={6} fill={c} {...S} />
    </>
  ),
  doc: (c) => (
    <>
      <path d="M18 6 L64 6 L84 26 L84 94 L18 94 Z" fill={C.paper} {...S} />
      <path d="M64 6 L64 26 L84 26" fill="none" {...S} />
      <line x1={30} y1={42} x2={72} y2={42} {...S} strokeWidth={4} />
      <line x1={30} y1={56} x2={72} y2={56} {...S} strokeWidth={4} />
      <line x1={30} y1={70} x2={56} y2={70} {...S} strokeWidth={4} />
      <circle cx={70} cy={76} r={10} fill={c} {...S} strokeWidth={3} />
    </>
  ),
  bank: (c) => (
    <>
      <path d="M8 34 L50 8 L92 34 Z" fill={c} {...S} />
      {[18, 36, 54, 72].map((x) => (
        <rect key={x} x={x} y={38} width={10} height={40} fill={C.paper} {...S} strokeWidth={3} />
      ))}
      <rect x={6} y={80} width={88} height={12} fill={c} {...S} />
    </>
  ),
  store: (c) => (
    <>
      <rect x={12} y={40} width={76} height={50} fill={C.paper} {...S} />
      <path d="M6 40 L14 14 L86 14 L94 40 Z" fill={c} {...S} />
      {[22, 40, 58, 76].map((x) => (
        <path key={x} d={`M${x - 9} 40 Q${x} 52 ${x + 9} 40`} fill={c} {...S} strokeWidth={3} />
      ))}
      <rect x={22} y={58} width={22} height={32} fill={C.yellow} {...S} strokeWidth={3} />
      <rect x={54} y={56} width={24} height={18} fill={C.faint} {...S} strokeWidth={3} />
    </>
  ),
  barrel: (c) => (
    <>
      <path d="M22 12 L78 12 Q86 50 78 88 L22 88 Q14 50 22 12 Z" fill={c} {...S} />
      <line x1={17} y1={34} x2={83} y2={34} {...S} />
      <line x1={17} y1={66} x2={83} y2={66} {...S} />
      <path d="M50 42 Q58 52 50 60 Q42 52 50 42 Z" fill={C.ink} />
    </>
  ),
  dollar: (c) => (
    <>
      <rect x={6} y={24} width={88} height={52} rx={8} fill={c} {...S} />
      <circle cx={50} cy={50} r={15} fill={C.paper} {...S} strokeWidth={3} />
      <text x={50} y={58} textAnchor="middle" fontSize={22} fontWeight={800} fill={C.ink} fontFamily="'Bricolage Grotesque', sans-serif">
        $
      </text>
    </>
  ),
  check: (c) => (
    <>
      <circle cx={50} cy={50} r={40} fill={c} {...S} />
      <path d="M30 52 L44 66 L72 36" fill="none" stroke={C.ink} strokeWidth={9} strokeLinecap="round" strokeLinejoin="round" />
    </>
  ),
  plate: (c) => (
    <>
      <ellipse cx={50} cy={62} rx={44} ry={20} fill={C.paper} {...S} />
      <path d="M22 60 Q24 36 50 34 Q76 36 78 60 Z" fill={c} {...S} />
      <path d="M40 30 Q36 22 42 16 M52 30 Q48 22 54 16" fill="none" stroke={C.muted} strokeWidth={3} strokeLinecap="round" />
    </>
  ),
};

export const Icon: React.FC<{ name: IconName; size: number; color?: string; style?: React.CSSProperties }> = ({
  name,
  size,
  color = C.blue,
  style,
}) => (
  <svg width={size} height={size} viewBox="0 0 100 100" style={{ overflow: "visible", ...style }}>
    {paths[name](color)}
  </svg>
);
