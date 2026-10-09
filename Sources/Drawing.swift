// Рисуване с пиксели по екраните. Нарисуваното става платформи, на които Пиксчо стъпва.
// Десен бутон рисува, ляв трие, Esc излиза.

import AppKit

let drawCell: CGFloat = 10
let drawPalette = [0x2b2b3a, 0xffffff, 0xe63946, 0xff924c, 0xffd23f, 0x52b788, 0x48cae4, 0x1982c4, 0xc77dff, 0xff8fab, 0x8b5a2b, 0x8d99ae]
let brushSizes = [1, 2, 3, 5]

func cellKey(_ x: Int, _ y: Int) -> Int { (x + 100_000) * 1_000_000 + (y + 100_000) }
func cellFromKey(_ k: Int) -> (Int, Int) { (k / 1_000_000 - 100_000, k % 1_000_000 - 100_000) }

/// Прозрачен слой върху един екран с нарисуваните пиксели.
final class DrawLayer: NSView {
    weak var game: Game?
    private var last: (Int, Int)?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private func cellAtMouse() -> (Int, Int) {
        let p = NSEvent.mouseLocation
        return (Int(floor(p.x / drawCell)), Int(floor(p.y / drawCell)))
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { game?.stopDrawing() } else { super.keyDown(with: event) }
    }

    // ляв бутон: трие (или пипета)
    override func mouseDown(with event: NSEvent) {
        guard let game, game.drawing else { return }
        window?.makeFirstResponder(self)
        let c = cellAtMouse()
        if game.pipetteOn { game.pickColor(at: c); return }
        stroke(to: c, erase: true)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let game, game.drawing, !game.pipetteOn else { return }
        stroke(to: cellAtMouse(), erase: true)
    }

    override func mouseUp(with event: NSEvent) { finish() }

    // десен бутон: рисува
    override func rightMouseDown(with event: NSEvent) {
        guard let game, game.drawing else { return }
        window?.makeFirstResponder(self)
        stroke(to: cellAtMouse(), erase: false)
    }

    override func rightMouseDragged(with event: NSEvent) {
        guard game?.drawing == true else { return }
        stroke(to: cellAtMouse(), erase: false)
    }

    override func rightMouseUp(with event: NSEvent) { finish() }

    private func finish() {
        last = nil
        game?.saveDrawing()
        game?.drawingChanged()
    }

    /// линия от последната клетка до тази, за да няма дупки
    private func stroke(to c: (Int, Int), erase: Bool) {
        if let l = last {
            let steps = max(abs(c.0 - l.0), abs(c.1 - l.1))
            if steps > 0 {
                for i in 1...steps {
                    let t = Double(i) / Double(steps)
                    dab((l.0 + Int((Double(c.0 - l.0) * t).rounded()), l.1 + Int((Double(c.1 - l.1) * t).rounded())), erase: erase)
                }
            }
        } else {
            dab(c, erase: erase)
        }
        last = c
        game?.redrawDrawing()
    }

    private func dab(_ c: (Int, Int), erase: Bool) {
        guard let game else { return }
        let n = game.brushSize
        let off = (n - 1) / 2
        for dx in 0..<n {
            for dy in 0..<n {
                let k = cellKey(c.0 - off + dx, c.1 - off + dy)
                if erase { game.drawCells.removeValue(forKey: k) }
                else {
                    if game.drawCells[k] == nil { game.newCellsThisSession += 1 }
                    game.drawCells[k] = game.drawColor
                }
            }
        }
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

    static let size = NSSize(width: 900, height: 64)
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { game?.stopDrawing() } else { super.keyDown(with: event) }
    }

    private var swatches: [NSRect] {
        drawPalette.indices.map { NSRect(x: 14 + CGFloat($0) * 26, y: 10, width: 22, height: 22) }
    }
    private var sizeRects: [NSRect] {
        let x0: CGFloat = 14 + CGFloat(drawPalette.count) * 26 + 14
        return brushSizes.indices.map { NSRect(x: x0 + CGFloat($0) * 30, y: 8, width: 26, height: 26) }
    }
    private var buttons: [(String, NSRect)] {
        var x = (sizeRects.last?.maxX ?? 0) + 16
        var out: [(String, NSRect)] = []
        for (n, w) in [("ПИПЕТА", 64.0), ("ИЗТРИЙ ВСИЧКО", 112.0), ("ГОТОВО", 64.0)] {
            out.append((n, NSRect(x: x, y: 8, width: CGFloat(w), height: 26)))
            x += CGFloat(w) + 6
        }
        return out
    }

