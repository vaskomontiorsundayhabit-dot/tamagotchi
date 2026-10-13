// Развалените пиксели: компост и пикселно цвете, рециклиране за монети, охлювът ги яде,
// и игра „Мишена“ с бомбички от развалени пиксели. Плюс минималния режим.

import AppKit

/// Колко голямо е цветето на всеки етап: кълн → растение → цвете → храст → дърво (и дървото расте без край).
func plantSize(_ st: Int) -> NSSize {
    if st < 8 { return NSSize(width: 60, height: 90 + CGFloat(max(0, st - 3)) * 8) }
    if st < 15 { return NSSize(width: 70 + CGFloat(st - 8) * 8, height: 92 + CGFloat(st - 8) * 7) }
    let t = CGFloat(st - 15)
    let crown = min(36 + t * 3, 110)
    let trunk = min(50 + t * 10, 420)
    return NSSize(width: crown * 2 + 20, height: trunk + crown * 2 + 16)
}

func plantName(_ st: Int) -> String {
    st <= 0 ? "" : st == 1 ? "Кълн" : st == 2 ? "Растение" : st < 8 ? "Цвете" : st < 15 ? "Храст" : "Дърво"
}

/// „цветето“, „храстът“, „дървото“…
func plantDefinite(_ st: Int) -> String {
    st <= 1 ? "кълнът" : st == 2 ? "растението" : st < 8 ? "цветето" : st < 15 ? "храстът" : "дървото"
}

/// Броят на цветовете: колкото повече компост, толкова повече цъфти.
func plantBlossoms(_ st: Int) -> Int { st < 3 ? 0 : min(60, st - 2) }

private func plantHash(_ i: Int) -> Int {
    var x = UInt32(truncatingIfNeeded: i &* 2654435761 &+ 12345)
    x ^= x >> 13; x = x &* 0x5bd1e995; x ^= x >> 15
    return Int(x % 100000)
}

