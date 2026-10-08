// Пиксчо — пикселно тамагочи, което живее на екрана на Мак-а.
// Само по себе си е пиксел с лице и крайници; с всяко ниво (опит от храна, работа и игри)
// става с един пиксел по-голямо.
// Компилира се с build.sh (нужни са само Command Line Tools).

import AppKit
import ServiceManagement

// MARK: - Цветове и рисуване по пиксели

extension NSColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255,
                  alpha: alpha)
    }
}

typealias Grid = [[Character]]

func grid(_ rows: [String]) -> Grid { rows.map { Array($0) } }

func put(_ g: inout Grid, _ x: Int, _ y: Int, _ c: Character) {
    guard y >= 0, y < g.count, x >= 0, x < g[y].count else { return }
    g[y][x] = c
}

func stamp(_ g: inout Grid, _ s: Grid, _ x: Int, _ y: Int) {
    for (r, line) in s.enumerated() {
        for (c, ch) in line.enumerated() where ch != "." { put(&g, x + c, y + r, ch) }
    }
}

let heartGrid = grid([
    ".RR.RR.",
    "RRRRRRR",
    "RRRRRRR",
    ".RRRRR.",
    "..RRR..",
    "...R...",
])
let pillGrid = grid([
    ".WWRR.",
    "WWWRRR",
    ".WWRR.",
])

let foodColors = [0xff595e, 0xffca3a, 0x8ac926, 0x1982c4, 0x6a4c93, 0xff924c, 0x52d1dc, 0xf15bb5]
let bodyYellow = 0xffd23f

// MARK: - Еволюцията: от 1 до 100 пиксела

/// Детерминиран „шум“ за всяка клетка, за да расте по-естествено (а не като идеален кръг).
func cellNoise(_ x: Int, _ y: Int) -> Double {
    var v = (x &* 73856093) ^ (y &* 19349663)
    v = (v ^ (v >> 13)) &* 1274126177
    v = v ^ (v >> 16)
    return Double(v & 0xffff) / 65536.0
}

/// Редът, в който се добавят пикселите: всеки нов е до тялото и възможно най-близо до средата.
func makeBlobOrder(_ count: Int) -> [(Int, Int)] {
    func key(_ x: Int, _ y: Int) -> Int { (x + 500) * 1000 + (y + 500) }
    // започва като квадратче 3×3, като сегашния Пиксчо
    var cells: [(Int, Int)] = []
    for y in 0..<3 { for x in 0..<3 { cells.append((x, y)) } }
    var set = Set(cells.map { key($0.0, $0.1) })
    let dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    while cells.count < count {
        let cx = Double(cells.reduce(0) { $0 + $1.0 }) / Double(cells.count)
        let cy = Double(cells.reduce(0) { $0 + $1.1 }) / Double(cells.count)
        var best: (Double, Int, Int)?
        for (x, y) in cells {
            for (dx, dy) in dirs {
                let c = (x + dx, y + dy)
                if set.contains(key(c.0, c.1)) { continue }
                let nb = dirs.filter { set.contains(key(c.0 + $0.0, c.1 + $0.1)) }.count
                let sc = pow(Double(c.0) - cx, 2) + pow(Double(c.1) - cy, 2) * 1.45
                    + cellNoise(c.0, c.1) * 1.4 - Double(nb) * 0.45
                if let b = best {
                    if sc < b.0 || (sc == b.0 && (c.0 < b.1 || (c.0 == b.1 && c.1 < b.2))) { best = (sc, c.0, c.1) }
                } else {
                    best = (sc, c.0, c.1)
                }
            }
        }
        if let b = best {
            cells.append((b.1, b.2))
            set.insert(key(b.1, b.2))
        }
    }
    return cells
}

let blobOrder = makeBlobOrder(108)

// MARK: - Спрайт

enum Face { case normal, blink, happy, sad, angry, sleep, eatOpen, eatShut, sick, dead, focus }
enum Pose { case idle, wave, walk, type, sleep }

let canvasW = 100
let canvasH = 80
let cellSize = 4

struct Sprite {
    var grid: Grid
    var cx = 0                       // средата на тялото
    var top = 0, bottom = 0, left = 0, right = 0
    var mouthX = 0, mouthY = 0
    var groundY = 0
    var minX = 0, minY = 0, maxX = 0, maxY = 0
    var monX = 0, monY = 0, monW = 0, monH = 0   // мониторът (ако работи)
}

func buildSprite(level: Int, face: Face, pose: Pose, frame: Int, working: Bool, worn: [String] = []) -> Sprite {
    var g = Grid(repeating: Array(repeating: ".", count: canvasW), count: canvasH)
    let count = max(1, min(100, level))
    let cells = blobOrder.prefix(8 + count)
    let minCX = cells.map { $0.0 }.min()!, maxCX = cells.map { $0.0 }.max()!
    let minCY = cells.map { $0.1 }.min()!, maxCY = cells.map { $0.1 }.max()!
    let bw = (maxCX - minCX + 1) * cellSize, bh = (maxCY - minCY + 1) * cellSize
    let limbs = pose != .sleep      // като спи, си прибира ръцете и краката
    let leg = count < 30 ? 4 : 6
    let groundY = canvasH - 1
    let by0 = limbs ? groundY - leg - bh - 1 : groundY - bh
    let bx0 = (canvasW - bw) / 2 - (working ? 18 : 0)

    // тяло от плочки
    var body = Set<Int>()
    func k(_ x: Int, _ y: Int) -> Int { y * 1000 + x }
    for (x, y) in cells {
        let fx = bx0 + (x - minCX) * cellSize, fy = by0 + (y - minCY) * cellSize
        for i in 0..<cellSize {
            for j in 0..<cellSize {
                let c: Character = (i == cellSize - 1 || j == cellSize - 1) ? "A" : "B"
                put(&g, fx + i, fy + j, c)
                body.insert(k(fx + i, fy + j))
            }
        }
    }
    func isBody(_ x: Int, _ y: Int) -> Bool { body.contains(k(x, y)) }
    for key in body {
        let x = key % 1000, y = key / 1000
        if !isBody(x + 1, y) || !isBody(x, y + 1) { put(&g, x, y, "D") }
        else if !isBody(x - 1, y) || !isBody(x, y - 1) { put(&g, x, y, "L") }
    }
    for key in body {
        let x = key % 1000, y = key / 1000
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] where !isBody(x + dx, y + dy) {
            put(&g, x + dx, y + dy, "K")
        }
    }
    let cx = bx0 + bw / 2
    func rowSpan(_ y: Int) -> (Int, Int) {
        var lo = Int.max, hi = Int.min
        for x in bx0..<(bx0 + bw) where isBody(x, y) { lo = min(lo, x); hi = max(hi, x) }
        return lo == Int.max ? (cx, cx) : (lo, hi)
    }
    func topOf(_ x: Int) -> Int {
        for y in by0..<(by0 + bh) where isBody(x, y) { return y }
        return by0
    }
    func bottomOf(_ x: Int) -> Int {
        for y in stride(from: by0 + bh - 1, through: by0, by: -1) where isBody(x, y) { return y }
        return by0 + bh - 1
    }
    let topY = (bx0..<(bx0 + bw)).map { topOf($0) }.min() ?? by0

    // лице
    let eyeY = by0 + bh * 2 / 5
    let e = bw >= 36 ? 4 : (bw >= 24 ? 3 : 2)
    let gap = max(2, bw / 6)
    let look = face == .focus ? 1 : 0
    let lx = cx - gap - e + look, rx = cx + gap + look
    let visor = false
    let ink: Character = visor ? "G" : "K"
    let mw = bw >= 36 ? 8 : (bw >= 28 ? 6 : 4)
    let mouthY = eyeY + e + (visor ? 3 : 2)
    let mx = cx - mw / 2

    do {
        if visor {
            for x in (lx - 3)..<(rx + e + 3) { for y in (eyeY - 2)..<(eyeY + e + 2) { put(&g, x, y, "S") } }
        }
        func eyeOpen(_ x0: Int) {
            for dx in 0..<e { for dy in 0..<e { put(&g, x0 + dx, eyeY + dy, ink) } }
            if !visor { put(&g, x0, eyeY, "W") }
        }
        func eyeClosed(_ x0: Int) {
            for dx in -1...e { put(&g, x0 + dx, eyeY + e - 1, ink) }
        }
        func eyeHappy(_ x0: Int) {
            put(&g, x0 - 1, eyeY + 1, ink)
            for dx in 0..<e { put(&g, x0 + dx, eyeY, ink) }
            put(&g, x0 + e, eyeY + 1, ink)
        }
        func brows() {
            put(&g, lx - 1, eyeY - 3, "K"); put(&g, lx, eyeY - 2, "K"); put(&g, lx + e - 1, eyeY - 1, "K")
            put(&g, rx + e, eyeY - 3, "K"); put(&g, rx + e - 1, eyeY - 2, "K"); put(&g, rx, eyeY - 1, "K")
        }
        switch face {
        case .normal, .sad, .angry, .sick, .focus: eyeOpen(lx); eyeOpen(rx)
        case .blink, .sleep, .dead: eyeClosed(lx); eyeClosed(rx)
        case .happy, .eatOpen, .eatShut: eyeHappy(lx); eyeHappy(rx)
        }
        if face == .angry { brows() }
        if face == .sad { put(&g, lx, eyeY + e, "T"); put(&g, lx, eyeY + e + 1, "T") }
        if face == .sick { put(&g, rowSpan(topY + 2).1 + 3, topY + 2, "T"); put(&g, rowSpan(topY + 2).1 + 3, topY + 3, "T") }

        do {
            func line(_ w: Int) { for dx in 0..<w { put(&g, cx - w / 2 + dx, mouthY, "K") } }
            switch face {
            case .normal, .blink:
                line(mw); put(&g, mx - 1, mouthY - 1, "K"); put(&g, mx + mw, mouthY - 1, "K")
            case .happy, .eatOpen:
                line(mw); for dx in 0..<mw { put(&g, mx + dx, mouthY + 1, "R") }
                put(&g, mx - 1, mouthY - 1, "K"); put(&g, mx + mw, mouthY - 1, "K")
            case .sad, .angry:
                line(mw); put(&g, mx - 1, mouthY + 1, "K"); put(&g, mx + mw, mouthY + 1, "K")
            case .eatShut, .sick, .dead: line(mw)
            case .sleep, .focus: line(2)
            }
        }
        if bw >= 16 && face != .angry && face != .dead {
            for dx in 0..<3 { put(&g, lx - 3 + dx, eyeY + e + 1, "P"); put(&g, rx + e + dx, eyeY + e + 1, "P") }
        }
    }

    // ръце и крака
    if limbs {
        let ay = by0 + bh / 2
        let (l, r) = rowSpan(ay)
        func arm(_ side: Int) {
            let sx = side < 0 ? l - 2 : r + 2
            for i in 0..<7 {
                let x = sx + side * i
                var y = ay + (i + 1) / 2
                switch pose {
                case .wave: y = ay - (frame % 2 == 0 ? i : (i + 1) / 2)
                case .sleep: y = ay + i
                case .walk: if (frame % 2 == 0) != (side < 0) { y = ay }
                case .type: if side > 0 { y = ay + 2 - (i == 6 && frame % 2 == 0 ? 1 : 0) }
                case .idle: break
                }
                put(&g, x, y, "K")
            }
        }
        arm(-1)
        arm(1)
        let spread = max(3, bw / 5)
        for (i, lx0) in [cx - spread - 1, cx + spread].enumerated() {
            let lift = pose == .walk && frame % 2 == i ? 1 : 0
            let start = max(bottomOf(lx0), bottomOf(lx0 + 1)) + 2
            let end = groundY - lift
            if start <= end {
                for y in start...end { put(&g, lx0, y, "K"); put(&g, lx0 + 1, y, "K") }
            }
            if i == 0 { put(&g, lx0 - 1, end, "K"); put(&g, lx0 - 2, end, "K") }
            else { put(&g, lx0 + 2, end, "K"); put(&g, lx0 + 3, end, "K") }
        }
    }

    // облекло от магазина
    let kk = bw >= 28 ? 2 : 1
    func stampK(_ s: Grid, _ x: Int, _ y: Int) {
        for (r, line) in s.enumerated() {
            for (c, ch) in line.enumerated() where ch != "." {
                for a in 0..<kk { for b in 0..<kk { put(&g, x + c * kk + a, y + r * kk + b, ch) } }
            }
        }
    }
    if worn.contains("headphones") {
        let (l, r) = rowSpan(eyeY)
        let a0 = cx - bw / 4, a1 = cx + bw / 4
        for x in a0...max(a0, a1) { put(&g, x, topY - 3, "N") }
        var x = a0, y = topY - 3
        while x > l - 3 && y < eyeY - 3 { x -= 1; y += 1; put(&g, x, y, "N") }
        x = a1; y = topY - 3
        while x < r + 3 && y < eyeY - 3 { x += 1; y += 1; put(&g, x, y, "N") }
        for yy in (eyeY - 3)..<(eyeY + 5) {
            for xx in (l - 5)..<(l - 1) { put(&g, xx, yy, "C") }
            for xx in (r + 2)..<(r + 6) { put(&g, xx, yy, "C") }
            put(&g, l - 6, yy, "K"); put(&g, r + 6, yy, "K")
        }
    }
    if worn.contains("glasses") || worn.contains("sunglasses") {
        let sun = worn.contains("sunglasses")
        for x0 in [lx, rx] {
            for x in (x0 - 1)...(x0 + e) { put(&g, x, eyeY - 1, "K"); put(&g, x, eyeY + e, "K") }
            for y in eyeY..<(eyeY + e) { put(&g, x0 - 1, y, "K"); put(&g, x0 + e, y, "K") }
            if sun {
                for x in x0..<(x0 + e) { for y in eyeY..<(eyeY + e) { put(&g, x, y, "S") } }
                put(&g, x0, eyeY, "W")
            }
        }
        if lx + e + 1 <= rx - 2 { for x in (lx + e + 1)...(rx - 2) { put(&g, x, eyeY, "K") } }
    }
    if worn.contains("bowtie") { stampK(neckBowtie, cx - 5 * kk / 2, mouthY + 2) }
    if worn.contains("scarf") {
        let y = mouthY + 3
        let (l, r) = rowSpan(min(y, by0 + bh - 1))
        for x in (l - 1)...(r + 1) { put(&g, x, y, "O"); put(&g, x, y + 1, "O") }
        for dy in 2...4 { put(&g, r - 3, y + dy, "O"); put(&g, r - 2, y + dy, "O") }
    }
    for (id, hat) in [("party", hatParty), ("beanie", hatBeanie), ("crown", hatCrown)] where worn.contains(id) {
        stampK(hat, cx - hat[0].count * kk / 2, topY - hat.count * kk + kk)
    }
    if worn.contains("bow") { stampK(hatBow, rowSpan(topY + 1).1 - 3 * kk, topY - 2 * kk) }

    var sp = Sprite(grid: g)
    sp.cx = cx
    sp.top = topY; sp.bottom = by0 + bh - 1; sp.left = bx0; sp.right = bx0 + bw - 1
    sp.mouthX = cx; sp.mouthY = mouthY
    sp.groundY = groundY

    // монитор с таймлайн, докато монтира
    if working {
        let (_, r) = rowSpan(by0 + bh / 2)
        let m0 = min(canvasW - 30, r + 11)
        let top = groundY - 23
        for x in m0..<(m0 + 28) { put(&g, x, top, "E"); put(&g, x, top + 18, "E") }
        for y in top...(top + 18) { put(&g, m0, y, "E"); put(&g, m0 + 27, y, "E") }
        for y in (top + 1)..<(top + 18) { for x in (m0 + 1)..<(m0 + 27) { put(&g, x, y, "S") } }
        let tracks: [(Int, Int, Int, Character)] = [
            (3, 2, 12, "C"), (3, 15, 24, "M"), (7, 3, 20, "O"), (11, 2, 8, "G"), (11, 10, 25, "Y"), (14, 5, 18, "P"),
        ]
        for (row, a, b, c) in tracks { for x in (m0 + a)...(m0 + b) { put(&g, x, top + row, c); put(&g, x, top + row + 1, c) } }
        let head = m0 + 2 + (frame * 2) % 23
        for y in (top + 1)..<(top + 18) { put(&g, head, y, "R") }
        for y in (top + 19)...(top + 21) { put(&g, m0 + 12, y, "E"); put(&g, m0 + 15, y, "E") }
        for x in (m0 + 8)...(m0 + 19) { put(&g, x, groundY, "E") }
        sp.monX = m0; sp.monY = top; sp.monW = 28; sp.monH = 23
    }

    sp.grid = g
    sp.minX = canvasW; sp.minY = canvasH; sp.maxX = 0; sp.maxY = 0
    for (y, row) in g.enumerated() {
        for (x, ch) in row.enumerated() where ch != "." {
            sp.minX = min(sp.minX, x); sp.maxX = max(sp.maxX, x)
            sp.minY = min(sp.minY, y); sp.maxY = max(sp.maxY, y)
        }
    }
    return sp
}

