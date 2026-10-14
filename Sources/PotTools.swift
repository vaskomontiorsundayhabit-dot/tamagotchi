// Саксията: лейка (вдигаш я над растението и го поливаш), кофа с набраните плодове
// (хващаш плод и го даваш на растението), бурени, които избягват от саксията и плъзват по екрана.

import AppKit

final class PotCanView: NSView {
    weak var game: PotGame?
    let drag = Dragger()
    var held = false
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { drag.down(window); held = true }
    override func mouseDragged(with event: NSEvent) { drag.dragged(window) }
    override func mouseUp(with event: NSEvent) {
        held = false
        if !drag.up() { game?.say("Хвани лейката и я вдигни над мен!", 2.5) }
    }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        let pouring = g.pouring
        NSGraphicsContext.current?.saveGraphicsState()
        if pouring {
            // наклонена: излива вода
            let t = NSAffineTransform()
            t.translateX(by: 34, yBy: 22)
            t.rotate(byDegrees: 28)
            t.translateX(by: -34, yBy: -22)
            t.concat()
        }
        let can = grid([
            "..........KKKK..",
            ".........K....K.",
            "KK......KCCCCCCK",
            ".KK....KCCCCCCCK",
            "..KKK.KCCWCCCCCK",
            "...KKKCCCCCCCCCK",
            "......KCCCCCCCCK",
            "......KCCCCCCCCK",
            ".......KKKKKKKK.",
        ])
        drawGrid(can, x: 4, y: 4, s: 3, palette: potColor)
        NSGraphicsContext.current?.restoreGraphicsState()
        if pouring {
            NSColor(hex: 0x48cae4).setFill()
            for i in 0..<8 {
                let k = CGFloat((g.time * 2.5 + Double(i) / 8).truncatingRemainder(dividingBy: 1))
                NSRect(x: 2 + CGFloat(i % 3) * 3, y: 18 + k * (bounds.height - 22), width: 2, height: 5).fill()
            }
        }
    }
}

final class PotBucketView: NSView {
    weak var game: PotGame?
    var handFruit: NSPanel?
    var moved = false
    var start = NSPoint.zero
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { start = NSEvent.mouseLocation; moved = false }
    override func mouseDragged(with event: NSEvent) {
        guard let g = game else { return }
        let m = NSEvent.mouseLocation
        if !moved && abs(m.x - start.x) + abs(m.y - start.y) > 4 {
            moved = true
            guard g.fruitsCollected > 0 else { g.say("Кофата е празна. Набери плодове!", 2.5); return }
            // взимаш плод от кофата
            g.fruitsCollected -= 1
            let p = overlayPanel(NSRect(x: m.x - 10, y: m.y - 10, width: 20, height: 20), key: false)
            p.ignoresMouseEvents = true
            p.contentView = PotFruitView(frame: NSRect(x: 0, y: 0, width: 20, height: 20))
            p.orderFrontRegardless()
            handFruit = p
        }
        handFruit?.setFrameOrigin(NSPoint(x: m.x - 10, y: m.y - 10))
    }
    override func mouseUp(with event: NSEvent) {
        guard let g = game else { return }
        if let f = handFruit {
            handFruit = nil
            f.orderOut(nil)
            if g.overPlant(NSPoint(x: f.frame.midX, y: f.frame.midY)) { g.feedFruit() } else { g.fruitsCollected += 1 }
            return
        }
        if !moved {
            g.say(g.fruitsCollected > 0 ? "В кофата има \(g.fruitsCollected) плода. Хвани един и ми го дай!" : "Кофата е празна. Набери плодове!", 3)
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        let w = bounds.width
        // плодовете отгоре
        let n = min(9, g.fruitsCollected)
        for i in 0..<n {
            let x = 8 + CGFloat(i % 5) * 7, y = 10 - CGFloat(i / 5) * 6
            NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: x, y: y, width: 8, height: 8).fill()
            NSColor(hex: i % 3 == 0 ? 0xff9f1c : 0xe63946).setFill(); NSRect(x: x + 1.5, y: y + 1.5, width: 5, height: 5).fill()
        }
        // кофата
        let b = NSBezierPath()
        b.move(to: NSPoint(x: 4, y: 16)); b.line(to: NSPoint(x: w - 4, y: 16))
        b.line(to: NSPoint(x: w - 9, y: bounds.height - 2)); b.line(to: NSPoint(x: 9, y: bounds.height - 2)); b.close()
        NSColor(hex: 0x8d99ae).setFill(); b.fill()
        NSColor(hex: 0x5c677d).setFill()
        NSRect(x: 2, y: 14, width: w - 4, height: 4).fill()
        NSRect(x: 9, y: 26, width: w - 18, height: 2).fill()
        if g.fruitsCollected > 9 {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy), .foregroundColor: NSColor.white]
            ("\(g.fruitsCollected)" as NSString).draw(at: NSPoint(x: w / 2 - 7, y: 30), withAttributes: a)
        }
    }
}