final class PlantView: NSView {
    weak var game: Game?
    let drag = Dragger()
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) { drag.dragged(window) }
    override func mouseUp(with event: NSEvent) {
        if drag.up() { game?.plantDropped() } else { game?.openPlantMenu() }
    }
    override func rightMouseDown(with event: NSEvent) { game?.openPlantMenu() }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let st = game.plantStage
        // при тревога му порастват крачета и бяга
        let legs = game.plantHiding
        let bottom = bounds.height - 2 - (legs ? 9 : 0)
        if legs {
            NSColor(hex: 0x5c3a1e).setFill()
            let ph = CGFloat(sin(game.time * 14)) * 3
            NSRect(x: bounds.midX - 9 + ph, y: bottom, width: 4, height: 9).fill()
            NSRect(x: bounds.midX + 5 - ph, y: bottom, width: 4, height: 9).fill()
            NSRect(x: bounds.midX - 11 + ph, y: bottom + 7, width: 7, height: 2).fill()
            NSRect(x: bounds.midX + 4 - ph, y: bottom + 7, width: 7, height: 2).fill()
        }
        let thirsty = game.plantWater < 20
        let leaf = NSColor(hex: 0x52b788).blended(withFraction: thirsty ? 0.45 : 0, of: NSColor(hex: 0x9c6644)) ?? NSColor(hex: 0x52b788)
        let leaf2 = NSColor(hex: 0x2d6a4f).blended(withFraction: thirsty ? 0.45 : 0, of: NSColor(hex: 0x9c6644)) ?? NSColor(hex: 0x2d6a4f)
        let sway = CGFloat(sin(game.time * 1.5)) * 2 + (thirsty ? 4 : 0)
        let mx = bounds.midX
        let petals = [0xff8fab, 0xffd166, 0xc77dff, 0xffffff, 0xe63946]
        func blossom(_ x: CGFloat, _ y: CGFloat, _ i: Int, _ s: CGFloat = 3) {
            NSColor(hex: petals[plantHash(i) % petals.count]).setFill()
            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                NSRect(x: x + CGFloat(dx) * s * 2 - s, y: y + CGFloat(dy) * s * 2 - s, width: s * 2, height: s * 2).fill()
            }
            NSColor(hex: 0xffd166).setFill()
            NSRect(x: x - s, y: y - s, width: s * 2, height: s * 2).fill()
        }
        // саксия (дървото е в земята)
        if st < 15 {
            let pw: CGFloat = st < 8 ? 28 : 40
            NSColor(hex: 0x8b5a2b).setFill()
            NSRect(x: mx - pw / 2, y: bottom - 14, width: pw, height: 14).fill()
            NSColor(hex: 0x5c3a1e).setFill()
            NSRect(x: mx - pw / 2 - 2, y: bottom - 16, width: pw + 4, height: 4).fill()
        } else {
            NSColor(hex: 0x5c3a1e).setFill()
            NSRect(x: mx - 30, y: bottom - 6, width: 60, height: 6).fill()
            NSRect(x: mx - 20, y: bottom - 10, width: 40, height: 4).fill()
        }
        // капки, докато го полива
        if game.time < game.wateringUntil {
            NSColor(hex: 0x48cae4).setFill()
            for i in 0..<8 {
                let ph = CGFloat((game.time * 2 + Double(i) / 8).truncatingRemainder(dividingBy: 1))
                NSRect(x: mx - 14 + CGFloat(i) * 4, y: 6 + ph * (bottom - 26), width: 2, height: 4).fill()
            }
        }
        guard st > 0 else { return }
        if st < 8 {
            // стрък с листа и цветове по него
            let h = (st < 3 ? CGFloat([0, 12, 30][st]) : 48 + CGFloat(st - 3) * 8) * (thirsty ? 0.75 : 1)
            let base = bottom - 16
            leaf.setFill()
            NSRect(x: mx - 1.5 + sway / 2, y: base - h, width: 3, height: h).fill()
            if st >= 2 {
                NSRect(x: mx - 12 + sway, y: base - h * 0.6, width: 10, height: 5).fill()
                NSRect(x: mx + 2 + sway, y: base - h * 0.4, width: 10, height: 5).fill()
            }
            if st >= 3 {
                blossom(mx + sway, base - h - 4, 0)
                // всеки нов цвят: на клонче встрани
                for i in 1..<plantBlossoms(st) {
                    let side: CGFloat = i % 2 == 0 ? -1 : 1
                    let y = base - h * (0.85 - CGFloat(i - 1) * 0.16)
                    leaf.setFill()
                    NSRect(x: side > 0 ? mx + sway / 2 : mx - 12 + sway / 2, y: y, width: 12, height: 2).fill()
                    blossom(mx + side * 15 + sway * 0.7, y - 2, i, 2.5)
                }
            }
            return
        }
        // храст или корона на дърво: кълбо от пикселни листа
        let cell: CGFloat = 6
        var cx = mx + sway / 2, cy: CGFloat, rx: CGFloat, ry: CGFloat
        if st < 15 {
            rx = bounds.width / 2 - 6
            ry = (bottom - 14) / 2 - 4
            cy = bottom - 14 - ry
        } else {
            let t = CGFloat(st - 15)
            let crown = min(36 + t * 3, 110)
            let trunkH = min(50 + t * 10, 420)
            let tw = min(8 + t * 0.5, 22)
            NSColor(hex: 0x8b5a2b).setFill()
            NSRect(x: mx - tw / 2, y: bottom - 6 - trunkH - crown * 0.4, width: tw, height: trunkH + crown * 0.4).fill()
            NSColor(hex: 0x5c3a1e).setFill()
            NSRect(x: mx - tw / 2, y: bottom - 6 - trunkH - crown * 0.4, width: 3, height: trunkH + crown * 0.4).fill()
            rx = crown; ry = crown
            cy = bottom - 6 - trunkH - crown
            cx = mx + sway
        }
        var spots: [NSPoint] = []
        var i = 0
        var y = cy - ry
        while y < cy + ry {
            var x = cx - rx
            while x < cx + rx {
                let dx = (x + cell / 2 - cx) / rx, dy = (y + cell / 2 - cy) / ry
                if dx * dx + dy * dy <= 1 {
                    (plantHash(i) % 3 == 0 ? leaf2 : leaf).setFill()
                    NSRect(x: x, y: y, width: cell, height: cell).fill()
                    spots.append(NSPoint(x: x + cell / 2, y: y + cell / 2))
                }
                x += cell; i += 1
            }
            y += cell
        }
        if !spots.isEmpty {
            for n in 0..<plantBlossoms(st) {
                let p = spots[plantHash(n * 7 + 3) % spots.count]
                blossom(p.x, p.y, n, 2)
            }
        }
    }
}