// MARK: - Общо рисуване (с глич)

func drawGrid(_ g: Grid, x: CGFloat, y: CGFloat, s: CGFloat, flip: Bool = false,
              palette: (Character) -> NSColor?, tint: NSColor? = nil, shifts: [CGFloat]? = nil) {
    for (row, line) in g.enumerated() {
        let dx = shifts?[row] ?? 0
        for (col, ch) in line.enumerated() {
            guard let base = palette(ch) else { continue }
            (tint ?? base).setFill()
            let cx = flip ? line.count - 1 - col : col
            NSRect(x: x + CGFloat(cx) * s + dx, y: y + CGFloat(row) * s, width: s, height: s).fill()
        }
    }
}

/// Рисува спрайта; ако glitch, с разместени редове, червено/синьо раздвояване и „шум“.
func drawGlitchy(_ g: Grid, x: CGFloat, y: CGFloat, s: CGFloat, flip: Bool = false,
                 palette: (Character) -> NSColor?, glitch: Bool, noiseRect: NSRect) {
    guard glitch else {
        drawGrid(g, x: x, y: y, s: s, flip: flip, palette: palette)
        return
    }
    var shifts = [CGFloat](repeating: 0, count: g.count)
    var row = 0
    while row < shifts.count {
        let band = Int.random(in: 1...4)
        let dx = Int.random(in: 0..<3) == 0 ? CGFloat(Int.random(in: -3...3)) * s : 0
        for r in row..<min(shifts.count, row + band) { shifts[r] = dx }
        row += band
    }
    drawGrid(g, x: x - s, y: y, s: s, flip: flip, palette: palette, tint: NSColor(hex: 0xff0055, alpha: 0.55), shifts: shifts)
    drawGrid(g, x: x + s, y: y, s: s, flip: flip, palette: palette, tint: NSColor(hex: 0x00e5ff, alpha: 0.55), shifts: shifts)
    drawGrid(g, x: x, y: y, s: s, flip: flip, palette: palette, shifts: shifts)
    for _ in 0..<7 {
        NSColor(hex: [0xff0055, 0x00e5ff, 0xffffff, 0x2b2b3a].randomElement()!, alpha: 0.85).setFill()
        NSRect(x: noiseRect.minX + CGFloat.random(in: 0...max(1, noiseRect.width)),
               y: noiseRect.minY + CGFloat.random(in: 0...max(1, noiseRect.height)),
               width: s * CGFloat(Int.random(in: 1...5)), height: s).fill()
    }
}

/// Нарисуван Пиксчо за иконката в горната лента.
func statusIcon(body: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: 18, height: 18))
    img.lockFocus()
    NSColor(hex: 0x2b2b3a).setFill()
    NSRect(x: 3, y: 4, width: 12, height: 12).fill()
    NSRect(x: 5, y: 1, width: 2, height: 3).fill()
    NSRect(x: 11, y: 1, width: 2, height: 3).fill()
    NSColor(hex: body).setFill()
    NSRect(x: 5, y: 6, width: 8, height: 8).fill()
    NSColor(hex: 0x2b2b3a).setFill()
    NSRect(x: 6, y: 10, width: 2, height: 2).fill()
    NSRect(x: 10, y: 10, width: 2, height: 2).fill()
    NSRect(x: 8, y: 7, width: 2, height: 1).fill()
    img.unlockFocus()
    return img
}

// MARK: - Иконки за ретро менюто (8×8)

let iconFood = grid([
    "...KG...",
    "..K.....",
    ".RRRRRR.",
    "RRWRRRRR",
    "RRRRRRRR",
    "RRRRRRRR",
    ".RRRRRR.",
    "..RR.RR.",
])
let iconFun = grid([
    "...PP...",
    "...PP...",
    "PPPPPPPP",
    ".PPPPPP.",
    "..PPPP..",
    ".PPPPPP.",
    ".PP..PP.",
    "PP....PP",
])
let iconEnergy = grid([
    "....YYY.",
    "...YYY..",
    "..YYY...",
    ".YYYYYY.",
    "...YYY..",
    "..YYY...",
    ".YY.....",
    "Y.......",
])
let iconWork = grid([
    "WKWKWKWK",
    "KWKWKWKW",
    "........",
    "EEEEEEEE",
    "ECCCMMME",
    "EOOOOOOE",
    "EGGGYYYE",
    "EEEEEEEE",
])
let iconHealth = grid([
    ".RR..RR.",
    "RRRRRRRR",
    "RRRRRRRR",
    "RRRRRRRR",
    ".RRRRRR.",
    "..RRRR..",
    "...RR...",
    "........",
])
let iconMonitor = grid([
    "EEEEEEEE",
    "ESSSSSSE",
    "ESCCSMSE",
    "ESOOOOSE",
    "ESSSSSSE",
    "EEEEEEEE",
    "...EE...",
    "..EEEE..",
])
let iconPause = grid([
    "........",
    ".WW..WW.",
    ".WW..WW.",
    ".WW..WW.",
    ".WW..WW.",
    ".WW..WW.",
    ".WW..WW.",
    "........",
])
let iconSky = grid([
    "Y.....C.",
    "........",
    "...M....",
    ".......G",
    ".K......",
    "KKK.....",
    ".K......",
    "..KBBK..",
])
let iconBall = grid([
    "..OOOO..",
    ".OOWOOO.",
    "OOWOOOOO",
    "OOOOOOOO",
    "OOOOOOOO",
    "OOOOOOOO",
    ".OOOOOO.",
    "..OOOO..",
])
let iconMoon = grid([
    "...YYY..",
    "..YY....",
    ".YY.....",
    ".YY.....",
    ".YY.....",
    ".YY.....",
    "..YY....",
    "...YYY..",
])
let iconSun = grid([
    "...Y....",
    ".Y.Y.Y..",
    "..YYY...",
    "YYYYYYY.",
    "..YYY...",
    ".Y.Y.Y..",
    "...Y....",
    "........",
])
let iconPill = grid([
    "........",
    "........",
    ".WWWRRR.",
    "WWWWRRRR",
    "WWWWRRRR",
    ".WWWRRR.",
    "........",
    "........",
])
let bombGrid = grid([
    "....YR",
    "...K..",
    ".KKKK.",
    "KKWKKK",
    "KWKKKK",
    "KKKKKK",
    "KKKKKK",
    ".KKKK.",
])

// MARK: - Животинчето

struct Pet: Codable {
    var name = "Пиксчо"
    var fullness: Double = 80
    var fun: Double = 80
    var energy: Double = 80
    var health: Double = 100
    var work: Double = 60          // „съвестта“: пада, докато не монтира
    var working = false
    var workSeconds: Double = 0
    var videos = 0
    var level = 1
    var xp = 0
    var coins = 0
    var owned: [String] = []
    var worn: [String] = []
    var workCoinSeconds: Double = 0
    var asleep = false
    var dead = false
    var born = Date()
    var lastUpdate = Date()

    init() {}

    // старите запазвания нямат новите полета, затова всичко е „ако го има“
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? name
        fullness = try c.decodeIfPresent(Double.self, forKey: .fullness) ?? fullness
        fun = try c.decodeIfPresent(Double.self, forKey: .fun) ?? fun
        energy = try c.decodeIfPresent(Double.self, forKey: .energy) ?? energy
        health = try c.decodeIfPresent(Double.self, forKey: .health) ?? health
        work = try c.decodeIfPresent(Double.self, forKey: .work) ?? work
        working = try c.decodeIfPresent(Bool.self, forKey: .working) ?? working
        workSeconds = try c.decodeIfPresent(Double.self, forKey: .workSeconds) ?? workSeconds
        videos = try c.decodeIfPresent(Int.self, forKey: .videos) ?? videos
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? level
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? xp
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? coins
        owned = try c.decodeIfPresent([String].self, forKey: .owned) ?? owned
        worn = try c.decodeIfPresent([String].self, forKey: .worn) ?? worn
        workCoinSeconds = try c.decodeIfPresent(Double.self, forKey: .workCoinSeconds) ?? workCoinSeconds
        asleep = try c.decodeIfPresent(Bool.self, forKey: .asleep) ?? asleep
        dead = try c.decodeIfPresent(Bool.self, forKey: .dead) ?? dead
        born = try c.decodeIfPresent(Date.self, forKey: .born) ?? born
        lastUpdate = try c.decodeIfPresent(Date.self, forKey: .lastUpdate) ?? lastUpdate
    }

    /// с всяко ниво един залепен пиксел повече (започва от 3×3)
    var cellsAcross: Int { Int(Double(8 + min(100, level)).squareRoot().rounded(.up)) }
    var xpNeeded: Int { 15 + level * 3 }

    static let videoSeconds: Double = 30 * 60

    /// dt — секунди. offline = докато приложението е било спряно (по-кротко и без да боледува).
    mutating func tick(_ dt: Double, offline: Bool = false) {
        guard !dead, dt > 0 else { return }
        let m = dt / 60
        if asleep {
            working = false
            fullness -= 0.25 * m
            fun -= 0.2 * m
            energy += 4 * m
            work -= 0.15 * m
            if energy >= 100 { energy = 100; asleep = false }
        } else if working && !offline {
            fullness -= 0.6 * m
            fun -= 0.3 * m
            energy -= 1.0 * m
            work += 5 * m
            workSeconds += dt
            if energy <= 10 { working = false }
        } else {
            working = false
            fullness -= 0.5 * m
            fun -= 0.7 * m
            energy -= 0.4 * m
            work -= 0.35 * m
            if energy <= 5 { asleep = true }
        }
        if !offline {
            if fullness <= 0 || energy <= 0 {
                health -= 1 * m
            } else if fullness > 50 && fun > 30 {
                health += 0.5 * m
            }
        }
        fullness = fullness.clamped()
        fun = fun.clamped()
        energy = energy.clamped()
        health = health.clamped()
        work = work.clamped()
        if health <= 0 { dead = true; asleep = false; working = false }
    }
}

extension Double {
    func clamped(_ lo: Double = 0, _ hi: Double = 100) -> Double { Swift.min(hi, Swift.max(lo, self)) }
}

// MARK: - Реплики

let editingLines = [
    "Рендерът е на 99%… от час.",
    "Кой снима това вертикално?!",
    "Ctrl+S, Ctrl+S, Ctrl+S…",
    "Клиентът иска „нещо по-уау“.",
    "Още една малка промяна… последна, обещавам.",
    "final_final_v7_ТОВА_Е.mp4",
    "Премиерът пак крашна. Добре съм.",
    "Звукът е разминат с 2 кадъра. ВИЖДАМ ГО.",
    "Кафе, монтаж, кафе, монтаж…",
    "Тая музика е без авторски права… нали?",
    "J-cut, L-cut, баница-cut.",
    "Кой изтри proxy файловете?!",
    "Цветокорекцията е изкуство. И страдание.",
    "Може ли логото по-голямо? Още. ОЩЕ.",
    "Таймлайнът ми е по-дълъг от опашка в банка.",
    "„Ще го оправим на пост-продукция“ = аз.",
    "Добавям преход „звезда“. Шегувам се. Или?",
    "Трябват ми още 3 монитора.",
    "Рендерирам… не ме пипай!",
    "Кой е записвал с микрофона на телефона?",
    "B-roll, B-roll, царството си за B-roll!",
    "Субтитрите няма да се напишат сами…",
    "Външният диск издава странни звуци…",
    "Минута видео = час монтаж.",
    "Клиентът: „Може ли да стане вайръл?“",
    "Това не е грешка, това е jump cut.",
    "Бяхме 4K… сега сме 480p заради лаптопа.",
    "Още едно кафе и ще виждам в 60fps.",
    "Експортът казва 3 часа. Лъже.",
    "Тук ще сложа нещо епично. После.",
    "Монтажът е 10% рязане и 90% чакане.",
    "Кадър по кадър, пиксел по пиксел.",
]

let happyLines = ["Хи-хи!", "Гъделичкаш!", "Обичам те!", "Още!", "Пиксчо е щастлив!", "<3", "Ихааа!", "Ти си най-добрият!", "Йей!"]
let angryLines = ["Остави ме да спя!", "Пет минутки още…", "Грррр!", "Сънувах рендер… и ме събуди!", "Шшшт!", "Не съм тук!", "Ще ти се сърдя!"]
let annoyedLines = ["Стига ме цъкаш!", "ГРРР!", "Ей! Боли!", "Ще глична от теб!", "Спри! СПРИ!", "Пиксел съм, не бутон!"]
let eatLines = ["Ням!", "Вкусен пиксел!", "Мммм!", "Ням-ням!", "Още един!", "Пиксели = живот"]
let fetchLines = ["Ето го!", "Донесох го!", "Пак! Пак!", "Хвърли пак!", "Бърз съм, а?"]

func pick(_ lines: [String], avoiding last: inout String) -> String {
    var line = lines.randomElement()!
    if lines.count > 1 { while line == last { line = lines.randomElement()! } }
    last = line
    return line
}


// MARK: - Изглед на Пиксчо

enum Action { case none, eat, love, angry, pill, levelUp }

final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

