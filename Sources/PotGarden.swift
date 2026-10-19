// Градината: семена → нови саксийки с различни сортове (живеят няколко дни и си отиват),
// животинки (охлюв, катеричка, пеперуди), желанията на създанието и голямото му развитие.
// Част от нещата са тайни: не ги описвай в README.

import AppKit

let potSorts = ["red", "willow", "bonsai", "cactus", "sunflower"]
let potSortNames: [String: String] = ["red": "червенолистно", "willow": "върбичка", "bonsai": "бонзай", "cactus": "кактус",
                                      "sunflower": "слънчоглед", "oak": "малък дъб"]

final class ExtraPot {
    let id: String
    let sort: String
    let panel: NSPanel
    let view: ExtraPotView
    init(id: String, sort: String, panel: NSPanel, view: ExtraPotView) { self.id = id; self.sort = sort; self.panel = panel; self.view = view }
}

final class ExtraPotView: NSView {
    weak var game: PotGame?
    var potId = ""
    var sort = "red"
    let drag = Dragger()
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) { drag.dragged(window) }
    override func mouseUp(with event: NSEvent) {
        if drag.up() { game?.extraDropped(potId) } else { game?.waterExtra(potId) }
    }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game, let info = g.extraInfo(potId) else { return }
        let t = g.time
        let bottom = bounds.height - 2, mx = bounds.midX
        let growth = info["g"] as? Double ?? 0
        let water = info["w"] as? Double ?? 60
        let st = growth < 5 ? 0 : (growth < 20 ? 1 : (growth < 60 ? 2 : 3))
        let dry = water < 15
        // саксийка
        NSColor(hex: 0xb5651d).setFill(); NSRect(x: mx - 15, y: bottom - 18, width: 30, height: 18).fill()
        NSColor(hex: 0x8b4513).setFill(); NSRect(x: mx - 17, y: bottom - 21, width: 34, height: 5).fill()
        let soil = bottom - 20
        let green = NSColor(hex: dry ? 0x9c6644 : 0x52b788)
        let sway = CGFloat(sin(t * 1.4 + Double(potId.hashValue % 7))) * 1.5
        if st == 0 {
            green.setFill(); NSRect(x: mx - 1, y: soil - 6, width: 2, height: 6).fill()
            NSRect(x: mx - 5, y: soil - 8, width: 4, height: 3).fill(); NSRect(x: mx + 1, y: soil - 9, width: 4, height: 3).fill()
        } else {
            let h: CGFloat = st == 1 ? 18 : (st == 2 ? 34 : 50)
            switch sort {
            case "cactus":
                NSColor(hex: dry ? 0x9c6644 : 0x2d6a4f).setFill()
                NSRect(x: mx - 5, y: soil - h, width: 10, height: h).fill()
                if st >= 2 { NSRect(x: mx - 13, y: soil - h * 0.7, width: 8, height: 5).fill(); NSRect(x: mx - 13, y: soil - h * 0.7 - 10, width: 4, height: 10).fill()
                             NSRect(x: mx + 5, y: soil - h * 0.5, width: 8, height: 5).fill(); NSRect(x: mx + 9, y: soil - h * 0.5 - 8, width: 4, height: 8).fill() }
                if st == 3 { NSColor(hex: 0xff8fab).setFill(); NSRect(x: mx - 4, y: soil - h - 6, width: 8, height: 6).fill() }
            case "sunflower":
                green.setFill(); NSRect(x: mx - 1.5 + sway, y: soil - h, width: 3, height: h).fill()
                NSRect(x: mx - 9, y: soil - h * 0.5, width: 8, height: 4).fill()
                if st == 3 {
                    // гледа към мишката
                    let m = NSEvent.mouseLocation
                    let dir: CGFloat = (m.x > (window?.frame.midX ?? 0)) ? 4 : -4
                    NSColor(hex: 0xffd166).setFill(); NSRect(x: mx - 10 + dir, y: soil - h - 18, width: 20, height: 20).fill()
                    NSColor(hex: 0x7f5539).setFill(); NSRect(x: mx - 5 + dir * 1.4, y: soil - h - 13, width: 10, height: 10).fill()
                }
            case "willow":
                NSColor(hex: 0x7f5539).setFill(); NSRect(x: mx - 2, y: soil - h, width: 4, height: h).fill()
                green.setFill()
                for k in 0..<(st * 3) {
                    let x = mx - 14 + CGFloat(k) * 28 / CGFloat(max(1, st * 3 - 1))
                    NSRect(x: x + sway, y: soil - h, width: 2, height: h * 0.7).fill()
                }
            case "bonsai":
                NSColor(hex: 0x7f5539).setFill()
                NSRect(x: mx - 2, y: soil - h * 0.5, width: 4, height: h * 0.5).fill()
                NSRect(x: mx - 2, y: soil - h * 0.5, width: 10, height: 4).fill()
                NSRect(x: mx + 6, y: soil - h, width: 4, height: h * 0.5).fill()
                green.setFill()
                NSRect(x: mx - 10, y: soil - h * 0.65, width: 16, height: 6).fill()
                NSRect(x: mx, y: soil - h - 4, width: 18, height: 7).fill()
            case "oak":
                NSColor(hex: 0x7f5539).setFill(); NSRect(x: mx - 2, y: soil - h, width: 5, height: h).fill()
                green.setFill(); NSRect(x: mx - 12, y: soil - h - 10, width: 24, height: 14).fill()
                if st == 3 { NSColor(hex: 0x9c6644).setFill(); NSRect(x: mx + 6, y: soil - h, width: 4, height: 5).fill() }
            default: // red
                green.setFill(); NSRect(x: mx - 1.5 + sway, y: soil - h, width: 3, height: h).fill()
                NSColor(hex: dry ? 0x9c6644 : 0xc1121f).setFill()
                for k in 0..<(st + 1) {
                    let y = soil - h * (0.35 + 0.2 * CGFloat(k))
                    NSRect(x: mx - 11 + sway, y: y, width: 9, height: 5).fill(); NSRect(x: mx + 2 + sway, y: y - 3, width: 9, height: 5).fill()
                }
            }
        }
        if water < 25 && Int(t * 2) % 2 == 0 {
            NSColor(hex: 0x48cae4).setFill(); NSBezierPath(ovalIn: NSRect(x: mx + 18, y: soil - 6, width: 6, height: 8)).fill()
        }
    }
}

