// Още домашни любимци от магазина: коте, куче, охлюв, рибка в аквариум, папагал.
// Всеки огладнява, иска да го галиш, има меню с иконки и име. Пиксчо ги храни (понякога забравя).

import AppKit

struct SmallPetKind {
    let id: String
    let label: String          // „котето“
    let frames: [Grid]
    let sound: String
    let speed: CGFloat
}

let smallPetKinds: [SmallPetKind] = [
    SmallPetKind(id: "cat", label: "котето", frames: [grid([
        "..K.K.......",
        ".KOKOK......",
        ".KOOOK.....K",
        "KOWOWOK...KO",
        "KOOPOOKKKKO.",
        ".KOOOOOOOOK.",
        "..KOOOOOOOK.",
        "..KK.K..KK..",
    ]), grid([
        "..K.K.......",
        ".KOKOK......",
        ".KOOOK....K.",
        "KOWOWOK..KO.",
        "KOOPOOKKKKO.",
        ".KOOOOOOOOK.",
        "..KOOOOOOOK.",
        "...KK..KK.K.",
    ])], sound: "Мяу!", speed: 45),
    SmallPetKind(id: "dog", label: "кучето", frames: [grid([
        "KK..........",
        "KQK.........",
        "KQQQK.....K.",
        "KQWQQK...KQ.",
        "KQQQQQKKKQK.",
        ".KKQQQQQQQK.",
        "..KQQQQQQQK.",
        "..KK.K..KK..",
    ]), grid([
        "KK..........",
        "KQK.......K.",
        "KQQQK....KQ.",
        "KQWQQK..KQ..",
        "KQQQQQKKKK..",
        ".KKQQQQQQQK.",
        "..KQQQQQQQK.",
        "...KK..KK.K.",
    ])], sound: "Бау!", speed: 70),
    SmallPetKind(id: "snail", label: "охлюва", frames: [grid([
        "....KKK.....",
        "...KMMMK....",
        "..KMKKMMK...",
        "..KMKMKMK.K.",
        "..KMMKMMKKYK",
        ".KYYYYYYYYYK",
        "KYYYYYYYYYK.",
        "............",
    ])], sound: "…", speed: 5),
    SmallPetKind(id: "fish", label: "рибката", frames: [grid([
        "..OO..O",
        ".OOOOOO",
        "OWKOOOO",
        ".OOOOOO",
        "..OO..O",
    ])], sound: "Блоп!", speed: 0),
    SmallPetKind(id: "parrot", label: "папагала", frames: [grid([
        "...GGG..",
        "..GWKGG.",
        "..GGGGYY",
        ".GGGGGY.",
        "GGGRGGG.",
        "GGRRGG..",
        ".G..K...",
        "..KK....",
    ]), grid([
        "...GGG..",
        "..GWKGG.",
        "G.GGGGYY",
        "GGGGGGY.",
        ".GGRGGG.",
        "..RRGG..",
        "....K...",
        "..KK....",
    ])], sound: "Ррр!", speed: 160),
]

let iconCat = grid(["K.K.....", "KOK.....", "OWOW...K", "OOPO..KO", ".OOOOOO.", ".OOOOOO.", ".K.K.KK.", "........"])
let iconDog = grid(["KK......", "KQK.....", "QWQK..K.", "QQQQKKQ.", ".QQQQQQ.", ".QQQQQQ.", ".K.K.KK.", "........"])
let iconSnail = grid(["...KKK..", "..KMMMK.", "..KMKMK.", "..KMMMK.", "Y.KKKKY.", "YYYYYYYY", ".YYYYYY.", "........"])
let iconFish = grid(["..CCCC..", ".C....C.", "C.OO.O.C", "COWOOO.C", "C.OO.O.C", ".C....C.", "..CCCC..", "........"])
let iconParrot = grid(["..GGG...", ".GWKGY..", ".GGGGY..", "GGGGG...", "GGRRG...", ".GRR....", "..K.....", ".KK....."])
let iconBone = grid(["........", "WW....WW", "WWWWWWWW", ".WWWWWW.", "WWWWWWWW", "WW....WW", "........", "........"])
let iconYarn = grid(["..MMMM..", ".MMWMMM.", "MMMMWMMM", "MWMMMMWM", "MMMWMMMM", ".MMMMWM.", "..MMMM.M", "........"])
let iconPetFood = grid(["........", ".YYOYY..", "YOYYOYY.", "KKKKKKKK", "KCCCCCCK", ".KCCCCK.", "..KKKK..", "........"])
let iconFishFood = grid(["..KKKK..", "..KWWK..", ".KOOOOK.", ".KOYOOK.", ".KOOYOK.", ".KOOOOK.", ".KKKKKK.", "........"])
let iconDogHouse = grid(["...RR...", "..RRRR..", ".RRRRRR.", "RRRRRRRR", ".QQQQQQ.", ".QQKKQQ.", ".QQKKQQ.", ".QQKKQQ."])

