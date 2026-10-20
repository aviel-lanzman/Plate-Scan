import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {CarScene} from './components/CarScene';
import {demoPlate} from './theme';

/** Stands in for the frames the app saves while scanning (720x1280). */
export const CarPhoto: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{background: '#000'}}>
      <CarScene
        plate={demoPlate}
        zoom={1 + frame * 0.003}
        shiftX={Math.sin(frame / 9) * 18}
        shiftY={-frame * 0.6}
        time={frame / 30}
      />
    </AbsoluteFill>
  );
};
