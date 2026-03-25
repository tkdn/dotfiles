#!/usr/bin/env node
/**
 * scan.mjs
 * Node.js バージョン指定箇所をリポジトリ群から走査して JSON で出力する
 *
 * Usage:
 *   node scan.mjs <root-dir>
 *
 * Output (stdout):
 *   JSON array of repository scan results
 */

import fs from 'fs';
import path from 'path';

const rootDir = process.argv[2] ? path.resolve(process.argv[2]) : process.cwd();

// ---- helpers ----

function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
}

function isDirectory(p) {
  try {
    return fs.statSync(p).isDirectory();
  } catch {
    return false;
  }
}

function fileExists(p) {
  try {
    fs.accessSync(p);
    return true;
  } catch {
    return false;
  }
}

// .node-version / .nvmrc を再帰的に探す（depth まで）
function findNodeVersionFiles(dir, depth = 3) {
  const results = [];
  if (depth < 0) return results;
  let entries;
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return results;
  }
  for (const entry of entries) {
    if (entry.name.startsWith('.') && entry.isDirectory()) continue;
    if (['node_modules', 'vendor', '.git'].includes(entry.name)) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findNodeVersionFiles(full, depth - 1));
    } else if (entry.name === '.node-version' || entry.name === '.nvmrc') {
      const content = readFile(full)?.trim();
      if (content) results.push({ file: full, version: content });
    }
  }
  return results;
}

// package.json の engines.node を取得
function getEnginesNode(pkgPath) {
  const content = readFile(pkgPath);
  if (!content) return null;
  try {
    const pkg = JSON.parse(content);
    return pkg?.engines?.node ?? null;
  } catch {
    return null;
  }
}

// .github/**/*.yml から node-version-file / node-version の参照先を収集
function scanGitHubActions(repoDir) {
  const githubDir = path.join(repoDir, '.github');
  if (!isDirectory(githubDir)) return [];

  const results = [];

  function walk(dir) {
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
      } else if (entry.name.endsWith('.yml') || entry.name.endsWith('.yaml')) {
        const content = readFile(full);
        if (!content) continue;
        // node-version-file の参照先を抽出
        const fileRefs = [...content.matchAll(/node-version-file:\s*['"]?([^'"\s]+)['"]?/g)]
          .map(m => m[1]);
        // 直接バージョン指定（数値のみ、x.y.z 形式）
        const directVersions = [...content.matchAll(/node-version:\s*['"]?(\d[\d.x*]*[^'"\s]*)['"]?/g)]
          .map(m => m[1])
          .filter(v => !v.startsWith('${{') && v !== 'lts/*');

        if (fileRefs.length > 0 || directVersions.length > 0) {
          results.push({
            workflow: path.relative(repoDir, full),
            nodeVersionFileRefs: fileRefs,
            directVersions,
          });
        }
      }
    }
  }

  walk(githubDir);
  return results;
}

// ---- メジャーバージョンを抽出 ----
function extractMajor(versionStr) {
  if (!versionStr) return null;
  const match = versionStr.match(/(\d+)/);
  return match ? parseInt(match[1], 10) : null;
}

// ---- 単一リポジトリを走査 ----
function scanRepo(repoDir) {
  const repoName = path.basename(repoDir);
  const findings = [];

  // .node-version / .nvmrc（リポジトリ直下 + サブディレクトリ）
  const nodeVersionFiles = findNodeVersionFiles(repoDir, 2);
  for (const { file, version } of nodeVersionFiles) {
    findings.push({
      type: 'node-version-file',
      file: path.relative(repoDir, file),
      version,
      major: extractMajor(version),
    });
  }

  // package.json の engines.node（直下 + 1階層サブディレクトリ）
  const pkgRoots = [repoDir];
  try {
    for (const entry of fs.readdirSync(repoDir, { withFileTypes: true })) {
      if (entry.isDirectory() && !['node_modules', '.git', 'vendor'].includes(entry.name)) {
        pkgRoots.push(path.join(repoDir, entry.name));
      }
    }
  } catch { /* ignore */ }

  for (const pkgRoot of pkgRoots) {
    const pkgPath = path.join(pkgRoot, 'package.json');
    if (!fileExists(pkgPath)) continue;
    const enginesNode = getEnginesNode(pkgPath);
    if (!enginesNode) continue;
    findings.push({
      type: 'engines.node',
      file: path.relative(repoDir, pkgPath),
      version: enginesNode,
      major: extractMajor(enginesNode),
      isRange: /[x*^~><=]/.test(enginesNode) || !/^\d+\.\d+\.\d+$/.test(enginesNode.replace(/^[^0-9]*/, '')),
    });
  }

  // GitHub Actions
  const actions = scanGitHubActions(repoDir);
  for (const action of actions) {
    // node-version-file 参照は .node-version や package.json を間接参照しているだけなので
    // 直接バージョン指定がある場合のみ findings に追加
    if (action.directVersions.length > 0) {
      for (const v of action.directVersions) {
        findings.push({
          type: 'github-actions-direct',
          file: action.workflow,
          version: v,
          major: extractMajor(v),
          isRange: /[x*]/.test(v),
        });
      }
    }
  }

  return { repo: repoName, repoDir, findings };
}

// ---- メイン ----

// rootDir がリポジトリ群の親か、単一リポジトリかを判定
// .git が直下にあれば単一リポジトリ
const isSingleRepo = isDirectory(path.join(rootDir, '.git'));

let repoDirs = [];
if (isSingleRepo) {
  repoDirs = [rootDir];
} else {
  // 直下ディレクトリをリポジトリとして扱う
  try {
    repoDirs = fs.readdirSync(rootDir, { withFileTypes: true })
      .filter(e => e.isDirectory() && !e.name.startsWith('.'))
      .map(e => path.join(rootDir, e.name))
      .filter(d => isDirectory(path.join(d, '.git')) || fileExists(path.join(d, 'package.json')));
  } catch (e) {
    process.stderr.write(`Error reading directory: ${e.message}\n`);
    process.exit(1);
  }
}

const results = repoDirs.map(scanRepo).filter(r => r.findings.length > 0);

process.stdout.write(JSON.stringify({
  rootDir,
  isSingleRepo,
  repos: results,
}, null, 2));
