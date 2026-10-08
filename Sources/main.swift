// Тамагочи — малко пикселно животинче, което живее на екрана на Мак-а.
// Компилира се с tamagotchi/build.sh (нужни са само Command Line Tools).

import AppKit
import ServiceManagement

// MARK: - Цветове и спрайтове

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

func overlay(_ g: Grid, _ pts: [(Int, Int, Character)]) -> Grid {
    var g = g
    for (x, y, c) in pts where y >= 0 && y < g.count && x >= 0 && x < g[y].count {
        g[y][x] = c
    }
    return g
}

// 16×16. K = контур, B = тяло, D = сянка, W = бяло, P = бузи, R = червено, T = сълза
let bodyGrid = grid([
    "................",
    ".....KKKKKK.....",
    "...KKBBBBBBKK...",
    "..KBBBBBBBBBBK..",
    ".KBBWBBBBBBBBBK.",
    ".KBWBBBBBBBBBBK.",
    "KBBBBBBBBBBBBBBK",
    "KBBBBBBBBBBBBBBK",
    "KBBBBBBBBBBBBBBK",
    "KBBBBBBBBBBBBBBK",
    "KBBBBBBBBBBBBBBK",
    ".KDBBBBBBBBBBDK.",
    "..KDDDDDDDDDDK..",
    "...KKKKKKKKKK...",
    "...KDK....KDK...",
    "...KKK....KKK...",
])

let eyesOpen: [(Int, Int, Character)] = [
    (4, 7, "W"), (5, 7, "K"), (4, 8, "K"), (5, 8, "K"),
    (10, 7, "W"), (11, 7, "K"), (10, 8, "K"), (11, 8, "K"),
]
let eyesClosed: [(Int, Int, Character)] = [
    (3, 8, "K"), (4, 8, "K"), (5, 8, "K"), (10, 8, "K"), (11, 8, "K"), (12, 8, "K"),
]
let eyesHappy: [(Int, Int, Character)] = [
    (3, 8, "K"), (4, 7, "K"), (5, 7, "K"), (6, 8, "K"),
    (9, 8, "K"), (10, 7, "K"), (11, 7, "K"), (12, 8, "K"),
]
let eyesDead: [(Int, Int, Character)] = [
    (3, 6, "K"), (5, 6, "K"), (4, 7, "K"), (3, 8, "K"), (5, 8, "K"),
    (10, 6, "K"), (12, 6, "K"), (11, 7, "K"), (10, 8, "K"), (12, 8, "K"),
]
let cheeks: [(Int, Int, Character)] = [(3, 9, "P"), (12, 9, "P")]
let mouthSmile: [(Int, Int, Character)] = [(6, 9, "K"), (7, 10, "K"), (8, 10, "K"), (9, 9, "K")]
let mouthOpen: [(Int, Int, Character)] = [
    (6, 10, "K"), (7, 10, "R"), (8, 10, "R"), (9, 10, "K"), (7, 11, "K"), (8, 11, "K"),
]
let mouthFrown: [(Int, Int, Character)] = [(6, 10, "K"), (7, 9, "K"), (8, 9, "K"), (9, 10, "K")]
let mouthFlat: [(Int, Int, Character)] = [(6, 10, "K"), (7, 10, "K"), (8, 10, "K"), (9, 10, "K")]
let mouthSmall: [(Int, Int, Character)] = [(7, 10, "K"), (8, 10, "K")]
let tears: [(Int, Int, Character)] = [(4, 9, "T"), (4, 10, "T"), (11, 9, "T")]
let sweat: [(Int, Int, Character)] = [(13, 3, "T"), (13, 4, "T")]

