// Тайните на саксията (10). Не ги описвай в README: откриват се в играта.

import AppKit


/// Съперничката: друга саксия в другия край на екрана.
final class PotRivalView: NSView {
    weak var game: PotGame?
    var text: String?
    var textUntil: Double = 0
    var wilted = false
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        let b = bounds, bottom = b.height - 2, mx = b.midX
        NSColor(hex: 0x6c757d).setFill()
        NSRect(x: mx - 20, y: bottom - 24, width: 40, height: 24).fill()
        NSColor(hex: 0x495057).setFill()
        NSRect(x: mx - 23, y: bottom - 28, width: 46, height: 6).fill()
        let leaf = NSColor(hex: wilted ? 0x9c6644 : 0x80b918)
        leaf.setFill()
        let h: CGFloat = wilted ? 30 : 70
        let sway = wilted ? 10 : CGFloat(sin(g.time * 1.7)) * 2
        NSRect(x: mx - 1.5 + sway / 2, y: bottom - 28 - h, width: 3, height: h).fill()
        for i in 0..<3 {
            let y = bottom - 28 - h * (0.3 + 0.25 * CGFloat(i))
            NSRect(x: mx - 16 + sway, y: y, width: 14, height: 5).fill()
            NSRect(x: mx + 2 + sway, y: y - 4, width: 14, height: 5).fill()
        }
        if !wilted {
            NSColor(hex: 0xf72585).setFill()
            for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                NSRect(x: mx + sway + CGFloat(dx * 6) - 3, y: bottom - 34 - h + CGFloat(dy * 6) - 3, width: 6, height: 6).fill()
            }
            // нацупени очички
            NSColor.white.setFill()
            NSRect(x: mx - 10, y: bottom - 20, width: 7, height: 5).fill(); NSRect(x: mx + 3, y: bottom - 20, width: 7, height: 5).fill()
            NSColor(hex: 0x2b2b3a).setFill()
            NSRect(x: mx - 7, y: bottom - 19, width: 3, height: 3).fill(); NSRect(x: mx + 6, y: bottom - 19, width: 3, height: 3).fill()
            NSRect(x: mx - 11, y: bottom - 23, width: 8, height: 2).fill(); NSRect(x: mx + 3, y: bottom - 22, width: 8, height: 2).fill()
        }
        if let text, g.time < textUntil {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold), .foregroundColor: NSColor.white]
            let s = text.uppercased() as NSString
            let sz = s.boundingRect(with: NSSize(width: b.width - 10, height: 60), options: [.usesLineFragmentOrigin], attributes: a).size
            let r = NSRect(x: (b.width - sz.width - 12) / 2, y: 2, width: ceil(sz.width) + 12, height: ceil(sz.height) + 8)
            NSColor(hex: 0x7209b7, alpha: 0.95).setFill(); r.fill()
            s.draw(with: r.insetBy(dx: 6, dy: 4), options: [.usesLineFragmentOrigin], attributes: a)
        }
    }
}

/// Кралят на бурените: голям, иска много скубане.
final class PotWeedKingView: NSView {
    weak var game: PotGame?
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.hitWeedKing() }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        let h = bounds.height, w = bounds.width
        let shake = CGFloat(sin(g.time * 3)) * 3
        NSColor(hex: 0x386641).setFill()
        for i in 0..<7 {
            let x = 6 + CGFloat(i) * (w - 12) / 6
            let hh = h * (0.45 + 0.35 * CGFloat((i * 37) % 10) / 10)
            NSRect(x: x - 3 + shake * CGFloat(i % 2), y: h - hh, width: 6, height: hh).fill()
        }
        NSColor(hex: 0x6a994e).setFill()
        NSRect(x: w / 2 - 22, y: h - 44, width: 44, height: 44).fill()
        // корона
        NSColor(hex: 0xffd166).setFill()
        NSRect(x: w / 2 - 16, y: h - 54, width: 32, height: 8).fill()
        for i in 0..<3 { NSRect(x: w / 2 - 16 + CGFloat(i) * 13, y: h - 62, width: 6, height: 8).fill() }
        // зли очи
        NSColor(hex: 0xe63946).setFill()
        NSRect(x: w / 2 - 14, y: h - 34, width: 9, height: 6).fill(); NSRect(x: w / 2 + 5, y: h - 34, width: 9, height: 6).fill()
        NSColor(hex: 0x2b2b3a).setFill()
        NSRect(x: w / 2 - 12, y: h - 18, width: 24, height: 3).fill()
        // живот
        NSColor(hex: 0x3a3a50).setFill(); NSRect(x: 4, y: 2, width: w - 8, height: 4).fill()
        NSColor(hex: 0xe63946).setFill(); NSRect(x: 4, y: 2, width: (w - 8) * CGFloat(g.weedKingHP) / 12, height: 4).fill()
    }
}

