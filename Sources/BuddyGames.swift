// Игри между приятелите (и с плъха): гоненица, подаване на топка, танци.

import AppKit

enum BuddyGameKind { case tag, pass, dance }

struct BuddyGameState {
    var kind: BuddyGameKind
    var a: String
    var b: String
    var until: Double
    var chaserIsA = true
    var swapAt: Double = 0
    var ballFromA = true
    var ballT0: Double = 0
    var centerX: CGFloat = 0
    var runDir: CGFloat = 1
}

final class BallDotView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor(hex: 0x2b2b3a).setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1)).fill()
        NSColor(hex: 0xe63946).setFill()
        NSBezierPath(ovalIn: bounds.insetBy(dx: 3, dy: 3)).fill()
        NSColor.white.setFill()
        NSRect(x: 5, y: bounds.height - 8, width: 3, height: 3).fill()
    }
}

extension Game {
    func inBuddyGame(_ id: String) -> Bool {
        guard let g = buddyGame else { return false }
        return g.a == id || g.b == id
    }

    /// Пуска игра между двама (приятел с приятел или приятел с плъха).
    func startBuddyGame() {
        guard buddyGame == nil, hidePhase == .off else { return }
        let free = buddies.filter { !$0.leaving && !buddyAsleep($0) && !$0.working && $0.service == nil && !(racePhase != .off && raceBuddy === $0) }
        guard let first = free.randomElement() else { say("Няма кой да играе…", seconds: 2); return }
        var pool = free.filter { $0 !== first }.map { $0.kind.id }
        if ratIsOut && !carryingRat && !ratEatingCheese { pool.append("rat") }
        guard let second = pool.randomElement() else { say("Трябват им поне двама…", seconds: 2); return }
        let kind: BuddyGameKind = second == "rat" ? .tag : [.tag, .pass, .dance].randomElement()!
        var g = BuddyGameState(kind: kind, a: first.kind.id, b: second, until: time + Double.random(in: 18...28))
        let bx = second == "rat" ? (ratPanel?.frame.midX ?? 0) : (buddy(second).map { buddyScreenBox($0).midX } ?? 0)
        g.centerX = (buddyScreenBox(first).midX + bx) / 2
        g.ballT0 = time
        buddyGame = g
        let other = second == "rat" ? ratLabel : (buddyKind(second).map { buddyName($0) } ?? "")
        switch kind {
        case .tag: buddySay(first, "\(other)! Гоненица! Ти гониш… не, аз гоня!", 3)
        case .pass: buddySay(first, "\(other), хвани топката!", 3)
        case .dance: buddySay(first, "\(other), да танцуваме!", 3)
        }
        sfx("Pop")
    }

    private func gameX(_ id: String) -> CGFloat {
        if id == "rat" { return ratPanel?.frame.midX ?? 0 }
        return buddy(id).map { buddyScreenBox($0).midX } ?? 0
    }

    private func moveGameX(_ id: String, toward x: CGFloat, speed: CGFloat, floor: CGFloat, running: Bool) {
        if id == "rat" {
            guard let p = ratPanel, let v = ratView else { return }
            let dx = x - p.frame.midX
            let nx = p.frame.minX + (dx > 0 ? 1 : -1) * min(abs(dx), speed)
            p.setFrameOrigin(NSPoint(x: nx, y: floor))
            v.running = running && abs(dx) > 2
            if abs(dx) > 2 { v.facingLeft = dx < 0 }
            return
        }
        guard let b = buddy(id) else { return }
        let dx = x - buddyScreenBox(b).midX
        var o = b.panel.frame.origin
        o.x += (dx > 0 ? 1 : -1) * min(abs(dx), speed)
        o.y = floor - (BuddyView.size.height - b.view.feetY)
        b.panel.setFrameOrigin(o)
        b.view.walking = running && abs(dx) > 2
        if abs(dx) > 2 { b.view.facingLeft = dx < 0 }
    }

    private func gameSay(_ id: String, _ text: String) {
        if id == "rat" { ratSay(text, 1.5) } else if let b = buddy(id) { buddySay(b, text, 1.8) }
    }