final class PotFruitView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor(hex: 0x2b2b3a).setFill(); bounds.insetBy(dx: 2, dy: 2).fill()
        NSColor(hex: 0xe63946).setFill(); bounds.insetBy(dx: 4, dy: 4).fill()
        NSColor(hex: 0x52b788).setFill(); NSRect(x: bounds.midX, y: bounds.maxY - 5, width: 3, height: 4).fill()
    }
}

/// Бурен, избягал от саксията, на пода.
final class PotWeedView: NSView {
    weak var game: PotGame?
    var index = 0
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.pullFloorWeed(window) }
    override func draw(_ dirtyRect: NSRect) {
        let h = bounds.height
        NSColor(hex: 0x6a994e).setFill()
        for (dx, hh) in [(4, 12), (9, 18), (14, 14), (19, 10)] {
            NSRect(x: CGFloat(dx), y: h - CGFloat(hh), width: 3, height: CGFloat(hh)).fill()
        }
        NSColor(hex: 0x386641).setFill()
        NSRect(x: 1, y: h - 7, width: 4, height: 3).fill()
        NSRect(x: 16, y: h - 12, width: 4, height: 3).fill()
        NSRect(x: 7, y: h - 15, width: 3, height: 3).fill()
    }
}

extension PotGame {
    // MARK: - лейката и кофата до саксията

    var potWidth: CGFloat { stage >= 5 ? 76 : (stage == 4 ? 60 : 46) }

    func setUpTools() {
        if canPanel == nil {
            let p = overlayPanel(NSRect(x: 0, y: 0, width: 60, height: 80), key: false)
            p.level = .floating
            let v = PotCanView(frame: NSRect(x: 0, y: 0, width: 60, height: 80))
            v.game = self
            p.contentView = v
            canPanel = p
        }
        if bucketPanel == nil {
            let p = overlayPanel(NSRect(x: 0, y: 0, width: 46, height: 44), key: false)
            p.level = .floating
            let v = PotBucketView(frame: NSRect(x: 0, y: 0, width: 46, height: 44))
            v.game = self
            p.contentView = v
            bucketPanel = p
        }
        if !hidden { canPanel?.orderFrontRegardless(); bucketPanel?.orderFrontRegardless() }
    }

    /// Лейката и кофата стоят от двете страни на саксията и тичат с нея при тревога.
    func updateTools(_ dt: Double) {
        guard let can = canPanel, let bucket = bucketPanel, let cv = can.contentView as? PotCanView else { return }
        let floorY = panel.frame.minY
        let bucketO = NSPoint(x: panel.frame.midX + potWidth / 2 + 8, y: floorY)
        if (bucket.contentView as? PotBucketView)?.handFruit == nil || bucket.frame.origin != bucketO { bucket.setFrameOrigin(bucketO) }
        bucket.contentView?.needsDisplay = true
        let home = NSPoint(x: panel.frame.midX - potWidth / 2 - 8 - can.frame.width, y: floorY)
        if cv.held {
            // поливане: лейката е над растението
            let c = NSPoint(x: can.frame.minX + 6, y: can.frame.minY)
            let over = panel.frame.insetBy(dx: 10, dy: 0).contains(NSPoint(x: c.x, y: panel.frame.minY + 20)) && c.y > panel.frame.minY + 30
            if over && !pouring { say(["Ааах, вода!", "Лей, лей!", "Мммм!"].randomElement()!, 1.5); sfx("Bottle") }
            pouring = over
            if over {
                water += 30 * dt
                wateringUntil = time + 0.3
                if water >= 100 && Int(time * 2) % 6 == 0 { say("Стига! Пълен съм!", 1.5) }
            }
        } else {
            pouring = false
            // връща се на мястото си до саксията
            var o = can.frame.origin
            let dx = home.x - o.x, dy = home.y - o.y
            let dist = (dx * dx + dy * dy).squareRoot()
            if dist > 1 {
                let sp = CGFloat(max(600, Double(dist) * 8) * dt)
                o.x += dx / dist * min(dist, sp); o.y += dy / dist * min(dist, sp)
                can.setFrameOrigin(o)
            }
        }
        can.contentView?.needsDisplay = true
        let a: CGFloat = hidePhase == 2 ? 0 : 1
        if can.alphaValue != a { can.alphaValue = a; bucket.alphaValue = a }
    }