/// Семе на пода: цъкни го, за да го посадиш.
final class PotSeedView: NSView {
    weak var game: PotGame?
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.plantSeed() }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        let bob = CGFloat(sin(g.time * 3)) * 1.5
        NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: 4, y: bounds.height - 12 + bob, width: 10, height: 8).fill()
        NSColor(hex: 0xd4a373).setFill(); NSRect(x: 5.5, y: bounds.height - 10.5 + bob, width: 7, height: 5).fill()
        if Int(g.time * 2) % 3 == 0 { NSColor.white.setFill(); NSRect(x: 14, y: bounds.height - 16, width: 2, height: 2).fill() }
    }
}

/// Животинка на пода: охлюв или катеричка.
final class PotCritterView: NSView {
    weak var game: PotGame?
    var kind = "snail"
    var facingLeft = false
    var moving = false
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.critterClicked(kind) }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        let t = g.time
        let step = moving ? Int(t * 8) % 2 : 0
        let pic: Grid
        if kind == "snail" {
            pic = grid([
                "....KKK...",
                "...KMMMK..",
                "..KMKKMMK.",
                "..KMKMKMK.",
                "K.KMMKMMK.",
                "KYKKKKKKK.",
                ".KYYYYYYYK",
            ])
        } else {
            pic = grid([
                "OO........",
                "OOO..K.K..",
                "OOO.KOKOK.",
                ".OOKOWOKO.",
                "..OOOOOOK.",
                "...KOOOK..",
                step == 0 ? "...K.K.K.." : "..K..K..K.",
            ])
        }
        drawGrid(pic, x: bounds.midX - 15, y: bounds.height - 22, s: 3, flip: !facingLeft, palette: potColor)
    }
}