func overlayPanel(_ frame: NSRect, key: Bool) -> NSPanel {
    let p: NSPanel = key
        ? KeyPanel(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        : NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    p.isOpaque = false
    p.backgroundColor = .clear
    p.hasShadow = false
    p.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
    p.hidesOnDeactivate = false
    p.isReleasedWhenClosed = false
    p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    return p
}

final class PetView: NSView {
    weak var game: Game?
    var hovering = false
    var spriteRect = NSRect.zero        // заетата част, в координатите на изгледа
    var monitorRect = NSRect.zero       // мониторът, докато работи
    var feetY: CGFloat = PetView.top + CGFloat(canvasH) * PetView.scale   // къде стъпва (без подскачането)
    var bodyX0: CGFloat = 120, bodyX1: CGFloat = 200
    private var downPoint = NSPoint.zero
    private var dragStart: NSPoint?
    private var windowStart = NSPoint.zero
    private var dragged = false

    static let scale: CGFloat = 3
    static let top: CGFloat = 56         // място за балончето
    static let left: CGFloat = 10
    static let size = NSSize(width: CGFloat(canvasW) * scale + 20, height: top + CGFloat(canvasH) * scale + 20)

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        windowStart = window?.frame.origin ?? .zero
        downPoint = convert(event.locationInWindow, from: nil)
        dragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let window, game?.busyMoving != true else { return }
        let p = NSEvent.mouseLocation
        let dx = p.x - start.x, dy = p.y - start.y
        if abs(dx) + abs(dy) > 3 { dragged = true; game?.isDragging = true }
        if dragged { window.setFrameOrigin(NSPoint(x: windowStart.x + dx, y: windowStart.y + dy)) }
    }

    override func mouseUp(with event: NSEvent) {
        if dragged {
            game?.finishedDrag()
        } else if game?.pet.working == true && monitorRect.contains(downPoint) {
            game?.playClip()
        } else {
            game?.petIt()
        }
        dragStart = nil
        dragged = false
        game?.isDragging = false
    }

    override func rightMouseDown(with event: NSEvent) { game?.openRetro() }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let s = PetView.scale
        let t = game.time
        let frame = Int(t * 2)
        let ox = PetView.left, oy = PetView.top
        let pet = game.pet
        let flip = game.walking && game.facingLeft

        let pose: Pose
        if pet.asleep || pet.dead { pose = .sleep }
        else if game.walking { pose = .walk }
        else if game.action == .love || game.action == .levelUp { pose = .wave }
        else if pet.working { pose = .type }
        else { pose = .idle }

        let sp = buildSprite(level: pet.level, face: game.currentFace(), pose: pose,
                             frame: pose == .walk ? Int(t * 8) : frame, working: pet.working, worn: pet.worn)

        var dy: CGFloat = 0
        if pet.dead {
            dy = CGFloat(sin(t * 2) * 4)
        } else if pet.asleep {
            dy = frame % 4 < 2 ? 0 : 2
        } else if game.action == .love || game.action == .levelUp {
            dy = -abs(CGFloat(sin(t * 8))) * 8
        } else if !game.walking && !pet.working && game.action != .angry {
            dy = frame % 2 == 0 ? 0 : 2
        }

        func vx(_ col: Int) -> CGFloat { ox + CGFloat(flip ? canvasW - 1 - col : col) * s }
        func vy(_ row: Int) -> CGFloat { oy + CGFloat(row) * s + dy }

        let left = min(vx(sp.minX), vx(sp.maxX))
        let box = NSRect(x: left, y: vy(sp.minY), width: CGFloat(sp.maxX - sp.minX + 1) * s,
                         height: CGFloat(sp.maxY - sp.minY + 1) * s)
        spriteRect = box.insetBy(dx: -4, dy: -4)
        if sp.monW > 0 {
            let a = vx(sp.monX), b = vx(sp.monX + sp.monW - 1)
            monitorRect = NSRect(x: min(a, b), y: vy(sp.monY), width: CGFloat(sp.monW) * s, height: CGFloat(sp.monH) * s)
        } else {
            monitorRect = .zero
        }
        let bodyW = CGFloat(sp.right - sp.left + 1) * s
        let centerX = (vx(sp.left) + vx(sp.right) + s) / 2
        feetY = oy + CGFloat(sp.groundY + 1) * s
        bodyX0 = centerX - bodyW / 2
        bodyX1 = centerX + bodyW / 2

        // сянка
        if !pet.dead && !game.rolling {
            NSColor(white: 0, alpha: 0.18).setFill()
            NSBezierPath(ovalIn: NSRect(x: centerX - bodyW / 2 - 6, y: oy + CGFloat(sp.groundY + 1) * s - 3,
                                        width: bodyW + 12, height: 5)).fill()
        }

        let ctx = NSGraphicsContext.current
        if game.rolling {
            // търкаля се: завърта се около средата на тялото
            ctx?.saveGraphicsState()
            let cx = centerX
            let cy = (vy(sp.top) + vy(sp.bottom) + s) / 2
            let tr = NSAffineTransform()
            tr.translateX(by: cx, yBy: cy)
            tr.rotate(byRadians: game.rollAngle)
            tr.translateX(by: -cx, yBy: -cy)
            tr.concat()
        }
        drawGlitchy(sp.grid, x: ox, y: oy + dy, s: s, flip: flip, palette: game.color,
                    glitch: game.glitching, noiseRect: box)
        if game.rolling { ctx?.restoreGraphicsState() }

        let headTop = vy(sp.minY)
        let p = game.actionProgress

        // тоалетна
        if game.toiletPhase == .doing {
            let tt = t - game.toiletStart
            let bottomY = vy(sp.bottom) + s
            if game.toiletPoop {
                for i in 0..<4 {
                    let ph = (tt * 1.2 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                    let px = game.facingLeft ? centerX + bodyW / 3 : centerX - bodyW / 3
                    NSColor(hex: 0x8b5a2b).setFill()
                    NSRect(x: px - 3, y: bottomY + CGFloat(ph) * (feetY - bottomY), width: 6, height: 6).fill()
                }
            } else {
                for i in 0..<10 {
                    let ph = (tt * 2 + Double(i) * 0.1).truncatingRemainder(dividingBy: 1)
                    let sx = centerX + (game.facingLeft ? -6 : 6) + CGFloat(ph) * (game.facingLeft ? -14 : 14)
                    NSColor(hex: 0xffe066).setFill()
                    NSRect(x: sx, y: bottomY + CGFloat(ph) * (feetY - bottomY), width: 3, height: 3).fill()
                }
            }
        }

        // пиксели, които плават около него (повече с нивата)
        if !pet.dead {
            let n = min(8, 2 + pet.level / 12)
            for i in 0..<n {
                let a = t * (0.35 + Double(i % 3) * 0.08) + Double(i) * 2.4
                let rx = bodyW / 2 + 14 + CGFloat(i % 3) * 6
                let px = centerX + CGFloat(cos(a)) * rx
                let py = (vy(sp.top) + vy(sp.bottom)) / 2 + CGFloat(sin(a * 1.3)) * (bodyW / 2 + 8) * 0.7
                let size: CGFloat = i % 2 == 0 ? 6 : 4
                NSColor(hex: 0x2b2b3a, alpha: 0.9).setFill()
                NSRect(x: px - size / 2 - 1, y: py - size / 2 - 1, width: size + 2, height: size + 2).fill()
                NSColor(hex: i % 3 == 0 ? 0xfff0a6 : bodyYellow).setFill()
                NSRect(x: px - size / 2, y: py - size / 2, width: size, height: size).fill()
            }
        }

        switch game.action {
        case .eat:
            let size = max(2, 12 * CGFloat(1 - p))
            let mx = vx(sp.mouthX) + s / 2, my = vy(sp.mouthY) + s / 2
            NSColor(hex: game.lastFoodColor).setFill()
            NSRect(x: mx - size / 2, y: my - size / 2, width: size, height: size).fill()
        case .love:
            for i in 0..<3 {
                let phase = (p + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                drawGrid(heartGrid, x: centerX - 30 + CGFloat(i) * 22, y: headTop - 4 - CGFloat(phase) * 30,
                         s: 2.5, palette: game.color)
            }
        case .levelUp:
            for _ in 0..<10 {
                NSColor(hex: [0xffd166, 0xffffff, 0x48cae4].randomElement()!).setFill()
                NSRect(x: box.minX + CGFloat.random(in: -20...(box.width + 20)),
                       y: box.minY + CGFloat.random(in: -20...(box.height)), width: 3, height: 3).fill()
            }
        case .angry:
            // пикселна „ядосана“ звездичка до главата
            let ax = centerX + bodyW / 2 + 6, ay = vy(sp.top) - 12
            NSColor(hex: 0xe63946).setFill()
            for (dx, dyy) in [(0, 0), (6, 0), (0, 6), (6, 6), (3, 3)] {
                NSRect(x: ax + CGFloat(dx), y: ay + CGFloat(dyy), width: 3, height: 3).fill()
            }
        case .pill:
            drawGrid(pillGrid, x: centerX - 7, y: headTop - 24 + CGFloat(p) * 30, s: 2.5, palette: game.color)
        case .none:
            break
        }

        if pet.asleep {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .heavy),
                .foregroundColor: NSColor(hex: 0x5dade2),
            ]
            for i in 0..<3 {
                let phase = (t * 0.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let zx = centerX + bodyW / 2 + CGFloat(phase) * 18
                let zy = headTop - 6 - CGFloat(phase) * 26
                ("z" as NSString).draw(at: NSPoint(x: zx, y: zy), withAttributes: attrs)
            }
        }

        if let text = game.bubbleText { drawBubble(text, tailX: centerX, bottom: headTop - 4) }
        if hovering && game.bubbleText == nil {
            drawName(pet.name, centerX: centerX, y: oy + CGFloat(sp.groundY + 1) * s + 3)
        }
    }

    /// Диалогово прозорче точно над главата, с опашка към него.
    private func drawBubble(_ text: String, tailX: CGFloat, bottom: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor.white,
        ]
        let str = text.uppercased() as NSString
        let maxW = bounds.width - 12
        let size = str.boundingRect(with: NSSize(width: maxW - 14, height: 200),
                                    options: [.usesLineFragmentOrigin], attributes: attrs).size
        let w = ceil(size.width) + 14, h = ceil(size.height) + 10
        let x = min(max(4, tailX - w / 2), bounds.width - w - 4)
        let y = max(2, bottom - h - 6)
        let rect = NSRect(x: x, y: y, width: w, height: h)
        NSColor(hex: 0x1b1b24, alpha: 0.95).setFill(); rect.fill()
        NSColor.white.setFill()
        NSRect(x: rect.minX, y: rect.minY, width: w, height: 2).fill()
        NSRect(x: rect.minX, y: rect.maxY - 2, width: w, height: 2).fill()
        NSRect(x: rect.minX, y: rect.minY, width: 2, height: h).fill()
        NSRect(x: rect.maxX - 2, y: rect.minY, width: 2, height: h).fill()
        // опашка от пиксели
        let tx = min(max(rect.minX + 8, tailX - 3), rect.maxX - 14)
        NSColor.white.setFill()
        NSRect(x: tx, y: rect.maxY - 2, width: 8, height: 3).fill()
        NSRect(x: tx + 2, y: rect.maxY + 1, width: 4, height: 2).fill()
        NSRect(x: tx + 3, y: rect.maxY + 3, width: 2, height: 2).fill()
        str.draw(with: NSRect(x: rect.minX + 7, y: rect.minY + 5, width: w - 14, height: h - 10),
                 options: [.usesLineFragmentOrigin], attributes: attrs)
    }

    private func drawName(_ name: String, centerX: CGFloat, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor.white,
        ]
        let str = name.uppercased() as NSString
        let size = str.size(withAttributes: attrs)
        let rect = NSRect(x: centerX - size.width / 2 - 6, y: y, width: size.width + 12, height: size.height + 4)
        NSColor(hex: 0x1b1b24, alpha: 0.9).setFill(); rect.fill()
        str.draw(at: NSPoint(x: rect.minX + 6, y: rect.minY + 2), withAttributes: attrs)
    }
}

// MARK: - Пиксели-храна по екрана

final class FoodPixel: NSObject {
    let color: Int
    let panel: NSPanel
    let view: FoodView

    init(color: Int, at origin: NSPoint, game: Game) {
        self.color = color
        panel = overlayPanel(NSRect(origin: origin, size: FoodView.size), key: false)
        view = FoodView(frame: NSRect(origin: .zero, size: FoodView.size))
        super.init()
        panel.level = .floating
        view.game = game
        view.food = self
        panel.contentView = view
        panel.orderFrontRegardless()
    }

    func remove() {
        panel.orderOut(nil)
        panel.close()
    }
}

final class FoodView: NSView {
    weak var game: Game?
    weak var food: FoodPixel?
    private var dragStart: NSPoint?
    private var windowStart = NSPoint.zero

    static let size = NSSize(width: 30, height: 34)

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        windowStart = window?.frame.origin ?? .zero
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let window else { return }
        let p = NSEvent.mouseLocation
        window.setFrameOrigin(NSPoint(x: windowStart.x + p.x - start.x, y: windowStart.y + p.y - start.y))
    }

    override func mouseUp(with event: NSEvent) {
        dragStart = nil
        if let food { game?.foodDropped(food) }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let food else { return }
        let t = game?.time ?? 0
        let bob = dragStart == nil ? CGFloat(sin(t * 3 + Double(food.color % 7))) * 2.5 : 0
        let r = NSRect(x: 7, y: 9 + bob, width: 16, height: 16)
        NSColor(hex: 0x2b2b3a).setFill(); r.fill()
        NSColor(hex: food.color).setFill(); r.insetBy(dx: 2.5, dy: 2.5).fill()
        NSColor(white: 1, alpha: 0.7).setFill()
        NSRect(x: r.minX + 3.5, y: r.minY + 3.5, width: 3, height: 3).fill()
        if Int(t * 2 + Double(food.color % 5)) % 3 == 0 {
            NSColor.white.setFill()
            NSRect(x: r.maxX + 1, y: r.minY - 5, width: 3, height: 3).fill()
        }
    }
}

// MARK: - Топче за гонене

final class BallPixel: NSObject {
    let panel: NSPanel
    let view: BallView
    weak var game: Game?
    var velocity = CGVector.zero
    var flying = false
    var carried = false
    var thrown = false
    private var timer: Timer?

    static let size = NSSize(width: 22, height: 22)

    init(at origin: NSPoint, game: Game) {
        panel = overlayPanel(NSRect(origin: origin, size: BallPixel.size), key: false)
        view = BallView(frame: NSRect(origin: .zero, size: BallPixel.size))
        self.game = game
        super.init()
        view.ball = self
        panel.contentView = view
        panel.orderFrontRegardless()
    }

    var bounds: NSRect {
        (panel.screen ?? NSScreen.main)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    }

    func launch(_ v: CGVector, thrown: Bool) {
        velocity = v
        self.thrown = thrown
        flying = true
        carried = false
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / 60, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        flying = false
    }

    @objc func step() {
        let dt: CGFloat = 1.0 / 60
        let vf = bounds
        var o = panel.frame.origin
        let w = BallPixel.size.width
        velocity.dy -= 2200 * dt
        o.x += velocity.dx * dt
        o.y += velocity.dy * dt
        if o.y <= vf.minY {
            o.y = vf.minY
            velocity.dy = abs(velocity.dy) * 0.55
            velocity.dx *= 0.82
            if velocity.dy < 90 { velocity.dy = 0 }
        }
        if o.y >= vf.maxY - w { o.y = vf.maxY - w; velocity.dy = -abs(velocity.dy) * 0.5 }
        if o.x <= vf.minX { o.x = vf.minX; velocity.dx = abs(velocity.dx) * 0.7 }
        if o.x >= vf.maxX - w { o.x = vf.maxX - w; velocity.dx = -abs(velocity.dx) * 0.7 }
        panel.setFrameOrigin(o)
        if o.y <= vf.minY && velocity.dy == 0 {
            velocity.dx *= 0.9
            if abs(velocity.dx) < 12 {
                stop()
                game?.ballLanded(self)
            }
        }
        view.needsDisplay = true
    }

