// Сънищата на Пиксчо: облаче над него, докато спи (след 2 минути сън, от време на време).

import AppKit

let dreams = [
    "БРОИ ОВЧИЦИ",
    "СЪНУВА КАФЕ",
    "ВАЛЯТ ПИКСЕЛИ",
    "ЛЕТИ",
    "МОНТИРА НАСЪН",
    "КОШМАР: БОМБИ!",
    "ЗЛАТЕН ПИКСЕЛ",
]

final class DreamView: NSView {
    weak var game: Game?
    var dream = 0
    var started: Double = 0

    static let size = NSSize(width: 190, height: 150)
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time - started
        let fade = CGFloat(min(1, t * 3, max(0, (game.dreamUntil - game.time) * 3)))

        // облаче: голямо заоблено + малки балончета към главата му
        let cloud = NSRect(x: 6, y: 6, width: bounds.width - 12, height: 108)
        let path = NSBezierPath(roundedRect: cloud, xRadius: 40, yRadius: 34)
        NSColor(white: 1, alpha: 0.95 * fade).setFill(); path.fill()
        NSColor(hex: 0x2b2b3a, alpha: fade).setStroke(); path.lineWidth = 3; path.stroke()
        for (x, y, r) in [(40.0, 122.0, 9.0), (28.0, 136.0, 6.0), (20.0, 146.0, 3.5)] {
            let b = NSBezierPath(ovalIn: NSRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            NSColor(white: 1, alpha: 0.95 * fade).setFill(); b.fill()
            NSColor(hex: 0x2b2b3a, alpha: fade).setStroke(); b.lineWidth = 2; b.stroke()
        }
        guard fade > 0.3 else { return }

        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(roundedRect: cloud.insetBy(dx: 6, dy: 6), xRadius: 34, yRadius: 28).setClip()
        let x0 = cloud.minX, y0 = cloud.minY, W = cloud.width, H = cloud.height
        let ground = y0 + H - 18

        func mini(_ face: Face, _ pose: Pose, x: CGFloat, ground g: CGFloat, height: CGFloat = 34) {
            let sp = buildSprite(level: game.bodyCells, face: face, pose: pose, frame: Int(game.time * 5), working: false,
                                 worn: game.pet.worn, variant: game.bodyVariant)
            let s = min(1.6, height / CGFloat(sp.maxY - sp.minY + 1))
            drawGrid(sp.grid, x: x - CGFloat(sp.cx) * s, y: g - CGFloat(sp.groundY + 1) * s, s: s, palette: game.color)
        }
        func caption(_ text: String) {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: 0x5c5c78)]
            let ns = text as NSString
            ns.draw(at: NSPoint(x: x0 + (W - ns.size(withAttributes: a).width) / 2, y: y0 + 10), withAttributes: a)
        }

        switch dream {
        case 0: // овчици над оградата
            NSColor(hex: 0x8ac926).setFill(); NSRect(x: x0, y: ground, width: W, height: 18).fill()
            NSColor(hex: 0x8b5a2b).setFill()
            NSRect(x: x0 + W / 2 - 2, y: ground - 16, width: 4, height: 16).fill()
            NSRect(x: x0 + W / 2 - 14, y: ground - 12, width: 28, height: 3).fill()
            let ph = CGFloat((t * 0.5).truncatingRemainder(dividingBy: 1))
            let sx = x0 + 20 + ph * (W - 40)
            let sy = ground - 12 - CGFloat(sin(Double(ph) * .pi)) * 26
            NSColor.white.setFill(); NSRect(x: sx, y: sy, width: 16, height: 10).fill()
            NSColor(hex: 0x2b2b3a).setFill()
            NSRect(x: sx + 14, y: sy + 1, width: 5, height: 5).fill()
            NSRect(x: sx + 2, y: sy + 10, width: 2, height: 3).fill(); NSRect(x: sx + 12, y: sy + 10, width: 2, height: 3).fill()
            caption("ОВЧИЦА №\(Int(t * 0.5) + 1)…")
        case 1: // кафе
            let cx = x0 + W / 2
            NSColor.white.setFill(); NSRect(x: cx - 18, y: ground - 30, width: 30, height: 28).fill()
            NSColor(hex: 0x2b2b3a).setStroke()
            NSBezierPath(rect: NSRect(x: cx - 18, y: ground - 30, width: 30, height: 28)).stroke()
            NSColor(hex: 0x5c3a1e).setFill(); NSRect(x: cx - 15, y: ground - 27, width: 24, height: 6).fill()
            NSRect(x: cx + 12, y: ground - 24, width: 6, height: 12).fill()
            for i in 0..<3 {
                let k = CGFloat((t * 1.2 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1))
                NSColor(hex: 0x8d99ae, alpha: 1 - k).setFill()
                NSRect(x: cx - 10 + CGFloat(i) * 8 + CGFloat(sin(t * 3 + Double(i))) * 3, y: ground - 36 - k * 30, width: 3, height: 5).fill()
            }
            caption("ОЩЕ ЕДНО КАФЕ… ХРР…")
        case 2: // пиксели валят в устата му
            mini(.eatOpen, .idle, x: x0 + W / 2, ground: ground)
            for i in 0..<8 {
                let k = CGFloat((t * 0.8 + Double(i) * 0.125).truncatingRemainder(dividingBy: 1))
                NSColor(hex: foodColors[i % foodColors.count]).setFill()
                NSRect(x: x0 + 20 + CGFloat(i * 19 % Int(W - 40)), y: y0 + 22 + k * (H - 50), width: 6, height: 6).fill()
            }
            caption("ПИКСЕЛИ… ВКУСНИ ПИКСЕЛИ…")
        case 3: // лети между облаците
            NSColor(hex: 0xbde0fe).setFill(); NSRect(x: x0, y: y0, width: W, height: H).fill()
            NSColor.white.setFill()
            for i in 0..<3 {
                let cx = x0 + (CGFloat(i) * 70 + W - CGFloat(t) * 30).truncatingRemainder(dividingBy: W + 40) - 20
                NSRect(x: cx, y: y0 + 30 + CGFloat(i) * 18, width: 30, height: 9).fill()
            }
            mini(.happy, .wave, x: x0 + W / 2, ground: y0 + H / 2 + 22 + CGFloat(sin(t * 2)) * 8)
            caption("ЛЕТЯЯЯ…")
        case 4: // монтира насън
            let m = NSRect(x: x0 + W / 2 - 40, y: y0 + 26, width: 80, height: 50)
            NSColor(hex: 0x8d99ae).setFill(); m.fill()
            NSColor(hex: 0x1b1b24).setFill(); m.insetBy(dx: 4, dy: 4).fill()
            for (row, c) in [(0, 0x48cae4), (1, 0xf4a261), (2, 0x52b788)] {
                NSColor(hex: c).setFill()
                NSRect(x: m.minX + 8, y: m.minY + 10 + CGFloat(row) * 11, width: 30 + CGFloat(row * 12), height: 6).fill()
            }
            NSColor(hex: 0xe63946).setFill()
            NSRect(x: m.minX + 6 + CGFloat((t * 30).truncatingRemainder(dividingBy: 66)), y: m.minY + 5, width: 2, height: 40).fill()
            caption("ЕКСПОРТ… 99%… ХРР…")
        case 5: // кошмар
            NSColor(hex: 0x3d2c4e).setFill(); NSRect(x: x0, y: y0, width: W, height: H).fill()
            for i in 0..<3 {
                let bx = x0 + W - CGFloat((t * 60 + Double(i) * 60).truncatingRemainder(dividingBy: Double(W) + 20))
                drawGrid(bombGrid, x: bx, y: ground - 24, s: 2.5, palette: game.color)
            }
            mini(.sad, .walk, x: x0 + 40, ground: ground)
            caption("НЕЕЕ! БОМБИТЕ!")
        default: // златен пиксел
            let pulse = 1 + CGFloat(sin(t * 4)) * 0.15
            drawGrid(iconGold, x: x0 + W / 2 - 16 * pulse, y: y0 + 26, s: 4 * pulse, palette: game.color)
            mini(.happy, .wave, x: x0 + W / 2 - 50, ground: ground)
            caption("МОЙ Е… ЗЛАТНИЯТ ПИКСЕЛ…")
        }
        NSGraphicsContext.current?.restoreGraphicsState()
    }
}

