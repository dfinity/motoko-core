// Generate a test file named `ImportAll.test.mo`

import { join, resolve } from "path";
import { existsSync, writeFileSync, mkdirSync } from "fs";
import glob from "fast-glob";
import execa from "execa";

const outDir = resolve(__dirname, "../generated");
if (!existsSync(outDir)) {
  mkdirSync(outDir);
}

const baseFilename = "ImportAll.test";
const outFile = resolve(outDir, `${baseFilename}.mo`);

const moFiles = glob.sync("**/*.mo", { cwd: resolve(__dirname, "../../src") });
if (moFiles.length === 0) {
  throw new Error("Expected at least one Motoko file in `src` directory");
}
const source = moFiles
  .map((f) => {
    const name = f.replace(/\.mo$/, "");
    return `import _${name.replace("/", "_")} "../../src/${name}";\n`;
  })
  .join("");

writeFileSync(outFile, source, "utf8");

(async () => {
  const mocPath = process.env.DFX_MOC_PATH || "moc";
  const wasmFile = join(outDir, `${baseFilename}.wasm`);
  const { stdout, stderr } = await execa(
    mocPath,
    [
      outFile,
      "--hide-warnings",
      "-wasi-system-api",
      "--experimental-stable-memory",
      "1",
      "-o",
      wasmFile,
    ],
    {
      stdio: "pipe",
      encoding: "utf8",
    }
  );
  console.log(stdout);
  if (stderr.trim()) {
    throw new Error(`Warning message while importing modules:\n${stderr}`);
  }
})();
