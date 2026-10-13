// Пиксел яйцето: Пиксчо (и ти) се грижите за него; излюпва се, когато се събере достатъчно
// грижа (обикновено за 2-3 дни). Какво ще се излюпи се решава чак тогава.

import AppKit

let eggGrid = grid([
    "...KKKK...",
    "..KWWWWK..",
    ".KWWLWWWK.",
    ".KWWWWWWK.",
    "KWWWWWLWWK",
    "KWLWWWWWWK",
    "KWWWWWWWWK",
    "KWWWWLWWWK",
    "KWWWWWWWWK",
    ".KWWWWWWK.",
    ".KWWWWWWK.",
    "..KKKKKK..",
])

/// Бебетата: решетка, цвят и дали е живо.
let babyKinds: [(id: String, grid: Grid, alive: Bool, sound: String)] = [
    ("a", grid([
        "..K....K..",
        ".KGK..KGK.",
        "..KGGGGK..",
        ".KGWKGWKG.",
        "KGGGGGGGGK",
        "KGGYYYYGGK",
        ".KGGGGGGK.",
        "..KK..KK..",
    ]), true, "Пф-пф!"),
    ("b", grid([
        "...KKK....",
        "..KYYYK...",
        ".KYKYYYK..",
        ".KYYYYOOK.",
        "KYYYYYYK..",
        "KYYYYYYK..",
        ".KYYYYK...",
        "..O..O....",
    ]), true, "Пиу-пиу!"),
    ("c", grid([
        ".KK...KK..",
        ".KWK.KWK..",
        ".KWK.KWK..",
        "KWWWWWWWK.",
        "KWKWWWKWK.",
        "KWWWPWWWK.",
        ".KWWWWWK..",
        "..KK.KK...",
    ]), true, "Ши-ши!"),
    ("d", grid([
        "K.......K.",
        "KOK...KOK.",
        "KOOOOOOOK.",
        "KOKOOOKOK.",
        "KOOOPOOOK.",
        ".KOOOOOK..",
        ".KOOOOOKO.",
        "..KK.KK.O.",
    ]), true, "Мяу-у!"),
    ("e", grid([
        "..........",
        "...KKKK...",
        "..KGQGQK..",
        ".KQGQGQGK.",
        "KGKQGQGQKG",
        "KGGKKKKKKG",
        ".KG....GK.",
        "..........",
    ]), true, "Хм-хм."),
    ("f", grid([
        "..........",
        "...KKKK...",
        "..KYYWYK..",
        ".KYOYYYYK.",
        "KYYYYOYYYK",
        "KYOYYYYOYK",
        ".KKKKKKKK.",
        "..........",
    ]), false, ""),
]

final class EggView: NSView {
    weak var game: Game?
    static let size = NSSize(width: 64, height: 76)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    let drag = Dragger()
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) { if drag.dragged(window) { game?.eggHeld = true } }
    override func mouseUp(with event: NSEvent) {
        guard let game else { return }
        if drag.up() {
            game.eggHeld = false
            if let w = window {
                UserDefaults.standard.set(Double(w.frame.midX), forKey: "eggX")
                game.eggFallFrom = w.frame.minY
            }
        } else {
            game.openEggMenu()
        }
    }
    override func rightMouseDown(with event: NSEvent) { game?.openEggMenu() }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time
        let p = game.eggProgress
        var g = eggGrid
        // пукнатини с напредването
        if p > 0.6 { g[4][3] = "K"; g[5][4] = "K"; g[5][3] = "K" }
        if p > 0.85 { g[6][6] = "K"; g[7][5] = "K"; g[7][6] = "K"; g[3][5] = "K" }
        let wobble = p > 0.9 || t < game.eggTurnUntil ? CGFloat(sin(t * (t < game.eggTurnUntil ? 12 : 6))) * 0.12 : 0
        let cold = game.eggWarmth < 25
        let ctx = NSGraphicsContext.current
        ctx?.saveGraphicsState()
        let tr = NSAffineTransform()
        tr.translateX(by: bounds.midX, yBy: bounds.height - 6)
        tr.rotate(byRadians: wobble + (cold ? CGFloat(sin(t * 30)) * 0.03 : 0))
        tr.translateX(by: -bounds.midX, yBy: -(bounds.height - 6))
        tr.concat()
        drawGrid(g, x: (bounds.width - 40) / 2, y: bounds.height - 6 - 48, s: 4, palette: { c in
            switch c {
            case "W": return NSColor(hex: cold ? 0xd6ecff : 0xfff6dd)
            case "L": return NSColor(hex: 0xffca3a)
            default: return game.color(c)
            }
        })
        // мръсотия
        if game.eggDirty {
            NSColor(hex: 0x8b5a2b, alpha: 0.8).setFill()
            for (x, y) in [(22.0, 40.0), (36.0, 52.0), (28.0, 60.0)] { NSRect(x: x, y: y, width: 4, height: 3).fill() }
        }
        // одеалцето (вижда се, докато е топло)
        if game.eggBlanket {
            let x0 = (bounds.width - 40) / 2 - 4, y0 = bounds.height - 6 - 26
            for row in 0..<6 {
                for col in 0..<12 {
                    let c = (row / 2 + col / 3) % 2 == 0 ? 0xe63946 : 0xffd166
                    NSColor(hex: c).setFill()
                    NSRect(x: x0 + CGFloat(col) * 4, y: y0 + CGFloat(row) * 4, width: 4, height: 4).fill()
                }
            }
            NSColor(hex: 0x2b2b3a).setFill()
            NSRect(x: x0, y: y0 - 2, width: 48, height: 2).fill()
        }
        ctx?.restoreGraphicsState()
        // топло: пара; студено: снежинка
        if game.eggWarmth > 70 {
            NSColor(white: 1, alpha: 0.6).setFill()
            for i in 0..<3 {
                let ph = CGFloat((t * 0.7 + Double(i) / 3).truncatingRemainder(dividingBy: 1))
                NSRect(x: 22 + CGFloat(i) * 9, y: 18 - ph * 14, width: 2, height: 4).fill()
            }
        } else if cold {
            NSColor(hex: 0x5dade2).setFill()
            NSRect(x: 50, y: 14, width: 2, height: 8).fill(); NSRect(x: 47, y: 17, width: 8, height: 2).fill()
        }
        // ноти, докато му пее
        if t < game.eggSongUntil {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: 0xc77dff)]
            ("♪" as NSString).draw(at: NSPoint(x: 6 + CGFloat(sin(t * 3)) * 3, y: 6), withAttributes: a)
        }
        if game.eggHover {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .heavy),
                                                    .foregroundColor: NSColor.white]
            let s = "ЯЙЦЕ \(Int(p * 100))%" as NSString
            let sz = s.size(withAttributes: a)
            NSColor(hex: 0x1b1b24, alpha: 0.9).setFill()
            NSRect(x: (bounds.width - sz.width) / 2 - 3, y: 0, width: sz.width + 6, height: sz.height + 2).fill()
            s.draw(at: NSPoint(x: (bounds.width - sz.width) / 2, y: 1), withAttributes: a)
        }
    }
}

