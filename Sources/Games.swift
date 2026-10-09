// Игри на работния плот: „гони точката“, „балон“ и „криеница“.

import AppKit

// MARK: - Червената точка (следва мишката)

final class LaserView: NSView {
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let pulse = CGFloat(sin(game.time * 12)) * 1.5
        NSColor(hex: 0xe63946, alpha: 0.35).setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 1 - pulse, dy: 1 - pulse)).fill()
        NSColor(hex: 0xff3b3b).setFill()
        NSRect(x: bounds.midX - 4, y: bounds.midY - 4, width: 8, height: 8).fill()
        NSColor.white.setFill()
        NSRect(x: bounds.midX - 3, y: bounds.midY - 3, width: 2, height: 2).fill()
    }
}

// MARK: - Балон (цъкаш го нагоре, той го бута с глава)

let balloonGrid = grid([
    "..KKKK..",
    ".KRRRRK.",
    "KRWRRRRK",
    "KRWRRRRK",
    "KRRRRRRK",
    "KRRRRRRK",
    ".KRRRRK.",
    "..KRRK..",
    "...KK...",
    "....K...",
    "...K....",
    "....K...",
    "...K....",
])

final class BalloonView: NSView {
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.balloonTapped() }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        drawGrid(balloonGrid, x: 2, y: 2, s: 4, palette: game.color)
    }
}

enum SeekPhase { case off, counting, hiding }

extension Game {
    /// Спира всичко друго, преди да почне игра.
    func clearForGame() {
        endFetch()
        endLaser(reward: false)
        endBalloon(reward: false)
        closeRetro()
        walkTarget = nil
    }

    var playingGame: Bool { laserPanel != nil || balloonPanel != nil }

    // --- гони точката ---

