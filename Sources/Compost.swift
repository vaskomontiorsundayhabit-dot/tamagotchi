// Развалените пиксели: компост и пикселно цвете, рециклиране за монети, охлювът ги яде,
// и игра „Мишена“ с бомбички от развалени пиксели. Плюс минималния режим.

import AppKit

final class PlantView: NSView {
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    let drag = Dragger()
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) { drag.dragged(window) }
    override func mouseUp(with event: NSEvent) {
        if drag.up() { game?.plantDropped() } else { game?.openPlantMenu() }
    }
    override func rightMouseDown(with event: NSEvent) { game?.openPlantMenu() }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let st = game.plantStage
        let bottom = bounds.height - 2
        // саксия
        NSColor(hex: 0x8b5a2b).setFill()
        NSRect(x: bounds.midX - 14, y: bottom - 14, width: 28, height: 14).fill()
        NSColor(hex: 0x5c3a1e).setFill()
        NSRect(x: bounds.midX - 16, y: bottom - 16, width: 32, height: 4).fill()
        // капки, докато го полива
        if game.time < game.wateringUntil {
            NSColor(hex: 0x48cae4).setFill()
            for i in 0..<6 {
                let ph = CGFloat((game.time * 2 + Double(i) / 6).truncatingRemainder(dividingBy: 1))
                NSRect(x: bounds.midX - 10 + CGFloat(i) * 4, y: 6 + ph * (bottom - 26), width: 2, height: 4).fill()
            }
        }
        guard st > 0 else { return }
        let h = CGFloat([0, 12, 30, 48][min(3, st)]) * (game.plantWater < 20 ? 0.75 : 1)
        let sway = CGFloat(sin(game.time * 1.5)) * 2 + (game.plantWater < 20 ? 6 : 0)
        NSColor(hex: 0x52b788).setFill()
        NSRect(x: bounds.midX - 1.5 + sway / 2, y: bottom - 16 - h, width: 3, height: h).fill()
        if st >= 2 {
            NSRect(x: bounds.midX - 12 + sway, y: bottom - 16 - h * 0.6, width: 10, height: 5).fill()
            NSRect(x: bounds.midX + 2 + sway, y: bottom - 16 - h * 0.4, width: 10, height: 5).fill()
        }
        if st >= 3 {
            let cx = bounds.midX + sway, cy = bottom - 20 - h
            NSColor(hex: 0xff8fab).setFill()
            for (dx, dy) in [(-6, 0), (6, 0), (0, -6), (0, 6)] { NSRect(x: cx + CGFloat(dx) - 3, y: cy + CGFloat(dy) - 3, width: 6, height: 6).fill() }
            NSColor(hex: 0xffd166).setFill()
            NSRect(x: cx - 3, y: cy - 3, width: 6, height: 6).fill()
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
        guard spoiled else { return }
        let compost = d.integer(forKey: "compost") + 1
        d.set(compost, forKey: "compost")
        if compost >= 3 && plantStage < 3 {
            d.set(0, forKey: "compost")
            plantStage += 1
            if !pet.asleep {
                say(["Компостът стана! Цветето порасна!", "От развалените пиксели расте цвете!", "Цветето цъфна!"][min(2, plantStage - 1)],
                    seconds: 3)
            }
        }
    }

    /// Цветето: расте от компоста; цъфнало, пуска пиксел-плод на всеки 15 минути.
    func updatePlant() {
        let show = plantStage > 0 && window.isVisible && !minimalMode
        if !show { plantPanel?.orderOut(nil); plantPanel = nil; return }
        var vf = NSScreen.main?.visibleFrame ?? .zero
        if plantPanel == nil {
            let s = NSSize(width: 50, height: 90)
            var x = vf.minX + 340
            if let saved = UserDefaults.standard.object(forKey: "plantX") as? Double { x = CGFloat(saved) }
            else { UserDefaults.standard.set(Double(x), forKey: "plantX") }
            // на екрана, на който е оставено (ако го няма, на главния)
            if let sc = NSScreen.screens.first(where: { x + 25 >= $0.frame.minX && x + 25 < $0.frame.maxX }) { vf = sc.visibleFrame }
            x = min(max(x, vf.minX), vf.maxX - s.width)
            let p = overlayPanel(NSRect(x: x, y: vf.minY, width: s.width, height: s.height), key: false)
            p.level = .floating
            let v = PlantView(frame: NSRect(origin: .zero, size: s))
            v.game = self
            p.contentView = v
            p.orderFrontRegardless()
            plantPanel = p
        }
        plantPanel?.contentView?.needsDisplay = true
        // пуснато във въздуха: пада обратно на пода
        if let p = plantPanel, let v = p.contentView as? PlantView, !v.drag.active {
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
        let fruitEvery: Double = plantWater > 50 ? 8 * 60 : (plantWater > 20 ? 15 * 60 : .greatestFiniteMagnitude)
        if plantStage >= 3 && time > nextFruit && foods.count < 10 && plantWater > 20, let p = plantPanel {
            nextFruit = time + fruitEvery
            let f = FoodPixel(color: foodColors.randomElement()!, at: NSPoint(x: p.frame.midX - 15, y: p.frame.maxY - 20), game: self)
            f.falls = true
            foods.append(f)
            if !pet.asleep { say("Цветето даде пиксел-плод!", seconds: 2.5) }
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
        showMiniMenu(title: ["", "Кълн", "Растение", "Цвете"][min(3, plantStage)],
                     stats: [("Вода", plantWater / 100, 0x48cae4), ("Растеж", Double(plantStage) / 3, 0x52b788)],
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
