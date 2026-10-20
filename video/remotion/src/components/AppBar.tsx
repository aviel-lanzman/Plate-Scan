import React from 'react';
import {fontFamily} from '../fonts';
import {ArrowForward} from './icons';

export const APP_BAR_H = 168;

/** The app's top bar (56dp) with the back arrow on the right, as in RTL. */
export const AppBar: React.FC<{title: string; trailing?: string}> = ({title, trailing}) => (
  <div
    style={{
      position: 'absolute',
      top: 0,
      left: 0,
      right: 0,
      height: APP_BAR_H,
      background: '#121318',
      display: 'flex',
      alignItems: 'center',
      direction: 'rtl',
      fontFamily,
      color: '#E3E2E9',
      padding: '0 36px',
      gap: 60,
    }}
  >
    <ArrowForward size={72} color="#E3E2E9" />
    <div style={{fontSize: 66, fontWeight: 400, flex: 1}}>{title}</div>
    {trailing && <div style={{fontSize: 42}}>{trailing}</div>}
  </div>
);
