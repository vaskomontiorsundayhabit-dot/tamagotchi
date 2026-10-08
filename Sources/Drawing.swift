// Рисуване с пиксели по екрана. Нарисуваното става платформи, на които Пиксчо стъпва.

import AppKit

let drawCell: CGFloat = 10
let drawPalette = [0x2b2b3a, 0xffffff, 0xe63946, 0xff924c, 0xffd23f, 0x52b788, 0x48cae4, 0x1982c4, 0xc77dff, 0xff8fab, 0x8b5a2b, 0x8d99ae]

enum DrawTool { case marker, eraser, pipette }

func cellKey(_ x: Int, _ y: Int) -> Int { (x + 100_000) * 1_000_000 + (y + 100_000) }
func cellFromKey(_ k: Int) -> (Int, Int) { (k / 1_000_000 - 100_000, k % 1_000_000 - 100_000) }

/// Прозрачен слой върху целия екран с нарисуваните пиксели.
final class DrawLayer: NSView {
    weak var game: Game?
    private var last: (Int, Int)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private func cell(_ event: NSEvent) -> (Int, Int) {
        let p = NSEvent.mouseLocation
        return (Int(floor(p.x / drawCell)), Int(floor(p.y / drawCell)))
    }

    override func mouseDown(with event: NSEvent) {
        guard let game, game.drawing else { return }
        let c = cell(event)
        if game.drawTool == .pipette {
            game.pickColor(at: c)
            return
        }
        apply(c)
        last = c
    }

    override func mouseDragged(with event: NSEvent) {
        guard let game, game.drawing, game.drawTool != .pipette else { return }
        let c = cell(event)
        // линия между последната и сегашната клетка, за да няма дупки
        if let l = last {
            let steps = max(abs(c.0 - l.0), abs(c.1 - l.1))
            if steps > 0 {
                for i in 1...steps {
                    let t = Double(i) / Double(steps)
                    apply((l.0 + Int((Double(c.0 - l.0) * t).rounded()), l.1 + Int((Double(c.1 - l.1) * t).rounded())))
                }
            }
        } else {
            apply(c)
        }
        last = c
    }

    override func mouseUp(with event: NSEvent) { last = nil; game?.saveDrawing() }

    private func apply(_ c: (Int, Int)) {
        guard let game else { return }
        let k = cellKey(c.0, c.1)
        if game.drawTool == .eraser { game.drawCells.removeValue(forKey: k) }
        else {
            if game.drawCells[k] == nil { game.newCellsThisSession += 1 }
            game.drawCells[k] = game.drawColor
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game, let w = window else { return }
        if game.drawing {
            NSColor(white: 0, alpha: 0.12).setFill()
            bounds.fill()
        }
        let origin = w.frame.origin
        for (k, color) in game.drawCells {
            let (x, y) = cellFromKey(k)
            let r = NSRect(x: CGFloat(x) * drawCell - origin.x, y: CGFloat(y) * drawCell - origin.y, width: drawCell, height: drawCell)
            guard r.intersects(dirtyRect) else { continue }
            NSColor(hex: color).setFill(); r.fill()
            NSColor(white: 0, alpha: 0.15).setFill()
            NSRect(x: r.minX, y: r.minY, width: r.width, height: 1).fill()
            NSRect(x: r.maxX - 1, y: r.minY, width: 1, height: r.height).fill()
        }
    }
}

/// Лентата с инструменти, докато се рисува.
final class DrawToolbar: NSView {
    weak var game: Game?

    static let size = NSSize(width: 640, height: 50)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private var swatches: [NSRect] {
        drawPalette.indices.map { NSRect(x: 12 + CGFloat($0) * 26, y: 13, width: 22, height: 22) }
    }
    private var buttons: [(String, NSRect)] {
        let x0: CGFloat = 12 + CGFloat(drawPalette.count) * 26 + 10
        let names = ["МАРКЕР", "ГУМА", "ПИПЕТА", "ИЗТРИЙ ВСИЧКО", "ГОТОВО"]
        let widths: [CGFloat] = [58, 46, 58, 104, 58]
        var x = x0
        var out: [(String, NSRect)] = []
        for (n, w) in zip(names, widths) {
            out.append((n, NSRect(x: x, y: 12, width: w, height: 26)))
            x += w + 6
        }
        return out
    }

