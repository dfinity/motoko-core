const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

function getAllMoFiles(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat && stat.isDirectory()) {
      results = results.concat(getAllMoFiles(filePath));
    } else if (file.endsWith(".mo")) {
      results.push(filePath);
    }
  });
  return results;
}

function runMocOnFile(file) {
  try {
    console.log(file);
    execSync(`moc -r ${file}`, { stdio: "pipe" });
  } catch (err) {
    if (err.stderr) {
      return err.stderr.toString();
    } else if (err.message) {
      return err.message;
    } else {
      return "Unknown error";
    }
  }
}

const moFiles = getAllMoFiles("src");

const errors = [];
moFiles.forEach((file) => {
  const error = runMocOnFile(file);
  if (error) {
    errors.push({ file, error });
  }
});

const errorLines = errors.flatMap(({ error }) =>
  error.split("\n").filter((line) => line.startsWith("src/"))
);
const uniqueErrors = Array.from(
  new Set(errorLines.map((e) => e.trim()))
).sort();

console.log("Unique errors:", uniqueErrors.length);
// console.log(uniqueErrors);
uniqueErrors.forEach((err) => console.log(err));

const files = uniqueErrors.map((line) => line.split(":")[0]);
const fileCounts = files.reduce((acc, file) => {
  acc[file] = (acc[file] || 0) + 1;
  return acc;
}, {});

console.log(fileCounts);

const errorCodes = uniqueErrors.map((line) => line.match(/\[(M\d+)\]/)[1]);
const errorCodeCounts = errorCodes.reduce((acc, code) => {
  acc[code] = (acc[code] || 0) + 1;
  return acc;
}, {});
console.log(errorCodeCounts);
