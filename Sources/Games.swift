// Две игри: „пикселна битка“ (хвърляш пиксели, той ги отбива) и „криеница“.

import AppKit

final class BattleView: NSView {
    weak var game: Game?
    struct Shot { var p: NSPoint; var v: CGVector; var deflected: Bool; var color: Int }
    var shots: [Shot] = []
    var petX: CGFloat = 0
    var you = 0
    var him = 0
    var time: Double = 0
    var over = false
    var blockUntil: Double = 0
    var ouchUntil: Double = 0
    var timer: Timer?
    let length: Double = 30

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    var ground: CGFloat { bounds.height - 40 }
    var petRect: NSRect { NSRect(x: petX - 50, y: ground - 120, width: 100, height: 120) }

    func start() {
        shots = []; you = 0; him = 0; time = 0; over = false
        petX = bounds.midX
        timer?.invalidate()
        let t = Timer(timeInterval: 1.0 / 60, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() { timer?.invalidate(); timer = nil }

    override func mouseDown(with event: NSEvent) {
        if over { start(); return }
        let p = convert(event.locationInWindow, from: nil)
        let target = NSPoint(x: petX + CGFloat.random(in: -30...30), y: ground - 60)
        let d = max(1, hypot(target.x - p.x, target.y - p.y))
        shots.append(Shot(p: p, v: CGVector(dx: (target.x - p.x) / d * 750, dy: (target.y - p.y) / d * 750),
                          deflected: false, color: foodColors.randomElement()!))
        game?.sfx("Pop", every: 0.05)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { game?.closeBattle() }
        else if event.keyCode == 49 && over { start() }
        else { super.keyDown(with: event) }
    }

    @objc func step() {
        let dt = 1.0 / 60
        guard !over else { needsDisplay = true; return }
        time += dt
        if time >= length { over = true; needsDisplay = true; return }
        // мести се към най-близкия пиксел
        if let near = shots.filter({ !$0.deflected }).min(by: { $0.p.y > $1.p.y }) {
            let dx = near.p.x - petX
            petX += max(-7, min(7, dx * 0.08))
        }
        let level = Double(game?.pet.level ?? 1)
        let blockChance = min(0.75, 0.45 + level / 600)
        var keep: [Shot] = []
        for var s in shots {
            s.p.x += s.v.dx * CGFloat(dt)
            s.p.y += s.v.dy * CGFloat(dt)
            if !s.deflected && petRect.contains(s.p) {
                if Double.random(in: 0..<1) < blockChance {
                    s.deflected = true
                    s.v = CGVector(dx: CGFloat.random(in: -500...500), dy: -700)
                    him += 1
                    blockUntil = time + 0.3
                    game?.sfx("Bottle", every: 0.1)
                } else {
                    you += 1
                    ouchUntil = time + 0.4
                    game?.sfx("Funk", every: 0.2)
                    continue
                }
            }
            if s.p.y < -40 || s.p.y > bounds.height + 40 || s.p.x < -40 || s.p.x > bounds.width + 40 { continue }
            keep.append(s)
        }
        shots = keep
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        NSColor(hex: 0x0b0b14, alpha: 0.55).setFill(); bounds.fill()
        NSColor(hex: 0x2b2b3a, alpha: 0.9).setFill()
        NSRect(x: 0, y: ground, width: bounds.width, height: bounds.height - ground).fill()
        let font = NSFont.monospacedSystemFont(ofSize: 20, weight: .heavy)
        func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ c: Int, _ f: NSFont? = nil, center: Bool = false) {
            let a: [NSAttributedString.Key: Any] = [.font: f ?? font, .foregroundColor: NSColor(hex: c)]
            let ns = s as NSString
            ns.draw(at: NSPoint(x: center ? x - ns.size(withAttributes: a).width / 2 : x, y: y), withAttributes: a)
        }
        text("ТИ: \(you)", 30, 40, 0xffd166)
        text("ПИКСЧО: \(him)", 30, 66, 0x48cae4)
        text("ВРЕМЕ: \(max(0, Int(length - time)))", 30, 92, 0xffffff)
        text("КЛИКАЙ, ЗА ДА ХВЪРЛЯШ    ESC  ИЗХОД", bounds.width - 470, 40, 0xffffff)

        let blocking = time < blockUntil, ouch = time < ouchUntil
        let sp = buildSprite(level: game.bodyCells, face: ouch ? .angry : (blocking ? .happy : .focus),
                             pose: blocking ? .wave : .idle, frame: Int(time * 8), working: false,
                             worn: game.pet.worn, variant: game.bodyVariant)
        let s: CGFloat = 4
        drawGrid(sp.grid, x: petX - CGFloat(sp.cx) * s, y: ground - CGFloat(sp.groundY + 1) * s, s: s, palette: game.color)
        if blocking { text("ОТБИХ!", petX, ground - 150, 0x48cae4, center: true) }
        if ouch { text("АУ!", petX, ground - 150, 0xe63946, center: true) }

        for sh in shots {
            NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: sh.p.x - 8, y: sh.p.y - 8, width: 16, height: 16).fill()
            NSColor(hex: sh.color).setFill(); NSRect(x: sh.p.x - 6, y: sh.p.y - 6, width: 12, height: 12).fill()
        }

        if over {
            let big = NSFont.monospacedSystemFont(ofSize: 44, weight: .heavy)
            text("КРАЙ!", bounds.midX, bounds.height * 0.3, 0xffffff, big, center: true)
            text(you > him ? "ТИ ПЕЧЕЛИШ \(you):\(him)" : (you == him ? "РАВЕНСТВО \(you):\(him)" : "ПИКСЧО ПЕЧЕЛИ \(him):\(you)"),
                 bounds.midX, bounds.height * 0.3 + 70, 0xffd166, big, center: true)
            text("КЛИК ИЛИ SPACE  ОТНОВО     ESC  ИЗХОД", bounds.midX, bounds.height * 0.3 + 140, 0x8d99ae, center: true)
        }
    }
}