    func remove() {
        stop()
        panel.orderOut(nil)
        panel.close()
    }
}

final class BallView: NSView {
    weak var ball: BallPixel?
    private var samples: [(Double, NSPoint)] = []
    private var dragStart: NSPoint?
    private var windowStart = NSPoint.zero

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let ball, !ball.carried else { return }
        ball.stop()
        dragStart = NSEvent.mouseLocation
        windowStart = window?.frame.origin ?? .zero
        samples = [(ProcessInfo.processInfo.systemUptime, NSEvent.mouseLocation)]
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let window else { return }
        let p = NSEvent.mouseLocation
        window.setFrameOrigin(NSPoint(x: windowStart.x + p.x - start.x, y: windowStart.y + p.y - start.y))
        samples.append((ProcessInfo.processInfo.systemUptime, p))
        if samples.count > 6 { samples.removeFirst() }
    }

    override func mouseUp(with event: NSEvent) {
        guard dragStart != nil, let ball else { return }
        dragStart = nil
        let now = ProcessInfo.processInfo.systemUptime
        var v = CGVector.zero
        if let first = samples.first(where: { now - $0.0 < 0.12 }), let last = samples.last, last.0 > first.0 {
            let dt = CGFloat(last.0 - first.0)
            v = CGVector(dx: (last.1.x - first.1.x) / dt, dy: (last.1.y - first.1.y) / dt)
        }
        let maxV: CGFloat = 2600
        let len = sqrt(v.dx * v.dx + v.dy * v.dy)
        if len > maxV { v = CGVector(dx: v.dx / len * maxV, dy: v.dy / len * maxV) }
        ball.launch(v, thrown: true)
        ball.game?.ballThrown()
    }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 2, dy: 2)
        NSColor(hex: 0x2b2b3a).setFill()
        NSBezierPath(ovalIn: r).fill()
        NSColor(hex: 0xf4a261).setFill()
        NSBezierPath(ovalIn: r.insetBy(dx: 2.5, dy: 2.5)).fill()
        NSColor(white: 1, alpha: 0.8).setFill()
        NSRect(x: r.minX + 5, y: r.minY + 5, width: 3, height: 3).fill()
    }
}

// MARK: - Ретро менюто (десен бутон)

struct RetroButton {
    let icon: Grid
    let label: String
    let value: Double?          // за чертите; nil = действие
    let action: Selector?
}

final class RetroView: NSView {
    weak var game: Game?
    var stats: [RetroButton] = []
    var actions: [RetroButton] = []
    var hover: (Int, Int)?      // (ред, индекс)

    static let cell: CGFloat = 36
    static let pad: CGFloat = 12
    static let width = pad * 2 + cell * 8
    static let height: CGFloat = 158

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    private func rowY(_ row: Int) -> CGFloat { row == 0 ? 50 : 94 }

    private func rowX(_ row: Int, _ i: Int) -> CGFloat {
        let count = CGFloat(row == 0 ? stats.count : actions.count)
        let start = (bounds.width - count * RetroView.cell) / 2
        return start + CGFloat(i) * RetroView.cell
    }

    private func hit(_ p: NSPoint) -> (Int, Int)? {
        for row in 0...1 {
            let items = row == 0 ? stats : actions
            for i in items.indices {
                let r = NSRect(x: rowX(row, i), y: rowY(row), width: RetroView.cell, height: RetroView.cell)
                if r.contains(p) { return (row, i) }
            }
        }
        return nil
    }

    override func mouseMoved(with event: NSEvent) {
        let h = hit(convert(event.locationInWindow, from: nil))
        if h?.0 != hover?.0 || h?.1 != hover?.1 { hover = h; needsDisplay = true }
    }

    override func mouseExited(with event: NSEvent) { hover = nil; needsDisplay = true }

    override func mouseDown(with event: NSEvent) {
        guard let h = hit(convert(event.locationInWindow, from: nil)), h.0 == 1,
              let sel = actions[h.1].action, let game else { return }
        game.closeRetro()
        game.perform(sel)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let pet = game.pet
        // рамка като в стара игра
        NSColor(hex: 0x1b1b24, alpha: 0.97).setFill(); bounds.fill()
        NSColor.white.setFill()
        let b = bounds
        for (x, y, w, h) in [(b.minX, b.minY, b.width, 3.0), (b.minX, b.maxY - 3, b.width, 3.0),
                             (b.minX, b.minY, 3.0, b.height), (b.maxX - 3, b.minY, 3.0, b.height)] {
            NSRect(x: x, y: y, width: w, height: h).fill()
        }
        NSColor(hex: 0x5dade2).setFill()
        for (x, y, w, h) in [(b.minX + 5, b.minY + 5, b.width - 10, 1.0), (b.minX + 5, b.maxY - 6, b.width - 10, 1.0),
                             (b.minX + 5, b.minY + 5, 1.0, b.height - 10), (b.maxX - 6, b.minY + 5, 1.0, b.height - 10)] {
            NSRect(x: x, y: y, width: w, height: h).fill()
        }

        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy)
        let white: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let yellow: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(hex: 0xffd166)]
        (pet.name.uppercased() as NSString).draw(at: NSPoint(x: 14, y: 12), withAttributes: white)
        let lvl = "НИВО \(pet.level)" as NSString
        let lw = lvl.size(withAttributes: yellow).width
        lvl.draw(at: NSPoint(x: b.width - 14 - lw, y: 12), withAttributes: yellow)
        let coins = "\(pet.coins) МОНЕТИ" as NSString
        let cw = coins.size(withAttributes: yellow).width
        coins.draw(at: NSPoint(x: (b.width - cw) / 2, y: 12), withAttributes: yellow)

        // XP черта на сегменти
        let segs = 20
        let filled = Int((Double(pet.xp) / Double(pet.xpNeeded) * Double(segs)).rounded(.down))
        let segW = (b.width - 28) / CGFloat(segs)
        for i in 0..<segs {
            NSColor(hex: i < filled ? 0x48cae4 : 0x3a3a50).setFill()
            NSRect(x: 14 + CGFloat(i) * segW, y: 32, width: segW - 2, height: 6).fill()
        }

        for row in 0...1 {
            let items = row == 0 ? stats : actions
            for (i, item) in items.enumerated() {
                let x = rowX(row, i), y = rowY(row)
                let isHover = hover?.0 == row && hover?.1 == i
                if isHover {
                    NSColor(hex: 0x3a3a50).setFill()
                    NSRect(x: x + 2, y: y + 2, width: RetroView.cell - 4, height: RetroView.cell - 4).fill()
                }
                let s: CGFloat = 3
                let ix = x + (RetroView.cell - 8 * s) / 2, iy = y + (RetroView.cell - 8 * s) / 2
                if let v = item.value {
                    // празна иконка, която се пълни отдолу нагоре
                    drawGrid(item.icon, x: ix, y: iy, s: s, palette: { $0 == "." ? nil : NSColor(hex: 0x4a4a60) })
                    let rows = Int((v / 100 * 8).rounded())
                    let part = Array(item.icon.enumerated().map { $0.offset >= 8 - rows ? $0.element : Array(repeating: Character("."), count: $0.element.count) })
                    drawGrid(part, x: ix, y: iy, s: s, palette: game.color)
                } else {
                    drawGrid(item.icon, x: ix, y: iy, s: s, palette: game.color)
                }
            }
        }

        // надпис за посоченото
        var label = "ПОСОЧИ ИКОНКА"
        if let h = hover {
            let item = h.0 == 0 ? stats[h.1] : actions[h.1]
            label = item.label.uppercased()
            if let v = item.value { label += "  \(Int(v.rounded()))%" }
        }
        let ls = label as NSString
        let size = ls.size(withAttributes: white)
        ls.draw(at: NSPoint(x: (b.width - size.width) / 2, y: 136), withAttributes: hover == nil ? [.font: font, .foregroundColor: NSColor(hex: 0x8d99ae)] : white)
    }
}

// MARK: - Игра: пиксели от небето

final class CatchView: NSView {
    weak var game: Game?
    struct Item { var x: CGFloat; var y: CGFloat; var vy: CGFloat; var kind: Int; var color: Int }  // 0 пиксел, 1 златен, 2 бомба
    var items: [Item] = []
    var booms: [(x: CGFloat, y: CGFloat, t: Double)] = []
    var playerX: CGFloat = 0
    var score = 0
    var best = 0
    var lives = 3
    var over = false
    var time: Double = 0
    var spawnIn: Double = 0.5
    var stuckSince: Double?      // кога е залепнал за екрана
    var stuckAt = NSPoint.zero
    var timer: Timer?
    var newRecord = false

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    func start() {
        items = []
        booms = []
        score = 0
        lives = 3
        over = false
        time = 0
        stuckSince = nil
        newRecord = false
        playerX = bounds.midX
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / 60, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() { timer?.invalidate(); timer = nil }

    var petScale: CGFloat { 4 }
    var groundY: CGFloat { bounds.height - 30 }

    private var playerRect: NSRect {
        let n = CGFloat(game?.pet.cellsAcross ?? 3) * CGFloat(cellSize)
        let w = (n + 4) * petScale
        return NSRect(x: playerX - w / 2, y: groundY - (n + 10) * petScale, width: w, height: (n + 4) * petScale)
    }

    @objc func step() {
        let dt = 1.0 / 60
        time += dt
        if !over {
            if stuckSince == nil {
                // Пиксчо следва мишката
                if let w = window {
                    let mx = NSEvent.mouseLocation.x - w.frame.minX
                    playerX += (mx - playerX) * 0.25
                }
                spawnIn -= dt
                if spawnIn <= 0 {
                    spawnIn = max(0.18, 0.7 - time * 0.006)
                    let r = Double.random(in: 0..<1)
                    let bombChance = min(0.4, 0.18 + time * 0.002)
                    let kind = r < bombChance ? 2 : (r < bombChance + 0.07 ? 1 : 0)
                    items.append(Item(x: CGFloat.random(in: 40...(bounds.width - 40)), y: -20,
                                      vy: CGFloat.random(in: 160...260) + CGFloat(time) * 3, kind: kind,
                                      color: kind == 1 ? 0xffd166 : foodColors.randomElement()!))
                }
                let pr = playerRect
                var keep: [Item] = []
                for var it in items {
                    it.y += it.vy * CGFloat(dt)
                    let r = NSRect(x: it.x - 9, y: it.y - 9, width: 18, height: 18)
                    if r.intersects(pr) {
                        if it.kind == 2 {
                            booms.append((it.x, it.y, time))
                            lives -= 1
                            stuckSince = time
                            stuckAt = NSPoint(x: bounds.midX + CGFloat.random(in: -200...200), y: bounds.height * 0.3)
                            game?.annoy(8)
                        } else {
                            score += it.kind == 1 ? 5 : 1
                        }
                        continue
                    }
                    if it.y > groundY + 10 {
                        if it.kind == 2 { booms.append((it.x, groundY, time)) }
                        continue
                    }
                    keep.append(it)
                }
                items = keep
            } else if let since = stuckSince, time - since > 2.8 {
                stuckSince = nil
                items.removeAll()
                if lives <= 0 {
                    over = true
                    if score > best { best = score; newRecord = true }
                }
            }
        }
        booms.removeAll { time - $0.t > 0.6 }
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: game?.closeCatch()
        case 49: if over { start() }
        case 123: playerX -= 40
        case 124: playerX += 40
        default: super.keyDown(with: event)
        }
    }

    override func mouseDown(with event: NSEvent) { if over { start() } }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        NSColor(hex: 0x0b0b14, alpha: 0.55).setFill(); bounds.fill()
        NSColor(hex: 0x2b2b3a, alpha: 0.9).setFill()
        NSRect(x: 0, y: groundY, width: bounds.width, height: bounds.height - groundY).fill()

        let font = NSFont.monospacedSystemFont(ofSize: 20, weight: .heavy)
        let white: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        let yellow: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor(hex: 0xffd166)]
        ("ТОЧКИ \(score)" as NSString).draw(at: NSPoint(x: 30, y: 40), withAttributes: white)
        ("РЕКОРД \(max(best, score))" as NSString).draw(at: NSPoint(x: 30, y: 66), withAttributes: yellow)
        ("ЖИВОТИ " + String(repeating: "■ ", count: max(0, lives)) as NSString)
            .draw(at: NSPoint(x: 30, y: 92), withAttributes: [.font: font, .foregroundColor: NSColor(hex: 0xe63946)])
        let hint = "ESC  ИЗХОД" as NSString
        hint.draw(at: NSPoint(x: bounds.width - hint.size(withAttributes: white).width - 30, y: 40), withAttributes: white)

        for it in items {
            if it.kind == 2 {
                drawGrid(bombGrid, x: it.x - 9, y: it.y - 12, s: 3, palette: game.color)
                if Int(time * 10) % 2 == 0 {
                    NSColor(hex: 0xffd166).setFill(); NSRect(x: it.x + 6, y: it.y - 15, width: 3, height: 3).fill()
                }
            } else {
                let r = NSRect(x: it.x - 9, y: it.y - 9, width: 18, height: 18)
                NSColor(hex: 0x2b2b3a).setFill(); r.fill()
                NSColor(hex: it.color).setFill(); r.insetBy(dx: 3, dy: 3).fill()
                if it.kind == 1 { NSColor.white.setFill(); NSRect(x: r.minX + 4, y: r.minY + 4, width: 3, height: 3).fill() }
            }
        }

        for b in booms {
            let p = CGFloat((time - b.t) / 0.6)
            let rad = 10 + p * 50
            NSColor(hex: 0xff924c, alpha: 1 - p).setFill()
            NSBezierPath(ovalIn: NSRect(x: b.x - rad, y: b.y - rad, width: rad * 2, height: rad * 2)).fill()
            NSColor(hex: 0xffd166, alpha: 1 - p).setFill()
            NSBezierPath(ovalIn: NSRect(x: b.x - rad / 2, y: b.y - rad / 2, width: rad, height: rad)).fill()
        }

        let level = game.pet.level
        if let since = stuckSince {
            // гръмнал е и е залепнал за стъклото на екрана, после бавно се свлича
            let p = CGFloat(min(1, (time - since) / 2.8))
            let sp = buildSprite(level: level, face: .angry, pose: .wave, frame: 0, working: false, worn: game.pet.worn)
            let s: CGFloat = max(5, 200 / CGFloat(sp.right - sp.left + 1))
            let ox = stuckAt.x - CGFloat(sp.cx) * s
            let oy = stuckAt.y - CGFloat(sp.top) * s + p * p * bounds.height * 0.5
            NSColor(white: 1, alpha: 0.6).setStroke()
            let c = NSPoint(x: stuckAt.x, y: stuckAt.y + CGFloat(sp.bottom - sp.top) * s / 2)
            for i in 0..<9 {
                let a = Double(i) * 0.7 + 0.3
                let path = NSBezierPath()
                path.lineWidth = 2
                path.move(to: c)
                path.line(to: NSPoint(x: c.x + CGFloat(cos(a)) * 180, y: c.y + CGFloat(sin(a)) * 160))
                path.stroke()
            }
            let box = NSRect(x: ox + CGFloat(sp.minX) * s, y: oy + CGFloat(sp.minY) * s,
                             width: CGFloat(sp.maxX - sp.minX + 1) * s, height: CGFloat(sp.maxY - sp.minY + 1) * s)
            drawGlitchy(sp.grid, x: ox, y: oy, s: s, palette: game.color, glitch: Int(time * 8) % 3 == 0, noiseRect: box)
        } else {
            let sp = buildSprite(level: level, face: over ? .sad : .happy, pose: .wave, frame: Int(time * 4), working: false, worn: game.pet.worn)
            let s = petScale
            let ox = playerX - CGFloat(sp.cx) * s
            let oy = groundY - CGFloat(sp.groundY + 1) * s
            drawGrid(sp.grid, x: ox, y: oy, s: s, palette: game.color)
        }

        if over {
            let big = NSFont.monospacedSystemFont(ofSize: 44, weight: .heavy)
            let lines = [
                ("КРАЙ НА ИГРАТА", 0xffffff),
                ("ТОЧКИ \(score)" + (newRecord ? "  НОВ РЕКОРД!" : ""), 0xffd166),
                ("SPACE  ОТНОВО     ESC  ИЗХОД", 0x8d99ae),
            ]
            var y = bounds.height * 0.35
            for (text, hex) in lines {
                let f = text == lines[2].0 ? NSFont.monospacedSystemFont(ofSize: 20, weight: .heavy) : big
                let a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: NSColor(hex: hex)]
                let str = text as NSString
                let w = str.size(withAttributes: a).width
                str.draw(at: NSPoint(x: (bounds.width - w) / 2, y: y), withAttributes: a)
                y += f.pointSize * 1.6
            }
        }
    }
}