final class TargetView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let c = NSPoint(x: bounds.midX, y: bounds.midY)
        for (i, col) in [0xe63946, 0xffffff, 0xe63946, 0xffffff, 0xe63946].enumerated() {
            let r = bounds.width / 2 - CGFloat(i) * 6 - 1
            NSColor(hex: col).setFill()
            NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)).fill()
        }
    }
}

extension Game {
    var minimalMode: Bool {
        get { UserDefaults.standard.bool(forKey: "minimalMode") }
        set { UserDefaults.standard.set(newValue, forKey: "minimalMode") }
    }

    @objc func toggleMinimal() {
        minimalMode.toggle()
        if minimalMode {
            bellPanel?.orderOut(nil); bellPanel = nil; bellView = nil
            closeWeather()
        } else {
            setUpBell()
        }
        say(minimalMode ? "Минимален режим: само най-важното на екрана." : "Всичко пак е на екрана!", seconds: 2.5)
    }

    var plantStage: Int {
        get { UserDefaults.standard.integer(forKey: "plantStage") }
        set { UserDefaults.standard.set(newValue, forKey: "plantStage") }
    }

    /// Пиксел в кофата: развалените стават компост; на всеки 10 — рециклиране за монети.
    func pixelBinned(spoiled: Bool) {
        let d = UserDefaults.standard
        let total = d.integer(forKey: "binned") + 1
        d.set(total, forKey: "binned")
        if total % 10 == 0 {
            earnCoins(5)
            if !pet.asleep { say("Рециклирах 10 пиксела! +5 монети", seconds: 2.5) }
        }
        if spoiled { addCompost(1) }
    }

    /// Компост за цветето: като се събере достатъчно, расте с един етап.
    func addCompost(_ n: Int) {
        let d = UserDefaults.standard
        let compost = d.integer(forKey: "compost") + n
        d.set(compost, forKey: "compost")
        if compost >= plantNeed {
            d.set(0, forKey: "compost")
            plantStage += 1
            let st = plantStage
            let line = st == 1 ? "От развалените пиксели поникна кълн!" : st == 2 ? "Компостът стана! Растението порасна!"
                : st == 3 ? "Цветето цъфна!" : st < 8 ? "Цветето пусна още един цвят!" : st == 8 ? "Цветето стана ХРАСТ!"
                : st < 15 ? "Храстът порасна и цъфна още!" : st == 15 ? "Храстът стана ДЪРВО!" : "Дървото порасна още!"
            if !pet.asleep { say(line, seconds: 3) }
            if st == 8 || st == 15 { confettiStart = time; sfx("Hero") }
        }
    }

    /// Колко развалени пиксела трябват за следващия етап (малко повече, колкото е по-голямо).
    var plantNeed: Int { plantStage < 3 ? 3 : min(10, 3 + (plantStage - 3) / 3) }

