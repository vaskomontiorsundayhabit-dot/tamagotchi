// Летящата чиния: преди обновяване минава над екрана и с лъча си прибира всичко
// (Пиксчо, приятелите, любимците, цветето, пикселите…). След обновяването пак минава и ги връща.

import AppKit

let ufoGrid = grid([
    "......KKKK......",
    ".....KCCCCK.....",
    "....KCWCCCCK....",
    "..KKKKKKKKKKKK..",
    ".KEEEEEEEEEEEEK.",
    "KEEYEEEYEEEYEEEK",
    ".KEEEEEEEEEEEEK.",
    "..KKKKKKKKKKKK..",
    "....KK....KK....",
])

final class UfoView: NSView {
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let blink = Int(game.time * 6) % 3
        drawGrid(ufoGrid, x: (bounds.width - 16 * 7) / 2, y: 6 + CGFloat(sin(game.time * 3)) * 3, s: 7, palette: { c in
            if c == "Y" { return NSColor(hex: [0xffd166, 0xe63946, 0x48cae4][blink]) }
            return game.color(c)
        })
    }
}

final class BeamView: NSView {
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let w = bounds.width, h = bounds.height
        let path = NSBezierPath()
        path.move(to: NSPoint(x: w / 2 - 25, y: 0))
        path.line(to: NSPoint(x: w / 2 + 25, y: 0))
        path.line(to: NSPoint(x: w, y: h))
        path.line(to: NSPoint(x: 0, y: h))
        path.close()
        NSColor(hex: 0xfff3b0, alpha: 0.28 + 0.08 * CGFloat(sin(game.time * 8))).setFill()
        path.fill()
        // искрици, които се издигат (или падат, когато ги връща)
        NSColor(hex: 0xffd166).setFill()
        for i in 0..<14 {
            var ph = CGFloat((game.time * 0.8 + Double(i) / 14).truncatingRemainder(dividingBy: 1))
            if game.ufoPhase == 2 { ph = 1 - ph }
            let y = h * (1 - ph)
            let spread = (y / h) * w / 2
            let x = w / 2 + CGFloat((i * 37) % 21 - 10) / 10 * spread * 0.8
            NSRect(x: x, y: y, width: 4, height: 4).fill()
        }
    }
}

extension Game {
    static let ufoDuration: Double = 7

    var ufoScreen: NSRect {
        let pr = petScreenRect()
        return screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
    }

    /// 1: прибира всичко преди обновяване, 2: връща всичко след него.
    func startUfo(_ phase: Int) {
        closeRetro(); closeMiniMenu(); closeQuestion(); closeShop()
        ufoPhase = phase
        ufoStart = time
        ufoPetBack = false
        let vf = ufoScreen
        ufoX = vf.minX - 120
        let up = overlayPanel(NSRect(x: ufoX - 70, y: vf.maxY - 90, width: 140, height: 80), key: false)
        up.ignoresMouseEvents = true
        let uv = UfoView(frame: NSRect(x: 0, y: 0, width: 140, height: 80))
        uv.game = self
        up.contentView = uv
        up.orderFrontRegardless()
        ufoPanel = up
        let bh = vf.height - 80
        let bp = overlayPanel(NSRect(x: ufoX - 90, y: vf.minY, width: 180, height: bh), key: false)
        bp.ignoresMouseEvents = true
        let bv = BeamView(frame: NSRect(x: 0, y: 0, width: 180, height: bh))
        bv.game = self
        bp.contentView = bv
        bp.orderFrontRegardless()
        beamPanel = bp
        sfx("Submarine")
        if phase == 1 {
            say("ЛЕТЯЩА ЧИНИЯ! Отнасят ни за обновяването! Връщаме се след малко!", seconds: 4)
        }
    }

    func updateUfo() {
        guard ufoPhase != 0 else { return }
        let vf = ufoScreen
        let k = min(1, (time - ufoStart) / Game.ufoDuration)
        ufoX = vf.minX - 120 + CGFloat(k) * (vf.width + 240)
        ufoPanel?.setFrameOrigin(NSPoint(x: ufoX - 70, y: vf.maxY - 90))
        beamPanel?.setFrameOrigin(NSPoint(x: ufoX - 90, y: vf.minY))
        ufoPanel?.contentView?.needsDisplay = true
        beamPanel?.contentView?.needsDisplay = true
        // връща Пиксчо: щом лъчът мине над него, пикселите му се събират
        if ufoPhase == 2 && !ufoPetBack && ufoX > petScreenRect().midX {
            ufoPetBack = true
            reviveUntil = time + 3.5
        }
        guard k >= 1 else { return }
        ufoPanel?.orderOut(nil); ufoPanel = nil
        beamPanel?.orderOut(nil); beamPanel = nil
        if ufoPhase == 1 {
            // всичко е прибрано; чака новата версия
            ufoPhase = 3
            if let pend = ufoPending { ufoPending = nil; finishUpdateNow(pend.0, replacing: pend.1) }
        } else {
            ufoPhase = 0
            if !ufoPetBack { reviveUntil = time + 3.5 }
        }
    }

    /// Кои прозорчета да не се виждат заради чинията (вече взети / още невърнати).
    func ufoHides(_ w: NSWindow) -> Bool {
        if w === ufoPanel || w === beamPanel { return false }
        switch ufoPhase {
        case 1: return w.frame.midX < ufoX - 30 && ufoScreen.insetBy(dx: -200, dy: -200).contains(NSPoint(x: w.frame.midX, y: w.frame.midY))
        case 2: return w.frame.midX > ufoX + 30
        case 3: return true
        default: return false
        }
    }

    /// Обновяването не стана: чинията връща всичко.
    func ufoCancel() {
        ufoPanel?.orderOut(nil); ufoPanel = nil
        beamPanel?.orderOut(nil); beamPanel = nil
        ufoPhase = 0
    }
}
