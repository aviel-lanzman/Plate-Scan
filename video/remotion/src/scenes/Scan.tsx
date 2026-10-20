import React from 'react';
import {Easing, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {AppBar, APP_BAR_H} from '../components/AppBar';
import {CarScene} from '../components/CarScene';
import {Check, Close} from '../components/icons';
import {PlateBadge} from '../components/PlateBadge';
import {APP_H, SCREEN_W} from '../components/Phone';
import {PhoneStage} from '../components/PhoneStage';
import {Tap} from '../components/Tap';
import {fontFamily} from '../fonts';
import {demoPlate} from '../theme';

const CAMERA_H = APP_H - APP_BAR_H;
const FRAME_W = SCREEN_W * 0.85;
const FRAME_H = FRAME_W / 4.7;
const FRAME_TOP = APP_BAR_H + (CAMERA_H - FRAME_H) / 2;
const CARD_AT = 95;
const TAP_AT = 160;

/** Point-and-shoot: aim, the plate is read on the phone, confirm it. */
export const Scan: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const zoom = interpolate(frame, [0, 90], [1.5, 2.25], {
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  const beam = interpolate(frame, [45, 85], [FRAME_W, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.inOut(Easing.quad),
  });
  const card = spring({frame: frame - CARD_AT, fps, config: {damping: 15}});
  const pressed = frame >= TAP_AT && frame < TAP_AT + 6;
  return (
    <PhoneStage
      cues={[
        {from: 0, title: 'מכוונים את המצלמה ללוחית', subtitle: 'הזיהוי רץ בטלפון עצמו'},
        {from: CARD_AT, title: 'המספר מזוהה תוך רגע', subtitle: 'ומאשרים אותו בלחיצה'},
      ]}
    >
      <div style={{position: 'absolute', top: APP_BAR_H, width: SCREEN_W, height: CAMERA_H}}>
        <CarScene
          plate={demoPlate}
          zoom={zoom}
          shiftX={Math.sin(frame / 11) * 10}
          shiftY={Math.cos(frame / 13) * 8}
          time={frame / 30}
        />
      </div>
      <AppBar title="כוון וצלם" />
      {/* Aiming frame and the reading beam */}
      <div
        style={{
          position: 'absolute',
          top: FRAME_TOP,
          left: (SCREEN_W - FRAME_W) / 2,
          width: FRAME_W,
          height: FRAME_H,
          border: '9px solid #fff',
          borderRadius: 24,
          overflow: 'hidden',
        }}
      >
        {frame >= 45 && frame <= 88 && (
          <div
            style={{
              position: 'absolute',
              top: 0,
              bottom: 0,
              left: beam - 12,
              width: 24,
              background: 'rgba(140,255,200,0.95)',
              boxShadow: '0 0 40px 16px rgba(140,255,200,0.6)',
            }}
          />
        )}
      </div>
      <div
        style={{
          position: 'absolute',
          top: APP_BAR_H + 48,
          width: SCREEN_W,
          display: 'flex',
          justifyContent: 'center',
        }}
      >
        <div
          style={{
            background: 'rgba(0,0,0,0.54)',
            borderRadius: 60,
            padding: '24px 48px',
            color: '#fff',
            fontSize: 48,
            fontFamily,
            direction: 'rtl',
          }}
        >
          כוון את המצלמה ללוחית הרישוי
        </div>
      </div>
      {/* The reading card from the app */}
      <div
        style={{
          position: 'absolute',
          left: 48,
          right: 48,
          bottom: 48,
          transform: `translateY(${(1 - card) * 640}px)`,
          background: '#1A1B21',
          borderRadius: 36,
          padding: 48,
          direction: 'rtl',
          fontFamily,
          color: '#E3E2E9',
          boxShadow: '0 12px 40px rgba(0,0,0,0.45)',
        }}
      >
        <div style={{fontSize: 42}}>מזהה מספר. האם זה המספר שעל הרכב?</div>
        <div style={{display: 'flex', justifyContent: 'center', margin: '28px 0 36px'}}>
          <PlateBadge plate={demoPlate} height={127} />
        </div>
        <div style={{display: 'flex', gap: 24}}>
          <div
            style={{
              flex: 1,
              height: 120,
              borderRadius: 60,
              background: pressed ? '#9fb2f5' : '#B7C4FF',
              color: '#132a6b',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 18,
              fontSize: 44,
              fontWeight: 500,
              transform: `scale(${pressed ? 0.96 : 1})`,
            }}
          >
            <Check size={54} color="#132a6b" />
            זה המספר
          </div>
          <div
            style={{
              flex: 1,
              height: 120,
              borderRadius: 60,
              border: '3px solid #90909A',
              color: '#B7C4FF',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 18,
              fontSize: 44,
              fontWeight: 500,
            }}
          >
            <Close size={54} color="#B7C4FF" />
            לא המספר
          </div>
        </div>
      </div>
      <Tap x={768} y={APP_H - 48 - 48 - 60} at={TAP_AT} />
    </PhoneStage>
  );
};