final class SmallPet: NSObject {
    let kind: SmallPetKind
    let panel: NSPanel
    let view: SmallPetView
    var targetX: CGFloat?
    var flyTarget: NSPoint?
    var nextMove: Double = 0
    var sleeping = false
    var nextNap: Double = 0
    var napUntil: Double = 0
    var nextTalk: Double = 0
    var chasingRat = false
    var trail: [(NSPoint, Double)] = []
    var held = false

    init(kind: SmallPetKind, origin: NSPoint, size: NSSize, game: Game) {
        self.kind = kind
        panel = overlayPanel(NSRect(origin: origin, size: size), key: false)
        view = SmallPetView(frame: NSRect(origin: .zero, size: size))
        super.init()
        panel.level = .floating
        view.game = game
        view.pet = self
        panel.contentView = view
        panel.orderFrontRegardless()
        nextNap = game.time + Double.random(in: 5 * 60...15 * 60)
        nextTalk = game.time + Double.random(in: 60...240)
    }

    func remove() {
        panel.orderOut(nil)
        panel.close()
    }
}

final class SmallPetView: NSView {
    weak var game: Game?
    weak var pet: SmallPet?
    var facingLeft = false
    var moving = false
    var text: String?
    var textUntil: Double = 0
    var heartsUntil: Double = 0
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    let drag = Dragger()
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) {
        if drag.dragged(window), let pet, !pet.held { pet.held = true; game?.smallPetSay(pet, pet.kind.sound + "!", 1.5) }
    }
    override func mouseUp(with event: NSEvent) {
        guard let pet else { return }
        if drag.up() { pet.held = false; pet.targetX = nil; pet.flyTarget = nil } else { game?.openSmallPetMenu(pet) }
    }
    override func rightMouseDown(with event: NSEvent) { if let pet { game?.openSmallPetMenu(pet) } }

    override func draw(_ dirtyRect: NSRect) {
        guard let game, let pet else { return }
        let t = game.time
        let k = pet.kind
        let s: CGFloat = 3
        if k.id == "fish" {
            // аквариум
            let bowl = NSRect(x: 6, y: bounds.height - 56, width: bounds.width - 12, height: 52)
            NSColor(hex: 0x48cae4, alpha: 0.35).setFill()
            NSBezierPath(roundedRect: bowl, xRadius: 18, yRadius: 18).fill()
            NSColor(hex: 0x8d99ae).setStroke()
            let path = NSBezierPath(roundedRect: bowl, xRadius: 18, yRadius: 18); path.lineWidth = 2; path.stroke()
            NSColor(hex: 0x52b788).setFill()
            NSRect(x: bowl.minX + 12, y: bowl.maxY - 16, width: 3, height: 12).fill()
            NSRect(x: bowl.minX + 18, y: bowl.maxY - 12, width: 3, height: 8).fill()
            let fx = bowl.midX + CGFloat(sin(t * 0.7)) * (bowl.width / 2 - 20) - 10
            let fy = bowl.midY + CGFloat(sin(t * 1.3)) * 8 - 6
            drawGrid(k.frames[0], x: fx, y: fy, s: 3, flip: cos(t * 0.7) > 0, palette: game.color)
            if Int(t * 2) % 5 == 0 {
                NSColor(white: 1, alpha: 0.7).setFill()
                NSRect(x: fx + 4, y: fy - 8 - CGFloat(Int(t * 6) % 6) * 2, width: 3, height: 3).fill()
            }
        } else {
            // охлювът оставя следа
            if k.id == "snail", let win = window {
                for (p, at) in pet.trail {
                    let a = CGFloat(max(0, 1 - (t - at) / 60)) * 0.4
                    NSColor(white: 0.9, alpha: a).setFill()
                    NSRect(x: p.x - win.frame.minX, y: bounds.height - 3, width: 4, height: 2).fill()
                }
            }
            let frame = k.frames[moving ? Int(t * 8) % k.frames.count : 0]
            let w = CGFloat(frame[0].count) * s, h = CGFloat(frame.count) * s
            let x = (bounds.width - w) / 2, y = bounds.height - h - 2
            drawGrid(frame, x: x, y: y, s: s, flip: !facingLeft, palette: game.color)
            if pet.sleeping {
                let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy),
                                                        .foregroundColor: NSColor(hex: 0x5dade2)]
                ("z" as NSString).draw(at: NSPoint(x: x + w, y: y - 8 - CGFloat(Int(t) % 2) * 3), withAttributes: a)
            }
            // играчката до него
            if k.id == "dog" && game.pet.has("bone") && !moving {
                drawGrid(iconBone, x: facingLeft ? x - 22 : x + w + 2, y: bounds.height - 14, s: 1.5, palette: game.color)
            }
            if k.id == "cat" && game.pet.has("yarn") && !moving {
                drawGrid(iconYarn, x: (facingLeft ? x - 22 : x + w + 2) + CGFloat(sin(t * 2)) * 3, y: bounds.height - 14, s: 1.5,
                         palette: game.color)
            }
        }
        if t < heartsUntil {
            drawGrid(heartGrid, x: bounds.midX - 7, y: 6, s: 2, palette: game.color)
        }
        if let text, t < textUntil { drawRatBubble(text, in: self, bottom: 18) }
    }
}