final class PotCritter {
    let kind: String
    let panel: NSPanel
    let view: PotCritterView
    var stage = 0          // 0 идва, 1 е при саксията, 2 си тръгва
    var stageAt: Double = 0
    let fromLeft: Bool
    init(kind: String, panel: NSPanel, view: PotCritterView, fromLeft: Bool) { self.kind = kind; self.panel = panel; self.view = view; self.fromLeft = fromLeft }
}

extension PotGame {
    // MARK: - допълнителни саксийки

    var extraPots: [[String: Any]] { get { d.array(forKey: "pot_extras") as? [[String: Any]] ?? [] } set { d.set(newValue, forKey: "pot_extras") } }
    func extraInfo(_ id: String) -> [String: Any]? { extraPots.first { $0["id"] as? String == id } }

    func setExtra(_ id: String, _ change: (inout [String: Any]) -> Void) {
        var all = extraPots
        guard let i = all.firstIndex(where: { $0["id"] as? String == id }) else { return }
        change(&all[i])
        extraPots = all
    }

    func syncExtraPanels() {
        let infos = extraPots
        // махнати
        for e in extraPanels where !infos.contains(where: { $0["id"] as? String == e.id }) { e.panel.orderOut(nil) }
        extraPanels.removeAll { e in !infos.contains(where: { $0["id"] as? String == e.id }) }
        let vf = screenFloor()
        for info in infos {
            guard let id = info["id"] as? String, !extraPanels.contains(where: { $0.id == id }) else { continue }
            let x = CGFloat(info["x"] as? Double ?? Double(vf.minX + 200))
            let p = overlayPanel(NSRect(x: x, y: vf.minY, width: 60, height: 100), key: false)
            p.level = .floating
            let v = ExtraPotView(frame: NSRect(x: 0, y: 0, width: 60, height: 100))
            v.game = self
            v.potId = id
            v.sort = info["sort"] as? String ?? "red"
            p.contentView = v
            fitScaled(p, NSSize(width: 60, height: 100))
            if !hidden { p.orderFrontRegardless() }
            extraPanels.append(ExtraPot(id: id, sort: v.sort, panel: p, view: v))
        }
    }

    func waterExtra(_ id: String) {
        setExtra(id) { $0["w"] = 100.0 }
        sfx("Bottle")
        if let e = extraPanels.first(where: { $0.id == id }) { _ = e }
        say("Полях и \(potSortNames[extraInfo(id)?["sort"] as? String ?? ""] ?? "малкото") в другата саксийка!", 2)
    }

    func extraDropped(_ id: String) {
        guard let e = extraPanels.first(where: { $0.id == id }) else { return }
        let vf = screenFloor()
        let x = min(max(e.panel.frame.minX, vf.minX), vf.maxX - e.panel.frame.width)
        e.panel.setFrameOrigin(NSPoint(x: x, y: vf.minY))
        setExtra(id) { $0["x"] = Double(x) }
    }

    func addExtraPot(sort: String, x: CGFloat) {
        guard extraPots.count < 2 else { return }
        let id = UUID().uuidString
        let life = Double.random(in: 2 * 86400...4 * 86400)
        extraPots = extraPots + [["id": id, "sort": sort, "g": 0.0, "w": 80.0, "x": Double(x), "leave": Date().addingTimeInterval(life).timeIntervalSince1970]]
        syncExtraPanels()
    }

