// Пиксчо — пикселно тамагочи, което живее на екрана на Мак-а.
// Само по себе си е пиксел с лице и крайници и всеки ден става с един пиксел по-голямо.
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

// MARK: - Облик (цвят и аксесоари)

struct Accessory {
    let name: String
    let grid: Grid
}

// N = тъмносиньо, O = оранжево
let hats: [String: Accessory] = [
    "crown": Accessory(name: "👑 Корона", grid: grid([
        "Y..YY..Y",
        "YY.YY.YY",
        "YYYYYYYY",
        "YRYYYYTY",
    ])),
    "party": Accessory(name: "🥳 Парти шапка", grid: grid([
        "..YY..",
        "..RR..",
        ".RYYR.",
        ".RRRR.",
        "RYYYYR",
    ])),
    "beanie": Accessory(name: "🧢 Зимна шапка", grid: grid([
        "....OO....",
        "..NNNNNN..",
        ".NNNNNNNN.",
        "OOOOOOOOOO",
    ])),
    "bow": Accessory(name: "🎀 Панделка", grid: grid([
        "PP.PP",
        "PPRPP",
        "PP.PP",
    ])),
    "flower": Accessory(name: "🌼 Цвете", grid: grid([
        ".W.",
        "WYW",
        ".W.",
    ])),
]
let faceItems: [String: String] = ["glasses": "👓 Очила", "sunglasses": "😎 Слънчеви очила"]
let neckItems: [String: String] = ["bowtie": "🎩 Папийонка", "scarf": "🧣 Шал"]
let hatOrder = ["crown", "party", "beanie", "bow", "flower"]
let faceOrder = ["glasses", "sunglasses"]
let neckOrder = ["bowtie", "scarf"]

let colorPresets: [(String, Int)] = [
    ("🌿 Мента", 0x8ed1a5),
    ("🍑 Праскова", 0xffb4a2),
    ("🩵 Небе", 0x9ad1f5),
    ("💜 Лавандула", 0xc9b6f2),
    ("🍋 Лимон", 0xfde68a),
    ("🌸 Розово", 0xffc8dd),
    ("🍫 Шоколад", 0xc49a6c),
    ("🩶 Облак", 0xd9dde3),
]

let foodColors = [0xff595e, 0xffca3a, 0x8ac926, 0x1982c4, 0x6a4c93, 0xff924c, 0x52d1dc, 0xf15bb5]

struct Look: Codable {
    var body = 0x8ed1a5
    var hat = ""
    var face = ""
    var neck = ""
}

// MARK: - Спрайт: пиксел с лице, ръце и крака

enum Face { case normal, blink, happy, sad, angry, sleep, eatOpen, eatShut, sick, dead, focus }
enum Pose { case idle, wave, walk, type, sleep }

let canvasW = 40
let canvasH = 32

struct Sprite {
    var grid: Grid
    var bx = 0, by = 0, n = 0          // вътрешността на тялото (без контура)
    var groundY = 0
    var mouthX = 0, mouthY = 0
    var minX = 0, minY = 0, maxX = 0, maxY = 0   // заетата част от платното
}

