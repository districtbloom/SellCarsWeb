import { readFile, writeFile, mkdir } from 'node:fs/promises';
const reference = new URL('../reference/roblox/', import.meta.url);
const extract = async path => {
  const source = await readFile(new URL(path, reference), 'utf8');
  const match = /\[====\[([\s\S]*?)\]====\]/.exec(source);
  if (!match) throw new Error(`No embedded data in ${path}`);
  return JSON.parse(match[1]);
};
await mkdir(new URL('../src/world/tycoon/', import.meta.url), { recursive: true });
await mkdir(new URL('../public/tycoon/', import.meta.url), { recursive: true });
const hub = await extract('ReplicatedStorage/HubSlice/HubData.luau');
await writeFile(new URL('../src/world/tycoon/catalog.ts', import.meta.url), '// Exact embedded HubData from Sell Cars Integration; regenerate with npm run tycoon:data.\nimport type { Catalog } from \'./types.js\';\nexport const catalog: Catalog = '+JSON.stringify(hub,null,2)+';\n');
for (const [name,path] of [['journey','ReplicatedStorage/SellCarsV5FullJourneyData.luau'],['benefits','ReplicatedStorage/SellCarsV5PurchaseBenefits.luau']]) {
  await writeFile(new URL(`../public/tycoon/${name}.json`, import.meta.url), JSON.stringify(await extract(path)));
}
console.log(`Extracted ${hub.pads.length} pads and ${hub.cars.length} cars, plus full journey and benefits.`);