let appleGrid = grid([
    "....G..",
    "...K...",
    ".RRKRR.",
    "RWRRRRR",
    "RRRRRRR",
    "RRRRRRR",
    ".RRRRR.",
    "..R.R..",
])
let heartGrid = grid([
    ".RR.RR.",
    "RRRRRRR",
    "RRRRRRR",
    ".RRRRR.",
    "..RRR..",
    "...R...",
])
let ballGrid = grid([
    "..YY..",
    ".YYRY.",
    "YYRRYY",
    "YYYYYY",
    ".YRYY.",
    "..YY..",
])
let pillGrid = grid([
    ".WWRR.",
    "WWWRRR",
    ".WWRR.",
])

enum Face { case normal, blink, happy, sad, sleep, eatOpen, eatShut, sick, dead }

func petGrid(_ face: Face) -> Grid {
    switch face {
    case .normal: return overlay(bodyGrid, eyesOpen + cheeks + mouthSmile)
    case .blink: return overlay(bodyGrid, eyesClosed + cheeks + mouthSmile)
    case .happy: return overlay(bodyGrid, eyesHappy + cheeks + mouthOpen)
    case .sad: return overlay(bodyGrid, eyesOpen + mouthFrown + tears)
    case .sleep: return overlay(bodyGrid, eyesClosed + cheeks + mouthSmall)
    case .eatOpen: return overlay(bodyGrid, eyesHappy + cheeks + mouthOpen)
    case .eatShut: return overlay(bodyGrid, eyesHappy + cheeks + mouthFlat)
    case .sick: return overlay(bodyGrid, eyesOpen + mouthFlat + sweat)
    case .dead: return overlay(bodyGrid, eyesDead + mouthFlat)
    }
}

// MARK: - Облик (цвят и аксесоари)

struct Accessory {
    let name: String
    let grid: Grid
    let dx: Int   // позиция спрямо спрайта 16×16 (може и над главата, с отрицателно dy)
    let dy: Int
}

// N = тъмносиньо, O = оранжево, S = тъмни стъкла
let hats: [String: Accessory] = [
    "crown": Accessory(name: "👑 Корона", grid: grid([
        "Y..YY..Y",
        "YY.YY.YY",
        "YYYYYYYY",
        "YRYYYYTY",
    ]), dx: 4, dy: -2),
    "party": Accessory(name: "🥳 Парти шапка", grid: grid([
        "..YY..",
        "..RR..",
        ".RYYR.",
        ".RRRR.",
        "RYYYYR",
    ]), dx: 5, dy: -4),
    "beanie": Accessory(name: "🧢 Зимна шапка", grid: grid([
        "....OO....",
        "..NNNNNN..",
        ".NNNNNNNN.",
        "OOOOOOOOOO",
    ]), dx: 3, dy: -2),
    "bow": Accessory(name: "🎀 Панделка", grid: grid([
        "PP.PP",
        "PPRPP",
        "PP.PP",
    ]), dx: 10, dy: 0),
    "flower": Accessory(name: "🌼 Цвете", grid: grid([
        ".W.",
        "WYW",
        ".W.",
    ]), dx: 11, dy: 0),
]
let faceItems: [String: Accessory] = [
    "glasses": Accessory(name: "👓 Очила", grid: grid([
        "KKKK..KKKK",
        "K..KKKK..K",
        "K..K..K..K",
        "KKKK..KKKK",
    ]), dx: 3, dy: 6),
    "sunglasses": Accessory(name: "😎 Слънчеви очила", grid: grid([
        "KKKK..KKKK",
        "KWSKKKKWSK",
        "KSSK..KSSK",
        "KKKK..KKKK",
    ]), dx: 3, dy: 6),
]
let neckItems: [String: Accessory] = [
    "bowtie": Accessory(name: "🎩 Папийонка", grid: grid([
        "RRKKRR",
        "RR..RR",
    ]), dx: 5, dy: 11),
    "scarf": Accessory(name: "🧣 Шал", grid: grid([
        "OOOOOOOOOOOOOO",
        "........OO....",
        "........OO....",
    ]), dx: 1, dy: 11),
]
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

struct Look: Codable {
    var body = 0x8ed1a5
    var hat = ""
    var face = ""
    var neck = ""
}

// MARK: - Животинчето

