// Пиксел плъхът: храни се, играе, гушка се, има клетка, сърди се, когато Пиксчо го забрави,
// краде от пикселите му и бяга с Пиксчо при тревога (за опашката).

import AppKit

enum RatGoal { case food(FoodPixel), pixel, ball }

let ratAngryLines = ["Цик! Гладен съм! Забрави ме!", "Цик-цик! Къде ми е храната?!", "Сърдит съм ти, цик!",
                     "Никой не се грижи за мен… цик.", "ЦИК! Купичката е празна!"]
let ratHappyLines = ["Цик!", "Цик-цик!", "Хи-цик!", "Мрън… цик.", "Обичам те, цик!"]

final class RatView: NSView {
    weak var game: Game?
    var facingLeft = false
    var running = false
    var hanging = false
    var text: String?
    var textUntil: Double = 0
    var heartsUntil: Double = 0
    var loot = 0                     // 1 = открадната частица, 2 = топката
    static let size = NSSize(width: 170, height: 66)
    /// Къде е върхът на опашката, докато виси (от долния край на прозорчето).
    static let tailTop: CGFloat = 46
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.ratClicked() }

    static func ratGrid(frame: Int, running: Bool) -> Grid {
        var g = grid([
            "....KK..........",
            "...KEEK.........",
            "..KEEEEKKKK.....",
            ".KEWKEEEEEEKK...",
            "KREEEEEEEEEEEK.P",
            ".KEEEEEEEEEEK.P.",
            "..KKK.KK.KKKPP..",
        ])
        if running && frame % 2 == 1 { g[6] = Array("...KK.KK..KK.P..") }
        return g
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let g = RatView.ratGrid(frame: Int(game.time * (running ? 12 : 3)), running: running)
        let s: CGFloat = 2.75
        let w = CGFloat(g[0].count) * s, h = CGFloat(g.count) * s
        let x = (bounds.width - w) / 2, y = bounds.height - h - 2
        let palette: (Character) -> NSColor? = { c in c == "R" ? NSColor(hex: 0xff8fab) : game.color(c) }
        if hanging {
            // виси за опашката: опашката горе (в ръката), главата надолу
            let ctx = NSGraphicsContext.current
            ctx?.saveGraphicsState()
            let cy = bounds.height - w / 2 - 2
            let tr = NSAffineTransform()
            tr.translateX(by: bounds.midX, yBy: cy)
            tr.rotate(byDegrees: -90)
            tr.translateX(by: -bounds.midX, yBy: -cy)
            tr.concat()
            drawGrid(g, x: x, y: cy - h / 2, s: s, flip: false, palette: palette)
            ctx?.restoreGraphicsState()
            // крачетата мърдат
            if Int(game.time * 8) % 2 == 0 {
                NSColor(hex: 0x2b2b3a).setFill()
                NSRect(x: bounds.midX + h / 2 - 1, y: bounds.height - 14, width: 3, height: 3).fill()
            }
        } else {
            drawGrid(g, x: x, y: y, s: s, flip: !facingLeft, palette: palette)
            if loot == 1 {
                // откраднат пиксел в устата
                let mx = facingLeft ? x - 4 : x + w - 2
                NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: mx - 1, y: y + 9, width: 8, height: 8).fill()
                (game.color("B") ?? .yellow).setFill(); NSRect(x: mx, y: y + 10, width: 6, height: 6).fill()
            }
        }
        if game.ratAngry && !hanging {
            // сърдито знакче над главата
            let ax = facingLeft ? x + 4 : x + w - 10
            NSColor(hex: 0xe63946).setFill()
            for (dx, dy) in [(0, 0), (4, 0), (0, 4), (4, 4), (2, 2)] {
                NSRect(x: ax + CGFloat(dx), y: y - 10 + CGFloat(dy), width: 2, height: 2).fill()
            }
        }
        if game.time < heartsUntil {
            let ph = CGFloat((heartsUntil - game.time).truncatingRemainder(dividingBy: 1))
            drawGrid(heartGrid, x: bounds.midX - 8, y: y - 14 - (1 - ph) * 10, s: 2, palette: game.color)
        }
        if let text, game.time < textUntil {
            drawRatBubble(text, in: self, bottom: hanging ? 18 : y - 2)
        }
    }
}