// MARK: - Съобщение на целия екран

final class AlertView: NSView {
    weak var game: Game?
    var title = ""
    var subtitle = ""
    var started: Double = 0

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.closeAlert() }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time - started
        NSColor(hex: 0x0b0b14, alpha: min(0.75, t * 2)).setFill(); bounds.fill()

        let sp = buildSprite(level: game.pet.level, face: .angry, pose: .wave, frame: Int(game.time * 4), working: false, worn: game.pet.worn)
        let s: CGFloat = min(14, 260 / CGFloat(sp.maxY - sp.minY + 1))
        let shake = CGFloat(Int.random(in: -3...3))
        let ox = bounds.midX - CGFloat(sp.cx) * s + shake
        let oy = bounds.midY - 40 - CGFloat(sp.groundY + 1) * s
        let box = NSRect(x: ox + CGFloat(sp.minX) * s, y: oy + CGFloat(sp.minY) * s,
                         width: CGFloat(sp.maxX - sp.minX + 1) * s, height: CGFloat(sp.maxY - sp.minY + 1) * s)
        drawGlitchy(sp.grid, x: ox, y: oy, s: s, palette: game.color, glitch: Int(game.time * 6) % 3 != 0, noiseRect: box)

        for (i, (text, size, hex)) in [(title, CGFloat(64), 0xe63946), (subtitle, CGFloat(26), 0xffffff)].enumerated() {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: size, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: hex)]
            let str = text as NSString
            let w = str.size(withAttributes: a).width
            let jx = i == 0 && Int(game.time * 10) % 4 == 0 ? CGFloat(Int.random(in: -6...6)) : 0
            str.draw(at: NSPoint(x: (bounds.width - w) / 2 + jx, y: bounds.midY + (i == 0 ? 0 : 80)), withAttributes: a)
        }
        let hint = "КЛИКНИ, ЗА ДА ЗАТВОРИШ" as NSString
        let ha: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 14, weight: .bold),
                                                 .foregroundColor: NSColor(hex: 0x8d99ae)]
        hint.draw(at: NSPoint(x: (bounds.width - hint.size(withAttributes: ha).width) / 2, y: bounds.maxY - 60), withAttributes: ha)
    }
}


// MARK: - Клипове, които Пиксчо е монтирал

let clipTitles = [
    "ВЛОГ: ЕДИН ДЕН С ПИКСЧО",
    "ЕКШЪН: БОМБИТЕ ИДВАТ",
    "КУЛИНАРНО ШОУ: ПИКСЕЛ ТАРТАР",
    "МУЗИКАЛЕН КЛИП: ПИКСЕЛ ДИСКО",
    "ДОКУМЕНТАЛЕН: ДИВИ ПИКСЕЛИ",
    "ХОРЪР: ГЛИЧЪТ",
    "СПОРТ: ПИКСЕЛ ФУТБОЛ",
    "КОСМОС: ПИКСЧО НА ЛУНАТА",
    "РЕКЛАМА: ПИКСЕЛ 3000",
    "НОВИНИ: ИЗВЪНРЕДНО",
]

final class ClipView: NSView {
    weak var game: Game?
    var clip = 0
    var started: Double = 0

    static let length: Double = 6
    static let size = NSSize(width: 320, height: 240)

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    private var yesRect: NSRect { NSRect(x: bounds.midX - 110, y: 128, width: 100, height: 34) }
    private var noRect: NSRect { NSRect(x: bounds.midX + 10, y: 128, width: 100, height: 34) }

    override func mouseDown(with event: NSEvent) {
        guard let game else { return }
        let p = convert(event.locationInWindow, from: nil)
        if game.time - started < ClipView.length {
            started = game.time - ClipView.length     // прескача до въпроса
        } else if yesRect.contains(p) {
            game.clipAnswer(true)
        } else if noRect.contains(p) {
            game.clipAnswer(false)
        }
    }

    private func text(_ str: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, color: Int, center: Bool = false) {
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: size, weight: .heavy),
                                                .foregroundColor: NSColor(hex: color)]
        let ns = str as NSString
        let w = center ? ns.size(withAttributes: a).width : 0
        ns.draw(at: NSPoint(x: x - w / 2, y: y), withAttributes: a)
    }

    /// Рисува Пиксчо с краката на дадена линия.
    private func pet(_ game: Game, face: Face, pose: Pose, frame: Int, x: CGFloat, ground: CGFloat,
                     height: CGFloat = 90, glitch: Bool = false) {
        let sp = buildSprite(level: game.pet.level, face: face, pose: pose, frame: frame, working: false, worn: game.pet.worn)
        let s = min(3, height / CGFloat(sp.maxY - sp.minY + 1))
        let ox = x - CGFloat(sp.cx) * s
        let oy = ground - CGFloat(sp.groundY + 1) * s
        let box = NSRect(x: ox + CGFloat(sp.minX) * s, y: oy + CGFloat(sp.minY) * s,
                         width: CGFloat(sp.maxX - sp.minX + 1) * s, height: CGFloat(sp.maxY - sp.minY + 1) * s)
        drawGlitchy(sp.grid, x: ox, y: oy, s: s, palette: game.color, glitch: glitch, noiseRect: box)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = min(ClipView.length, game.time - started)
        let b = bounds
        NSColor(hex: 0x1b1b24).setFill(); b.fill()
        let screen = NSRect(x: 8, y: 26, width: b.width - 16, height: 170)
        let W = screen.width, H = screen.height

        text("КЛИП \(clip + 1)/\(clipTitles.count)", 10, 6, size: 10, color: 0x8d99ae)
        if Int(t * 2) % 2 == 0 {
            NSColor(hex: 0xe63946).setFill()
            NSBezierPath(ovalIn: NSRect(x: b.width - 52, y: 8, width: 8, height: 8)).fill()
        }
        text("REC", b.width - 40, 6, size: 10, color: 0xe63946)

        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: screen).setClip()
        let x0 = screen.minX, y0 = screen.minY
        let ground = y0 + H - 22

        switch clip {
        case 0: // влог
            NSColor(hex: 0x9ad1f5).setFill(); screen.fill()
            NSColor(hex: 0xffd166).setFill()
            NSRect(x: x0 + W - 60, y: y0 + 14, width: 30, height: 30).fill()
            NSColor.white.setFill()
            for i in 0..<3 {
                let cx = x0 + (CGFloat(i) * 130 + 300 - CGFloat(t) * 25).truncatingRemainder(dividingBy: W + 80) - 40
                NSRect(x: cx, y: y0 + 20 + CGFloat(i) * 18, width: 44, height: 12).fill()
                NSRect(x: cx + 10, y: y0 + 14 + CGFloat(i) * 18, width: 22, height: 8).fill()
            }
            NSColor(hex: 0x8ac926).setFill(); NSRect(x: x0, y: ground, width: W, height: 22).fill()
            NSColor(hex: 0x6a9e1f).setFill()
            for i in 0..<12 {
                let gx = x0 + (CGFloat(i) * 30 - CGFloat(t) * 60).truncatingRemainder(dividingBy: W + 30)
                NSRect(x: gx < x0 ? gx + W + 30 : gx, y: ground + 8, width: 10, height: 4).fill()
            }
            pet(game, face: .happy, pose: .walk, frame: Int(t * 8), x: x0 + W / 2, ground: ground)
            text(t < 3 ? "ДЕН 1: ИЗЛИЗАМ НАВЪН" : "ВРЕМЕТО Е ПИКСЕЛНО!", x0 + 8, y0 + H - 16, size: 9, color: 0x1b1b24)
        case 1: // екшън
            NSColor(hex: 0x3d2c4e).setFill(); screen.fill()
            NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: x0, y: ground, width: W, height: 22).fill()
            let px = x0 + 80
            var jump: CGFloat = 0
            for i in 0..<4 {
                let bx = x0 + W + CGFloat(i) * 110 - CGFloat(t) * 150
                drawGrid(bombGrid, x: bx, y: ground - 24, s: 3, palette: game.color)
                let d = bx + 9 - px
                if abs(d) < 45 { jump = max(jump, CGFloat(cos(Double(d / 45) * .pi / 2)) * 55) }
                if d < -60 && d > -110 {
                    let r = (-60 - d) * 0.8
                    NSColor(hex: 0xff924c, alpha: max(0, 1 - (-60 - d) / 50)).setFill()
                    NSBezierPath(ovalIn: NSRect(x: bx + 9 - r, y: ground - 12 - r, width: r * 2, height: r * 2)).fill()
                }
            }
            pet(game, face: jump > 5 ? .happy : .angry, pose: jump > 5 ? .wave : .walk, frame: Int(t * 8),
                x: px, ground: ground - jump, height: 70)
            text("БЕЗ КАСКАДЬОРИ!", x0 + W - 8 - 100, y0 + 8, size: 9, color: 0xffd166)
        case 2: // кулинарно шоу
            NSColor(hex: 0xfff3d6).setFill(); screen.fill()
            NSColor(hex: 0xf4e1b5).setFill()
            for i in 0..<12 { for j in 0..<6 where (i + j) % 2 == 0 {
                NSRect(x: x0 + CGFloat(i) * 26, y: y0 + CGFloat(j) * 26, width: 26, height: 26).fill()
            } }
            NSColor(hex: 0xc49a6c).setFill(); NSRect(x: x0, y: ground, width: W, height: 22).fill()
            let mouthOpen = Int(t * 4) % 2 == 0
            for i in 0..<5 {
                let ph = (t * 0.7 + Double(i) * 0.2).truncatingRemainder(dividingBy: 1)
                let fy = y0 + CGFloat(ph) * (H - 70)
                NSColor(hex: 0x2b2b3a).setFill()
                NSRect(x: x0 + W / 2 - 7 + CGFloat(i - 2) * 6, y: fy, width: 14, height: 14).fill()
                NSColor(hex: foodColors[(i + clip) % foodColors.count]).setFill()
                NSRect(x: x0 + W / 2 - 5 + CGFloat(i - 2) * 6, y: fy + 2, width: 10, height: 10).fill()
            }
            pet(game, face: mouthOpen ? .eatOpen : .eatShut, pose: .idle, frame: 0, x: x0 + W / 2, ground: ground)
            if t > 3.5 { text("ВКУСНО!", x0 + W / 2, y0 + 10, size: 18, color: 0xe63946, center: true) }
        case 3: // музикален клип
            let beat = Int(t * 4)
            let colors = [0xff0055, 0x00e5ff, 0xffd166, 0xc77dff, 0x8ac926]
            for i in 0..<8 {
                NSColor(hex: colors[(i + beat) % colors.count], alpha: 0.85).setFill()
                NSRect(x: x0 + CGFloat(i) * W / 8, y: y0, width: W / 8 + 1, height: H).fill()
            }
            NSColor(hex: 0x1b1b24).setFill(); NSRect(x: x0, y: ground, width: W, height: 22).fill()
            for i in 0..<4 {
                let ph = (t * 0.5 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                text("♪", x0 + 20 + CGFloat(i) * 75, ground - 20 - CGFloat(ph) * 120, size: 20, color: 0xffffff)
            }
            let bounce: CGFloat = beat % 2 == 0 ? 10 : 0
            pet(game, face: .happy, pose: .wave, frame: beat, x: x0 + W / 2, ground: ground - bounce)
        case 4: // документален
            NSColor(hex: 0xbde0a4).setFill(); screen.fill()
            NSColor(hex: 0x52b788).setFill(); NSRect(x: x0, y: ground, width: W, height: 22).fill()
            for i in 0..<4 {
                let gold = i == 3 && t > 3
                let ph = (t * 0.25 + Double(i) * 0.27).truncatingRemainder(dividingBy: 1)
                let px = x0 + W - CGFloat(ph) * (W + 40)
                let hop = abs(CGFloat(sin(t * 6 + Double(i)))) * 20
                NSColor(hex: 0x2b2b3a).setFill()
                NSRect(x: px - 1, y: ground - 12 - hop, width: 12, height: 12).fill()
                NSColor(hex: gold ? 0xffd166 : foodColors[i]).setFill()
                NSRect(x: px + 1, y: ground - 10 - hop, width: 8, height: 8).fill()
            }
            pet(game, face: .focus, pose: .idle, frame: 0, x: x0 + 60, ground: ground, height: 70)
            text(t > 3 ? "РЯДЪК ЗЛАТЕН ПИКСЕЛ…" : "ДИВИТЕ ПИКСЕЛИ МИГРИРАТ", x0 + 8, y0 + 8, size: 9, color: 0x1b1b24)
        case 6: // футбол
            NSColor(hex: 0x52b788).setFill(); screen.fill()
            NSColor(white: 1, alpha: 0.7).setFill()
            NSRect(x: x0 + W / 2 - 1, y: y0, width: 2, height: H).fill()
            NSRect(x: x0 + W - 30, y: ground - 60, width: 4, height: 60).fill()
            NSRect(x: x0 + W - 30, y: ground - 60, width: 26, height: 4).fill()
            let kick = min(1, max(0, (t - 2.5) / 1.5))
            let bx = x0 + 110 + CGFloat(kick) * (W - 150)
            let by = ground - 10 - CGFloat(sin(kick * .pi)) * 50
            NSColor.white.setFill(); NSBezierPath(ovalIn: NSRect(x: bx, y: by, width: 12, height: 12)).fill()
            NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: bx + 4, y: by + 4, width: 4, height: 4).fill()
            let px = x0 + 20 + CGFloat(min(t, 2.5) / 2.5) * 70
            pet(game, face: t > 4 ? .happy : .focus, pose: t < 2.5 ? .walk : .wave, frame: Int(t * 8), x: px, ground: ground, height: 70)
            if t > 4 { text("ГОООЛ!", x0 + W / 2, y0 + 12, size: 24, color: 0xffd166, center: true) }
        case 7: // космос
            NSColor(hex: 0x0b0b1e).setFill(); screen.fill()
            for i in 0..<30 {
                let sx = x0 + CGFloat((i * 97) % Int(W)), sy = y0 + CGFloat((i * 53) % Int(H - 30))
                NSColor(white: 1, alpha: Int(t * 3 + Double(i)) % 4 == 0 ? 0.3 : 0.9).setFill()
                NSRect(x: sx, y: sy, width: 2, height: 2).fill()
            }
            NSColor(hex: 0x1982c4).setFill(); NSBezierPath(ovalIn: NSRect(x: x0 + W - 70, y: y0 + 14, width: 40, height: 40)).fill()
            NSColor(hex: 0x52b788).setFill(); NSRect(x: x0 + W - 60, y: y0 + 26, width: 14, height: 10).fill()
            NSColor(hex: 0x8d99ae).setFill(); NSRect(x: x0, y: ground, width: W, height: 22).fill()
            NSColor(hex: 0x6a6a80).setFill()
            for i in 0..<5 { NSRect(x: x0 + 20 + CGFloat(i) * 60, y: ground + 6, width: 16, height: 6).fill() }
            let float = CGFloat(sin(t * 1.5)) * 30 + 30
            pet(game, face: .happy, pose: .wave, frame: Int(t * 2), x: x0 + W / 2 - 40, ground: ground - float, height: 70)
            text("МАЛКА СТЪПКА ЗА ПИКСЕЛ…", x0 + 8, y0 + 8, size: 9, color: 0xffffff)
        case 8: // реклама
            for i in 0..<10 {
                NSColor(hex: i % 2 == 0 ? 0xff8fab : 0xffc8dd).setFill()
                NSRect(x: x0 + CGFloat(i) * W / 10, y: y0, width: W / 10 + 1, height: H).fill()
            }
            let pulse = 1 + CGFloat(sin(t * 6)) * 0.12
            let gs = 5 * pulse
            drawGrid(iconGold, x: x0 + W - 70 - 4 * gs, y: y0 + 40 - 4 * gs + 30, s: gs, palette: game.color)
            pet(game, face: .happy, pose: .wave, frame: Int(t * 4), x: x0 + 70, ground: ground + 18, height: 80)
            text("ПИКСЕЛ 3000!", x0 + W / 2 + 40, y0 + 10, size: 16, color: 0xe63946, center: true)
            if t > 3 { text("САМО 9,99 МОНЕТИ!", x0 + W / 2 + 40, y0 + H - 34, size: 12, color: 0x1b1b24, center: true) }
        case 9: // новини
            NSColor(hex: 0x1d3557).setFill(); screen.fill()
            NSColor(hex: 0x457b9d).setFill(); NSRect(x: x0, y: y0 + 20, width: W, height: 4).fill()
            pet(game, face: Int(t * 3) % 5 == 0 ? .blink : .focus, pose: .idle, frame: 0, x: x0 + W / 2, ground: ground + 4, height: 80)
            NSColor(hex: 0xa8dadc).setFill(); NSRect(x: x0 + 30, y: ground - 22, width: W - 60, height: 44).fill()
            NSColor(hex: 0xe63946).setFill(); NSRect(x: x0, y: ground + 4, width: W, height: 18).fill()
            let ticker = "ИЗВЪНРЕДНО: ПИКСЧО МОНТИРА 100 ВИДЕА ЗА ЕДИН ДЕН • КЛИЕНТЪТ ВСЕ ОЩЕ ИСКА ПО-ГОЛЯМО ЛОГО • "
            text(ticker + ticker, x0 + W - CGFloat(t) * 90, ground + 7, size: 9, color: 0xffffff)
            text("НОВИНИ", x0 + 8, y0 + 4, size: 11, color: 0xffffff)
        default: // хорър
            let flicker = Int(t * 12) % 7 == 0
            NSColor(hex: flicker ? 0x2b2b3a : 0x050508).setFill(); screen.fill()
            if t < 4.3 {
                pet(game, face: .angry, pose: .idle, frame: 0, x: x0 + W / 2, ground: ground,
                    height: 50 + CGFloat(t) * 6, glitch: Int(t * 8) % 3 == 0)
                text("НЕ ГАСИ ЛАМПАТА…", x0 + W / 2, y0 + 10, size: 10, color: 0x8d99ae, center: true)
            } else {
                pet(game, face: .angry, pose: .wave, frame: Int(t * 10), x: x0 + W / 2, ground: y0 + H + 40,
                    height: 230, glitch: true)
                text("БУ!", x0 + W / 2, y0 + 20, size: 40, color: 0xe63946, center: true)
            }
        }
        NSGraphicsContext.current?.restoreGraphicsState()

        // накрая пита дали ти харесва
        if game.time - started >= ClipView.length {
            NSColor(hex: 0x0b0b14, alpha: 0.8).setFill(); screen.fill()
            text("ХАРЕСВА ЛИ ТИ?", b.midX, 80, size: 18, color: 0xffffff, center: true)
            for (r, label, color) in [(yesRect, "ДА", 0x52b788), (noRect, "НЕ", 0xe63946)] {
                NSColor(hex: color).setFill(); r.fill()
                NSColor.white.setFill()
                NSRect(x: r.minX, y: r.minY, width: r.width, height: 2).fill()
                NSRect(x: r.minX, y: r.maxY - 2, width: r.width, height: 2).fill()
                text(label, r.midX, r.minY + 8, size: 16, color: 0xffffff, center: true)
            }
        }

        // таймлайн отдолу, като в програма за монтаж
        let tl = NSRect(x: 8, y: 204, width: b.width - 16, height: 12)
        let segColors = [0x48cae4, 0xc77dff, 0xf4a261, 0x52b788]
        for i in 0..<4 {
            NSColor(hex: segColors[(i + clip) % segColors.count]).setFill()
            NSRect(x: tl.minX + CGFloat(i) * tl.width / 4, y: tl.minY, width: tl.width / 4 - 2, height: tl.height).fill()
        }
        NSColor(hex: 0xe63946).setFill()
        NSRect(x: tl.minX + CGFloat(t / ClipView.length) * tl.width - 1, y: tl.minY - 3, width: 3, height: tl.height + 6).fill()
        text(clipTitles[clip], 10, 222, size: 9, color: 0xffffff)
        text(String(format: "00:0%d / 00:06", Int(min(t, 6))), b.width - 92, 222, size: 9, color: 0x8d99ae)
    }
}