final class PotFlashView: NSView {
    override func draw(_ dirtyRect: NSRect) { NSColor(white: 1, alpha: 0.75).setFill(); bounds.fill() }
}

extension PotGame {
    var secrets: [String] { get { d.stringArray(forKey: "pot_secrets") ?? [] } set { d.set(newValue, forKey: "pot_secrets") } }

    /// Открита тайна: в дневника със звездичка.
    func discover(_ id: String, _ text: String) {
        guard !secrets.contains(id) else { return }
        secrets = secrets + [id]
        journal("★ Тайна \(secrets.count): \(text)")
        sfx("Hero")
    }

    func dayKey(_ date: Date = Date()) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    /// Пълнолуние ли е (±1 ден)?
    var fullMoon: Bool {
        let known = Date(timeIntervalSince1970: 947182440)   // новолуние, 6 януари 2000
        let days = Date().timeIntervalSince(known) / 86400
        let phase = days.truncatingRemainder(dividingBy: 29.530588)
        return abs(phase - 14.77) < 1.2
    }

    var isNight: Bool {
        let h = Calendar.current.component(.hour, from: Date())
        return h >= 22 || h < 6
    }

    func updateSecrets() {
        guard time > nextSecretCheck, hidePhase == 0, !hidden, userActive else { return }
        nextSecretCheck = time + 5
        let hour = Calendar.current.component(.hour, from: Date())

        // 1. нощен крадец
        if hour < 5 && fruitsCollected >= 3 && visitor == nil && d.string(forKey: "pot_thiefNight") != dayKey() && Int.random(in: 0..<360) == 0 {
            d.set(dayKey(), forKey: "pot_thiefNight")
            startVisitor(.raccoon)
        }
        // 5. пълнолуние
        if fullMoon && isNight && stage >= 2 && !secrets.contains("moon") {
            discover("moon", "Пълнолуние: растението свети в сребро")
            announce("Луната е пълна… чувствам се… СРЕБЪРЕН!", 4)
            if creature != nil { creatureSay = "Ауууу!"; creatureSayUntil = time + 4 }
        }
        // 3. съперничка
        if rivalPanel == nil && stage >= 3 && Date().timeIntervalSince(d.object(forKey: "pot_rivalAt") as? Date ?? .distantPast) > 3 * 86400
            && Int.random(in: 0..<720) == 0 {
            d.set(Date(), forKey: "pot_rivalAt")
            startRival()
        }
        if rivalPanel != nil { updateRival() }
        // 4. кралят на бурените
        if weedKingPanel == nil && weedPanels.count >= 15 && Int.random(in: 0..<60) == 0 { spawnWeedKing() }
        // 7. мравешката царица: ако много пъти си гонил мравките
        if !antsAllies && !queenPresent && d.integer(forKey: "pot_shoo") >= 8 && stage >= 2 && Int.random(in: 0..<120) == 0 {
            queenPresent = true
            ants = (0..<12).map { _ in PotAnt(t: CGFloat.random(in: 0...0.3), side: Bool.random() ? -1 : 1, speed: CGFloat.random(in: 0.01...0.025)) }
            announce("МРАВЕШКАТА ЦАРИЦА дойде с цяла армия! „Стига сте гонили поданиците ми!“", 5)
        }
        if antsAllies && Date().timeIntervalSince(d.object(forKey: "pot_antGift") as? Date ?? .distantPast) > 3 * 3600 {
            d.set(Date(), forKey: "pot_antGift")
            fruitsCollected += 1
            announce("Мравките-съюзници донесоха плод в кофата!", 3)
        }
        // 8. влюбената пчела носи мед
        if loveBee && dayKey() != d.string(forKey: "pot_honeyDay") && stage >= 3 && Int.random(in: 0..<240) == 0 {
            d.set(dayKey(), forKey: "pot_honeyDay")
            fruitsCollected += 5
            loveBeeUntil = time + 60
            announce("Влюбената пчела ми донесе мед! (+5 в кофата)", 4)
        }
        // 9. птичката се връща и вижда кой се е излюпил
        if creature != nil && !secrets.contains("birdback") && visitor == nil && stage >= 4
            && Date().timeIntervalSince(d.object(forKey: "pot_hatchedAt") as? Date ?? Date()) > 6 * 3600 && Int.random(in: 0..<240) == 0 {
            birdReturning = true
            startVisitor(.bird)
        }
        // 10. мълния в дървото
        if stage >= 5 && !d.bool(forKey: "pot_scorched") && Int.random(in: 0..<2400) == 0 { lightning() }
        if d.bool(forKey: "pot_scorched") && !d.bool(forKey: "pot_rainbow")
            && Date().timeIntervalSince(d.object(forKey: "pot_scorchedAt") as? Date ?? Date()) > 4 * 3600 {
            d.set(true, forKey: "pot_rainbow")
            announce("От изгорялото място поникнаха ДЪГОВИ листа!", 4)
            journal("От изгорялото поникнаха дъгови листа")
        }
    }