    override func mouseDown(with event: NSEvent) {
        guard let game else { return }
        let p = convert(event.locationInWindow, from: nil)
        for (i, r) in swatches.enumerated() where r.contains(p) {
            game.drawColor = drawPalette[i]
            if game.drawTool != .marker { game.drawTool = .marker }
            needsDisplay = true
            return
        }
        for (name, r) in buttons where r.contains(p) {
            switch name {
            case "МАРКЕР": game.drawTool = .marker
            case "ГУМА": game.drawTool = .eraser
            case "ПИПЕТА": game.drawTool = .pipette
            case "ИЗТРИЙ ВСИЧКО": game.clearDrawing()
            default: game.stopDrawing()
            }
            needsDisplay = true
            return
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let b = bounds
        NSColor(hex: 0x1b1b24, alpha: 0.97).setFill(); b.fill()
        NSColor.white.setFill()
        for r in [NSRect(x: 0, y: 0, width: b.width, height: 2), NSRect(x: 0, y: b.height - 2, width: b.width, height: 2),
                  NSRect(x: 0, y: 0, width: 2, height: b.height), NSRect(x: b.width - 2, y: 0, width: 2, height: b.height)] { r.fill() }
        for (i, r) in swatches.enumerated() {
            if drawPalette[i] == game.drawColor && game.drawTool == .marker {
                NSColor.white.setFill(); r.insetBy(dx: -3, dy: -3).fill()
            }
            NSColor(hex: 0x2b2b3a).setFill(); r.fill()
            NSColor(hex: drawPalette[i]).setFill(); r.insetBy(dx: 2, dy: 2).fill()
        }
        let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .heavy)
        for (name, r) in buttons {
            let active = (name == "МАРКЕР" && game.drawTool == .marker) || (name == "ГУМА" && game.drawTool == .eraser)
                || (name == "ПИПЕТА" && game.drawTool == .pipette)
            NSColor(hex: active ? 0x48cae4 : (name == "ГОТОВО" ? 0x52b788 : 0x3a3a50)).setFill(); r.fill()
            if name == "МАРКЕР" {
                NSColor(hex: game.drawColor).setFill()
                NSRect(x: r.minX + 3, y: r.maxY - 5, width: r.width - 6, height: 3).fill()
            }
            let a: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: active ? NSColor(hex: 0x1b1b24) : NSColor.white]
            let ns = name as NSString
            let sz = ns.size(withAttributes: a)
            ns.draw(at: NSPoint(x: r.midX - sz.width / 2, y: r.midY - sz.height / 2), withAttributes: a)
        }
    }
}

extension Game {
    func setUpDrawLayer() {
        guard let screen = NSScreen.main else { return }
        let p = overlayPanel(screen.frame, key: true)
        p.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        let v = DrawLayer(frame: NSRect(origin: .zero, size: screen.frame.size))
        v.game = self
        p.contentView = v
        p.ignoresMouseEvents = true
        p.orderFrontRegardless()
        drawPanel = p
        drawView = v
    }

    @objc func startDrawing() {
        if drawing { return }
        closeRetro()
        drawing = true
        newCellsThisSession = 0
        drawPanel?.ignoresMouseEvents = false
        drawPanel?.orderFrontRegardless()
        drawView?.needsDisplay = true
        if let vf = NSScreen.main?.visibleFrame {
            let size = DrawToolbar.size
            let tb = DrawToolbar(frame: NSRect(origin: .zero, size: size))
            tb.game = self
            let p = overlayPanel(NSRect(x: vf.midX - size.width / 2, y: vf.maxY - size.height - 8,
                                        width: size.width, height: size.height), key: false)
            p.contentView = tb
            p.orderFrontRegardless()
            toolbarPanel = p
        }
        NSApp.activate(ignoringOtherApps: true)
        drawPanel?.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        say("Нарисувай ми нещо, на което да стъпя!", seconds: 3)
    }