final class BabyView: NSView {
    weak var game: Game?
    var facingLeft = false
    var walking = false
    var text: String?
    var textUntil: Double = 0
    var heartsUntil: Double = 0
    static let size = NSSize(width: 130, height: 90)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    let drag = Dragger()
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) { if drag.dragged(window) { game?.babyHeld = true } }
    override func mouseUp(with event: NSEvent) {
        if drag.up() { game?.babyHeld = false } else { game?.babyClicked() }
    }
    override func rightMouseDown(with event: NSEvent) { game?.openBabyMenu() }

    var crying = false
    var imitateWork = false
    var dancing = false

    override func draw(_ dirtyRect: NSRect) {
        guard let game, let k = game.babyInfo else { return }
        let t = game.time
        // расте: бебе 3, малко 4, голямо 5 точки на квадратче
        let st = k.alive ? game.babyStage : 0
        let s = CGFloat(3 + st)
        let w = CGFloat(k.grid[0].count) * s, h = CGFloat(k.grid.count) * s
        var hop: CGFloat = 0
        if walking && k.alive { hop = abs(CGFloat(sin(t * (st == 0 ? 5 : 10)))) * (st == 0 ? 1.5 : 4) }
        if dancing && k.alive { hop = abs(CGFloat(sin(t * 8))) * 10 }
        if st == 2 && walking && Int(t / 3) % 4 == 0 { hop = abs(CGFloat(sin(t * 3.14))) * 14 }   // голямото подскача
        let x = (bounds.width - w) / 2, y = bounds.height - h - 2 - hop
        drawGrid(k.grid, x: x, y: y, s: s, flip: !facingLeft, palette: game.color)
        if imitateWork && k.alive {
            // мъничък монитор: „монтира“ като Пиксчо
            let mx = facingLeft ? x - 22 : x + w + 4
            NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: mx, y: bounds.height - 22, width: 18, height: 14).fill()
            NSColor(hex: Int(t * 3) % 2 == 0 ? 0x5dade2 : 0x48cae4).setFill(); NSRect(x: mx + 2, y: bounds.height - 20, width: 14, height: 9).fill()
            NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: mx + 7, y: bounds.height - 8, width: 4, height: 6).fill()
        }
        if crying && k.alive && !game.pet.asleep {
            // сълзички
            NSColor(hex: 0x48cae4).setFill()
            let ph = CGFloat((t * 2).truncatingRemainder(dividingBy: 1))
            NSRect(x: x + w * 0.3, y: y + h * 0.4 + ph * 10, width: 2, height: 3).fill()
            NSRect(x: x + w * 0.7, y: y + h * 0.4 + ph * 10, width: 2, height: 3).fill()
        }
        if game.pet.asleep && k.alive {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: 0x5dade2)]
            ("z" as NSString).draw(at: NSPoint(x: x + w + 2, y: y - 6 - CGFloat(Int(t) % 2) * 3), withAttributes: a)
        }
        if t < heartsUntil {
            drawGrid(heartGrid, x: bounds.midX - 7, y: y - 14 - CGFloat((heartsUntil - t).truncatingRemainder(dividingBy: 1)) * 6,
                     s: 2, palette: game.color)
        }
        if let text, t < textUntil { drawRatBubble(text, in: self, bottom: y - 2) }
    }
}

