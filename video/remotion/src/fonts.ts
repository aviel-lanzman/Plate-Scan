import {loadFont} from '@remotion/fonts';
import {staticFile} from 'remotion';

// Heebo (SIL OFL), static instances made from the variable font in
// video/assets/fonts. The same files render the app screenshots.
export const fontFamily = 'Heebo';

const weights = [
  ['Regular', '400'],
  ['Medium', '500'],
  ['Bold', '700'],
  ['ExtraBold', '800'],
  ['Black', '900'],
] as const;

for (const [name, weight] of weights) {
  loadFont({
    family: fontFamily,
    url: staticFile(`fonts/Heebo-${name}.ttf`),
    weight,
  });
}
