import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {fontFamily} from '../fonts';
import {colors} from '../theme';

export type CaptionCue = {from: number; title: string; subtitle?: string};

/**
 * The headline above the phone. Each cue rises in at its frame and the
 * previous one fades out.
 */
export const Captions: React.FC<{cues: CaptionCue[]}> = ({cues}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: 340,
        paddingTop: 64,
        zIndex: 10,
        // Solid behind the text, so a zoomed-in phone never shows through.
        background:
          'linear-gradient(180deg, #061033 0%, #061033 76%, rgba(6,16,51,0) 100%)',
      }}
    >
      {cues.map((cue, i) => {
        const next = cues[i + 1];
        const enter = spring({frame: frame - cue.from, fps, config: {damping: 16}});
        const exit = next ? interpolate(frame, [next.from - 8, next.from], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}) : 1;
        if (frame < cue.from || exit === 0) return null;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: 60,
              right: 60,
              textAlign: 'center',
              direction: 'rtl',
              fontFamily,
              opacity: enter * exit,
              transform: `translateY(${(1 - enter) * 40}px)`,
            }}
          >
            <div style={{fontSize: 68, fontWeight: 800, color: colors.text, lineHeight: 1.15}}>
              {cue.title}
            </div>
            {cue.subtitle && (
              <div style={{fontSize: 40, fontWeight: 500, color: colors.textMuted, marginTop: 14}}>
                {cue.subtitle}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
};
