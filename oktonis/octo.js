// Октонис: рисуването (общо за index.html и пробните страници).
// Octo.draw(ctx, { x, y, s, age, mode, t, mt, st, ground })
//   x, y   – къде е основата на пипалата (точно под главата)
//   s      – мащаб (1 = голям Октонис, висок ~430)
//   age    – egg | baby | kid | teen | adult | aging | old
//   mode   – idle | happy | party | work | hurt | sleep
//   st     – обект за частиците ({}), пази се между кадрите
//   ground – null във вода; иначе y на пода (в същите координати като y)
(function () {
const VER = 38;
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

let PLASTER = false, HAT = null, WORK = null, HUG = false, NOPACI = false, CRACK = 0, SAD = false, EAT = false, g, mode, A, COL, GROUND, SP, DROP, CUTE, STATIC, LOOK, LIE, TR = [];

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
  const sp = { idle: 1.8, happy: 3, party: 7, work: 11, hurt: 1.3, sleep: 0.7, wee: 6, angry: 10, read: 1.2 }[mode] * SP;
  let amp = { idle: 0.012, happy: 0.02, party: 0.03, work: 0.03, hurt: 0.008, sleep: 0.006, wee: 0.03, angry: 0.035, read: 0.008 }[mode];
  if (GROUND == null) amp *= 1.5;                       // във вода се полюшват повече
  let x = T.dx, y = 62;
  const armA = mode === "work" ? 1.15 + Math.sin(t * 13 + T.ph) * 0.25 : 0.55 + (A.cane ? 0.3 : 0);
  const hug = HUG && T.kind === "arm";      // прегръща възглавницата: ръцете се увиват надолу и навътре
  let ang = hug ? (s > 0 ? -0.35 : Math.PI + 0.35) : T.kind === "arm" ? (s > 0 ? armA : Math.PI - armA) : Math.PI / 2 + -s * T.spread * (CUTE ? 1.6 : 1) * (mode === "sleep" ? 1.8 : 1);
  const pts = [];
  for (let j = 0; j <= N; j++) {
    const k = j / N;
    pts.push([x, y, k]);
    let d = Math.sin(t * sp + T.ph - j * 0.18) * amp * (1 + k * 2);
    if (hug) d += s * (k < 0.35 ? 0.012 : 0.07);
    else if (T.kind === "arm") {
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
  for (const sd of [-1, 1]) {           // вместо каишка: малки месингови нитове
    const nx = hx + sd * (gap + r + 6);
    g.fillStyle = "#e0b25a"; g.strokeStyle = C.line; g.lineWidth = 4; ell(nx, y + 2, 9, 9); g.fill(); g.stroke();
    g.fillStyle = "rgba(255,255,255,.6)"; ell(nx - 2, y - 1, 3, 3); g.fill();
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
function drawHat(k, cx, cy, ry, t) {          // шапките от подаръците
  g.save(); g.strokeStyle = C.line; g.lineWidth = 5; g.lineJoin = "round";
  if (k === "beanie") {
    g.translate(cx, cy - ry * 0.78); g.rotate(-0.06);
    g.fillStyle = "#e5383b"; g.beginPath(); g.moveTo(-70, 10); g.quadraticCurveTo(-66, -62, 0, -64); g.quadraticCurveTo(66, -62, 70, 10); g.closePath(); g.fill(); g.stroke();
    g.fillStyle = "#fffaf0"; g.beginPath(); g.roundRect(-74, -6, 148, 24, 10); g.fill(); g.stroke();
    g.strokeStyle = "rgba(255,255,255,.5)"; g.lineWidth = 3; for (let i = -2; i <= 2; i++) { g.beginPath(); g.moveTo(i * 24, -6); g.lineTo(i * 20, -52); g.stroke(); }
    g.strokeStyle = C.line; g.lineWidth = 5; g.fillStyle = "#fffaf0"; g.beginPath(); g.arc(0, -70, 16 + Math.sin(t * 3) * 1.5, 0, 7); g.fill(); g.stroke();
  } else if (k === "straw") {
    g.translate(cx, cy - ry * 0.85); g.rotate(0.08);
    g.fillStyle = "#e8c96a"; g.beginPath(); g.ellipse(0, 6, 110, 20, 0, 0, 7); g.fill(); g.stroke();
    g.beginPath(); g.moveTo(-50, 6); g.quadraticCurveTo(-48, -46, 0, -48); g.quadraticCurveTo(48, -46, 50, 6); g.closePath(); g.fill(); g.stroke();
    g.fillStyle = "#4f8ff0"; g.beginPath(); g.rect(-50, -12, 100, 14); g.fill(); g.stroke();
    g.fillStyle = "#ff8ab0"; g.beginPath(); g.arc(40, -6, 10, 0, 7); g.fill(); g.stroke();
  } else if (k === "pirate") {
    g.translate(cx, cy - ry * 0.85); g.rotate(-0.05);
    g.fillStyle = "#2b2a33"; g.beginPath(); g.moveTo(-100, 10); g.quadraticCurveTo(-60, -20, -40, -50); g.quadraticCurveTo(0, -80, 40, -50); g.quadraticCurveTo(60, -20, 100, 10); g.quadraticCurveTo(0, -10, -100, 10); g.fill(); g.stroke();
    g.strokeStyle = "#e9c46a"; g.lineWidth = 4; g.beginPath(); g.moveTo(-90, 4); g.quadraticCurveTo(0, -16, 90, 4); g.stroke();
    g.fillStyle = "#fffaf0"; g.strokeStyle = C.line; g.lineWidth = 3; g.beginPath(); g.arc(0, -36, 12, 0, 7); g.fill(); g.stroke();
    g.beginPath(); g.moveTo(-14, -20); g.lineTo(14, -12); g.moveTo(14, -20); g.lineTo(-14, -12); g.stroke();
  } else if (k === "captain") {
    g.translate(cx, cy - ry * 0.88);
    g.fillStyle = "#fffaf0"; g.beginPath(); g.ellipse(0, -26, 80, 26, 0, 0, 7); g.fill(); g.stroke();
    g.fillStyle = "#1f3b70"; g.beginPath(); g.roundRect(-60, -18, 120, 26, 6); g.fill(); g.stroke();
    g.fillStyle = "#2b2a33"; g.beginPath(); g.moveTo(-58, 8); g.quadraticCurveTo(0, 30, 58, 8); g.quadraticCurveTo(0, 16, -58, 8); g.fill(); g.stroke();
    g.fillStyle = "#e9c46a"; g.beginPath(); g.arc(0, -8, 10, 0, 7); g.fill(); g.stroke();
  } else if (k === "party") {
    g.translate(cx + 14, cy - ry * 0.85); g.rotate(0.18);
    g.fillStyle = "#7d5cff"; g.beginPath(); g.moveTo(-46, 6); g.lineTo(0, -110); g.lineTo(46, 6); g.closePath(); g.fill(); g.stroke();
    g.save(); g.beginPath(); g.moveTo(-46, 6); g.lineTo(0, -110); g.lineTo(46, 6); g.closePath(); g.clip();
    for (const [x, y, col] of [[-16, -20, "#ffd23f"], [14, -46, "#ff5d8a"], [-4, -74, "#7fd3ff"], [20, -6, "#7cc256"]]) { g.fillStyle = col; g.beginPath(); g.arc(x, y, 9, 0, 7); g.fill(); }
    g.restore(); g.fillStyle = "#ffd23f"; g.beginPath(); g.arc(0, -114, 12, 0, 7); g.fill(); g.stroke();
  } else if (k === "shellcrown") {
    g.translate(cx, cy - ry * 0.88);
    g.fillStyle = "#ffcf3a"; g.beginPath(); g.moveTo(-64, 6); g.lineTo(-64, -34); g.lineTo(-34, -12); g.lineTo(0, -52); g.lineTo(34, -12); g.lineTo(64, -34); g.lineTo(64, 6); g.closePath(); g.fill(); g.stroke();
    for (const [x, col] of [[-36, "#ffd9c2"], [0, "#ffb0c8"], [36, "#ffd9c2"]]) { g.fillStyle = col; g.beginPath(); g.arc(x, -6, 11, Math.PI, 0); g.lineTo(x, 4); g.closePath(); g.fill(); g.stroke(); }
    g.fillStyle = "#fff"; g.beginPath(); g.arc(0, -52, 7, 0, 7); g.fill(); g.stroke();
  }
  g.restore();
}
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
  if (p.k === "skbolt") {              // болтче с химикал
    g.save(); g.translate(p.x, p.y); g.rotate(p.a); g.strokeStyle = SK.ink; g.fillStyle = "#fbf7ee"; g.lineWidth = 1.5;
    g.beginPath(); g.rect(-1.8, -1, 3.6, 12); g.fill(); g.stroke(); g.beginPath(); g.rect(-4.5, -4, 9, 4); g.fill(); g.stroke();
    g.restore(); return;
  }
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
  const shake = ((t % 5.5) < 0.7 ? Math.sin(t * 40) * 0.1 * (1 - (t % 5.5) / 0.7) : 0) + (CRACK > 0.97 ? Math.sin(t * 60) * 0.12 : CRACK > 0.8 ? Math.sin(t * 30) * 0.03 : 0);
  const rot = Math.sin(t * 1.6) * 0.04 + shake;
  const cy = GROUND != null ? GROUND - 118 : 30 + Math.sin(t * 1.3) * 6;
  if (GROUND != null) { g.fillStyle = "rgba(60,55,75,.22)"; ell(0, GROUND + 6, 110, 16); g.fill(); }
  if (CRACK > 0.3) {                   // стопленото яйце свети
    const a = Math.min(0.55, (CRACK - 0.3) * 0.8), rg = g.createRadialGradient(0, cy, 20, 0, cy, 230);
    rg.addColorStop(0, `rgba(255,220,150,${a})`); rg.addColorStop(1, "rgba(255,220,150,0)"); g.fillStyle = rg; g.beginPath(); g.arc(0, cy, 230, 0, 7); g.fill();
  }
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
  const CR = [[[-20, -90], [-8, -70], [-24, -52], [-6, -36]], [[40, -60], [56, -44], [44, -24], [64, -8]], [[-70, 20], [-50, 30], [-62, 52], [-40, 64]], [[20, 40], [36, 54], [24, 74], [44, 90]], [[-30, -20], [-10, -2], [-28, 16]]];
  g.strokeStyle = C.line; g.lineWidth = 5; g.lineJoin = "miter";
  CR.slice(0, Math.floor(CRACK * 6)).forEach(c => { g.beginPath(); c.forEach(([x, y], i) => i ? g.lineTo(x, y) : g.moveTo(x, y)); g.stroke(); });
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
  if (mode === "sleep") { bob = 10 + Math.sin(t * 0.9) * 3; tilt = 0.12; squash = (GROUND != null ? 0.84 : 1) + Math.sin(t * 0.9) * 0.03; }
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

  g.save(); g.translate(0, 70); g.rotate(tilt); g.scale(A.head / squash * (TR.includes("chubby") ? 1.13 : 1), A.head * squash); g.translate(0, -70);
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
  const look = SAD ? [Math.sin(t * 0.4) * 0.3, 0.7] : mode === "read" ? [Math.sin(t * 1.3) * 0.6, 0.8] : mode === "work" ? [Math.sin(t * 3) * 0.5, 0.75] : [Math.sin(t * 0.5) * 0.7, Math.sin(t * 0.33) * 0.3];
  if (mode !== "hurt") { g.fillStyle = C.cheek; for (const s of [-1, 1]) { ell(hx + s * (CUTE ? 86 : 80), ey + (CUTE ? 34 : 46), 13, 7.5); g.fill(); } }
  if (A.freckles) { g.fillStyle = COL.spot; for (const s of [-1, 1]) for (const [dx, dy] of [[-8, 0], [6, -4], [4, 8]]) { ell(hx + s * (80 + dx), ey + 44 + dy, 2.5, 2.5); g.fill(); } }
  const my = ey + (CUTE ? 46 : 62);
  g.lineWidth = 5; g.strokeStyle = C.line; g.lineCap = "round";
  g.beginPath();
  if (EAT) { const o2 = Math.abs(Math.sin(t * 9)); g.fillStyle = "#8a2f3a"; ell(hx, my, 11, 3 + o2 * 9); g.fill(); }
  else if (mode === "happy") g.arc(hx, my - 10, 16, 0.15 * Math.PI, 0.85 * Math.PI);
  else if (mode === "angry") { g.moveTo(hx - 16, my + 4); for (let i = 1; i <= 4; i++) g.lineTo(hx - 16 + i * 8, my + (i % 2 ? -3 : 4)); }
  else if (mode === "party" || mode === "wee") { g.moveTo(hx - 20, my - 6); g.quadraticCurveTo(hx, my + 28, hx + 20, my - 6); g.closePath(); g.fillStyle = "#8a2f3a"; g.fill(); }
  else if (mode === "hurt") { g.moveTo(hx - 14, my + 4); g.quadraticCurveTo(hx - 7, my - 5, hx, my + 2); g.quadraticCurveTo(hx + 7, my + 9, hx + 14, my); }
  else if (mode === "sleep") ell(hx, my, 6, 4 + Math.sin(t * 0.9) * 2);
  else if (mode === "work") { g.moveTo(hx - 12, my + 1); g.quadraticCurveTo(hx, my - 3, hx + 12, my + 1); }
  else if (SAD) { g.moveTo(hx - 14, my + 6); g.quadraticCurveTo(hx, my - 6, hx + 14, my + 6); }
  else { g.moveTo(hx - 13, my - 3); g.quadraticCurveTo(hx, my + 7, hx + 13, my - 3); }
  g.stroke();
  if (SAD) {                 // сълза
    const ty = ey + 40 + ((t * 30) % 40);
    g.fillStyle = "#8fd3ff"; g.strokeStyle = C.line; g.lineWidth = 3;
    g.beginPath(); g.moveTo(hx - 60, ty - 12); g.quadraticCurveTo(hx - 52, ty, hx - 60, ty + 4); g.quadraticCurveTo(hx - 68, ty, hx - 60, ty - 12); g.fill(); g.stroke();
  }
  if (A.paci && !NOPACI && mode !== "party") {   // биберонче за бебето
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
  // какъв е станал: цилиндър (търговец), кърпа (авантюрист), листенце (здравеняк)
  if (mode === "read") {                // чете книга
    g.save(); g.translate(hx, ey + 108 + Math.sin(t * 1.2) * 2);
    g.fillStyle = "#3a6ea5"; g.strokeStyle = C.line; g.lineWidth = 5;
    g.beginPath(); g.moveTo(-72, -6); g.lineTo(0, 6); g.lineTo(72, -6); g.lineTo(72, 50); g.lineTo(0, 62); g.lineTo(-72, 50); g.closePath(); g.fill(); g.stroke();
    g.fillStyle = "#fffaf0"; g.lineWidth = 3;
    for (const sg of [-1, 1]) { g.beginPath(); g.moveTo(0, 6); g.lineTo(sg * 64, -2); g.lineTo(sg * 64, 44); g.lineTo(0, 54); g.closePath(); g.fill(); g.stroke(); }
    g.strokeStyle = "rgba(43,42,51,.45)"; g.lineWidth = 2.5;
    for (let i = 0; i < 4; i++) for (const sg of [-1, 1]) { g.beginPath(); g.moveTo(sg * 10, 16 + i * 9); g.lineTo(sg * 52, 10 + i * 9); g.stroke(); }
    if (((t * 0.4) % 1) < 0.12) { g.fillStyle = "#fffaf0"; g.strokeStyle = C.line; g.beginPath(); g.moveTo(0, 6); g.quadraticCurveTo(30, -30, 50, -10); g.lineTo(0, 54); g.closePath(); g.fill(); g.stroke(); }
    g.restore();
  }
  if (PLASTER) {                                  // превръзка около главата с червен кръст
    g.save(); g.translate(cx, cy - ry * 0.55); g.rotate(-0.08); g.fillStyle = "#fffaf0"; g.strokeStyle = C.line; g.lineWidth = 4;
    g.beginPath(); g.moveTo(-118, 0); g.quadraticCurveTo(0, -26, 118, 0); g.lineTo(116, 24); g.quadraticCurveTo(0, 0, -116, 24); g.closePath(); g.fill(); g.stroke();
    g.fillStyle = "#e5383b"; g.fillRect(-6, -14, 12, 30); g.fillRect(-15, -5, 30, 12); g.restore(); }
  if (HAT) drawHat(HAT, cx, cy, ry, t);
  if (TR.includes("adventure") && !TR.includes("trader") && !HAT) {     // изследователска шапка с перо
    g.save(); g.translate(cx - 6, cy - ry * 0.9); g.rotate(-0.12); g.scale(1.35, 1.35);
    g.fillStyle = "#d8b878"; g.strokeStyle = C.line; g.lineWidth = 5;
    g.beginPath(); g.ellipse(0, 4, 78, 15, 0, 0, Math.PI * 2); g.fill(); g.stroke();
    g.beginPath(); g.moveTo(-48, 4); g.quadraticCurveTo(-46, -54, 0, -56); g.quadraticCurveTo(46, -54, 48, 4); g.closePath(); g.fill(); g.stroke();
    g.fillStyle = "#7a4a26"; g.beginPath(); g.rect(-47, -12, 94, 12); g.fill(); g.stroke();
    g.fillStyle = "#e5383b"; g.beginPath(); g.moveTo(30, -10); g.quadraticCurveTo(60, -60, 44, -78); g.quadraticCurveTo(36, -40, 26, -12); g.closePath(); g.fill(); g.stroke();
    g.restore();
  }
  if (TR.includes("trader") && !HAT) {
    g.save(); g.translate(cx + 10, cy - ry * 0.98); g.rotate(0.12);
    g.fillStyle = "#2b2a33"; g.strokeStyle = "#111"; g.lineWidth = 4;
    g.beginPath(); g.ellipse(0, 0, 62, 13, 0, 0, Math.PI * 2); g.fill(); g.stroke();
    g.beginPath(); g.roundRect(-38, -78, 76, 78, 6); g.fill(); g.stroke();
    g.fillStyle = "#c9a227"; g.fillRect(-38, -24, 76, 12);
    g.restore();
  }
  if (TR.includes("healthy")) {
    g.save(); g.translate(cx + 30, cy - ry * 0.98); g.rotate(0.5);
    g.strokeStyle = C.line; g.lineWidth = 4; g.beginPath(); g.moveTo(0, 6); g.lineTo(0, -14); g.stroke();
    g.fillStyle = "#57c08a"; g.beginPath(); g.ellipse(14, -22, 16, 8, -0.5, 0, Math.PI * 2); g.fill(); g.stroke();
    g.restore();
  }
  if (TR.includes("grumpy") && mode === "idle") {
    g.strokeStyle = C.line; g.lineWidth = 6; g.lineCap = "round";
    for (const sg of [-1, 1]) { g.beginPath(); g.moveTo(hx + sg * 30, ey - 58); g.lineTo(hx + sg * 82, ey - 70); g.stroke(); }
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
  const cloudY = WORK ? WORK[1] : 62 + 150 * A.tL, cloudX = WORK ? WORK[0] : 0;
  if (mode === "work") {
    if (WORK) { g.save(); g.translate(cloudX, cloudY); g.scale(0.7, 0.7); brawl(0, 0, t); g.restore(); } else brawl(0, cloudY, t);
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
  if (mode === "sleep" && !LIE) zzz(t, 125 * A.head, headTop + 90);
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

// ---------- Нарисуваните кадри (art/*.png) ----------
const ART = { idle: 6 };              // поза: брой кадри
const IMG = {};
let tint = null;
function artFrames(pose) {
  if (!IMG[pose]) {
    IMG[pose] = [];
    for (let i = 1; i <= ART[pose]; i++) { const im = new Image(); im.src = `art/${pose}_${i}.png?v=${VER}`; IMG[pose].push(im); }
  }
  const list = IMG[pose];
  return list.every(im => im.complete && im.naturalWidth) ? list : null;
}
let LINE = null;
function artLine() {
  if (!LINE) { LINE = new Image(); LINE.src = `art/idle_1_line.png?v=${VER}`; }
  return LINE.complete && LINE.naturalWidth ? LINE : null;
}
function artReady() { return !!artFrames("idle"); }

// Лицето върху нарисувания кадър: очите и устата се рисуват наново, за да се движат (в пиксели на 512×512 кадъра)
const EYES = [{ x: 202, y: 167, rx: 44, ry: 46, s: -1 }, { x: 337, y: 166, rx: 42, ry: 46, s: 1 }];
const SKIN = "rgb(252,106,31)", INK = "#120f18";
let comp = null;
function lookAround(t, st) {
  if (LOOK) return LOOK;
  if (!st.lt || t > st.lnext) {                 // от време на време поглежда нанякъде
    st.lt = Math.random() < 0.35 ? [0, 0] : [rnd(-1, 1), rnd(-0.6, 0.7)];
    st.lnext = t + rnd(1.2, 3.5);
  }
  st.lc = st.lc || [0, 0];
  st.lc[0] += (st.lt[0] - st.lc[0]) * 0.25; st.lc[1] += (st.lt[1] - st.lc[1]) * 0.25;
  return st.lc;
}
function lidCover(e, amt, slant) {               // клепач отгоре до amt (0..1), наклонен
  g.save(); ell(e.x, e.y, e.rx, e.ry); g.clip();
  const yb = e.y - e.ry + amt * 2 * e.ry;
  g.fillStyle = SKIN; g.beginPath(); g.moveTo(e.x - e.rx - 2, e.y - e.ry - 2); g.lineTo(e.x + e.rx + 2, e.y - e.ry - 2);
  g.lineTo(e.x + e.rx + 2, yb + slant * e.s); g.lineTo(e.x - e.rx - 2, yb - slant * e.s); g.closePath(); g.fill();
  g.strokeStyle = INK; g.lineWidth = 6; g.lineCap = "round";
  g.beginPath(); g.moveTo(e.x - e.rx, yb - slant * e.s); g.lineTo(e.x + e.rx, yb + slant * e.s); g.stroke();
  g.restore();
}
function artFace(t, st) {
  const look = lookAround(t, st);
  const bt = t % 4.3, blinkAmt = bt < 0.18 ? Math.sin(bt / 0.18 * Math.PI) : (((t + 1.7) % 9.1) < 0.18 ? 1 : 0);
  g.lineCap = "round"; g.lineJoin = "round";
  // устата: замазвам оригиналната
  const mg = g.createRadialGradient(270, 191, 4, 270, 191, 24);
  mg.addColorStop(0, SKIN); mg.addColorStop(0.75, SKIN); mg.addColorStop(1, "rgba(252,106,31,0)");
  g.fillStyle = mg; ell(270, 191, 26, 13); g.fill();
  const closedFace = mode === "happy" || mode === "party" || mode === "wee" || mode === "sleep" || mode === "hurt";
  g.globalCompositeOperation = "source-atop";     // не излиза извън тялото
  for (const e of EYES) {
    if (closedFace) {
      g.fillStyle = SKIN; ell(e.x, e.y, e.rx + 3, e.ry + 3); g.fill();
      g.strokeStyle = INK; g.lineWidth = 7; g.beginPath();
      if (mode === "sleep") g.arc(e.x, e.y - 6, e.rx * 0.6, 0.15 * Math.PI, 0.85 * Math.PI);
      else if (mode === "hurt") { const q = 16; g.moveTo(e.x + e.s * q, e.y - q); g.lineTo(e.x - e.s * q, e.y); g.lineTo(e.x + e.s * q, e.y + q); }
      else g.arc(e.x, e.y + 12, e.rx * 0.55, 1.15 * Math.PI, 1.85 * Math.PI);
      g.stroke();
      continue;
    }
    // бялото с лека сянка горе
    g.save(); ell(e.x, e.y, e.rx, e.ry); g.clip();
    g.fillStyle = "#dfe4ee"; g.fillRect(e.x - e.rx, e.y - e.ry, e.rx * 2, e.ry * 2);
    g.fillStyle = "#fbfbfd"; ell(e.x + 3, e.y + 7, e.rx, e.ry); g.fill();
    // зеницата
    let lx = look[0], ly = look[1], pk = 1;
    if (mode === "work") { lx = -e.s * 0.35; ly = 0.75; }
    if (mode === "angry") { lx = 0; ly = 0.1; pk = 0.85; }
    const px = e.x + lx * e.rx * 0.36, py = e.y + ly * e.ry * 0.33 + 4;
    const prx = e.rx * 0.56 * pk, pry = e.ry * 0.62 * pk;
    g.fillStyle = INK; ell(px, py, prx, pry); g.fill();
    g.fillStyle = "#fff"; ell(px - prx * 0.32, py - pry * 0.38, prx * 0.3, prx * 0.3); g.fill();
    ell(px + prx * 0.35, py + pry * 0.38, prx * 0.11, prx * 0.11); g.fill();
    g.restore();
    if (mode === "work") lidCover(e, 0.42, 0);
    else if (mode === "angry") lidCover(e, 0.36, 10);
    else if (blinkAmt > 0) lidCover(e, blinkAmt * 0.98, 0);
    g.strokeStyle = INK; g.lineWidth = 6; ell(e.x, e.y, e.rx, e.ry); g.stroke();
  }
  g.globalCompositeOperation = "source-over";
  const line = artLine();                          // контурът на тялото отгоре, ако е покрит от очите
  if (line) g.drawImage(line, 0, 0, 512, 512);
  if (mode === "angry") {                       // вежди
    g.strokeStyle = INK; g.lineWidth = 10;
    g.beginPath(); g.moveTo(160, 112); g.lineTo(236, 132); g.stroke();
    g.beginPath(); g.moveTo(378, 110); g.lineTo(304, 131); g.stroke();
  }
  if (mode === "happy" || mode === "party" || mode === "wee") {   // руменина
    g.fillStyle = "rgba(255,120,140,.55)"; ell(186, 222, 18, 9); g.fill(); ell(352, 220, 18, 9); g.fill();
  }
  // устата
  const mx = 270, my = 191;
  g.strokeStyle = INK; g.lineWidth = 5; g.beginPath();
  if (mode === "happy" || mode === "wee") g.arc(mx, my - 8, 13, 0.15 * Math.PI, 0.85 * Math.PI);
  else if (mode === "party") { g.moveTo(mx - 16, my - 5); g.quadraticCurveTo(mx, my + 24, mx + 16, my - 5); g.closePath(); g.fillStyle = "#7a1f2b"; g.fill(); }
  else if (mode === "angry") { g.moveTo(mx - 14, my + 3); for (let i = 1; i <= 4; i++) g.lineTo(mx - 14 + i * 7, my + (i % 2 ? -3 : 3)); }
  else if (mode === "sleep") ell(mx, my, 5, 3.5 + Math.sin(t * 0.9) * 1.5);
  else if (mode === "hurt") { g.moveTo(mx - 12, my + 3); g.quadraticCurveTo(mx - 6, my - 4, mx, my + 2); g.quadraticCurveTo(mx + 6, my + 8, mx + 12, my); }
  else if (mode === "work") { g.moveTo(mx - 10, my); g.quadraticCurveTo(mx, my - 3, mx + 10, my); }
  else { g.moveTo(mx - 11, my + 3); g.quadraticCurveTo(mx, my - 4, mx + 11, my + 3); }
  g.stroke();
  if (mode === "work") {                        // изплезва се от време на време
    const tp = t % 3.4, out = tp < 1.6 ? Math.min(1, tp / 0.25, (1.6 - tp) / 0.25) : 0;
    if (out > 0) {
      g.save(); g.translate(mx + 6, my); g.rotate(0.55 + Math.sin(t * 14) * 0.18);
      g.fillStyle = "#ff7d92"; g.strokeStyle = INK; g.lineWidth = 3.5;
      g.beginPath(); g.moveTo(-7, 0); g.lineTo(-7, 8 + 13 * out); g.arc(0, 8 + 13 * out, 7, Math.PI, 0, true); g.lineTo(7, 0); g.fill(); g.stroke();
      g.restore();
    }
  }
}
function drawArt(t, mt, st) {
  const frames = artFrames("idle");
  const fps = { idle: 7, happy: 10, party: 14, work: 14, hurt: 5, sleep: 3, wee: 12, angry: 16 }[mode] || 7;
  const n = frames.length, cyc = Math.floor(t * fps) % (2 * n - 2);
  const im = STATIC ? frames[0] : frames[cyc < n ? cyc : 2 * n - 2 - cyc];   // статично или напред-назад
  let bob = Math.sin(t * 1.6 * SP) * (STATIC ? 3 : 6), tilt = Math.sin(t * 0.8) * (STATIC ? 0.012 : 0.03), sq = 1 + Math.sin(t * 1.6 * SP) * (STATIC ? 0.012 : 0.02), shx = 0;
  if (mode === "happy") { bob = Math.sin(t * 3.4) * 9; tilt = Math.sin(t * 1.7) * 0.06; }
  if (mode === "party") { const j = Math.abs(Math.sin(t * 6)); bob = -j * 45; sq = 1 + (j - 0.4) * 0.1; }
  if (mode === "wee") { tilt = Math.sin(t * 5) * 0.15; }
  if (mode === "angry") { shx = Math.sin(t * 40) * 3; tilt = Math.sin(t * 30) * 0.03; }
  if (mode === "sleep") { bob = 8 + Math.sin(t * 0.9) * 3; tilt = 0.1; sq = 1 + Math.sin(t * 0.9) * 0.03; }
  if (mode === "hurt") { tilt = -0.06 + (mt < 0.6 ? Math.sin(mt * 50) * 0.1 * (1 - mt / 0.6) : Math.sin(t * 2.4) * 0.04); }
  if (mode === "work") { bob = Math.sin(t * 9) * 2; shx = Math.sin(t * 23) * 2; }
  const f = 1.12, S = 512 * f, top = -138, bottom = top + (365 - 41) * f;
  if (GROUND != null) {
    if (DROP) { const drop = Math.max(0, GROUND - bottom); g.translate(0, drop); GROUND -= drop; }
    const sh = 1 - Math.min(0.45, -Math.min(0, bob) / 90);
    g.fillStyle = "rgba(60,55,75,.22)"; ell(0, GROUND + 10, 190 * sh, 20 * sh); g.fill();
  }
  g.save();
  g.translate(shx, bob + bottom); g.rotate(tilt); g.scale(1 / sq, sq); g.translate(0, -bottom);
  comp = comp || document.createElement("canvas");
  comp.width = im.naturalWidth; comp.height = im.naturalHeight;
  const outer = g, c = comp.getContext("2d");
  c.clearRect(0, 0, comp.width, comp.height); c.drawImage(im, 0, 0);
  if (STATIC) { g = c; c.save(); c.scale(comp.width / 512, comp.height / 512); artFace(t, st); c.restore(); g = outer; }
  if (mode === "angry" || mode === "sleep") {     // оцветяване: червено при яд, синкаво в съня
    c.globalCompositeOperation = "source-atop";
    c.fillStyle = mode === "angry" ? `rgba(230,30,30,${0.22 + Math.sin(t * 6) * 0.07})` : "rgba(40,30,110,.25)";
    c.fillRect(0, 0, comp.width, comp.height); c.globalCompositeOperation = "source-over";
  }
  const src = comp;
  g.drawImage(src, -S / 2, top - 41 * f, S, S);
  if (mode === "hurt") {                          // лепенка
    g.save(); g.translate(60, top + 40);
    for (const a of [0.75, -0.75]) {
      g.save(); g.rotate(a); g.fillStyle = "#f6dfb4"; g.strokeStyle = C.line; g.lineWidth = 4;
      g.beginPath(); g.roundRect(-30, -10, 60, 20, 9); g.fill(); g.stroke(); g.restore();
    }
    g.fillStyle = "#e3c389"; g.fillRect(-8, -8, 16, 16); g.restore();
  }
  g.restore();
  // ефекти около него
  const cloudY = bottom - 30;
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
  if (mode === "hurt") for (let i = 0; i < 3; i++) { const a = t * 2.5 + i * Math.PI * 2 / 3; star(Math.cos(a) * 100, top - 14 + Math.sin(a) * 14, 13); }
  if (mode === "sleep" && !LIE) zzz(t, 110, top + 70);
  if (mode === "angry") anger(100, top + 30, 1 + Math.sin(t * 10) * 0.12);
}

// ---------- Стил „Скица“: химикал в тетрадка ----------
// Рисува се в малки единици (глава ~50) и се увеличава ×2.
const SK = { ink: "#23395d", red: "#d63b3b" };
let SEED = 0, DIR = 1;
function jit(i, a = 1.6) { const v = Math.sin(SEED * 12.9898 + i * 78.233) * 43758.5453; return (v - Math.floor(v) - 0.5) * a; }
function skFill(age) {
  if (mode === "angry") return "#ff9a8a";
  return { baby: "#ffe39a", kid: "#ffdb7d", teen: "#ffd36b", adult: "#ffd36b", aging: "#f4d27c", old: "#efdcaa" }[age] || "#ffd36b";
}
function skHead(sc = 1) {
  g.beginPath(); g.moveTo(-50 * sc, 10 * sc);
  g.bezierCurveTo(-56 * sc, -60 * sc, 56 * sc, -60 * sc, 50 * sc, 10 * sc);
  g.bezierCurveTo(46 * sc, 40 * sc, -46 * sc, 40 * sc, -50 * sc, 10 * sc); g.closePath();
}
function skTents(t, pulse, L) {
  const out = [], n = 8, N = 26;
  for (let i = 0; i < n; i++) {
    const o = i - (n - 1) / 2, sg = Math.sign(o);
    let x = o * 12, y = 14, ang = Math.PI / 2 + o * 0.4;
    if (mode === "swim") ang = Math.PI / 2 + o * (0.05 + pulse * 0.16);
    if (mode === "angry") ang = Math.PI / 2 + o * 0.52;
    if (mode === "sleep") ang = Math.PI / 2 + o * 0.56;
    if (mode === "party" && Math.abs(o) > 2) ang = Math.PI / 2 + o * 0.6;
    if (mode === "work") ang = Math.PI / 2 + o * 0.26;
    const pts = [];
    for (let j = 0; j <= N; j++) {
      const k = j / N;
      pts.push([x, y, k]);
      let d;
      if (mode === "swim") d = Math.sin(t * 5.2 + i * 0.5 - j * 0.3) * 0.07 * (0.3 + k) + (k > 0.8 ? -sg * 0.05 : 0);
      else if (mode === "angry") d = Math.sin(t * 14 + i * 1.3 - j * 0.4) * 0.045 * (0.3 + k) - sg * (k > 0.62 ? 0.13 : 0.012);
      else if (mode === "party") d = Math.sin(t * 9 + i - j * 0.4) * 0.06 * (0.3 + k) - sg * (Math.abs(o) > 2 ? 0.075 : k > 0.6 ? 0.1 : 0);
      else if (mode === "wee") d = Math.sin(t * 7 + i - j * 0.4) * 0.06 * (0.3 + k) - sg * 0.02;
      else if (mode === "work") d = Math.sin(t * 13 + i * 1.7 - j * 0.5) * 0.06 * (0.3 + k);
      else if (mode === "sleep") d = Math.sin(t * 0.8 + i - j * 0.2) * 0.008 - sg * (k > 0.5 ? 0.06 : 0.01);
      else if (mode === "hurt") d = Math.sin(t * 1.4 + i - j * 0.2) * 0.012 - sg * (k > 0.7 ? 0.08 : 0);
      else d = Math.sin(t * 2.2 * SP + i * 0.9 - j * 0.25) * 0.02 * (0.3 + k) - sg * (k > 0.62 ? 0.15 : 0.004);
      ang += d;
      x += Math.cos(ang) * L / N; y += Math.sin(ang) * L / N;
      if (GROUND != null && y > GROUND) y = GROUND;
    }
    out.push(pts);
  }
  return out;
}
function skTube(pts, i, w0, fill, outlineW) {
  g.fillStyle = fill;
  for (const [x, y, k] of pts) { g.beginPath(); g.arc(x + 2, y + 2, w0 * (1 - 0.7 * k), 0, Math.PI * 2); g.fill(); }
  g.strokeStyle = SK.ink; g.lineWidth = outlineW; g.lineCap = "round"; g.lineJoin = "round";
  for (const side of [-1, 1]) {
    g.beginPath();
    pts.forEach(([x, y, k], j) => {
      const a = pts[Math.min(j + 1, pts.length - 1)], b = pts[Math.max(j - 1, 0)];
      let nx = -(a[1] - b[1]), ny = a[0] - b[0]; const l = Math.hypot(nx, ny) || 1;
      const w = w0 * (1 - 0.7 * k);
      const X = x + nx / l * w * side + jit(i * 50 + j + side * 300), Y = y + ny / l * w * side + jit(i * 50 + j + 7 + side * 300);
      j ? g.lineTo(X, Y) : g.moveTo(X, Y);
    });
    g.stroke();
  }
  const [ex, ey, ek] = pts[pts.length - 1];       // заоблен връх
  g.beginPath(); g.arc(ex, ey, w0 * (1 - 0.7 * ek), 0, Math.PI * 2); g.stroke();
  for (let j = 8; j < pts.length - 3; j += 5) {   // вендузи като малки кръгчета
    const [x, y, k] = pts[j], w = w0 * (1 - 0.7 * k);
    g.lineWidth = 1; g.beginPath(); g.arc(x + jit(j + i * 9) * 0.5, y + w * 0.35, Math.max(1, w * 0.3), 0, Math.PI * 2); g.stroke();
  }
}
function skEyes(t, age) {
  const ink = SK.ink, fill = skFill(age);
  const bt = t % 4.1, bl = bt < 0.16 ? Math.sin(bt / 0.16 * Math.PI) : 0;
  const r = age === "baby" ? 14 : 12, ex = 21;
  let look = LOOK || [Math.sin(t * 0.5) * 0.6, Math.sin(t * 0.33) * 0.3];
  if (mode === "swim") look = [0.7, -0.1];
  if (mode === "work") look = [0, 0.8];
  g.lineCap = "round"; g.lineJoin = "round";
  for (const s of [-1, 1]) {
    const x = s * ex, y = 2;
    g.strokeStyle = ink; g.lineWidth = 2.6;
    if (mode === "happy" || mode === "party" || mode === "wee") { g.beginPath(); g.arc(x, y + 5, r * 0.6, 1.15 * Math.PI, 1.85 * Math.PI); g.stroke(); continue; }
    if (mode === "sleep") { g.beginPath(); g.arc(x, y - 2, r * 0.6, 0.15 * Math.PI, 0.85 * Math.PI); g.stroke(); continue; }
    if (mode === "hurt") { const q = 7; g.beginPath(); g.moveTo(x + s * q, y - q); g.lineTo(x - s * q, y); g.lineTo(x + s * q, y + q); g.stroke(); continue; }
    g.fillStyle = "#fffdf6"; ell(x, y, r, r * 1.12); g.fill();
    g.lineWidth = 2; g.beginPath(); g.ellipse(x + jit(s * 3), y + jit(s * 5), r, r * 1.12, 0, 0, Math.PI * 2); g.stroke();
    const pk = mode === "angry" ? 0.5 : 0.58;
    const px = x + look[0] * r * 0.42, py = y + look[1] * r * 0.38 + 1;
    g.fillStyle = ink; ell(px, py, r * pk, r * pk * 1.12); g.fill();
    g.fillStyle = "#fff"; ell(px - r * 0.2, py - r * 0.24, r * 0.2, r * 0.2); g.fill();
    let lid = 0, sl = 0;
    if (mode === "angry") { lid = 0.45; sl = 6; }
    else if (mode === "work") lid = 0.42;
    else if (age === "old") lid = 0.5;
    else if (bl > 0) lid = bl;
    if (lid > 0) {
      g.save(); ell(x, y, r + 0.5, r * 1.12 + 0.5); g.clip();
      const yb = y - r * 1.12 + lid * r * 2.24;
      g.fillStyle = fill; g.beginPath(); g.moveTo(x - r - 2, y - r * 1.3); g.lineTo(x + r + 2, y - r * 1.3);
      g.lineTo(x + r + 2, yb + s * sl); g.lineTo(x - r - 2, yb - s * sl); g.fill();
      g.strokeStyle = ink; g.lineWidth = 2.2; g.beginPath(); g.moveTo(x - r, yb - s * sl); g.lineTo(x + r, yb + s * sl); g.stroke();
      g.restore();
    }
  }
}
function skMouth(t, age) {
  const ink = SK.ink, y = 20;
  g.strokeStyle = ink; g.lineWidth = 2; g.lineCap = "round"; g.beginPath();
  if (mode === "happy" || mode === "wee") g.arc(0, y - 4, 6, 0.15 * Math.PI, 0.85 * Math.PI);
  else if (mode === "party") { g.moveTo(-8, y - 2); g.quadraticCurveTo(0, y + 12, 8, y - 2); g.closePath(); g.fillStyle = "#e86a6a"; g.fill(); }
  else if (mode === "angry") { g.moveTo(-8, y + 2); for (let i = 1; i <= 4; i++) g.lineTo(-8 + i * 4, y + (i % 2 ? -1.5 : 2)); }
  else if (mode === "sleep") g.ellipse(0, y, 2.5, 1.8 + Math.sin(t * 0.9), 0, 0, Math.PI * 2);
  else if (mode === "hurt") { g.moveTo(-6, y + 1); g.quadraticCurveTo(-3, y - 2, 0, y + 1); g.quadraticCurveTo(3, y + 4, 6, y); }
  else if (mode === "work") { g.moveTo(-5, y); g.lineTo(5, y - 1); }
  else { g.moveTo(-5, y); g.quadraticCurveTo(0, y + 4, 5, y); }
  g.stroke();
  if (mode === "work") {                           // езикът навън
    const tp = t % 3.4, out = tp < 1.6 ? Math.min(1, tp / 0.25, (1.6 - tp) / 0.25) : 0;
    if (out > 0) { g.save(); g.translate(3, y); g.rotate(0.5 + Math.sin(t * 14) * 0.18);
      g.fillStyle = "#ff8a9a"; g.lineWidth = 1.6; g.beginPath(); g.moveTo(-3.5, 0); g.lineTo(-3.5, 4 + 6 * out); g.arc(0, 4 + 6 * out, 3.5, Math.PI, 0, true); g.lineTo(3.5, 0); g.fill(); g.stroke(); g.restore(); }
  }
  if (age === "baby" && mode !== "party") {        // биберонче
    g.fillStyle = "#9fd3ff"; g.lineWidth = 1.6; ell(0, y + 3, 9, 5); g.fill(); g.stroke();
    g.fillStyle = "#ffd36b"; ell(0, y + 3, 2.5, 2.5); g.fill(); g.stroke();
  }
  if (age === "old") {                             // бели мустаци
    g.fillStyle = "#fff"; g.lineWidth = 1.6;
    for (const s of [-1, 1]) { g.beginPath(); g.ellipse(s * 7, y - 3, 9, 4.5, s * 0.35, 0, Math.PI * 2); g.fill(); g.stroke(); }
  }
}
function skSpecs(age) {                            // кръгли очила за застаряващия и стария
  if (age !== "aging" && age !== "old") return;
  const y = mode === "sleep" ? -26 : 2;
  g.strokeStyle = SK.ink; g.lineWidth = 1.8;
  for (const s of [-1, 1]) { g.beginPath(); g.arc(s * 21, y, 15, 0, Math.PI * 2); g.stroke(); }
  g.beginPath(); g.moveTo(-6, y - 2); g.quadraticCurveTo(0, y - 6, 6, y - 2); g.stroke();
  g.beginPath(); g.moveTo(-36, y - 2); g.lineTo(-48, y - 6); g.moveTo(36, y - 2); g.lineTo(48, y - 6); g.stroke();
  g.strokeStyle = "rgba(120,170,230,.6)"; g.lineWidth = 1.5;
  for (const s of [-1, 1]) { g.beginPath(); g.moveTo(s * 21 - 8, y - 6); g.lineTo(s * 21 - 3, y - 11); g.stroke(); }
}
function skBody(t, mt, st, age) {
  SEED = Math.floor(t * 8);
  const fill = skFill(age), ink = SK.ink;
  const pulse = (Math.sin(t * 5.2) + 1) / 2;
  let bob = Math.sin(t * 2 * SP) * 3, rot = Math.sin(t * 0.8) * 0.03, sx = 1, sy = 1 + Math.sin(t * 2 * SP) * 0.015, shx = 0;
  if (mode === "swim") { rot = DIR * 0.8; sx = 1 + pulse * 0.05; sy = 1 - pulse * 0.08; bob = Math.sin(t * 2.6) * 4; }
  if (mode === "happy") { bob = Math.sin(t * 3.4) * 5; rot = Math.sin(t * 1.7) * 0.07; }
  if (mode === "party") { const j = Math.abs(Math.sin(t * 6 * SP)); bob = -j * 22 * (age === "old" ? 0.4 : 1); sy = 1 + (j - 0.4) * 0.08; }
  if (mode === "wee") rot = Math.sin(t * 5) * 0.15;
  if (mode === "angry") { shx = Math.sin(t * 45) * 1.5; rot = Math.sin(t * 30) * 0.03; const pf = 1 + Math.sin(t * 7) * 0.035; sx = pf; sy = pf; }
  if (mode === "sleep") { bob = 4 + Math.sin(t * 0.9) * 1.5; rot = 0.1; sy = 1 + Math.sin(t * 0.9) * 0.03; }
  if (mode === "hurt") rot = -0.06 + (mt < 0.6 ? Math.sin(mt * 50) * 0.1 * (1 - mt / 0.6) : Math.sin(t * 2.4) * 0.04);
  if (mode === "work") { bob = Math.sin(t * 9) * 1; shx = Math.sin(t * 23) * 1; }
  if (age === "old") rot += 0.08;
  const L = 100 * A.tL, bottom = 14 + L * 0.92;
  if (GROUND != null) {
    if (DROP) { const drop = Math.max(0, GROUND - bottom); g.translate(0, drop); GROUND -= drop; }
    g.strokeStyle = "rgba(35,57,93,.35)"; g.lineWidth = 1.2;              // сянка с щрихи
    for (let x = -60; x <= 60; x += 6) { g.beginPath(); g.moveTo(x, GROUND + 4); g.lineTo(x + 5, GROUND - 1); g.stroke(); }
  }
  g.save(); g.translate(shx, bob); g.rotate(rot); g.scale(sx, sy);
  const tt = skTents(t, pulse, L);
  if (A.cane && mode !== "swim") {                 // бастун
    const p = tt[7][16], bot = GROUND != null ? GROUND - bob : p[1] + 70;
    g.strokeStyle = "#8a5a2b"; g.lineWidth = 3.5; g.lineCap = "round";
    g.beginPath(); g.moveTo(p[0] + 4, bot); g.lineTo(p[0] + 4, p[1] - 6); g.arc(p[0] - 4, p[1] - 6, 8, 0, Math.PI * 1.05, true); g.stroke();
    g.strokeStyle = ink; g.lineWidth = 1.2; g.stroke();
  }
  tt.forEach((pts, i) => skTube(pts, i, 9.5 * A.tW, fill, 1.8));
  // главата
  g.save(); g.translate(0, 14); g.scale(A.head, A.head); g.translate(0, -14);
  g.save(); g.translate(3, 3); skHead(); g.fillStyle = fill; g.fill(); g.restore();
  g.strokeStyle = ink; g.lineWidth = 2.2;
  for (let pass = 0; pass < 2; pass++) { g.save(); g.translate(jit(pass * 3), jit(pass * 3 + 1)); skHead(); g.stroke(); g.restore(); }
  g.save(); skHead(); g.clip(); g.strokeStyle = "rgba(35,57,93,.3)"; g.lineWidth = 1.1;
  for (let x = 10; x < 70; x += 6) { g.beginPath(); g.moveTo(x, 40); g.lineTo(x + 30, -10); g.stroke(); }
  if (A.wrinkles) { g.strokeStyle = ink; g.lineWidth = 1.4; for (let i = 0; i < A.wrinkles; i++) { g.beginPath(); g.arc(0, -16 - i * 6, 14 - i * 2, 1.2 * Math.PI, 1.8 * Math.PI); g.stroke(); } }
  if (mode === "angry") { g.fillStyle = "rgba(214,59,59,.15)"; skHead(); g.fill(); }
  g.restore();
  if (age === "kid" || age === "teen") { g.fillStyle = "rgba(139,90,43,.55)"; for (const s of [-1, 1]) for (const [dx, dy] of [[-3, 0], [3, -2], [1, 3]]) { ell(s * 32 + dx, 13 + dy, 1.2, 1.2); g.fill(); } }
  if (mode !== "hurt" && mode !== "angry") {       // руменина с молив
    g.strokeStyle = "rgba(230,90,110,.55)"; g.lineWidth = 1.3;
    for (const s of [-1, 1]) for (let i = 0; i < 4; i++) { g.beginPath(); g.moveTo(s * 32 - 6 + i * 3, 18); g.lineTo(s * 32 - 3 + i * 3, 12); g.stroke(); }
  }
  skEyes(t, age); skSpecs(age); skMouth(t, age);
  if (mode === "angry" || (mode === "work" && age !== "old")) {
    g.strokeStyle = ink; g.lineWidth = 3; g.lineCap = "round";
    const yy = mode === "work" ? -12 : -16;
    g.beginPath(); g.moveTo(-34, yy - 6); g.lineTo(-9, yy + 2); g.stroke();
    g.beginPath(); g.moveTo(34, yy - 6); g.lineTo(9, yy + 2); g.stroke();
  }
  if (A.brows) {                                   // бели рунтави вежди
    g.strokeStyle = ink; g.lineWidth = 6; g.lineCap = "round";
    for (const s of [-1, 1]) { g.beginPath(); g.moveTo(s * 10, -16); g.quadraticCurveTo(s * 22, -22, s * 34, -15); g.stroke(); }
    g.strokeStyle = A.brows; g.lineWidth = 3.6; for (const s of [-1, 1]) { g.beginPath(); g.moveTo(s * 10, -16); g.quadraticCurveTo(s * 22, -22, s * 34, -15); g.stroke(); }
  }
  if (mode === "hurt") {                           // лепенка
    g.save(); g.translate(22, -30);
    for (const a of [0.75, -0.75]) { g.save(); g.rotate(a); g.fillStyle = "#f6dfb4"; g.strokeStyle = ink; g.lineWidth = 1.6; g.beginPath(); g.roundRect(-14, -4.5, 28, 9, 4); g.fill(); g.stroke(); g.restore(); }
    g.restore();
  }
  g.restore();
  g.restore();
  // ефекти
  const headTop = 14 - 59 * A.head;
  if (mode === "angry") {
    g.strokeStyle = SK.red; g.lineWidth = 1.8; g.beginPath();
    for (let i = 0; i <= 40; i++) { const a = i / 40 * Math.PI * 8; g.lineTo(Math.cos(a) * (18 + jit(i) * 3) + i * 0.4 - 8, headTop - 14 + Math.sin(a) * 9 + jit(i + 99)); }
    g.stroke();
    g.fillStyle = SK.red; g.font = "bold 15px 'Comic Sans MS', 'Chalkboard SE', cursive"; g.textAlign = "center"; g.fillText("#@!", 42, headTop);
  }
  if (mode === "sleep" && !LIE) {
    g.fillStyle = SK.ink; g.textAlign = "center";
    for (let i = 0; i < 3; i++) { const z = (t * 0.35 + i / 3) % 1; g.globalAlpha = Math.sin(z * Math.PI);
      g.font = `bold ${10 + z * 12}px 'Comic Sans MS', 'Chalkboard SE', cursive`; g.fillText("z", 40 + z * 22, headTop + 20 - z * 40); }
    g.globalAlpha = 1;
  }
  if (mode === "hurt") {
    g.strokeStyle = SK.ink; g.lineWidth = 1.5;
    for (let i = 0; i < 3; i++) { const a = t * 2.5 + i * 2.1, x = Math.cos(a) * 42, y = headTop - 6 + Math.sin(a) * 6;
      g.beginPath(); for (let k = 0; k < 10; k++) { const aa = -Math.PI / 2 + k * Math.PI / 5, rr = k % 2 ? 2.5 : 6; g.lineTo(x + Math.cos(aa) * rr, y + Math.sin(aa) * rr); } g.closePath(); g.fillStyle = "#ffe066"; g.fill(); g.stroke(); }
  }
  if (mode === "swim") {                           // линии зад него
    g.strokeStyle = "rgba(35,57,93,.45)"; g.lineWidth = 1.5;
    for (let i = 0; i < 3; i++) { const y = -10 + i * 14, x = -DIR * 70; g.beginPath(); g.moveTo(x, y); g.lineTo(x - DIR * 22, y); g.stroke(); }
  }
  if (mode === "work") {                           // облак от суматоха, нарисуван с химикал
    const cy = bottom - 18;
    g.fillStyle = "#fbf7ee"; g.strokeStyle = ink; g.lineWidth = 1.8;
    const puffs = [[-50, 0, 18], [-28, -12, 20], [0, -16, 22], [28, -12, 20], [50, 0, 18], [26, 10, 18], [-26, 10, 18], [0, 6, 22]];
    for (const [x, y, r] of puffs) { g.beginPath(); g.arc(x + jit(x) * 2, cy + y + jit(y) * 2, r, 0, Math.PI * 2); g.fill(); }
    for (const [x, y, r] of puffs) { g.beginPath(); g.arc(x + jit(x) * 2, cy + y + jit(y) * 2, r, Math.PI * 0.9, Math.PI * 2.1); g.stroke(); }
    g.fillStyle = "#fbf7ee"; ell(0, cy, 60, 18); g.fill();
    g.save(); g.translate(0, cy - 4); g.rotate(t * 4); g.strokeStyle = ink; g.lineWidth = 1.6; g.beginPath();
    for (let i = 0; i < 16; i++) { const rr = i % 2 ? 6 : 8.5, a = i / 16 * Math.PI * 2; g.lineTo(Math.cos(a) * rr, Math.sin(a) * rr); } g.closePath(); g.stroke(); g.beginPath(); g.arc(0, 0, 2.5, 0, Math.PI * 2); g.stroke(); g.restore();
    g.font = "bold 13px 'Comic Sans MS', 'Chalkboard SE', cursive"; g.fillStyle = ink; g.textAlign = "center";
    const words = ["бум!", "дзън", "трак", "!!", "?!"]; g.fillText(words[SEED % words.length], 40 + jit(1) * 3, cy - 26);
    if (Math.random() < 0.12) { const side = Math.random() < 0.5 ? -1 : 1;
      st.parts.push({ x: side * rnd(10, 30), y: cy - 10, vx: side * rnd(1, 2.5), vy: rnd(-4, -2.5), l: 60, k: "skbolt", a: rnd(0, 6), va: rnd(-0.3, 0.3) }); }
  }
  if (mode === "party" && Math.random() < 0.35)
    st.parts.push({ x: rnd(-140, 140), y: -170, vx: rnd(-0.5, 0.5), vy: rnd(0.6, 1.4), l: 260, c: pick(["#ff6b6b", "#ffd166", "#6fb3ff", "#6fd3a0"]), k: "conf", a: rnd(0, 6), sz: 0.45 });
}
function skEgg(t) {
  SEED = Math.floor(t * 8);
  const shake = (t % 5.5) < 0.7 ? Math.sin(t * 40) * 0.1 * (1 - (t % 5.5) / 0.7) : 0;
  const cy = GROUND != null ? GROUND - 60 : 20 + Math.sin(t * 1.3) * 3;
  g.save(); g.translate(0, cy + 58); g.rotate(Math.sin(t * 1.6) * 0.04 + shake); g.translate(0, -58);
  const path = () => { g.beginPath(); g.moveTo(0, -60); g.bezierCurveTo(34, -60, 48, 5, 48, 20); g.bezierCurveTo(48, 48, 26, 58, 0, 58);
    g.bezierCurveTo(-26, 58, -48, 48, -48, 20); g.bezierCurveTo(-48, 5, -34, -60, 0, -60); g.closePath(); };
  g.save(); g.translate(3, 3); path(); g.fillStyle = "#fff4d6"; g.fill(); g.restore();
  g.strokeStyle = SK.ink; g.lineWidth = 2.2;
  for (let pass = 0; pass < 2; pass++) { g.save(); g.translate(jit(pass), jit(pass + 5)); path(); g.stroke(); g.restore(); }
  g.save(); path(); g.clip(); g.strokeStyle = "rgba(35,57,93,.3)"; g.lineWidth = 1.1;
  for (let x = 10; x < 60; x += 6) { g.beginPath(); g.moveTo(x, 60); g.lineTo(x + 30, 0); g.stroke(); }
  g.restore();
  g.lineWidth = 1.4; for (const [x, y, r] of [[-18, -20, 6], [16, -36, 4], [22, 10, 7], [-24, 24, 5], [4, 36, 6]]) { g.beginPath(); g.arc(x + jit(x), y + jit(y), r, 0, Math.PI * 2); g.stroke(); }
  g.lineWidth = 2; g.beginPath(); g.moveTo(14, -48); g.lineTo(8, -38); g.lineTo(16, -30); g.lineTo(9, -20); g.stroke();
  // очички през пукнатината
  if ((t % 7) > 4.5) { g.fillStyle = SK.ink; ell(-6, -8, 2.5, 3); g.fill(); ell(8, -8, 2.5, 3); g.fill(); }
  g.restore();
}

let PXC = null;
function drawPixel(ctx, o) {
  const P = 6, sc = o.s || 1, w = Math.ceil(800 * sc / P), h = Math.ceil(860 * sc / P);
  PXC = PXC || document.createElement("canvas");
  if (PXC.width !== w || PXC.height !== h) { PXC.width = w; PXC.height = h; }
  const c = PXC.getContext("2d"); c.setTransform(1, 0, 0, 1, 0, 0); c.clearRect(0, 0, w, h);
  const ox = o.x - 400 * sc, oy = o.y - 600 * sc;
  c.setTransform(1 / P, 0, 0, 1 / P, -ox / P, -oy / P);
  const res = drawReal(c, { ...o, style: "goggles" });
  const im = c.getImageData(0, 0, w, h), d = im.data;
  for (let i = 0; i < d.length; i += 4) {                  // твърди ръбове и малко цветове
    if (d[i + 3] < 110) { d[i + 3] = 0; continue; }
    const a = d[i + 3] / 255; d[i + 3] = 255;
    for (let j = 0; j < 3; j++) d[i + j] = Math.round(d[i + j] / a / 40) * 40;
  }
  c.putImageData(im, 0, 0);
  ctx.save(); ctx.imageSmoothingEnabled = false; ctx.drawImage(PXC, ox, oy, w * P, h * P); ctx.restore();
  return res;
}
function drawArcade(ctx, o) {
  const age = o.age || "adult", A2 = AGES[age] || AGES.adult, k = age === "egg" ? 0.8 : A2.k, P = Math.max(2, Math.round(11 * (o.s || 1) * k));
  const t = o.t || 0, md = o.mode || "idle", GW = 32, GH = 34;
  const skin = { ...BASE, ...(A2.col || {}), ...(o.skin || {}) };
  const px = {};                                   // "x,y" → цвят
  const set = (x, y, c) => { if (x >= 0 && x < GW && y >= 0 && y < GH) px[x + "," + y] = c; };
  const bob = md === "sleep" ? 0 : Math.round(Math.sin(t * (md === "happy" || md === "party" || md === "wee" ? 7 : 2.2)) * (md === "party" ? 2 : 1));
  if (age === "egg") {
    for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) { const dx = (x - 16) / 9, dy = (y - 21) / 11.5; if (dx * dx + dy * dy < 1) set(x, y, (x + y * 3) % 11 === 0 && y > 13 ? "#d7c3a0" : y < 17 && x < 14 ? "#fffbea" : "#f3e7c8"); }
  } else {
    const hy = 11 + bob, sw = md === "sleep" ? 0.3 : md === "angry" ? 2.2 : 1;
    for (let i = 0; i < 6; i++) {                  // пипала
      const x0 = 6 + i * 4;
      for (let y = 18; y < 31; y++) {
        const kk = (y - 18) / 12, dx = Math.round(Math.sin(t * 3 * sw + i * 1.3 + y * 0.35) * 1.4 * kk + (i < 3 ? -1 : 1) * kk * kk * 3);
        set(x0 + dx, y + bob, skin.back); set(x0 + dx + 1, y + bob, y % 3 === 0 && kk > 0.2 ? skin.spot : skin.body);
      }
    }
    for (let y = 0; y < 21; y++) for (let x = 0; x < GW; x++) {            // глава
      const dx = (x - 16) / 10.5, dy = (y - hy) / 10; if (dx * dx + dy * dy >= 1) continue;
      set(x, y, dx > 0.35 && dy > 0.1 ? skin.shade : skin.body);
    }
    set(9, hy - 6, "#fff"); set(10, hy - 7, "#fff"); set(9, hy - 5, "#ffd9c4");
    const ey = hy + 1, look = md === "sad" ? 1 : 0;
    for (const cx of [11, 21]) {                    // очила
      for (let y = -4; y <= 4; y++) for (let x = -4; x <= 4; x++) {
        const d = Math.hypot(x, y); if (d > 4.3) continue;
        set(cx + x, ey + y, d > 2.9 ? "#3c4350" : "#c6ece6");
      }
      if (md === "sleep" || md === "happy" || md === "party" || md === "wee" || md === "eat") { for (let x = -2; x <= 2; x++) set(cx + x, ey + (Math.abs(x) === 2 ? 1 : 0), "#1c0a16"); }
      else if (md === "hurt") { for (let j = -1; j <= 1; j++) { set(cx + j, ey + j, "#1c0a16"); set(cx + j, ey - j, "#1c0a16"); } }
      else { const lx = Math.round(Math.sin(t * 0.5) * 1); set(cx + lx, ey + look, "#1c0a16"); set(cx + lx + 1, ey + look, "#1c0a16"); set(cx + lx, ey + look + 1, "#1c0a16"); set(cx + lx + 1, ey + look + 1, "#1c0a16"); set(cx + lx - 1, ey - 1 + look, "#fff"); }
      if (md === "angry") for (let x = -3; x <= 3; x++) set(cx + x, ey - 5 + Math.round((cx < 16 ? x : -x) * 0.4), "#1c0a16");
    }
    for (let x = 15; x <= 17; x++) set(x, ey, "#3c4350");
    set(5, ey + 1, "#e0b25a"); set(27, ey + 1, "#e0b25a");
    set(7, hy + 6, "#ff9a9a"); set(8, hy + 6, "#ff9a9a"); set(24, hy + 6, "#ff9a9a"); set(25, hy + 6, "#ff9a9a");
    const my = hy + 7;                              // уста
    if (md === "eat") { const op = Math.sin(t * 9) > 0; for (let x = 14; x <= 18; x++) { set(x, my, "#8a2f3a"); if (op) set(x, my + 1, "#8a2f3a"); } }
    else if (md === "sad" || md === "hurt") { set(14, my + 1, "#1c0a16"); for (let x = 15; x <= 17; x++) set(x, my, "#1c0a16"); set(18, my + 1, "#1c0a16"); }
    else if (md === "happy" || md === "party" || md === "wee") { set(14, my, "#1c0a16"); for (let x = 15; x <= 17; x++) set(x, my + 1, "#8a2f3a"); set(18, my, "#1c0a16"); }
    else if (md === "angry") { for (let x = 14; x <= 18; x++) set(x, my + (x % 2), "#1c0a16"); }
    else for (let x = 15; x <= 17; x++) set(x, my, "#1c0a16");
    if (md === "sad") { const ty = ey + 4 + Math.floor((t * 6) % 6); set(7, ty, "#8fd3ff"); set(7, ty + 1, "#8fd3ff"); }
    if (md === "sleep") { const zz = Math.floor(t * 2) % 3; for (const [x, y] of [[0, 0], [1, 0], [2, 0], [1, 1], [0, 2], [1, 2], [2, 2]]) set(26 + x + zz, 1 + y - zz, "#ffffff"); }
  }
  // контур: празно поле до пълно → тъмно
  const keys = Object.keys(px);
  for (const kk of keys) { const [x, y] = kk.split(",").map(Number); for (const [a, b] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { const n = (x + a) + "," + (y + b); if (!px[n]) px[n] = "#1c0a16"; } }
  let ox = Math.round(o.x - 16 * P), oy = Math.round(o.y - 19 * P);
  if (o.ground != null && md !== "swim") oy = Math.min(oy, Math.round(o.ground - 31 * P));
  if (age === "egg" && o.ground != null) oy = Math.round(o.ground - 33 * P);
  if (md === "angry") { ctx.save(); ctx.translate(Math.round(Math.sin(t * 40) * 2), 0); }
  for (const [kk, c] of Object.entries(px)) { const [x, y] = kk.split(",").map(Number); ctx.fillStyle = md === "angry" && c === skin.body ? "#f2603e" : c; ctx.fillRect(ox + x * P, oy + y * P, P, P); }
  if (md === "angry") ctx.restore();
  return { top: oy, r: 16 * P, cy: oy + 12 * P };
}
function draw(ctx, o) { return o.style === "pixel" ? drawArcade(ctx, o) : o.style === "pixelsoft" ? drawPixel(ctx, o) : drawReal(ctx, o); }
function drawReal(ctx, o) {
  g = ctx; mode = o.mode || "idle"; SAD = mode === "sad"; EAT = mode === "eat"; CRACK = o.crack || 0; NOPACI = o.paci === false; if (SAD) mode = "idle"; if (EAT) mode = "happy"; TR = o.traits || [];
  if (mode === "swim" && o.style !== "sketch") mode = "idle";
  const st = o.st || (o.st = {});
  st.parts = st.parts || [];
  if (st.mode !== mode) { st.mode = mode; st.parts = []; }
  const sc = o.s || 1;
  const age = o.age || "adult";
  A = AGES[age] || AGES.adult;
  CUTE = o.style === "cute" || o.style === "art" || o.style === "artanim";
  STATIC = o.style === "art";
  LOOK = null;
  if (o.lookAt) {                      // гледа към пръста или мишката
    const dx = o.lookAt.x - o.x, dy = o.lookAt.y - (o.y - 90 * (o.s || 1)), d = Math.hypot(dx, dy) || 1, m = Math.min(1, d / (220 * (o.s || 1)));
    LOOK = [dx / d * m, dy / d * m * 0.8];
  }
  if (o.glasses === false && A.gog === "on") A = { ...A, gog: "none", eye: 30 };   // очилата още не са пристигнали
  if (mode === "work" && age !== "egg") A = { ...A, gog: "on" };   // предпазни очила при майсторене
  if (CUTE) {                          // сладкият стил: без очила (само маска при работа), кръгла глава
    const old = age === "old", aging = age === "aging";
    A = { ...A, gog: mode === "work" ? "on" : "none", brows: null, mustache: false, paci: false, freckles: false, tuft: false,
      eye: age === "baby" ? 36 : 32, lids: old, spots: old || aging, wrinkles: old ? 3 : aging ? 1 : 0,
      col: { body: old ? "#e98a45" : "#f57c1f", shade: old ? "#cc6c30" : "#d9601a", back: old ? "#cf6e33" : "#d8641c",
             backShade: old ? "#ad5826" : "#b84f12", spot: old ? "#c2601f" : "#c85a14" } };
    C.rim = "#2f6fb0"; C.lens = "#bfe7f5";
  } else { C.rim = "#3c4350"; C.lens = "#c6ece6"; }
  COL = A.col || BASE;
  if (o.skin) COL = { ...COL, ...o.skin };          // наследникът е оцветен според храната на родителя
  SP = A.speed || 1;
  const k = sc * (age === "egg" ? 0.9 : A.k);
  LIE = !!o.lie && mode === "sleep" && age !== "egg";
  HUG = !!o.hug && mode === "sleep" && age !== "egg";
  HAT = o.hat || null; PLASTER = !!o.plaster;
  WORK = o.work && mode === "work" ? [(o.work[0] - o.x) / k, (o.work[1] - o.y) / k] : null;       // спи легнал на дъното
  GROUND = o.ground == null || LIE ? null : (o.ground - o.y) / k;
  DROP = o.drop !== false;
  g.save(); g.translate(o.x, o.y); if (LIE) g.rotate(-1.45); g.scale(k, k);
  g.lineJoin = "round";
  const sketch = o.style === "sketch";
  const skk = age === "egg" ? 1.5 : 2.3;
  if (sketch) { g.scale(skk, skk); if (GROUND != null) GROUND /= skk; DIR = o.dir || 1; }
  if (sketch) { if (age === "egg") skEgg(o.t); else skBody(o.t, o.mt || 9, st, age); }
  else if (age === "egg") egg(o.t, st);
  else if ((o.style === "art" || o.style === "artanim") && artReady()) drawArt(o.t, o.mt || 9, st);
  else body(o.t, o.mt || 9, st);
  st.parts = st.parts.filter(p => {
    p.x += p.vx; p.y += p.vy; p.vy += p.k === "spark" ? 0.28 : p.k === "conf" ? 0.02 : 0.32; p.l--;
    if (p.k === "spark") { g.strokeStyle = p.c; g.lineWidth = 4; g.lineCap = "round"; g.beginPath(); g.moveTo(p.x, p.y); g.lineTo(p.x - p.vx * 2, p.y - p.vy * 2); g.stroke(); }
    else if (p.k !== "conf") { p.a += p.va; part(p); }
    else { p.a += 0.15; g.save(); g.translate(p.x + Math.sin(p.a) * 6, p.y); g.rotate(p.a); g.fillStyle = p.c; const z = p.sz || 1; g.fillRect(-6 * z, -3.5 * z, 12 * z, 7 * z); g.restore(); }
    return p.l > 0;
  });
  g.restore();
  if (LIE) { g.save(); g.translate(o.x, o.y); g.scale(k, k); zzz(o.t, -40, -110); g.restore(); }
  // къде е върхът на главата и колко е голям (за балончето и докосването)
  const top = o.style === "sketch" ? (age === "egg" ? -80 : (14 - 59 * A.head) * 2.3 - 10) : age === "egg" ? -150 : (o.style === "art" || o.style === "artanim") ? -150 : 70 - 238 * A.head;
  return { top: o.y + top * k, r: 260 * k, cy: o.y + (top + 200) * k / 2 };
}

window.Octo = { V: VER, draw, AGES: ["egg", "baby", "kid", "teen", "adult", "aging", "old"],
  AGE_NAMES: { egg: "Яйце", baby: "Бебе", kid: "Малък", teen: "Тийнейджър", adult: "Голям", aging: "Застаряващ", old: "Много стар" } };
})();
