import React from 'react';
import {Easing, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {APP_H, SCREEN_W, STATUS_H} from '../components/Phone';
import {PhoneStage} from '../components/PhoneStage';
import {Tap} from '../components/Tap';
import layout from '../../public/screens/result_layout.json';

// The result screen is one tall screenshot (video/flutter_shots); the
// layout file says where each card is in it.
const BAR = layout.appBarHeight;
const VIEW_H = APP_H - BAR;
const reportFocus = (layout.call.centerY + layout.photos.bottom + 250) / 2;

// [start frame, scroll, focused content y, zoom]
const keys: [number, number, number, number][] = [
  [0, 0, layout.status.centerY, 1],
  [40, 0, layout.status.centerY, 1.22],
  [150, 0, layout.vehicle.centerY, 1.22],
  [270, layout.stolen.centerY - (BAR + VIEW_H / 2), layout.stolen.centerY, 1.22],
  [390, reportFocus - (BAR + VIEW_H / 2), reportFocus, 1.12],
];

const CALL_AT = 440;
const SHARE_AT = 498;

export const RESULT_FLOW_FRAMES = 540;

/** Scrolls through the result: status, vehicle, stolen check, reporting. */
export const ResultFlow: React.FC = () => {
  const frame = useCurrentFrame();
  const track = (i: 1 | 2 | 3) => {
    // Ease from each key to the next over 30 frames.
    const points = keys.flatMap(([at, ...v], k) =>
      k === 0 ? [[at, v[i - 1]]] : [[at, keys[k - 1][i]], [at + 30, v[i - 1]]],
    );
    return interpolate(
      frame,
      points.map((p) => p[0]),
      points.map((p) => p[1]),
      {extrapolateRight: 'clamp', easing: Easing.inOut(Easing.cubic)},
    );
  };
  const scroll = track(1);
  const focus = track(2);
  const zoom = track(3);
  return (
    <PhoneStage
      zoom={zoom}
      focusY={STATUS_H + focus - scroll}
      cues={[
        {from: 0, title: 'בדיקה תוך שניות', subtitle: 'מול מאגרי משרד התחבורה'},
        {from: 150, title: 'פרטי הרכב לא תואמים?', subtitle: 'ייתכן שהלוחית מזויפת'},
        {from: 270, title: 'בדיקת גניבה באתר המשטרה', subtitle: 'המספר ממולא אוטומטית'},
        {from: 390, title: 'חייגו 100, או שמרו תיעוד', subtitle: 'עם מיקום ותמונות מהסריקה'},
      ]}
    >
      <div style={{position: 'absolute', top: BAR, width: SCREEN_W, height: VIEW_H, overflow: 'hidden'}}>
        <Img
          src={staticFile('screens/result_full.png')}
          style={{position: 'absolute', top: -BAR - scroll, width: SCREEN_W}}
        />
      </div>
      <div style={{position: 'absolute', top: 0, width: SCREEN_W, height: BAR, overflow: 'hidden'}}>
        <Img src={staticFile('screens/result_full.png')} style={{width: SCREEN_W}} />
      </div>
      <Tap x={layout.call.centerX} y={layout.call.centerY - keys[4][1]} at={CALL_AT} />
      <Tap x={layout.share.centerX} y={layout.share.centerY - keys[4][1]} at={SHARE_AT} />
    </PhoneStage>
  );
};
