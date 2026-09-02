#!/usr/bin/env node
// Zenn 記事の章ジャンプ(ページ内リンク)が、実レンダラーの見出し ID と一致するか検証する。
//
// Zenn の markdown は html:false で初期化されているため、独立行の <a id="..."> は
// リテラル文字列として本文に露出する。章ジャンプは見出しの自動アンカーへ直接張るしかない。
// 見出し ID の生成規則は実装依存なので、規則を再実装せず zenn-markdown-html でレンダリングして
// 実際に出た id と突き合わせる。
//
//   node scripts/verify-anchors.mjs                 # articles/*.md を全部見る
//   node scripts/verify-anchors.mjs articles/foo.md # ファイル指定
//
// 未解決のリンクが1本でもあれば exit 1。

import { readFileSync, readdirSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

let markdownToHtml;
try {
  const mod = require('zenn-markdown-html');
  markdownToHtml = mod.default ?? mod;
} catch {
  console.error('zenn-markdown-html が見つからない。npm install --save-dev zenn-markdown-html を実行する。');
  process.exit(2);
}

const args = process.argv.slice(2);
const files = args.length
  ? args
  : readdirSync('articles')
      .filter((f) => f.endsWith('.md'))
      .map((f) => join('articles', f));

// frontmatter を落とす(--- で挟まれた先頭ブロック)
function stripFrontmatter(text) {
  if (!text.startsWith('---')) return text;
  const end = text.indexOf('\n---', 3);
  return end === -1 ? text : text.slice(text.indexOf('\n', end + 1) + 1);
}

function headingIds(html) {
  const ids = new Set();
  for (const m of html.matchAll(/<h[1-6][^>]*\sid="([^"]+)"/g)) ids.add(m[1]);
  return ids;
}

// 本文中のページ内リンク。レンダリング後の href を見る(markdown-it の正規化を通した形)
function inPageHrefs(html) {
  const out = [];
  for (const m of html.matchAll(/href="#([^"]*)"/g)) out.push(m[1]);
  return out;
}

// Zenn は生 HTML をエスケープする。独立行のアンカーは書いても機能しない
function strayHtmlAnchors(md) {
  return md
    .split('\n')
    .map((line, i) => [i + 1, line])
    .filter(([, line]) => /^\s*<a\s+id=/.test(line));
}

let failed = 0;
let checked = 0;

for (const file of files) {
  const raw = readFileSync(file, 'utf8');
  const md = stripFrontmatter(raw);
  const html = await markdownToHtml(md);
  const ids = headingIds(html);
  const hrefs = inPageHrefs(html);
  const unresolved = [...new Set(hrefs)].filter((h) => h && !ids.has(h) && !ids.has(decodeURIComponent(h)));
  const strays = strayHtmlAnchors(md);
  checked += 1;

  const label = relative(process.cwd(), file).split(sep).join('/');
  if (unresolved.length === 0 && strays.length === 0) {
    console.log(`OK   ${label}  見出し ${ids.size} / 章ジャンプ ${hrefs.length}`);
    continue;
  }

  failed += 1;
  console.log(`FAIL ${label}  見出し ${ids.size} / 章ジャンプ ${hrefs.length}`);
  for (const u of unresolved) {
    console.log(`  未解決のリンク先: #${u}`);
    console.log(`    (デコード: #${safeDecode(u)})`);
  }
  for (const [line, text] of strays) {
    console.log(`  ${line}行目: 独立行の HTML アンカーは Zenn ではリテラル表示になる: ${text.trim()}`);
  }
}

function safeDecode(s) {
  try {
    return decodeURIComponent(s);
  } catch {
    return s;
  }
}

console.log(`\n${checked} ファイル中 ${failed} ファイルに問題があった。`);
process.exit(failed === 0 ? 0 : 1);
