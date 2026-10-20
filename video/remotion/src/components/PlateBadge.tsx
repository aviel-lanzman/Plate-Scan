import React from 'react';
import {fontFamily} from '../fonts';

/** The app's yellow Israeli plate badge, sized by its height. */
export const PlateBadge: React.FC<{plate: string; height: number}> = ({
  plate,
  height,
}) => (
  <div
    style={{
      display: 'inline-flex',
      direction: 'ltr',
      height,
      background: '#FFCC00',
      border: `${Math.max(2, height * 0.05)}px solid #000`,
      borderRadius: height * 0.16,
      overflow: 'hidden',
      fontFamily,
    }}
  >
    <div
      style={{
        background: '#0038B8',
        color: '#fff',
        fontWeight: 700,
        fontSize: height * 0.3,
        padding: `0 ${height * 0.14}px`,
        display: 'flex',
        alignItems: 'center',
      }}
    >
      IL
    </div>
    <div
      style={{
        color: '#000',
        fontWeight: 900,
        fontSize: height * 0.66,
        letterSpacing: height * 0.03,
        padding: `0 ${height * 0.26}px`,
        display: 'flex',
        alignItems: 'center',
        fontVariantNumeric: 'tabular-nums',
      }}
    >
      {plate}
    </div>
  </div>
);
