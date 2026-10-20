import React from 'react';
import {AbsoluteFill, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {Backdrop} from './Backdrop';
import {CaptionCue, Captions} from './Caption';
import {Phone, SCREEN_W} from './Phone';

export const PHONE_W = 460;
const BEZEL = PHONE_W * 0.032;
const SCALE = PHONE_W / SCREEN_W;

/**
 * Backdrop, captions and a phone that slides up on entry. [zoom] scales the
 * phone around [focusY] (device pixels from the top of the screen), so the
 * point being explained stays put while it grows.
 */
export const PhoneStage: React.FC<{
  cues: CaptionCue[];
  zoom?: number;
  focusY?: number;
  shakeX?: number;
  statusColor?: string;
  children: React.ReactNode;
}> = ({cues, zoom = 1, focusY = 1170, shakeX = 0, statusColor, children}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const enter = spring({frame, fps, config: {damping: 18, mass: 0.9}});
  const outerW = PHONE_W + BEZEL * 2;
  return (
    <AbsoluteFill>
      <Backdrop />
      <div
        style={{
          position: 'absolute',
          left: (1080 - outerW) / 2,
          top: 318,
          transform: `translate(${shakeX}px, ${(1 - enter) * 260}px) scale(${zoom})`,
          transformOrigin: `${outerW / 2}px ${BEZEL + focusY * SCALE}px`,
          opacity: enter,
        }}
      >
        <Phone width={PHONE_W} statusColor={statusColor}>
          {children}
        </Phone>
      </div>
      <Captions cues={cues} />
    </AbsoluteFill>
  );
};
