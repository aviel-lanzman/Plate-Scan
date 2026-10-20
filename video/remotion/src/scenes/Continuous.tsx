import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {AppBar, APP_BAR_H} from '../components/AppBar';
import {CarScene} from '../components/CarScene';
import {CheckCircle, Dangerous, NoCrash} from '../components/icons';
import {PlateBadge} from '../components/PlateBadge';
import {APP_H, SCREEN_W} from '../components/Phone';
import {PhoneStage} from '../components/PhoneStage';
import {fontFamily} from '../fonts';
import {demoPlate} from '../theme';

const STRIP_H = 99;
const REST = APP_H - APP_BAR_H - STRIP_H;
const CAMERA_H = (REST * 3) / 5;
const SEEN_AT = 18;
const ALERT_AT = 45;

type Row = {plate: string; status?: 'off' | 'ok'; summary?: string; time: string};

const StatusText: React.FC<{status?: Row['status']}> = ({status}) => {
  if (!status) {
    return (
      <div style={{display: 'flex', alignItems: 'center', gap: 18, fontSize: 42, color: '#E3E2E9'}}>
        <div
          style={{
            width: 42,
            height: 42,
            borderRadius: 21,
            border: '6px solid #B7C4FF',
            borderTopColor: 'transparent',
          }}
        />
        בודק...
      </div>
    );
  }
  // The app lightens status colours in dark mode.
  const color = status === 'off' ? '#E78D8D' : '#8CB88E';
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: 12, fontSize: 42, fontWeight: 700, color}}>
      {status === 'off' ? <Dangerous size={54} color={color} inner="#1A1B21" /> : <CheckCircle size={54} color={color} />}
      {status === 'off' ? 'ירד מהכביש' : 'רכב פעיל'}
    </div>
  );
};

const Tile: React.FC<{row: Row; flash: number}> = ({row, flash}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 36,
      padding: '30px 48px',
      borderBottom: '3px solid #45464F',
      background: `rgba(211,47,47,${flash * 0.25})`,
    }}
  >
    <PlateBadge plate={row.plate} height={73} />
    <div style={{flex: 1, display: 'flex', flexDirection: 'column', gap: 4}}>
      <StatusText status={row.status} />
      {row.summary && (
        <div
          style={{
            fontSize: 42,
            color: '#E3E2E9',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            maxWidth: 560,
          }}
        >
          {row.summary}
        </div>
      )}
      <div style={{fontSize: 36, color: '#C5C6D0'}}>{row.time}</div>
    </div>
  </div>
);

/** Continuous mode: plates are checked as they pass and alerts pop up. */
export const Continuous: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const banner = spring({frame: frame - ALERT_AT, fps, config: {damping: 14}});
  const shake =
    frame >= ALERT_AT && frame < ALERT_AT + 24
      ? Math.sin((frame - ALERT_AT) * 2.4) * 14 * (1 - (frame - ALERT_AT) / 24)
      : 0;
  const rows: Row[] = [
    ...(frame >= SEEN_AT
      ? [
          {
            plate: demoPlate,
            status: frame >= ALERT_AT ? ('off' as const) : undefined,
            summary: frame >= ALERT_AT ? 'יונדאי קוריאה I20, אפור מטאלי, 2012' : undefined,
            time: '09:40:12',
          },
        ]
      : []),
    {plate: '98-765-41', status: 'ok', summary: 'קיה פיקנטו, לבן, 2019', time: '09:39:58'},
    {plate: '987-65-432', status: 'ok', summary: 'סקודה אוקטביה, כסף, 2021', time: '09:39:41'},
  ];
  const flash = frame >= ALERT_AT ? interpolate(frame, [ALERT_AT, ALERT_AT + 30], [1, 0], {extrapolateRight: 'clamp'}) : 0;
  return (
    <PhoneStage
      shakeX={shake}
      cues={[
        {from: 0, title: 'סריקה רציפה לנוסעים', subtitle: 'כל לוחית שעוברת מול המצלמה נבדקת'},
        {from: ALERT_AT, title: 'רכב שירד מהכביש? התרעה מיד', subtitle: 'ברטט, בצליל ובבאנר'},
      ]}
    >
      <AppBar title="סריקה רציפה" trailing={`${rows.length} לוחיות`} />
      <div
        style={{
          position: 'absolute',
          top: APP_BAR_H,
          width: SCREEN_W,
          height: STRIP_H,
          background: '#FFA000',
          display: 'flex',
          alignItems: 'center',
          gap: 24,
          padding: '0 36px',
          direction: 'rtl',
          fontFamily,
          fontSize: 42,
          color: '#000',
        }}
      >
        <NoCrash size={72} color="#000" />
        לשימוש נוסע בלבד. אין להפעיל בזמן נהיגה.
      </div>
      <div
        style={{
          position: 'absolute',
          top: APP_BAR_H + STRIP_H,
          width: SCREEN_W,
          height: CAMERA_H,
          overflow: 'hidden',
        }}
      >
        <CarScene
          plate={demoPlate}
          zoom={interpolate(frame, [0, 150], [1.15, 1.45])}
          shiftY={Math.sin(frame / 4) * 3 + 120}
          shiftX={Math.sin(frame / 17) * 20}
          time={frame / 30}
        />
        <div
          style={{
            position: 'absolute',
            top: 24,
            left: 24,
            right: 24,
            transform: `translateY(${(1 - banner) * -420}px)`,
            opacity: frame >= ALERT_AT ? 1 : 0,
            background: '#D32F2F',
            borderRadius: 36,
            padding: 36,
            display: 'flex',
            alignItems: 'center',
            gap: 36,
            direction: 'rtl',
            fontFamily,
            color: '#fff',
            boxShadow: '0 18px 50px rgba(0,0,0,0.5)',
          }}
        >
          <Dangerous size={108} color="#fff" />
          <div>
            <div style={{fontSize: 54, fontWeight: 700}}>{demoPlate}: ירד מהכביש</div>
            <div style={{fontSize: 42}}>הקש לפרטים ולדיווח</div>
          </div>
        </div>
      </div>
      <div
        style={{
          position: 'absolute',
          top: APP_BAR_H + STRIP_H + CAMERA_H,
          width: SCREEN_W,
          height: REST - CAMERA_H,
          background: '#121318',
          direction: 'rtl',
          fontFamily,
          overflow: 'hidden',
        }}
      >
        {rows.map((row, i) => (
          <Tile key={row.plate} row={row} flash={i === 0 && row.plate === demoPlate ? flash : 0} />
        ))}
      </div>
    </PhoneStage>
  );
};
