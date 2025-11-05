import { readFile } from "fs/promises";
import { join } from "path";

const rootDirectory = join(__dirname, "../../..");

async function getMopsVersion(): Promise<string> {
  const mopsContent = await readFile(
    join(rootDirectory, "/mops.toml"),
    "utf-8"
  );
  const versionMatch = mopsContent.match(/version\s*=\s*"([^"]+)"/);
  if (!versionMatch) {
    throw new Error("Could not find version in mops.toml");
  }
  return versionMatch[1];
}

async function validateChangelog(): Promise<{ latestVersion: string }> {
  const changelogContent = await readFile(
    join(rootDirectory, "Changelog.md"),
    "utf-8"
  );

  const versionNumberRegex = /^\d+\.\d+\.\d+$/;
  const versions = [...changelogContent.matchAll(/##?\s+([^\n]+)/g)].map(
    (match) => match[1].trim()
  );

  if (versions.length === 0) {
    throw new Error("No versions found in Changelog.md");
  }

  let startIndex = 0;
  if (versions[0] === "Next") {
    await validateNextSection(changelogContent);
    startIndex = 1;
    if (versions.length === 1) {
      throw new Error("Changelog.md has 'Next' without any numeric versions");
    }
  } else if (!versionNumberRegex.test(versions[0])) {
    throw new Error(
      "The first entry in Changelog.md must be either '## Next' or a numeric version"
    );
  }

  for (let i = startIndex; i < versions.length; i++) {
    if (!versionNumberRegex.test(versions[i])) {
      throw new Error(`Invalid version format in section: ${versions[i]}`);
    }
  }

  // Get latest version (first version after optional Next)
  return { latestVersion: versions[startIndex] };
}

async function validateNextSection(changelogContent: string): Promise<void> {
  const nextSectionMatch = changelogContent.match(
    /^## Next\s*\n([\s\S]*?)(?=\n## |\n$)/m
  );
  if (!nextSectionMatch) {
    console.warn('Missing "## Next" section in Changelog.md');
    return;
  }

  const nextSectionContent = nextSectionMatch[1];

  // Extract all bullet point entries from the Next section
  const entryRegex = /^\* (.+)$/gm;
  const entries = [...nextSectionContent.matchAll(entryRegex)].map((match) =>
    match[1].trim()
  );

  if (entries.length === 0) {
    return;
  }

  const prNumbers: number[] = [];

  // Check each entry for PR number
  for (const entry of entries) {
    const prMatch = entry.match(/\(#(\d+)\)\.?$/);
    if (!prMatch) {
      throw new Error(`Entry in Next section missing PR number: "${entry}"`);
    }

    const prNumber = parseInt(prMatch[1], 10);
    prNumbers.push(prNumber);
  }

  // Check sorted PR numbers
  for (let i = 1; i < prNumbers.length; i++) {
    if (prNumbers[i] >= prNumbers[i - 1]) {
      throw new Error(
        `PR numbers in Next section should be sorted in descending order. ` +
          `Found PR #${prNumbers[i]} after PR #${prNumbers[i - 1]}`
      );
    }
  }
}

async function main() {
  try {
    const [mopsVersion, { latestVersion }] = await Promise.all([
      getMopsVersion(),
      validateChangelog(),
    ]);

    if (mopsVersion !== latestVersion) {
      throw new Error(
        `Version mismatch: mops.toml version (${mopsVersion}) does not match latest version in Changelog.md (${latestVersion})`
      );
    }

    console.log("✓ Changelog validation passed");
    process.exit(0);
  } catch (error) {
    console.error("✗ Changelog validation failed:");
    console.error(error.message);
    process.exit(1);
  }
}

main();