    // --- 3. съперничката ---

    func startRival() {
        let vf = screenFloor()
        let left = panel.frame.midX > vf.midX
        let x = left ? vf.minX + 20 : vf.maxX - 140
        let p = overlayPanel(NSRect(x: x, y: vf.minY, width: 120, height: 170), key: false)
        p.ignoresMouseEvents = true
        p.level = .floating
        let v = PotRivalView(frame: NSRect(x: 0, y: 0, width: 120, height: 170))
        v.game = self
        p.contentView = v
        fitScaled(p, NSSize(width: 120, height: 170))
        p.orderFrontRegardless()
        rivalPanel = p
        rivalStep = 0
        rivalNext = time + 3
        announce("Кой е ТОВА?! Някаква друга саксия!", 3)
    }

    func updateRival() {
        guard let p = rivalPanel, let v = p.contentView as? PotRivalView else { return }
        v.needsDisplay = true
        guard time > rivalNext else { return }
        let iWin = stage >= 4
        let script: [(Bool, String)] = [
            (true, "Здрасти, кълнче. Аз съм най-красивото цвете на този екран."),
            (false, "Какво?! Тук живея АЗ!"),
            (true, "Пчелите вече идват при мен, миличко."),
            (false, iWin ? "Аз съм \(potStageNames[stage].lowercased())! Ти си просто стрък!" : "Само почакай да порасна…"),
            (true, iWin ? "Ох… не ми е добре… изсъхвам от срам…" : "Хи-хи! Довиждане, малко кълнче!"),
        ]
        if rivalStep < script.count {
            let (rival, line) = script[rivalStep]
            if rival { v.text = line; v.textUntil = time + 4.5 } else { announce(line, 4.5) }
            rivalStep += 1
            rivalNext = time + 5
            if rivalStep == script.count && iWin { v.wilted = true }
        } else {
            p.orderOut(nil)
            rivalPanel = nil
            if iWin {
                discover("rival", "Съперничката саксия изсъхна от срам")
                announce("Победих! Само аз съм цвете тук!", 3)
            } else {
                discover("rival", "Съперничката се подигра и открадна пчелите за ден")
                nextBees = time + 6 * 3600
                announce("Грр! Ще порасна и ще види тя!", 3)
            }
        }
    }

    // --- 4. кралят на бурените ---

    func spawnWeedKing() {
        guard let x = weedPanels.randomElement()?.frame.midX else { return }
        let vf = screenFloor()
        let p = overlayPanel(NSRect(x: x - 40, y: vf.minY, width: 80, height: 90), key: false)
        p.level = .floating
        let v = PotWeedKingView(frame: NSRect(x: 0, y: 0, width: 80, height: 90))
        v.game = self
        p.contentView = v
        fitScaled(p, NSSize(width: 80, height: 90))
        p.orderFrontRegardless()
        weedKingPanel = p
        weedKingHP = 12
        announce("КРАЛЯТ НА БУРЕНИТЕ! Скубни го много пъти!", 4)
    }

    func hitWeedKing() {
        weedKingHP -= 1
        sfx("Pop")
        if weedKingHP <= 0 {
            weedKingPanel?.orderOut(nil)
            weedKingPanel = nil
            pullAllFloorWeeds()
            discover("weedking", "Победи Краля на бурените")
            announce("Кралят падна! Всичките му бурени избягаха!", 4)
        } else if weedKingHP % 4 == 0 {
            announce(["Още! Държи се!", "Скубни го пак!", "Кралят пищи!"].randomElement()!, 1.5)
        }
    }