    /// Всяка минута: малките саксийки растат, пият, а след няколко дни си отиват.
    func updateExtras() {
        var all = extraPots
        guard !all.isEmpty else { return }
        var leaving: [[String: Any]] = []
        for i in all.indices {
            var w = all[i]["w"] as? Double ?? 60
            var g = all[i]["g"] as? Double ?? 0
            w = max(0, w - 100.0 / 180)
            if w > 20 { g += 1 }
            all[i]["w"] = w; all[i]["g"] = g
            if Date().timeIntervalSince1970 > all[i]["leave"] as? Double ?? .greatestFiniteMagnitude && userActive { leaving.append(all[i]) }
        }
        for l in leaving {
            all.removeAll { $0["id"] as? String == l["id"] as? String }
            let name = potSortNames[l["sort"] as? String ?? ""] ?? "растението"
            let lines = ["Съседката мина и си взе \(name) — обеща да го гледа!",
                         "\(name.capitalizedFirst) пусна семена и отлетя с вятъра… Чао!",
                         "Една птичка отнесе \(name) да украси гнездото си!"]
            let line = lines.randomElement()!
            announce(line, 4)
            journal(line)
        }
        extraPots = all
        if !leaving.isEmpty { syncExtraPanels() }
        for e in extraPanels where frameCount % 2 == 0 { e.view.needsDisplay = true }
    }

    // MARK: - семена

    func updateSeeds() {
        guard stage >= 4, seedPanel == nil, extraPots.count < 2, userActive, time > nextSeed else { return }
        nextSeed = time + Double.random(in: 4 * 3600...8 * 3600)
        let vf = screenFloor()
        let side: CGFloat = Bool.random() ? 1 : -1
        let x = min(max(panel.frame.midX + side * (panel.frame.width / 2 + 90 * scale), vf.minX + 10), vf.maxX - 30)
        let p = overlayPanel(NSRect(x: x, y: vf.minY, width: 20, height: 20), key: false)
        p.level = .floating
        let v = PotSeedView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        seedPanel = p
        seedAt = time
        say("Пуснах СЕМЕ! Цъкни го, за да го посадиш!", 4)
    }

    func plantSeed() {
        guard let p = seedPanel else { return }
        p.orderOut(nil)
        seedPanel = nil
        let sort = potSorts.randomElement()!
        addExtraPot(sort: sort, x: p.frame.midX - 30)
        sfx("Pop")
        announce("Посадихме семето! Ще видим какво ще излезе…", 3)
        journal("Посадено семе: \(potSortNames[sort] ?? sort)")
    }

    func updateSeedLying() {
        if let p = seedPanel {
            p.contentView?.needsDisplay = true
            if time - seedAt > 3600 { p.orderOut(nil); seedPanel = nil; announce("Една птичка изкълва семето, което не посадихме.", 3) }
        }
    }

    // MARK: - животинки

    func updateCritters(_ dt: Double) {
        if let c = critter {
            c.view.needsDisplay = true
            let vf = screenFloor()
            var o = c.panel.frame.origin
            let target: CGFloat
            switch c.stage {
            case 0: target = panel.frame.midX + (c.fromLeft ? -1 : 1) * (panel.frame.width / 2 + 4) - c.panel.frame.width / 2
            case 1:
                target = o.x
                let stay: Double = c.kind == "snail" ? 15 * 60 : 6
                if c.kind == "snail" { health -= 1.5 / 60 * dt }       // гризе листата
                if time - c.stageAt > stay {
                    c.stage = 2; c.stageAt = time
                    if c.kind == "squirrel" { squirrelHidNut() }
                }
            default: target = c.fromLeft ? vf.minX - 60 : vf.maxX + 10
            }
            let dx = target - o.x
            let sp = CGFloat((c.kind == "snail" ? (c.stage == 2 ? 30 : 12) : 200) * dt)
            c.view.moving = abs(dx) > 1
            if abs(dx) > 1 { o.x += (dx > 0 ? 1 : -1) * min(abs(dx), sp); c.view.facingLeft = dx < 0; o.y = vf.minY; c.panel.setFrameOrigin(o) }
            else if c.stage == 0 {
                c.stage = 1; c.stageAt = time
                if c.kind == "snail" { say("Охлюв ми гризе листата! Махни го!", 3) }
                else { say("Катеричка рови в саксията ми!", 2.5); trimmingUntil = time + 4 }
            } else if c.stage == 2 { c.panel.orderOut(nil); critter = nil }
        }
        // идват понякога
        guard critter == nil, stage >= 2, userActive, hidePhase == 0, time > nextCritter else { return }
        nextCritter = time + Double.random(in: 50 * 60...110 * 60)
        let kind = Int.random(in: 0..<3)
        if kind == 2 && stage >= 3 {
            butterflies = (0..<Int.random(in: 2...4)).map { _ in Double.random(in: 0...6) }
            butterfliesUntil = time + 120
            say("Пеперуди! Колко са красиви!", 2.5)
            return
        }
        let k = kind == 0 ? "snail" : "squirrel"
        let fromLeft = Bool.random()
        let start = NSPoint(x: fromLeft ? vf0().minX - 40 : vf0().maxX, y: vf0().minY)
        let p = overlayPanel(NSRect(origin: start, size: NSSize(width: 40, height: 30)), key: false)
        p.level = .floating
        let v = PotCritterView(frame: NSRect(x: 0, y: 0, width: 40, height: 30))
        v.game = self
        v.kind = k
        p.contentView = v
        fitScaled(p, NSSize(width: 40, height: 30))
        p.orderFrontRegardless()
        critter = PotCritter(kind: k, panel: p, view: v, fromLeft: fromLeft)
    }