func buildSprite(n: Int, face: Face, pose: Pose, frame: Int, look: Look, working: Bool) -> Sprite {
    var g = Grid(repeating: Array(repeating: ".", count: canvasW), count: canvasH)
    let limb = n < 8 ? 2 : (n < 12 ? 3 : 4)
    let groundY = canvasH - 1
    let bottom = groundY - limb            // ред на долния контур
    let by = bottom - n                     // първи вътрешен ред
    let bx: Int
    if working {
        let total = limb + 1 + n + 1 + limb + 1 + 12
        bx = (canvasW - total) / 2 + limb + 1
    } else {
        bx = (canvasW - n) / 2
    }

    // тяло: контур, пълнеж, сянка, отблясък
    for x in (bx - 1)...(bx + n) { put(&g, x, by - 1, "K"); put(&g, x, bottom, "K") }
    for y in by..<bottom { put(&g, bx - 1, y, "K"); put(&g, bx + n, y, "K") }
    for y in by..<bottom {
        for x in bx..<(bx + n) { put(&g, x, y, (x == bx + n - 1 || y == bottom - 1) ? "D" : "B") }
    }
    if n >= 6 { put(&g, bx, by, "L"); put(&g, bx + 1, by, "L"); put(&g, bx, by + 1, "L") }

    // крака
    let legs = [bx + n / 4, bx + n - 1 - n / 4]
    for (i, lx) in legs.enumerated() {
        var len = limb
        if pose == .walk && frame % 2 == i { len -= 1 }
        for k in 1...len { put(&g, lx, bottom + k, "K") }
        put(&g, i == 0 ? lx - 1 : lx + 1, bottom + len, "K")
    }

    // ръце
    let armY = by + n / 2
    func arm(_ side: Int) {
        let startX = side < 0 ? bx - 2 : bx + n + 1
        for i in 0..<limb {
            let x = startX + side * i
            var y = armY + i
            switch pose {
            case .wave:
                y = armY - (frame % 2 == 0 ? i + 1 : i)
            case .sleep:
                y = armY + i
            case .walk:
                let swing = (frame % 2 == 0) == (side < 0)
                y = swing ? armY + i : armY
            case .type:
                if side > 0 {
                    y = armY + 1
                    if i == limb - 1 && frame % 2 == 0 { y -= 1 }
                }
            case .idle:
                break
            }
            put(&g, x, y, "K")
        }
    }
    arm(-1)
    arm(1)

    // лице
    let e = n >= 10 ? 2 : 1
    let eyeY = by + n / 3
    let look1 = face == .focus ? 1 : 0
    let lx = bx + n / 4 + look1
    let rx = bx + n - n / 4 - e + look1
    let mouthY = eyeY + e + 1
    let mw = n >= 12 ? 4 : (n >= 8 ? 2 : 1)
    let mx = bx + (n - mw) / 2

    func eyeOpen(_ x: Int) {
        for dx in 0..<e { for dy in 0..<e { put(&g, x + dx, eyeY + dy, "K") } }
        if e == 2 { put(&g, x, eyeY, "W") }
    }
    func eyeClosed(_ x: Int) {
        for dx in 0..<e { put(&g, x + dx, eyeY + e - 1, "K") }
    }
    func eyeHappy(_ x: Int) {
        put(&g, x - 1, eyeY + 1, "K")
        for dx in 0..<e { put(&g, x + dx, eyeY, "K") }
        put(&g, x + e, eyeY + 1, "K")
    }
    func mouthLine(_ w: Int) {
        let x0 = bx + (n - w) / 2
        for dx in 0..<w { put(&g, x0 + dx, mouthY, "K") }
    }
    func mouthSmile() {
        mouthLine(mw)
        if mw >= 2 { put(&g, mx - 1, mouthY - 1, "K"); put(&g, mx + mw, mouthY - 1, "K") }
    }
    func mouthFrown() {
        mouthLine(mw)
        if mw >= 2 { put(&g, mx - 1, mouthY + 1, "K"); put(&g, mx + mw, mouthY + 1, "K") }
    }
    func mouthOpen() {
        let w = max(mw, 2)
        let x0 = bx + (n - w) / 2
        for dx in 0..<w { put(&g, x0 + dx, mouthY, "K"); put(&g, x0 + dx, mouthY + 1, "R") }
    }
    func cheeks() {
        if n >= 8 { put(&g, lx - 1, eyeY + e, "P"); put(&g, rx + e, eyeY + e, "P") }
    }

    switch face {
    case .normal: eyeOpen(lx); eyeOpen(rx); mouthSmile(); cheeks()
    case .blink: eyeClosed(lx); eyeClosed(rx); mouthSmile(); cheeks()
    case .happy, .eatOpen: eyeHappy(lx); eyeHappy(rx); mouthOpen(); cheeks()
    case .eatShut: eyeHappy(lx); eyeHappy(rx); mouthLine(max(mw, 2)); cheeks()
    case .sad:
        eyeOpen(lx); eyeOpen(rx); mouthFrown()
        put(&g, lx, eyeY + e, "T")
        if n >= 8 { put(&g, lx, eyeY + e + 1, "T") }
    case .angry:
        eyeOpen(lx); eyeOpen(rx); mouthFrown()
        if n >= 8 {
            put(&g, lx - 1, eyeY - 2, "K"); put(&g, lx + e - 1, eyeY - 1, "K")
            put(&g, rx + e, eyeY - 2, "K"); put(&g, rx, eyeY - 1, "K")
        }
    case .sleep: eyeClosed(lx); eyeClosed(rx); mouthLine(1)
    case .sick:
        eyeOpen(lx); eyeOpen(rx); mouthLine(mw)
        put(&g, bx + n + 1, by - 1, "T"); put(&g, bx + n + 1, by, "T")
    case .dead: eyeClosed(lx); eyeClosed(rx); mouthLine(mw)
    case .focus: eyeOpen(lx); eyeOpen(rx); mouthLine(1)
    }

    // очила
    if !look.face.isEmpty && face != .dead {
        for x0 in [lx, rx] {
            for x in (x0 - 1)...(x0 + e) { put(&g, x, eyeY - 1, "K"); put(&g, x, eyeY + e, "K") }
            for y in eyeY..<(eyeY + e) { put(&g, x0 - 1, y, "K"); put(&g, x0 + e, y, "K") }
            if look.face == "sunglasses" {
                for x in x0..<(x0 + e) { for y in eyeY..<(eyeY + e) { put(&g, x, y, "S") } }
                if e == 2 { put(&g, x0, eyeY, "W") }
            }
        }
        if lx + e + 1 <= rx - 2 {
            for x in (lx + e + 1)...(rx - 2) { put(&g, x, eyeY, "K") }
        }
    }

    // на врата
    switch look.neck {
    case "bowtie":
        let y = mouthY + 4 <= bottom ? mouthY + 2 : bottom - 1
        stamp(&g, grid(["RR.RR", "RRKRR", "RR.RR"]), bx + n / 2 - 2, y)
    case "scarf":
        let y = min(mouthY + 2, bottom - 1)
        for x in (bx - 1)...(bx + n) { put(&g, x, y, "O") }
        for dy in 1...2 { put(&g, bx + n - 2, y + dy, "O"); put(&g, bx + n - 1, y + dy, "O") }
    default: break
    }

    // шапка
    if let hat = hats[look.hat] {
        let w = hat.grid[0].count, h = hat.grid.count
        switch look.hat {
        case "bow": stamp(&g, hat.grid, bx + n - 3, by - 2)
        case "flower": stamp(&g, hat.grid, bx + n - 2, by - 2)
        default: stamp(&g, hat.grid, bx + n / 2 - w / 2, by - h)
        }
    }

    // монитор с таймлайн, докато монтира
    if working {
        let m0 = bx + n + 1 + limb + 1
        let top = groundY - 9
        for x in m0...(m0 + 11) { put(&g, x, top, "E"); put(&g, x, top + 7, "E") }
        for y in top...(top + 7) { put(&g, m0, y, "E"); put(&g, m0 + 11, y, "E") }
        for y in (top + 1)...(top + 6) { for x in (m0 + 1)...(m0 + 10) { put(&g, x, y, "S") } }
        for x in (m0 + 1)...(m0 + 5) { put(&g, x, top + 2, "C") }
        for x in (m0 + 7)...(m0 + 9) { put(&g, x, top + 2, "M") }
        for x in (m0 + 2)...(m0 + 8) { put(&g, x, top + 4, "O") }
        for x in (m0 + 1)...(m0 + 3) { put(&g, x, top + 5, "G") }
        for x in (m0 + 5)...(m0 + 10) { put(&g, x, top + 5, "Y") }
        let head = m0 + 1 + (frame % 10)
        for y in (top + 1)...(top + 6) { put(&g, head, y, "R") }
        put(&g, m0 + 5, top + 8, "E"); put(&g, m0 + 6, top + 8, "E")
        for x in (m0 + 3)...(m0 + 8) { put(&g, x, top + 9, "E") }
    }

    var s = Sprite(grid: g, bx: bx, by: by, n: n, groundY: groundY, mouthX: bx + n / 2, mouthY: mouthY)
    s.minX = canvasW; s.minY = canvasH; s.maxX = 0; s.maxY = 0
    for (y, row) in g.enumerated() {
        for (x, ch) in row.enumerated() where ch != "." {
            s.minX = min(s.minX, x); s.maxX = max(s.maxX, x)
            s.minY = min(s.minY, y); s.maxY = max(s.maxY, y)
        }
    }
    return s
}

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
        asleep = try c.decodeIfPresent(Bool.self, forKey: .asleep) ?? asleep
        dead = try c.decodeIfPresent(Bool.self, forKey: .dead) ?? dead
        born = try c.decodeIfPresent(Date.self, forKey: .born) ?? born
        lastUpdate = try c.decodeIfPresent(Date.self, forKey: .lastUpdate) ?? lastUpdate
    }

    var days: Int { max(0, Int(Date().timeIntervalSince(born) / 86_400)) }
    /// всеки ден с един пиксел повече, до 16×16
    var size: Int { min(16, 5 + days) }

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
            energy -= 1.2 * m
            work += 10 * m
            workSeconds += dt
            if workSeconds >= 600 { workSeconds -= 600; videos += 1 }
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
    "Премиерът пак крашна. Добре съм. 🙂",
    "Звукът е разминат с 2 кадъра. ВИЖДАМ ГО.",
    "Кафе → монтаж → кафе → монтаж",
    "Тая музика е без авторски права… нали?",
    "J-cut, L-cut, баница-cut 🥧",
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
    "Външният диск издава странни звуци 😬",
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

