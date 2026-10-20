import React from 'react';
import {fontFamily} from '../fonts';

// The app is drawn at 1080x2340 device pixels (360x780dp at 3x): a 72px
// status bar, then 2268px of app, which is what the screenshots cover.
export const SCREEN_W = 1080;
export const SCREEN_H = 2340;
export const STATUS_H = 72;
export const APP_H = SCREEN_H - STATUS_H;

const StatusBar: React.FC<{color: string}> = ({color}) => (
  <div
    style={{
      position: 'absolute',
      top: 0,
      left: 0,
      width: SCREEN_W,
      height: STATUS_H,
      background: color,
      color: '#fff',
      fontFamily,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 48px',
      fontSize: 36,
      fontWeight: 500,
    }}
  >
    <div style={{display: 'flex', gap: 14, alignItems: 'center'}}>
      {/* battery, wifi, signal */}
      <div style={{width: 52, height: 26, border: '3px solid #fff', borderRadius: 7, padding: 3}}>
        <div style={{width: '75%', height: '100%', background: '#fff', borderRadius: 2}} />
      </div>
      <svg width={36} height={36} viewBox="0 0 24 24">
        <path fill="#fff" d="M12 21 1 8.5C4 5.9 7.9 4.5 12 4.5s8 1.4 11 4z" />
      </svg>
      <svg width={36} height={36} viewBox="0 0 24 24">
        <path fill="#fff" d="M2 22h20V2z" />
      </svg>
    </div>
    <div>9:41</div>
  </div>
);

/** A phone with the given app content filling the screen below the status bar. */
export const Phone: React.FC<{
  width: number;
  statusColor?: string;
  children: React.ReactNode;
}> = ({width, statusColor = '#121318', children}) => {
  const scale = width / SCREEN_W;
  const height = width * (SCREEN_H / SCREEN_W);
  const bezel = width * 0.032;
  return (
    <div
      style={{
        width: width + bezel * 2,
        height: height + bezel * 2,
        borderRadius: (width + bezel * 2) * 0.13,
        background: 'linear-gradient(150deg, #3a3f4a 0%, #14161b 45%, #0a0b0e 100%)',
        padding: bezel,
        boxShadow:
          '0 60px 140px rgba(0,0,0,0.6), 0 0 0 2px rgba(255,255,255,0.08), inset 0 0 0 2px rgba(255,255,255,0.12)',
      }}
    >
      <div
        style={{
          width,
          height,
          borderRadius: width * 0.105,
          overflow: 'hidden',
          position: 'relative',
          background: '#000',
        }}
      >
        <div
          style={{
            position: 'absolute',
            width: SCREEN_W,
            height: SCREEN_H,
            transform: `scale(${scale})`,
            transformOrigin: 'top left',
          }}
        >
          <StatusBar color={statusColor} />
          <div
            style={{
              position: 'absolute',
              top: STATUS_H,
              width: SCREEN_W,
              height: APP_H,
              overflow: 'hidden',
            }}
          >
            {children}
          </div>
          <div
            style={{
              position: 'absolute',
              top: 18,
              left: SCREEN_W / 2 - 18,
              width: 36,
              height: 36,
              borderRadius: 18,
              background: '#050506',
            }}
          />
        </div>
      </div>
    </div>
  );
};
