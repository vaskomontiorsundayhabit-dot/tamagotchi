// Малко ретро меню с иконки (като това на Пиксчо) за яйцето, приятелите и любимците.

import AppKit

let iconWarm = grid([
    "...R....",
    "..RR.R..",
    "..RORR..",
    ".RROORR.",
    ".ROYYOR.",
    ".ROYYOR.",
    "..RRRR..",
    "........",
])
let iconTurn = grid([
    "..CCCC..",
    ".C....C.",
    "C......C",
    "C....CCC",
    "C.....C.",
    ".C......",
    "..CCCC..",
    "........",
])
let iconClean = grid([
    "......W.",
    ".YYYY...",
    "YYOYYY.W",
    "YYYYOY..",
    "YOYYYY..",
    ".YYYY.W.",
    "........",
    "........",
])
let iconTalk = grid([
    ".WWWWWW.",
    "WWKWKWKW",
    "WWWWWWWW",
    ".WWWWWW.",
    "..WW....",
    ".W......",
    "........",
    "........",
])
let iconSing = grid([
    "...MMMMM",
    "...M...M",
    "...M...M",
    "...M...M",
    ".MMM.MMM",
    "MMMMMMMM",
    ".MM..MM.",
    "........",
])
let iconBlanket = grid([
    "........",
    "RRRRYYYY",
    "RRRRYYYY",
    "YYYYRRRR",
    "YYYYRRRR",
    "RRRRYYYY",
    "RRRRYYYY",
    "........",
])
let iconHug = grid([
    "........",
    ".RR.RR..",
    "RRRRRRR.",
    "RRRRRRR.",
    ".RRRRR..",
    "..RRR...",
    "...R....",
    "........",
])
let iconHouse = grid([
    "...KK...",
    "..KRRK..",
    ".KRRRRK.",
    "KRRRRRRK",
    ".KQQQQK.",
    ".KQUUQK.",
    ".KQUUQK.",
    ".KKKKKK.",
])

struct MiniButton {
    let icon: Grid
    let label: String
    let enabled: Bool
    let action: () -> Void
}

final class MiniMenuView: NSView {
    weak var game: Game?
    var title = ""
    var stats: [(String, Double, Int)] = []      // име, 0…1, цвят
    var buttons: [MiniButton] = []
    var hover: Int?

    static let cell: CGFloat = 36
    static let pad: CGFloat = 12

    static func size(buttons: Int, stats: Int) -> NSSize {
        let w = max(240, pad * 2 + CGFloat(buttons) * cell)
        return NSSize(width: w, height: 40 + CGFloat(stats) * 14 + cell + 34)
    }

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    private var rowY: CGFloat { 36 + CGFloat(stats.count) * 14 }

    private func rect(_ i: Int) -> NSRect {
        let start = (bounds.width - CGFloat(buttons.count) * MiniMenuView.cell) / 2
        return NSRect(x: start + CGFloat(i) * MiniMenuView.cell, y: rowY, width: MiniMenuView.cell, height: MiniMenuView.cell)
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
        let action = buttons[i].action
        game?.closeMiniMenu()
        action()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let b = bounds
        NSColor(hex: 0x1b1b24, alpha: 0.97).setFill(); b.fill()
        NSColor.white.setFill()
        for r in [NSRect(x: 0, y: 0, width: b.width, height: 3), NSRect(x: 0, y: b.height - 3, width: b.width, height: 3),
                  NSRect(x: 0, y: 0, width: 3, height: b.height), NSRect(x: b.width - 3, y: 0, width: 3, height: b.height)] { r.fill() }
        NSColor(hex: 0x5dade2).setFill()
        NSRect(x: 5, y: 5, width: b.width - 10, height: 1).fill()
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy)
        let white: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]
        (title.uppercased() as NSString).draw(at: NSPoint(x: 12, y: 12), withAttributes: white)
        let small: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: 0x8d99ae)]
        for (i, s) in stats.enumerated() {
            let y = 32 + CGFloat(i) * 14
            (s.0.uppercased() as NSString).draw(at: NSPoint(x: 12, y: y), withAttributes: small)
            let bar = NSRect(x: 90, y: y + 2, width: b.width - 102, height: 7)
            NSColor(hex: 0x3a3a50).setFill(); bar.fill()
            NSColor(hex: s.2).setFill()
            NSRect(x: bar.minX, y: bar.minY, width: bar.width * CGFloat(max(0, min(1, s.1))), height: bar.height).fill()
        }
        for (i, btn) in buttons.enumerated() {
            let r = rect(i)
            if hover == i && btn.enabled { NSColor(hex: 0x3a3a50).setFill(); r.insetBy(dx: 2, dy: 2).fill() }
            let w = CGFloat(btn.icon[0].count), h = CGFloat(btn.icon.count)
            let s = min(3, 24 / max(w, h))
            let pal: (Character) -> NSColor? = btn.enabled ? { c in game.color(c) } : { c in game.color(c) == nil ? nil : NSColor(hex: 0x4a4a60) }
            drawGrid(btn.icon, x: r.midX - w * s / 2, y: r.midY - h * s / 2, s: s, palette: pal)
        }
        let label = hover.map { buttons[$0].label.uppercased() } ?? "ПОСОЧИ ИКОНКА"
        let ls = label as NSString
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 10, weight: .heavy),
                                                .foregroundColor: hover == nil ? NSColor(hex: 0x8d99ae) : NSColor.white]
        let sz = ls.size(withAttributes: a)
        ls.draw(at: NSPoint(x: (b.width - sz.width) / 2, y: b.height - 22), withAttributes: a)
    }
}

extension Game {
    /// Показва малкото меню над дадено място на екрана.
    func showMiniMenu(title: String, stats: [(String, Double, Int)], buttons: [MiniButton], above p: NSPoint) {
        closeMiniMenu()
        closeRetro()
        let size = MiniMenuView.size(buttons: buttons.count, stats: stats.count)
        let v = MiniMenuView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        v.title = title
        v.stats = stats
        v.buttons = buttons
        let vf = screenAt(p)?.visibleFrame ?? .zero
        var o = NSPoint(x: p.x - size.width / 2, y: p.y + 8)
        o.x = min(max(o.x, vf.minX + 4), vf.maxX - size.width - 4)
        o.y = min(max(o.y, vf.minY + 4), vf.maxY - size.height - 4)
        let panel = overlayPanel(NSRect(origin: o, size: size), key: false)
        panel.contentView = v
        panel.acceptsMouseMovedEvents = true
        panel.orderFrontRegardless()
        miniMenuPanel = panel
        miniMenuOpened = time
    }

    func closeMiniMenu() {
        miniMenuPanel?.orderOut(nil)
        miniMenuPanel = nil
    }

    /// Клик извън менюто го затваря.
    func updateMiniMenu() {
        guard let p = miniMenuPanel else { return }
        p.contentView?.needsDisplay = true
        if NSEvent.pressedMouseButtons != 0 && !p.frame.contains(NSEvent.mouseLocation) && time - miniMenuOpened > 0.4 {
            closeMiniMenu()
        }
    }
}