    /// Цветето: расте от компоста без край; колкото повече цветове, толкова по-често дава пиксел-плод.
    func updatePlant() {
        let show = plantStage > 0 && window.isVisible && !minimalMode
        if !show { plantPanel?.orderOut(nil); plantPanel = nil; return }
        var vf = NSScreen.main?.visibleFrame ?? .zero
        if plantPanel == nil {
            let s = plantSize(plantStage)
            var x = vf.minX + 340
            if let saved = UserDefaults.standard.object(forKey: "plantX") as? Double { x = CGFloat(saved) }
            else { UserDefaults.standard.set(Double(x), forKey: "plantX") }
            // на екрана, на който е оставено (ако го няма, на главния)
            if let sc = NSScreen.screens.first(where: { x + 25 >= $0.frame.minX && x + 25 < $0.frame.maxX }) { vf = sc.visibleFrame }
            x = min(max(x, vf.minX), vf.maxX - s.width)
            let p = overlayPanel(NSRect(x: x, y: vf.minY, width: s.width, height: s.height), key: false)
            p.level = .floating
            let v = PlantView(frame: NSRect(origin: .zero, size: s))
            v.autoresizingMask = [.width, .height]
            v.game = self
            p.contentView = v
            p.orderFrontRegardless()
            plantPanel = p
        }
        plantPanel?.contentView?.needsDisplay = true
        // порасло: прозорчето става по-голямо (стои на същото място)
        if let p = plantPanel, p.frame.size != plantSize(plantStage) {
            let ns = plantSize(plantStage)
            let sf = (screenAt(NSPoint(x: p.frame.midX, y: p.frame.minY + 5)) ?? NSScreen.main)?.visibleFrame ?? vf
            let x = min(max(p.frame.midX - ns.width / 2, sf.minX), sf.maxX - ns.width)
            p.setFrame(NSRect(x: x, y: p.frame.minY, width: ns.width, height: ns.height), display: true)
            UserDefaults.standard.set(Double(x), forKey: "plantX")
        }
        // тревога: порастват му крачета и бяга зад ръба; после се връща на мястото си
        if let p = plantPanel, let v = p.contentView as? PlantView, !v.drag.active,
           hidePhase != .off && hidePhase != .returning || plantHiding {
            let c = NSPoint(x: p.frame.midX, y: p.frame.minY + 10)
            let sc = screenAt(c) ?? NSScreen.main
            let svf = sc?.visibleFrame ?? vf
            var x = p.frame.minX
            if hidePhase != .off && hidePhase != .returning {
                if !plantHiding { plantHiding = true; p.contentView?.needsDisplay = true }
                let side = hideSide(x: p.frame.midX, screen: sc?.frame ?? svf)
                let goal = side.left ? svf.minX - p.frame.width - 10 : svf.maxX + 10
                x += (goal > x ? 1 : -1) * min(abs(goal - x), CGFloat(240 * (1.0 / 30)))
                if abs(goal - x) < 1 && p.alphaValue != 0 { p.alphaValue = 0 }
            } else {
                if p.alphaValue == 0 { p.alphaValue = 1 }
                let home = CGFloat(UserDefaults.standard.double(forKey: "plantX"))
                x += (home > x ? 1 : -1) * min(abs(home - x), CGFloat(120 * (1.0 / 30)))
                if abs(home - x) < 1 { plantHiding = false }
            }
            p.setFrameOrigin(NSPoint(x: x, y: svf.minY))
        } else if let p = plantPanel, let v = p.contentView as? PlantView, !v.drag.active {
            // пуснато във въздуха: пада обратно на пода
            let c = NSPoint(x: p.frame.midX, y: p.frame.minY + 10)
            let floorY = (screenAt(c) ?? NSScreen.main)?.visibleFrame.minY ?? p.frame.minY
            if p.frame.minY > floorY + 0.5 {
                plantFallSpeed = min(plantFallSpeed + 1.2, 30)
                p.setFrameOrigin(NSPoint(x: p.frame.minX, y: max(floorY, p.frame.minY - plantFallSpeed)))
            } else {
                plantFallSpeed = 0
                if p.frame.minY < floorY - 0.5 { p.setFrameOrigin(NSPoint(x: p.frame.minX, y: floorY)) }
            }
        }
        // вода: изсъхва бавно; дъждът го полива
        plantWater = max(0, plantWater - 1.0 / 30 / 180)
        if raining { plantWater = min(100, plantWater + 1.0 / 30 / 6) }
        if plantWater < 25 && time > nextPlantNag && !pet.asleep && hidePhase == .off {
            nextPlantNag = time + 10 * 60
            say("Цветето е жадно! Трябва да го полеем.", seconds: 3)
            if errands.isEmpty && !busyMoving && !pet.working && !playingGame && Int.random(in: 0..<3) > 0 { runErrands([.waterPlant]) }
        }
        let blossoms = Double(plantBlossoms(plantStage))
        let base: Double = plantWater > 50 ? 8 * 60 : (plantWater > 20 ? 15 * 60 : .greatestFiniteMagnitude)
        let fruitEvery = max(90, base / (1 + 0.15 * max(0, blossoms - 1)))
        let fresh = foods.filter { !$0.spoiled }.count
        if plantStage >= 3 && time > nextFruit && fresh < 14 && plantWater > 20, let p = plantPanel {
            nextFruit = time + fruitEvery
            let n = plantStage >= 15 && Bool.random() ? 2 : 1
            for _ in 0..<n {
                let fx = p.frame.minX + CGFloat.random(in: 10...max(11, p.frame.width - 30))
                let f = FoodPixel(color: foodColors.randomElement()!, at: NSPoint(x: fx, y: p.frame.maxY - 30), game: self)
                f.falls = true
                foods.append(f)
            }
            if !pet.asleep && Int.random(in: 0..<3) == 0 {
                say("\(plantDefinite(plantStage).capitalizedFirst) даде пиксел-плод!", seconds: 2.5)
            }
        }
    }

