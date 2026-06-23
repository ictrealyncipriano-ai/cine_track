import express from "express";
import * as cheerio from "cheerio";

const app = express();
const PORT = 3001;

const decoders = {
  LXVUMCoAHJ: (p) => {
    const r = p.split("").reverse().join("").replace(/-/g, "+").replace(/_/g, "/");
    const d = Buffer.from(r, "base64").toString("utf-8");
    let o = "";
    for (let i = 0; i < d.length; i++) o += String.fromCharCode(d.charCodeAt(i) - 3);
    return o;
  },
  GuxKGDsA2T: (p) => {
    const r = p.split("").reverse().join("").replace(/-/g, "+").replace(/_/g, "/");
    const d = Buffer.from(r, "base64").toString("utf-8");
    let o = "";
    for (let i = 0; i < d.length; i++) o += String.fromCharCode(d.charCodeAt(i) - 7);
    return o;
  },
  laM1dAi3vO: (p) => {
    const r = p.split("").reverse().join("").replace(/-/g, "+").replace(/_/g, "/");
    const d = Buffer.from(r, "base64").toString("utf-8");
    let o = "";
    for (let i = 0; i < d.length; i++) o += String.fromCharCode(d.charCodeAt(i) - 5);
    return o;
  },
  nZlUnj2VSo: (p) => {
    const m = { x:"a", y:"b", z:"c", a:"d", b:"e", c:"f", d:"g", e:"h", f:"i", g:"j", h:"k", i:"l", j:"m", k:"n", l:"o", m:"p", n:"q", o:"r", p:"s", q:"t", r:"u", s:"v", t:"w", u:"x", v:"y", w:"z", X:"A", Y:"B", Z:"C", A:"D", B:"E", C:"F", D:"G", E:"H", F:"I", G:"J", H:"K", I:"L", J:"M", K:"N", L:"O", M:"P", N:"Q", O:"R", P:"S", Q:"T", R:"U", S:"V", T:"W", U:"X", V:"Y", W:"Z" };
    return p.replace(/[xyzabcdefghijklmnopqrstuvwXYZABCDEFGHIJKLMNOPQRSTUVW]/g, (c) => m[c]);
  },
  Iry9MQXnLs: (p) => {
    const k = "pWB9V)[*4I`nJpp?ozyB~dbr9yt!_n4u";
    const hex = p.match(/.{1,2}/g).map((x) => String.fromCharCode(parseInt(x, 16))).join("");
    let xored = "";
    for (let i = 0; i < hex.length; i++) xored += String.fromCharCode(hex.charCodeAt(i) ^ k.charCodeAt(i % k.length));
    let shifted = "";
    for (let i = 0; i < xored.length; i++) shifted += String.fromCharCode(xored.charCodeAt(i) - 3);
    return Buffer.from(shifted, "base64").toString("utf-8");
  },
  IGLImMhWrI: (p) => {
    const r = p.split("").reverse().join("");
    const rot = r.replace(/[a-zA-Z]/g, (c) => String.fromCharCode(c.charCodeAt(0) + (c.toLowerCase() < "n" ? 13 : -13)));
    const back = rot.split("").reverse().join("");
    return Buffer.from(back, "base64").toString("utf-8");
  },
  GTAxQyTyBx: (p) => {
    const r = p.split("").reverse().join("");
    let o = "";
    for (let i = 0; i < r.length; i += 2) o += r[i];
    return Buffer.from(o, "base64").toString("utf-8");
  },
  C66jPHx8qu: (p) => {
    const k = "X9a(O;FMV2-7VO5x;Ao:dN1NoFs?j,";
    const r = p.split("").reverse().join("");
    const hex = r.match(/.{1,2}/g).map((x) => String.fromCharCode(parseInt(x, 16))).join("");
    let o = "";
    for (let i = 0; i < hex.length; i++) o += String.fromCharCode(hex.charCodeAt(i) ^ k.charCodeAt(i % k.length));
    return o;
  },
  MyL1IRSfHe: (p) => {
    const r = p.split("").reverse().join("");
    let s = "";
    for (let i = 0; i < r.length; i++) s += String.fromCharCode(r.charCodeAt(i) - 1);
    let o = "";
    for (let i = 0; i < s.length; i += 2) o += String.fromCharCode(parseInt(s.substr(i, 2), 16));
    return o;
  },
  detdj7JHiK: (p) => {
    const k = "3SAY~#%Y(V%>5d/Yg\"$G[Lh1rK4a;7ok";
    const sliced = p.slice(10, -16);
    const d = Buffer.from(sliced, "base64").toString("utf-8");
    const rk = k.repeat(Math.ceil(d.length / k.length)).substring(0, d.length);
    let o = "";
    for (let i = 0; i < d.length; i++) o += String.fromCharCode(d.charCodeAt(i) ^ rk.charCodeAt(i));
    return o;
  },
  bMGyx71TzQLfdonN: (p) => {
    let o = "";
    for (let i = 0; i < p.length; i += 3) o += p.slice(i, i + 3);
    return o.split("").reverse().join("");
  },
};

