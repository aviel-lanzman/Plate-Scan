import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {colors} from '../theme';

/** The navy background shared with the HyperFrames intro and outro. */
export const Backdrop: React.FC = () => {
  const frame = useCurrentFrame();
  const drift = interpolate(frame, [0, 600], [0, 60]);
  return (
    <AbsoluteFill
      style={{
        background: `radial-gradient(120% 80% at 50% 20%, ${colors.navyLight} 0%, ${colors.navy} 60%, #030a22 100%)`,
      }}
    >
      <div
        style={{
          position: 'absolute',
          width: 1000,
          height: 1000,
          left: 40 + drift,
          top: 260,
          borderRadius: '50%',
          background:
            'radial-gradient(circle, rgba(0,92,255,0.35) 0%, rgba(0,56,184,0) 65%)',
        }}
      />
    </AbsoluteFill>
  );
};
