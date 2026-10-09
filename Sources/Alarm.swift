// Кофа за пиксели, звънче за тревога и криене зад ръба на екрана.

import AppKit

enum HidePhase { case off, grabRat, running, hidden, peeking }

let peekLines = ["Отиде ли си?", "Тихо ли е вече?", "Страх ме е…", "Някой още ли звъни?",
                 "Ще изляза само ако е чисто…", "Пссст… опасно ли е?", "Аз не съм тук.", "Чувам те, звънче!"]
let hiddenReturnLines = ["Ей, къде бях? Беше тъмно!", "Защо ме скри? Изплаших се!", "Кой загаси лампата?!"]

let bellGrid = grid([
    "....KK....",
    "...KYYK...",
    "..KYYYYK..",
    "..KYWYYK..",
    ".KYWYYYYK.",
    ".KYYYYYYK.",
    "KYYYYYYYYK",
    "KKKKKKKKKK",
    "....KK....",
])
let binGrid = grid([
    ".EEEEEEEE.",
    "EEEEEEEEEE",
    ".KKKKKKKK.",
    ".KSEESEESK",
    ".KSEESEESK",
    ".KSEESEESK",
    ".KSEESEESK",
    ".KSEESEESK",
    "..KKKKKKK.",
])

// MARK: - Кофа

final class BinView: NSView {
    weak var game: Game?
    var gulpAt: Double = -10
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let open = game.time - gulpAt < 0.6
        var g = binGrid
        if open { g[0] = Array(".........."); g[1] = Array("EEEEE.....") }
        drawGrid(g, x: 2, y: 8, s: 5, palette: game.color)
        if open {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: 0x52b788)]
            ("ХАМ!" as NSString).draw(at: NSPoint(x: 16, y: 0), withAttributes: a)
        }
    }
}

// MARK: - Звънче

final class BellView: NSView {
    weak var game: Game?
    private var dragStart: NSPoint?
    private var windowStart = NSPoint.zero
    private var lastX: CGFloat = 0
    private var lastDir: CGFloat = 0
    private var flips: [Double] = []
    private var moved = false

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        windowStart = window?.frame.origin ?? .zero
        lastX = NSEvent.mouseLocation.x
        lastDir = 0
        flips = []
        moved = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart, let window, let game else { return }
        let p = NSEvent.mouseLocation
        if abs(p.x - start.x) + abs(p.y - start.y) > 3 { moved = true }
        window.setFrameOrigin(NSPoint(x: windowStart.x + p.x - start.x, y: windowStart.y + p.y - start.y))
        // разклащане: смяна на посоката наляво/надясно
        let dx = p.x - lastX
        if abs(dx) > 3 {
            let dir: CGFloat = dx > 0 ? 1 : -1
            if lastDir != 0 && dir != lastDir {
                game.dingBell()
                flips.append(game.time)
                flips.removeAll { game.time - $0 > 1.2 }
                if flips.count >= 4 { flips.removeAll(); game.ringAlarm() }
            }
            lastDir = dir
            lastX = p.x
        }
    }

    override func mouseUp(with event: NSEvent) {
        dragStart = nil
        if !moved { game?.dingBell() }
        if let o = window?.frame.origin {
            UserDefaults.standard.set(Double(o.x), forKey: "bellX")
            UserDefaults.standard.set(Double(o.y), forKey: "bellY")
        }
        game?.bellDropped()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let ringing = game.time - game.lastDing < 0.4
        let ctx = NSGraphicsContext.current
        ctx?.saveGraphicsState()
        if ringing {
            let tr = NSAffineTransform()
            tr.translateX(by: bounds.midX, yBy: 8)
            tr.rotate(byRadians: CGFloat(sin(game.time * 40)) * 0.35)
            tr.translateX(by: -bounds.midX, yBy: -8)
            tr.concat()
        }
        drawGrid(bellGrid, x: (bounds.width - 30) / 2, y: 12, s: 3, palette: game.color)
        ctx?.restoreGraphicsState()
        if ringing {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: 0xe63946)]
            ("ДЗЪН!" as NSString).draw(at: NSPoint(x: 2, y: 0), withAttributes: a)
        }
    }
}