struct Pet: Codable {
    var name = "Пикси"
    var fullness: Double = 80
    var fun: Double = 80
    var energy: Double = 80
    var health: Double = 100
    var asleep = false
    var dead = false
    var born = Date()
    var lastUpdate = Date()

    /// dt — секунди. offline = докато приложението е било спряно (по-кротко и без да боледува).
    mutating func tick(_ dt: Double, offline: Bool = false) {
        guard !dead, dt > 0 else { return }
        let m = dt / 60
        if asleep {
            fullness -= 0.25 * m
            fun -= 0.2 * m
            energy += 4 * m
            if energy >= 100 { energy = 100; asleep = false }
        } else {
            fullness -= 0.5 * m
            fun -= 0.7 * m
            energy -= 0.4 * m
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
        if health <= 0 { dead = true; asleep = false }
    }

    var ageText: String {
        let days = Int(Date().timeIntervalSince(born) / 86_400)
        if days == 0 {
            let hours = Int(Date().timeIntervalSince(born) / 3_600)
            return "\(hours) ч."
        }
        return days == 1 ? "1 ден" : "\(days) дни"
    }
}

extension Double {
    func clamped(_ lo: Double = 0, _ hi: Double = 100) -> Double { Swift.min(hi, Swift.max(lo, self)) }
}

// MARK: - Изглед

enum Action { case none, eat, play, love, pill }

final class PetView: NSView {
    weak var game: Game?
    var hovering = false
    private var dragStart: NSPoint?
    private var windowStart = NSPoint.zero
    private var dragged = false

    static let scale: CGFloat = 6
    static let size = NSSize(width: 150, height: 180)
    static let top: CGFloat = 48

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { hovering = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent) { hovering = false; needsDisplay = true }

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

    private func color(_ c: Character) -> NSColor? {
        guard let game else { return nil }
        let pet = game.pet
        switch c {
        case "K": return NSColor(hex: 0x2b2b3a)
        case "B", "D":
            if pet.dead { return NSColor(hex: c == "B" ? 0xe8e8f0 : 0xc8c8d8, alpha: 0.85) }
            var body = NSColor(hex: game.look.body)
            if pet.health < 40 { body = body.blended(withFraction: 0.6, of: NSColor(hex: 0xb5c49a)) ?? body }
            return c == "B" ? body : (body.blended(withFraction: 0.25, of: .black) ?? body)
        case "W": return .white
        case "P": return NSColor(hex: 0xff8fab)
        case "R": return NSColor(hex: 0xe63946)
        case "T": return NSColor(hex: 0x5dade2)
        case "G": return NSColor(hex: 0x52b788)
        case "Y": return NSColor(hex: 0xffd166)
        case "N": return NSColor(hex: 0x3d5a80)
        case "O": return NSColor(hex: 0xf4a261)
        case "S": return NSColor(hex: 0x1b1b24)
        default: return nil
        }
    }

    private func draw(_ g: Grid, x: CGFloat, y: CGFloat, scale s: CGFloat, flip: Bool = false, skipCols: Int = 0) {
        for (row, line) in g.enumerated() {
            for (col, ch) in line.enumerated() where col >= skipCols {
                guard let c = color(ch) else { continue }
                c.setFill()
                let cx = flip ? line.count - 1 - col : col
                NSRect(x: x + CGFloat(cx) * s, y: y + CGFloat(row) * s, width: s, height: s).fill()
            }
        }
    }