    func vf0() -> NSRect { screenFloor() }

    func critterClicked(_ kind: String) {
        guard let c = critter else { return }
        if kind == "snail" && c.stage < 2 {
            c.stage = 2; c.stageAt = time
            sfx("Pop")
            say("Махнах охлюва! Листата ми са спасени.", 2.5)
        } else if kind == "squirrel" {
            say("Катеричката: „Чик-чирик! Не ме гледай!“", 2)
        }
    }

    /// Катеричката зарови лешник. (Тайно: след седмица от него може да поникне нещо.)
    func squirrelHidNut() {
        var nuts = d.array(forKey: "pot_nuts") as? [Double] ?? []
        nuts.append(Date().timeIntervalSince1970)
        d.set(nuts, forKey: "pot_nuts")
        announce("Катеричката зарови нещо в саксията и избяга…", 3)
    }

    func updateNuts() {
        var nuts = d.array(forKey: "pot_nuts") as? [Double] ?? []
        guard let first = nuts.first, Date().timeIntervalSince1970 - first > 7 * 86400, extraPots.count < 2, userActive else { return }
        nuts.removeFirst()
        d.set(nuts, forKey: "pot_nuts")
        addExtraPot(sort: "oak", x: panel.frame.maxX + 70 * scale)
        discover("oak", "От лешника на катеричката поникна дъбче")
        announce("От лешника, който катеричката зарови, поникна ДЪБЧЕ!", 4)
    }

    // MARK: - желанията на създанието

    func updateWishes() {
        guard creature != nil, !creatureAway else { creatureWish = nil; return }
        if let w = creatureWish, time > wishUntil {
            creatureWish = nil
            if w == "hide" { creatureHidden = false }
            creatureSay = "Хмпф…"; creatureSayUntil = time + 2
        }
        guard creatureWish == nil, userActive, hidePhase == 0, time > nextWish else { return }
        nextWish = time + Double.random(in: 20 * 60...40 * 60)
        let w = ["fruit", "pet", "hide"].randomElement()!
        creatureWish = w
        wishUntil = time + 5 * 60
        switch w {
        case "fruit": creatureSay = "Искам плод!"
        case "pet": creatureSay = "Погали ме!"
        default:
            creatureSay = "Криеница! Намери ме!"
            creatureHidden = true
        }
        creatureSayUntil = time + 4
    }

    func wishFulfilled(_ kind: String) {
        guard creatureWish == kind else { return }
        creatureWish = nil
        creatureHidden = false
        creatureGrow(10)
        lastCreatureLove = Date()
        creatureHeartsUntil = time + 3
        creatureSay = kind == "hide" ? "Намери ме! Ура!" : "Благодаря!"
        creatureSayUntil = time + 3
        sfx("Hero")
    }

