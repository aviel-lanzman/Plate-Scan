import React from 'react';

// Simple stand-ins for the Material icons the app uses, as inline SVG.
type P = {size: number; color: string};

export const ArrowForward: React.FC<P> = ({size, color}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path fill={color} d="M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8z" />
  </svg>
);

export const Check: React.FC<P> = ({size, color}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path fill={color} d="M9 16.17 4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
  </svg>
);

export const Close: React.FC<P> = ({size, color}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path
      fill={color}
      d="M19 6.41 17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"
    />
  </svg>
);

/** Icons.dangerous: an octagon with an X. */
export const Dangerous: React.FC<P & {inner?: string}> = ({size, color, inner = '#D32F2F'}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path fill={color} d="M15.73 3H8.27L3 8.27v7.46L8.27 21h7.46L21 15.73V8.27z" />
    <path
      fill={inner}
      d="M16.24 14.83l-1.41 1.41L12 13.41l-2.83 2.83-1.41-1.41L10.59 12 7.76 9.17l1.41-1.41L12 10.59l2.83-2.83 1.41 1.41L13.41 12z"
    />
  </svg>
);

export const CheckCircle: React.FC<P> = ({size, color}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path
      fill={color}
      d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"
    />
  </svg>
);

export const NoCrash: React.FC<P> = ({size, color}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path
      fill={color}
      d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"
    />
  </svg>
);
