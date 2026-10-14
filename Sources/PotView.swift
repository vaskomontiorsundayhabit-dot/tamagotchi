// Рисунката на саксията: растението на всички етапи, бурени, мравки, пчели, плодове,
// гнездо с яйце, тайнственото създание, очи, крачета, танц, балонче с текст.

import AppKit

struct PotCreature {
    let id: String
    let name: String
    let pic: Grid
    let sound: String

    static let all: [PotCreature] = [
        PotCreature(id: "dragon", name: "мъничко драконче", pic: grid([
            "K.......K.",
            "GK.KKK.KG.",
            ".KGGGGGK..",
            "KGWKGWKGG.",
            "KGGGGGGGGK",
            ".KGRRRGK.G",
            "..KGGGK..G",
            "..K...K...",
        ]), sound: "Рррр! (пуф, искричка)"),
        PotCreature(id: "phoenix", name: "огнена птичка феникс", pic: grid([
            "...R.Y....",
            "..ROYR....",
            ".KOOOOK...",
            "KOWKOOOK..",
            "KOOOOOOOKY",
            ".KOYYOOKRO",
            "..KOOOK.Y.",
            "...Y.Y....",
        ]), sound: "Пиу! (свети)"),
        PotCreature(id: "ghost", name: "малко духче", pic: grid([
            "..WWWW....",
            ".WWWWWW...",
            "WWKWWKWW..",
            "WWKWWKWW..",
            "WWWWWWWW..",
            "WWWPPWWW..",
            "WWWWWWWW..",
            "W.WW.WW...",
        ]), sound: "Бууу… хи-хи"),
        PotCreature(id: "robot", name: "робот-пиленце", pic: grid([
            "....Y.....",
            ".KKKKKK...",
            ".KEEEEK...",
            ".KCKKCKO..",
            ".KEEEEK...",
            "KKKKKKKK..",
            ".KEKKEK...",
            ".KK..KK...",
        ]), sound: "Бип-буп!"),
        PotCreature(id: "fairy", name: "горска фея", pic: grid([
            "T...K...T.",
            "TT.KPK.TT.",
            ".TTKPKTT..",
            "..KWKWK...",
            "..KPPPK...",
            "...KMK....",
            "..KMMMK...",
            "...K.K....",
        ]), sound: "Тин-тин! (блести)"),
        PotCreature(id: "unicorn", name: "мъничък еднорог", pic: grid([
            "......Y...",
            ".....KY...",
            "....KWWK..",
            "MMMKWKWWK.",
            ".MKWWWWPK.",
            "..KWWWWK..",
            "..KWKKWK..",
            "..KK..KK..",
        ]), sound: "Иии-хи-хи! (дъга)"),
        PotCreature(id: "octopus", name: "горско октоподче", pic: grid([
            "...KKKK...",
            "..KMMMMK..",
            ".KMWKMWKK.",
            ".KMMMMMMK.",
            ".KMMPPMMK.",
            "KMKMKMKMK.",
            "M.M.M.M.M.",
            "..........",
        ]), sound: "Блуп-блуп!"),
    ]
    static func find(_ id: String) -> PotCreature? { all.first { $0.id == id } }
}

final class PotView: NSView {
    weak var game: PotGame?
    let drag = Dragger()
    // къде какво е нарисувано (за кликовете)
    var fruitRects: [NSRect] = []
    var weedRects: [NSRect] = []
    var antRects: [NSRect] = []
    var eggRect = NSRect.zero
    var potRect = NSRect.zero
    var mushroomRect = NSRect.zero
    var plantTop: CGFloat = 0       // най-горната точка на растението (отгоре на прозорчето)

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    static let top: CGFloat = 70          // място отгоре за балончето и пчелите