    override func mouseDown(with event: NSEvent) {
        guard let game else { return }
        let p = convert(event.locationInWindow, from: nil)
        for (i, r) in swatches.enumerated() where r.contains(p) {
            game.drawColor = drawPalette[i]
            game.pipetteOn = false
            needsDisplay = true
            return
        }
        for (i, r) in sizeRects.enumerated() where r.contains(p) {
            game.brushSize = brushSizes[i]
            needsDisplay = true
            return
        }
        for (name, r) in buttons where r.contains(p) {
            switch name {
            case "ПИПЕТА": game.pipetteOn.toggle()
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
            if drawPalette[i] == game.drawColor { NSColor.white.setFill(); r.insetBy(dx: -3, dy: -3).fill() }
            NSColor(hex: 0x2b2b3a).setFill(); r.fill()
            NSColor(hex: drawPalette[i]).setFill(); r.insetBy(dx: 2, dy: 2).fill()
        }
        // текущият цвят (и от пипетата)
        if !drawPalette.contains(game.drawColor) {
            let r = NSRect(x: swatches.last!.maxX + 2, y: 36, width: 10, height: 10)
            NSColor(hex: game.drawColor).setFill(); r.fill()
        }
        for (i, r) in sizeRects.enumerated() {
            NSColor(hex: game.brushSize == brushSizes[i] ? 0x48cae4 : 0x3a3a50).setFill(); r.fill()
            let d = CGFloat(4 + brushSizes[i] * 3)
            NSColor(hex: game.drawColor).setFill()
            NSRect(x: r.midX - d / 2, y: r.midY - d / 2, width: d, height: d).fill()
        }
        let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .heavy)
        for (name, r) in buttons {
            let active = name == "ПИПЕТА" && game.pipetteOn
            NSColor(hex: active ? 0x48cae4 : (name == "ГОТОВО" ? 0x52b788 : 0x3a3a50)).setFill(); r.fill()
            let a: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: active ? NSColor(hex: 0x1b1b24) : NSColor.white]
            let ns = name as NSString
            let sz = ns.size(withAttributes: a)
            ns.draw(at: NSPoint(x: r.midX - sz.width / 2, y: r.midY - sz.height / 2), withAttributes: a)
        }
        let hint = "ДЕСЕН БУТОН РИСУВА   ЛЯВ БУТОН ТРИЕ   ESC ИЗЛИЗА" as NSString
        let ha: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .bold),
                                                 .foregroundColor: NSColor(hex: 0x8d99ae)]
        hint.draw(at: NSPoint(x: 14, y: 44), withAttributes: ha)
    }
}

extension Game {
    func setUpDrawLayer() {
        for p in drawPanels { p.orderOut(nil) }
        drawPanels = []
        drawViews = []
        for screen in NSScreen.screens {
            let p = overlayPanel(screen.frame, key: true)
            p.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
            p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            let v = DrawLayer(frame: NSRect(origin: .zero, size: screen.frame.size))
            v.game = self
            p.contentView = v
            p.ignoresMouseEvents = !drawing
            p.orderFrontRegardless()
            drawPanels.append(p)
            drawViews.append(v)
        }
    }

    func redrawDrawing() { drawViews.forEach { $0.needsDisplay = true } }

    @objc func startDrawing() {
        if drawing { return }
        closeRetro()
        drawing = true
        pipetteOn = false
        newCellsThisSession = 0
        if drawPanels.count != NSScreen.screens.count { setUpDrawLayer() }
        for p in drawPanels { p.ignoresMouseEvents = false; p.orderFrontRegardless() }
        redrawDrawing()
        let screen = window.screen ?? NSScreen.main
        if let vf = screen?.visibleFrame {
            let size = DrawToolbar.size
            let tb = DrawToolbar(frame: NSRect(origin: .zero, size: size))
            tb.game = self
            let w = min(size.width, vf.width - 20)
            let p = overlayPanel(NSRect(x: vf.midX - w / 2, y: vf.maxY - size.height - 8, width: w, height: size.height), key: true)
            p.contentView = tb
            toolbarPanel = p
            NSApp.activate(ignoringOtherApps: true)
            p.makeKeyAndOrderFront(nil)
            p.makeFirstResponder(tb)
        }
        window.orderFrontRegardless()
        say("Нарисувай ми нещо, на което да стъпя!", seconds: 3)
    }

    func stopDrawing() {
        guard drawing else { return }
        drawing = false
        pipetteOn = false
        for p in drawPanels { p.ignoresMouseEvents = true }
        toolbarPanel?.orderOut(nil)
        toolbarPanel = nil
        redrawDrawing()
        saveDrawing()
        if newCellsThisSession >= 5 {
            fulfill(.platform)
            fulfillDrawRequest()
        }
        drawingChanged()
    }

    func clearDrawing() {
        drawCells.removeAll()
        redrawDrawing()
        saveDrawing()
    }

    func pickColor(at c: (Int, Int)) {
        if let color = drawCells[cellKey(c.0, c.1)] {
            pickedColor(color)
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
        pipetteOn = false
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

    /// Екранът под дадена точка (или най-близкият).
    func screenAt(_ p: NSPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(p) } ?? window.screen ?? NSScreen.main
    }

    /// Най-високата повърхност под краката: нарисуван пиксел или дъното на екрана.
    func supportY(x0: CGFloat, x1: CGFloat, feet: CGFloat) -> CGFloat {
        let floor0 = screenAt(NSPoint(x: (x0 + x1) / 2, y: feet + 5))?.visibleFrame.minY ?? 0
        var best = floor0
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
            if fallSpeed == 0 { fallFrom = feet }
            fallSpeed += CGFloat(1800 * step)
            let dy = min(fallSpeed * CGFloat(step), feet - support)
            window.setFrameOrigin(NSPoint(x: wf.minX, y: wf.minY - dy))
            if feet - dy <= support + 0.5 {
                // сърди се само ако е паднал от много високо
                if fallFrom - support > 350 && !pet.asleep && !pet.dead {
                    annoy(10, reason: "ме изпусна и паднах")
                    start(.angry, length: 1.5)
                    say(pick(fallLines, avoiding: &lastLine), seconds: 2.5)
                }
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
