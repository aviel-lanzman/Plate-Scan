import React from 'react';
import {interpolate, useCurrentFrame} from 'remotion';

/** A finger-tap ripple at (x, y) in the parent's pixels, starting at [at]. */
export const Tap: React.FC<{x: number; y: number; at: number; size?: number}> = ({
  x,
  y,
  at,
  size = 150,
}) => {
  const t = useCurrentFrame() - at;
  if (t < 0 || t > 24) return null;
  const scale = interpolate(t, [0, 24], [0.4, 1.6]);
  const opacity = interpolate(t, [0, 6, 24], [0, 0.9, 0]);
  return (
    <>
      <div
        style={{
          position: 'absolute',
          left: x - size / 2,
          top: y - size / 2,
          width: size,
          height: size,
          borderRadius: '50%',
          border: '8px solid rgba(255,255,255,0.95)',
          transform: `scale(${scale})`,
          opacity,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: x - size * 0.22,
          top: y - size * 0.22,
          width: size * 0.44,
          height: size * 0.44,
          borderRadius: '50%',
          background: 'rgba(255,255,255,0.75)',
          opacity: interpolate(t, [0, 4, 12], [0, 1, 0], {extrapolateRight: 'clamp'}),
        }}
      />
    </>
  );
};