extension Game {
    func smallPetName(_ id: String) -> String? { UserDefaults.standard.string(forKey: "petName_\(id)") }
    func smallPetLabel(_ k: SmallPetKind) -> String { smallPetName(k.id) ?? k.label }
    func smallPetFedAt(_ id: String) -> Date {
        UserDefaults.standard.object(forKey: "petFed_\(id)") as? Date ?? Date()
    }
    func smallPetHungry(_ id: String) -> Double { Date().timeIntervalSince(smallPetFedAt(id)) / 60 }
    func smallPet(_ id: String) -> SmallPet? { smallPets.first { $0.kind.id == id } }

    func smallPetSay(_ p: SmallPet, _ text: String, _ seconds: Double) {
        p.view.text = text
        p.view.textUntil = time + seconds
    }

    func feedSmallPet(_ p: SmallPet) {
        UserDefaults.standard.set(Date(), forKey: "petFed_\(p.kind.id)")
        p.view.heartsUntil = time + 2
        smallPetSay(p, p.kind.sound + " Ням!", 2)
        sfx("Pop")
    }

    func updateSmallPets(_ step: Double) {
        let visible = window.isVisible && !pet.dead
        // махнати или непокупени: изчезват
        let gone = smallPets.filter { !pet.has($0.kind.id) || !visible || minimalMode && $0.kind.id == "fish" }
        gone.forEach { $0.remove() }
        smallPets.removeAll { p in gone.contains { $0 === p } }
        guard visible else { return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        for k in smallPetKinds where pet.has(k.id) && smallPet(k.id) == nil && !(minimalMode && k.id == "fish") {
            let size = k.id == "fish" ? NSSize(width: 80, height: 80) : NSSize(width: 110, height: 64)
            var x = CGFloat.random(in: (vf.minX + 80)...max(vf.minX + 81, vf.maxX - 180))
            if let saved = UserDefaults.standard.object(forKey: "petX_\(k.id)") as? Double { x = CGFloat(saved) }
            let p = SmallPet(kind: k, origin: NSPoint(x: x, y: vf.minY), size: size, game: self)
            smallPets.append(p)
            if UserDefaults.standard.object(forKey: "petFed_\(k.id)") == nil {
                UserDefaults.standard.set(Date(), forKey: "petFed_\(k.id)")
            }
            if time > 5 { smallPetSay(p, k.sound + " Здрасти!", 2.5); nextNameAsk = min(nextNameAsk, time + 4) }
        }
        for p in smallPets { updateSmallPet(p, step, pr: pr, vf: vf) }

        // Пиксчо ги храни, когато са гладни (понякога забравя)
        if time > nextPetCare && !pet.asleep && errands.isEmpty && !busyMoving && hidePhase == .off && !playingGame
            && !monitorDetached && questionPanel == nil {
            nextPetCare = time + Double.random(in: 4 * 60...9 * 60)
            if let p = smallPets.first(where: { smallPetHungry($0.kind.id) > 60 }), Int.random(in: 0..<100) >= 25 {
                runBreakErrands([.feedPet(p.kind.id)])
            }
        }
    }

    private func updateSmallPet(_ p: SmallPet, _ step: Double, pr: NSRect, vf: NSRect) {
        let v = p.view, panel = p.panel
        v.needsDisplay = true
        let k = p.kind
        let m = NSEvent.mouseLocation
        let hitR = NSRect(x: panel.frame.midX - 26, y: panel.frame.minY, width: 52, height: k.id == "fish" ? 60 : 30)
        let hit = hitR.contains(m)
        setClickable(panel, hit)
        if p.held { return }
        var o = panel.frame.origin
        // пуснат от мишката: пада на пода (папагалът си лети)
        if k.id != "parrot" && o.y > vf.minY + 1 {
            o.y = max(vf.minY, o.y - CGFloat(800 * step))
            panel.setFrameOrigin(o)
            return
        }
        let half = panel.frame.width / 2
        let hungry = smallPetHungry(k.id)

        if time > p.nextTalk {
            p.nextTalk = time + Double.random(in: 2 * 60...5 * 60)
            if hungry > 90 {
                smallPetSay(p, k.sound + " (гладно)", 2.5)
            } else if k.id == "parrot", let last = bubbleText {
                smallPetSay(p, "Ррр! " + last, 3)
            } else {
                smallPetSay(p, k.sound, 1.8)
            }
        }
        if k.id == "fish" { o.y = vf.minY; panel.setFrameOrigin(o); return }

        // при тревога и те бягат зад ръба
        if hidePhase != .off && hidePhase != .returning {
            let goal = o.x + half < vf.midX ? vf.minX - panel.frame.width - 20 : vf.maxX + 20
            o.x += (goal > o.x ? 1 : -1) * min(abs(goal - o.x), CGFloat(500 * step))
            if k.id != "parrot" { o.y = vf.minY }
            v.moving = true
            v.facingLeft = goal < o.x
            panel.setFrameOrigin(o)
            return
        }

        // дрямка
        if p.sleeping {
            v.moving = false
            if time > p.napUntil && !(pet.asleep && Bool.random()) { p.sleeping = false }
            if k.id != "parrot" { o.y = vf.minY }
            panel.setFrameOrigin(o)
            return
        }
        if time > p.nextNap {
            p.nextNap = time + Double.random(in: 10 * 60...25 * 60)
            p.sleeping = true
            p.napUntil = time + (k.id == "cat" ? Double.random(in: 4 * 60...9 * 60) : Double.random(in: 2 * 60...4 * 60))
            return
        }

        if k.id == "parrot" {
            // лети: каца на главата на Пиксчо, на платформа или кръжи
            if p.flyTarget == nil || time > p.nextMove {
                p.nextMove = time + Double.random(in: 8...20)
                switch Int.random(in: 0..<3) {
                case 0: p.flyTarget = NSPoint(x: pr.midX - half, y: pr.maxY - 10)
                case 1: p.flyTarget = NSPoint(x: CGFloat.random(in: vf.minX...max(vf.minX + 1, vf.maxX - 110)), y: vf.minY)
                default: p.flyTarget = NSPoint(x: CGFloat.random(in: vf.minX...max(vf.minX + 1, vf.maxX - 110)),
                                               y: CGFloat.random(in: (vf.minY + 150)...max(vf.minY + 151, vf.maxY - 100)))
                }
            }
            if let t = p.flyTarget {
                let dx = t.x - o.x, dy = t.y - o.y
                let d = hypot(dx, dy)
                v.moving = d > 4
                if d > 4 {
                    let sp = min(d, k.speed * CGFloat(step))
                    o.x += dx / d * sp; o.y += dy / d * sp
                    v.facingLeft = dx < 0
                }
            }
            panel.setFrameOrigin(o)
            return
        }

        // котето понякога гони плъха
        if k.id == "cat" && ratIsOut && !p.chasingRat && Int.random(in: 0..<20000) < Int(step * 1000) {
            p.chasingRat = true
            smallPetSay(p, "Мяу! Мишка!", 2)
            ratSay("ЦИК! Котка!", 2)
        }
        if p.chasingRat, let rp = ratPanel {
            p.targetX = rp.frame.midX - half
            ratTarget = rp.frame.minX + (rp.frame.midX > o.x + half ? 260 : -260)
            if abs(rp.frame.midX - (o.x + half)) < 30 || Int.random(in: 0..<600) == 0 { p.chasingRat = false; p.targetX = nil }
        }
        // охлювът обича развалените пиксели на пода
        if k.id == "snail", let sf = foods.first(where: { $0.spoiled && $0.onFloor && !$0.view.held }) {
            p.targetX = sf.panel.frame.midX - half
            if abs(sf.panel.frame.midX - (o.x + half)) < 14 {
                sf.remove()
                foods.removeAll { $0 === sf }
                feedSmallPet(p)
                smallPetSay(p, "Ммм… развалено. Вкусно.", 2.5)
            }
        }
        // кучето ходи по-често след Пиксчо
        if p.targetX == nil && time > p.nextMove {
            p.nextMove = time + Double.random(in: 15...45)
            let followPet = k.id == "dog" ? Int.random(in: 0..<10) < 6 : Int.random(in: 0..<10) < 2
            p.targetX = followPet ? pr.midX + (Bool.random() ? -1 : 1) * (pr.width / 2 + 50) - half
                : CGFloat.random(in: (vf.minX + 40)...max(vf.minX + 41, vf.maxX - 150))
        }
        o.y = vf.minY
        if let tx = p.targetX {
            let dx = tx - o.x
            v.moving = abs(dx) > 3
            if v.moving {
                v.facingLeft = dx < 0
                let speed = p.chasingRat ? k.speed * 2.5 : k.speed
                let nx = o.x + (dx > 0 ? 1 : -1) * min(abs(dx), speed * CGFloat(step))
                if buddyBlockedAt(nx + half + (dx > 0 ? 14 : -14), vf.minY) { p.targetX = nil; v.moving = false } else { o.x = nx }
                if k.id == "snail" && (p.trail.last.map { abs($0.0.x - (o.x + half)) > 4 } ?? true) {
                    p.trail.append((NSPoint(x: o.x + half, y: o.y), time))
                    p.trail.removeAll { time - $0.1 > 60 }
                }
            } else {
                p.targetX = nil
                UserDefaults.standard.set(Double(o.x), forKey: "petX_\(k.id)")
            }
        } else {
            v.moving = false
        }
        panel.setFrameOrigin(o)
    }

    /// Пиксчо отива до любимеца и го храни.
    func updateFeedPetErrand(_ id: String, _ step: Double) {
        guard let p = smallPet(id) else { nextErrand(); return }
        switch errandStage {
        case 0:
            say("Отивам да нахраня \(smallPetLabel(p.kind))!", seconds: 2)
            errandStage = 1
        case 1:
            let spot = NSPoint(x: p.panel.frame.midX, y: id == "parrot" ? p.panel.frame.minY : floorY)
            if walkTo(feet: spot, speed: 280, step) {
                feedSmallPet(p)
                start(.love, length: 1.5)
                say("Заповядай, \(smallPetLabel(p.kind))!", seconds: 2)
                errandStage = 2
                errandStart = time
            }
        default:
            if time - errandStart > 2 { nextErrand() }
        }
    }

    /// Пусна пиксел върху любимец.
    func tryFeedSmallPet(_ food: FoodPixel) -> Bool {
        let f = food.panel.frame
        for p in smallPets where NSRect(x: p.panel.frame.midX - 30, y: p.panel.frame.minY, width: 60, height: 60)
            .contains(NSPoint(x: f.midX, y: f.midY)) {
            food.remove()
            foods.removeAll { $0 === food }
            feedSmallPet(p)
            return true
        }
        return false
    }

    func openSmallPetMenu(_ p: SmallPet) {
        attentionToOthers()
        let id = p.kind.id
        let label = smallPetLabel(p.kind)
        let buttons = [
            MiniButton(icon: iconFood, label: "Нахрани", enabled: true, action: { [weak self] in
                guard let self, let p = self.smallPet(id) else { return }
                if !self.pet.asleep && self.errands.isEmpty && !self.busyMoving && !self.monitorDetached {
                    self.runBreakErrands([.feedPet(id)])
                } else { self.feedSmallPet(p) }
            }),
            MiniButton(icon: iconHug, label: "Погали", enabled: true, action: { [weak self] in
                guard let self, let p = self.smallPet(id) else { return }
                p.view.heartsUntil = self.time + 2
                self.smallPetSay(p, p.kind.sound, 1.5)
                self.sfx("Purr")
            }),
            MiniButton(icon: iconTalk, label: "Смени името", enabled: true, action: { [weak self] in self?.askName("pet_" + id) }),
        ]
        showMiniMenu(title: label.capitalized, stats: [("Ситост", max(0, 1 - smallPetHungry(id) / 120), 0x52b788)],
                     buttons: buttons, above: NSPoint(x: p.panel.frame.midX, y: p.panel.frame.minY + 40))
    }
}