// MARK: - Контролер

enum FetchPhase { case off, waiting, running, returning }

final class Game: NSObject, NSApplicationDelegate {
    var pet = Pet()
    var window: NSPanel!
    var view: PetView!
    var statusItem: NSStatusItem!

    var time: Double = 0
    var action: Action = .none
    var actionStart: Double = 0
    var actionLength: Double = 2.5
    var bubbleText: String?
    var bubbleUntil: Double = 0
    var nextNag: Double = 8
    var nextBlink: Double = 3
    var blinkUntil: Double = 0
    var nextWorkLine: Double = 60
    var lastLine = ""
    var isDragging = false
    var facingLeft = false
    var walking = false
    var walkTarget: CGFloat?
    var lastTick = Date()
    var lastSave: Double = 0
    var lastFoodColor = 0xffca3a

    // ядосване и гличове
    var anger: Double = 0
    var clickTimes: [Double] = []
    var glitchUntil: Double = 0
    var nextGlitch: Double = 40
    var glitching: Bool { time < glitchUntil || action == .angry && Int(time * 7) % 3 == 0 }

    // търкаляне през екрана
    var rolling = false
    var rollTarget: CGFloat = 0
    var rollAngle: CGFloat = 0
    var nextRoll: Double = 15 * 60

    // храна, топче, игри, менюта
    var foods: [FoodPixel] = []
    var nextFoodSpawn: Double = 45
    var ball: BallPixel?
    var fetchPhase = FetchPhase.off
    var fetchHome = NSPoint.zero
    var fetchIdleSince: Double = 0
    var retroPanel: NSPanel?
    var retroLastInside: Double = 0
    var catchPanel: NSPanel?
    var catchView: CatchView?
    var alertPanel: NSPanel?
    var alertView: AlertView?
    var nextBigAlert: Double = 5 * 60
    var clipPanel: NSPanel?
    var clipView: ClipView?
    var lastClip = -1

    // магазин, рисуване, желания, тоалетна
    var shopPanel: NSPanel?
    var drawPanel: NSPanel?
    var drawView: DrawLayer?
    var toolbarPanel: NSPanel?
    var drawing = false
    var drawTool = DrawTool.marker
    var drawColor = 0x2b2b3a
    var drawCells: [Int: Int] = [:]
    var newCellsThisSession = 0
    var fallSpeed: CGFloat = 0
    var want: Want?
    var wantSince: Double = 0
    var lastWantNag: Double = 0
    var nextWant: Double = 6 * 60
    var nextIdleLine: Double = 3 * 60
    var toiletPhase = ToiletPhase.off
    var toiletTarget: CGFloat = 0
    var toiletStart: Double = 0
    var toiletPoop = false
    var nextToilet: Double = 12 * 60
    var messes: [MessPixel] = []

    var videoLength: Double { pet.owned.contains("fastedit") ? 20 * 60 : 30 * 60 }
    var coinMultiplier: Int { pet.owned.contains("monitor2") ? 2 : 1 }

    var busyMoving: Bool { rolling || fetchPhase == .running || fetchPhase == .returning || toiletPhase != .off }

    // обновяване
    static let updateRepo = "vaskomontiorsundayhabit-dot/tamagotchi"
    let currentBuild = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0
    var availableBuild = 0
    var availableURL: URL?
    var checkingUpdate = false
    var updating = false
    var nextUpdateCheck: Double = 15