// MARK: - Логиката

extension Game {
    // --- кофа ---

    func showBin(near food: FoodPixel) {
        guard binPanel == nil else { return }
        let f = food.panel.frame
        let vf = screenAt(NSPoint(x: f.midX, y: f.midY))?.visibleFrame ?? .zero
        let size = NSSize(width: 56, height: 56)
        // отстрани на екрана, откъм по-далечния от Пиксчо ъгъл
        let pr = petScreenRect()
        let x = pr.midX > vf.midX ? vf.minX + 20 : vf.maxX - size.width - 20
        let p = overlayPanel(NSRect(x: x, y: vf.minY + 10, width: size.width, height: size.height), key: false)
        p.level = .floating
        p.ignoresMouseEvents = true
        let v = BinView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        binPanel = p
        binView = v
    }

    /// Пуснат пиксел върху кофата? Тогава го изхвърля.
    func tryBin(_ food: FoodPixel) -> Bool {
        guard let p = binPanel else { return false }
        let f = food.panel.frame
        if p.frame.insetBy(dx: -12, dy: -12).contains(NSPoint(x: f.midX, y: f.midY)) {
            food.remove()
            foods.removeAll { $0 === food }
            binView?.gulpAt = time
            binHideAt = time + 0.9
            if window.isVisible && !pet.asleep {
                say(food.spoiled ? "Браво, развален беше!" : "Ей, тоя можеше да го изям!", seconds: 2)
            }
            return true
        }
        binHideAt = time + 0.3
        return false
    }

    func updateBin() {
        binView?.needsDisplay = true
        if binPanel != nil && binHideAt > 0 && time > binHideAt {
            binPanel?.orderOut(nil)
            binPanel = nil
            binView = nil
            binHideAt = 0
        }
    }

    // --- звънче ---

    func setUpBell() {
        guard bellOn, bellPanel == nil, let vf = NSScreen.main?.visibleFrame else { return }
        let d = UserDefaults.standard
        let size = NSSize(width: 44, height: 44)
        var o = NSPoint(x: vf.minX + 70, y: vf.minY + 4)
        if d.object(forKey: "bellX") != nil { o = NSPoint(x: d.double(forKey: "bellX"), y: d.double(forKey: "bellY")) }
        let p = overlayPanel(NSRect(origin: o, size: size), key: false)
        p.level = .floating
        let v = BellView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        bellPanel = p
        bellView = v
    }

    @objc func toggleBell() {
        bellOn.toggle()
        if bellOn { setUpBell() } else { bellPanel?.orderOut(nil); bellPanel = nil; bellView = nil }
    }

    func dingBell() {
        guard time - lastDing > 0.1 else { return }
        lastDing = time
        NSSound(named: NSSound.Name("Tink"))?.play()
    }

    func bellDropped() {}

    /// Тревога: бяга и се крие. Ако вече е скрит, звънчето го вика обратно.
    func ringAlarm() {
        guard time - lastAlarm > 2, !pet.dead else { return }
        lastAlarm = time
        if hidePhase == .off { startHiding() } else { comeOutOfHiding() }
    }

    func startHiding() {
        guard window.isVisible else { return }
        if pet.asleep { pet.asleep = false }
        if pet.working { pet.working = false }
        if monitorDetached { reattachMonitor() }
        endFetch()
        clearForGame()
        cancelErrands()
        if seekPhase != .off { endSeek() }
        closeQuestion()
        hideHome = window.frame.origin
        walkTarget = nil
        chasing = false
        annoy(10, reason: "звънеше тревога")
        glitchUntil = time + 0.5
        if ratIsOut && !carryingRat {
            // първо тича да грабне плъха за опашката
            hidePhase = .grabRat
            say(["ТРЕВОГА! \(ratLabel.uppercased()), ЕЛА!", "АААА! Къде е \(ratLabel)?!", "Опасност! Взимам \(ratLabel) и бягам!"]
                .randomElement()!, seconds: 2)
            return
        }
        beginHideRun()
        say(["ТРЕВОГА! Крия се!", "АААА! Бягам!", "Опасност! Не ме търсете!"].randomElement()!, seconds: 2)
    }