    func overPlant(_ p: NSPoint) -> Bool {
        panel.frame.insetBy(dx: 6, dy: 0).contains(p) && p.y > panel.frame.minY + 20 && p.y < panel.frame.maxY - PotView.top + 20
    }

    /// Дадеш му плод от кофата: подхранва го.
    func feedFruit() {
        health += 15
        growth += 3
        eyesUntil = time + 3
        sfx("Pop")
        say(["Ням! Вкусно!", "Мммм, витамини!", "Благодаря! Раста!"].randomElement()!, 2)
    }

    // MARK: - бурени по пода

    var floorWeeds: [Double] { get { d.array(forKey: "pot_floorWeeds") as? [Double] ?? [] } set { d.set(newValue, forKey: "pot_floorWeeds") } }

    /// Ако дълго не плевиш (3 бурена в саксията), излизат и плъзват по пода без край.
    func updateWeedSpread() {
        guard time > nextWeedSpread else { return }
        nextWeedSpread = time + 60
        let vf = screenFloor()
        var fw = floorWeeds
        if weeds.count >= 3 {
            weedFullMinutes += 1
            if weedFullMinutes >= 8 {
                weedFullMinutes = 0
                let side: CGFloat = Bool.random() ? -1 : 1
                let x = panel.frame.midX + side * (potWidth / 2 + 80 + CGFloat(Int.random(in: 0...2)) * 26)
                if x > vf.minX && x < vf.maxX - 26 { fw.append(Double(x)); say("Бурените избягаха от саксията!", 3) }
            }
        } else {
            weedFullMinutes = 0
        }
        // по пода плъзват все по-нататък
        if !fw.isEmpty && fw.count < 300 && Int.random(in: 0..<14) == 0 {
            let src = fw.randomElement()!
            let nx = src + (Bool.random() ? 26 : -26)
            if nx > Double(vf.minX) && nx < Double(vf.maxX - 26) && !fw.contains(where: { abs($0 - nx) < 12 }) { fw.append(nx) }
        }
        if fw.count != floorWeeds.count { floorWeeds = fw }
        syncWeedPanels()
    }

    func syncWeedPanels() {
        let fw = floorWeeds
        let vf = screenFloor()
        while weedPanels.count > fw.count { weedPanels.removeLast().orderOut(nil) }
        for (i, x) in fw.enumerated() {
            if i >= weedPanels.count {
                let p = overlayPanel(NSRect(x: CGFloat(x), y: vf.minY, width: 24, height: 22), key: false)
                p.level = .floating
                let v = PotWeedView(frame: NSRect(x: 0, y: 0, width: 24, height: 22))
                v.game = self
                p.contentView = v
                if !hidden { p.orderFrontRegardless() }
                weedPanels.append(p)
            } else if abs(weedPanels[i].frame.minX - CGFloat(x)) > 0.5 {
                weedPanels[i].setFrameOrigin(NSPoint(x: CGFloat(x), y: vf.minY))
            }
        }
    }

    func pullFloorWeed(_ w: NSWindow?) {
        guard let w, let i = weedPanels.firstIndex(where: { $0 === w }) else { return }
        weedPanels[i].orderOut(nil)
        weedPanels.remove(at: i)
        var fw = floorWeeds
        if i < fw.count { fw.remove(at: i) }
        floorWeeds = fw
        sfx("Pop")
        if fw.isEmpty { say("Подът е чист! Браво!", 2) }
    }

    @objc func pullAllFloorWeeds() {
        weedPanels.forEach { $0.orderOut(nil) }
        weedPanels = []
        floorWeeds = []
        sfx("Pop")
        say("Изскубнахме всички бурени по пода!", 2.5)
    }
}