    var wander: Bool {
        get { UserDefaults.standard.object(forKey: "wander") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "wander") }
    }

    var foodPixelsOn: Bool {
        get { UserDefaults.standard.object(forKey: "foodPixels") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "foodPixels") }
    }

    var actionProgress: Double {
        action == .none ? 0 : min(1, (time - actionStart) / actionLength)
    }

    // --- старт ---

    func applicationDidFinishLaunching(_ notification: Notification) {
        load()
        loadDrawing()
        setUpDrawLayer()

        window = overlayPanel(NSRect(origin: .zero, size: PetView.size), key: false)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        view = PetView(frame: NSRect(origin: .zero, size: PetView.size))
        view.game = self
        window.contentView = view

        let d = UserDefaults.standard
        if d.object(forKey: "winX") != nil {
            window.setFrameOrigin(NSPoint(x: d.double(forKey: "winX"), y: d.double(forKey: "winY")))
            keepOnScreen()
        } else {
            callHome()
        }
        if d.object(forKey: "hidden") as? Bool != true { window.orderFrontRegardless() }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = statusIcon(body: bodyYellow)
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let timer = Timer(timeInterval: 1.0 / 30, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)

        say(pet.dead ? "…" : "Здрасти, аз съм \(pet.name)!", seconds: 3)
    }

    func applicationWillTerminate(_ notification: Notification) { save() }

    // --- цикъл ---

    @objc func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTick)
        lastTick = now

        let workingBefore = pet.working
        // Мак-ът е спал → броим го като „офлайн“ време
        if dt > 30 { pet.tick(min(dt, 8 * 3600) * 0.3, offline: true) } else { pet.tick(dt) }
        let step = min(dt, 0.5)
        time += step

        while pet.workSeconds >= videoLength {
            pet.workSeconds -= videoLength
            pet.videos += 1
            let coins = 25 * coinMultiplier
            earnCoins(coins)
            say("Готово видео №\(pet.videos)! +40 опит, +\(coins) монети", seconds: 4)
            addXP(40)
        }
        if pet.working {
            pet.workCoinSeconds += step
            while pet.workCoinSeconds >= 60 { pet.workCoinSeconds -= 60; earnCoins(coinMultiplier) }
        }
        if workingBefore && !pet.working && !pet.asleep && !pet.dead {
            say("Стига толкова, капнах…", seconds: 3)
        }

        if action != .none && time - actionStart >= actionLength { action = .none }
        if bubbleText != nil && time > bubbleUntil { bubbleText = nil }

        updateMood(step)

        if time > nextBlink {
            blinkUntil = time + 0.15
            nextBlink = time + Double.random(in: 2.5...6)
        }

        if pet.working && time > nextWorkLine {
            nextWorkLine = time + Double.random(in: 60...150)
            if bubbleText == nil { say(pick(editingLines, avoiding: &lastLine), seconds: 4) }
        }

        if time > nextNag {
            nextNag = time + Double.random(in: 25...45)
            if let need = currentNeed() { say(need, seconds: 4) }
        }

        if foodPixelsOn && time > nextFoodSpawn {
            nextFoodSpawn = time + (pet.owned.contains("magnet") ? Double.random(in: 60...150) : Double.random(in: 2 * 60...5 * 60))
            if foods.count < 10 { spawnFood() }
        }
        for f in foods { f.view.needsDisplay = true }

        updateRoll(step)
        updateFetch(step)
        updateWalk(step)
        updateLife(step)
        applyGravity(step)
        updateMouse()
        updateRetro()
        alertView?.needsDisplay = true
        clipView?.needsDisplay = true
        if let c = clipView, time - c.started > ClipView.length + 15 { closeClip() }
        shopPanel?.contentView?.needsDisplay = true
        if let a = alertView, time - a.started > 6 { closeAlert() }

        if time - lastSave > 30 { save() }
        if time > nextUpdateCheck {
            nextUpdateCheck = time + 6 * 3600
            checkForUpdate(manual: false)
        }
        view.needsDisplay = true
    }

    /// Ядосване, гличове, голямото съобщение и търкалянето.
    func updateMood(_ step: Double) {
        let m = step / 60
        let hungry = pet.fullness < 20, sleepy = pet.energy < 15 && !pet.asleep
        if !pet.dead && (hungry || sleepy) { anger += 1.5 * m } else { anger -= 3 * m }
        anger = anger.clamped()

        if time > nextGlitch && !pet.dead {
            glitchUntil = time + Double.random(in: 0.2...0.6)
            if anger > 60 { nextGlitch = time + Double.random(in: 3...8) }
            else if anger > 30 { nextGlitch = time + Double.random(in: 15...40) }
            else { nextGlitch = time + Double.random(in: 60...180) }
        }

        if !pet.dead && (hungry || sleepy) && time > nextBigAlert && catchPanel == nil && alertPanel == nil {
            nextBigAlert = time + 20 * 60
            anger = (anger + 10).clamped()
            showAlert(hungry ? "ГЛАДЕН СЪМ!" : "ИСКА МИ СЕ ДА СПЯ!",
                      hungry ? "ДАЙ МИ ПИКСЕЛИ! ВЕДНАГА!" : "ПРИСПИ МЕ, ЧЕ ЩЕ ГЛИЧНА!")
        }

        if time > nextRoll {
            nextRoll = time + Double.random(in: 20 * 60...40 * 60)
            if !pet.dead && !pet.asleep && !pet.working && anger < 40 && fetchPhase == .off && !isDragging { startRoll() }
        }
    }

    /// Прозорецът пропуска кликовете навсякъде, освен върху самия Пиксчо.
    func updateMouse() {
        let inside = window.isVisible && petScreenRect().contains(NSEvent.mouseLocation)
        if !isDragging && window.ignoresMouseEvents == inside { window.ignoresMouseEvents = !inside }
        if view.hovering != inside { view.hovering = inside }
    }

    func petScreenRect() -> NSRect {
        let r = view.spriteRect
        let wf = window.frame
        return NSRect(x: wf.minX + r.minX, y: wf.maxY - r.maxY, width: r.width, height: r.height)
    }

    func color(_ c: Character) -> NSColor? {
        switch c {
        case "K": return NSColor(hex: 0x2b2b3a)
        case "B", "D", "L", "A":
            if pet.dead { return NSColor(hex: c == "D" ? 0xc8c8d8 : 0xe8e8f0, alpha: 0.85) }
            var body = NSColor(hex: bodyYellow)
            if pet.health < 40 { body = body.blended(withFraction: 0.6, of: NSColor(hex: 0xb5c49a)) ?? body }
            if action == .angry || anger > 60 { body = body.blended(withFraction: 0.35, of: NSColor(hex: 0xe63946)) ?? body }
            if c == "D" { return body.blended(withFraction: 0.22, of: .black) ?? body }
            if c == "A" { return body.blended(withFraction: 0.08, of: .black) ?? body }
            if c == "L" { return body.blended(withFraction: 0.45, of: .white) ?? body }
            return body
        case "W": return .white
        case "P": return NSColor(hex: 0xff8fab)
        case "R": return NSColor(hex: 0xe63946)
        case "T": return NSColor(hex: 0x5dade2)
        case "G": return NSColor(hex: 0x52b788)
        case "Y": return NSColor(hex: 0xffd166)
        case "N": return NSColor(hex: 0x3d5a80)
        case "O": return NSColor(hex: 0xf4a261)
        case "S": return NSColor(hex: 0x1b1b24)
        case "E": return NSColor(hex: 0x8d99ae)
        case "C": return NSColor(hex: 0x48cae4)
        case "M": return NSColor(hex: 0xc77dff)
        case "Q": return NSColor(hex: 0x8b5a2b)
        case "U": return NSColor(hex: 0x5c3a1e)
        default: return nil
        }
    }

    func currentNeed() -> String? {
        if pet.dead || pet.asleep { return nil }
        if pet.health < 40 { return "Не ми е добре…" }
        if pet.fullness < 25 { return "Гладен съм! Дай пиксел!" }
        if pet.energy < 20 { return "Уморен съм…" }
        if pet.working { return nil }
        if pet.work < 25 { return "Трябва да монтирам! Клиентът чака!" }
        if pet.fun < 25 { return "Скучно ми е…" }
        return nil
    }

    func currentFace() -> Face {
        if pet.dead { return .dead }
        if pet.asleep { return action == .angry ? .angry : .sleep }
        switch action {
        case .eat: return Int(time * 5) % 2 == 0 ? .eatOpen : .eatShut
        case .love, .pill, .levelUp: return .happy
        case .angry: return .angry
        case .none: break
        }
        if isDragging || rolling || fetchPhase == .running { return .happy }
        if toiletPhase == .doing { return .focus }
        if anger > 60 { return .angry }
        if pet.health < 40 { return .sick }
        if pet.working { return time < blinkUntil ? .blink : .focus }
        if pet.fullness < 25 || pet.fun < 25 { return .sad }
        return time < blinkUntil ? .blink : .normal
    }

    // --- движение ---

    func updateWalk(_ step: Double) {
        guard wander, !busyMoving, !drawing, !pet.dead, !pet.asleep, !pet.working, !isDragging, action == .none,
              let screen = window.screen ?? NSScreen.main else {
            if !busyMoving { walking = false }
            return
        }
        let vf = screen.visibleFrame
        var origin = window.frame.origin
        guard let target = walkTarget else {
            walking = false
            if Double.random(in: 0..<1) < 0.06 * step {
                let t = origin.x + CGFloat.random(in: -220...220)
                walkTarget = min(max(t, vf.minX), vf.maxX - PetView.size.width)
            }
            return
        }
        let speed = CGFloat(18 * step)
        if abs(target - origin.x) <= speed {
            walkTarget = nil
            walking = false
            saveWindowPosition()
            return
        }
        walking = true
        facingLeft = target < origin.x
        origin.x += facingLeft ? -speed : speed
        window.setFrameOrigin(origin)
    }

    /// Премества прозореца към дадена точка; връща true, когато стигне.
    func moveWindow(toward target: NSPoint, speed: CGFloat) -> Bool {
        var o = window.frame.origin
        let dx = target.x - o.x, dy = target.y - o.y
        let dist = sqrt(dx * dx + dy * dy)
        if dist <= speed { window.setFrameOrigin(target); return true }
        o.x += dx / dist * speed
        o.y += dy / dist * speed
        if abs(dx) > 2 { facingLeft = dx < 0 }
        window.setFrameOrigin(o)
        return false
    }

    func startRoll() {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
        let x = window.frame.minX
        let leftSide = x - vf.minX > vf.maxX - x
        rollTarget = leftSide ? vf.minX + 20 : vf.maxX - PetView.size.width - 20
        rolling = true
        walkTarget = nil
        say("Уиииии!", seconds: 2)
    }

    func updateRoll(_ step: Double) {
        guard rolling else { return }
        let speed = CGFloat(380 * step)
        let o = window.frame.origin
        let dir: CGFloat = rollTarget < o.x ? -1 : 1
        let radius = CGFloat(pet.cellsAcross * cellSize + 2) * PetView.scale / 2
        rollAngle -= dir * speed / radius
        if moveWindow(toward: NSPoint(x: rollTarget, y: o.y), speed: speed) {
            rolling = false
            rollAngle = 0
            saveWindowPosition()
            say("Леле, завъртях се…", seconds: 2.5)
        }
    }

    func keepOnScreen() {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let vf = screen.visibleFrame
        var o = window.frame.origin
        o.x = min(max(o.x, vf.minX - 20), vf.maxX - PetView.size.width + 20)
        o.y = min(max(o.y, vf.minY - 10), vf.maxY - PetView.size.height)
        window.setFrameOrigin(o)
    }

    // --- действия ---

    func start(_ a: Action, length: Double = 2.5) {
        action = a
        actionStart = time
        actionLength = length
        walkTarget = nil
    }

    func say(_ text: String, seconds: Double = 2.5) {
        bubbleText = text
        bubbleUntil = time + seconds
    }

    func addXP(_ amount: Int) {
        guard !pet.dead, amount > 0 else { return }
        pet.xp += amount
        var leveled = false
        while pet.xp >= pet.xpNeeded {
            pet.xp -= pet.xpNeeded
            pet.level += 1
            leveled = true
        }
        if leveled {
            start(.levelUp, length: 2.5)
            say(pet.level <= 12 ? "НИВО \(pet.level)! Пораснах!" : "НИВО \(pet.level)!", seconds: 3.5)
        }
        save()
    }

    func annoy(_ amount: Double) { anger = (anger + amount).clamped() }

    func finishedDrag() {
        walkTarget = nil
        keepOnScreen()
        saveWindowPosition()
    }

    /// Клик: работи → смешна реплика, спи → сърди се, иначе → кефи се. Много кликове → ядосва се.
    func petIt() {
        if pet.dead { say("…", seconds: 1.5); return }
        clickTimes.append(time)
        clickTimes.removeAll { time - $0 > 3 }
        if pet.asleep {
            pet.fun = (pet.fun - 2).clamped()
            annoy(20)
            start(.angry, length: 2)
            glitchUntil = time + 0.5
            say(pick(angryLines, avoiding: &lastLine), seconds: 2.5)
            return
        }
        if clickTimes.count >= 6 {
            annoy(15)
            clickTimes.removeAll()
            start(.angry, length: 2)
            glitchUntil = time + 0.6
            say(pick(annoyedLines, avoiding: &lastLine), seconds: 2.5)
            return
        }
        if pet.working {
            say(pick(editingLines, avoiding: &lastLine), seconds: 4)
            nextWorkLine = time + Double.random(in: 60...150)
            return
        }
        pet.fun = (pet.fun + 4).clamped()
        anger = (anger - 3).clamped()
        start(.love, length: 1.6)
        say(pick(happyLines, avoiding: &lastLine), seconds: 1.8)
        fulfill(.pet)
    }

    @discardableResult
    func eat(color: Int) -> Bool {
        if pet.fullness >= 90 {
            start(.angry, length: 1.2)
            say(["Не мога повече! Преядох!", "Не! Пълен съм!", "Махни това, ще се пръсна!"].randomElement()!, seconds: 2.5)
            return false
        }
        say(pick(eatLines, avoiding: &lastLine), seconds: 2)
        pet.fullness = (pet.fullness + 15).clamped()
        anger = (anger - 10).clamped()
        lastFoodColor = color
        start(.eat, length: 1.6)
        addXP(5)
        fulfill(.color(color))
        return true
    }

    @objc func feed() {
        guard checkAwake() else { return }
        eat(color: foodColors.randomElement()!)
    }

    // пиксели по екрана

    @objc func spawnFood() { spawnFood(color: foodColors.randomElement()!) }

    func spawnFood(color: Int) {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
        let origin = NSPoint(x: CGFloat.random(in: (vf.minX + 40)...(vf.maxX - 70)),
                             y: CGFloat.random(in: (vf.minY + 40)...(vf.maxY - 70)))
        foods.append(FoodPixel(color: color, at: origin, game: self))
    }

    func foodDropped(_ food: FoodPixel) {
        let f = food.panel.frame
        let center = NSPoint(x: f.midX, y: f.midY)
        if window.isVisible && petScreenRect().insetBy(dx: -14, dy: -14).contains(center) {
            if pet.dead { say("…", seconds: 1.5); return }
            if pet.asleep { say("Zzz… (спи)", seconds: 2); return }
            if eat(color: food.color) {
                food.remove()
                foods.removeAll { $0 === food }
            } else {
                food.panel.setFrameOrigin(NSPoint(x: f.minX + (f.midX > petScreenRect().midX ? 70 : -70), y: f.minY + 30))
            }
            return
        }
        if let vf = food.panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            var o = f.origin
            o.x = min(max(o.x, vf.minX), vf.maxX - f.width)
            o.y = min(max(o.y, vf.minY), vf.maxY - f.height)
            food.panel.setFrameOrigin(o)
        }
    }

    @objc func toggleFoodPixels() {
        foodPixelsOn.toggle()
        if foodPixelsOn {
            nextFoodSpawn = time + 20
        } else {
            foods.forEach { $0.remove() }
            foods.removeAll()
        }
    }

    // работа

    @objc func toggleWork() {
        guard checkAwake() else { return }
        if pet.working {
            pet.working = false
            say("Пауза за кафе!", seconds: 2)
        } else {
            if pet.energy < 15 { say("Нямам сили да монтирам…", seconds: 2.5); return }
            endFetch()
            pet.working = true
            walkTarget = nil
            nextWorkLine = time + Double.random(in: 20...50)
            say("Отварям таймлайна…", seconds: 2.5)
            fulfill(.work)
        }
        save()
    }

    // игра: пиксели от небето

    @objc func startCatch() {
        guard checkAwake() else { return }
        if catchPanel != nil { return }
        if pet.energy < 15 { say("Нямам сили…", seconds: 2.5); return }
        guard let screen = window.screen ?? NSScreen.main else { return }
        endFetch()
        pet.working = false
        let p = overlayPanel(screen.frame, key: true)
        let v = CatchView(frame: NSRect(origin: .zero, size: screen.frame.size))
        v.game = self
        v.best = UserDefaults.standard.integer(forKey: "catchBest")
        p.contentView = v
        catchPanel = p
        catchView = v
        window.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)
        p.makeFirstResponder(v)
        v.start()
    }

    func closeCatch() {
        guard let p = catchPanel, let v = catchView else { return }
        v.stop()
        p.orderOut(nil)
        catchPanel = nil
        catchView = nil
        if UserDefaults.standard.object(forKey: "hidden") as? Bool != true { window.orderFrontRegardless() }
        let oldBest = UserDefaults.standard.integer(forKey: "catchBest")
        let best = max(v.best, v.score)
        let record = best > oldBest
        if record { UserDefaults.standard.set(best, forKey: "catchBest") }
        pet.fun = (pet.fun + min(40, 10 + Double(v.score))).clamped()
        pet.energy = (pet.energy - min(15, 3 + Double(v.score) / 5)).clamped()
        anger = (anger - 20).clamped()
        start(.love, length: 1.6)
        say(record ? "Нов рекорд: \(best)! +\(v.score + 25) опит" : "\(v.score) точки! +\(v.score) опит", seconds: 3.5)
        earnCoins(v.score / 2 + (record ? 10 : 0))
        addXP(v.score + (record ? 25 : 0))
        fulfill(.play)
    }

    // игра: донеси

    @objc func toggleFetch() {
        if fetchPhase != .off { endFetch(); return }
        guard checkAwake() else { return }
        pet.working = false
        let r = petScreenRect()
        fetchHome = window.frame.origin
        ball = BallPixel(at: NSPoint(x: r.maxX + 4, y: r.minY), game: self)
        fetchPhase = .waiting
        fetchIdleSince = time
        walkTarget = nil
        say("Хвърли топчето!", seconds: 3)
    }

    func endFetch() {
        ball?.remove()
        ball = nil
        if fetchPhase != .off { walking = false; saveWindowPosition() }
        fetchPhase = .off
    }

    func ballThrown() {
        fetchIdleSince = time
        if fetchPhase == .waiting { fetchHome = window.frame.origin }
    }

    func ballLanded(_ b: BallPixel) {
        guard b === ball, b.thrown, fetchPhase == .waiting else { return }
        fetchPhase = .running
        say("Отивам!", seconds: 1.5)
    }

    func updateFetch(_ step: Double) {
        guard let ball else { return }
        let r = petScreenRect()
        switch fetchPhase {
        case .off:
            break
        case .waiting:
            walking = false
            if time - fetchIdleSince > 120 && !ball.flying {
                endFetch()
                say("Добре, стига игра.", seconds: 2.5)
            }
        case .running:
            walking = true
            let bf = ball.panel.frame
            let anchor = NSPoint(x: r.midX - window.frame.minX, y: r.minY - window.frame.minY)
            let target = NSPoint(x: bf.midX - anchor.x, y: bf.minY - anchor.y)
            if moveWindow(toward: target, speed: CGFloat(420 * step)) && !ball.flying {
                ball.stop()
                ball.carried = true
                fetchPhase = .returning
            }
        case .returning:
            walking = true
            let arrived = moveWindow(toward: fetchHome, speed: CGFloat(300 * step))
            let pr = petScreenRect()
            ball.panel.setFrameOrigin(NSPoint(x: facingLeft ? pr.minX - 10 : pr.maxX - 12, y: pr.minY + pr.height * 0.3))
            if arrived {
                walking = false
                ball.carried = false
                ball.launch(.zero, thrown: false)
                fetchPhase = .waiting
                fetchIdleSince = time
                pet.fun = (pet.fun + 6).clamped()
                pet.energy = (pet.energy - 1.5).clamped()
                anger = (anger - 5).clamped()
                start(.love, length: 1.2)
                say(pick(fetchLines, avoiding: &lastLine) + " +3 опит", seconds: 2.5)
                earnCoins(1)
                fulfill(.play)
                addXP(3)
            }
        }
    }

    // клипове на монитора

    func playClip() {
        closeClip()
        var n = Int.random(in: 0..<clipTitles.count)
        while n == lastClip { n = Int.random(in: 0..<clipTitles.count) }
        lastClip = n
        let v = ClipView(frame: NSRect(x: 0, y: 0, width: ClipView.size.width, height: ClipView.size.height))
        v.game = self
        v.clip = n
        v.started = time
        let mr = view.monitorRect
        let wf = window.frame
        let monScreen = NSRect(x: wf.minX + mr.minX, y: wf.maxY - mr.maxY, width: mr.width, height: mr.height)
        let vf = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        var o = NSPoint(x: monScreen.midX - ClipView.size.width / 2, y: monScreen.maxY + 10)
        o.x = min(max(o.x, vf.minX + 4), vf.maxX - ClipView.size.width - 4)
        o.y = min(max(o.y, vf.minY + 4), vf.maxY - ClipView.size.height - 4)
        let p = overlayPanel(NSRect(origin: o, size: ClipView.size), key: false)
        p.contentView = v
        p.orderFrontRegardless()
        clipPanel = p
        clipView = v
        say("Виж какво монтирах!", seconds: 2)
    }

    func clipAnswer(_ liked: Bool) {
        closeClip()
        if liked {
            earnCoins(3)
            anger = (anger - 5).clamped()
            start(.love, length: 1.6)
            say(pick(clipLikeLines, avoiding: &lastLine) + " +3 монети", seconds: 3)
        } else {
            annoy(25)
            start(.angry, length: 2.5)
            glitchUntil = time + 0.7
            say(pick(clipDislikeLines, avoiding: &lastLine), seconds: 3.5)
        }
    }

    func closeClip() {
        clipPanel?.orderOut(nil)
        clipPanel = nil
        clipView = nil
    }

    // съобщение на целия екран

    func showAlert(_ title: String, _ subtitle: String) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let p = overlayPanel(screen.frame, key: false)
        let v = AlertView(frame: NSRect(origin: .zero, size: screen.frame.size))
        v.game = self
        v.title = title
        v.subtitle = subtitle
        v.started = time
        p.contentView = v
        p.orderFrontRegardless()
        alertPanel = p
        alertView = v
    }

    func closeAlert() {
        alertPanel?.orderOut(nil)
        alertPanel = nil
        alertView = nil
    }

    // ретро менюто

    @objc func openRetro() {
        closeRetro()
        let v = RetroView(frame: NSRect(x: 0, y: 0, width: RetroView.width, height: RetroView.height))
        v.game = self
        let asleep = pet.asleep, dead = pet.dead
        v.stats = [
            RetroButton(icon: iconFood, label: "Ситост", value: pet.fullness, action: nil),
            RetroButton(icon: iconFun, label: "Радост", value: pet.fun, action: nil),
            RetroButton(icon: iconEnergy, label: "Енергия", value: pet.energy, action: nil),
            RetroButton(icon: iconWork, label: "Работа", value: pet.work, action: nil),
            RetroButton(icon: iconHealth, label: "Здраве", value: pet.health, action: nil),
        ]
        if dead {
            v.actions = [RetroButton(icon: iconSun, label: "Ново животинче", value: nil, action: #selector(newPet))]
        } else {
            v.actions = [
                RetroButton(icon: iconFood, label: "Нахрани", value: nil, action: asleep ? nil : #selector(feed)),
                RetroButton(icon: pet.working ? iconPause : iconMonitor, label: pet.working ? "Спри работа" : "Работи",
                            value: nil, action: asleep ? nil : #selector(toggleWork)),
                RetroButton(icon: iconSky, label: "Игра: пиксели от небето", value: nil, action: asleep ? nil : #selector(startCatch)),
                RetroButton(icon: iconBall, label: fetchPhase == .off ? "Игра: донеси" : "Спри „донеси“",
                            value: nil, action: asleep ? nil : #selector(toggleFetch)),
                RetroButton(icon: asleep ? iconSun : iconMoon, label: asleep ? "Събуди" : "Приспи", value: nil, action: #selector(toggleSleep)),
                RetroButton(icon: iconPill, label: "Лекарство", value: nil, action: asleep ? nil : #selector(medicine)),
                RetroButton(icon: iconShop, label: "Магазин", value: nil, action: #selector(openShop)),
                RetroButton(icon: iconPencil, label: "Рисувай платформи", value: nil, action: #selector(startDrawing)),
            ]
        }
        let pr = petScreenRect()
        let vf = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        var o = NSPoint(x: pr.midX - RetroView.width / 2, y: pr.maxY + 6)
        if o.y + RetroView.height > vf.maxY { o.y = pr.minY - RetroView.height - 6 }
        o.x = min(max(o.x, vf.minX + 4), vf.maxX - RetroView.width - 4)
        o.y = min(max(o.y, vf.minY + 4), vf.maxY - RetroView.height - 4)
        let p = overlayPanel(NSRect(origin: o, size: v.frame.size), key: false)
        p.contentView = v
        p.acceptsMouseMovedEvents = true
        p.orderFrontRegardless()
        retroPanel = p
        retroLastInside = time
    }

    func closeRetro() {
        retroPanel?.orderOut(nil)
        retroPanel = nil
    }

    /// Затваря ретро менюто, когато мишката стои извън него.
    func updateRetro() {
        guard let p = retroPanel else { return }
        // клик някъде отстрани го затваря (без горната лента, там е иконката)
        let m = NSEvent.mouseLocation
        let inMenuBar = m.y > (NSScreen.main?.visibleFrame.maxY ?? .greatestFiniteMagnitude)
        let inside = p.frame.contains(m) || petScreenRect().contains(m)
        if NSEvent.pressedMouseButtons != 0 && !inside && !inMenuBar && time - retroLastInside > 0.3 {
            closeRetro()
            return
        }
        p.contentView?.needsDisplay = true
    }

    @objc func medicine() {
        guard checkAwake() else { return }
        if pet.health > 80 { say("Не съм болен!", seconds: 2); return }
        pet.health = (pet.health + 35).clamped()
        start(.pill, length: 1.6)
        say("Бляк… но помага", seconds: 2.5)
        save()
    }

    @objc func toggleSleep() {
        if pet.dead { return }
        endFetch()
        pet.asleep.toggle()
        pet.working = false
        action = .none
        say(pet.asleep ? "Лека нощ…" : "Добро утро!", seconds: 2)
        save()
    }

    func checkAwake() -> Bool {
        if pet.dead { say("…", seconds: 1.5); return false }
        if pet.asleep { say("Zzz… (спи)", seconds: 2); return false }
        return true
    }

    // --- иконката в горната лента ---

    @objc func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = adminMenu()
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            if !window.isVisible { toggleWindow() }
            if retroPanel == nil { openRetro() } else { closeRetro() }
        }
    }

    func adminMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        func item(_ title: String, _ sel: Selector?, on: Bool = false, enabled: Bool = true) {
            let it = NSMenuItem(title: title, action: sel, keyEquivalent: "")
            it.target = self
            it.state = on ? .on : .off
            it.isEnabled = enabled && sel != nil
            menu.addItem(it)
        }
        if availableBuild > currentBuild {
            item("Обнови до версия \(availableBuild)", updating ? nil : #selector(installUpdate))
            menu.addItem(.separator())
        }
        item("\(pet.name) · ниво \(pet.level) · опит \(pet.xp)/\(pet.xpNeeded) · видеа \(pet.videos)", nil)
        item("Монети: \(pet.coins)", nil)
        if let w = want { item("Иска: \(wantText(w))", nil) }
        menu.addItem(.separator())
        item("Магазин…", #selector(openShop))
        item(drawing ? "Спри рисуването" : "Рисувай с пиксели (платформи)", drawing ? #selector(stopDrawingAction) : #selector(startDrawing))
        item("Изтрий всичко нарисувано", #selector(clearDrawingAction), enabled: !drawCells.isEmpty)
        menu.addItem(.separator())
        item(window.isVisible ? "Скрий" : "Покажи", #selector(toggleWindow))
        item("Повикай в ъгъла", #selector(callHome))
        item("Разхожда се", #selector(toggleWander), on: wander)
        item("Пиксели-храна по екрана", #selector(toggleFoodPixels), on: foodPixelsOn)
        if foodPixelsOn { item("Пусни пиксел сега", #selector(spawnFood), enabled: foods.count < 12) }
        item("Смени името…", #selector(rename))
        if #available(macOS 13.0, *) {
            item("Пускай при включване", #selector(toggleLogin), on: SMAppService.mainApp.status == .enabled)
        }
        if !pet.dead { item("Ново животинче…", #selector(newPet)) }
        menu.addItem(.separator())
        item("Версия \(currentBuild) · Провери за обновления", #selector(checkForUpdateManually))
        item("Изход", #selector(quit))
        return menu
    }

    @objc func toggleWindow() {
        if window.isVisible { window.orderOut(nil); closeRetro() } else { window.orderFrontRegardless() }
        UserDefaults.standard.set(!window.isVisible, forKey: "hidden")
    }

    @objc func toggleWander() { wander.toggle(); walkTarget = nil }
    @objc func stopDrawingAction() { stopDrawing() }
    @objc func clearDrawingAction() { clearDrawing() }

    @objc func callHome() {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
        endFetch()
        rolling = false
        window.setFrameOrigin(NSPoint(x: vf.maxX - PetView.size.width - 20, y: vf.minY - 6))
        window.orderFrontRegardless()
        UserDefaults.standard.set(false, forKey: "hidden")
        saveWindowPosition()
    }

    @objc func rename() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Как да се казва?"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.stringValue = pet.name
        alert.accessoryView = field
        alert.addButton(withTitle: "Готово")
        alert.addButton(withTitle: "Отказ")
        alert.window.initialFirstResponder = field
        if alert.runModal() == .alertFirstButtonReturn {
            let name = field.stringValue.trimmingCharacters(in: .whitespaces)
            if !name.isEmpty { pet.name = name; save(); say("Аз съм \(name)!", seconds: 2.5) }
        }
    }

    @objc func newPet() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = pet.dead ? "Ново животинче?" : "Наистина ли ново животинче?"
        alert.informativeText = pet.dead ? "" : "\(pet.name) ще си отиде завинаги."
        alert.addButton(withTitle: "Да, ново")
        alert.addButton(withTitle: "Отказ")
        if alert.runModal() == .alertFirstButtonReturn {
            pet = Pet()
            anger = 0
            say("Здрасти, аз съм \(pet.name)!", seconds: 3)
            save()
        }
    }

    @objc func toggleLogin() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Не успях да променя автоматичното пускане"
            alert.informativeText = "Сложи приложението в папка Applications и опитай пак.\n\n\(error.localizedDescription)"
            alert.runModal()
        }
    }

    @objc func quit() { save(); NSApp.terminate(nil) }


    // --- обновяване ---

    @objc func checkForUpdateManually() { checkForUpdate(manual: true) }

    func checkForUpdate(manual: Bool) {
        if checkingUpdate || updating { return }
        checkingUpdate = true
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(Game.updateRepo)/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        URLSession.shared.dataTask(with: req) { data, _, _ in
            var build = 0
            var url: URL?
            if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let tag = json["tag_name"] as? String ?? ""
                build = Int(tag.filter { $0.isNumber }) ?? 0
                let assets = json["assets"] as? [[String: Any]] ?? []
                if let link = assets.first(where: { $0["name"] as? String == "Tamagotchi.zip" })?["browser_download_url"] as? String {
                    url = URL(string: link)
                }
            }
            let failed = data == nil
            let (b, u) = (build, url)
            DispatchQueue.main.async {
                self.updateChecked(build: b, url: u, failed: failed, manual: manual)
            }
        }.resume()
    }

    func updateChecked(build: Int, url: URL?, failed: Bool, manual: Bool) {
        checkingUpdate = false
        if build > currentBuild, let url {
            let isNew = build != availableBuild
            availableBuild = build
            availableURL = url
            if manual {
                NSApp.activate(ignoringOtherApps: true)
                let alert = NSAlert()
                alert.messageText = "Има нова версия (\(build))"
                alert.informativeText = "Сега си на версия \(currentBuild). Да се обнови ли?"
                alert.addButton(withTitle: "Обнови")
                alert.addButton(withTitle: "По-късно")
                if alert.runModal() == .alertFirstButtonReturn { installUpdate() }
            } else if isNew {
                say("Има обновление!", seconds: 5)
            }
        } else if manual {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = failed ? "Не успях да проверя" : "Имаш последната версия"
            alert.informativeText = failed ? "Провери дали има интернет." : "Версия \(currentBuild)"
            alert.runModal()
        }
    }

    @objc func installUpdate() {
        guard let url = availableURL, !updating else { return }
        // Ако macOS пуска приложението от скрито временно копие (App Translocation),
        // новата версия отива направо в Applications.
        var target = Bundle.main.bundleURL
        if target.path.contains("/AppTranslocation/") {
            target = URL(fileURLWithPath: "/Applications/Tamagotchi.app")
        }
        updating = true
        say("Обновявам се…", seconds: 60)
        URLSession.shared.downloadTask(with: url) { tmp, _, _ in
            // временният файл изчезва след края на тази функция, затова се разархивира веднага
            var newApp: URL?
            if let tmp {
                let fm = FileManager.default
                let dir = fm.temporaryDirectory.appendingPathComponent("tamagotchi-\(UUID().uuidString)")
                let zip = dir.appendingPathComponent("update.zip")
                do {
                    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                    try fm.moveItem(at: tmp, to: zip)
                    let unzip = Process()
                    unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                    unzip.arguments = ["-x", "-k", zip.path, dir.path]
                    try unzip.run()
                    unzip.waitUntilExit()
                    let app = dir.appendingPathComponent("Tamagotchi.app")
                    if unzip.terminationStatus == 0 && fm.fileExists(atPath: app.path) { newApp = app }
                } catch {}
            }
            let result = newApp
            DispatchQueue.main.async { self.finishUpdate(result, replacing: target) }
        }.resume()
    }

    func finishUpdate(_ newApp: URL?, replacing target: URL) {
        guard let newApp else {
            updating = false
            say("Не успях да се обновя", seconds: 4)
            return
        }
        save()
        saveWindowPosition()
        // скрипт, който чака това копие да спре, сменя приложението и го пуска отново
        let q = { (s: String) in "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }
        let script = """
        while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.2; done
        rm -rf \(q(target.path))
        mv \(q(newApp.path)) \(q(target.path))
        xattr -dr com.apple.quarantine \(q(target.path)) 2>/dev/null
        open \(q(target.path))
        """
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", script]
        do {
            try p.run()
            NSApp.terminate(nil)
        } catch {
            updating = false
            say("Не успях да се обновя", seconds: 4)
        }
    }




    // --- запазване ---

    func save() {
        pet.lastUpdate = Date()
        if let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: "pet")
        }
        lastSave = time
    }

    func load() {
        let d = UserDefaults.standard
        guard let data = d.data(forKey: "pet"),
              let saved = try? JSONDecoder().decode(Pet.self, from: data) else { return }
        pet = saved
        if pet.name == "Пикси" { pet.name = "Пиксчо" }
        let away = Date().timeIntervalSince(pet.lastUpdate)
        pet.tick(min(away, 8 * 3600) * 0.3, offline: true)
    }

    func saveWindowPosition() {
        let o = window.frame.origin
        UserDefaults.standard.set(Double(o.x), forKey: "winX")
        UserDefaults.standard.set(Double(o.y), forKey: "winY")
    }
}

// MARK: - main

let app = NSApplication.shared
let game = Game()
app.delegate = game
app.setActivationPolicy(.accessory)
app.run()
