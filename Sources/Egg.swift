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
    override func mouseDown(with event: NSEvent) { game?.openEggMenu() }
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
    static let size = NSSize(width: 120, height: 60)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.babyClicked() }
    override func rightMouseDown(with event: NSEvent) { game?.openBabyMenu() }

    override func draw(_ dirtyRect: NSRect) {
        guard let game, let k = game.babyInfo else { return }
        let t = game.time
        let s: CGFloat = 3
        let w = CGFloat(k.grid[0].count) * s, h = CGFloat(k.grid.count) * s
        let hop = walking && k.alive ? abs(CGFloat(sin(t * 10))) * 4 : 0
        let x = (bounds.width - w) / 2, y = bounds.height - h - 2 - hop
        drawGrid(k.grid, x: x, y: y, s: s, flip: !facingLeft, palette: game.color)
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
                say("Какво е това?! ЯЙЦЕ! Ще се грижа за него!", seconds: 4)
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
        // пада отгоре при появата
        if eggFallFrom != nil {
            var o = p.frame.origin
            o.y = max(vf.minY, o.y - CGFloat(500 * step))
            p.setFrameOrigin(o)
            if o.y <= vf.minY { eggFallFrom = nil; sfx("Tink") }
            return
        }
        // при тревога Пиксчо не го оставя: и то се скрива (не се вижда)
        p.alphaValue = hidePhase == .hidden || hidePhase == .peeking ? 0 : 1

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
        let m = NSEvent.mouseLocation
        let hit = NSRect(x: p.frame.midX - 18, y: p.frame.minY, width: 36, height: 28).contains(m)
        if p.ignoresMouseEvents == hit { p.ignoresMouseEvents = !hit }
        var o = p.frame.origin
        o.y = vf.minY
        p.alphaValue = hidePhase == .hidden || hidePhase == .peeking ? 0 : 1
        guard k.alive, !pet.asleep else { v.walking = false; p.setFrameOrigin(o); return }
        // при тревога бяга при Пиксчо; иначе ходи след него
        let behind: CGFloat = facingLeft ? 1 : -1
        let goal = hidePhase != .off ? pr.midX : pr.midX + behind * (pr.width / 2 + 40)
        let dx = goal - p.frame.midX
        v.walking = abs(dx) > 6
        if v.walking {
            v.facingLeft = dx < 0
            let sp = min(abs(dx), CGFloat((hidePhase != .off ? 500 : (abs(dx) > 250 ? 160 : 70)) * step))
            let nx = o.x + (dx > 0 ? sp : -sp)
            if hidePhase != .off || !buddyBlockedAt(nx + p.frame.width / 2 + (dx > 0 ? 10 : -10), vf.minY) { o.x = nx } else { v.walking = false }
        }
        p.setFrameOrigin(o)
        if time > nextBabySound {
            nextBabySound = time + Double.random(in: 2 * 60...5 * 60)
            babySay(k.sound, 2)
        }
    }

    func openBabyMenu() {
        guard let p = babyPanel else { return }
        var buttons = [
            MiniButton(icon: iconHug, label: "Погали", enabled: true, action: { [weak self] in self?.babyClicked() }),
            MiniButton(icon: iconSing, label: "Приспивна песен", enabled: babyAlive, action: { [weak self] in
                guard let self else { return }
                self.babySay("Ги… zzz", 3)
                if !self.pet.asleep { self.say("♪ Нани-на, малкото… ♪", seconds: 3) }
            }),
        ]
        if babyAlive {
            buttons.append(MiniButton(icon: iconTalk, label: "Смени името", enabled: true, action: { [weak self] in self?.askName("baby") }))
        }
        showMiniMenu(title: babyLabel.capitalized, stats: [], buttons: buttons, above: NSPoint(x: p.frame.midX, y: p.frame.minY + 30))
    }

    func babyClicked() {
        attentionToOthers()
        sfx("Purr")
        guard let k = babyInfo else { return }
        babyView?.heartsUntil = time + 1.5
        if k.alive { babySay(k.sound, 2) }
        else if !pet.asleep { say("Обичам те, \(babyLabel)… дори да си камък.", seconds: 2.5) }
    }

    /// Пусна пиксел върху бебето.
    func tryFeedBaby(_ food: FoodPixel) -> Bool {
        guard babyAlive, let p = babyPanel else { return false }
        let f = food.panel.frame
        guard p.frame.insetBy(dx: 30, dy: -10).contains(NSPoint(x: f.midX, y: f.midY)) else { return false }
        food.remove()
        foods.removeAll { $0 === food }
        babyView?.heartsUntil = time + 2
        babySay("Ням! Ги-ги!", 2)
        sfx("Pop")
        return true
    }
}