enum SeekPhase { case off, counting, hiding }

extension Game {
    // --- пикселна битка ---

    @objc func startBattle() {
        guard checkAwake(), battlePanel == nil, let screen = window.screen ?? NSScreen.main else { return }
        endFetch()
        pet.working = false
        let p = overlayPanel(screen.frame, key: true)
        let v = BattleView(frame: NSRect(origin: .zero, size: screen.frame.size))
        v.game = self
        p.contentView = v
        battlePanel = p
        battleView = v
        window.orderOut(nil)
        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)
        p.makeFirstResponder(v)
        v.start()
    }

    func closeBattle() {
        guard let p = battlePanel, let v = battleView else { return }
        v.stop()
        p.orderOut(nil)
        battlePanel = nil
        battleView = nil
        window.orderFrontRegardless()
        let total = v.you + v.him
        guard total > 0 else { return }
        pet.fun = (pet.fun + min(30, Double(total))).clamped()
        pet.energy = (pet.energy - min(12, Double(total) / 4)).clamped()
        earnCoins(v.you / 2)
        addXP(total)
        start(v.him >= v.you ? .love : .angry, length: 2)
        say(v.him >= v.you ? "Отбих \(v.him)! Аз съм стена!" : "Уцели ме \(v.you) пъти! Реванш!", seconds: 3)
        fulfill(.play)
    }

    // --- криеница ---

    @objc func startSeek() {
        guard checkAwake(), seekPhase == .off, hidePhase == .off else { return }
        endFetch()
        pet.working = false
        seekHome = window.frame.origin
        seekPhase = .counting
        seekStart = time
        say("Затвори очи и брой до 3! Не гледай!", seconds: 2.5)
    }

    func updateSeek() {
        switch seekPhase {
        case .off:
            return
        case .counting:
            window.alphaValue = CGFloat(max(0, 1 - (time - seekStart - 2) / 1))
            if time - seekStart > 3 { hideForSeek() }
        case .hiding:
            if time - seekStart > 90 {
                endSeek()
                jump(toOrigin: seekHome)
                say("Не ме намери! Ха-ха! Бях тук!", seconds: 3)
            }
        }
    }

    /// Скрива се зад някой прозорец (отчасти се показва) или зад ръба на екрана.
    private func hideForSeek() {
        refreshWindows()
        let bodyW = view.bodyX1 - view.bodyX0
        let wf = window.frame
        var placed = false
        let candidates = windowRects.indices.filter { windowRects[$0].width > 200 && windowRects[$0].height > 150 }
        if let i = candidates.randomElement() {
            let r = windowRects[i]
            let leftSide = Bool.random()
            let cx = leftSide ? r.minX + bodyW * 0.25 : r.maxX - bodyW * 0.25
            let feet = r.minY + 6
            window.setFrameOrigin(NSPoint(x: cx - bodyCenterOffset, y: feet - (wf.height - view.feetY)))
            window.level = .normal
            if i < windowNumbers.count { window.order(.below, relativeTo: windowNumbers[i]) }
            placed = true
        }
        if !placed, let vf = (window.screen ?? NSScreen.main)?.visibleFrame {
            let left = Bool.random()
            let x = left ? vf.minX - view.bodyX1 + bodyW * 0.3 : vf.maxX - view.bodyX0 - bodyW * 0.3
            window.setFrameOrigin(NSPoint(x: x, y: vf.minY - (wf.height - view.feetY)))
        }
        window.alphaValue = 1
        bubbleText = nil
        seekPhase = .hiding
        seekStart = time
    }

    func foundInSeek() {
        let secs = Int(time - seekStart)
        endSeek()
        earnCoins(10)
        addXP(8)
        start(.love, length: 2)
        sfx("Hero")
        say("Намери ме за \(secs) секунди! Браво! +10 монети", seconds: 3)
        fulfill(.play)
        jump(toOrigin: seekHome)
    }

    func endSeek() {
        seekPhase = .off
        window.alphaValue = 1
        window.level = .floating
        window.orderFrontRegardless()
    }
}