    @objc func toggleLaser() {
        if laserPanel != nil { endLaser(reward: true); return }
        guard checkAwake(), !pet.working, errands.isEmpty else { busyForGame(); return }
        clearForGame()
        let p = overlayPanel(NSRect(x: 0, y: 0, width: 18, height: 18), key: false)
        p.level = .floating
        p.ignoresMouseEvents = true
        let v = LaserView(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        laserPanel = p
        laserUntil = time + 60
        laserHits = 0
        laserPause = 0
        say("Мърдай мишката! Ще хвана червената точка!", seconds: 3)
    }

    func busyForGame() {
        if pet.working || errands.contains(.fetchMonitor) { say("Сега монтирам! После ще играем.", seconds: 2.5) }
    }

    func updateLaser(_ step: Double) {
        guard let p = laserPanel else { return }
        if time > laserUntil || pet.asleep || hidePhase != .off { endLaser(reward: true); return }
        p.contentView?.needsDisplay = true
        let m = NSEvent.mouseLocation
        p.setFrameOrigin(NSPoint(x: m.x + 16, y: m.y - 30))
        if time < laserPause {
            p.alphaValue = 0
            walking = false
            return
        }
        p.alphaValue = 1
        let dot = NSPoint(x: p.frame.midX, y: p.frame.midY)
        let pr = petScreenRect()
        let target = NSPoint(x: window.frame.minX + dot.x - pr.midX, y: window.frame.minY + dot.y - pr.midY)
        walking = true
        _ = moveWindow(toward: target, speed: CGFloat((240 + Double(laserHits) * 12) * step))
        if petScreenRect().insetBy(dx: 12, dy: 12).contains(dot) {
            laserHits += 1
            laserPause = time + 1.4
            start(.love, length: 0.8)
            sfx("Pop", every: 0.1)
            say(["Хванах я! \(laserHits)", "Моя е! \(laserHits)", "Ха! \(laserHits)"].randomElement()!, seconds: 1.2)
        }
    }

    func endLaser(reward: Bool) {
        guard let p = laserPanel else { return }
        p.orderOut(nil)
        laserPanel = nil
        walking = false
        guard reward else { return }
        landOnFloor()
        pet.fun = (pet.fun + min(35, 8 + Double(laserHits) * 3)).clamped()
        pet.energy = (pet.energy - min(12, Double(laserHits))).clamped()
        anger = (anger - 10).clamped()
        earnCoins(laserHits * 2)
        addXP(laserHits * 2)
        say(laserHits > 0 ? "Хванах я \(laserHits) пъти! +\(laserHits * 2) монети" : "Не я хванах нито веднъж… Пак!", seconds: 3)
        fulfill(.play)
    }

    /// След игра в небето слиза долу със скок (без да се ядосва от падането).
    func landOnFloor() {
        let pr = petScreenRect()
        guard let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame else { return }
        let x = min(max(pr.midX, vf.minX + pr.width / 2), vf.maxX - pr.width / 2)
        if feetScreenY - vf.minY > 30 { jump(toFeet: NSPoint(x: x, y: vf.minY)) }
    }

    // --- балон ---

    @objc func toggleBalloon() {
        if balloonPanel != nil { endBalloon(reward: true); return }
        guard checkAwake(), !pet.working, errands.isEmpty else { busyForGame(); return }
        clearForGame()
        let pr = petScreenRect()
        let size = NSSize(width: 36, height: 56)
        let p = overlayPanel(NSRect(x: pr.midX - size.width / 2, y: pr.maxY + 160, width: size.width, height: size.height), key: false)
        p.level = .floating
        let v = BalloonView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        balloonPanel = p
        balloonVel = CGVector(dx: CGFloat.random(in: -40...40), dy: 0)
        balloonHits = 0
        balloonStart = time
        say("Не давай балона да падне! Цъкай го!", seconds: 3)
    }

    func balloonTapped() {
        balloonVel = CGVector(dx: CGFloat.random(in: -110...110), dy: 260)
        balloonHits += 1
        sfx("Pop", every: 0.05)
    }

    func updateBalloon(_ step: Double) {
        guard let p = balloonPanel else { return }
        if pet.asleep || hidePhase != .off || time - balloonStart > 180 { endBalloon(reward: true); return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let dt = CGFloat(step)
        balloonVel.dy = max(-110, balloonVel.dy - 120 * dt)
        balloonVel.dx *= 0.99
        var o = p.frame.origin
        o.x += balloonVel.dx * dt
        o.y += balloonVel.dy * dt
        if o.x < vf.minX { o.x = vf.minX; balloonVel.dx = abs(balloonVel.dx) }
        if o.x > vf.maxX - p.frame.width { o.x = vf.maxX - p.frame.width; balloonVel.dx = -abs(balloonVel.dx) }
        if o.y > vf.maxY - p.frame.height { o.y = vf.maxY - p.frame.height; balloonVel.dy = -abs(balloonVel.dy) }
        p.setFrameOrigin(o)
        // тича под балона
        let bx = o.x + p.frame.width / 2
        let target = NSPoint(x: window.frame.minX + bx - pr.midX, y: window.frame.minY)
        walking = abs(bx - pr.midX) > 6
        if walking { _ = moveWindow(toward: target, speed: CGFloat(230 * step)) }
        // удря го с глава
        if balloonVel.dy < 0 && o.y < pr.maxY + 6 && o.y > pr.maxY - 40 && abs(bx - pr.midX) < pr.width / 2 {
            balloonVel = CGVector(dx: CGFloat.random(in: -90...90), dy: CGFloat.random(in: 200...280))
            balloonHits += 1
            start(.wave, length: 0.6)
            sfx("Bottle", every: 0.2)
            say(["Хоп!", "С глава!", "Горе!", "Мой е!"].randomElement()! + " \(balloonHits)", seconds: 1)
        }
        if o.y <= vf.minY + 2 {
            say("Падна! \(balloonHits) удара!", seconds: 3)
            endBalloon(reward: true)
        }
    }

    func endBalloon(reward: Bool) {
        guard let p = balloonPanel else { return }
        p.orderOut(nil)
        balloonPanel = nil
        walking = false
        saveWindowPosition()
        guard reward else { return }
        let n = balloonHits
        pet.fun = (pet.fun + min(35, 8 + Double(n) * 2)).clamped()
        pet.energy = (pet.energy - min(10, Double(n) / 2)).clamped()
        anger = (anger - 10).clamped()
        earnCoins(n)
        addXP(n * 2)
        start(.love, length: 1.5)
        if bubbleText == nil { say("\(n) удара! +\(n) монети", seconds: 3) }
        fulfill(.play)
    }

    // --- криеница ---

    @objc func startSeek() {
        guard checkAwake(), seekPhase == .off, hidePhase == .off, errands.isEmpty else { busyForGame(); return }
        clearForGame()
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

    /// Крие се на различни места: зад програма, между два прозореца, зад клетката, зад приятеля,
    /// под горната лента, зад дока или зад ръба на екрана. Винаги се вижда малко от него.
    private func hideForSeek() {
        refreshWindows()
        let wf = window.frame
        let bodyW = view.bodyX1 - view.bodyX0
        let pr = petScreenRect()
        let screen = screenAt(NSPoint(x: pr.midX, y: pr.midY)) ?? NSScreen.main
        let vf = screen?.visibleFrame ?? .zero
        let sf = screen?.frame ?? .zero
        let lift = wf.height - view.feetY      // от краката до долния край на прозореца
        func put(feetX: CGFloat, feetY: CGFloat) {
            window.setFrameOrigin(NSPoint(x: feetX - bodyCenterOffset, y: feetY - lift))
        }

        var options: [Int] = [0, 0]                       // ръбът на екрана
        let big = windowRects.indices.filter { windowRects[$0].width > 200 && windowRects[$0].height > 150 }
        if !big.isEmpty { options += [1, 1, 1] }
        if big.count >= 2 { options += [2, 2] }
        if cagePanel != nil { options += [3, 3] }
        if friendPanel != nil { options.append(4) }
        options.append(5)                                  // под горната лента
        if vf.minY - sf.minY > 30 { options.append(6) }    // зад дока

        window.level = .floating
        switch options.randomElement()! {
        case 1, 2:
            // зад програма; при 2 е между два прозореца (над единия, под другия)
            let i = big.randomElement()!
            let r = windowRects[i]
            let leftSide = Bool.random()
            put(feetX: leftSide ? r.minX + bodyW * 0.25 : r.maxX - bodyW * 0.25, feetY: max(vf.minY, r.minY + 6))
            window.level = .normal
            if i < windowNumbers.count { window.order(.below, relativeTo: windowNumbers[i]) }
        case 3:
            if let c = cagePanel {
                put(feetX: c.frame.midX + (Bool.random() ? -1 : 1) * c.frame.width * 0.2, feetY: c.frame.minY)
                window.order(.below, relativeTo: c.windowNumber)
            }
        case 4:
            if let f = friendPanel {
                put(feetX: f.frame.midX + 30, feetY: f.frame.maxY - (friendView?.feetY ?? 0))
                window.order(.below, relativeTo: f.windowNumber)
            }
        case 5:
            // само краката висят под горната лента
            let x = CGFloat.random(in: (vf.minX + 80)...max(vf.minX + 81, vf.maxX - 80))
            put(feetX: x, feetY: vf.maxY - 14)
        case 6:
            // само темето се подава над дока
            let x = CGFloat.random(in: (vf.minX + 80)...max(vf.minX + 81, vf.maxX - 80))
            put(feetX: x, feetY: vf.minY - view.spriteRect.height + 26)
        default:
            let left = Bool.random()
            let x = left ? vf.minX - view.bodyX1 + bodyW * 0.3 : vf.maxX - view.bodyX0 - bodyW * 0.3
            window.setFrameOrigin(NSPoint(x: x, y: vf.minY - lift))
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