function decrypt(param, type) {
  const fn = decoders[type];
  if (!fn) return null;
  try { return fn(param); } catch(e) { return null; }
}

async function serversLoad(html) {
  const $ = cheerio.load(html);
  const servers = [];
  const title = $("title").text() ?? "";
  let BASEDOM = "https://whisperingauroras.com";
  const base = $("iframe").attr("src") ?? "";
  if (base) {
    BASEDOM = new URL(base.startsWith("//") ? "https:" + base : base).origin;
  }
  $(".serversList .server").each((_, element) => {
    const el = $(element);
    servers.push({
      name: el.text().trim(),
      dataHash: el.attr("data-hash") ?? null,
    });
  });
  return { servers, title, BASEDOM };
}

async function PRORCPhandler(prorcp, BASEDOM) {
  const prorcpResp = await fetch(`${BASEDOM}/prorcp/${prorcp}`);
  const prorcpText = await prorcpResp.text();

  const scripts = prorcpText.match(/<script\s+src="\/([^"]*\.js)\?\_=([^"]*)"><\/script>/gm);
  let script = null;
  if (scripts) {
    const last = scripts[scripts.length - 1];
    const secondLast = scripts[scripts.length - 2];
    if (last && last.includes("cpt.js") && secondLast) {
      script = secondLast.replace(/.*src="\/([^"]*\.js)\?\_=([^"]*)".*/, "$1?_=$2");
    } else {
      script = last.replace(/.*src="\/([^"]*\.js)\?\_=([^"]*)".*/, "$1?_=$2");
    }
  }
  if (!script) return null;

  const jsReq = await fetch(`${BASEDOM}/${script}`, {
    headers: {
      "accept": "*/*",
      "accept-language": "en-US,en;q=0.9",
      "sec-ch-ua": '"Chromium";v="128", "Not;A=Brand";v="24", "Google Chrome";v="128"',
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": '"Windows"',
      "Referer": `${BASEDOM}/`,
    },
  });
  const jsCode = await jsReq.text();
  const decryptRegex = /{}\}window\[([^"]+)\("([^"]+)"\)/;
  const decryptMatches = jsCode.match(decryptRegex);
  if (!decryptMatches || decryptMatches.length < 3) return null;

  const id = decrypt(decryptMatches[2].trim(), decryptMatches[1].trim());
  const $ = cheerio.load(prorcpText);
  const data = $("#" + id);
  if (!data.length) return null;
  const result = await decrypt(await data.text(), decryptMatches[2].trim());
  return result;
}

async function rcpGrabber(html) {
  const regex = /src:\s*'([^']*)'/;
  const match = html.match(regex);
  if (!match) return null;
  return { metadata: { image: "" }, data: match[1] };
}

async function tmdbScrape(tmdbId, type, season, episode) {
  const baseEmbed = "https://vidsrc.to";
  const url = type === "movie"
    ? `${baseEmbed}/embed/${type}?tmdb=${tmdbId}`
    : `${baseEmbed}/embed/${type}?tmdb=${tmdbId}&season=${season}&episode=${episode}`;

  const embedResp = await fetch(url);
  const embedHtml = await embedResp.text();

  const { servers, title, BASEDOM } = await serversLoad(embedHtml);
  if (!servers.length) return [];

  const rcpResponses = await Promise.all(
    servers.map((s) => fetch(`${BASEDOM}/rcp/${s.dataHash}`).then((r) => r.text()))
  );
  const prosrcrcp = await Promise.all(
    rcpResponses.map((t) => rcpGrabber(t))
  );

  const results = [];
  for (const item of prosrcrcp) {
    if (!item) continue;
    if (item.data.startsWith("/prorcp/")) {
      const stream = await PRORCPhandler(item.data.replace("/prorcp/", ""), BASEDOM);
      if (stream) {
        results.push({
          name: title,
          image: item.metadata.image,
          mediaId: tmdbId,
          stream,
          referer: BASEDOM,
        });
      }
    }
  }
  return results;
}

app.get("/api/:id/:ss?/:ep?", async (req, res) => {
  try {
    const { id, ss, ep } = req.params;
    const isMovie = !ss || !ep;
    const results = isMovie
      ? await tmdbScrape(id, "movie")
      : await tmdbScrape(id, "tv", Number(ss), Number(ep));
    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`vidsrc-server running on http://localhost:${PORT}`);
});