    // MARK: - голямото развитие и тръгването

    /// Голямото създание лети из екрана; древното някой ден си тръгва да създаде свое царство.
    func updateCreatureJourney() {
        guard let c = creature else {
            // бившето създание идва на гости от своето царство
            if let former = d.string(forKey: "pot_former"), userActive, time > nextKingdomVisit,
               Date().timeIntervalSince(d.object(forKey: "pot_formerVisit") as? Date ?? .distantPast) > 3 * 86400 {
                nextKingdomVisit = time + 3600
                d.set(Date(), forKey: "pot_formerVisit")
                fruitsCollected += 10
                let name = PotCreature.find(former)?.name ?? "създанието"
                discover("kingdom", "\(name.capitalizedFirst) дойде на гости от своето царство")
                announce("\(name.capitalizedFirst) долетя от своето царство! Донесе 10 плода и прегърна саксията.", 5)
            }
            return
        }
        _ = c
        // лети из екрана (огромно и нагоре)
        if creatureStage >= 4 && !creatureAway && userActive && time > nextFlight && creatureWish == nil {
            nextFlight = time + Double.random(in: 20 * 60...45 * 60)
            flightUntil = time + 18
            announce("\(creatureName.capitalizedFirst) излетя да обиколи екрана!", 2.5)
        }
        // древното си тръгва
        if creatureStage >= 5 {
            if d.object(forKey: "pot_ancientAt") == nil { d.set(Date(), forKey: "pot_ancientAt") }
            if Date().timeIntervalSince(d.object(forKey: "pot_ancientAt") as? Date ?? Date()) > 2 * 86400 && userActive {
                let name = creatureName
                d.set(creature, forKey: "pot_former")
                d.set(Date(), forKey: "pot_formerVisit")
                creature = creature2
                creature2 = nil
                creatureXP = creature2XP
                creature2XP = 0
                lastCreatureLove = Date()
                d.removeObject(forKey: "pot_ancientAt")
                d.set(0, forKey: "pot_cAnn")
                hasNest = false
                discover("leave", "\(name.capitalizedFirst) отлетя да създаде свое царство")
                announce("\(name.capitalizedFirst) порасна толкова, че гнездото му отесня… Прегърна ме и отлетя да създаде СВОЕ ЦАРСТВО. Ще идва на гости!", 6)
            }
        }
    }

    var creatureAway: Bool { time < flightUntil }
}

/// Създанието лети из екрана (когато е огромно).
final class PotFlightView: NSView {
    weak var game: PotGame?
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game, let c = g.creature.flatMap({ PotCreature.find($0) }) else { return }
        let flap = CGFloat(sin(g.time * 12)) * 3
        drawGrid(c.pic, x: 10, y: 10 + flap, s: 5, flip: g.flightFacingLeft, palette: potColor)
    }
}

extension PotGame {
    func updateFlight() {
        if creatureAway {
            if flightPanel == nil {
                let p = overlayPanel(NSRect(x: panel.frame.midX, y: panel.frame.maxY, width: 70, height: 60), key: false)
                p.ignoresMouseEvents = true
                p.level = .floating
                let v = PotFlightView(frame: NSRect(x: 0, y: 0, width: 70, height: 60))
                v.game = self
                p.contentView = v
                p.orderFrontRegardless()
                flightPanel = p
            }
            guard let p = flightPanel else { return }
            let vf = screenFloor()
            let k = (18 - (flightUntil - time)) / 18          // 0…1
            let a = k * .pi * 2
            let cx = vf.midX, cy = vf.minY + vf.height * 0.55
            let x = cx + CGFloat(cos(a + .pi)) * vf.width * 0.4
            let y = cy + CGFloat(sin(a * 2)) * vf.height * 0.25
            flightFacingLeft = sin(a + .pi) > 0
            p.setFrameOrigin(NSPoint(x: x - 35, y: y))
            p.contentView?.needsDisplay = true
        } else if let p = flightPanel {
            p.orderOut(nil)
            flightPanel = nil
        }
    }
}