/// Малко балонче (за плъха и клетката).
func drawRatBubble(_ text: String, in view: NSView, bottom: CGFloat) {
    let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .bold),
                                            .foregroundColor: NSColor.white]
    let str = text.uppercased() as NSString
    let size = str.boundingRect(with: NSSize(width: view.bounds.width - 12, height: 40), options: [.usesLineFragmentOrigin],
                                attributes: a).size
    let w = ceil(size.width) + 8, h = ceil(size.height) + 4
    let r = NSRect(x: (view.bounds.width - w) / 2, y: max(0, bottom - h), width: w, height: h)
    NSColor(hex: 0x4a3a5a, alpha: 0.95).setFill(); r.fill()
    str.draw(with: r.insetBy(dx: 4, dy: 2), options: [.usesLineFragmentOrigin], attributes: a)
}

// MARK: - Клетката

final class CageView: NSView {
    weak var game: Game?
    static let size = NSSize(width: 150, height: 96)
    private var dragStart: NSPoint?
    private var windowStart = NSPoint.zero
    private var moved = false
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragStart = NSEvent.mouseLocation
        windowStart = window?.frame.origin ?? .zero
        moved = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let s = dragStart, let window else { return }
        let p = NSEvent.mouseLocation
        if abs(p.x - s.x) > 3 { moved = true }
        if moved { window.setFrameOrigin(NSPoint(x: windowStart.x + p.x - s.x, y: windowStart.y)) }
    }

    override func mouseUp(with event: NSEvent) {
        dragStart = nil
        if moved {
            UserDefaults.standard.set(Double(window?.frame.minX ?? 0), forKey: "cageX")
        } else {
            game?.cageClicked()
        }
    }

    var cageRect: NSRect { NSRect(x: (bounds.width - 84) / 2, y: bounds.height - 62, width: 84, height: 60) }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let r = cageRect
        // дъно и покрив
        NSColor(hex: 0x8b5a2b).setFill()
        NSRect(x: r.minX - 4, y: r.maxY - 6, width: r.width + 8, height: 6).fill()
        NSColor(hex: 0x5c3a1e).setFill()
        NSRect(x: r.minX - 2, y: r.minY, width: r.width + 4, height: 5).fill()
        NSRect(x: r.midX - 6, y: r.minY - 6, width: 12, height: 6).fill()
        // плъхът вътре
        if game.ratInCage {
            let g = RatView.ratGrid(frame: Int(game.time * 3), running: false)
            let s: CGFloat = 2.5
            let w = CGFloat(g[0].count) * s
            let bob = Int(game.time * 2) % 2 == 0 ? 0 : CGFloat(1)
            drawGrid(g, x: r.midX - w / 2, y: r.maxY - 6 - CGFloat(g.count) * s - bob, s: s, flip: true,
                     palette: { c in c == "R" ? NSColor(hex: 0xff8fab) : game.color(c) })
            // купичка
            NSColor(hex: 0x5dade2).setFill()
            NSRect(x: r.minX + 6, y: r.maxY - 12, width: 14, height: 6).fill()
            if game.ratHungryMinutes < 30 {
                NSColor(hex: 0xffca3a).setFill(); NSRect(x: r.minX + 9, y: r.maxY - 14, width: 8, height: 3).fill()
            }
        }
        // решетките
        NSColor(hex: 0x8d99ae).setFill()
        var bx = r.minX
        while bx <= r.maxX {
            NSRect(x: bx, y: r.minY + 5, width: 2, height: r.height - 11).fill()
            bx += 8
        }
        NSRect(x: r.minX, y: r.minY + 5, width: r.width + 2, height: 2).fill()
        if let text = game.ratView?.text, game.ratInCage, game.time < (game.ratView?.textUntil ?? 0) {
            drawRatBubble(text, in: self, bottom: r.minY - 8)
        }
    }
}

// MARK: - Логиката

extension Game {
    var ratInCage: Bool {
        get { UserDefaults.standard.bool(forKey: "ratInCage") }
        set { UserDefaults.standard.set(newValue, forKey: "ratInCage") }
    }