    func updateBuddyGame(_ step: Double) {
        guard var g = buddyGame else { return }
        let alive: (String) -> Bool = { id in id == "rat" ? self.ratIsOut : self.buddy(id).map { !self.buddyAsleep($0) && !$0.leaving } ?? false }
        if time > g.until || !alive(g.a) || !alive(g.b) || hidePhase != .off {
            endBuddyGame()
            return
        }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let floor = vf.minY
        switch g.kind {
        case .tag:
            // който бяга, тича в една посока и се обръща чак при стената (без да трепери наляво-надясно)
            let chaser = g.chaserIsA ? g.a : g.b, runner = g.chaserIsA ? g.b : g.a
            let cx = gameX(chaser), rx = gameX(runner)
            if rx + g.runDir * 60 > vf.maxX - 30 || rx + g.runDir * 60 < vf.minX + 30 { g.runDir = -g.runDir }
            moveGameX(runner, toward: rx + g.runDir * 200, speed: CGFloat(150 * step), floor: floor, running: true)
            if time < g.swapAt {
                // току-що хванат: брои до три, преди да гони
                moveGameX(chaser, toward: cx, speed: 0, floor: floor, running: false)
            } else {
                moveGameX(chaser, toward: rx, speed: CGFloat(170 * step), floor: floor, running: true)
                if abs(cx - rx) < 30 {
                    g.chaserIsA.toggle()
                    g.swapAt = time + 1.2
                    g.runDir = cx >= rx ? 1 : -1      // новият бягащ тича в посоката, в която е гледал
                    gameSay(chaser, ["Хванах те!", "Гониш ти!", "Пипнах те!"].randomElement()!)
                    gameSay(runner, ["Ей!", "Не важи!", "Сега ще видиш!"].randomElement()!)
                }
            }
        case .pass:
            moveGameX(g.a, toward: g.centerX - 110, speed: CGFloat(120 * step), floor: floor, running: true)
            moveGameX(g.b, toward: g.centerX + 110, speed: CGFloat(120 * step), floor: floor, running: true)
            if gameBall == nil {
                let p = overlayPanel(NSRect(x: g.centerX, y: floor + 60, width: 16, height: 16), key: false)
                p.level = .floating
                p.ignoresMouseEvents = true
                p.contentView = BallDotView(frame: NSRect(x: 0, y: 0, width: 16, height: 16))
                p.orderFrontRegardless()
                gameBall = p
            }
            let k = CGFloat(min(1, (time - g.ballT0) / 1.1))
            let fromX = g.ballFromA ? gameX(g.a) : gameX(g.b), toX = g.ballFromA ? gameX(g.b) : gameX(g.a)
            gameBall?.setFrameOrigin(NSPoint(x: fromX + (toX - fromX) * k - 8, y: floor + 40 + 120 * k * (1 - k)))
            if k >= 1 {
                g.ballFromA.toggle()
                g.ballT0 = time + (Int.random(in: 0..<8) == 0 ? 1.5 : 0)
                if Int.random(in: 0..<8) == 0 { gameSay(g.ballFromA ? g.a : g.b, "Изпуснах я! Хаха!") }
            }
        case .dance:
            for id in [g.a, g.b] {
                if let b = buddy(id) {
                    b.view.walking = Int(time * 4) % 2 == 0
                    b.view.face = .happy
                    var o = b.panel.frame.origin
                    o.y = floor - (BuddyView.size.height - b.view.feetY) + abs(CGFloat(sin(time * 6))) * 10
                    b.panel.setFrameOrigin(o)
                }
            }
            if Int(time * 2) % 6 == 0 && Int(time * 30) % 15 == 0 { gameSay(g.a, ["♪ Ла-ла!", "Въртим се!", "Йе!"].randomElement()!) }
        }
        buddyGame = g
    }

    func endBuddyGame() {
        guard let g = buddyGame else { return }
        buddyGame = nil
        gameBall?.orderOut(nil)
        gameBall = nil
        for id in [g.a, g.b] {
            if let b = buddy(id) { b.view.walking = false; b.wanderX = nil }
            gameSay(id, id == "rat" ? "Цик! Пак!" : ["Беше забавно!", "Пак ще играем!", "Уф, изморих се!"].randomElement()!)
        }
        if g.b == "rat" { ratPlayedAt = Date() }
        changeFriendship(g.a, 5)
        if g.b != "rat" { changeFriendship(g.b, 5) }
    }
}