    // --- 7. мравешката царица ---

    func antsShooed(all: Bool) {
        d.set(d.integer(forKey: "pot_shoo") + 1, forKey: "pot_shoo")
        if queenPresent && ants.isEmpty {
            queenPresent = false
            antsAllies = true
            discover("queen", "Примирие с мравешката царица: мравките стават съюзници")
            announce("Царицата се предаде! Мравките вече ще ми носят плодове.", 4.5)
        }
    }

    // --- 6. гъбата ---

    func overwatered() {
        let n = d.integer(forKey: "pot_overwater") + 1
        d.set(n, forKey: "pot_overwater")
        if n >= 3 && !hasMushroom {
            hasMushroom = true
            announce("Ох… прекалено много вода… нещо поникна в саксията!", 3.5)
        }
    }

    func eatMushroom() {
        hasMushroom = false
        d.set(0, forKey: "pot_overwater")
        trippyUntil = time + 120
        sfx("Morse")
        discover("mushroom", "Странната гъба: виждаше всичко в цветове")
        announce("Уааа… виждам ЗВЕЗДИ… и цветове… и звуци…", 4)
    }

    // --- 8. влюбената пчела ---

    func beeCame(_ n: Int) {
        let total = d.integer(forKey: "pot_bees") + n
        d.set(total, forKey: "pot_bees")
        if total >= 12 && !loveBee && userActive {
            loveBee = true
            loveBeeUntil = time + 90
            discover("lovebee", "Една пчела се влюби в цветовете")
            announce("Тази пчела… ме гледа с ♥ в очите!", 4)
        }
    }

    // --- 10. мълния ---

    func lightning() {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSPoint(x: panel.frame.midX, y: panel.frame.midY)) }) ?? NSScreen.main else { return }
        let p = overlayPanel(screen.frame, key: false)
        p.ignoresMouseEvents = true
        p.contentView = PotFlashView(frame: NSRect(origin: .zero, size: screen.frame.size))
        p.orderFrontRegardless()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { p.orderOut(nil) }
        sfx("Basso")
        d.set(true, forKey: "pot_scorched")
        d.set(Date(), forKey: "pot_scorchedAt")
        health -= 25
        discover("lightning", "Мълния удари дървото")
        announce("БУУУМ! Мълния ме удари!!! Опърлих се!", 4.5)
    }

    // --- 2. и 9.: драмите при гостите ---

    func gardenerScandal() -> Bool {
        guard fruitsCollected >= 1, Int.random(in: 0..<4) == 0 else { return false }
        fruitsCollected -= 1
        discover("gardener", "Хвана градинаря да яде плод от кофата")
        announce("ЕЙ! Видях те как изяде плод от кофата ми! Скандал!", 4)
        return true
    }

    func birdBackScandal() {
        birdReturning = false
        discover("birdback", "Птичката се върна и видя кой се е излюпил")
        if Bool.random() {
            announce("Птичката: „ТОВА НЕ Е МОЕТО ДЕТЕ!!!“ … после го прегърна и снесе ново яйце.", 5)
            hasEgg = true
            eggCare = 30
            eggLaid = Date()
        } else {
            announce("Птичката: „Кой подмени яйцето ми?!“ И отлетя обидена.", 5)
        }
    }

    func raccoonFinished(caught: Bool) {
        if caught {
            discover("thief", "Хвана нощния крадец на плодове")
            announce("Хванах те, крадецо! Плодовете остават!", 3.5)
        } else {
            let n = min(2, fruitsCollected)
            fruitsCollected -= n
            discover("thief", "Нощен крадец отмъкна плодове")
            announce("Някой открадна \(n) плода от кофата! Видях опашка на райета!", 4)
        }
    }

    // --- рисуване на тайните (вика се от PotView) ---

    func secretLeafColor(_ base: NSColor, _ i: Int) -> NSColor {
        if time < trippyUntil {
            return NSColor(hue: CGFloat((time * 0.3 + Double(i % 17) / 17).truncatingRemainder(dividingBy: 1)), saturation: 0.7, brightness: 0.9, alpha: 1)
        }
        if d.bool(forKey: "pot_rainbow") && i % 9 == 0 {
            return NSColor(hue: CGFloat(i % 7) / 7, saturation: 0.6, brightness: 0.95, alpha: 1)
        }
        if lunar || fullMoon && isNight { return base.blended(withFraction: 0.45, of: NSColor(hex: 0xe0e1dd)) ?? base }
        return base
    }
}
