// Саксията: меню с грижите (карта), иконката горе, звънчето и бягането с крачета,
// гостите (градинар и птичка) и обновяването.

import AppKit

let potIconFert = grid(["..QQQQ..", ".QYQQYQ.", ".QQQQQQ.", ".QQYQQQ.", ".QQQQYQ.", ".QYQQQQ.", ".QQQQQQ.", "........"])
let potIconWeed = grid(["...G....", ".G.G..G.", ".G.G.G..", "..GGG...", "...G....", "KKKKKKKK", ".KQQQQK.", "..KKKK.."])
let potIconAnt = grid(["........", "K..K..K.", ".KK.KK..", "KKKKKKKK", ".KK.KK..", "K..K..K.", "........", "........"])
let potIconEgg = grid(["...WW...", "..WWWW..", ".WWCWWW.", ".WWWWCW.", ".WCWWWW.", "..WWWW..", "QQQQQQQQ", ".QQQQQQ."])
let potIconFruit = grid(["....G...", "...G....", "..RRRR..", ".RWRRRR.", ".RRRRRR.", ".RRRRRR.", "..RRRR..", "........"])
let potIconBook = grid(["KKKKKKK.", "KWWWWWK.", "KWKKKWK.", "KWWWWWK.", "KWKKKWK.", "KWWWWWK.", "KKKKKKK.", "........"])

struct PotButton {
    let icon: Grid
    let label: String
    let enabled: Bool
    let action: () -> Void
}

final class PotCardView: NSView {
    weak var game: PotGame?
    var buttons: [PotButton] = []
    var hover: Int?
    static let cell: CGFloat = 36

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil))
    }
    private var rowY: CGFloat { bounds.height - PotCardView.cell - 26 }
    private func rect(_ i: Int) -> NSRect {
        let start = (bounds.width - CGFloat(buttons.count) * PotCardView.cell) / 2
        return NSRect(x: start + CGFloat(i) * PotCardView.cell, y: rowY, width: PotCardView.cell, height: PotCardView.cell)
    }
    override func mouseMoved(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let h = buttons.indices.first { rect($0).contains(p) }
        if h != hover { hover = h; needsDisplay = true }
    }
    override func mouseExited(with event: NSEvent) { hover = nil; needsDisplay = true }
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        guard let i = buttons.indices.first(where: { rect($0).contains(p) }), buttons[i].enabled else { return }
        buttons[i].action()
        game?.refreshCard()
    }
    override func rightMouseDown(with event: NSEvent) { game?.closeCard() }

    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        let b = bounds
        NSColor(hex: 0x1d2d24, alpha: 0.97).setFill(); b.fill()
        NSColor(hex: 0x95d5b2).setFill()
        for r in [NSRect(x: 0, y: 0, width: b.width, height: 3), NSRect(x: 0, y: b.height - 3, width: b.width, height: 3),
                  NSRect(x: 0, y: 0, width: 3, height: b.height), NSRect(x: b.width - 3, y: 0, width: 3, height: b.height)] { r.fill() }
        let big: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy), .foregroundColor: NSColor.white]
        let small: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .heavy), .foregroundColor: NSColor(hex: 0xb7e4c7)]
        let st = g.stage
        let title = potStageNames[st].uppercased() + (st < 5 ? "" : " · ВИСОЧИНА \(Int(g.stageProgress * 100))%")
        (title as NSString).draw(at: NSPoint(x: 12, y: 11), withAttributes: big)
        let next = st < potThresholds.count - 1 ? "ДО „\(potStageNames[st + 1].uppercased())“" : "РАСТЕ НА ВИСОЧИНА"
        let bars: [(String, Double, Int)] = [("ВОДА", g.water / 100, 0x48cae4), ("ЗДРАВЕ", g.health / 100, 0xff8fab),
                                             (next, g.stageProgress, 0x52b788)] + (st >= 4 ? [("РАЗРОШЕН", g.overgrowth / 100, 0xf4a261)] : [])
        for (i, bar) in bars.enumerated() {
            let y = 32 + CGFloat(i) * 15
            (bar.0 as NSString).draw(at: NSPoint(x: 12, y: y), withAttributes: small)
            let r = NSRect(x: 118, y: y + 2, width: b.width - 130, height: 7)
            NSColor(hex: 0x2d4a3a).setFill(); r.fill()
            NSColor(hex: bar.2).setFill(); NSRect(x: r.minX, y: r.minY, width: r.width * CGFloat(max(0, min(1, bar.1))), height: r.height).fill()
        }
        var info = "ПЛОДОВЕ: \(g.fruitsCollected)"
        if Date() < g.fertUntil { info += " · ТОР: ДВОЕН РАСТЕЖ" }
        if g.weedsCount > 0 { info += " · БУРЕНИ: \(g.weedsCount)" }
        if !g.ants.isEmpty { info += " · МРАВКИ: \(g.ants.count)" }
        if g.hasEgg { info += " · ЯЙЦЕ: \(Int(g.eggCare))%" }
        if !g.weedPanels.isEmpty { info += " · БУРЕНИ ПО ПОДА: \(g.weedPanels.count)" }
        (info as NSString).draw(at: NSPoint(x: 12, y: 32 + CGFloat(bars.count) * 15 + 2), withAttributes: small)
        for (i, btn) in buttons.enumerated() {
            let r = rect(i)
            if hover == i && btn.enabled { NSColor(hex: 0x2d4a3a).setFill(); r.insetBy(dx: 2, dy: 2).fill() }
            let pal: (Character) -> NSColor? = btn.enabled ? { c in potColor(c) } : { c in potColor(c) == nil ? nil : NSColor(hex: 0x40594b) }
            drawGrid(btn.icon, x: r.midX - 12, y: r.midY - 12, s: 3, palette: pal)
        }
        let label = hover.map { buttons[$0].label.uppercased() } ?? "ДЕСЕН БУТОН: ЗАТВОРИ"
        let la: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 10, weight: .heavy),
                                                 .foregroundColor: hover == nil ? NSColor(hex: 0x95d5b2) : NSColor.white]
        let ls = label as NSString
        let sz = ls.size(withAttributes: la)
        ls.draw(at: NSPoint(x: (b.width - sz.width) / 2, y: b.height - 20), withAttributes: la)
    }
}