    private func drawAccessory(_ a: Accessory, x: CGFloat, y: CGFloat, scale s: CGFloat, flip: Bool) {
        for (row, line) in a.grid.enumerated() {
            for (col, ch) in line.enumerated() {
                guard let c = color(ch) else { continue }
                c.setFill()
                let px = flip ? 15 - (a.dx + col) : a.dx + col
                NSRect(x: x + CGFloat(px) * s, y: y + CGFloat(a.dy + row) * s, width: s, height: s).fill()
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let s = PetView.scale
        let t = game.time
        let frame = Int(t * 2)               // смяна на кадъра два пъти в секунда
        let spriteW = 16 * s
        let baseX = (bounds.width - spriteW) / 2
        let baseY = PetView.top
        let face = game.currentFace()

        var dy: CGFloat = 0
        if game.pet.dead {
            dy = CGFloat(sin(t * 2) * 4)       // духче, леко плува
        } else if game.pet.asleep {
            dy = frame % 4 < 2 ? 0 : s / 2
        } else if game.action == .play || game.action == .love {
            dy = -abs(CGFloat(sin(t * 8))) * s * 2
        } else if game.walking {
            dy = Int(t * 6) % 2 == 0 ? 0 : -s / 2
        } else {
            dy = frame % 2 == 0 ? 0 : s / 3
        }

        // сянка на земята
        if !game.pet.dead {
            NSColor(white: 0, alpha: 0.18).setFill()
            NSBezierPath(ovalIn: NSRect(x: baseX + 2 * s, y: baseY + 15.3 * s, width: 12 * s, height: s * 0.9)).fill()
        }

        draw(petGrid(face), x: baseX, y: baseY + dy, scale: s, flip: game.facingLeft)
        for acc in [neckItems[game.look.neck], faceItems[game.look.face], hats[game.look.hat]] {
            if let acc { drawAccessory(acc, x: baseX, y: baseY + dy, scale: s, flip: game.facingLeft) }
        }

        // ефекти
        let p = game.actionProgress
        switch game.action {
        case .eat:
            let bites = p < 0.33 ? 0 : (p < 0.66 ? 3 : 5)
            draw(appleGrid, x: game.facingLeft ? baseX - 18 : baseX + spriteW - 10,
                 y: baseY + 7 * s, scale: 4, skipCols: bites)
        case .play:
            let by = baseY - 22 - abs(CGFloat(sin(t * 5))) * 10
            draw(ballGrid, x: baseX + spriteW / 2 - 9 + CGFloat(sin(t * 3)) * 24, y: by, scale: 3)
        case .love:
            for i in 0..<3 {
                let phase = (p + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let hx = baseX + CGFloat(i) * 34 + 6
                let hy = baseY + 20 - CGFloat(phase) * 46
                draw(heartGrid, x: hx, y: hy, scale: 3)
            }
        case .pill:
            draw(pillGrid, x: baseX + spriteW / 2 - 9, y: baseY - 14 + CGFloat(p) * 50, scale: 3)
        case .none:
            break
        }

        if game.pet.asleep {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .heavy),
                .foregroundColor: NSColor(hex: 0x5dade2),
            ]
            for i in 0..<3 {
                let phase = (t * 0.5 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let zx = baseX + spriteW - 14 + CGFloat(phase) * 18
                let zy = baseY + 4 - CGFloat(phase) * 30
                ("z" as NSString).draw(at: NSPoint(x: zx, y: zy), withAttributes: attrs)
            }
        }

        if let text = game.bubbleText { drawBubble(text) }

        if hovering || game.showBars { drawBars() }
    }

    private func drawBubble(_ text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor(hex: 0x2b2b3a),
        ]
        let str = text as NSString
        let size = str.size(withAttributes: attrs)
        let w = min(bounds.width - 4, size.width + 14)
        let rect = NSRect(x: (bounds.width - w) / 2, y: 3, width: w, height: 19)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        NSColor.white.setFill(); path.fill()
        NSColor(hex: 0x2b2b3a).setStroke(); path.lineWidth = 2; path.stroke()
        str.draw(at: NSPoint(x: rect.minX + (w - size.width) / 2, y: rect.minY + (19 - size.height) / 2),
                 withAttributes: attrs)
    }

    private func drawBars() {
        guard let pet = game?.pet else { return }
        let bars: [(Double, Int)] = [
            (pet.fullness, 0xf4a261),
            (pet.fun, 0xff8fab),
            (pet.energy, 0x5dade2),
            (pet.health, 0x52b788),
        ]
        let w: CGFloat = 80, h: CGFloat = 4
        let x = (bounds.width - w) / 2
        for (i, (value, hex)) in bars.enumerated() {
            let y: CGFloat = PetView.top + 106 + CGFloat(i) * 6
            NSColor(white: 0, alpha: 0.35).setFill()
            NSRect(x: x - 1, y: y - 1, width: w + 2, height: h + 2).fill()
            NSColor(hex: hex).setFill()
            NSRect(x: x, y: y, width: w * CGFloat(value / 100), height: h).fill()
        }
    }
}

// MARK: - Контролер

final class Game: NSObject, NSApplicationDelegate, NSMenuDelegate {
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
    var isDragging = false
    var facingLeft = false
    var walking = false
    var walkTarget: CGFloat?
    var showBars = false
    var lastTick = Date()
    var lastSave: Double = 0

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
        } else if let vf = NSScreen.main?.visibleFrame {
            window.setFrameOrigin(NSPoint(x: vf.maxX - PetView.size.width - 40, y: vf.minY))
        }
        if d.object(forKey: "hidden") as? Bool != true { window.orderFrontRegardless() }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🐣"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        let timer = Timer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)