extension Game {
    /// Сънят се вижда, когато посочиш спящия Пиксчо с мишката (след 2 минути сън).
    func updateDreams() {
        guard pet.asleep, window.isVisible, hidePhase == .off else {
            sleepStart = 0
            closeDream()
            return
        }
        if sleepStart == 0 { sleepStart = time }
        let canDream = time - sleepStart > 120
        if let p = dreamPanel, let v = dreamView {
            positionDream(p)
            v.needsDisplay = true
            if view.hovering { dreamUntil = max(dreamUntil, time + 0.8) }
            if time > dreamUntil {
                if v.dream == 5 && bubbleText == nil { say("Ммм… бомби… не…", seconds: 2.5) }
                closeDream()
            } else if time - v.started > 12 && view.hovering {
                // сменя съня, ако го гледаш дълго
                v.dream = (v.dream + 1 + Int.random(in: 0..<(dreams.count - 1))) % dreams.count
                v.started = time
            }
            return
        }
        guard canDream, view.hovering else { return }
        let v = DreamView(frame: NSRect(origin: .zero, size: DreamView.size))
        v.game = self
        v.dream = Int.random(in: 0..<dreams.count)
        v.started = time
        let p = overlayPanel(NSRect(origin: .zero, size: DreamView.size), key: false)
        p.level = .floating
        p.ignoresMouseEvents = true
        p.contentView = v
        positionDream(p)
        p.orderFrontRegardless()
        dreamPanel = p
        dreamView = v
        dreamUntil = time + 0.8
    }

    func positionDream(_ p: NSPanel) {
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        var o = NSPoint(x: pr.midX - 20, y: pr.maxY - 6)
        o.x = min(max(o.x, vf.minX + 4), vf.maxX - DreamView.size.width - 4)
        o.y = min(max(o.y, vf.minY + 4), vf.maxY - DreamView.size.height - 4)
        if abs(p.frame.minX - o.x) > 0.5 || abs(p.frame.minY - o.y) > 0.5 { p.setFrameOrigin(o) }
    }

    func closeDream() {
        dreamPanel?.orderOut(nil)
        dreamPanel = nil
        dreamView = nil
    }
}