    var plantWater: Double {
        get { UserDefaults.standard.object(forKey: "plantWater") as? Double ?? 60 }
        set { UserDefaults.standard.set(min(100, max(0, newValue)), forKey: "plantWater") }
    }

    /// Цветето е преместено с мишката: помни мястото.
    func plantDropped() {
        guard let p = plantPanel else { return }
        let vf = (screenAt(NSPoint(x: p.frame.midX, y: p.frame.midY)) ?? NSScreen.main)?.visibleFrame ?? .zero
        let x = min(max(p.frame.minX, vf.minX), vf.maxX - p.frame.width)
        p.setFrameOrigin(NSPoint(x: x, y: max(p.frame.minY, vf.minY)))
        UserDefaults.standard.set(Double(x), forKey: "plantX")
    }

    func openPlantMenu() {
        guard let p = plantPanel else { return }
        let buttons = [
            MiniButton(icon: iconWater, label: "Полей", enabled: true, action: { [weak self] in
                guard let self else { return }
                if !self.pet.asleep && self.errands.isEmpty && !self.busyMoving && !self.monitorDetached {
                    self.runBreakErrands([.waterPlant])
                } else {
                    self.waterPlantNow()
                }
            }),
        ]
        let compost = Double(UserDefaults.standard.integer(forKey: "compost"))
        showMiniMenu(title: plantName(plantStage) + (plantStage >= 3 ? " · \(plantBlossoms(plantStage)) цв." : ""),
                     stats: [("Вода", plantWater / 100, 0x48cae4), ("Растеж", compost / Double(plantNeed), 0x52b788)],
                     buttons: buttons, above: NSPoint(x: p.frame.midX, y: p.frame.maxY))
    }

    func waterPlantNow() {
        plantWater = 100
        wateringUntil = time + 2.5
        sfx("Bottle")
    }