let happyLines = ["Хи-хи!", "Гъделичкаш!", "Обичам те!", "Още!", "Пиксчо е щастлив!", "♥", "Ихааа!", "Ти си най-добрият!", "Йей!"]
let angryLines = ["Остави ме да спя! 😠", "Пет минутки още…", "Грррр!", "Сънувах рендер… и ме събуди!", "Шшшт!", "Не съм тук!", "Ще ти се сърдя!"]
let eatLines = ["Ням!", "Вкусен пиксел!", "Мммм!", "Ням-ням!", "Още един!", "Пиксели = живот"]

func pick(_ lines: [String], avoiding last: inout String) -> String {
    var line = lines.randomElement()!
    if lines.count > 1 { while line == last { line = lines.randomElement()! } }
    last = line
    return line
}

// MARK: - Изглед на Пиксчо

enum Action { case none, eat, love, angry, pill }

final class PetView: NSView {
    weak var game: Game?
    var hovering = false
    var spriteRect = NSRect.zero        // заетата част, в координатите на изгледа
    private var dragStart: NSPoint?
    private var windowStart = NSPoint.zero
    private var dragged = false

    static let scale: CGFloat = 5
    static let top: CGFloat = 44         // място за балончето
    static let left: CGFloat = 10
    static let size = NSSize(width: CGFloat(canvasW) * scale + 20, height: top + CGFloat(canvasH) * scale + 20)

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        windowStart = window?.frame.origin ?? .zero
        dragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let window else { return }
        let p = NSEvent.mouseLocation
        let dx = p.x - start.x, dy = p.y - start.y
        if abs(dx) + abs(dy) > 3 { dragged = true; game?.isDragging = true }
        if dragged { window.setFrameOrigin(NSPoint(x: windowStart.x + dx, y: windowStart.y + dy)) }
    }

    override func mouseUp(with event: NSEvent) {
        if dragged { game?.finishedDrag() } else { game?.petIt() }
        dragStart = nil
        dragged = false
        game?.isDragging = false
    }

    override func menu(for event: NSEvent) -> NSMenu? { game?.makeMenu() }

    // --- рисуване ---

    func color(_ c: Character) -> NSColor? {
        guard let game else { return nil }
        let pet = game.pet
        switch c {
        case "K": return NSColor(hex: 0x2b2b3a)
        case "B", "D", "L":
            if pet.dead { return NSColor(hex: c == "D" ? 0xc8c8d8 : 0xe8e8f0, alpha: 0.85) }
            var body = NSColor(hex: game.look.body)
            if pet.health < 40 { body = body.blended(withFraction: 0.6, of: NSColor(hex: 0xb5c49a)) ?? body }
            if game.action == .angry { body = body.blended(withFraction: 0.35, of: NSColor(hex: 0xe63946)) ?? body }
            if c == "D" { return body.blended(withFraction: 0.22, of: .black) ?? body }
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
        default: return nil
        }
    }

    private func draw(_ g: Grid, x: CGFloat, y: CGFloat, scale s: CGFloat, flip: Bool = false) {
        for (row, line) in g.enumerated() {
            for (col, ch) in line.enumerated() {
                guard let c = color(ch) else { continue }
                c.setFill()
                let cx = flip ? line.count - 1 - col : col
                NSRect(x: x + CGFloat(cx) * s, y: y + CGFloat(row) * s, width: s, height: s).fill()
            }
        }
    }

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
        else if game.action == .love { pose = .wave }
        else if pet.working { pose = .type }
        else { pose = .idle }

        let sp = buildSprite(n: pet.size, face: game.currentFace(), pose: pose,
                             frame: pose == .walk ? Int(t * 6) : frame, look: game.look, working: pet.working)

        var dy: CGFloat = 0
        if pet.dead {
            dy = CGFloat(sin(t * 2) * 4)
        } else if pet.asleep {
            dy = frame % 4 < 2 ? 0 : 2
        } else if game.action == .love {
            dy = -abs(CGFloat(sin(t * 8))) * s * 1.5
        } else if game.action == .angry {
            dy = 0
        } else if !game.walking && !pet.working {
            dy = frame % 2 == 0 ? 0 : 2
        }

        func vx(_ col: Int) -> CGFloat { ox + CGFloat(flip ? canvasW - 1 - col : col) * s }
        func vy(_ row: Int) -> CGFloat { oy + CGFloat(row) * s + dy }

        // сянка
        if !pet.dead {
            NSColor(white: 0, alpha: 0.18).setFill()
            let left = min(vx(sp.bx - 1), vx(sp.bx + sp.n))
            NSBezierPath(ovalIn: NSRect(x: left - s, y: oy + CGFloat(sp.groundY + 1) * s - 3,
                                        width: CGFloat(sp.n + 4) * s, height: 5)).fill()
        }

        draw(sp.grid, x: ox, y: oy + dy, scale: s, flip: flip)

        let minX = min(vx(sp.minX), vx(sp.maxX))
        spriteRect = NSRect(x: minX, y: vy(sp.minY), width: CGFloat(sp.maxX - sp.minX + 1) * s,
                            height: CGFloat(sp.maxY - sp.minY + 1) * s).insetBy(dx: -4, dy: -4)

        let headTop = vy(sp.by - 1)
        let centerX = (vx(sp.bx) + vx(sp.bx + sp.n - 1) + s) / 2
        let p = game.actionProgress

        switch game.action {
        case .eat:
            let size = max(2, s * 2.4 * CGFloat(1 - p))
            let mx = vx(sp.mouthX) + s / 2, my = vy(sp.mouthY) + s / 2
            NSColor(hex: game.lastFoodColor).setFill()
            NSRect(x: mx - size / 2, y: my - size / 2, width: size, height: size).fill()
        case .love:
            for i in 0..<3 {
                let phase = (p + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let hx = centerX - 30 + CGFloat(i) * 22
                let hy = headTop - 4 - CGFloat(phase) * 34
                draw(heartGrid, x: hx, y: hy, scale: 2.5)
            }
        case .angry:
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 16)]
            ("💢" as NSString).draw(at: NSPoint(x: vx(sp.bx + sp.n) + 2, y: headTop - 18), withAttributes: attrs)
        case .pill:
            draw(pillGrid, x: centerX - 7, y: headTop - 24 + CGFloat(p) * 30, scale: 2.5)
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
                let zx = centerX + CGFloat(sp.n) * s / 2 + CGFloat(phase) * 18
                let zy = headTop - 6 - CGFloat(phase) * 28
                ("z" as NSString).draw(at: NSPoint(x: zx, y: zy), withAttributes: attrs)
            }
        }

        if let text = game.bubbleText { drawBubble(text) }
        if hovering { drawName(pet.name, centerX: centerX, y: oy + CGFloat(sp.groundY + 1) * s + 3) }
    }

    private func drawBubble(_ text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor(hex: 0x2b2b3a),
        ]
        let str = text as NSString
        let maxW = bounds.width - 16
        let size = str.boundingRect(with: NSSize(width: maxW - 12, height: 200),
                                    options: [.usesLineFragmentOrigin], attributes: attrs).size
        let w = ceil(size.width) + 14, h = ceil(size.height) + 8
        let rect = NSRect(x: (bounds.width - w) / 2, y: 3, width: w, height: h)
        let path = NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7)
        NSColor.white.setFill(); path.fill()
        NSColor(hex: 0x2b2b3a).setStroke(); path.lineWidth = 2; path.stroke()
        str.draw(with: NSRect(x: rect.minX + 7, y: rect.minY + 4, width: w - 14, height: h - 8),
                 options: [.usesLineFragmentOrigin], attributes: attrs)
    }

    private func drawName(_ name: String, centerX: CGFloat, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor.white,
        ]
        let str = name as NSString
        let size = str.size(withAttributes: attrs)
        let rect = NSRect(x: centerX - size.width / 2 - 7, y: y, width: size.width + 14, height: size.height + 3)
        NSColor(hex: 0x2b2b3a, alpha: 0.85).setFill()
        NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2).fill()
        str.draw(at: NSPoint(x: rect.minX + 7, y: rect.minY + 1.5), withAttributes: attrs)
    }
}

