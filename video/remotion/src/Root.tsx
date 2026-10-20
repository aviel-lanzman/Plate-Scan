import React from 'react';
import {Composition} from 'remotion';
import './fonts';
import {CarPhoto} from './CarPhoto';
import {Demo, DEMO_FRAMES} from './Demo';
import {Continuous} from './scenes/Continuous';
import {RESULT_FLOW_FRAMES, ResultFlow} from './scenes/ResultFlow';
import {Scan} from './scenes/Scan';

const video = {fps: 30, width: 1080, height: 1350};

export const Root: React.FC = () => (
  <>
    <Composition id="PlateScanDemo" component={Demo} durationInFrames={DEMO_FRAMES} {...video} />
    {/* Single scenes, for previewing. */}
    <Composition id="Scan" component={Scan} durationInFrames={210} {...video} />
    <Composition id="ResultFlow" component={ResultFlow} durationInFrames={RESULT_FLOW_FRAMES} {...video} />
    <Composition id="Continuous" component={Continuous} durationInFrames={150} {...video} />
    <Composition id="CarPhoto" component={CarPhoto} durationInFrames={60} fps={30} width={720} height={1280} />
  </>
);