    private func beginHideRun() {
        let pr = petScreenRect()
        let sf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.frame ?? .zero
        hideLeft = pr.midX - sf.minX < sf.maxX - pr.midX
        hideScreen = sf
        hidePhase = .running
    }

    func comeOutOfHiding() {
        guard hidePhase != .off else { return }
        closeQuestion()
        hidePhase = .off
        bubbleText = nil
        jump(toOrigin: hideHome)
        anger = (anger - 10).clamped()
        say(["Чисто ли е? Излизам!", "Уф, мина ли? Връщам се!", "Може ли вече? Идвам!"].randomElement()!, seconds: 2.5)
    }

    /// Къде е прозорецът, за да е зад ръба на екрана (скрит) или само да наднича.
    private func hideX(peek: Bool) -> CGFloat {
        let bodyW = view.bodyX1 - view.bodyX0
        if hideLeft {
            return hideScreen.minX - view.bodyX1 - 8 + (peek ? bodyW * 0.25 : 0)
        }
        return hideScreen.maxX - view.bodyX0 + 8 - (peek ? bodyW * 0.25 : 0)
    }

    func updateHiding(_ step: Double) {
        let y = window.frame.minY
        switch hidePhase {
        case .off:
            return
        case .grabRat:
            guard ratIsOut, let rp = ratPanel else { beginHideRun(); return }
            if walkTo(feet: NSPoint(x: rp.frame.midX, y: rp.frame.minY), speed: 900, step) {
                carryingRat = true
                ratSay("ЦИИИК!", 1.5)
                sfx("Pop")
                beginHideRun()
            }
        case .running:
            walking = true
            facingLeft = hideLeft
            if moveWindow(toward: NSPoint(x: hideX(peek: false), y: y), speed: CGFloat(700 * step)) {
                walking = false
                hidePhase = .hidden
                bubbleText = nil
                // наднича след 2, после след 4, после след 6 минути…
                peekCount = 1
                nextPeek = time + 120
            }
        case .hidden:
            _ = moveWindow(toward: NSPoint(x: hideX(peek: false), y: y), speed: CGFloat(260 * step))
            if time > nextPeek {
                hidePhase = .peeking
                peekUntil = time + 4
                nextHideAsk = time + 1.5
                facingLeft = !hideLeft
            }
        case .peeking:
            // наднича мълчаливо; излиза със звънчето или с клик върху него
            _ = moveWindow(toward: NSPoint(x: hideX(peek: true), y: y), speed: CGFloat(160 * step))
            if time > peekUntil {
                hidePhase = .hidden
                peekCount += 1
                nextPeek = time + 120 * Double(peekCount)
            }
        }
    }

    // --- скрит от менюто ---

    func noteHidden(_ hidden: Bool) {
        if hidden {
            hiddenSince = Date()
            UserDefaults.standard.set(hiddenSince, forKey: "hiddenSince")
            closeQuestion()
            closeRetro()
            return
        }
        guard let since = hiddenSince ?? UserDefaults.standard.object(forKey: "hiddenSince") as? Date else { return }
        hiddenSince = nil
        UserDefaults.standard.removeObject(forKey: "hiddenSince")
        let m = Int(Date().timeIntervalSince(since) / 60)
        if m < 1 { say(pick(hiddenReturnLines, avoiding: &lastLine), seconds: 3) }
        else if m < 60 { say("Беше тъмно цели \(m) мин.! Скучно ми беше!", seconds: 3.5); annoy(Double(min(m, 20))) }
        else { say("Къде ме държа \(m / 60) ч. в тъмното?! Сърдит съм!", seconds: 4); annoy(30, reason: "ме държа скрит") }
    }
}