// MARK: - Пиксели-храна по екрана

final class FoodPixel: NSObject {
    let color: Int
    let panel: NSPanel
    let view: FoodView

    init(color: Int, at origin: NSPoint, game: Game) {
        self.color = color
        panel = NSPanel(contentRect: NSRect(origin: origin, size: FoodView.size),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        view = FoodView(frame: NSRect(origin: .zero, size: FoodView.size))
        super.init()
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
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

// MARK: - Змията

final class SnakeView: NSView {
    weak var game: Game?
    let cols = 20, rows = 20
    let cell: CGFloat = 16
    let header: CGFloat = 30
    var snake: [(Int, Int)] = []
    var dir = (1, 0)
    var nextDir = (1, 0)
    var food = (5, 5)
    var foodColor = 0xffca3a
    var score = 0
    var best = 0
    var started = false
    var over = false
    var timer: Timer?

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    func reset() {
        snake = [(10, 10), (9, 10), (8, 10)]
        dir = (1, 0)
        nextDir = dir
        score = 0
        over = false
        started = false
        placeFood()
        restartTimer()
        needsDisplay = true
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func restartTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: max(0.06, 0.15 - Double(score) * 0.004), target: self,
                      selector: #selector(step), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func placeFood() {
        var spot = (0, 0)
        repeat { spot = (Int.random(in: 0..<cols), Int.random(in: 0..<rows)) } while snake.contains(where: { $0 == spot })
        food = spot
        foodColor = foodColors.randomElement()!
    }

    @objc func step() {
        guard started, !over else { return }
        dir = nextDir
        let head = (snake[0].0 + dir.0, snake[0].1 + dir.1)
        let eating = head == food
        let body = eating ? snake : Array(snake.dropLast())
        if head.0 < 0 || head.0 >= cols || head.1 < 0 || head.1 >= rows || body.contains(where: { $0 == head }) {
            over = true
            best = max(best, score)
            needsDisplay = true
            return
        }
        snake.insert(head, at: 0)
        if eating {
            score += 1
            best = max(best, score)
            placeFood()
            restartTimer()
        } else {
            snake.removeLast()
        }
        needsDisplay = true
    }

    private func turn(_ d: (Int, Int)) {
        if over { return }
        started = true
        if d.0 == -dir.0 && d.1 == -dir.1 { return }
        nextDir = d
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123, 0: turn((-1, 0))     // ← или A
        case 124, 2: turn((1, 0))      // → или D
        case 125, 1: turn((0, 1))      // ↓ или S
        case 126, 13: turn((0, -1))    // ↑ или W
        case 49: if over { reset() }   // интервал
        case 53: window?.performClose(nil)
        default: super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(hex: 0x1b1b24).setFill(); bounds.fill()
        let body = NSColor(hex: game?.look.body ?? 0x8ed1a5)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.white,
        ]
        ("Точки: \(score)    Рекорд: \(best)" as NSString).draw(at: NSPoint(x: 10, y: 7), withAttributes: attrs)

        NSColor(hex: 0x24243a).setFill()
        NSRect(x: 0, y: header, width: CGFloat(cols) * cell, height: CGFloat(rows) * cell).fill()

        func rect(_ c: (Int, Int)) -> NSRect {
            NSRect(x: CGFloat(c.0) * cell, y: header + CGFloat(c.1) * cell, width: cell, height: cell)
        }

        // храна
        let fr = rect(food).insetBy(dx: 2, dy: 2)
        NSColor(hex: 0x2b2b3a).setFill(); fr.fill()
        NSColor(hex: foodColor).setFill(); fr.insetBy(dx: 2, dy: 2).fill()

        // опашка
        for (i, seg) in snake.enumerated().reversed() where i > 0 {
            let r = rect(seg).insetBy(dx: 1, dy: 1)
            NSColor(hex: 0x2b2b3a).setFill(); r.fill()
            let c = i % 2 == 0 ? body : (body.blended(withFraction: 0.2, of: .black) ?? body)
            c.setFill(); r.insetBy(dx: 2, dy: 2).fill()
        }

        // главата е самият Пиксчо
        if let head = snake.first {
            let r = rect(head)
            NSColor(hex: 0x2b2b3a).setFill(); r.fill()
            body.setFill(); r.insetBy(dx: 2, dy: 2).fill()
            NSColor(hex: 0x2b2b3a).setFill()
            let ex = r.midX + CGFloat(dir.0) * 3, ey = r.midY + CGFloat(dir.1) * 3
            let px = CGFloat(abs(dir.1)) * 3.5, py = CGFloat(abs(dir.0)) * 3.5
            NSRect(x: ex - px - 1.5, y: ey - py - 1.5, width: 3, height: 3).fill()
            NSRect(x: ex + px - 1.5, y: ey + py - 1.5, width: 3, height: 3).fill()
        }

        let msg: String?
        if over { msg = "Край! \(score) точки\nИнтервал = нова игра" }
        else if !started { msg = "Стрелките или WASD\nза старт" }
        else { msg = nil }
        if let msg {
            NSColor(white: 0, alpha: 0.55).setFill()
            NSRect(x: 0, y: header, width: bounds.width, height: bounds.height - header).fill()
            let big: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: NSColor.white,
            ]
            let str = msg as NSString
            let size = str.boundingRect(with: NSSize(width: bounds.width - 20, height: 200),
                                        options: [.usesLineFragmentOrigin], attributes: big).size
            str.draw(with: NSRect(x: (bounds.width - size.width) / 2, y: header + (bounds.height - header - size.height) / 2,
                                  width: size.width + 2, height: size.height + 2),
                     options: [.usesLineFragmentOrigin], attributes: big)
        }
    }
}

// MARK: - Контролер

final class Game: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    var pet = Pet()
    var look = Look()
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