        say(pet.dead ? "..." : "Здрасти! 👋", seconds: 3)
    }

    func applicationWillTerminate(_ notification: Notification) { save() }

    // --- цикъл ---

    @objc func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTick)
        lastTick = now
        // Мак-ът е спал → броим го като „офлайн“ време
        if dt > 30 { pet.tick(min(dt, 8 * 3600) * 0.3, offline: true) } else { pet.tick(dt) }
        time += min(dt, 0.5)

        if action != .none && time - actionStart >= actionLength { action = .none }
        if bubbleText != nil && time > bubbleUntil { bubbleText = nil }

        if time > nextBlink {
            blinkUntil = time + 0.15
            nextBlink = time + Double.random(in: 2.5...6)
        }

        if time > nextNag {
            nextNag = time + Double.random(in: 25...45)
            if let need = currentNeed() { say(need, seconds: 4) }
        }

        updateWalk()

        statusItem.button?.title = pet.dead ? "👻" : (pet.asleep ? "💤" : (currentNeed() != nil ? "🥺" : "🐣"))

        if time - lastSave > 30 { save() }
        if time > nextUpdateCheck {
            nextUpdateCheck = time + 6 * 3600
            checkForUpdate(manual: false)
        }
        view.needsDisplay = true
    }

    func currentNeed() -> String? {
        if pet.dead || pet.asleep { return nil }
        if pet.health < 40 { return "Не ми е добре…" }
        if pet.fullness < 25 { return "Гладен съм!" }
        if pet.fun < 25 { return "Скучно ми е…" }
        if pet.energy < 20 { return "Уморен съм…" }
        return nil
    }

    func currentFace() -> Face {
        if pet.dead { return .dead }
        if pet.asleep { return .sleep }
        switch action {
        case .eat: return Int(time * 5) % 2 == 0 ? .eatOpen : .eatShut
        case .play, .love, .pill: return .happy
        case .none: break
        }
        if isDragging { return .happy }
        if pet.health < 40 { return .sick }
        if pet.fullness < 25 || pet.fun < 25 { return .sad }
        return time < blinkUntil ? .blink : .normal
    }

    func updateWalk() {
        guard wander, !pet.dead, !pet.asleep, !isDragging, action == .none,
              let screen = window.screen ?? NSScreen.main else {
            walking = false
            return
        }
        let vf = screen.visibleFrame
        var origin = window.frame.origin
        if walkTarget == nil {
            walking = false
            if Double.random(in: 0..<1) < 0.006 {
                let target = origin.x + CGFloat.random(in: -220...220)
                walkTarget = min(max(target, vf.minX), vf.maxX - PetView.size.width)
            }
            return
        }
        guard let target = walkTarget else { return }
        let step: CGFloat = 2
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
        o.x = min(max(o.x, vf.minX), vf.maxX - PetView.size.width)
        o.y = min(max(o.y, vf.minY), vf.maxY - PetView.size.height)
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

    func petIt() {
        if pet.dead { say("…", seconds: 1.5); return }
        if pet.asleep { say("Zzz…", seconds: 1.5); return }
        pet.fun = (pet.fun + 4).clamped()
        start(.love, length: 1.6)
        if Bool.random() { say(["♥", "Хи-хи!", "Обичам те!", "Още!"].randomElement()!, seconds: 1.5) }
    }

    @objc func feed() {
        guard checkAwake() else { return }
        if pet.fullness > 90 {
            pet.health = (pet.health - 5).clamped()
            say("Преядох! 🤢", seconds: 2.5)
        } else {
            say("Ням-ням!", seconds: 2)
        }
        pet.fullness = (pet.fullness + 25).clamped()
        start(.eat)
        save()
    }

    @objc func play() {
        guard checkAwake() else { return }
        if pet.energy < 15 { say("Нямам сили…", seconds: 2.5); return }
        pet.fun = (pet.fun + 20).clamped()
        pet.energy = (pet.energy - 8).clamped()
        start(.play, length: 3)
        say("Йееей!", seconds: 2)
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

    @objc func toggleBars() { showBars.toggle() }

    @objc func callHome() {
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
        window.setFrameOrigin(NSPoint(x: vf.maxX - PetView.size.width - 40, y: vf.minY))
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
            say("Здрасти! 👋", seconds: 3)
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

        let state = pet.dead ? "👻 отиде си" : (pet.asleep ? "💤 спи" : (currentNeed() ?? "😊 добре е"))
        item("\(pet.name) · \(pet.ageText) · \(state)", nil)
        item("🍎 Ситост   \(bar(pet.fullness))", nil)
        item("🎈 Радост    \(bar(pet.fun))", nil)
        item("⚡ Енергия  \(bar(pet.energy))", nil)
        item("❤️ Здраве    \(bar(pet.health))", nil)
        menu.addItem(.separator())

        if pet.dead {
            item("🥚 Ново животинче", #selector(newPet))
        } else {
            item("🍎 Нахрани", #selector(feed), enabled: !pet.asleep)
            item("⚽ Играй", #selector(play), enabled: !pet.asleep)
            item("💊 Дай лекарство", #selector(medicine), enabled: !pet.asleep)
            item(pet.asleep ? "☀️ Събуди" : "🌙 Приспи", #selector(toggleSleep))
        }
        menu.addItem(.separator())
        menu.addItem(lookMenu())
        menu.addItem(.separator())
        item(window.isVisible ? "Скрий" : "Покажи", #selector(toggleWindow))
        item("Повикай в ъгъла", #selector(callHome))
        item("Разхожда се", #selector(toggleWander), on: wander)
        item("Показвай чертите винаги", #selector(toggleBars), on: showBars)
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
                matched = matched || hex == look.body
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
            for key in faceOrder { choice(m, faceItems[key]!.name, #selector(pickFace(_:)), key, on: look.face == key) }
        }
        group("На врата") { m in
            choice(m, "Без", #selector(pickNeck(_:)), "", on: look.neck.isEmpty)
            for key in neckOrder { choice(m, neckItems[key]!.name, #selector(pickNeck(_:)), key, on: look.neck == key) }
        }
        sub.addItem(.separator())
        let random = NSMenuItem(title: "🎲 Изненадай ме", action: #selector(randomLook), keyEquivalent: "")
        random.target = self
        sub.addItem(random)
        return root
    }

    func lookChanged() {
        saveLook()
        if !pet.dead && !pet.asleep {
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
        let target = Bundle.main.bundleURL
        if target.path.contains("/AppTranslocation/") {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Премести приложението в Applications"
            alert.informativeText = "Оттам ще може да се обновява само."
            alert.runModal()
            return
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