    /// Размерът на прозорчето според етапа (дървото расте и след като стане дърво).
    static func size(for g: PotGame) -> NSSize {
        let s = g.stage, p = CGFloat(g.stageProgress)
        var w: CGFloat = 150, h: CGFloat = 40
        switch s {
        case 0: h = 40
        case 1: h = 30 + 40 * p
        case 2: h = 70 + 40 * p
        case 3: h = 110 + 30 * p
        case 4: w = max(150, 2 * (40 + 30 * p) + 40); h = 2 * (34 + 22 * p) + 30
        default:
            let crown = 60 + 90 * p
            w = max(170, crown * 2 + 40)
            h = 70 + 380 * p + crown * 2
        }
        return NSSize(width: w, height: h + top + 34)
    }

    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) { drag.dragged(window) }
    override func mouseUp(with event: NSEvent) {
        guard let game else { return }
        if drag.up() { game.dropped(); return }
        let p = convert(event.locationInWindow, from: nil)
        if let i = fruitRects.firstIndex(where: { $0.insetBy(dx: -4, dy: -4).contains(p) }) { _ = i; game.pickFruit(); return }
        if let i = antRects.firstIndex(where: { $0.insetBy(dx: -6, dy: -6).contains(p) }) { game.shooAnt(i); return }
        if let i = weedRects.firstIndex(where: { $0.insetBy(dx: -3, dy: -3).contains(p) }) { game.pullWeed(i); return }
        if eggRect.insetBy(dx: -4, dy: -4).contains(p) { game.warmEgg(); return }
        if mushroomRect.insetBy(dx: -3, dy: -3).contains(p) { game.eatMushroom(); return }
        if potRect.contains(p) { game.openCard(); return }
        game.clickedPlant()
    }
    override func rightMouseDown(with event: NSEvent) { game?.openCard() }

    override func draw(_ dirtyRect: NSRect) {
        guard let g = game else { return }
        fruitRects = []; weedRects = []; antRects = []; eggRect = .zero
        let t = g.time
        let st = g.stage
        let p = CGFloat(g.stageProgress)
        let legs = g.hidePhase != 0
        let bottom = bounds.height - 2 - (legs ? 10 : 0)
        let mx = bounds.midX
        let sick = g.health < 30 || g.water < 10
        func tint(_ hex: Int) -> NSColor {
            let c = NSColor(hex: hex)
            return sick ? (c.blended(withFraction: 0.45, of: NSColor(hex: 0x9c6644)) ?? c) : c
        }
        let leaf = tint(0x52b788), leaf2 = tint(0x2d6a4f), stemC = tint(0x40916c)
        let dancing = t < g.trippyUntil && g.hidePhase == 0
        let sway: CGFloat = dancing ? CGFloat(sin(t * 7)) * 6 : CGFloat(sin(t * 1.3)) * 1.5 + (g.water < 15 ? 5 : 0)
        let bounce: CGFloat = dancing ? abs(CGFloat(sin(t * 7))) * 4 : 0

        // крачета (при тревога)
        if legs {
            NSColor(hex: 0x5c3a1e).setFill()
            let ph = CGFloat(sin(t * 16)) * 4
            NSRect(x: mx - 12 + ph, y: bottom, width: 5, height: 10).fill()
            NSRect(x: mx + 7 - ph, y: bottom, width: 5, height: 10).fill()
            NSRect(x: mx - 15 + ph, y: bottom + 8, width: 9, height: 2).fill()
            NSRect(x: mx + 6 - ph, y: bottom + 8, width: 9, height: 2).fill()
        }
        // саксията
        let pw: CGFloat = st >= 5 ? 76 : (st == 4 ? 60 : 46)
        let ph: CGFloat = st >= 4 ? 30 : 26
        let potTop = bottom - ph - bounce
        let pot = NSBezierPath()
        pot.move(to: NSPoint(x: mx - pw / 2, y: potTop + 5))
        pot.line(to: NSPoint(x: mx + pw / 2, y: potTop + 5))
        pot.line(to: NSPoint(x: mx + pw / 2 - 6, y: bottom - bounce))
        pot.line(to: NSPoint(x: mx - pw / 2 + 6, y: bottom - bounce))
        pot.close()
        NSColor(hex: 0xc8693f).setFill(); pot.fill()
        NSColor(hex: 0xa0522d).setFill()
        NSRect(x: mx - pw / 2 - 3, y: potTop, width: pw + 6, height: 7).fill()
        NSColor(hex: 0x5c3a1e).setFill()
        NSRect(x: mx - pw / 2 + 2, y: potTop + 1, width: pw - 4, height: 3).fill()
        potRect = NSRect(x: mx - pw / 2 - 3, y: potTop, width: pw + 6, height: ph)
        mushroomRect = .zero
        // пълнолуние: сребърно сияние
        if g.fullMoon && g.isNight && st >= 2 {
            NSColor(hex: 0xe0e1dd, alpha: 0.12 + 0.05 * CGFloat(sin(t * 2))).setFill()
            NSBezierPath(ovalIn: NSRect(x: 4, y: PotView.top - 10, width: bounds.width - 8, height: potTop - PotView.top + 20)).fill()
        }
        // гъбата (от много вода)
        if g.hasMushroom {
            let gx = mx + pw / 2 - 14, gy = potTop - 12
            NSColor(hex: 0xfefae0).setFill(); NSRect(x: gx + 3, y: gy + 5, width: 4, height: 8).fill()
            NSColor(hex: Int(t * 3) % 2 == 0 ? 0xe63946 : 0xc77dff).setFill(); NSRect(x: gx - 2, y: gy, width: 14, height: 6).fill()
            NSColor.white.setFill(); NSRect(x: gx + 1, y: gy + 1, width: 2, height: 2).fill(); NSRect(x: gx + 7, y: gy + 2, width: 2, height: 2).fill()
            mushroomRect = NSRect(x: gx - 3, y: gy - 1, width: 16, height: 15)
        }
        let soil = potTop + 1

        // бурени в саксията
        for (i, wx) in g.weeds.enumerated() {
            let x = mx + CGFloat(wx) * (pw / 2 - 8)
            NSColor(hex: 0x6a994e).setFill()
            for (dx, h) in [(-4, 9), (0, 13), (4, 8)] {
                NSRect(x: x + CGFloat(dx) - 1, y: soil - CGFloat(h), width: 3, height: CGFloat(h)).fill()
            }
            NSColor(hex: 0x386641).setFill()
            NSRect(x: x - 6, y: soil - 5, width: 3, height: 3).fill()
            NSRect(x: x + 4, y: soil - 7, width: 3, height: 3).fill()
            weedRects.append(NSRect(x: x - 7, y: soil - 14, width: 14, height: 14))
            _ = i
        }

        // растението
        let baseX = mx + sway * 0.3
        var crownCenter = NSPoint(x: mx, y: soil - 40)
        var crownR: CGFloat = 0
        var stemTopY = soil
        var spots: [NSPoint] = []         // места за плодове, пчели, мравки
        switch st {
        case 0:
            let h = 8 + 8 * p
            stemC.setFill()
            NSRect(x: baseX - 1.5, y: soil - h, width: 3, height: h).fill()
            leaf.setFill()
            NSRect(x: baseX - 9 + sway * 0.3, y: soil - h - 2, width: 8, height: 4).fill()
            NSRect(x: baseX + 1 + sway * 0.3, y: soil - h - 4, width: 8, height: 4).fill()
            stemTopY = soil - h
        case 1, 2, 3:
            let h: CGFloat = st == 1 ? 18 + 40 * p : (st == 2 ? 58 + 40 * p : 98 + 30 * p)
            stemC.setFill()
            let segs = Int(h / 6)
            for i in 0..<max(1, segs) {
                let k = CGFloat(i) / CGFloat(max(1, segs))
                NSRect(x: baseX - 1.5 + sway * k, y: soil - CGFloat(i + 1) * 6, width: 3, height: 6.5).fill()
            }
            stemTopY = soil - h
            let leafPairs = st == 1 ? 1 : (st == 2 ? 2 + Int(p * 2) : 4)
            for i in 0..<leafPairs {
                let k = 0.3 + 0.6 * CGFloat(i) / CGFloat(max(1, leafPairs))
                let y = soil - h * k
                let x = baseX + sway * k
                g.secretLeafColor(i % 2 == 0 ? leaf : leaf2, i * 5).setFill()
                NSRect(x: x - 15, y: y - 3, width: 13, height: 6).fill()
                NSRect(x: x + 2, y: y - 6, width: 13, height: 6).fill()
                spots.append(NSPoint(x: x - 10, y: y - 2)); spots.append(NSPoint(x: x + 10, y: y - 5))
            }
            if st == 3 {
                let blossoms = 1 + Int(p * 3)
                for i in 0..<blossoms {
                    let k: CGFloat = i == 0 ? 1 : 0.55 + 0.12 * CGFloat(i)
                    let side: CGFloat = i == 0 ? 0 : (i % 2 == 0 ? -1 : 1)
                    flower(NSPoint(x: baseX + sway * k + side * 14, y: soil - h * k - 4), i, s: i == 0 ? 3 : 2.5)
                }
            }
            crownCenter = NSPoint(x: baseX + sway, y: soil - h)
        case 4:
            let rx = 40 + 30 * p, ry = 34 + 22 * p
            crownCenter = NSPoint(x: mx + sway * 0.6, y: soil - ry - 2)
            crownR = rx
            spots = blob(center: crownCenter, rx: rx, ry: ry, leaf: leaf, leaf2: leaf2, seed: 1)
            for i in 0..<(3 + Int(p * 5)) where !spots.isEmpty {
                let s = spots[hash(i * 13 + 5) % spots.count]
                flower(s, i, s: 2)
            }
            stemTopY = crownCenter.y - ry
        default:
            let crown = 60 + 90 * p
            let trunkH = 70 + 380 * p
            let tw = 10 + 10 * p
            NSColor(hex: 0x8b5a2b).setFill()
            NSRect(x: mx - tw / 2, y: soil - trunkH - crown * 0.3, width: tw, height: trunkH + crown * 0.3).fill()
            NSColor(hex: 0x5c3a1e).setFill()
            NSRect(x: mx - tw / 2, y: soil - trunkH - crown * 0.3, width: 3, height: trunkH + crown * 0.3).fill()
            crownCenter = NSPoint(x: mx + sway, y: soil - trunkH - crown)
            crownR = crown
            spots = blob(center: crownCenter, rx: crown, ry: crown * 0.85, leaf: leaf, leaf2: leaf2, seed: 2)
            for i in 0..<(6 + Int(p * 14)) where !spots.isEmpty {
                let s = spots[hash(i * 17 + 3) % spots.count]
                flower(s, i, s: 2)
            }
            stemTopY = crownCenter.y - crown * 0.85
        }

        // плодове
        if g.fruitsOnPlant > 0 && !spots.isEmpty {
            for i in 0..<g.fruitsOnPlant {
                let s = spots[hash(i * 29 + 11) % spots.count]
                let r = NSRect(x: s.x - 4, y: s.y - 1, width: 8, height: 8)
                NSColor(hex: 0x2b2b3a).setFill(); r.fill()
                NSColor(hex: i % 3 == 0 ? 0xff9f1c : 0xe63946).setFill(); r.insetBy(dx: 1.5, dy: 1.5).fill()
                NSColor(white: 1, alpha: 0.7).setFill(); NSRect(x: r.minX + 2, y: r.minY + 2, width: 2, height: 2).fill()
                fruitRects.append(r)
            }
        }

        // гнездо, яйце, създанието
        if (g.hasNest || g.creature != nil) && st >= 4 {
            let n = NSPoint(x: crownCenter.x + crownR * 0.25, y: crownCenter.y - crownR * 0.55)
            NSColor(hex: 0x7f5539).setFill()
            NSRect(x: n.x - 13, y: n.y, width: 26, height: 7).fill()
            NSColor(hex: 0x9c6644).setFill()
            NSRect(x: n.x - 10, y: n.y + 6, width: 20, height: 4).fill()
            if g.hasEgg {
                let wob = g.eggCare > 80 ? CGFloat(sin(t * 12)) * 1.5 : 0
                let e = NSRect(x: n.x - 5 + wob, y: n.y - 9, width: 10, height: 12)
                NSColor(hex: 0xe0fbfc).setFill(); NSBezierPath(ovalIn: e).fill()
                NSColor(hex: 0x5dade2).setFill()
                NSRect(x: e.minX + 3, y: e.minY + 4, width: 2, height: 2).fill()
                NSRect(x: e.minX + 6, y: e.minY + 7, width: 2, height: 2).fill()
                eggRect = e
                // лента: колко е стоплено
                NSColor(hex: 0x3a3a50).setFill(); NSRect(x: n.x - 12, y: n.y + 12, width: 24, height: 3).fill()
                NSColor(hex: 0xff8fab).setFill(); NSRect(x: n.x - 12, y: n.y + 12, width: 24 * CGFloat(g.eggCare / 100), height: 3).fill()
            }
            for (ci, cid) in [g.creature, g.creature2].enumerated() {
                guard let c = cid.flatMap({ PotCreature.find($0) }) else { continue }
                let ph = Double(ci) * 2.1
                let hop: CGFloat = dancing ? abs(CGFloat(sin(t * 8 + ph))) * 6 : (Int(t / 3 + ph) % 5 == 0 ? abs(CGFloat(sin(t * 6))) * 4 : 0)
                let wander = CGFloat(sin(t * 0.3 + ph)) * crownR * 0.3 - CGFloat(ci) * 26
                drawGrid(c.pic, x: n.x - 15 + wander, y: n.y - 24 - hop, s: 3, flip: sin(t * 0.3 + ph + 1.57) < 0, palette: potColor)
                if ci == 0, let say = g.creatureSay, t < g.creatureSayUntil {
                    let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy), .foregroundColor: NSColor.white]
                    let str = say.uppercased() as NSString
                    let sz = str.size(withAttributes: a)
                    let r = NSRect(x: n.x - 15 + wander, y: n.y - 42 - hop, width: sz.width + 8, height: sz.height + 4)
                    NSColor(hex: 0x2b2b3a, alpha: 0.9).setFill(); r.fill()
                    str.draw(at: NSPoint(x: r.minX + 4, y: r.minY + 2), withAttributes: a)
                }
            }
        }

        // очи на храста/дървото
        if st >= 4 && (t < g.eyesUntil || dancing) {
            let m = NSEvent.mouseLocation
            let wp = window.map { NSPoint(x: m.x - $0.frame.minX, y: $0.frame.maxY - m.y) } ?? .zero
            let dx = max(-2, min(2, (wp.x - crownCenter.x) / 60)), dy = max(-2, min(2, (wp.y - crownCenter.y) / 60))
            let blink = Int(t * 10) % 37 == 0
            for side in [-1.0, 1.0] as [CGFloat] {
                let ex = crownCenter.x + side * 13 - 6, ey = crownCenter.y - 8
                NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: ex - 1, y: ey - 1, width: 14, height: blink ? 3 : 14).fill()
                if !blink {
                    NSColor.white.setFill(); NSRect(x: ex, y: ey, width: 12, height: 12).fill()
                    NSColor(hex: 0x2b2b3a).setFill(); NSRect(x: ex + 4 + dx * 2, y: ey + 4 + dy * 2, width: 5, height: 5).fill()
                }
            }
            // усмивка
            NSColor(hex: 0x2b2b3a).setFill()
            NSRect(x: crownCenter.x - 6, y: crownCenter.y + 12, width: 12, height: 2).fill()
            NSRect(x: crownCenter.x - 8, y: crownCenter.y + 10, width: 2, height: 2).fill()
            NSRect(x: crownCenter.x + 6, y: crownCenter.y + 10, width: 2, height: 2).fill()
        }

        // мравки: пълзят по саксията и нагоре по растението
        for (i, a) in g.ants.enumerated() {
            let y0 = potTop + ph * 0.6, y1 = stemTopY + 10
            let y = y0 + (y1 - y0) * a.t
            let x = mx + a.side * (a.t < 0.3 ? pw / 2 - 6 - a.t * 20 : 6 + CGFloat(sin(Double(a.t) * 9 + Double(i))) * 5) + sway * a.t
            NSColor(hex: 0x1b1b24).setFill()
            NSRect(x: x - 3, y: y - 2, width: 3, height: 3).fill()
            NSRect(x: x, y: y - 1, width: 3, height: 3).fill()
            NSRect(x: x + 3, y: y - 2, width: 3, height: 3).fill()
            antRects.append(NSRect(x: x - 4, y: y - 4, width: 11, height: 8))
            // царицата: голяма, с корона
            if g.queenPresent && i == 0 {
                NSColor(hex: 0x9d0208).setFill(); NSRect(x: x - 6, y: y - 5, width: 14, height: 7).fill()
                NSColor(hex: 0xffd166).setFill(); NSRect(x: x - 4, y: y - 9, width: 8, height: 3).fill()
            }
        }
        // влюбената пчела: със сърчица
        if t < g.loveBeeUntil {
            let a = t * 1.7
            let c = crownR > 0 ? crownCenter : NSPoint(x: baseX, y: stemTopY)
            let x = c.x + CGFloat(cos(a)) * (40 + crownR * 0.5), y = c.y + CGFloat(sin(a * 1.4)) * 20 - 20
            NSColor(hex: 0xffd166).setFill(); NSRect(x: x - 3, y: y - 1, width: 7, height: 4).fill()
            NSColor(hex: 0x1b1b24).setFill(); NSRect(x: x, y: y - 1, width: 2, height: 4).fill()
            NSColor(hex: 0xff4d6d).setFill()
            let hy = y - 10 - CGFloat((t * 1.5).truncatingRemainder(dividingBy: 1)) * 8
            NSRect(x: x - 2, y: hy, width: 3, height: 3).fill(); NSRect(x: x + 2, y: hy, width: 3, height: 3).fill(); NSRect(x: x - 1, y: hy + 2, width: 5, height: 3).fill()
        }
        // опърлено от мълнията
        if g.d.bool(forKey: "pot_scorched") && st >= 5 && !g.d.bool(forKey: "pot_rainbow") {
            NSColor(hex: 0x1b1b24).setFill()
            for k in 0..<10 {
                NSRect(x: crownCenter.x - crownR * 0.6 + CGFloat(hash(k * 7) % 100) / 100 * crownR * 0.5,
                       y: crownCenter.y - crownR * 0.5 + CGFloat(hash(k * 11) % 100) / 100 * crownR * 0.5, width: 6, height: 6).fill()
            }
        }

        // пчели около цветовете
        for b in g.bees {
            let a = t * 2.2 + b.phase
            let c = crownR > 0 ? crownCenter : NSPoint(x: baseX, y: stemTopY)
            let x = c.x + CGFloat(cos(a)) * (b.radius + crownR * 0.6), y = c.y + CGFloat(sin(a * 1.3)) * (b.radius * 0.5) - 10
            NSColor(white: 1, alpha: 0.8).setFill()
            NSRect(x: x - 1, y: y - 4 - (Int(t * 20) % 2 == 0 ? 1 : 0), width: 4, height: 3).fill()
            NSColor(hex: 0xffd166).setFill(); NSRect(x: x - 3, y: y - 1, width: 7, height: 4).fill()
            NSColor(hex: 0x1b1b24).setFill(); NSRect(x: x, y: y - 1, width: 2, height: 4).fill()
        }

        // поливане: капки
        if t < g.wateringUntil {
            NSColor(hex: 0x48cae4).setFill()
            for i in 0..<10 {
                let k = CGFloat((t * 2 + Double(i) / 10).truncatingRemainder(dividingBy: 1))
                NSRect(x: mx - 20 + CGFloat(i) * 4, y: max(0, stemTopY - 30) + k * (soil - max(0, stemTopY - 30)), width: 2, height: 4).fill()
            }
        }
        // градинарят подрязва: падат листенца
        if t < g.trimmingUntil {
            leaf.setFill()
            for i in 0..<8 {
                let k = CGFloat((t * 0.9 + Double(i) / 8).truncatingRemainder(dividingBy: 1))
                NSRect(x: crownCenter.x - crownR + CGFloat(hash(i) % 100) / 100 * crownR * 2, y: crownCenter.y + k * (soil - crownCenter.y),
                       width: 4, height: 3).fill()
            }
        }
        // танц: ноти
        if dancing {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .heavy), .foregroundColor: NSColor(hex: 0xc77dff)]
            for i in 0..<3 {
                let k = CGFloat((t * 0.6 + Double(i) / 3).truncatingRemainder(dividingBy: 1))
                ("♪" as NSString).draw(at: NSPoint(x: 8 + CGFloat(i) * (bounds.width - 24) / 2, y: PotView.top + (soil - PotView.top) * (1 - k)), withAttributes: a)
            }
        }
        // жадно: капка-иконка
        if g.water < 25 && Int(t * 2) % 2 == 0 {
            NSColor(hex: 0x48cae4).setFill()
            NSBezierPath(ovalIn: NSRect(x: mx + pw / 2 + 4, y: potTop - 12, width: 8, height: 10)).fill()
        }
        plantTop = max(0, min(stemTopY, crownCenter.y - crownR) - 10)
        // балонче
        if let text = g.bubble, t < g.bubbleUntil { bubbleText(text, above: max(PotView.top - 6, min(stemTopY, crownCenter.y - crownR) - 8)) }
    }

    private func hash(_ i: Int) -> Int {
        var x = UInt32(truncatingIfNeeded: i &* 2654435761 &+ 977)
        x ^= x >> 13; x = x &* 0x5bd1e995; x ^= x >> 15
        return Int(x % 100000)
    }

    private func flower(_ c: NSPoint, _ i: Int, s: CGFloat) {
        let petals = [0xff8fab, 0xffffff, 0xc77dff, 0xffd166]
        NSColor(hex: petals[hash(i) % petals.count]).setFill()
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            NSRect(x: c.x + CGFloat(dx) * s * 2 - s, y: c.y + CGFloat(dy) * s * 2 - s, width: s * 2, height: s * 2).fill()
        }
        NSColor(hex: 0xffd166).setFill()
        NSRect(x: c.x - s, y: c.y - s, width: s * 2, height: s * 2).fill()
    }

    /// Кълбо от пикселни листа; връща местата по него.
    private func blob(center: NSPoint, rx: CGFloat, ry: CGFloat, leaf: NSColor, leaf2: NSColor, seed: Int) -> [NSPoint] {
        let cell: CGFloat = 6
        var spots: [NSPoint] = []
        var i = seed * 1000
        var y = center.y - ry
        while y < center.y + ry {
            var x = center.x - rx
            while x < center.x + rx {
                let dx = (x + cell / 2 - center.x) / rx, dy = (y + cell / 2 - center.y) / ry
                if dx * dx + dy * dy <= 1 {
                    let base = hash(i) % 3 == 0 ? leaf2 : leaf
                    (game?.secretLeafColor(base, i) ?? base).setFill()
                    NSRect(x: x, y: y, width: cell, height: cell).fill()
                    if dx * dx + dy * dy < 0.8 { spots.append(NSPoint(x: x + cell / 2, y: y + cell / 2)) }
                }
                x += cell; i += 1
            }
            y += cell
        }
        return spots
    }

    private func bubbleText(_ text: String, above y: CGFloat) {
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 10, weight: .bold), .foregroundColor: NSColor.white]
        let str = text.uppercased() as NSString
        let sz = str.boundingRect(with: NSSize(width: bounds.width - 16, height: 60), options: [.usesLineFragmentOrigin], attributes: a).size
        let w = ceil(sz.width) + 12, h = ceil(sz.height) + 8
        let r = NSRect(x: (bounds.width - w) / 2, y: max(2, y - h), width: w, height: h)
        NSColor(hex: 0x2d6a4f, alpha: 0.95).setFill(); r.fill()
        str.draw(with: r.insetBy(dx: 6, dy: 4), options: [.usesLineFragmentOrigin], attributes: a)
    }
}

