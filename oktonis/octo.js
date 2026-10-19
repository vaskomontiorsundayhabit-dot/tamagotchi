// Октонис: рисуването (общо за index.html и пробните страници).
// Octo.draw(ctx, { x, y, s, age, mode, t, mt, st, ground })
//   x, y   – къде е основата на пипалата (точно под главата)
//   s      – мащаб (1 = голям Октонис, висок ~430)
//   age    – egg | baby | kid | teen | adult | aging | old
//   mode   – idle | happy | party | work | hurt | sleep
//   st     – обект за частиците ({}), пази се между кадрите
//   ground – null във вода; иначе y на пода (в същите координати като y)
(function () {
const AGES = {
  baby:  { k: 0.5,  head: 1.32, tL: 0.5,  tW: 1.15, gog: "none", eye: 36, paci: true, speed: 1.2,
           col: { body: "#fba383", shade: "#e3825e", back: "#e1866a", backShade: "#c86f54", spot: "#ec9374" } },
  kid:   { k: 0.66, head: 1.18, tL: 0.68, tW: 1.05, gog: "none", eye: 32, speed: 1.15 },
  teen:  { k: 0.83, head: 1.05, tL: 0.9,  tW: 1,    gog: "on", freckles: true },
  adult: { k: 1,    head: 1,    tL: 1,    tW: 1,    gog: "on" },
  aging: { k: 1,    head: 1,    tL: 0.97, tW: 1,    gog: "on", wrinkles: 2, brows: "#cfc8bd", speed: 0.8,
           col: { body: "#e3804f", shade: "#c2643a", back: "#b9603a", backShade: "#9c4f2e", spot: "#a8582f" } },
  old:   { k: 0.93, head: 1,    tL: 0.92, tW: 0.95, gog: "on", wrinkles: 3, brows: "#f4f1ea", mustache: true, cane: true,
           speed: 0.55, hunch: 0.09,
           col: { body: "#d99577", shade: "#b9765a", back: "#b07258", backShade: "#93604a", spot: "#a06a52" } },
};
const BASE = { body: "#ee7a43", shade: "#cf5b2a", back: "#c4562a", backShade: "#a9461f", spot: "#b9501f" };
const C = { line: "#2b2a33", rim: "#3c4350", lens: "#c6ece6", cheek: "rgba(255,120,120,.45)" };
const rnd = (a, b) => a + Math.random() * (b - a);
const pick = a => a[Math.floor(Math.random() * a.length)];

let g, mode, A, COL, GROUND, SP, DROP, CUTE;

const TENT = [
  { dx: -70, side: -1, kind: "arm", back: false, L: 210, ph: 0.0 },
  { dx: -48, side: -1, kind: "leg", back: true, L: 190, ph: 1.7, spread: 0.45 },
  { dx: -24, side: -1, kind: "leg", back: false, L: 185, ph: 3.1, spread: 0.12 },
  { dx: 24, side: 1, kind: "leg", back: false, L: 185, ph: 4.4, spread: 0.12 },
  { dx: 48, side: 1, kind: "leg", back: true, L: 190, ph: 5.2, spread: 0.45 },
  { dx: 70, side: 1, kind: "arm", back: false, L: 210, ph: 2.3 },
];
function tentPts(T, t) {
  const s = T.side, N = 44, step = T.L * A.tL * (CUTE ? 0.78 : 1) / N;
  const sp = { idle: 1.8, happy: 3, party: 7, work: 11, hurt: 1.3, sleep: 0.7, wee: 6, angry: 10 }[mode] * SP;
  let amp = { idle: 0.012, happy: 0.02, party: 0.03, work: 0.03, hurt: 0.008, sleep: 0.006, wee: 0.03, angry: 0.035 }[mode];
  if (GROUND == null) amp *= 1.5;                       // във вода се полюшват повече
  let x = T.dx, y = 62;
  const armA = mode === "work" ? 1.15 + Math.sin(t * 13 + T.ph) * 0.25 : 0.55 + (A.cane ? 0.3 : 0);
  let ang = T.kind === "arm" ? (s > 0 ? armA : Math.PI - armA) : Math.PI / 2 + -s * T.spread * (CUTE ? 1.6 : 1);
  const pts = [];
  for (let j = 0; j <= N; j++) {
    const k = j / N;
    pts.push([x, y, k]);
    let d = Math.sin(t * sp + T.ph - j * 0.18) * amp * (1 + k * 2);
    if (T.kind === "arm") {
      let up = A.cane ? 0.02 : 0.045;
      if (mode === "party" || mode === "wee") up = 0.075 + Math.sin(t * 9 + T.ph) * 0.03;
      if (mode === "angry") up = 0.06 + Math.sin(t * 14 + T.ph) * 0.04;
      if (mode === "sleep") up = 0.012;
      if (mode === "work") up = -0.004;
      d += -s * up;
      if (k > (CUTE ? 0.66 : 0.72)) d += -s * (mode === "sleep" ? 0.1 : CUTE ? 0.26 : 0.2);      // къдрица на върха
    } else if (k > (CUTE ? 0.62 : 0.7)) d += -s * (CUTE ? 0.26 : 0.22);                             // ходилото се извива навън
    ang += d;
    x += Math.cos(ang) * step; y += Math.sin(ang) * step;
    if (GROUND != null && y > GROUND) y = GROUND;
  }
  return pts;
}
function tube(pts, w0, fill, under) {
  for (const pass of [0, 1]) {
    g.fillStyle = pass ? fill : C.line;
    for (const [x, y, k] of pts) {
      const w = w0 * (1 - 0.6 * k) + (pass ? 0 : 4.5);
      g.beginPath(); g.arc(x, y, w, 0, Math.PI * 2); g.fill();
    }
  }
  g.fillStyle = under;
  for (const [x, y, k] of pts) {
    const w = w0 * (1 - 0.6 * k);
    g.beginPath(); g.arc(x + w * 0.35, y + w * 0.35, w * 0.45, 0, Math.PI * 2); g.fill();
  }
}
function cups(pts, w0, s) {             // вендузите отдолу по пипалото
  for (let j = 9; j < pts.length - 3; j += 5) {
    const [x, y, k] = pts[j], [x2, y2] = pts[j + 1];
    let nx = -(y2 - y), ny = x2 - x; const L = Math.hypot(nx, ny) || 1; nx /= L; ny /= L;
    const w = w0 * (1 - 0.6 * k), cxp = x + nx * w * 0.5 * s, cyp = y + ny * w * 0.5 * s, r = Math.max(3, w * 0.4);
    g.fillStyle = "#ffd9c2"; g.strokeStyle = COL.backShade; g.lineWidth = 2.2;
    g.beginPath(); g.arc(cxp, cyp, r, 0, Math.PI * 2); g.fill(); g.stroke();
    g.beginPath(); g.arc(cxp, cyp, r * 0.4, 0, Math.PI * 2); g.stroke();
  }
}
function ell(x, y, rx, ry, rot = 0) { g.beginPath(); g.ellipse(x, y, rx, ry, rot, 0, Math.PI * 2); }

function goggles(hx, ey, t, look, up) {
  const r = 46, gap = 56;
  const y = up ? ey - 95 : ey;
  g.lineCap = "butt";
  for (const [w, c, e] of [[15, C.line, 0], [9, C.rim, 2]]) {
    g.lineWidth = w; g.strokeStyle = c;
    g.beginPath(); g.moveTo(hx - gap - r, y + 4); g.lineTo(hx - gap - r - 30 + e, y + 2); g.stroke();
    g.beginPath(); g.moveTo(hx + gap + r, y + 4); g.lineTo(hx + gap + r + 25 - e, y + 2); g.stroke();
  }
  g.fillStyle = C.rim; g.strokeStyle = C.line; g.lineWidth = 4;
  g.beginPath(); g.roundRect(hx - 18, y - 2, 36, 16, 5); g.fill(); g.stroke();
  for (const s of [-1, 1]) {
    const x = hx + s * gap;
    g.fillStyle = C.lens; ell(x, y, r, r); g.fill();
    if (!up) eyeIn(x, y, r, t, look, s);
    g.strokeStyle = "rgba(255,255,255,.75)"; g.lineWidth = 5; g.lineCap = "round";
    g.beginPath(); g.arc(x, y, r * 0.72, 1.1 * Math.PI, 1.35 * Math.PI); g.stroke();
    g.lineWidth = 16; g.strokeStyle = C.line; ell(x, y, r, r); g.stroke();
    g.lineWidth = 9; g.strokeStyle = C.rim; ell(x, y, r, r); g.stroke();
    g.lineWidth = 2; g.strokeStyle = "rgba(255,255,255,.25)"; g.beginPath(); g.arc(x, y, r + 1, 1.05 * Math.PI, 1.45 * Math.PI); g.stroke();
  }
}
function bareEyes(hx, ey, t, look) {
  const r = (A.eye || 32) * (CUTE ? 1.05 : 1), ry = CUTE ? 1.2 : 1.08;
  for (const s of [-1, 1]) {
    const x = hx + s * (CUTE ? 50 : 54);
    g.fillStyle = "#fff"; ell(x, ey, r, r * ry); g.fill();
    eyeIn(x, ey, r, t, look, s, true);
    if (A.lids && mode !== "sleep") {   // старчески тежки клепачи
      g.save(); ell(x, ey, r, r * ry); g.clip();
      g.fillStyle = COL.body; g.fillRect(x - r, ey - r * ry, r * 2, r * ry * 0.95);
      g.strokeStyle = C.line; g.lineWidth = 5; g.beginPath(); g.moveTo(x - r, ey - r * 0.05 + s * 3); g.lineTo(x + r, ey - r * 0.05 - s * 3); g.stroke();
      g.restore();
    }
    g.lineWidth = 5; g.strokeStyle = C.line; ell(x, ey, r, r * ry); g.stroke();
  }
}
function eyeIn(x, y, r, t, look, s, bare) {
  const blink = (t % 4.1) < 0.13 || ((t + 0.3) % 8.7) < 0.12;
  const big = CUTE && bare ? 1.4 : bare && A.eye > 34 ? 1.25 : 1;
  g.lineCap = "round"; g.strokeStyle = C.line; g.lineWidth = 5;
  if (mode === "angry") {           // ядосан: зениците гледат право, клепачите са наклонени надолу към носа
    g.fillStyle = "#15131c"; ell(x - s * 2, y + 8, 12, 13); g.fill();
    g.save(); ell(x, y, r, r * (bare ? 1.08 : 1)); g.clip();
    g.fillStyle = COL.body; g.beginPath(); g.moveTo(x - r, y - r * 1.2); g.lineTo(x + r, y - r * 1.2);
    g.lineTo(x + r, y - 4 - s * 16); g.lineTo(x - r, y - 4 + s * 16); g.closePath(); g.fill();
    g.lineWidth = 5; g.beginPath(); g.moveTo(x + r, y - 4 - s * 16); g.lineTo(x - r, y - 4 + s * 16); g.stroke();
    g.restore(); return;
  }
  if (mode === "happy" || mode === "party" || mode === "wee") { g.beginPath(); g.arc(x, y + 10, 14, 1.15 * Math.PI, 1.85 * Math.PI); g.stroke(); return; }
  if (mode === "hurt") { const q = 11; g.beginPath(); g.moveTo(x + s * q, y - q); g.lineTo(x - s * q, y); g.lineTo(x + s * q, y + q); g.stroke(); return; }
  if (mode === "work") {             // съсредоточен: присвити очи, гледа надолу
    const px = x - s * 7, py = y + 12;
    g.fillStyle = "#15131c"; ell(px, py, 11, 12); g.fill();
    g.fillStyle = "#fff"; ell(px - 4, py - 4, 3.5, 3.5); g.fill();
    g.save(); ell(x, y, r, r * (bare ? 1.08 : 1)); g.clip();
    const lid = y - 2 + s * 4;
    g.fillStyle = COL.body; g.beginPath(); g.moveTo(x - r, y - r * 1.2); g.lineTo(x + r, y - r * 1.2);
    g.lineTo(x + r, lid - s * 8); g.lineTo(x - r, lid + s * 8); g.closePath(); g.fill();
    g.lineWidth = 5; g.beginPath(); g.moveTo(x + r, lid - s * 8); g.lineTo(x - r, lid + s * 8); g.stroke();
    g.restore();
    return;
  }
  if (blink) {
    if (bare) { g.fillStyle = COL.body; ell(x, y, r, r * 1.08); g.fill(); }
    g.beginPath(); g.moveTo(x - 15, y + 2); g.quadraticCurveTo(x, y + 9, x + 15, y + 2); g.stroke(); return;
  }
  const px = x + look[0] * 10 + s * 3, py = y + look[1] * 10 + 2;
  g.fillStyle = "#15131c"; ell(px, py, 15 * big, 17 * big); g.fill();
  g.fillStyle = "#fff";
  ell(px - 5 * big, py - 6 * big, 5.5 * big, 5.5 * big); g.fill();
  ell(px + 5 * big, py + 6 * big, 2.2 * big, 2.2 * big); g.fill();
}
function gear(x, y, r, a) {
  g.save(); g.translate(x, y); g.rotate(a);
  g.beginPath();
  for (let i = 0; i < 16; i++) {
    const rr = i % 2 ? r : r * 1.3, a1 = i / 16 * Math.PI * 2, a2 = (i + 1) / 16 * Math.PI * 2;
    g.lineTo(Math.cos(a1) * rr, Math.sin(a1) * rr); g.lineTo(Math.cos(a2) * rr, Math.sin(a2) * rr);
  }
  g.closePath(); g.fillStyle = "#c9cfdc"; g.fill(); g.lineWidth = 4.5; g.strokeStyle = C.line; g.lineJoin = "round"; g.stroke();
  g.beginPath(); g.arc(0, 0, r * 0.38, 0, Math.PI * 2); g.fillStyle = "#7c8597"; g.fill(); g.stroke();
  g.restore();
}
function star(x, y, r) {
  g.beginPath();
  for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * 0.45 : r; g.lineTo(x + Math.cos(a) * rr, y + Math.sin(a) * rr); }
  g.closePath(); g.fillStyle = "#ffd166"; g.fill(); g.lineWidth = 3; g.strokeStyle = C.line; g.stroke();
}
const PUFFS = [[-125, 4, 36], [-82, -24, 40], [-30, -36, 42], [25, -34, 40], [80, -24, 40], [126, 2, 36],
  [85, 16, 36], [30, 22, 38], [-30, 22, 38], [-85, 16, 36], [0, 0, 44]];
function brawl(cx, cy, t) {
  const pts = PUFFS.map(([x, y, r], i) => [cx + x + Math.sin(t * 17 + i * 2.1) * 6, cy + y + Math.cos(t * 15 + i * 1.3) * 6,
    r + Math.sin(t * 21 + i) * 5]);
  g.fillStyle = C.line;
  for (const [x, y, r] of pts) { g.beginPath(); g.arc(x, y, r + 5, 0, Math.PI * 2); g.fill(); }
  g.fillStyle = "#f4f0ea";
  for (const [x, y, r] of pts) { g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fill(); }
  g.fillStyle = "#e7e1ec";
  for (const [x, y, r] of pts) if (y > cy + 5) { g.beginPath(); g.arc(x + 4, y + 10, r * 0.6, 0, Math.PI * 2); g.fill(); }
  const k = Math.floor(t * 3);
  for (let i = 0; i < 3; i++) {
    const seed = Math.sin((k + i * 7) * 12.9898) * 43758.5453, f = seed - Math.floor(seed);
    const x = cx + (f - 0.5) * 200, y = cy - 8 + (Math.sin(seed) * 0.5) * 30;
    const kind = ["star", "cog", "bolt", "tent"][Math.floor(f * 37) % 4];
    if (kind === "star") star(x, y, 13);
    else if (kind === "cog") gear(x, y, 12, t * 6);
    else if (kind === "bolt") part({ x, y, a: t * 8, k: "bolt" });
    else { g.save(); g.translate(x, y); g.rotate(f * 6);
      g.lineCap = "round"; g.strokeStyle = C.line; g.lineWidth = 22; g.beginPath(); g.moveTo(-22, 0); g.quadraticCurveTo(0, -16, 20, 0); g.stroke();
      g.strokeStyle = COL.body; g.lineWidth = 13; g.stroke(); g.restore(); }
  }
  g.strokeStyle = C.line; g.lineWidth = 4; g.lineCap = "round";
  for (let i = 0; i < 4; i++) {
    const a = t * 4 + i * 1.7, r1 = 160 + Math.sin(t * 9 + i) * 8;
    const x = cx + Math.cos(a) * r1, y = cy - 20 + Math.sin(a) * 50;
    g.beginPath(); g.moveTo(x, y); g.lineTo(x + Math.cos(a) * 18, y + Math.sin(a) * 8); g.stroke();
  }
}
function part(p) {
  g.save(); g.translate(p.x, p.y); g.rotate(p.a);
  g.strokeStyle = C.line; g.lineWidth = 3.5; g.lineJoin = "round"; g.fillStyle = "#c9cfdc";
  if (p.k === "bolt") {
    g.beginPath(); g.roundRect(-3.5, -2, 7, 24, 2); g.fill(); g.stroke();
    g.lineWidth = 2; for (let i = 4; i < 20; i += 5) { g.beginPath(); g.moveTo(-3.5, i); g.lineTo(3.5, i + 2); g.stroke(); }
    g.lineWidth = 3.5; g.beginPath(); g.roundRect(-9, -8, 18, 8, 2); g.fill(); g.stroke();
  } else if (p.k === "nut") {
    g.beginPath(); for (let i = 0; i < 6; i++) g.lineTo(Math.cos(i * Math.PI / 3) * 11, Math.sin(i * Math.PI / 3) * 11);
    g.closePath(); g.fill(); g.stroke();
    g.beginPath(); g.arc(0, 0, 4.5, 0, Math.PI * 2); g.fillStyle = "#f7f3ec"; g.fill(); g.stroke();
  } else if (p.k === "cog") { g.restore(); gear(p.x, p.y, 11, p.a); return; }
  else if (p.k === "spring") {
    g.strokeStyle = C.line; g.lineWidth = 6; g.beginPath();
    for (let i = 0; i <= 8; i++) g.lineTo(i % 2 ? 7 : -7, -16 + i * 4);
    g.stroke(); g.strokeStyle = "#c9cfdc"; g.lineWidth = 2.5; g.stroke();
  }
  g.restore();
}

// ---------- Яйцето ----------
function egg(t, st) {
  const shake = (t % 5.5) < 0.7 ? Math.sin(t * 40) * 0.1 * (1 - (t % 5.5) / 0.7) : 0;
  const rot = Math.sin(t * 1.6) * 0.04 + shake;
  const cy = GROUND != null ? GROUND - 118 : 30 + Math.sin(t * 1.3) * 6;
  if (GROUND != null) { g.fillStyle = "rgba(60,55,75,.22)"; ell(0, GROUND + 6, 110, 16); g.fill(); }
  g.save(); g.translate(0, cy + 118); g.rotate(rot); g.translate(0, -118);
  const path = () => {
    g.beginPath(); g.moveTo(0, -122);
    g.bezierCurveTo(68, -122, 98, 10, 98, 40);
    g.bezierCurveTo(98, 98, 52, 120, 0, 120);
    g.bezierCurveTo(-52, 120, -98, 98, -98, 40);
    g.bezierCurveTo(-98, 10, -68, -122, 0, -122); g.closePath();
  };
  path(); g.lineWidth = 9; g.strokeStyle = C.line; g.stroke();
  g.fillStyle = "#f1d9bd"; g.fill();
  g.save(); path(); g.clip();
  g.fillStyle = "#fff3e2"; g.beginPath(); g.ellipse(-14, -10, 92, 118, 0, 0, Math.PI * 2); g.fill();
  g.fillStyle = "#f6ae86"; g.strokeStyle = "#d9845c"; g.lineWidth = 3;
  for (const [x, y, r] of [[-40, -50, 13], [30, -78, 9], [50, 0, 16], [-55, 40, 10], [5, 60, 14], [-10, -10, 7], [70, 70, 9]]) {
    g.beginPath(); g.arc(x, y, r, 0, Math.PI * 2); g.fill(); g.stroke();
  }
  g.strokeStyle = "rgba(255,255,255,.9)"; g.lineWidth = 7; g.lineCap = "round";
  g.beginPath(); g.ellipse(-8, -8, 70, 98, 0, 1.12 * Math.PI, 1.32 * Math.PI); g.stroke();
  g.restore();
  if (CUTE) {                          // бебето наднича през дупката
    const hole = [[-38, -40], [-24, -58], [-6, -46], [10, -64], [26, -48], [44, -56], [48, -24], [36, 2], [20, -8], [2, 8], [-18, -4], [-36, 4], [-46, -18]];
    g.save(); g.beginPath(); hole.forEach(([x, y], i) => i ? g.lineTo(x, y) : g.moveTo(x, y)); g.closePath();
    g.fillStyle = "#2b1d1a"; g.fill(); g.clip();
    g.fillStyle = "#f57c1f"; ell(4, -6, 52, 46); g.fill();
    g.fillStyle = "rgba(255,255,255,.5)"; ell(-18, -34, 12, 7, -0.5); g.fill();
    const bl = (t % 3.7) < 0.15;
    for (const sx of [-1, 1]) {
      const ex = 4 + sx * 20, eyy = -16;
      if (bl) { g.strokeStyle = C.line; g.lineWidth = 4; g.beginPath(); g.moveTo(ex - 9, eyy); g.lineTo(ex + 9, eyy); g.stroke(); continue; }
      g.fillStyle = "#fff"; ell(ex, eyy, 11, 13); g.fill(); g.strokeStyle = C.line; g.lineWidth = 3.5; g.stroke();
      g.fillStyle = "#15131c"; ell(ex + Math.sin(t) * 2, eyy + 2, 7, 8); g.fill();
      g.fillStyle = "#fff"; ell(ex - 2, eyy - 2, 2.5, 2.5); g.fill();
    }
    g.restore();
    g.beginPath(); hole.forEach(([x, y], i) => i ? g.lineTo(x, y) : g.moveTo(x, y)); g.closePath();
    g.strokeStyle = C.line; g.lineWidth = 5; g.stroke();
  }
  // пукнатина
  g.strokeStyle = C.line; g.lineWidth = 4.5; g.lineJoin = "round"; g.lineCap = "round";
  g.beginPath(); g.moveTo(32, -98); g.lineTo(20, -76); g.lineTo(36, -62); g.lineTo(22, -40); g.stroke();
  g.restore();
  if (mode === "sleep") zzz(t, 90, cy - 110);
  if (mode === "happy" || mode === "party") for (let i = 0; i < 3; i++) {
    const a = t * 1.5 + i * 2.1;
    star(Math.cos(a) * 140, cy - 40 + Math.sin(a) * 30, 9);
  }
}
function anger(x, y, k) {                 // 💢
  g.save(); g.translate(x, y); g.scale(k, k);
  g.strokeStyle = "#e5383b"; g.lineWidth = 7; g.lineCap = "round";
  for (let i = 0; i < 4; i++) {
    g.save(); g.rotate(i * Math.PI / 2);
    g.beginPath(); g.moveTo(6, -18); g.quadraticCurveTo(6, -6, 18, -6); g.stroke();
    g.restore();
  }
  g.restore();
}
function zzz(t, x0, y0) {
  g.textAlign = "center"; g.lineWidth = 5; g.strokeStyle = C.line; g.fillStyle = "#fff";
  for (let i = 0; i < 3; i++) {
    const z = (t * 0.35 + i / 3) % 1;
    g.globalAlpha = Math.sin(z * Math.PI);
    g.font = `900 ${20 + z * 24}px sans-serif`;
    const zx = x0 + z * 50 + Math.sin(z * 8) * 6, zy = y0 - z * 90;
    g.strokeText("z", zx, zy); g.fillText("z", zx, zy);
  }
  g.globalAlpha = 1;
}

// ---------- Целият Октонис ----------
function body(t, mt, st) {
  let bob = Math.sin(t * 2 * SP) * 4, tilt = Math.sin(t * 0.8) * 0.03, squash = 1 + Math.sin(t * 2 * SP) * 0.015;
  if (mode === "happy") { bob = Math.sin(t * 3.4) * 7; tilt = Math.sin(t * 1.7) * 0.07; }
  if (mode === "party") { const j = Math.abs(Math.sin(t * 6 * SP)); bob = -j * 40 * (A.cane ? 0.4 : 1); squash = 1 + (j - 0.4) * 0.08; }
  if (mode === "sleep") { bob = 10 + Math.sin(t * 0.9) * 3; tilt = 0.12; squash = 1 + Math.sin(t * 0.9) * 0.03; }
  if (mode === "hurt") { bob = 6; tilt = -0.08 + (mt < 0.6 ? Math.sin(mt * 50) * 0.1 * (1 - mt / 0.6) : Math.sin(t * 2.4) * 0.04); }
  if (mode === "work") { bob = Math.sin(t * 8) * 2; tilt = 0.04; }
  if (mode === "wee") { tilt = Math.sin(t * 5) * 0.12; }
  if (mode === "angry") { tilt = Math.sin(t * 30) * 0.03; bob = Math.sin(t * 25) * 2; }
  tilt += A.hunch || 0;

  if (GROUND != null) {
    const sh = 1 - Math.min(0.45, -Math.min(0, bob) / 90);
    g.fillStyle = "rgba(60,55,75,.22)"; ell(10, GROUND + 14, 200 * sh * A.tW, 22 * sh); g.fill();
  }
  g.save();
  if (GROUND != null && DROP) {       // малките стъпват на пода, не висят
    const drop = Math.max(0, GROUND - (62 + 185 * A.tL * (CUTE ? 0.7 : 1)));
    g.translate(0, drop); GROUND -= drop;
  }
  g.translate(0, bob);

  const all = TENT.map(T => [T, tentPts(T, t)]);
  if (A.cane) {                       // бастунче в дясното пипало
    const p = all[5][1][30];
    const bottom = GROUND != null ? GROUND - bob : p[1] + 150;
    g.lineCap = "round";
    g.strokeStyle = C.line; g.lineWidth = 15; g.beginPath(); g.moveTo(p[0] + 10, bottom); g.lineTo(p[0] + 10, p[1] - 10);
    g.arc(p[0] - 10, p[1] - 10, 20, 0, Math.PI * 1.05, true); g.stroke();
    g.strokeStyle = "#a8743e"; g.lineWidth = 7; g.stroke();
  }
  const tw = CUTE ? 1.2 : 1;
  for (const [T, p] of all) if (T.back) tube(p, 19 * A.tW * tw, COL.back, COL.backShade);
  for (const [T, p] of all) if (!T.back) { tube(p, 23 * A.tW * tw, COL.body, COL.shade); if (CUTE) cups(p, 23 * A.tW * tw, T.side); }

  g.save(); g.translate(0, 70); g.rotate(tilt); g.scale(A.head / squash, A.head * squash); g.translate(0, -70);
  const hx = 0, hy = 0;
  const cx = CUTE ? hx : hx + 8, cy = CUTE ? hy - 34 : hy - 40, rx = CUTE ? 120 : 112, ry = CUTE ? 112 : 128, rot = CUTE ? 0 : -0.22;
  g.lineWidth = 9; g.strokeStyle = C.line; ell(cx, cy, rx, ry, rot); g.stroke();
  g.fillStyle = COL.shade; ell(cx, cy, rx, ry, rot); g.fill();
  g.save(); ell(cx, cy, rx, ry, rot); g.clip();
  g.fillStyle = COL.body; ell(cx - 16, cy - 12, rx * 0.95, ry * 0.95, rot); g.fill();
  g.strokeStyle = COL.spot; g.lineWidth = 3.5;
  if (!CUTE || A.spots) for (const [x, y, r] of [[-80, -70, 9], [-95, -35, 5], [-60, -110, 6], [70, -120, 4], [92, 30, 6], [-30, -135, 4]]) {
    g.beginPath(); g.arc(cx + x, cy + y, r, 0, Math.PI * 2); g.stroke();
  }
  if (CUTE) {                          // лъскав отблясък
    g.fillStyle = "rgba(255,255,255,.55)"; ell(cx - 52, cy - 62, 30, 17, -0.6); g.fill();
    g.fillStyle = "rgba(255,255,255,.8)"; ell(cx - 20, cy - 88, 7, 5, -0.3); g.fill();
  } else {
    g.strokeStyle = "rgba(255,240,225,.85)"; g.lineWidth = 7; g.lineCap = "round";
    g.beginPath(); g.ellipse(cx - 10, cy - 10, rx * 0.78, ry * 0.8, rot, 1.08 * Math.PI, 1.22 * Math.PI); g.stroke();
    g.beginPath(); g.arc(cx - 66, cy - 100, 4, 0, Math.PI * 2); g.fillStyle = "rgba(255,240,225,.85)"; g.fill();
  }
  if (mode === "angry") { g.fillStyle = `rgba(230,40,40,${0.18 + Math.sin(t * 6) * 0.06})`; ell(cx, cy, rx, ry, rot); g.fill(); }
  // бръчки
  g.strokeStyle = COL.spot; g.lineWidth = 4;
  for (let i = 0; i < (A.wrinkles || 0); i++) {
    g.beginPath(); g.arc(hx + 4, hy - (CUTE ? 52 : 30) - i * 13, 34 - i * 4, 1.25 * Math.PI, 1.75 * Math.PI); g.stroke();
  }
  g.restore();

  if (A.tuft) {                       // тийнейджърски перчем
    g.lineCap = "round";
    for (const [w, c] of [[15, C.line], [7, COL.body]]) {
      g.strokeStyle = c; g.lineWidth = w; g.beginPath();
      g.moveTo(cx + 22, cy - 120); g.quadraticCurveTo(cx + 18, cy - 160, cx + 46, cy - 160); g.quadraticCurveTo(cx + 62, cy - 150, cx + 46, cy - 140);
      g.stroke();
    }
  }

  const ey = CUTE ? hy - 6 : hy + 6;
  const look = mode === "work" ? [Math.sin(t * 3) * 0.5, 0.75] : [Math.sin(t * 0.5) * 0.7, Math.sin(t * 0.33) * 0.3];
  if (mode !== "hurt") { g.fillStyle = C.cheek; for (const s of [-1, 1]) { ell(hx + s * (CUTE ? 86 : 80), ey + (CUTE ? 34 : 46), 13, 7.5); g.fill(); } }
  if (A.freckles) { g.fillStyle = COL.spot; for (const s of [-1, 1]) for (const [dx, dy] of [[-8, 0], [6, -4], [4, 8]]) { ell(hx + s * (80 + dx), ey + 44 + dy, 2.5, 2.5); g.fill(); } }
  const my = ey + (CUTE ? 46 : 62);
  g.lineWidth = 5; g.strokeStyle = C.line; g.lineCap = "round";
  g.beginPath();
  if (mode === "happy") g.arc(hx, my - 10, 16, 0.15 * Math.PI, 0.85 * Math.PI);
  else if (mode === "angry") { g.moveTo(hx - 16, my + 4); for (let i = 1; i <= 4; i++) g.lineTo(hx - 16 + i * 8, my + (i % 2 ? -3 : 4)); }
  else if (mode === "party" || mode === "wee") { g.moveTo(hx - 20, my - 6); g.quadraticCurveTo(hx, my + 28, hx + 20, my - 6); g.closePath(); g.fillStyle = "#8a2f3a"; g.fill(); }
  else if (mode === "hurt") { g.moveTo(hx - 14, my + 4); g.quadraticCurveTo(hx - 7, my - 5, hx, my + 2); g.quadraticCurveTo(hx + 7, my + 9, hx + 14, my); }
  else if (mode === "sleep") ell(hx, my, 6, 4 + Math.sin(t * 0.9) * 2);
  else if (mode === "work") { g.moveTo(hx - 12, my + 1); g.quadraticCurveTo(hx, my - 3, hx + 12, my + 1); }
  else { g.moveTo(hx - 13, my - 3); g.quadraticCurveTo(hx, my + 7, hx + 13, my - 3); }
  g.stroke();
  if (A.paci && mode !== "party") {   // биберонче за бебето
    g.fillStyle = "#7cc8f2"; g.strokeStyle = C.line; g.lineWidth = 4;
    g.beginPath(); g.ellipse(hx, my + 4, 22, 12, 0, 0, Math.PI * 2); g.fill(); g.stroke();
    g.beginPath(); g.arc(hx, my + 4, 6, 0, Math.PI * 2); g.fillStyle = "#ffd166"; g.fill(); g.stroke();
  }
  if (mode === "angry" && !A.brows) {
    g.strokeStyle = C.line; g.lineWidth = 9; g.lineCap = "round";
    for (const s of [-1, 1]) { g.beginPath(); g.moveTo(hx + s * 24, ey - 54); g.lineTo(hx + s * 86, ey - 82); g.stroke(); }
  }
  if (mode === "work") {
    const tp = (t % 3.4), out = tp < 1.6 ? Math.min(1, tp / 0.25, (1.6 - tp) / 0.25) : 0;
    if (out > 0) {
      const wig = Math.sin(t * 14) * 0.18;
      g.save(); g.translate(hx + 7, my); g.rotate(0.55 + wig);
      g.fillStyle = "#ff7d92"; g.strokeStyle = C.line; g.lineWidth = 4;
      g.beginPath(); g.moveTo(-9, 0); g.lineTo(-9, 10 + 18 * out); g.arc(0, 10 + 18 * out, 9, Math.PI, 0, true); g.lineTo(9, 0); g.fill(); g.stroke();
      g.strokeStyle = "#d94f6a"; g.lineWidth = 2.5; g.beginPath(); g.moveTo(0, 3); g.lineTo(0, 8 + 16 * out); g.stroke();
      g.restore();
    }
    if (!A.brows) {
      g.strokeStyle = C.line; g.lineWidth = 4; g.lineCap = "round";
      for (const s of [-1, 1]) { g.beginPath(); g.moveTo(hx + s * 26, ey - 60); g.quadraticCurveTo(hx + s * 55, ey - 64, hx + s * 84, ey - 78); g.stroke(); }
    }
  }
  if (A.mustache) {
    for (const s of [-1, 1]) {
      g.fillStyle = "#f4f1ea"; g.strokeStyle = C.line; g.lineWidth = 4;
      g.beginPath(); g.ellipse(hx + s * 20, my - 8, 24, 12, s * 0.35, 0, Math.PI * 2); g.fill(); g.stroke();
    }
  }
  const asleep = mode === "sleep";
  if (asleep || A.gog !== "on") {
    if (asleep) {
      g.lineWidth = 5; g.strokeStyle = C.line;
      for (const s of [-1, 1]) { g.beginPath(); g.arc(hx + s * (CUTE ? 50 : 56), ey - 2, 16, 0.15 * Math.PI, 0.85 * Math.PI); g.stroke(); }
    } else bareEyes(hx, ey, t, look);
    if (A.gog !== "none") goggles(hx, ey, t, look, true);
  } else goggles(hx, ey, t, look, false);
  if (A.brows) {                      // рунтави вежди над очилата
    const by = (asleep ? ey - 20 : ey - 62) + (mode === "work" ? 6 : 0);
    for (const s of [-1, 1]) {
      g.lineCap = "round";
      for (const [w, c] of [[17, C.line], [10, A.brows]]) {
        g.strokeStyle = c; g.lineWidth = w; g.beginPath();
        g.moveTo(hx + s * 30, by + (mode === "work" ? 6 : 0)); g.quadraticCurveTo(hx + s * 56, by - 12, hx + s * 84, by + (mode === "work" ? -8 : 2)); g.stroke();
      }
    }
  }
  if (mode === "hurt") {
    g.save(); g.translate(cx + 55, cy - 80);
    for (const a of [0.75, -0.75]) {
      g.save(); g.rotate(a);
      g.fillStyle = "#f6dfb4"; g.strokeStyle = C.line; g.lineWidth = 4;
      g.beginPath(); g.roundRect(-34, -11, 68, 22, 10); g.fill(); g.stroke();
      g.restore();
    }
    g.fillStyle = "#e3c389"; g.fillRect(-9, -9, 18, 18);
    g.restore();
  }
  g.restore();

  // ефекти
  const cloudY = 62 + 150 * A.tL;
  if (mode === "work") {
    brawl(0, cloudY, t);
    if (Math.random() < 0.09) {
      const side = pick([-1, 1]);
      st.parts.push({ x: side * rnd(40, 120), y: cloudY - rnd(20, 70), vx: side * rnd(2, 5.5), vy: rnd(-9, -5), l: 90,
        k: pick(["bolt", "bolt", "nut", "cog", "cog", "spring"]), a: rnd(0, 6), va: rnd(-0.3, 0.3) });
    }
    if (Math.random() < 0.3) st.parts.push({ x: rnd(-110, 110), y: cloudY - rnd(10, 80), vx: rnd(-3, 3), vy: rnd(-5, -1), l: 16, c: pick(["#ffb52e", "#ffd166"]), k: "spark" });
  }
  if (mode === "party" && Math.random() < 0.7)
    for (let i = 0; i < 3; i++) st.parts.push({ x: rnd(-300, 300), y: -380, vx: rnd(-1, 1), vy: rnd(1, 3), l: 260, c: pick(["#ffd166", "#ff8fa3", "#7cc8f2", "#6fd3a0", "#b39ddb"]), k: "conf", a: rnd(0, 6) });
  const headTop = 70 - 238 * A.head;
  if (mode === "hurt") for (let i = 0; i < 3; i++) {
    const a = t * 2.5 + i * Math.PI * 2 / 3;
    star(10 + Math.cos(a) * 95 * A.head, headTop - 12 + Math.sin(a) * 14, 13);
  }
  if (mode === "sleep") zzz(t, 125 * A.head, headTop + 90);
  if (mode === "angry") {
    anger(95 * A.head, headTop + 40, 1 + Math.sin(t * 10) * 0.12);
    for (let i = 0; i < 2; i++) {                 // пара от главата
      const z = (t * 1.2 + i * 0.5) % 1, sx = (i ? 1 : -1) * (40 + z * 30);
      g.globalAlpha = 1 - z; g.fillStyle = "#fff"; g.strokeStyle = C.line; g.lineWidth = 3;
      g.beginPath(); g.arc(sx, headTop + 10 - z * 60, 10 + z * 14, 0, Math.PI * 2); g.fill(); g.stroke();
      g.globalAlpha = 1;
    }
  }
  g.restore();
}

function draw(ctx, o) {
  g = ctx; mode = o.mode || "idle";
  const st = o.st || (o.st = {});
  st.parts = st.parts || [];
  if (st.mode !== mode) { st.mode = mode; st.parts = []; }
  const sc = o.s || 1;
  const age = o.age || "adult";
  A = AGES[age] || AGES.adult;
  CUTE = o.style === "cute";
  if (CUTE) {                          // сладкият стил: без очила (само маска при работа), кръгла глава
    const old = age === "old", aging = age === "aging";
    A = { ...A, gog: mode === "work" ? "on" : "none", brows: null, mustache: false, paci: false, freckles: false, tuft: false,
      eye: age === "baby" ? 36 : 32, lids: old, spots: old || aging, wrinkles: old ? 3 : aging ? 1 : 0,
      col: { body: old ? "#e98a45" : "#f57c1f", shade: old ? "#cc6c30" : "#d9601a", back: old ? "#cf6e33" : "#d8641c",
             backShade: old ? "#ad5826" : "#b84f12", spot: old ? "#c2601f" : "#c85a14" } };
    C.rim = "#2f6fb0"; C.lens = "#bfe7f5";
  } else { C.rim = "#3c4350"; C.lens = "#c6ece6"; }
  COL = A.col || BASE;
  SP = A.speed || 1;
  const k = sc * (age === "egg" ? 0.9 : A.k);
  GROUND = o.ground == null ? null : (o.ground - o.y) / k;
  DROP = o.drop !== false;
  g.save(); g.translate(o.x, o.y); g.scale(k, k);
  g.lineJoin = "round";
  if (age === "egg") egg(o.t, st); else body(o.t, o.mt || 9, st);
  st.parts = st.parts.filter(p => {
    p.x += p.vx; p.y += p.vy; p.vy += p.k === "spark" ? 0.28 : p.k === "conf" ? 0.02 : 0.32; p.l--;
    if (p.k === "spark") { g.strokeStyle = p.c; g.lineWidth = 4; g.lineCap = "round"; g.beginPath(); g.moveTo(p.x, p.y); g.lineTo(p.x - p.vx * 2, p.y - p.vy * 2); g.stroke(); }
    else if (p.k !== "conf") { p.a += p.va; part(p); }
    else { p.a += 0.15; g.save(); g.translate(p.x + Math.sin(p.a) * 6, p.y); g.rotate(p.a); g.fillStyle = p.c; g.fillRect(-6, -3.5, 12, 7); g.restore(); }
    return p.l > 0;
  });
  g.restore();
  // къде е върхът на главата и колко е голям (за балончето и докосването)
  const top = age === "egg" ? -150 : 70 - 238 * A.head;
  return { top: o.y + top * k, r: 260 * k, cy: o.y + (top + 200) * k / 2 };
}

window.Octo = { V: 7, draw, AGES: ["egg", "baby", "kid", "teen", "adult", "aging", "old"],
  AGE_NAMES: { egg: "Яйце", baby: "Бебе", kid: "Малък", teen: "Тийнейджър", adult: "Голям", aging: "Застаряващ", old: "Много стар" } };
})();