/// Звънчето за тревога.
final class PotBellView: NSView {
    weak var game: PotGame?
    let drag = Dragger()
    var ringAt: Double = -10
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) { drag.dragged(window) }
    override func mouseUp(with event: NSEvent) {
        if drag.up() { game?.bellDropped() } else { ringAt = game?.time ?? 0; game?.ringBell() }
    }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let shake = game.time - ringAt < 1 ? CGFloat(sin(game.time * 40)) * 4 : 0
        let g = grid(["...KK...", "..KYYK..", ".KYYYYK.", ".KYYWYK.", ".KYYYYK.", "KYYYYYYK", "KKKKKKKK", "...KK..."])
        drawGrid(g, x: bounds.midX - 12 + shake, y: 4, s: 3, palette: potColor)
    }
}

/// Гост: градинар (подрязва храста) или птичка (прави гнездо и снася яйце).
enum PotVisitorKind { case gardener, bird, raccoon, pixcho, hen }

final class PotVisitor {
    let kind: PotVisitorKind
    let panel: NSPanel
    let view: PotVisitorView
    var stage = 0          // 0 идва, 1 работи, 2 си тръгва
    var stageAt: Double = 0
    var fromLeft: Bool
    init(kind: PotVisitorKind, panel: NSPanel, view: PotVisitorView, fromLeft: Bool) {
        self.kind = kind; self.panel = panel; self.view = view; self.fromLeft = fromLeft
    }
}