func potColor(_ c: Character) -> NSColor? {
    switch c {
    case "K": return NSColor(hex: 0x2b2b3a)
    case "W": return .white
    case "P": return NSColor(hex: 0xff8fab)
    case "R": return NSColor(hex: 0xe63946)
    case "T": return NSColor(hex: 0xa2d2ff)
    case "G": return NSColor(hex: 0x52b788)
    case "Y": return NSColor(hex: 0xffd166)
    case "O": return NSColor(hex: 0xf4a261)
    case "E": return NSColor(hex: 0x8d99ae)
    case "C": return NSColor(hex: 0x48cae4)
    case "M": return NSColor(hex: 0xc77dff)
    case "Q": return NSColor(hex: 0x8b5a2b)
    default: return nil
    }
}

/// Иконката горе: саксийка с кълнче.
func potStatusIcon() -> NSImage {
    let img = NSImage(size: NSSize(width: 18, height: 18))
    img.lockFocus()
    NSColor(hex: 0x2b2b3a).setFill()
    NSRect(x: 4, y: 1, width: 10, height: 7).fill()
    NSRect(x: 3, y: 7, width: 12, height: 2).fill()
    NSRect(x: 8, y: 9, width: 2, height: 5).fill()
    NSRect(x: 4, y: 12, width: 4, height: 3).fill()
    NSRect(x: 10, y: 13, width: 4, height: 3).fill()
    img.unlockFocus()
    img.isTemplate = true
    return img
}
