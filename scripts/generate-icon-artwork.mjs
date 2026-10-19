// Generates app icon artwork candidates (the cup on a transparent background)
// with an image model through OpenRouter's Image API. The prompt follows the
// SnapAI approach (https://github.com/betomoedano/snapai) but is written out
// here, so nothing is fetched from npm. Plain Node, no dependencies.
//
// Setup: put OPENROUTER_API_KEY=... in .env.icons.local at the repo root
//        (gitignored; never commit it).
// Run:   node --env-file=.env.icons.local scripts/generate-icon-artwork.mjs [--n 3]
// Then:  pick a candidate from build/icon-candidates/ and pass it to
//        `swift scripts/make-icon.swift --artwork <png>`.
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

const { values } = parseArgs({
  options: {
    n: { type: 'string', default: '3' },
    model: { type: 'string', default: 'openai/gpt-image-1' },
    prompt: { type: 'string' },
  },
});

const prompt =
  values.prompt ??
  [
    'App icon artwork for "Awake", a macOS menu bar utility that keeps the Mac awake.',
    'Subject: a single cream-white glossy ceramic coffee cup on a matching saucer, seen slightly from above,',
    'filled with dark espresso with a thin caramel crema ring, and three soft, elegant wisps of white steam rising from it.',
    'Style: modern, premium macOS app icon illustration; smooth rounded 3D forms with soft studio lighting,',
    'subtle specular highlights on the glaze, gentle soft shadows; simple shapes with no fine detail,',
    'so the silhouette stays readable at 32 pixels. Warm palette: cream, espresso brown, amber and caramel accents.',
    'Composition: centred, the cup, saucer and steam together fill about 80% of the canvas with even margins.',
    'Transparent background: no backdrop, no rounded-square tile, no frame, no glow or halo, no cast shadow on a floor,',
    'no text, no letters, no logos.',
  ].join(' ');

const apiKey = process.env.OPENROUTER_API_KEY;
if (!apiKey) throw new Error('Missing OPENROUTER_API_KEY (put it in .env.icons.local)');

const response = await fetch('https://openrouter.ai/api/v1/images', {
  method: 'POST',
  headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({
    model: values.model,
    prompt,
    n: Number(values.n),
    aspect_ratio: '1:1',
    quality: 'high',
    background: 'transparent',
    output_format: 'png',
  }),
});
if (!response.ok) throw new Error(`OpenRouter ${response.status}: ${await response.text()}`);
const { data, usage } = await response.json();

const dir = join(root, 'build/icon-candidates');
await mkdir(dir, { recursive: true });
const stamp = new Date().toISOString().replace(/[:.]/g, '-');
for (const [index, image] of data.entries()) {
  const file = join(dir, `${stamp}-${index + 1}.png`);
  await writeFile(file, Buffer.from(image.b64_json, 'base64'));
  console.log(file);
}
if (usage?.cost !== undefined) console.log(`Cost: $${usage.cost}`);
