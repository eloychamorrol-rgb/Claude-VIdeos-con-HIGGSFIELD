import React from "react";
import { C } from "./theme";
import { useF } from "./ui";

/**
 * Avatar ilustrado (busto), con el mismo lenguaje del canal: formas planas y borde negro.
 * Es una caricatura genérica configurable; no pretende ser un retrato fotográfico.
 */
export type AvatarLook = {
  skin: string;
  hair: "short" | "receding" | "bald" | "bob" | "long" | "curly";
  hairColor: string;
  glasses?: boolean;
  beard?: "none" | "stubble" | "full";
  beardColor?: string;
  suit: string;
  shirt?: string;
  tie?: string; // si no hay, cuello abierto
  earrings?: boolean;
};

const ink = C.ink;
const sw = 5;

export const Avatar: React.FC<{ look: AvatarLook; size: number; talking?: boolean; bg?: string; style?: React.CSSProperties }> = ({
  look,
  size,
  talking = false,
  bg = C.yellow,
  style,
}) => {
  const f = useF();
  const blink = f % 90 > 86;
  const mouth = talking ? 3 + Math.abs(Math.sin(f / 2.2)) * 9 : 2;
  const bob = talking ? Math.sin(f / 6) * 1.5 : 0;
  const L = look;
  return (
    <svg width={size} height={size} viewBox="0 0 200 200" style={{ overflow: "visible", ...style }}>
      <defs>
        <clipPath id="av-circle">
          <circle cx={100} cy={100} r={96} />
        </clipPath>
      </defs>
      <circle cx={100} cy={100} r={96} fill={bg} stroke={ink} strokeWidth={sw} />
      <g clipPath="url(#av-circle)">
        <g transform={`translate(0 ${bob})`}>
          {/* pelo largo detrás */}
          {L.hair === "long" || L.hair === "bob" ? (
            <path d={L.hair === "long" ? "M52 80 Q48 150 62 172 L138 172 Q152 150 148 80 Z" : "M54 78 Q50 130 62 140 L138 140 Q150 130 146 78 Z"} fill={L.hairColor} stroke={ink} strokeWidth={sw} />
          ) : null}
          {/* cuerpo */}
          <path d="M28 210 Q30 156 72 146 L128 146 Q170 156 172 210 Z" fill={L.suit} stroke={ink} strokeWidth={sw} strokeLinejoin="round" />
          <path d="M82 146 L100 182 L118 146 Z" fill={L.shirt ?? C.paper} stroke={ink} strokeWidth={4} strokeLinejoin="round" />
          {L.tie ? <path d="M95 152 L105 152 L109 190 L100 200 L91 190 Z" fill={L.tie} stroke={ink} strokeWidth={3.5} strokeLinejoin="round" /> : null}
          <path d="M72 146 L92 176 M128 146 L108 176" stroke={ink} strokeWidth={4} fill="none" />
          {/* cuello */}
          <rect x={86} y={124} width={28} height={26} fill={L.skin} stroke={ink} strokeWidth={4} />
          {/* cabeza */}
          <ellipse cx={100} cy={92} rx={38} ry={44} fill={L.skin} stroke={ink} strokeWidth={sw} />
          <ellipse cx={62} cy={96} rx={7} ry={10} fill={L.skin} stroke={ink} strokeWidth={4} />
          <ellipse cx={138} cy={96} rx={7} ry={10} fill={L.skin} stroke={ink} strokeWidth={4} />
          {L.earrings ? (
            <>
              <circle cx={62} cy={110} r={3.5} fill={C.yellow} stroke={ink} strokeWidth={2} />
              <circle cx={138} cy={110} r={3.5} fill={C.yellow} stroke={ink} strokeWidth={2} />
            </>
          ) : null}
          {/* pelo */}
          {L.hair === "short" ? <path d="M62 86 Q60 46 100 44 Q140 46 138 86 Q130 66 100 64 Q72 66 62 86 Z" fill={L.hairColor} stroke={ink} strokeWidth={sw} strokeLinejoin="round" /> : null}
          {L.hair === "receding" ? (
            <>
              <path d="M62 90 Q60 64 72 56 Q70 74 68 92 Z" fill={L.hairColor} stroke={ink} strokeWidth={4} strokeLinejoin="round" />
              <path d="M138 90 Q140 64 128 56 Q130 74 132 92 Z" fill={L.hairColor} stroke={ink} strokeWidth={4} strokeLinejoin="round" />
            </>
          ) : null}
          {L.hair === "bald" ? (
            <>
              <path d="M62 96 Q62 80 66 74 L70 96 Z" fill={L.hairColor} stroke={ink} strokeWidth={3} />
              <path d="M138 96 Q138 80 134 74 L130 96 Z" fill={L.hairColor} stroke={ink} strokeWidth={3} />
            </>
          ) : null}
          {L.hair === "curly" ? (
            <path
              d="M60 86 Q52 60 70 50 Q74 34 92 40 Q104 28 118 40 Q138 36 136 56 Q150 66 140 86 Q132 66 116 66 Q100 58 84 66 Q68 66 60 86 Z"
              fill={L.hairColor}
              stroke={ink}
              strokeWidth={sw}
              strokeLinejoin="round"
            />
          ) : null}
          {L.hair === "bob" || L.hair === "long" ? (
            <path d="M60 92 Q56 46 100 44 Q144 46 140 92 Q132 62 104 60 Q90 74 66 78 Q62 84 60 92 Z" fill={L.hairColor} stroke={ink} strokeWidth={sw} strokeLinejoin="round" />
          ) : null}
          {/* barba */}
          {L.beard === "full" ? <path d="M64 100 Q66 140 100 140 Q134 140 136 100 Q128 122 100 124 Q72 122 64 100 Z" fill={L.beardColor ?? L.hairColor} stroke={ink} strokeWidth={4} strokeLinejoin="round" /> : null}
          {L.beard === "stubble" ? <path d="M66 104 Q70 136 100 138 Q130 136 134 104 Q126 126 100 128 Q74 126 66 104 Z" fill={L.beardColor ?? L.hairColor} opacity={0.35} /> : null}
          {/* cejas, ojos */}
          <path d="M76 78 Q84 73 92 77 M108 77 Q116 73 124 78" stroke={ink} strokeWidth={4} fill="none" strokeLinecap="round" />
          {blink ? (
            <path d="M78 90 L90 90 M110 90 L122 90" stroke={ink} strokeWidth={4} strokeLinecap="round" />
          ) : (
            <>
              <circle cx={84} cy={90} r={4.5} fill={ink} />
              <circle cx={116} cy={90} r={4.5} fill={ink} />
            </>
          )}
          {L.glasses ? (
            <g fill="none" stroke={ink} strokeWidth={3.5}>
              <rect x={70} y={81} width={26} height={19} rx={6} />
              <rect x={104} y={81} width={26} height={19} rx={6} />
              <line x1={96} y1={89} x2={104} y2={89} />
            </g>
          ) : null}
          {/* nariz y boca */}
          <path d="M100 94 Q96 106 102 108" stroke={ink} strokeWidth={3.5} fill="none" strokeLinecap="round" />
          <ellipse cx={100} cy={120} rx={10} ry={mouth / 2 + 1} fill="#7A2E2E" stroke={ink} strokeWidth={3.5} />
        </g>
      </g>
    </svg>
  );
};

/* Avatares de este video. Ajustables cuando haya foto de referencia. */
export const LOOKS: Record<"quiroz" | "costa" | "ortiz", AvatarLook> = {
  quiroz: { skin: "#E7B996", hair: "receding", hairColor: "#9A9AA2", glasses: true, beard: "none", suit: "#2B3550", tie: C.red },
  costa: { skin: "#EDC3A4", hair: "bob", hairColor: "#B9915F", glasses: false, suit: "#3B4A6B", shirt: C.paper, earrings: true },
  ortiz: { skin: "#D9A57F", hair: "short", hairColor: "#2D2420", glasses: true, beard: "stubble", suit: "#5A6472", shirt: "#DDE6F5" },
};