final class PotVisitorView: NSView {
    weak var game: PotGame?
    var kind = PotVisitorKind.gardener
    var facingLeft = false
    var moving = false
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { if kind == .raccoon { game?.caughtRaccoon() } }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time
        if kind == .pixcho {
            let step = moving ? Int(t * 8) % 2 : 0
            let g = grid([
                ".KKKKKKKK.",
                ".KYYYYYYK.",
                ".KYKYYKYK.",
                ".KYYYYYYK.",
                ".KYYKKYYK.",
                ".KYYYYYYK.",
                ".KKKKKKKK.",
                step == 0 ? "..K....K.." : ".K......K.",
            ])
            drawGrid(g, x: bounds.midX - 15, y: bounds.height - 26, s: 3, flip: facingLeft, palette: potColor)
            return
        }
        if kind == .hen {
            let step = moving ? Int(t * 8) % 2 : 0
            let g = grid([
                "..RR......",
                ".KWWK.....",
                "KWKWWK....",
                "YWWWWWKK..",
                ".KWWWWWWK.",
                "..KWWWWWK.",
                "...KKKKK..",
                step == 0 ? "....Y.Y..." : "...Y...Y..",
            ])
            drawGrid(g, x: bounds.midX - 15, y: bounds.height - 26, s: 3, flip: facingLeft, palette: potColor)
            return
        }
        if kind == .raccoon {
            let step = moving ? Int(t * 10) % 2 : 0
            let g = grid([
                ".K......K....",
                "KEK....KEK...",
                "KEEEEEEEEK...",
                "KKWKEEKWKK...",
                "KEEEKKEEEKEKE",
                ".KEEEEEEKKEKE",
                "..KEEEEEEEKE.",
                "..KEEEEEEK...",
                step == 0 ? "..K.K..K.K..." : ".K..K..K..K..",
            ])
            drawGrid(g, x: bounds.midX - 20, y: bounds.height - 29, s: 3, flip: facingLeft, palette: potColor)
            return
        }
        if kind == .bird {
            let up = Int(t * 8) % 2 == 0
            let g = grid([up ? "..K....K" : "........", up ? ".KQK..KQ" : "........", "..KQQQQK", ".KWKQQQQ", "KYQQQQQK", "..KQQQK.", "...K.K..", "........"])
            drawGrid(g, x: bounds.midX - 12, y: 4, s: 3, flip: facingLeft, palette: potColor)
            return
        }
        // градинар: шапка, гащеризон, ножица
        let step = moving ? Int(t * 8) % 2 : 0
        let g = grid([
            "..YYYYY...",
            ".YYYYYYY..",
            "...OOOO...",
            "...OKOK...",
            "...OOOO...",
            "..GGGGGG..",
            ".OGGGGGGO.",
            "..GGGGGG..",
            "..TT..TT..",
            step == 0 ? "..KK..KK.." : ".KK....KK.",
        ])
        drawGrid(g, x: bounds.midX - 15, y: bounds.height - 32, s: 3, flip: facingLeft, palette: potColor)
        if game.visitor?.stage == 1 && Int(t * 6) % 2 == 0 {
            NSColor(hex: 0x8d99ae).setFill()
            let sx = facingLeft ? bounds.midX - 24 : bounds.midX + 15
            NSRect(x: sx, y: bounds.height - 22, width: 8, height: 2).fill()
            NSRect(x: sx + 2, y: bounds.height - 25, width: 2, height: 8).fill()
        }
    }
}

extension PotGame {
    // MARK: - иконката горе

