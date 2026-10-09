// Разбиване на нарисуваните пиксели: при тревога пробива стените, а като е полудял
// и затворен, се надува и ги разхвърчава. Плюс блъскане в нарисуваните стени.

import AppKit

struct Debris {
    var p: NSPoint
    var v: CGVector
    let color: Int
    let born: Double
}

let bumpLines = ["Ауч! Стена!", "Бум! Пак стена!", "Пуснете ме! Блъснах се!", "Тук няма изход!", "Оф, главата ми!"]

final class DebrisView: NSView {
    weak var game: Game?
    override func draw(_ dirtyRect: NSRect) {
        guard let game, let w = window else { return }
        let o = w.frame.origin
        for d in game.debris {
            let a = CGFloat(max(0, 1 - (game.time - d.born) / 1.6))
            NSColor(hex: 0x2b2b3a, alpha: a).setFill()
            NSRect(x: d.p.x - o.x - 1, y: d.p.y - o.y - 1, width: drawCell + 2, height: drawCell + 2).fill()
            NSColor(hex: d.color, alpha: a).setFill()
            NSRect(x: d.p.x - o.x, y: d.p.y - o.y, width: drawCell, height: drawCell).fill()
        }
    }
}

extension Game {
    /// Разбива нарисуваните пиксели в правоъгълника; те се разхвърчават от центъра.
    @discardableResult
    func smashCells(in r: NSRect, from center: NSPoint, limit: Int = 250) -> Int {
        let x0 = Int(floor(r.minX / drawCell)), x1 = Int(floor(r.maxX / drawCell))
        let y0 = Int(floor(r.minY / drawCell)), y1 = Int(floor(r.maxY / drawCell))
        guard !drawCells.isEmpty, x1 >= x0, y1 >= y0, (x1 - x0 + 1) * (y1 - y0 + 1) < 40000 else { return 0 }
        var n = 0
        for y in y0...y1 {
            for x in x0...x1 {
                let k = cellKey(x, y)
                guard n < limit, let c = drawCells[k] else { continue }
                drawCells.removeValue(forKey: k)
                n += 1
                let p = NSPoint(x: CGFloat(x) * drawCell, y: CGFloat(y) * drawCell)
                let dx = p.x - center.x, dy = p.y - center.y
                let d = max(1, hypot(dx, dy))
                let sp = CGFloat.random(in: 350...750)
                debris.append(Debris(p: p, v: CGVector(dx: dx / d * sp + CGFloat.random(in: -80...80),
                                                       dy: dy / d * sp + CGFloat.random(in: 100...300)),
                                     color: c, born: time))
            }
        }
        if n > 0 {
            redrawDrawing()
            saveDrawing()
            showDebris()
            sfx("Glass", every: 0.3)
        }
        return n
    }

    func showDebris() {
        guard debrisPanel == nil else { return }
        let pr = petScreenRect()
        guard let sf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.frame else { return }
        let p = overlayPanel(sf, key: false)
        p.level = .floating
        p.ignoresMouseEvents = true
        let v = DebrisView(frame: NSRect(origin: .zero, size: sf.size))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        debrisPanel = p
    }

    func updateDebris(_ step: Double) {
        // полудял и затворен: надува се и после разхвърчава рисунката
        if crazySmashAt > 0 && time > crazySmashAt {
            crazySmashAt = 0
            let pr = petScreenRect()
            let n = smashCells(in: pr.insetBy(dx: -110, dy: -90), from: NSPoint(x: pr.midX, y: pr.midY))
            if n > 0 {
                glitchUntil = time + 0.6
                say(["ПРОСТОР! БУМ!", "МАХАЙТЕ СЕ, ПИКСЕЛИ!", "НИКОЙ НЕ МЕ ЗАТВАРЯ!"].randomElement()!, seconds: 2.5)
            }
            checkEnclosure()
        }
        if debris.isEmpty {
            if debrisPanel != nil { debrisPanel?.orderOut(nil); debrisPanel = nil }
            return
        }
        let dt = CGFloat(step)
        for i in debris.indices {
            debris[i].v.dy -= 1400 * dt
            debris[i].p.x += debris[i].v.dx * dt
            debris[i].p.y += debris[i].v.dy * dt
        }
        debris.removeAll { time - $0.born > 1.6 }
        debrisPanel?.contentView?.needsDisplay = true
    }

    /// Луд и затворен: започва да се надува.
    func checkCrazySmash() {
        guard enclosed, isHyper, crazySmashAt == 0, time > nextCrazySmash, !pet.asleep, window.isVisible else { return }
        nextCrazySmash = time + 20
        closeUpUntil = time + 5
        crazySmashAt = time + 1.6
        glitchUntil = time + 1.2
        say("ТЯСНО МИ Е! НАДУВАМ СЕ!", seconds: 2)
    }

    /// При тревога: каквото е нарисувано на пътя му, го разбива.
    func smashWhileRunning() {
        guard !drawCells.isEmpty else { return }
        let pr = petScreenRect()
        let feet = feetScreenY
        let r = NSRect(x: pr.minX - 8, y: feet + 3, width: pr.width + 16, height: max(1, pr.maxY - feet))
        if smashCells(in: r, from: NSPoint(x: pr.midX, y: pr.midY), limit: 60) > 0 && time - lastSmashLine > 2 {
            lastSmashLine = time
            say(["РАЗБИВАМ!", "ПРАВ ПЪТ!", "БУУМ!"].randomElement()!, seconds: 1.5)
        }
    }

    /// Дали тялото би влязло в нарисуван пиксел, ако се премести с dx (подът под краката не се брои).
    func bodyHitsDrawing(dx: CGFloat) -> Bool {
        guard !drawCells.isEmpty else { return false }
        let pr = petScreenRect().insetBy(dx: 6, dy: 0)
        let feet = feetScreenY
        let r = NSRect(x: pr.minX + dx, y: feet + 4, width: pr.width, height: max(1, pr.maxY - feet - 8))
        let x0 = Int(floor(r.minX / drawCell)), x1 = Int(floor(r.maxX / drawCell))
        let y0 = Int(floor(r.minY / drawCell)), y1 = Int(floor(r.maxY / drawCell))
        guard x1 >= x0, y1 >= y0, (x1 - x0 + 1) * (y1 - y0 + 1) < 20000 else { return false }
        for y in y0...y1 {
            for x in x0...x1 where drawCells[cellKey(x, y)] != nil { return true }
        }
        return false
    }

    /// Блъсна се в нарисувана стена.
    func bumpWall() {
        walkTarget = nil
        walking = false
        var o = window.frame.origin
        o.x += facingLeft ? 6 : -6
        window.setFrameOrigin(o)
        sfx("Basso", every: 1)
        glitchUntil = time + 0.3
        if enclosed {
            annoy(3, reason: "ме затвори")
            start(.angry, length: 1)
        }
        if bubbleText == nil || enclosed { say(pick(bumpLines, avoiding: &lastLine), seconds: 2) }
    }
}
