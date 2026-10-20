import React from 'react';
import {AbsoluteFill, OffthreadVideo, staticFile} from 'remotion';
import {linearTiming, TransitionSeries} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {Continuous} from './scenes/Continuous';
import {RESULT_FLOW_FRAMES, ResultFlow} from './scenes/ResultFlow';
import {Scan} from './scenes/Scan';

// Intro and outro are HyperFrames renders (video/hyperframes); the app
// scenes are Remotion. Durations are in frames at 30 fps.
const scenes = [
  {frames: 120, node: <OffthreadVideo src={staticFile('hf/intro.mp4')} muted />},
  {frames: 210, node: <Scan />},
  {frames: RESULT_FLOW_FRAMES, node: <ResultFlow />},
  {frames: 150, node: <Continuous />},
  {frames: 150, node: <OffthreadVideo src={staticFile('hf/outro.mp4')} muted />},
];
const FADE = 12;

export const DEMO_FRAMES =
  scenes.reduce((sum, s) => sum + s.frames, 0) - FADE * (scenes.length - 1);

export const Demo: React.FC = () => (
  <AbsoluteFill style={{background: '#061033'}}>
    <TransitionSeries>
      {scenes.map((scene, i) => (
        <React.Fragment key={i}>
          {i > 0 && (
            <TransitionSeries.Transition
              presentation={fade()}
              timing={linearTiming({durationInFrames: FADE})}
            />
          )}
          <TransitionSeries.Sequence durationInFrames={scene.frames}>
            {scene.node}
          </TransitionSeries.Sequence>
        </React.Fragment>
      ))}
    </TransitionSeries>
  </AbsoluteFill>
);
