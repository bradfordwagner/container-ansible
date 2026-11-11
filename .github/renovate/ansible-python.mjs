// Renovate postUpgradeTask: keep the Python settings consistent with the ansible major.
// Usage: node .github/renovate/ansible-python.mjs <ansible version>
// Source of truth: .github/renovate/compat.json (ansible major -> control node Python range).
import { readFileSync, writeFileSync } from "node:fs";

const version = process.argv[2];
const major = version?.split(".")[0];
const compat = JSON.parse(readFileSync(".github/renovate/compat.json", "utf8"));
const row = compat[major];
if (!row) {
  console.error(`ansible ${version}: no row for major ${major} in .github/renovate/compat.json`);
  process.exit(1);
}

const { min, max } = row.python;
const next = (v) => {
  const [maj, min] = v.split(".").map(Number);
  return `${maj}.${min + 1}`;
};
const minor = (v) => v.split(".").slice(0, 2).join(".");
const cmp = (a, b) => {
  const [a1, a2] = a.split(".").map(Number);
  const [b1, b2] = b.split(".").map(Number);
  return a1 - b1 || a2 - b2;
};

const edit = (path, fn) => {
  const before = readFileSync(path, "utf8");
  const after = fn(before);
  if (after !== before) {
    writeFileSync(path, after);
    console.log(`updated ${path}`);
  }
};

// requires-python in pyproject.toml and uv.lock (lock separates the bounds with ", ")
edit("pyproject.toml", (s) =>
  s.replace(/^requires-python = ".*"$/m, `requires-python = ">=${min},<${next(max)}"`),
);
edit("uv.lock", (s) =>
  s.replace(/^requires-python = ".*"$/m, `requires-python = ">=${min}, <${next(max)}"`),
);

// .python-version: keep the exact pin when it is in range, otherwise move to the nearest supported minor
edit(".python-version", (s) => {
  const m = minor(s.trim());
  if (cmp(m, min) < 0) return `${min}\n`;
  if (cmp(m, max) > 0) return `${max}\n`;
  return s;
});

// Renovate cap: never propose a Python above what this ansible major supports
edit("renovate.json", (s) => {
  const json = JSON.parse(s);
  const rule = json.packageRules?.find((r) => r.matchPackageNames?.includes("python"));
  if (!rule) {
    console.error("renovate.json: no packageRule for python");
    process.exit(1);
  }
  rule.allowedVersions = `<${next(max)}`;
  return `${JSON.stringify(json, null, 2)}\n`;
});