    var ratFedAt: Date {
        get { UserDefaults.standard.object(forKey: "ratFedAt") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "ratFedAt") }
    }

    var ratPlayedAt: Date {
        get { UserDefaults.standard.object(forKey: "ratPlayedAt") as? Date ?? Date() }
        set { UserDefaults.standard.set(newValue, forKey: "ratPlayedAt") }
    }

    var ratHungryMinutes: Double { Date().timeIntervalSince(ratFedAt) / 60 }
    var ratLonelyMinutes: Double { Date().timeIntervalSince(ratPlayedAt) / 60 }
    var ratHungerLimit: Double { pet.owned.contains("feeder") ? 120 : 60 }
    var ratAngry: Bool { ratHungryMinutes > ratHungerLimit || ratLonelyMinutes > (pet.owned.contains("wheel") ? 240 : 120) }
    var hasRat: Bool { pet.owned.contains("rat") }
    var ratIsOut: Bool { hasRat && !ratInCage && ratPanel != nil }

    func ratSay(_ text: String, _ seconds: Double) {
        ratView?.text = text
        ratView?.textUntil = time + seconds
    }

    /// Мястото на плъха (краката), или на клетката, ако е вътре.
    var ratSpot: NSPoint {
        if ratInCage, let c = cagePanel { return NSPoint(x: c.frame.midX, y: c.frame.minY) }
        if let p = ratPanel { return NSPoint(x: p.frame.midX, y: p.frame.minY) }
        return NSPoint(x: petScreenRect().midX, y: feetScreenY)
    }

    /// Покривът на клетката (на него може да се стъпва).
    var cageRoof: NSRect? {
        guard let c = cagePanel, !carryingCage else { return nil }
        return NSRect(x: c.frame.midX - 46, y: c.frame.maxY - 40, width: 92, height: 6)
    }

    func setUpCage() {
        guard cagePanel == nil else { return }
        let vf = NSScreen.main?.visibleFrame ?? .zero
        let s = CageView.size
        var x = vf.minX + 130
        if let saved = UserDefaults.standard.object(forKey: "cageX") as? Double { x = CGFloat(saved) }
        let p = overlayPanel(NSRect(x: x, y: vf.minY, width: s.width, height: s.height), key: false)
        p.level = .floating
        let v = CageView(frame: NSRect(origin: .zero, size: s))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        cagePanel = p
        cageView = v
        // при първото пускане не е гладен от часове
        if Date().timeIntervalSince(ratFedAt) > 50 * 60 { ratFedAt = Date().addingTimeInterval(-50 * 60) }
        if Date().timeIntervalSince(ratPlayedAt) > 100 * 60 { ratPlayedAt = Date().addingTimeInterval(-100 * 60) }
    }

    func updateRat(_ step: Double) {
        let has = hasRat && window.isVisible
        if !has {
            ratPanel?.orderOut(nil); ratPanel = nil; ratView = nil; chasing = false; carryingRat = false
            cagePanel?.orderOut(nil); cagePanel = nil; cageView = nil; carryingCage = false
            return
        }
        setUpCage()
        if ratPanel == nil {
            let s = RatView.size
            let start = cagePanel.map { NSPoint(x: $0.frame.maxX + 10, y: $0.frame.minY) } ?? NSPoint(x: 200, y: 0)
            let p = overlayPanel(NSRect(origin: start, size: s), key: false)
            p.level = .floating
            let v = RatView(frame: NSRect(origin: .zero, size: s))
            v.game = self
            p.contentView = v
            ratPanel = p
            ratView = v
        }
        guard let p = ratPanel, let v = ratView else { return }
        v.needsDisplay = true
        cageView?.needsDisplay = true
        updateRatMood()
        updateCarriedCage()
        // кликовете минават през празните части на прозорчетата
        let m = NSEvent.mouseLocation
        let ratHit = NSRect(x: p.frame.midX - 28, y: p.frame.minY, width: 56, height: 28).contains(m)
        if p.ignoresMouseEvents == ratHit { p.ignoresMouseEvents = !ratHit }
        if let c = cagePanel {
            let cageHit = NSRect(x: c.frame.midX - 46, y: c.frame.minY, width: 92, height: 68).contains(m)
                || NSEvent.pressedMouseButtons != 0 && !c.ignoresMouseEvents
            if c.ignoresMouseEvents == cageHit { c.ignoresMouseEvents = !cageHit }
        }

        if ratInCage && !carryingRat {
            if p.isVisible { p.orderOut(nil) }
            chasing = false
            dropRatLoot(caught: false)
            return
        }
        if !p.isVisible { p.orderFrontRegardless() }
        let half = RatView.size.width / 2
        var o = p.frame.origin
        let pr = petScreenRect()

        if carryingRat && hidePhase == .off && !jumping && errands.first != .ratToCage {
            // пуска го (след криенето или ако задачата е прекъсната)
            carryingRat = false
            ratSay("Уф! Цик!", 1.5)
        }
        if carryingRat {
            // виси за опашката от ръката му
            v.hanging = true
            v.running = false
            dropRatLoot(caught: false)
            let hx = facingLeft ? pr.minX + 8 : pr.maxX - 8
            let handY = pr.minY + pr.height * 0.42
            p.setFrameOrigin(NSPoint(x: hx - half, y: handY - RatView.tailTop))
            return
        }
        v.hanging = false
        v.loot = ratHasBall ? 2 : (ratHasPixel ? 1 : 0)
        let vf = screenAt(NSPoint(x: o.x + half, y: o.y + 10))?.visibleFrame ?? .zero
        let lo = vf.minX - half + 30, hi = vf.maxX - half - 30
        let petOnFloor = abs(feetScreenY - vf.minY) < 10

        // пада, ако е във въздуха
        if o.y > vf.minY + 0.5 { o.y = max(vf.minY, o.y - CGFloat(520 * step)) } else { o.y = vf.minY }

        // тича към нещо: пиксел на пода, паднал пиксел на Пиксчо или топката
        if let goal = ratGoal {
            let gx: CGFloat
            switch goal {
            case .food(let f):
                guard foods.contains(where: { $0 === f }), f.onFloor else { ratGoal = nil; p.setFrameOrigin(o); return }
                gx = f.panel.frame.midX - half
            case .pixel:
                guard isHyper, petOnFloor, !busyMoving || chasing else { ratGoal = nil; p.setFrameOrigin(o); return }
                gx = pr.midX - half
            case .ball:
                guard let b = ball, fetchPhase == .waiting, !b.flying, !b.carried else { ratGoal = nil; p.setFrameOrigin(o); return }
                gx = b.panel.frame.midX - half
            }
            let dx = gx - o.x
            v.running = true
            v.facingLeft = dx < 0
            let sp = CGFloat(230 * step)
            if abs(dx) <= sp + 4 {
                o.x = gx
                ratGoal = nil
                ratReached(goal)
            } else {
                o.x += dx > 0 ? sp : -sp
            }
            p.setFrameOrigin(o)
            return
        }

        if chasing {
            // бяга от Пиксчо; при стената се обръща и минава покрай него (без да трепери)
            v.running = true
            var nx = o.x + ratRunDir * CGFloat(170 * step)
            if nx < lo || nx > hi {
                ratRunDir = -ratRunDir
                nx = min(max(nx, lo), hi)
                ratSay("Цик!", 1)
            }
            o.x = nx
            v.facingLeft = ratRunDir < 0
            let ratX = o.x + half
            let target = NSPoint(x: window.frame.minX + ratX - pr.midX, y: window.frame.minY)
            _ = moveWindow(toward: target, speed: CGFloat(150 * step))
            walking = true
            let caught = abs(pr.midX - ratX) < pr.width / 2 - 6 && abs(feetScreenY - o.y) < 40
            if caught || time > chaseUntil {
                chasing = false
                walking = false
                ratPlayedAt = Date()
                if ratHasPixel || ratHasBall {
                    say(caught ? (ratHasBall ? "Хванах те! Дай ми топката!" : "Хванах те! Върни ми пиксела!")
                        : (ratHasBall ? "Избяга с топката ми! ГРРР!" : "Избяга с пиксела ми! ГРРР!"), seconds: 3)
                    if !caught { annoy(8, reason: "плъхът ми открадна нещо") }
                    dropRatLoot(caught: caught)
                } else if caught {
                    start(.love, length: 2)
                    v.heartsUntil = time + 2
                    sfx("Purr")
                    say("Хванах те, \(ratLabel)! Добро плъхче!", seconds: 2.5)
                } else {
                    say("Избяга ми! Пак ще те гоня!", seconds: 2.5)
                }
                saveWindowPosition()
            }
            p.setFrameOrigin(o)
            return
        }

        if ratTarget == nil || abs(ratTarget! - o.x) < 3 {
            ratTarget = Double.random(in: 0..<1) < 0.02 ? CGFloat.random(in: lo...max(lo + 1, hi)) : nil
        }
        v.running = false
        if let tx = ratTarget {
            let dx = tx - o.x
            v.facingLeft = dx < 0
            v.running = true
            o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(70 * step))
        } else if ratAngry {
            // сърдит: обръща гръб на Пиксчо
            v.facingLeft = pr.midX > o.x + half
        }
        o.x = min(max(o.x, lo), hi)
        p.setFrameOrigin(o)

        let free = !pet.asleep && hidePhase == .off && !isDragging && errands.isEmpty
        // понякога гони Пиксчо сам (играят си)
        if time > nextChase && petOnFloor && free && !pet.working && !busyMoving && !ratAngry {
            nextChase = time + Double.random(in: 180...420)
            startRatChase()
            say("\(ratLabel.capitalized)! Ела тук!", seconds: 2)
            sfx("Pop")
            return
        }
        // краде паднали пиксели от Пиксчо, когато е полудял
        if isHyper && !lostPixels.isEmpty && petOnFloor && time > nextRatSteal && !chasing {
            nextRatSteal = time + Double.random(in: 15...40)
            ratGoal = .pixel
            ratSay("Пиксел! Мой!", 1.5)
            return
        }
        // краде топката, докато играят на „донеси“
        if let b = ball, fetchPhase == .waiting, !b.flying, !b.carried, time > nextBallSteal {
            nextBallSteal = time + Double.random(in: 40...120)
            if Int.random(in: 0..<100) < 40 { ratGoal = .ball; ratSay("Топка! Цик!", 1.5); return }
        }
        // яде паднали на пода пиксели
        if time > nextRatSnack {
            let onFloorFoods = foods.filter { $0.onFloor && !$0.view.held }
            if let food = onFloorFoods.min(by: { abs($0.panel.frame.midX - (o.x + half)) < abs($1.panel.frame.midX - (o.x + half)) }) {
                nextRatSnack = time + (ratHungryMinutes > 40 ? Double.random(in: 40...90) : Double.random(in: 2 * 60...5 * 60))
                ratGoal = .food(food)
                ratSay("Пиксел на пода! Цик!", 1.5)
            } else {
                nextRatSnack = time + 20
            }
        }
    }

    func startRatChase() {
        guard let p = ratPanel else { return }
        chasing = true
        chaseUntil = time + 10
        ratRunDir = p.frame.midX > petScreenRect().midX ? 1 : -1
    }

    private func ratReached(_ goal: RatGoal) {
        switch goal {
        case .food(let food):
            food.remove()
            foods.removeAll { $0 === food }
            ratFedAt = Date()
            ratView?.heartsUntil = time + 1.5
            ratSay("Ням! Цик!", 2)
            sfx("Pop")
            if !pet.asleep && window.isVisible && hidePhase == .off {
                start(.angry, length: 1.5)
                annoy(6, reason: "плъхът ми изяде пиксела")
                say(["ЕЙ! \(ratLabel.capitalized) ми изяде пиксела!", "Това беше МОЯТ пиксел, \(ratLabel)!",
                     "Не яж от пода… и от моята храна!"].randomElement()!, seconds: 3)
            }
        case .pixel:
            if !lostPixels.isEmpty { lostPixels.removeFirst() }
            ratHasPixel = true
            sfx("Pop")
            ratSay("Хи-хи! Цик!", 1.5)
            start(.angry, length: 1.5)
            say("ЕЙ! Открадна ми пиксел! ВЪРНИ ГО!", seconds: 2.5)
            if !chasing && !busyMoving { startRatChase() }
        case .ball:
            guard let b = ball else { return }
            b.carried = true
            ratHasBall = true
            sfx("Pop")
            ratSay("Моя е! Цик!", 1.5)
            say("Ей! \(ratLabel.capitalized) ми открадна топката!", seconds: 2.5)
            if !chasing && !busyMoving { startRatChase() }
        }
    }

    /// Плъхът пуска това, което е откраднал.
    func dropRatLoot(caught: Bool) {
        if ratHasBall {
            ratHasBall = false
            if let b = ball {
                b.carried = false
                b.launch(.zero, thrown: false)
            }
        }
        if ratHasPixel {
            ratHasPixel = false
            if caught { start(.love, length: 1.2); say("Пикселът ми е пак мой!", seconds: 2) }
        }
    }

    /// Топката лети с плъха, докато я държи.
    func updateRatBall() {
        guard ratHasBall, let b = ball, let p = ratPanel else { return }
        let left = ratView?.facingLeft ?? false
        b.panel.setFrameOrigin(NSPoint(x: left ? p.frame.midX - 34 : p.frame.midX + 12, y: p.frame.minY + 4))
    }

    /// При тревога носи и клетката.
    func updateCarriedCage() {
        guard let c = cagePanel else { return }
        if carryingCage {
            let pr = petScreenRect()
            let x = facingLeft ? pr.maxX - 40 : pr.minX - c.frame.width + 40
            c.setFrameOrigin(NSPoint(x: x, y: pr.minY + 6))
            if hidePhase == .off && !jumping {
                carryingCage = false
                c.setFrameOrigin(cageHome)
            }
        }
    }

    /// Плъхът се сърди, когато е гладен или самотен.
    func updateRatMood() {
        guard ratAngry, time > nextRatComplain, !pet.dead, window.isVisible else { return }
        nextRatComplain = time + Double.random(in: 4 * 60...8 * 60)
        ratSay(ratHungryMinutes > ratHungerLimit ? pick(ratAngryLines, avoiding: &lastLine) : "Цик… никой не си играе с мен.", 3)
        sfx("Funk", every: 5)
        guard !pet.asleep, hidePhase == .off else { return }
        say(ratHungryMinutes > ratHungerLimit ? "Ох! Забравих да нахраня \(ratLabel)!" : "Ох… отдавна не съм си играл с \(ratLabel).", seconds: 3)
        if errands.isEmpty && !pet.working && !playingGame && Bool.random() {
            runErrands([ratHungryMinutes > ratHungerLimit ? .feedRat : .cuddleRat])
        }
    }

    /// Задълженията на Пиксчо към плъха (понякога ги забравя).
    func updateRatCare(_ idle: Bool) {
        guard hasRat, idle, errands.isEmpty, !busyMoving, !pet.working, !playingGame, questionPanel == nil,
              time > nextRatCare else { return }
        nextRatCare = time + Double.random(in: 6 * 60...12 * 60)
        // буден е, а плъхът е в клетката: пуска го да потича
        if ratInCage && Int.random(in: 0..<100) < 70 { runErrands([.ratOut]); return }
        if Int.random(in: 0..<100) < 30 { return }   // забрави
        if ratHungryMinutes > 25 { runErrands([.feedRat]); return }
        var options: [Errand] = [.cuddleRat, .cuddleRat]
        if ratInCage { options += [.ratOut, .ratOut] } else { options.append(.ratToCage) }
        let e = options.randomElement()!
        if e == .cuddleRat && !ratInCage && Bool.random() && ratLonelyMinutes > 20 {
            nextChase = time   // ще поиграят на гонене
            return
        }
        runErrands([e])
    }

    func updateRatErrand(_ e: Errand, _ step: Double) {
        guard hasRat, ratPanel != nil else { nextErrand(); return }
        switch errandStage {
        case 0:
            if e == .ratToCage && ratInCage { nextErrand(); return }
            if e == .ratOut && !ratInCage { nextErrand(); return }
            switch e {
            case .feedRat: say("Отивам да нахраня \(ratLabel)!", seconds: 2)
            case .cuddleRat: say("Ела да те гушна, \(ratLabel)!", seconds: 2)
            case .ratToCage: say("Хайде в клетката, \(ratLabel)!", seconds: 2)
            default: say("Ще пусна \(ratLabel) да потича.", seconds: 2)
            }
            chasing = false
            errandStage = 1
        case 1:
            if walkTo(feet: ratSpot, speed: 300, step) {
                errandStage = 2
                errandStart = time
                arrivedAtRat(e)
            }
        case 2:
            if e == .ratToCage {
                // носи го за опашката до клетката
                guard let c = cagePanel else { carryingRat = false; nextErrand(); return }
                if walkTo(feet: NSPoint(x: c.frame.midX, y: c.frame.minY), speed: 260, step) {
                    carryingRat = false
                    ratInCage = true
                    ratSay("Цик…", 2)
                    say("Готово! Стой мирно в клетката.", seconds: 2.5)
                    nextErrand()
                }
            } else if time - errandStart > 2 {
                nextErrand()
            }
        default:
            nextErrand()
        }
    }

    private func arrivedAtRat(_ e: Errand) {
        switch e {
        case .feedRat:
            let wasAngry = ratAngry
            ratFedAt = Date()
            start(.love, length: 1.5)
            ratView?.heartsUntil = time + 2
            ratSay("Ням-ням! Цик!", 2)
            say(wasAngry ? "Прости ми, \(ratLabel)! Забравих те… Ето ти храна." : "Ето ти пиксели, \(ratLabel)!", seconds: 3)
            addXP(2)
        case .cuddleRat:
            if ratHungryMinutes > ratHungerLimit {
                start(.angry, length: 1.5)
                glitchUntil = time + 0.4
                ratSay("ЦИК! (хап)", 2)
                say("Ау! \(ratLabel.capitalized) ме ухапа! Сърди ми се, гладен е…", seconds: 3)
                annoy(5)
                runErrands([.cuddleRat, .feedRat])
                errandStage = 2
                return
            }
            ratPlayedAt = Date()
            start(.love, length: 2)
            ratView?.heartsUntil = time + 2.5
            ratSay(pick(ratHappyLines, avoiding: &lastLine), 2)
            say("Гуш-гуш, \(ratLabel)!", seconds: 2)
            sfx("Purr")
            addXP(2)
        case .ratToCage:
            carryingRat = true
            sfx("Pop")
            ratSay("Цииик!", 1.5)
        case .ratOut:
            ratInCage = false
            if let c = cagePanel, let p = ratPanel {
                p.setFrameOrigin(NSPoint(x: c.frame.maxX - 20, y: c.frame.minY + 30))
                p.orderFrontRegardless()
            }
            ratPlayedAt = Date()
            ratSay("Свобода! Цик!", 2)
        default:
            break
        }
    }

    func ratClicked() {
        sfx("Purr")
        if ratAngry {
            ratSay(ratHungryMinutes > ratHungerLimit ? "Цик! Гладен съм!" : "Цик… скучно ми е.", 2.5)
            if !pet.asleep { say("\(ratLabel.capitalized) ми се сърди… трябва да се погрижа за него.", seconds: 3) }
            return
        }
        ratSay(pick(ratHappyLines, avoiding: &lastLine), 2)
        ratView?.heartsUntil = time + 1.2
        if ratName == nil && questionPanel == nil { askName("rat") }
    }

    func cageClicked() {
        if ratInCage {
            ratInCage = false
            if let c = cagePanel, let p = ratPanel {
                p.setFrameOrigin(NSPoint(x: c.frame.maxX - 20, y: c.frame.minY + 30))
                p.orderFrontRegardless()
            }
            ratSay("Свобода! Цик!", 2)
        } else if !pet.asleep && errands.isEmpty && !busyMoving && !pet.working {
            runErrands([.ratToCage])
        }
    }

    /// Пикселите, които падат, стигат до пода; там плъхът може да ги изяде.
    func updateFallingFood(_ step: Double) {
        for f in foods where f.falls && !f.flying && !f.view.held {
            let fr = f.panel.frame
            let vf = screenAt(NSPoint(x: fr.midX, y: fr.midY))?.visibleFrame ?? .zero
            let floorY = vf.minY - 8
            if fr.minY > floorY + 0.5 {
                f.onFloor = false
                f.fallV += CGFloat(900 * step)
                f.panel.setFrameOrigin(NSPoint(x: fr.minX, y: max(floorY, fr.minY - f.fallV * CGFloat(step))))
            } else {
                if !f.onFloor { sfx("Tink", every: 1) }
                f.fallV = 0
                f.onFloor = true
            }
        }
    }

    /// Пусна пиксел върху плъха: храниш го ти.
    func tryFeedRat(_ food: FoodPixel) -> Bool {
        guard hasRat, let p = ratPanel, p.isVisible, !carryingRat else { return false }
        let f = food.panel.frame
        guard p.frame.insetBy(dx: 0, dy: -10).contains(NSPoint(x: f.midX, y: f.midY)) else { return false }
        food.remove()
        foods.removeAll { $0 === food }
        ratFedAt = Date()
        ratView?.heartsUntil = time + 2
        ratSay("Ням! Благодаря! Цик!", 2)
        sfx("Pop")
        return true
    }
}
