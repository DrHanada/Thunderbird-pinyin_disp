import { cp, mkdir, readFile, readdir, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";
import { zipSync } from "fflate";

const root = path.dirname(fileURLToPath(import.meta.url));
const dist = path.join(root, "dist");
const manifest = JSON.parse(await readFile(path.join(root, "manifest.json"), "utf8"));

await rm(dist, { recursive: true, force: true });
await mkdir(path.join(dist, "vendor"), { recursive: true });

for (const file of ["manifest.json", "background.js", "content.js", "LICENSE", "THIRD_PARTY_NOTICES.md"]) {
  await cp(path.join(root, file), path.join(dist, file));
}

async function copyTree(source, destination) {
  await mkdir(destination, { recursive: true });
  for (const entry of await readdir(source, { withFileTypes: true })) {
    const sourcePath = path.join(source, entry.name);
    const destinationPath = path.join(destination, entry.name);
    if (entry.isDirectory()) {
      await copyTree(sourcePath, destinationPath);
    } else if (entry.isFile()) {
      await cp(sourcePath, destinationPath);
    }
  }
}

await copyTree(path.join(root, "_locales"), path.join(dist, "_locales"));

// Bundle the declared npm dependency into the runtime file shipped in the XPI.
await build({
  entryPoints: [path.join(root, "node_modules", "pinyin-pro", "dist", "index.js")],
  bundle: true,
  format: "iife",
  globalName: "pinyinPro",
  platform: "browser",
  target: ["firefox128"],
  outfile: path.join(dist, "vendor", "pinyin-pro.js")
});

const files = {};
async function addFiles(directory, relativeDirectory = "") {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const absolutePath = path.join(directory, entry.name);
    const relativePath = relativeDirectory
      ? `${relativeDirectory}/${entry.name}`
      : entry.name;
    if (entry.isDirectory()) {
      await addFiles(absolutePath, relativePath);
    } else if (entry.isFile()) {
      files[relativePath] = new Uint8Array(await readFile(absolutePath));
    }
  }
}

await addFiles(dist);
const xpi = zipSync(files, { level: 9 });
const xpiPath = path.join(dist, `thunderbird-pinyin-display-${manifest.version}.xpi`);
await (await import("node:fs/promises")).writeFile(xpiPath, xpi);

console.log(`Built ${xpiPath}`);
console.log("The source archive must contain the readable source and package files, not this generated XPI.");
