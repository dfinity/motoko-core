import { readFile } from "fs/promises";
import { join } from "path";

const rootDirectory = join(__dirname, "../../..");

async function getMopsVersion(): Promise<string> {
  const mopsContent = await readFile(join(rootDirectory, "mops.toml"), "utf-8");
  const versionMatch = mopsContent.match(/version\s*=\s*"([^"]+)"/);
  if (!versionMatch) {
    throw new Error("Could not find package version in mops.toml");
  }
  return versionMatch[1];
}

async function getMocVersion(): Promise<string> {
  const mopsContent = await readFile(join(rootDirectory, "mops.toml"), "utf-8");
  const mocMatch = mopsContent.match(/moc\s*=\s*"([^"]+)"/);
  if (!mocMatch) {
    throw new Error("Could not find 'moc' version in mops.toml");
  }
  return mocMatch[1];
}

async function getReadmeVersions(): Promise<{
  core: string;
}> {
  const readmeContent = await readFile(
    join(rootDirectory, "README.md"),
    "utf-8"
  );
  const coreMatch = readmeContent.match(/core\s*=\s*"(\d+\.\d+\.\d+)"/);
  if (!coreMatch) {
    throw new Error("Could not find 'core' version in README.md");
  }
  return {
    core: coreMatch[1],
  };
}

async function main() {
  try {
    const [mopsVersion, mocVersion, readmeVersions] = await Promise.all([
      getMopsVersion(),
      getMocVersion(),
      getReadmeVersions(),
    ]);
    if (mopsVersion !== readmeVersions.core) {
      throw new Error(
        `Version mismatch: mops.toml version (${mopsVersion}) does not match 'core' version in README.md (${readmeVersions.core})`
      );
    }
    console.log("✓ All version checks passed:");
    console.log(
      `  • mops.toml version (${mopsVersion}) matches 'core' version in README.md`
    );
    process.exit(0);
  } catch (error) {
    console.error("✗ Version validation failed:");
    console.error(error.message);
    process.exit(1);
  }
}

main();
