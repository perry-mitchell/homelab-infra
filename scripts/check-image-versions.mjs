#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const tfFile =
  process.argv[2] ??
  join(
    dirname(fileURLToPath(import.meta.url)),
    "..",
    "applications",
    "harvester",
    "init_versions.tf",
  );

function parseImages(tf) {
  const out = [];
  const re = /(\w+)\s*=\s*\{\s*uri\s*=\s*"([^"]+)"\s*tag\s*=\s*"([^"]+)"/g;
  let m;
  while ((m = re.exec(tf))) out.push({ name: m[1], uri: m[2], tag: m[3] });
  return out;
}

function classify(tag) {
  if (tag.includes("@sha256")) return { kind: "digest" };
  if (/^(latest|dev|main|nightly|apache|alpine|slim)$/.test(tag))
    return { kind: "floating" };
  if (/^(v?\d+|pg\d+)$/.test(tag)) return { kind: "major" };
  if (/^v?\d/.test(tag)) return { kind: "pinned" };
  return { kind: "floating" };
}

const vkey = (t) =>
  (t.match(/\d+/g) ?? []).map(Number);

function cmp(a, b) {
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const d = (a[i] ?? 0) - (b[i] ?? 0);
    if (d) return d;
  }
  return 0;
}

function parseWwwAuth(h) {
  const m = /Bearer realm="([^"]+)",service="([^"]+)"/.exec(h ?? "");
  return m ? { realm: m[1], service: m[2] } : null;
}

async function regFetch(host, repo, seed) {
  const base = `https://${host}`;
  let token;
  const doFetch = async (url) => {
    const h = token ? { Authorization: `Bearer ${token}` } : {};
    for (let i = 0; i < 4; i++) {
      const res = await fetch(url, { headers: h });
      if (res.status !== 429 && res.status < 500) return res;
      await new Promise((r) => setTimeout(r, 1000 * (i + 1) ** 2));
    }
    throw new Error("rate limited");
  };
  const abs = (u) => (u.startsWith("http") ? u : base + u);
  const auth = async () => {
    const p = await doFetch(`${base}/v2/${repo}/tags/list?n=1`);
    if (p.status !== 401) return p;
    const wa = parseWwwAuth(p.headers.get("www-authenticate"));
    if (!wa) throw new Error("auth required, no bearer realm");
    const scope = `repository:${repo}:pull`;
    const tr = await fetch(
      `${wa.realm}?service=${encodeURIComponent(wa.service)}&scope=${encodeURIComponent(scope)}`,
    );
    if (!tr.ok) throw new Error(`token fetch ${tr.status}`);
    const tj = await tr.json();
    token = tj.token ?? tj.access_token;
    return doFetch(`${base}/v2/${repo}/tags/list?n=1`);
  };
  let res = await auth();
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const collect = async (firstUrl) => {
    let out = [],
      url = firstUrl,
      guard = 0,
      link = null;
    const r0 = await doFetch(url);
    if (!r0.ok) throw new Error(`HTTP ${r0.status}`);
    const j0 = await r0.json();
    out = out.concat(j0.tags ?? []);
    link = r0.headers.get("link");
    while (link && guard++ < 50) {
      const res2 = await doFetch(abs(link.split(";")[0].trim().replace(/[<>]/g, "")));
      if (!res2.ok) throw new Error(`pagination HTTP ${res2.status}`);
      const j = await res2.json();
      out = out.concat(j.tags ?? []);
      link = res2.headers.get("link");
    }
    return out;
  };
  let tags = await collect(`${base}/v2/${repo}/tags/list?n=1000`);
  if (seed) {
    const after = await collect(
      `${base}/v2/${repo}/tags/list?n=1000&last=${encodeURIComponent(seed)}`,
    );
    tags = tags.concat(after);
  }
  return [...new Set(tags)];
}

function splitImage(uri) {
  const first = uri.split("/")[0];
  if (first.includes(".") || first.includes(":") || first === "localhost")
    return { host: first, repo: uri.split("/").slice(1).join("/") };
  return { host: "registry-1.docker.io", repo: uri };
}

const latestOf = (tags) => {
  const cands = tags
    .filter((t) => /^[vV]?\d+([.-]\d+)*$/.test(t))
    .filter((t) => !/^v?\d{5,}$/.test(t))
    .filter((t) => !/(rc|beta|alpha|test)/i.test(t))
    .map((t) => ({ t, k: vkey(t) }))
    .sort((a, b) => cmp(a.k, b.k));
  return cands.length ? cands[cands.length - 1].t : null;
};

const images = parseImages(readFileSync(tfFile, "utf8"));
const results = await Promise.all(
  images.map(async (img) => {
    const c = classify(img.tag);
    if (c.kind !== "pinned") return { ...img, status: c.kind };
    try {
      const { host, repo } = splitImage(img.uri);
      const tags = await regFetch(host, repo, img.tag);
      const latest = latestOf(tags);
      if (!latest) return { ...img, status: "no-numeric-tags" };
      const c = cmp(vkey(latest), vkey(img.tag));
      if (c > 0) return { ...img, status: "behind", latest };
      if (c === 0) return { ...img, status: "current", latest };
      return { ...img, status: "not-in-registry", latest };
    } catch (e) {
      return { ...img, status: `error: ${e.message}` };
    }
  }),
);

for (const r of results) {
  const note =
    r.status === "behind"
      ? `BEHIND  ${r.tag} -> ${r.latest}`
      : r.status === "current"
        ? `ok      (${r.latest})`
        : r.status;
  console.log(`${r.name.padEnd(24)} ${r.tag.padEnd(46)} ${note}`);
}
const behind = results.filter((r) => r.status === "behind").length;
console.log(`\n${behind} of ${results.length} pinned images behind`);
process.exit(behind ? 1 : 0);
