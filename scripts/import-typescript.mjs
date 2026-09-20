import { readFile, writeFile } from 'node:fs/promises';
import { mkdtempSync, unlinkSync, rmdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { pathToFileURL, fileURLToPath } from 'node:url';
import ts from 'typescript';

const compiled = new Map();
const directory = mkdtempSync(join(tmpdir(), 'sell-cars-ts-'));
process.on('exit', () => {
  // Remove only the files created by this test process, then its empty directory.
  for (const url of compiled.values()) { try { unlinkSync(fileURLToPath(url)); } catch {} }
  try { rmdirSync(directory); } catch {}
});

// Reuse source modules in the generator and Node tests without another runtime.
async function compileTypescript(url) {
  if (compiled.has(url.href)) return compiled.get(url.href);
  const compiledUrl = pathToFileURL(join(directory, 'module-' + compiled.size + '.mjs')).href;
  compiled.set(url.href, compiledUrl);
  let code = ts.transpileModule(await readFile(url, 'utf8'), {
    compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.ES2020 },
  }).outputText;
  // Browser-only stylesheet side effects have no role in Node gameplay tests.
  code = code.replace(/^import\s+['"][^'"]+\.css['"];?\s*$/gm, '');
  for (const match of [...code.matchAll(/from (['"])([^'"]+)\1/g)]) {
    const [statement, quote, specifier] = match;
    const resolved = specifier.startsWith('.')
      ? await compileTypescript(new URL(specifier.replace(/\.js$/, '.ts'), url))
      : import.meta.resolve(specifier);
    code = code.replace(statement, `from ${quote}${resolved}${quote}`);
  }
  await writeFile(new URL(compiledUrl), code);
  return compiledUrl;
}

export async function importTypescript(url) {
  return import(await compileTypescript(url));
}
