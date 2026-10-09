import { access, cp, mkdir, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const frontendDirectory = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sourceDirectory = path.join(frontendDirectory, 'dist');
const terraformDirectory = path.resolve(
  frontendDirectory,
  '..',
  '..',
  'secure-3tier-cloud-app',
  'infrastructure',
);
const destinationDirectory = path.join(terraformDirectory, 'dist');

await access(sourceDirectory);
await mkdir(terraformDirectory, { recursive: true });
await rm(destinationDirectory, { recursive: true, force: true });
await cp(sourceDirectory, destinationDirectory, { recursive: true });

console.log(`Copied ${sourceDirectory} to ${destinationDirectory}`);
