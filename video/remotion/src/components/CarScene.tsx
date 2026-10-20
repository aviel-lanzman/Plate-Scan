import React from 'react';
import {fontFamily} from '../fonts';

/**
 * A synthetic street with a grey hatchback seen from behind, drawn in a
 * 1080x1920 portrait "camera" space. The plate's centre sits at the centre
 * of the frame, where the app's aiming frame is.
 */
export const CarScene: React.FC<{
  plate: string;
  zoom?: number;
  shiftX?: number;
  shiftY?: number;
  /** Seconds, for the slow drift of the background. */
  time?: number;
}> = ({plate, zoom = 1, shiftX = 0, shiftY = 0, time = 0}) => {
  const carScale = 1.3;
  // Plate centre in car coordinates is (300, 349).
  const carX = 540 - 300 * carScale;
  const carY = 960 - 349 * carScale;
  return (
    <svg
      viewBox="0 0 1080 1920"
      preserveAspectRatio="xMidYMid slice"
      style={{width: '100%', height: '100%', display: 'block'}}
    >
      <defs>
        <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#8fb2d9" />
          <stop offset="1" stopColor="#e4ebf2" />
        </linearGradient>
        <linearGradient id="road" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#6c7077" />
          <stop offset="1" stopColor="#2b2e33" />
        </linearGradient>
        <linearGradient id="body" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#8794a3" />
          <stop offset="0.55" stopColor="#6b7785" />
          <stop offset="1" stopColor="#4c5560" />
        </linearGradient>
        <linearGradient id="cabin" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#9aa6b3" />
          <stop offset="1" stopColor="#66717d" />
        </linearGradient>
        <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#3a4b5c" />
          <stop offset="0.45" stopColor="#1b2631" />
          <stop offset="1" stopColor="#0f161d" />
        </linearGradient>
        <linearGradient id="light" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ff6b5e" />
          <stop offset="1" stopColor="#b3151b" />
        </linearGradient>
        <linearGradient id="bumper" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#5d6773" />
          <stop offset="1" stopColor="#3b424b" />
        </linearGradient>
        <radialGradient id="vignette" cx="0.5" cy="0.5" r="0.75">
          <stop offset="0.6" stopColor="rgba(0,0,0,0)" />
          <stop offset="1" stopColor="rgba(0,0,0,0.45)" />
        </radialGradient>
      </defs>
      <g
        transform={`translate(${540 + shiftX} ${960 + shiftY}) scale(${zoom}) translate(-540 -960)`}
      >
        <rect x={-400} y={-400} width={1880} height={1060} fill="url(#sky)" />
        {/* Buildings drift slowly, as if the camera breathes. */}
        <g transform={`translate(${Math.sin(time * 0.6) * 6} 0)`}>
          {[
            [-200, 360, 260, '#c5cdd6'],
            [80, 300, 210, '#b4bec9'],
            [300, 410, 240, '#cfd5dc'],
            [560, 330, 200, '#bcc5cf'],
            [770, 280, 260, '#c8d0d8'],
            [1040, 380, 260, '#b7c0ca'],
          ].map(([x, y, w, c], i) => (
            <g key={i}>
              <rect x={x as number} y={y as number} width={w as number} height={700 - (y as number)} fill={c as string} />
              {Array.from({length: 6}).map((_, r) =>
                Array.from({length: 4}).map((__, k) => (
                  <rect
                    key={`${r}-${k}`}
                    x={(x as number) + 24 + k * (((w as number) - 48) / 4)}
                    y={(y as number) + 30 + r * 52}
                    width={((w as number) - 48) / 4 - 18}
                    height={30}
                    fill="rgba(255,255,255,0.35)"
                  />
                )),
              )}
            </g>
          ))}
        </g>
        <rect x={-400} y={640} width={1880} height={50} fill="#b9b3a8" />
        <rect x={-400} y={686} width={1880} height={10} fill="#8f8a80" />
        <rect x={-400} y={696} width={1880} height={1500} fill="url(#road)" />
        {[0, 1, 2, 3].map((i) => (
          <polygon
            key={i}
            points={`${520 - i * 6},${760 + i * 300} ${560 + i * 6},${760 + i * 300} ${566 + i * 10},${900 + i * 330} ${514 - i * 10},${900 + i * 330}`}
            fill="rgba(255,255,255,0.55)"
            transform={`translate(${-470 - i * 40} 0)`}
          />
        ))}
        <g transform={`translate(${carX} ${carY}) scale(${carScale})`}>
          <ellipse cx={300} cy={494} rx={292} ry={26} fill="rgba(0,0,0,0.45)" />
          <rect x={62} y={392} width={96} height={102} rx={22} fill="#141518" />
          <rect x={442} y={392} width={96} height={102} rx={22} fill="#141518" />
          <path d="M118 250 C128 150 170 104 232 96 L368 96 C430 104 472 150 482 250 Z" fill="url(#cabin)" />
          <path d="M146 238 C156 160 190 126 240 120 L360 120 C410 126 444 160 454 238 Z" fill="url(#glass)" />
          <path d="M190 150 L250 128 L262 136 L206 162 Z" fill="rgba(255,255,255,0.12)" />
          <path d="M300 228 L376 198" stroke="#0b0f14" strokeWidth={5} strokeLinecap="round" />
          <path
            d="M58 300 C58 262 84 244 120 242 L480 242 C516 244 542 262 542 300 L548 418 C548 440 532 454 510 454 L90 454 C68 454 52 440 52 418 Z"
            fill="url(#body)"
          />
          <path d="M66 270 C68 256 82 250 100 250 L150 252 L146 318 L70 314 Z" fill="url(#light)" />
          <path d="M534 270 C532 256 518 250 500 250 L450 252 L454 318 L530 314 Z" fill="url(#light)" />
          <path d="M150 252 L150 318 Q300 330 450 318 L450 252" fill="none" stroke="rgba(0,0,0,0.22)" strokeWidth={3} />
          <ellipse cx={300} cy={282} rx={20} ry={13} fill="none" stroke="#d3d9df" strokeWidth={4} />
          <rect x={54} y={376} width={492} height={78} rx={34} fill="url(#bumper)" />
          <rect x={208} y={324} width={184} height={50} rx={8} fill="rgba(0,0,0,0.25)" />
          <g transform="translate(220 332)">
            <rect width={160} height={34} rx={4} fill="#FFCC00" stroke="#111" strokeWidth={2} />
            <rect x={1} y={1} width={18} height={32} rx={3} fill="#0038B8" />
            <text x={10} y={21} fontSize={10} fill="#fff" textAnchor="middle" fontWeight={700} fontFamily={fontFamily}>
              IL
            </text>
            <text x={90} y={27} fontSize={25} fill="#111" textAnchor="middle" fontWeight={800} fontFamily={fontFamily} letterSpacing={1}>
              {plate}
            </text>
          </g>
          <rect x={112} y={420} width={56} height={10} rx={5} fill="#a3171c" opacity={0.85} />
          <rect x={432} y={420} width={56} height={10} rx={5} fill="#a3171c" opacity={0.85} />
        </g>
      </g>
      <rect width={1080} height={1920} fill="url(#vignette)" />
    </svg>
  );
};