    func stopDrawing() {
        guard drawing else { return }
        drawing = false
        drawPanel?.ignoresMouseEvents = true
        toolbarPanel?.orderOut(nil)
        toolbarPanel = nil
        drawView?.needsDisplay = true
        saveDrawing()
        if newCellsThisSession >= 5 { fulfill(.platform) }
    }

    func clearDrawing() {
        drawCells.removeAll()
        drawView?.needsDisplay = true
        saveDrawing()
    }

    func pickColor(at c: (Int, Int)) {
        if let color = drawCells[cellKey(c.0, c.1)] {
            drawColor = color
            drawTool = .marker
            toolbarPanel?.contentView?.needsDisplay = true
            return
        }
        // няма нарисуван пиксел там: взима цвят от екрана с лупата на macOS
        NSColorSampler().show { [weak self] color in
            guard let c = color?.usingColorSpace(.sRGB) else { return }
            let r = Int((c.redComponent * 255).rounded()), g = Int((c.greenComponent * 255).rounded())
            let b = Int((c.blueComponent * 255).rounded())
            let hex = (r << 16) | (g << 8) | b
            DispatchQueue.main.async { self?.pickedColor(hex) }
        }
    }

    func pickedColor(_ hex: Int) {
        drawColor = hex
        drawTool = .marker
        toolbarPanel?.contentView?.needsDisplay = true
    }

    func saveDrawing() {
        let arr = drawCells.map { [$0.key, $0.value] }
        UserDefaults.standard.set(arr, forKey: "drawCells")
    }

    func loadDrawing() {
        guard let arr = UserDefaults.standard.array(forKey: "drawCells") as? [[Int]] else { return }
        for pair in arr where pair.count == 2 { drawCells[pair[0]] = pair[1] }
    }

    // --- гравитация и платформи ---

    /// Най-високата повърхност под краката: нарисуван пиксел или дъното на екрана.
    func supportY(x0: CGFloat, x1: CGFloat, feet: CGFloat) -> CGFloat {
        var best = (window.screen ?? NSScreen.main)?.visibleFrame.minY ?? 0
        let c0 = Int(floor(x0 / drawCell)), c1 = Int(floor(x1 / drawCell))
        for (k, _) in drawCells {
            let (cx, cy) = cellFromKey(k)
            guard cx >= c0 && cx <= c1 else { continue }
            let top = CGFloat(cy + 1) * drawCell
            if top <= feet + 3 && top > best { best = top }
        }
        return best
    }

    func applyGravity(_ step: Double) {
        guard window.isVisible, !isDragging, !busyMoving, catchPanel == nil else { fallSpeed = 0; return }
        let wf = window.frame
        let feet = wf.maxY - view.feetY
        let x0 = wf.minX + view.bodyX0, x1 = wf.minX + view.bodyX1
        let support = supportY(x0: x0, x1: x1, feet: feet)
        if feet > support + 0.5 {
            fallSpeed += CGFloat(1800 * step)
            let dy = min(fallSpeed * CGFloat(step), feet - support)
            window.setFrameOrigin(NSPoint(x: wf.minX, y: wf.minY - dy))
            if feet - dy <= support + 0.5 {
                if fallSpeed > 500 && !pet.asleep { say(["Оп!", "Ауч!", "Приземих се!"].randomElement()!, seconds: 1.5) }
                fallSpeed = 0
                saveWindowPosition()
            }
        } else {
            if support - feet > 0.5 && support - feet < 4 {
                window.setFrameOrigin(NSPoint(x: wf.minX, y: wf.minY + (support - feet)))
            }
            fallSpeed = 0
        }
    }
}