    @objc func statusClicked() {
        statusItem.menu = makeMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    func makeMenu() -> NSMenu {
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
        item("🌱 \(potStageNames[stage]) · вода \(Int(water))% · плодове \(fruitsCollected)", nil)
        menu.addItem(.separator())
        item("Грижи се…", #selector(openCardAction))
        item("Полей", #selector(waterAction))
        item(hidden ? "Покажи саксията" : "Скрий саксията", #selector(toggleHidden))
        item("Звънче за тревога на екрана", #selector(toggleBell), on: bellOn)
        if bellOn { item("Звънни!", #selector(ringFromMenu)) }
        item("Звуци", #selector(toggleSounds), on: soundsOn)
        // размер на всичко
        let sizeMenu = NSMenu()
        for v in [1.0, 0.75, 0.5, 0.35] {
            let it = NSMenuItem(title: "\(Int(v * 100))%", action: #selector(setScaleAction(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = v
            it.state = abs(Double(scale) - v) < 0.01 ? .on : .off
            sizeMenu.addItem(it)
        }
        let sizeItem = NSMenuItem(title: "Размер (по-малко място на екрана)", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        item(unseen > 0 ? "Дневник… (\(unseen) нови, докато те нямаше)" : "Дневник…", #selector(showJournal))
        item("★ Открити тайни: \(secrets.count)", nil)
        if !weedPanels.isEmpty { item("Изскубни всички бурени по пода (\(weedPanels.count))", #selector(pullAllFloorWeeds)) }
        menu.addItem(.separator())
        item("🐹 Към Пиксчо (стария живот)", #selector(switchToPixcho))
        menu.addItem(.separator())
        item("Версия \(currentBuild) · Провери за обновления", #selector(checkUpdateManually))
        item("Изход", #selector(quitApp))
        return menu
    }

    @objc func openCardAction() { if hidden { toggleHidden() }; openCard() }
    @objc func waterAction() { waterIt() }
    @objc func ringFromMenu() { ringBell() }
    @objc func toggleSounds() { soundsOn.toggle() }
    @objc func toggleDance() { danceOn.toggle(); if !danceOn { musicPlaying = false } }
    @objc func ignoreDanceApp(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? String else { return }
        danceIgnore = danceIgnore + [app]
        musicPlaying = false
        musicSeconds = 0
        say("Добре, на „\(app)“ няма да танцувам.", 2.5)
    }
    @objc func clearDanceIgnore() { danceIgnore = [] }
    @objc func quitApp() { savePosition(); NSApp.terminate(nil) }
    @objc func switchToPixcho() { savePosition(); AppMode.switchTo(pixcho: true) }

    @objc func toggleHidden() {
        hidden.toggle()
        let extra = [bellPanel, canPanel, bucketPanel].compactMap { $0 } + weedPanels
        if hidden { panel.orderOut(nil); extra.forEach { $0.orderOut(nil) }; closeCard() }
        else { panel.orderFrontRegardless(); extra.forEach { $0.orderFrontRegardless() } }
    }

    // MARK: - картата с грижите

    func openCard() {
        closeCard()
        let size = NSSize(width: 300, height: 150 + (stage >= 4 ? 15 : 0))
        let v = PotCardView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        let vf = screenFloor()
        // над растението; ако горе няма място, отстрани
        let plantTop = panel.frame.maxY - view.plantTop * scale
        var o = NSPoint(x: panel.frame.midX - size.width / 2, y: plantTop + 8)
        if o.y + size.height > vf.maxY - 4 {
            o.y = max(vf.minY + 4, plantTop - size.height)
            o.x = panel.frame.midX < vf.midX ? panel.frame.maxX + 6 : panel.frame.minX - size.width - 6
        }
        o.x = min(max(o.x, vf.minX + 4), vf.maxX - size.width - 4)
        o.y = min(max(o.y, vf.minY + 4), vf.maxY - size.height - 4)
        let p = overlayPanel(NSRect(origin: o, size: size), key: false)
        p.contentView = v
        p.acceptsMouseMovedEvents = true
        p.orderFrontRegardless()
        cardPanel = p
        cardOpened = time
        refreshCard()
    }

    func refreshCard() {
        guard let v = cardPanel?.contentView as? PotCardView else { return }
        var b = [
            PotButton(icon: iconWater, label: water > 90 ? "Полей (пълно е)" : "Полей (или вдигни лейката над него)", enabled: true,
                      action: { [weak self] in self?.waterIt() }),
            PotButton(icon: potIconFert, label: "Тор (двоен растеж 30 мин)", enabled: Date().timeIntervalSince(lastFert) > 2 * 3600,
                      action: { [weak self] in self?.fertilize() }),
            PotButton(icon: potIconWeed, label: "Плеви бурените", enabled: weedsCount > 0, action: { [weak self] in self?.pullAllWeeds() }),
            PotButton(icon: potIconAnt, label: "Изгони мравките", enabled: !ants.isEmpty, action: { [weak self] in self?.shooAllAnts() }),
        ]
        if stage >= 3 { b.append(PotButton(icon: potIconFruit, label: "Откъсни плод (отива в кофата)", enabled: fruitsOnPlant > 0, action: { [weak self] in self?.pickFruit() })) }
        b.append(PotButton(icon: potIconFruit, label: "Нахрани с плод от кофата (\(fruitsCollected))", enabled: fruitsCollected > 0, action: { [weak self] in
            guard let self, self.fruitsCollected > 0 else { return }
            self.fruitsCollected -= 1
            self.feedFruit()
        }))
        if hasEgg { b.append(PotButton(icon: potIconEgg, label: "Стопли яйцето", enabled: true, action: { [weak self] in self?.warmEgg() })) }
        b.append(PotButton(icon: potIconBook, label: "Дневник", enabled: true, action: { [weak self] in self?.closeCard(); self?.showJournal() }))
        v.buttons = b
        v.needsDisplay = true
    }

    func closeCard() { cardPanel?.orderOut(nil); cardPanel = nil }

    func updateCard() {
        guard let p = cardPanel else { return }
        p.contentView?.needsDisplay = true
        if NSEvent.pressedMouseButtons != 0 && !p.frame.contains(NSEvent.mouseLocation) && time - cardOpened > 0.4 { closeCard() }
    }

    // MARK: - звънчето и бягането

    @objc func toggleBell() {
        bellOn.toggle()
        if bellOn { setUpBell() } else { bellPanel?.orderOut(nil); bellPanel = nil }
    }

    func setUpBell() {
        guard bellPanel == nil else { return }
        let vf = NSScreen.main?.visibleFrame ?? .zero
        let x = d.object(forKey: "pot_bellX") as? Double ?? Double(vf.minX + 30)
        let y = d.object(forKey: "pot_bellY") as? Double ?? Double(vf.minY + 4)
        let p = overlayPanel(NSRect(x: x, y: y, width: 40, height: 34), key: false)
        p.level = .floating
        let v = PotBellView(frame: NSRect(x: 0, y: 0, width: 40, height: 34))
        v.game = self
        p.contentView = v
        fitScaled(p, NSSize(width: 40, height: 34))
        if !hidden { p.orderFrontRegardless() }
        bellPanel = p
    }

    func bellDropped() {
        guard let p = bellPanel else { return }
        let vf = (NSScreen.screens.first { $0.frame.contains(NSPoint(x: p.frame.midX, y: p.frame.midY)) } ?? NSScreen.main)?.visibleFrame ?? .zero
        let o = NSPoint(x: min(max(p.frame.minX, vf.minX), vf.maxX - p.frame.width), y: min(max(p.frame.minY, vf.minY), vf.maxY - p.frame.height))
        p.setFrameOrigin(o)
        d.set(Double(o.x), forKey: "pot_bellX"); d.set(Double(o.y), forKey: "pot_bellY")
    }

    /// Звънец: порастват му крачета и бяга зад ръба; пак звънец (или след 3 минути) се връща.
    func ringBell() {
        sfx("Glass")
        bellRungAgain()
        if hidePhase == 0 || hidePhase == 3 {
            closeCard()
            let sf = (NSScreen.screens.first { $0.frame.contains(NSPoint(x: panel.frame.midX, y: panel.frame.minY + 10)) } ?? NSScreen.main)?.frame ?? .zero
            let vf = screenFloor()
            func free(_ left: Bool) -> Bool {
                !NSScreen.screens.contains { s in
                    s.frame != sf && s.frame.maxY > sf.minY + 10 && s.frame.minY < sf.maxY - 10
                        && (left ? abs(s.frame.maxX - sf.minX) < 3 : abs(s.frame.minX - sf.maxX) < 3)
                }
            }
            let nearLeft = panel.frame.midX - vf.minX < vf.maxX - panel.frame.midX
            let left = free(nearLeft) ? nearLeft : (free(!nearLeft) ? !nearLeft : nearLeft)
            if hidePhase == 0 { hideHome = panel.frame.minX }
            hideGoal = left ? vf.minX - panel.frame.width - 10 : vf.maxX + 10
            hidePhase = 1
            hideUntil = time + 3 * 60
            say(["АААА! Бягам!", "Тревога! Крия се!", "Крачета, бягайте!"].randomElement()!, 1.5)
        } else {
            hidePhase = 3
            panel.alphaValue = 1
            say("Мина ли? Връщам се!", 2)
        }
    }

    func updateHiding(_ dt: Double) {
        guard hidePhase != 0 else { return }
        var x = panel.frame.minX
        let vf = screenFloor()
        switch hidePhase {
        case 1:
            x += (hideGoal > x ? 1 : -1) * min(abs(hideGoal - x), CGFloat(420 * dt))
            if abs(hideGoal - x) < 1 { hidePhase = 2; panel.alphaValue = 0 }
        case 2:
            if time > hideUntil { hidePhase = 3; panel.alphaValue = 1; say("Чисто ли е? Излизам!", 2) }
        default:
            x += (hideHome > x ? 1 : -1) * min(abs(hideHome - x), CGFloat(160 * dt))
            if abs(hideHome - x) < 1 { hidePhase = 0; savePosition() }
        }
        panel.setFrameOrigin(NSPoint(x: x, y: vf.minY))
    }

    // MARK: - гости

    func startVisitor(_ kind: PotVisitorKind) {
        guard visitor == nil, !hidden, hidePhase == 0, userActive else { return }
        let vf = screenFloor()
        let fromLeft = panel.frame.midX > vf.midX
        let size = kind == .bird ? NSSize(width: 40, height: 32) : NSSize(width: 60, height: 50)
        if kind == .raccoon && fruitsCollected == 0 { return }
        let start = NSPoint(x: fromLeft ? vf.minX - size.width : vf.maxX, y: kind == .bird ? vf.maxY - 120 : vf.minY)
        let p = overlayPanel(NSRect(origin: start, size: size), key: false)
        p.ignoresMouseEvents = kind != .raccoon
        p.level = .floating
        let v = PotVisitorView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        v.kind = kind
        v.facingLeft = !fromLeft
        p.contentView = v
        fitScaled(p, size)
        p.orderFrontRegardless()
        visitor = PotVisitor(kind: kind, panel: p, view: v, fromLeft: fromLeft)
        switch kind {
        case .gardener: say("Идва градинарят да ме подреже!", 2.5)
        case .bird: say(birdReturning ? "Птичката се връща! Ох-ох…" : "Птичка! Лети към мен!", 2.5)
        case .raccoon: say("Пст… някой се промъква към кофата! Хвани го!", 3)
        case .pixcho: say("Кой е този жълт квадрат?! Идва към мен!", 3)
        case .hen: say("Кокошка?! Кът-кудяк! Гледа плодовете в кофата!", 3)
        }
    }

    func updateVisitor(_ dt: Double) {
        guard let v = visitor else { return }
        v.view.needsDisplay = true
        let vf = screenFloor()
        var o = v.panel.frame.origin
        let target: NSPoint
        switch v.stage {
        case 0:
            if v.kind == .raccoon || v.kind == .hen, let bk = bucketPanel {
                target = NSPoint(x: bk.frame.midX - v.panel.frame.width / 2 + (v.fromLeft ? -30 : 30), y: vf.minY)
            } else if v.kind == .gardener || v.kind == .pixcho {
                target = NSPoint(x: panel.frame.midX + (v.fromLeft ? -1 : 1) * (panel.frame.width / 2 + 10) - v.panel.frame.width / 2, y: vf.minY)
            } else {
                target = NSPoint(x: panel.frame.midX - 20 * scale, y: panel.frame.maxY - (PotView.top + 10) * scale)
            }
        case 1:
            target = o
            if time - v.stageAt > (v.kind == .gardener ? 5 : (v.kind == .raccoon ? 3 : 4)) {
                v.stage = 2; v.stageAt = time
                finishVisit(v.kind)
            }
        default:
            target = NSPoint(x: v.fromLeft ? vf.minX - 80 : vf.maxX + 20, y: v.kind == .bird ? vf.maxY - 60 : vf.minY)
        }
        let dx = target.x - o.x, dy = target.y - o.y
        let dist = (dx * dx + dy * dy).squareRoot()
        let sp = CGFloat((v.kind == .bird ? 220 : (v.kind == .raccoon ? (v.stage == 2 ? 300 : 120) : 90)) * dt)
        v.view.moving = dist > 2
        if dist > 2 {
            o.x += dx / dist * min(dist, sp); o.y += dy / dist * min(dist, sp)
            v.view.facingLeft = dx < 0
            v.panel.setFrameOrigin(o)
        } else if v.stage == 0 {
            v.stage = 1; v.stageAt = time
            if v.kind == .gardener { trimmingUntil = time + 5; sfx("Tink") }
            else if v.kind == .bird && !birdReturning { say("Птичката си прави гнездо!", 2.5) }
        } else if v.stage == 2 {
            v.panel.orderOut(nil)
            visitor = nil
        }
    }

    func caughtRaccoon() {
        guard let v = visitor, v.kind == .raccoon, v.stage < 2 else { return }
        v.stage = 2
        v.stageAt = time
        raccoonFinished(caught: true)
    }

    func finishVisit(_ kind: PotVisitorKind) {
        if kind == .raccoon { raccoonFinished(caught: false); return }
        if kind == .pixcho { pixchoVisitDone(); return }
        if kind == .hen { henVisitDone(); return }
        if kind == .gardener && repairPotIfCracked() { return }
        if kind == .bird && birdReturning { birdBackScandal(); return }
        if kind == .gardener {
            overgrowth = 0
            health += 20
            if fruitsCollected >= 3 {
                fruitsCollected -= 3
                say("Градинарят ме подстрига! Взе си 3 плода за труда.", 3.5)
            } else {
                say("Градинарят ме подстрига! Друг път ще му платим с плодове.", 3.5)
            }
            journal("Градинарят подряза растението")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in _ = self?.gardenerScandal() }
        } else {
            hasNest = true
            hasEgg = true
            eggCare = 30
            eggLaid = Date()
            say("Птичката снесе ЯЙЦЕ в гнездото! Грижи се за него (цъкни го)!", 4)
            journal("Птичка си направи гнездо и снесе яйце")
        }
    }

    // MARK: - обновяване

    @objc func checkUpdateManually() { checkForUpdate(manual: true) }

    func checkForUpdate(manual: Bool) {
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(Game.updateRepo)/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        URLSession.shared.dataTask(with: req) { data, _, _ in
            var build = 0
            var url: URL?
            if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                build = Int((json["tag_name"] as? String ?? "").filter { $0.isNumber }) ?? 0
                let assets = json["assets"] as? [[String: Any]] ?? []
                if let link = assets.first(where: { $0["name"] as? String == "Tamagotchi.zip" })?["browser_download_url"] as? String {
                    url = URL(string: link)
                }
            }
            let b = build, u = url
            DispatchQueue.main.async {
                if b > self.currentBuild, let u {
                    self.availableBuild = b
                    self.availableURL = u
                    if manual { self.installUpdate() } else { self.say("Има нова версия! Цъкни иконката горе → „Обнови“.", 5) }
                } else if manual {
                    self.say(data == nil ? "Няма интернет…" : "Това е последната версия (\(self.currentBuild)).", 3)
                }
            }
        }.resume()
    }

    @objc func installUpdate() {
        guard let url = availableURL, !updating else { return }
        var target = Bundle.main.bundleURL
        if target.path.contains("/AppTranslocation/") { target = URL(fileURLWithPath: "/Applications/Tamagotchi.app") }
        updating = true
        say("Обновявам се…", 30)
        URLSession.shared.downloadTask(with: url) { tmp, _, _ in
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
            DispatchQueue.main.async {
                guard let newApp = result else { self.updating = false; self.say("Не успях да се обновя", 3); return }
                self.savePosition()
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
                do { try p.run(); NSApp.terminate(nil) } catch { self.updating = false; self.say("Не успях да се обновя", 3) }
            }
        }.resume()
    }
}