    /// Пиксчо отива до цветето и го полива.
    func updateWaterErrand(_ step: Double) {
        guard let p = plantPanel else { nextErrand(); return }
        switch errandStage {
        case 0:
            say("Отивам да полея цветето!", seconds: 2)
            errandStage = 1
        case 1:
            if walkTo(feet: NSPoint(x: p.frame.midX, y: p.frame.minY), speed: 280, step) {
                waterPlantNow()
                say(["Пий, цветенце!", "Ето ти водичка!", "Расти голямо!"].randomElement()!, seconds: 2)
                errandStage = 2
                errandStart = time
            }
        default:
            if time - errandStart > 2.5 { nextErrand() }
        }
    }

    // --- игра „Мишена“ ---

    @objc func toggleTargetGame() {
        if targetPanel != nil { endTargetGame(); return }
        guard checkAwake() else { return }
        clearForGame()
        let vf = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        let p = overlayPanel(NSRect(x: vf.midX, y: vf.midY + 100, width: 64, height: 64), key: false)
        p.level = .floating
        p.ignoresMouseEvents = true
        p.contentView = TargetView(frame: NSRect(x: 0, y: 0, width: 64, height: 64))
        p.orderFrontRegardless()
        targetPanel = p
        targetUntil = time + 60
        targetHits = 0
        targetDir = 1
        // бомбички: ако няма развалени пиксели, слага няколко
        let spoiled = foods.filter { $0.spoiled }.count
        for _ in 0..<max(0, 6 - spoiled) {
            let f = FoodPixel(color: 0x1a1a1a, at: NSPoint(x: CGFloat.random(in: (vf.minX + 60)...(vf.maxX - 90)),
                                                           y: CGFloat.random(in: (vf.minY + 40)...(vf.minY + 200))), game: self)
            f.spoiled = true
            foods.append(f)
        }
        say("Цъкай развалените пиксели — летят към мишената! 60 секунди!", seconds: 3.5)
    }

    func updateTargetGame(_ step: Double) {
        guard let p = targetPanel else { return }
        let vf = p.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var o = p.frame.origin
        o.x += targetDir * CGFloat(140 * step)
        if o.x < vf.minX + 20 || o.x > vf.maxX - 84 { targetDir = -targetDir }
        p.setFrameOrigin(o)
        var keep: [(FoodPixel, NSPoint, NSPoint, Double)] = []
        for (f, from, to, t0) in targetShots {
            let k = CGFloat(min(1, (time - t0) / 0.6))
            f.panel.setFrameOrigin(NSPoint(x: from.x + (to.x - from.x) * k, y: from.y + (to.y - from.y) * k + 120 * k * (1 - k)))
            if k >= 1 {
                let hit = p.frame.insetBy(dx: -6, dy: -6).contains(NSPoint(x: f.panel.frame.midX, y: f.panel.frame.midY))
                f.remove()
                if hit {
                    targetHits += 1
                    sfx("Glass", every: 0.1)
                    say(["БУМ! \(targetHits)", "В десетката! \(targetHits)", "Уцели! \(targetHits)"].randomElement()!, seconds: 1.2)
                } else {
                    say(["Мимо!", "Пропусна!", "Почти!"].randomElement()!, seconds: 1)
                }
            } else {
                keep.append((f, from, to, t0))
            }
        }
        targetShots = keep
        if time > targetUntil { endTargetGame() }
    }

    /// Клик върху развален пиксел по време на играта: лети към мишената.
    func shootAtTarget(_ food: FoodPixel) -> Bool {
        guard let p = targetPanel, food.spoiled else { return false }
        foods.removeAll { $0 === food }
        targetShots.append((food, food.panel.frame.origin, NSPoint(x: p.frame.midX - 15, y: p.frame.midY - 17), time))
        return true
    }

    func endTargetGame() {
        guard targetPanel != nil else { return }
        targetPanel?.orderOut(nil)
        targetPanel = nil
        targetShots.forEach { $0.0.remove() }
        targetShots.removeAll()
        pet.fun = (pet.fun + min(30, 5 + Double(targetHits) * 4)).clamped()
        addXP(targetHits * 3)
        say("Мишена: \(targetHits) попадения! +\(targetHits * 3) опит", seconds: 3)
        fulfill(.play)
    }
}