extension Game {
    // --- състояние (пази се между пусканията) ---

    var eggState: String {
        get { UserDefaults.standard.string(forKey: "eggState") ?? "none" }
        set { UserDefaults.standard.set(newValue, forKey: "eggState") }
    }
    var eggCare: Double {
        get { UserDefaults.standard.double(forKey: "eggCare") }
        set { UserDefaults.standard.set(newValue, forKey: "eggCare") }
    }
    var eggWarmth: Double {
        get { UserDefaults.standard.object(forKey: "eggWarmth") as? Double ?? 80 }
        set { UserDefaults.standard.set(min(100, max(0, newValue)), forKey: "eggWarmth") }
    }
    var eggDirty: Bool {
        get { UserDefaults.standard.bool(forKey: "eggDirty") }
        set { UserDefaults.standard.set(newValue, forKey: "eggDirty") }
    }
    var eggLaid: Date {
        get { UserDefaults.standard.object(forKey: "eggLaid") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "eggLaid") }
    }
    static let eggNeed: Double = 300
    var eggBlanket: Bool {
        get { UserDefaults.standard.bool(forKey: "eggBlanket") }
        set { UserDefaults.standard.set(newValue, forKey: "eggBlanket") }
    }
    var eggProgress: Double { min(1, eggCare / Game.eggNeed) }
    var eggHover: Bool { eggPanel?.frame.contains(NSEvent.mouseLocation) ?? false }

    var babyInfo: (id: String, grid: Grid, alive: Bool, sound: String)? {
        guard eggState == "hatched", let id = UserDefaults.standard.string(forKey: "babyKind") else { return nil }
        return babyKinds.first { $0.id == id }
    }
    var babyAlive: Bool { babyInfo?.alive ?? false }
    var babyName: String? { UserDefaults.standard.string(forKey: "babyName") }
    var babyLabel: String { babyName ?? (babyAlive ? "бебето" : "камъчето") }

    @objc func renameBaby() { if babyAlive { askName("baby") } }

    func babySay(_ text: String, _ seconds: Double) {
        babyView?.text = text
        babyView?.textUntil = time + seconds
    }

    // --- яйцето ---

    func updateEgg(_ step: Double) {
        let visible = window.isVisible && !pet.dead
        // бебето е пораснало (или го няма): след няколко дни идва ново яйце
        if eggState == "gone" {
            if Date() > (UserDefaults.standard.object(forKey: "nextEggDate") as? Date ?? .distantPast) {
                eggState = "none"
                UserDefaults.standard.set(true, forKey: "eggAgain")
            }
            return
        }
        if eggState == "none" {
            // появява се веднъж, след малко време буден
            if visible && time > 8 * 60 && !pet.asleep && hidePhase == .off {
                eggState = "egg"
                eggCare = 0
                eggWarmth = 80
                eggLaid = Date()
                let pr = petScreenRect()
                let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
                UserDefaults.standard.set(Double(min(max(pr.midX + 140, vf.minX + 40), vf.maxX - 100)), forKey: "eggX")
                eggFallFrom = vf.maxY
                start(.love, length: 2)
                say(UserDefaults.standard.bool(forKey: "eggAgain") ? "Ооо! Още едно яйце! Ще се грижа и за него!"
                    : "Какво е това?! ЯЙЦЕ! Ще се грижа за него!", seconds: 4)
                eggBlanket = false
                eggDirty = false
                sfx("Glass")
            }
            return
        }
        if eggState == "hatched" { updateBaby(step); return }
        guard visible else { eggPanel?.orderOut(nil); eggPanel = nil; return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let ex = CGFloat(UserDefaults.standard.double(forKey: "eggX"))
        if eggPanel == nil {
            let s = EggView.size
            let p = overlayPanel(NSRect(x: ex - s.width / 2, y: eggFallFrom ?? vf.minY, width: s.width, height: s.height), key: false)
            p.level = .floating
            let v = EggView(frame: NSRect(origin: .zero, size: s))
            v.game = self
            p.contentView = v
            p.orderFrontRegardless()
            eggPanel = p
        }
        guard let p = eggPanel else { return }
        p.contentView?.needsDisplay = true
        if eggHeld { return }
        // подът под самото яйце (на неговия екран) — никога не пада извън екрана
        let eggScreen = NSScreen.screens.first { $0.frame.minX <= p.frame.midX && $0.frame.maxX > p.frame.midX } ?? NSScreen.main
        let evf = eggScreen?.visibleFrame ?? vf
        if p.frame.midX < evf.minX + 20 || p.frame.midX > evf.maxX - 20 || p.frame.minY < evf.minY - 1 || p.frame.minY > evf.maxY {
            let nx = min(max(p.frame.midX, evf.minX + 40), evf.maxX - 40)
            p.setFrameOrigin(NSPoint(x: nx - p.frame.width / 2, y: max(evf.minY, min(p.frame.minY, evf.maxY - p.frame.height))))
            UserDefaults.standard.set(Double(nx), forKey: "eggX")
        }
        // пада (при появата или като го пуснеш)
        if eggFallFrom != nil || p.frame.minY > evf.minY + 1 {
            var o = p.frame.origin
            o.y = max(evf.minY, o.y - CGFloat(500 * step))
            p.setFrameOrigin(o)
            if o.y <= evf.minY { eggFallFrom = nil; sfx("Tink") }
            return
        }
        p.alphaValue = 1

        // топлината пада; мръсотия; стои топло → бавно трупа грижа
        let m = step / 60
        // под одеалцето изстива по-бавно; щом изстине, одеалцето е паднало
        eggWarmth -= (eggBlanket ? 0.4 : 0.8) * m
        if eggBlanket && eggWarmth < 40 { eggBlanket = false }
        if eggWarmth > 50 { eggCare += 0.2 * m }
        if eggWarmth < 20 { eggCare = max(0, eggCare - 0.1 * m) }
        if !eggDirty && Double.random(in: 0..<1) < step / 3600 { eggDirty = true }
        if eggWarmth < 25 && time > nextEggComplain && !pet.asleep && hidePhase == .off {
            nextEggComplain = time + 6 * 60
            say(["Яйцето е студено! Трябва да го стопля!", "Ох, яйцето трепери от студ!"].randomElement()!, seconds: 3)
            if errands.isEmpty && !playingGame && !monitorDetached { runBreakErrands([.eggCare]) }
        }
        // Пиксчо сам се грижи (понякога забравя)
        if time > nextEggCare && !pet.asleep && errands.isEmpty && !busyMoving && hidePhase == .off
            && questionPanel == nil && !playingGame && !monitorDetached {
            nextEggCare = time + Double.random(in: 12 * 60...25 * 60)
            if Int.random(in: 0..<100) >= 25 && (!pet.working || eggWarmth < 50) { runBreakErrands([.eggCare]) }
        }
        // излюпване
        let ageH = Date().timeIntervalSince(eggLaid) / 3600
        if eggCare >= Game.eggNeed && ageH >= 20 || ageH >= 96 && eggCare >= Game.eggNeed / 2 { hatchEgg() }
    }

    var eggSpot: NSPoint {
        guard let p = eggPanel else { return NSPoint(x: petScreenRect().midX, y: feetScreenY) }
        return NSPoint(x: p.frame.midX, y: p.frame.minY)
    }

    /// Пиксчо отива до яйцето и прави каквото му трябва.
    func updateEggErrand(_ step: Double) {
        guard eggState == "egg", eggPanel != nil else { nextErrand(); return }
        switch errandStage {
        case 0:
            say("Отивам да видя яйцето!", seconds: 2)
            errandStage = 1
        case 1:
            if walkTo(feet: eggSpot, speed: 280, step) {
                errandStage = 2
                errandStart = time
                let what: String
                if let w = pendingEggCare { what = w; pendingEggCare = nil }
                else if eggWarmth < 50 { what = "warm" } else if eggDirty { what = "clean" }
                else { what = ["turn", "talk", "sing", "warm"].randomElement()! }
                careForEgg(what, byPet: true)
            }
        default:
            if time - errandStart > 2.5 { nextErrand() }
        }
    }

    /// Грижа: стопли, обърни, почисти, говори, пей, завий.
    func careForEgg(_ what: String, byPet: Bool) {
        guard eggState == "egg" else { return }
        let cooldowns: [String: Double] = ["warm": 3 * 60, "turn": 10 * 60, "clean": 60, "talk": 5 * 60, "sing": 5 * 60, "blanket": 20 * 60]
        if let last = eggCareTimes[what], time - last < cooldowns[what] ?? 60 {
            say(["Вече го направих преди малко.", "Яйцето е добре засега!", "Чакай малко, не прекалявай!"].randomElement()!, seconds: 2)
            return
        }
        eggCareTimes[what] = time
        let quiet = pet.asleep || !byPet && hidePhase != .off
        if quiet {
            // спи: ти се грижиш тихо
            switch what {
            case "warm": eggWarmth += 40
            case "turn": eggTurnUntil = time + 1.5
            case "clean": eggDirty = false
            case "sing": eggSongUntil = time + 4
            case "blanket": eggWarmth = 100; eggBlanket = true
            default: break
            }
            eggCare += 3
            return
        }
        var points: Double = 3
        switch what {
        case "warm":
            eggWarmth += 40
            points = 5
            start(.love, length: 2)
            say(["Гуш-гуш, топло ли ти е?", "Стоплям те, малко яйце!", "Сядам до теб да ти е топло."].randomElement()!, seconds: 2.5)
        case "turn":
            eggTurnUntil = time + 1.5
            points = 4
            say(["Обръщам го внимателно…", "Хоп, на другата страна!"].randomElement()!, seconds: 2.5)
        case "clean":
            if !eggDirty { say("Чисто си е!", seconds: 2); return }
            eggDirty = false
            points = 4
            say("Лъсвам го да блести!", seconds: 2.5)
        case "talk":
            points = 3
            say(["Здравей, малкото! Аз съм \(pet.name)!", "Като се излюпиш, ще те науча да монтираш!",
                 "Чуваш ли ме там вътре?", "Навън е хубаво, излизай скоро!"].randomElement()!, seconds: 3)
        case "sing":
            eggSongUntil = time + 4
            points = 3
            say("♪ Нани-на, яйчице… ♪", seconds: 3)
        case "blanket":
            eggWarmth = 100
            eggBlanket = true
            points = 4
            say("Завивам го с одеалце.", seconds: 2.5)
        default:
            break
        }
        eggCare += points
        if !byPet { addXP(1) }
        if eggProgress > 0.6 && Int.random(in: 0..<4) == 0 {
            eggTurnUntil = time + 1
            sfx("Tink")
        }
    }

    func eggMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let ageH = Int(Date().timeIntervalSince(eggLaid) / 3600)
        let info = NSMenuItem(title: "Яйце · грижа \(Int(eggProgress * 100))% · топлина \(Int(eggWarmth))% · на \(ageH) ч", action: nil,
                              keyEquivalent: "")
        info.isEnabled = false
        menu.addItem(info)
        menu.addItem(.separator())
        for (title, code) in [("Стопли", "warm"), ("Обърни", "turn"), ("Почисти", "clean"), ("Говори му", "talk"), ("Пей му", "sing"),
                              ("Завий с одеалце", "blanket")] {
            let it = NSMenuItem(title: title, action: #selector(eggMenuAction(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = code
            it.isEnabled = code != "clean" || eggDirty
            menu.addItem(it)
        }
        return menu
    }

    func openEggMenu() {
        guard let p = eggPanel else { return }
        let ageH = Int(Date().timeIntervalSince(eggLaid) / 3600)
        let items: [(Grid, String, String)] = [(iconWarm, "Стопли", "warm"), (iconTurn, "Обърни", "turn"), (iconClean, "Почисти", "clean"),
                                               (iconTalk, "Говори му", "talk"), (iconSing, "Пей му", "sing"),
                                               (iconBlanket, eggBlanket ? "Махни одеалцето" : "Завий с одеалце",
                                                eggBlanket ? "unblanket" : "blanket")]
        let buttons = items.map { item in
            MiniButton(icon: item.0, label: item.1, enabled: item.2 != "clean" || eggDirty, action: { [weak self] in
                self?.requestEggCare(item.2)
            })
        }
        showMiniMenu(title: "Яйце · \(ageH) ч", stats: [("Грижа", eggProgress, 0xffd166), ("Топлина", eggWarmth / 100, 0xe63946)],
                     buttons: buttons, above: NSPoint(x: p.frame.midX, y: p.frame.maxY))
    }

    @objc func eggMenuAction(_ sender: NSMenuItem) {
        guard let what = sender.representedObject as? String else { return }
        requestEggCare(what)
    }

    func requestEggCare(_ what: String) {
        if what == "unblanket" {
            eggBlanket = false
            if !pet.asleep { say("Махнах одеалцето.", seconds: 2) }
            return
        }
        // Пиксчо отива до яйцето и го прави сам (ако може)
        if !pet.asleep && !pet.dead && hidePhase == .off && !playingGame && errands.isEmpty && !busyMoving && !monitorDetached {
            pendingEggCare = what
            if runBreakErrands([.eggCare]) { return }
            pendingEggCare = nil
        }
        careForEgg(what, byPet: false)
    }

    func hatchEgg() {
        guard eggState == "egg" else { return }
        let k = babyKinds.randomElement()!
        UserDefaults.standard.set(k.id, forKey: "babyKind")
        eggState = "hatched"
        babyBorn = Date()
        babyGrowth = 0
        babyFull = 80
        UserDefaults.standard.removeObject(forKey: "babyName")
        if let p = eggPanel { UserDefaults.standard.set(Double(p.frame.midX), forKey: "babyX") }
        eggPanel?.orderOut(nil)
        eggPanel = nil
        confettiStart = time
        sfx("Hero")
        start(.love, length: 3)
        if k.alive {
            say("ИЗЛЮПИ СЕ! Ооо, колко е сладко! Аз съм татко!", seconds: 4)
            photoMoment("hatch")
            nextNameAsk = time + 6
        } else {
            say("Излюпи се… камъче?! Златно камъче! Хм… пак ще го обичам.", seconds: 4.5)
            earnCoins(50)
        }
        addXP(50)
    }

    // --- бебето ---

    var babyGrowth: Double {
        get { UserDefaults.standard.double(forKey: "babyGrowth") }
        set { UserDefaults.standard.set(newValue, forKey: "babyGrowth") }
    }
    var babyFull: Double {
        get { UserDefaults.standard.object(forKey: "babyFull") as? Double ?? 80 }
        set { UserDefaults.standard.set(min(100, max(0, newValue)), forKey: "babyFull") }
    }
    var babyBorn: Date {
        get { UserDefaults.standard.object(forKey: "babyBorn") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "babyBorn") }
    }
    var babyJob: String? { UserDefaults.standard.string(forKey: "babyJob") }
    /// 0 бебе (пълзи), 1 малко (ходи), 2 голямо (тича, скача, говори).
    var babyStage: Int { babyGrowth < 30 ? 0 : (babyGrowth < 80 ? 1 : 2) }
    var babyAgeDays: Double { Date().timeIntervalSince(babyBorn) / 86400 }

    func growBaby(_ n: Double) {
        guard babyAlive else { return }
        let before = babyStage
        babyGrowth += n
        if babyStage > before { babyGrewUp() }
    }

    private func babyGrewUp() {
        confettiStart = time
        sfx("Hero")
        if babyStage == 1 {
            babySay("Ма-ма? Та-та?", 3)
            if !pet.asleep { say("\(babyLabel.capitalizedFirst) порасна! Вече не пълзи, а ходи!", seconds: 3.5) }
        } else {
            // първата дума: името на Пиксчо
            babySay("\(pet.name)!", 3)
            if !pet.asleep { say("Първата дума! Каза името ми! \(babyLabel.capitalizedFirst) вече е голямо!", seconds: 4) }
            photoMoment("hatch")
        }
    }

    func feedBaby(byPet: Bool) {
        babyFull += 40
        growBaby(6)
        babyView?.heartsUntil = time + 2
        babySay(babyStage == 2 ? "Ням! Благодаря!" : "Ням! Ги-ги!", 2)
        sfx("Pop")
    }

    func updateBaby(_ step: Double) {
        guard let k = babyInfo else { return }
        guard window.isVisible, !pet.dead else { babyPanel?.orderOut(nil); babyPanel = nil; babyView = nil; return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        if babyPanel == nil {
            let s = BabyView.size
            let x = CGFloat(UserDefaults.standard.object(forKey: "babyX") as? Double ?? Double(pr.midX + 100))
            let p = overlayPanel(NSRect(x: x - s.width / 2, y: vf.minY, width: s.width, height: s.height), key: false)
            p.level = .floating
            let v = BabyView(frame: NSRect(origin: .zero, size: s))
            v.game = self
            p.contentView = v
            p.orderFrontRegardless()
            babyPanel = p
            babyView = v
        }
        guard let p = babyPanel, let v = babyView else { return }
        v.needsDisplay = true
        let sc = CGFloat(3 + babyStage)
        let m = NSEvent.mouseLocation
        let hit = NSRect(x: p.frame.midX - 6 * sc, y: p.frame.minY, width: 12 * sc, height: 10 * sc).contains(m)
        setClickable(p, hit)
        if babyHeld { return }
        var o = p.frame.origin
        if o.y > vf.minY + 1 {
            o.y = max(vf.minY, o.y - CGFloat(800 * step))
            p.setFrameOrigin(o)
            return
        }
        o.y = vf.minY
        p.alphaValue = hidePhase == .hidden || hidePhase == .peeking ? 0 : 1
        if !k.alive { v.walking = false; p.setFrameOrigin(o); return }
        updateBabyLife(step)
        if pet.asleep { v.walking = false; p.setFrameOrigin(o); return }
        // при тревога бяга при Пиксчо; иначе ходи след него (или отива при плъха да си играят)
        let behind: CGFloat = facingLeft ? 1 : -1
        var goal = hidePhase != .off ? pr.midX : pr.midX + behind * (pr.width / 2 + 40)
        if time < babyPlayUntil, let rp = ratPanel, ratIsOut { goal = rp.frame.midX + 40 }
        let dx = goal - p.frame.midX
        v.walking = abs(dx) > 6
        if v.walking {
            v.facingLeft = dx < 0
            let slow: Double = [35, 70, 90][babyStage], fast: Double = [110, 160, 220][babyStage]
            let sp = min(abs(dx), CGFloat((hidePhase != .off ? 500 : (abs(dx) > 250 ? fast : slow)) * step))
            let nx = o.x + (dx > 0 ? sp : -sp)
            if hidePhase != .off || !buddyBlockedAt(nx + p.frame.width / 2 + (dx > 0 ? 10 : -10), vf.minY) { o.x = nx } else { v.walking = false }
        }
        p.setFrameOrigin(o)
        if time > nextBabySound {
            nextBabySound = time + Double.random(in: 2 * 60...5 * 60)
            let words = babyStage == 0 ? [k.sound, "Агу!", "Ги-ги!"]
                : babyStage == 1 ? [k.sound, "Ма-ма?", "Та-та!", "Ам-ам!", "Пиксе!"]
                : ["\(pet.name)!", "Искам пиксел!", "Да играем!", "Гледай как скачам!", "Аз съм голям!", "Ти си най-добрият!"]
            babySay(words.randomElement()!, 2.5)
        }
    }

    /// Нуждите, ученето и игрите на бебето.
    private func updateBabyLife(_ step: Double) {
        guard let p = babyPanel, let v = babyView else { return }
        if UserDefaults.standard.object(forKey: "babyBorn") == nil { babyBorn = Date() }
        // огладнява (за около 8 часа); нахранено расте само по малко
        babyFull -= step * 100 / (8 * 3600)
        if babyFull > 40 { babyGrowTick += step; if babyGrowTick > 20 * 60 { babyGrowTick = 0; growBaby(1) } }
        if babyFull < 30 && time > nextBabyCry && !pet.asleep {
            nextBabyCry = time + 3 * 60
            babySay(babyStage == 2 ? "Гладен съм!" : "Уаа! Уаа!", 2.5)
            v.crying = true
            if errands.isEmpty && !busyMoving && hidePhase == .off && !playingGame && !monitorDetached && Int.random(in: 0..<4) > 0 {
                runBreakErrands([.feedPet("baby")])
            }
        }
        if babyFull >= 30 { v.crying = false }
        guard !pet.asleep, hidePhase == .off else { return }
        // подражава: като Пиксчо монтира, и то „монтира“ на мъничък монитор; като танцува, подскача
        v.imitateWork = pet.working && babyStage >= 1
        v.dancing = action == .wave || action == .love || time < babyDanceUntil
        // играе с плъха
        if babyStage >= 1 && time > nextBabyPlay {
            nextBabyPlay = time + Double.random(in: 4 * 60...8 * 60)
            if ratIsOut && !pet.working {
                babyPlayUntil = time + 15
                babySay("Хи-хи! \(ratLabel.capitalizedFirst)!", 2)
                ratSay("Цик! Малкото!", 1.5)
            } else if let o = buddies.filter({ !$0.leaving && !buddyAsleep($0) && !$0.working && $0.service == nil }).randomElement() {
                // приятелите го гледат (особено докато Пиксчо монтира)
                o.wanderX = p.frame.midX + 70
                o.nextWander = time + 40
                let lines: [String: String] = ["dancer": "Малкото, да потанцуваме!", "science": "Виж, мехурчета от колбата!",
                                               "music": "Ще ти изсвиря приспивна песен!", "chef": "Сготвих ти пюре от пиксели!",
                                               "photo": "Усмивка за снимка, малкото!", "gamer": "Искаш ли да натиснеш копчето?",
                                               "artist": "Ще ти нарисувам слънце!", "garden": "Да посадим семенце!",
                                               "post": "Нося ти картичка!", "detective": "Да търсим скрити пиксели!"]
                buddySay(o, pet.working ? "Аз ще гледам малкото, докато монтираш!" : (lines[o.kind.id] ?? "Здрасти, малкото!"), 3)
                babyDanceUntil = o.kind.id == "dancer" || o.kind.id == "music" ? time + 8 : 0
                v.heartsUntil = time + 3
                babySay("Хи-хи!", 2)
                growBaby(1)
            }
        }
        // голямото си избира професия и понякога изкарва монети
        if babyStage == 2 {
            if babyJob == nil && babyAgeDays >= 2 {
                let jobs = ["готвач", "музикант", "художник", "геймър", "фотограф", "градинар", "учен", "танцьор", "пощальон", "детектив", "монтажист"]
                let j = jobs.randomElement()!
                UserDefaults.standard.set(j, forKey: "babyJob")
                babySay("Като порасна, ще бъда \(j)!", 3.5)
                if !pet.asleep { say(j == "монтажист" ? "Монтажист като мен! Гордея се!" : "\(j.capitalizedFirst)! Браво, малкото!", seconds: 3) }
            }
            if let j = babyJob, time > nextBabyWork {
                nextBabyWork = time + 30 * 60
                earnCoins(5)
                babySay("Аз, малкият \(j), изкарах 5 монети!", 3)
            }
            // порасна съвсем: отива да живее самостоятелно (и после може да дойде ново яйце)
            if babyJob != nil && babyAgeDays >= 6 { babyMovesOut(); return }
        }
        // рожден ден всяка седмица
        let weeks = Int(babyAgeDays / 7)
        if weeks >= 1 && UserDefaults.standard.integer(forKey: "babyBirthdayWeeks") < weeks {
            UserDefaults.standard.set(weeks, forKey: "babyBirthdayWeeks")
            confettiStart = time
            sfx("Hero")
            say("Днес \(babyLabel) става на \(weeks) седмиц\(weeks == 1 ? "а" : "и")! Честит рожден ден!", seconds: 4)
            babySay("Торта!", 2.5)
            for b in buddies.prefix(3) { buddySay(b, "Честит рожден ден, \(babyLabel)!", 3) }
            photoMoment("hatch")
        }
        // умира от глад, ако дълго никой не го храни
        if babyFull <= 0 {
            if babyStarving == 0 { babyStarving = time }
            if time - babyStarving > 6 * 3600 { babyDies(); return }
        } else { babyStarving = 0 }
    }

    func babyMovesOut() {
        let name = babyLabel
        babySay("Пораснах! Отивам да живея сам. Ще ви идвам на гости!", 4)
        say("\(name.capitalizedFirst) порасна и тръгва по света… Ще ми липсваш!", seconds: 4)
        addMemorial("\(name.capitalizedFirst) порасна и отиде да живее самостоятелно (\(babyJob ?? "без професия"))")
        if let p = babyPanel { spawnGhost(at: NSPoint(x: p.frame.midX, y: p.frame.minY + 10), happy: true) }
        clearBaby(nextEggInDays: Double.random(in: 1...3))
    }

    func babyDies() {
        let name = babyLabel
        if let p = babyPanel { spawnGhost(at: NSPoint(x: p.frame.midX, y: p.frame.minY + 10), happy: false) }
        addMemorial("\(name.capitalizedFirst) почина от глад…")
        say("Не! \(name.capitalizedFirst)… Не го нахранихме навреме…", seconds: 4.5)
        pet.fun = (pet.fun - 30).clamped()
        clearBaby(nextEggInDays: Double.random(in: 2...4))
    }

    /// Махат се бебето и всичко за него; след няколко дни идва ново яйце.
    func clearBaby(nextEggInDays d: Double) {
        babyPanel?.orderOut(nil); babyPanel = nil; babyView = nil
        for k in ["babyKind", "babyName", "babyGrowth", "babyFull", "babyBorn", "babyJob", "babyBirthdayWeeks", "babyX",
                  "eggCare", "eggWarmth", "eggDirty", "eggBlanket"] {
            UserDefaults.standard.removeObject(forKey: k)
        }
        eggState = "gone"
        UserDefaults.standard.set(Date().addingTimeInterval(d * 86400), forKey: "nextEggDate")
    }

    func openBabyMenu() {
        guard let p = babyPanel else { return }
        var buttons = [
            MiniButton(icon: iconHug, label: "Погали", enabled: true, action: { [weak self] in self?.babyClicked() }),
        ]
        if babyAlive {
            buttons.append(MiniButton(icon: iconFood, label: "Нахрани", enabled: babyFull < 90, action: { [weak self] in
                guard let self else { return }
                if self.errands.isEmpty && !self.busyMoving && !self.pet.asleep && !self.monitorDetached {
                    self.runBreakErrands([.feedPet("baby")])
                } else { self.feedBaby(byPet: false) }
            }))
            buttons.append(MiniButton(icon: iconSing, label: "Приспивна песен", enabled: true, action: { [weak self] in
                guard let self else { return }
                self.babySay("Ги… zzz", 3)
                if !self.pet.asleep { self.say("♪ Нани-на, \(self.babyLabel)… ♪", seconds: 3) }
            }))
            buttons.append(MiniButton(icon: iconTalk, label: "Смени името", enabled: true, action: { [weak self] in self?.askName("baby") }))
        }
        let stageName = ["бебе", "малко", "голямо"][babyStage] + (babyJob.map { " · бъдещ \($0)" } ?? "")
        showMiniMenu(title: babyLabel.capitalized + " · " + stageName,
                     stats: babyAlive ? [("Ситост", babyFull / 100, 0xf4a261), ("Растеж", min(1, babyGrowth / 80), 0x52b788)] : [],
                     buttons: buttons, above: NSPoint(x: p.frame.midX, y: p.frame.minY + 30))
    }

    func babyClicked() {
        attentionToOthers()
        sfx("Purr")
        guard let k = babyInfo else { return }
        babyView?.heartsUntil = time + 1.5
        if k.alive {
            babySay(babyStage == 2 ? ["Обичам те!", "Хи-хи, гъдел!", "Още!"].randomElement()! : k.sound, 2)
            if time - lastBabyPet > 60 { lastBabyPet = time; growBaby(2) }
        } else {
            // камъчето: понякога от обичта оживява
            if Int.random(in: 0..<25) == 0, let alive = babyKinds.filter({ $0.alive }).randomElement() {
                UserDefaults.standard.set(alive.id, forKey: "babyKind")
                UserDefaults.standard.set(Date(), forKey: "babyBorn")
                confettiStart = time
                sfx("Hero")
                say("КАМЪЧЕТО ОЖИВЯ! От толкова обич!", seconds: 4)
                babySay(alive.sound, 2.5)
                nextNameAsk = time + 6
            } else if !pet.asleep { say("Обичам те, \(babyLabel)… дори да си камък.", seconds: 2.5) }
        }
    }

    /// Пусна пиксел върху бебето.
    func tryFeedBaby(_ food: FoodPixel) -> Bool {
        guard babyAlive, let p = babyPanel else { return false }
        let f = food.panel.frame
        guard p.frame.insetBy(dx: 30, dy: -10).contains(NSPoint(x: f.midX, y: f.midY)) else { return false }
        food.remove()
        foods.removeAll { $0 === food }
        feedBaby(byPet: false)
        return true
    }
}