    var foods: [FoodPixel] = []
    var nextFoodSpawn: Double = 60

    var snakeWindow: NSWindow?
    var snakeView: SnakeView?

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

        window = NSPanel(contentRect: NSRect(origin: .zero, size: PetView.size),
                         styleMask: [.borderless, .nonactivatingPanel],
                         backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.isFloatingPanel = true
        window.hidesOnDeactivate = false
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
        statusItem.button?.title = "🟩"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        let timer = Timer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)

        say(pet.dead ? "…" : "Здрасти, аз съм \(pet.name)! 👋", seconds: 3)
    }

    func applicationWillTerminate(_ notification: Notification) { save() }

    // --- цикъл ---

    @objc func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTick)
        lastTick = now

        let videosBefore = pet.videos
        let workingBefore = pet.working
        // Мак-ът е спал → броим го като „офлайн“ време
        if dt > 30 { pet.tick(min(dt, 8 * 3600) * 0.3, offline: true) } else { pet.tick(dt) }
        time += min(dt, 0.5)

        if pet.videos > videosBefore {
            say("Готово видео №\(pet.videos)! 🎬", seconds: 4)
        } else if workingBefore && !pet.working && !pet.asleep && !pet.dead {
            say("Стига толкова, капнах…", seconds: 3)
        }

        if action != .none && time - actionStart >= actionLength { action = .none }
        if bubbleText != nil && time > bubbleUntil { bubbleText = nil }

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
            nextFoodSpawn = time + Double.random(in: 6 * 60...15 * 60)
            if foods.count < 3 { spawnFood() }
        }
        for f in foods { f.view.needsDisplay = true }

        updateWalk()
        updateMouse()

        let icon: String
        if pet.dead { icon = "👻" }
        else if pet.asleep { icon = "💤" }
        else if pet.working { icon = "🎬" }
        else if currentNeed() != nil { icon = "🥺" }
        else { icon = "🟩" }
        if statusItem.button?.title != icon { statusItem.button?.title = icon }

        if time - lastSave > 30 { save() }
        if time > nextUpdateCheck {
            nextUpdateCheck = time + 6 * 3600
            checkForUpdate(manual: false)
        }
        view.needsDisplay = true
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
        case .love, .pill: return .happy
        case .angry: return .angry
        case .none: break
        }
        if isDragging { return .happy }
        if pet.health < 40 { return .sick }
        if pet.working { return time < blinkUntil ? .blink : .focus }
        if pet.fullness < 25 || pet.fun < 25 { return .sad }
        return time < blinkUntil ? .blink : .normal
    }

    func updateWalk() {
        guard wander, !pet.dead, !pet.asleep, !pet.working, !isDragging, action == .none,
              let screen = window.screen ?? NSScreen.main else {
            walking = false
            return
        }
        let vf = screen.visibleFrame
        var origin = window.frame.origin
        guard let target = walkTarget else {
            walking = false
            if Double.random(in: 0..<1) < 0.006 {
                let t = origin.x + CGFloat.random(in: -220...220)
                walkTarget = min(max(t, vf.minX), vf.maxX - PetView.size.width)
            }
            return
        }
        let step: CGFloat = 1.5
        if abs(target - origin.x) <= step {
            walkTarget = nil
            walking = false
            saveWindowPosition()
            return
        }
        walking = true
        facingLeft = target < origin.x
        origin.x += facingLeft ? -step : step
        window.setFrameOrigin(origin)
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

    func finishedDrag() {
        walkTarget = nil
        keepOnScreen()
        saveWindowPosition()
    }

    /// Клик върху Пиксчо: работи → смешна реплика, спи → сърди се, иначе → кефи се.
    func petIt() {
        if pet.dead { say("…", seconds: 1.5); return }
        if pet.asleep {
            pet.fun = (pet.fun - 2).clamped()
            start(.angry, length: 2)
            say(pick(angryLines, avoiding: &lastLine), seconds: 2.5)
            return
        }
        if pet.working {
            say(pick(editingLines, avoiding: &lastLine), seconds: 4)
            nextWorkLine = time + Double.random(in: 60...150)
            return
        }
        pet.fun = (pet.fun + 4).clamped()
        start(.love, length: 1.6)
        say(pick(happyLines, avoiding: &lastLine), seconds: 1.8)
    }

    func eat(color: Int) {
        if pet.fullness > 92 {
            pet.health = (pet.health - 3).clamped()
            say("Преядох! 🤢", seconds: 2.5)
        } else {
            say(pick(eatLines, avoiding: &lastLine), seconds: 2)
        }
        pet.fullness = (pet.fullness + 15).clamped()
        lastFoodColor = color
        start(.eat, length: 1.6)
        save()
    }

    @objc func feed() {
        guard checkAwake() else { return }
        eat(color: foodColors.randomElement()!)
    }

    // пиксели по екрана

    @objc func spawnFood() {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
        let origin = NSPoint(x: CGFloat.random(in: (vf.minX + 40)...(vf.maxX - 70)),
                             y: CGFloat.random(in: (vf.minY + 40)...(vf.maxY - 70)))
        foods.append(FoodPixel(color: foodColors.randomElement()!, at: origin, game: self))
    }

    func foodDropped(_ food: FoodPixel) {
        let f = food.panel.frame
        let center = NSPoint(x: f.midX, y: f.midY)
        if window.isVisible && petScreenRect().insetBy(dx: -14, dy: -14).contains(center) {
            if pet.dead { say("…", seconds: 1.5); return }
            if pet.asleep { say("Zzz… (спи)", seconds: 2); return }
            food.remove()
            foods.removeAll { $0 === food }
            eat(color: food.color)
            return
        }
        // да не се изгуби извън екрана
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
            say("Пауза! ☕", seconds: 2)
        } else {
            if pet.energy < 15 { say("Нямам сили да монтирам…", seconds: 2.5); return }
            pet.working = true
            walkTarget = nil
            nextWorkLine = time + Double.random(in: 20...50)
            say("Отварям таймлайна… 💻", seconds: 2.5)
        }
        save()
    }

    // змията

    @objc func play() {
        guard checkAwake() else { return }
        if let w = snakeWindow {
            NSApp.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
            return
        }
        if pet.energy < 15 { say("Нямам сили…", seconds: 2.5); return }
        let sv = SnakeView(frame: NSRect(x: 0, y: 0, width: 320, height: 350))
        sv.game = self
        let w = NSWindow(contentRect: sv.frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "🐍 Змията с \(pet.name)"
        w.contentView = sv
        w.isReleasedWhenClosed = false
        w.delegate = self
        w.center()
        snakeWindow = w
        snakeView = sv
        sv.reset()
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        w.makeFirstResponder(sv)
        say("Да играем! 🐍", seconds: 2)
    }

    func windowWillClose(_ notification: Notification) {
        guard let w = notification.object as? NSWindow, w === snakeWindow, let sv = snakeView else { return }
        sv.stop()
        let best = sv.best
        snakeWindow = nil
        snakeView = nil
        guard !pet.dead else { return }
        pet.fun = (pet.fun + min(40, 8 + Double(best) * 2)).clamped()
        pet.energy = (pet.energy - min(15, 3 + Double(best) / 2)).clamped()
        start(.love, length: 1.6)
        say(best > 0 ? "Изкарахме \(best) точки! 🐍" : "Пак ще играем!", seconds: 3)
        save()
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

    @objc func toggleWindow() {
        if window.isVisible { window.orderOut(nil) } else { window.orderFrontRegardless() }
        UserDefaults.standard.set(!window.isVisible, forKey: "hidden")
    }

    @objc func toggleWander() { wander.toggle(); walkTarget = nil }

    @objc func callHome() {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
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
            say("Здрасти, аз съм \(pet.name)! 👋", seconds: 3)
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

    // --- меню ---

    func menuNeedsUpdate(_ menu: NSMenu) { fill(menu) }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        fill(menu)
        return menu
    }

    private func fill(_ menu: NSMenu) {
        menu.removeAllItems()
        func item(_ title: String, _ sel: Selector?, on: Bool = false, enabled: Bool = true) {
            let it = NSMenuItem(title: title, action: sel, keyEquivalent: "")
            it.target = self
            it.state = on ? .on : .off
            it.isEnabled = enabled && sel != nil
            menu.addItem(it)
        }
        func bar(_ v: Double) -> String {
            let n = Int((v / 10).rounded())
            return String(repeating: "■", count: n) + String(repeating: "□", count: 10 - n)
        }
        menu.autoenablesItems = false

        if availableBuild > currentBuild {
            item("⬆️ Обнови до версия \(availableBuild)", updating ? nil : #selector(installUpdate))
            menu.addItem(.separator())
        }

        let state: String
        if pet.dead { state = "👻 отиде си" }
        else if pet.asleep { state = "💤 спи" }
        else if pet.working { state = "🎬 монтира" }
        else { state = currentNeed() ?? "😊 добре е" }
        item("\(pet.name) · ден \(pet.days + 1) · \(pet.size)×\(pet.size) пиксела", nil)
        item(state, nil)
        item("🍎 Ситост    \(bar(pet.fullness))", nil)
        item("🎈 Радост     \(bar(pet.fun))", nil)
        item("⚡ Енергия   \(bar(pet.energy))", nil)
        item("🎬 Работа     \(bar(pet.work))", nil)
        item("❤️ Здраве     \(bar(pet.health))", nil)
        item("Монтирани видеа: \(pet.videos)", nil)
        menu.addItem(.separator())

        if pet.dead {
            item("🥚 Ново животинче", #selector(newPet))
        } else {
            let awake = !pet.asleep
            item(pet.working ? "⏸ Спри работа" : "💻 Работи (монтаж)", #selector(toggleWork), enabled: awake)
            item("🍎 Нахрани", #selector(feed), enabled: awake)
            item("🐍 Играй (змията)", #selector(play), enabled: awake)
            item("💊 Дай лекарство", #selector(medicine), enabled: awake)
            item(pet.asleep ? "☀️ Събуди" : "🌙 Приспи", #selector(toggleSleep))
        }
        menu.addItem(.separator())
        menu.addItem(lookMenu())
        item("Пиксели-храна по екрана", #selector(toggleFoodPixels), on: foodPixelsOn)
        if foodPixelsOn { item("✨ Пусни пиксел сега", #selector(spawnFood), enabled: foods.count < 6) }
        menu.addItem(.separator())
        item(window.isVisible ? "Скрий" : "Покажи", #selector(toggleWindow))
        item("Повикай в ъгъла", #selector(callHome))
        item("Разхожда се", #selector(toggleWander), on: wander)
        item("Смени името…", #selector(rename))
        if #available(macOS 13.0, *) {
            item("Пускай при включване", #selector(toggleLogin), on: SMAppService.mainApp.status == .enabled)
        }
        if !pet.dead { item("Ново животинче…", #selector(newPet)) }
        menu.addItem(.separator())
        item("Версия \(currentBuild) · Провери за обновления", #selector(checkForUpdateManually))
        item("Изход", #selector(quit))
    }

    // --- облик ---

    private func lookMenu() -> NSMenuItem {
        let root = NSMenuItem(title: "🎨 Облик", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        sub.autoenablesItems = false
        root.submenu = sub

        func group(_ title: String, _ build: (NSMenu) -> Void) {
            let it = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let m = NSMenu()
            m.autoenablesItems = false
            build(m)
            it.submenu = m
            sub.addItem(it)
        }
        func choice(_ m: NSMenu, _ title: String, _ sel: Selector, _ value: Any, on: Bool) {
            let it = NSMenuItem(title: title, action: sel, keyEquivalent: "")
            it.target = self
            it.representedObject = value
            it.state = on ? .on : .off
            m.addItem(it)
        }

        group("Цвят") { m in
            var matched = false
            for (name, hex) in colorPresets {
                if hex == look.body { matched = true }
                choice(m, name, #selector(pickPreset(_:)), hex, on: hex == look.body)
            }
            m.addItem(.separator())
            let other = NSMenuItem(title: "🎨 Друг цвят…", action: #selector(openColorPanel), keyEquivalent: "")
            other.target = self
            other.state = matched ? .off : .on
            m.addItem(other)
        }
        group("Шапка") { m in
            choice(m, "Без", #selector(pickHat(_:)), "", on: look.hat.isEmpty)
            for key in hatOrder { choice(m, hats[key]!.name, #selector(pickHat(_:)), key, on: look.hat == key) }
        }
        group("Очи") { m in
            choice(m, "Без", #selector(pickFace(_:)), "", on: look.face.isEmpty)
            for key in faceOrder { choice(m, faceItems[key]!, #selector(pickFace(_:)), key, on: look.face == key) }
        }
        group("На врата") { m in
            choice(m, "Без", #selector(pickNeck(_:)), "", on: look.neck.isEmpty)
            for key in neckOrder { choice(m, neckItems[key]!, #selector(pickNeck(_:)), key, on: look.neck == key) }
        }
        sub.addItem(.separator())
        let random = NSMenuItem(title: "🎲 Изненадай ме", action: #selector(randomLook), keyEquivalent: "")
        random.target = self
        sub.addItem(random)
        return root
    }

    func lookChanged() {
        saveLook()
        if !pet.dead && !pet.asleep && !pet.working {
            start(.love, length: 1.2)
            say(["Красавец!", "Харесва ми!", "Ооо, ново!", "Как ми стои?"].randomElement()!, seconds: 2)
        }
    }

    @objc func pickPreset(_ sender: NSMenuItem) {
        guard let hex = sender.representedObject as? Int else { return }
        look.body = hex
        lookChanged()
    }

    @objc func pickHat(_ sender: NSMenuItem) { look.hat = sender.representedObject as? String ?? ""; lookChanged() }
    @objc func pickFace(_ sender: NSMenuItem) { look.face = sender.representedObject as? String ?? ""; lookChanged() }
    @objc func pickNeck(_ sender: NSMenuItem) { look.neck = sender.representedObject as? String ?? ""; lookChanged() }

    @objc func randomLook() {
        look.body = colorPresets.randomElement()!.1
        look.hat = (hatOrder + [""]).randomElement()!
        look.face = (faceOrder + ["", ""]).randomElement()!
        look.neck = (neckOrder + [""]).randomElement()!
        lookChanged()
    }

    @objc func openColorPanel() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(colorPicked(_:)))
        panel.isContinuous = true
        panel.color = NSColor(hex: look.body)
        panel.orderFront(nil)
    }

    @objc func colorPicked(_ sender: NSColorPanel) {
        guard let c = sender.color.usingColorSpace(.sRGB) else { return }
        let r = Int((c.redComponent * 255).rounded()), g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent * 255).rounded())
        look.body = (r << 16) | (g << 8) | b
        saveLook()
    }

    func saveLook() {
        if let data = try? JSONEncoder().encode(look) { UserDefaults.standard.set(data, forKey: "look") }
    }

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
                say("Има обновление! ⬆️", seconds: 5)
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
            say("Не успях да се обновя 😕", seconds: 4)
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
            say("Не успях да се обновя 😕", seconds: 4)
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
        if let data = UserDefaults.standard.data(forKey: "look"),
           let saved = try? JSONDecoder().decode(Look.self, from: data) {
            look = saved
        }
        guard let data = UserDefaults.standard.data(forKey: "pet"),
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
