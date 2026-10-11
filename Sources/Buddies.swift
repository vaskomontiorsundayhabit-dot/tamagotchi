// Приятели: идват на гости сами (не се купуват). След второто гостуване питат дали
// могат да останат. Всеки има професия: фотографка, музикант, готвачка, геймър, художничка.

import AppKit

struct BuddyKind {
    let id: String
    let job: String
    let defaultName: String
    let color: Int
    let female: Bool
    let lines: [String]
    let prop: Grid
}

let propCamera = grid([
    "..KKK.....",
    "KKKKKKKKKK",
    "KSSSKKKSSK",
    "KSSKCCKSSK",
    "KSSKCCKSSK",
    "KSSSKKSSSK",
    "KKKKKKKKKK",
])
let propGuitar = grid([
    "......KK",
    ".....KUK",
    "....KUK.",
    ".OOKUK..",
    "OOOOK...",
    "OOKOO...",
    "OOOOO...",
    ".OOO....",
])
let propPan = grid([
    ".YRY.....",
    "KKKKK....",
    "KEEEK....",
    "KEEEKUUUU",
    "KEEEK....",
    "KKKKK....",
])
let propPad = grid([
    ".KKKKKKKK.",
    "KSSSSSSSSK",
    "KSWSSSSRSK",
    "KWWWSSGSCK",
    "KSWSSSSYSK",
    ".KKK..KKK.",
])
let propBrush = grid([
    "......MM",
    ".....MM.",
    "....UU..",
    "...UU...",
    "..UU....",
    ".UU.....",
])

let buddyKinds: [BuddyKind] = [
    BuddyKind(id: "photo", job: "фотографка", defaultName: "Пиксчочка", color: 0xff8fab, female: true,
              lines: friendJobLines, prop: propCamera),
    BuddyKind(id: "music", job: "музикант", defaultName: "Нотко", color: 0x5dade2, female: false,
              lines: ["Тин-тирин!", "Нова песен за клипа ти!", "Ла-ла-лааа!", "Китарата ми е разстроена…", "Това е хит!"],
              prop: propGuitar),
    BuddyKind(id: "chef", job: "готвачка", defaultName: "Кексичка", color: 0xf4a261, female: true,
              lines: ["Пиксели на тиган!", "Малко сол… готово!", "Мирише ли ви на вкусно?", "Рецепта на баба!"], prop: propPan),
    BuddyKind(id: "gamer", job: "геймър", defaultName: "Джойко", color: 0x52b788, female: false,
              lines: ["GG!", "Още едно ниво!", "Лаг! ЛАГ!", "Стриймвам на живо!", "Кой ще ме бие?"], prop: propPad),
    BuddyKind(id: "artist", job: "художничка", defaultName: "Боя", color: 0xc77dff, female: true,
              lines: ["Малко лилаво тук…", "Шедьовър!", "Рисувам ти платформа!", "Изкуството иска жертви."], prop: propBrush),
]

final class Buddy: NSObject {
    let kind: BuddyKind
    let panel: NSPanel
    let view: BuddyView
    var guest: Bool
    var visitUntil: Double = 0
    var leaving = false
    var asked = false
    var working = false
    var sleeping = false
    var full: Double = 80
    var workSeconds: Double = 0
    var workStart: Double = 0
    var done = 0
    var nextFlash: Double = 0
    var nextLine: Double = 0
    var nextWork: Double = 0
    var nextHungry: Double = 0
    var nextAct: Double = 0
    var nextDance: Double = 0
    var target: NSPoint?
    var food: FoodPixel?

    init(kind: BuddyKind, guest: Bool, origin: NSPoint, game: Game) {
        self.kind = kind
        self.guest = guest
        panel = overlayPanel(NSRect(origin: origin, size: BuddyView.size), key: false)
        view = BuddyView(frame: NSRect(origin: .zero, size: BuddyView.size))
        super.init()
        panel.level = .floating
        view.game = game
        view.buddy = self
        panel.contentView = view
        panel.orderFrontRegardless()
        nextWork = game.time + Double.random(in: 2 * 60...6 * 60)
        nextAct = game.time + Double.random(in: 30...90)
    }

    func remove() {
        panel.orderOut(nil)
        panel.close()
    }
}

final class BuddyView: NSView {
    weak var game: Game?
    weak var buddy: Buddy?
    var text: String?
    var textUntil: Double = 0
    var face: Face = .normal
    var walking = false
    var facingLeft = false
    var flashAt: Double = -10
    static let size = NSSize(width: 210, height: 190)
    static let scale: CGFloat = 1.5
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        if let buddy { game?.buddyClicked(buddy) }
    }
    override func rightMouseDown(with event: NSEvent) {
        guard let game, let buddy else { return }
        NSMenu.popUpContextMenu(game.buddyMenu(buddy), with: event, for: self)
    }

    var feetY: CGFloat { 30 + CGFloat(canvasH) * BuddyView.scale }

    override func draw(_ dirtyRect: NSRect) {
        guard let game, let buddy else { return }
        let t = game.time
        let asleep = game.buddyAsleep(buddy)
        let working = buddy.working && !asleep
        let flashing = t - flashAt < 0.25
        let pose: Pose = asleep ? .sleep : (walking ? .walk : (flashing ? .wave : .idle))
        let f: Face = asleep ? .sleep : (working && !flashing ? .focus : face)
        let sp = buildSprite(level: 14, face: f, pose: pose, frame: Int(t * (walking ? 7 : 2)), working: false)
        let s = BuddyView.scale
        let ox = (bounds.width - CGFloat(canvasW) * s) / 2
        let flip = walking && facingLeft
        let body = NSColor(hex: buddy.kind.color)
        drawGrid(sp.grid, x: ox, y: 30, s: s, flip: flip, palette: { c in
            switch c {
            case "B": return body
            case "D": return body.blended(withFraction: 0.22, of: .black)
            case "L": return body.blended(withFraction: 0.45, of: .white)
            case "A": return body.blended(withFraction: 0.08, of: .black)
            default: return game.color(c)
            }
        })
        let cx = ox + CGFloat(sp.cx) * s
        let midY = 30 + CGFloat(sp.top + sp.bottom) / 2 * s
        if working {
            let prop = buddy.kind.prop
            let pw = CGFloat(prop[0].count) * 3
            let px = facingLeft ? cx - pw - 4 : cx + 4
            drawGrid(prop, x: px, y: midY - 6, s: 3, flip: facingLeft, palette: game.color)
            if flashing && buddy.kind.id == "photo" {
                NSColor(white: 1, alpha: 0.85).setFill()
                NSBezierPath(ovalIn: NSRect(x: px + 6, y: midY - 22, width: 20, height: 20)).fill()
            }
            if buddy.kind.id == "music" {
                // ноти във въздуха
                let a: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .heavy),
                                                        .foregroundColor: NSColor(hex: 0x2b2b3a)]
                for i in 0..<3 {
                    let ph = (t * 0.6 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    ("♪" as NSString).draw(at: NSPoint(x: cx + 20 + CGFloat(i) * 12 + CGFloat(sin(t * 3 + Double(i))) * 4,
                                                       y: midY - 20 - CGFloat(ph) * 40), withAttributes: a)
                }
            }
        }
        if asleep {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
                                                    .foregroundColor: body]
            for i in 0..<2 {
                let ph = (t * 0.5 + Double(i) / 2).truncatingRemainder(dividingBy: 1)
                ("z" as NSString).draw(at: NSPoint(x: cx + 20 + CGFloat(ph) * 14, y: 30 + CGFloat(sp.minY) * s - CGFloat(ph) * 20),
                                       withAttributes: a)
            }
        }
        let hoverText: String? = game.buddyHover(buddy) ? game.buddyName(buddy.kind) + (buddy.guest ? " (ГОСТ)" : "") : nil
        let shown = text.flatMap { t < textUntil ? $0 : nil } ?? hoverText
        if let shown {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .bold),
                                                    .foregroundColor: NSColor.white]
            let str = shown.uppercased() as NSString
            let size = str.boundingRect(with: NSSize(width: bounds.width - 16, height: 60), options: [.usesLineFragmentOrigin],
                                        attributes: a).size
            let w = ceil(size.width) + 10, h = ceil(size.height) + 6
            let r = NSRect(x: (bounds.width - w) / 2, y: max(0, 30 + CGFloat(sp.minY) * s - h - 4), width: w, height: h)
            body.blended(withFraction: 0.65, of: .black)?.withAlphaComponent(0.95).setFill(); r.fill()
            str.draw(with: r.insetBy(dx: 5, dy: 3), options: [.usesLineFragmentOrigin], attributes: a)
        }
    }
}

// MARK: - Логиката

extension Game {
    var joinedBuddies: [String] {
        get { UserDefaults.standard.stringArray(forKey: "buddies") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "buddies") }
    }

    func buddyKind(_ id: String) -> BuddyKind? { buddyKinds.first { $0.id == id } }

    func buddyName(_ k: BuddyKind) -> String {
        if let n = UserDefaults.standard.string(forKey: "buddyName_\(k.id)") { return n }
        if k.id == "photo", let n = UserDefaults.standard.string(forKey: "friendName") { return n }
        return k.defaultName
    }

    func buddyHasName(_ id: String) -> Bool {
        UserDefaults.standard.string(forKey: "buddyName_\(id)") != nil
            || id == "photo" && UserDefaults.standard.string(forKey: "friendName") != nil
    }

    func buddyAsleep(_ b: Buddy) -> Bool { b.sleeping || pet.asleep && !b.guest }
    func buddyHover(_ b: Buddy) -> Bool { b.panel.frame.insetBy(dx: 50, dy: 30).contains(NSEvent.mouseLocation) }
    var friendPanel: NSPanel? { buddies.first { !$0.guest }?.panel }
    var friendFeetY: CGFloat { buddies.first { !$0.guest }?.view.feetY ?? 0 }
    func buddy(_ id: String) -> Buddy? { buddies.first { $0.kind.id == id } }

    func buddySay(_ b: Buddy, _ text: String, _ seconds: Double) {
        b.view.text = text
        b.view.textUntil = time + seconds
    }

    func updateBuddies(_ step: Double) {
        // приятелката от магазина (старите запазвания) вече е приятел
        if pet.owned.contains("friend") && !joinedBuddies.contains("photo") { joinedBuddies.append("photo") }
        if !window.isVisible || pet.dead {
            buddies.forEach { $0.remove() }
            buddies.removeAll()
            return
        }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        for id in joinedBuddies where buddy(id) == nil {
            guard let k = buddyKind(id) else { continue }
            let b = Buddy(kind: k, guest: false, origin: NSPoint(x: pr.midX + 120, y: vf.minY), game: self)
            buddies.append(b)
        }
        // гости
        let idle = !pet.asleep && hidePhase == .off && seekPhase == .off && racePhase == .off
        if time > nextVisit && idle && !buddies.contains(where: { $0.guest }) {
            nextVisit = time + Double.random(in: 25 * 60...45 * 60)
            let free = buddyKinds.filter { !joinedBuddies.contains($0.id) }
            if let k = free.randomElement() {
                let left = Bool.random()
                let x = left ? vf.minX - BuddyView.size.width : vf.maxX
                let b = Buddy(kind: k, guest: true, origin: NSPoint(x: x, y: vf.minY), game: self)
                b.visitUntil = time + Double.random(in: 4 * 60...6 * 60)
                buddies.append(b)
                let visits = UserDefaults.standard.integer(forKey: "buddyVisits_\(k.id)") + 1
                UserDefaults.standard.set(visits, forKey: "buddyVisits_\(k.id)")
                buddySay(b, visits == 1 ? "Здрасти! Аз съм \(buddyName(k)), \(k.job)!" : "Пак съм аз, \(buddyName(k))!", 3)
                pendingReply = (visits == 1 ? (k.female ? "О, гости! Добре дошла!" : "О, гости! Добре дошъл!")
                                : "\(buddyName(k))! Пак си тук! Радвам се!", time + 3, false)
                sfx("Glass")
            }
        }
        for (i, b) in buddies.enumerated() { updateBuddy(b, index: i, step, pr: pr, vf: vf) }
        let gone = buddies.filter { $0.leaving && !$0.panel.frame.intersects(vf.insetBy(dx: -5, dy: -5)) }
        gone.forEach { $0.remove() }
        buddies.removeAll { b in gone.contains { $0 === b } }
    }

    private func updateBuddy(_ b: Buddy, index i: Int, _ step: Double, pr: NSRect, vf: NSRect) {
        let p = b.panel, v = b.view
        if !p.isVisible { p.orderFrontRegardless() }
        let y = vf.minY - (BuddyView.size.height - v.feetY)
        var o = p.frame.origin
        let asleep = buddyAsleep(b)
        v.needsDisplay = true
        let hit = buddyHover(b)
        if p.ignoresMouseEvents == hit { p.ignoresMouseEvents = !hit }

        // гостът си тръгва (или пита дали може да остане)
        if b.guest && !b.leaving && (time > b.visitUntil || pet.asleep) {
            let visits = UserDefaults.standard.integer(forKey: "buddyVisits_\(b.kind.id)")
            let canAsk = visits >= 2 && !b.asked && !pet.asleep
            if canAsk {
                if questionPanel == nil {
                b.asked = true
                pendingBuddy = b.kind.id
                buddySay(b, "Може ли да остана при вас?", 4)
                ask(Question(text: "\(buddyName(b.kind)) (\(b.kind.job)) иска да остане при нас. Да остане ли?", answers: [
                    ("ДА", "Ура! Вече живеем заедно!", .buddyStay), ("НЕ", "Добре… друг път.", .buddyGo),
                ]), index: -1)
                }
            } else if !b.asked || questionPanel == nil || pendingBuddy != b.kind.id {
                if pendingBuddy == b.kind.id { pendingBuddy = nil }
                b.leaving = true
                buddySay(b, "Чао! Пак ще дойда!", 2.5)
            }
        }
        if b.leaving {
            let goal = o.x + p.frame.width / 2 < vf.midX ? vf.minX - p.frame.width - 20 : vf.maxX + 20
            let dx = goal - o.x
            v.walking = true
            v.facingLeft = dx < 0
            o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(90 * step))
            o.y = y
            p.setFrameOrigin(o)
            return
        }
        if racePhase != .off && raceBuddy === b { return }

        if !asleep && !b.guest {
            b.full = max(0, b.full - step / 180)
            if b.full < 30 && time > b.nextHungry {
                b.nextHungry = time + Double.random(in: 4 * 60...7 * 60)
                buddySay(b, b.kind.female ? "Гладна съм! Дай ми пиксел!" : "Гладен съм! Дай ми пиксел!", 3)
            }
        }
        if b.working && !asleep { updateBuddyJob(b, step) }
        else if !asleep && !b.guest && !b.working && time > b.nextWork && b.full > 20 {
            b.nextWork = time + Double.random(in: 15 * 60...30 * 60)
            if pet.working || Bool.random() { startBuddyWork(b) }
        }

        if asleep {
            v.walking = false
        } else if let target = b.target {
            // тича към пиксел-храната
            let dx = target.x - o.x, dy = target.y - o.y
            let d = hypot(dx, dy)
            let sp = CGFloat(500 * step)
            v.walking = true
            v.facingLeft = dx < 0
            if d < sp {
                b.target = nil
                if let f = b.food, foods.contains(where: { $0 === f }) {
                    f.remove(); foods.removeAll { $0 === f }
                    b.full = min(100, b.full + 30)
                    buddySay(b, "Ням! Мое е!", 2)
                    if !pet.asleep {
                        say("ЕЙ! Това беше мое!", seconds: 2.5)
                        annoy(5, reason: "\(buddyName(b.kind)) ми открадна пиксела")
                    }
                    sfx("Pop")
                }
                b.food = nil
            } else {
                o.x += dx / d * sp; o.y += dy / d * sp
            }
        } else {
            // стои до Пиксчо: първият вляво, вторият вдясно, следващите по-навън
            let side: CGFloat = i % 2 == 0 ? -1 : 1
            let goal = pr.midX + side * (pr.width / 2 + 70 + CGFloat(i / 2) * 110) - BuddyView.size.width / 2
            let gx = min(max(goal, vf.minX - 40), vf.maxX - BuddyView.size.width + 40)
            let dx = gx - o.x
            v.walking = abs(dx) > 3 || abs(o.y - y) > 3
            if abs(dx) > 3 { v.facingLeft = dx < 0; o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(60 * step)) }
            if abs(o.y - y) > 3 { o.y += (y > o.y ? 1 : -1) * min(abs(y - o.y), CGFloat(300 * step)) } else { o.y = y }
            if !v.walking { v.facingLeft = pr.midX < o.x + BuddyView.size.width / 2 }
        }
        p.setFrameOrigin(o)

        guard time > b.nextAct, !pet.asleep, !asleep, hidePhase == .off else { return }
        b.nextAct = time + Double.random(in: 60...150)
        let r = Int.random(in: 0..<10)
        if (r < 2 || b.full < 30), let food = foods.randomElement() {
            b.food = food
            b.target = NSPoint(x: food.panel.frame.midX - BuddyView.size.width / 2, y: food.panel.frame.minY - v.feetY + 40)
            buddySay(b, "Пиксел!", 1.5)
        } else if r < 4 {
            let (a, c) = friendFights.randomElement()!
            buddySay(b, a, 3); v.face = .angry
            pendingReply = (c, time + 2.5, true)
        } else if r < 5 {
            buddySay(b, "Прегръдка!", 2); start(.love, length: 2)
            sfx("Purr")
        } else if r < 6 && b.kind.id == "gamer" && racePhase == .off {
            buddySay(b, "Хайде на състезание, \(pet.name)!", 3)
            offerRace(with: b)
        } else {
            let (a, c) = friendTalks.randomElement()!
            buddySay(b, a, 3); v.face = .happy
            pendingReply = (c, time + 2.5, false)
        }
    }

    // --- професиите ---

    func startBuddyWork(_ b: Buddy) {
        guard !buddyAsleep(b), !b.guest else { return }
        b.working = true
        b.workStart = time
        b.workSeconds = 0
        let starts: [String: String] = ["photo": "Вадя фотоапарата!", "music": "Настройвам китарата!", "chef": "Пристягам престилката!",
                                        "gamer": "Пускам стрийма!", "artist": "Вадя четките!"]
        buddySay(b, starts[b.kind.id] ?? "Почвам работа!", 2.5)
    }

    private func updateBuddyJob(_ b: Buddy, _ step: Double) {
        let v = b.view
        b.workSeconds += step
        if time > b.nextLine && time > v.textUntil {
            b.nextLine = time + Double.random(in: 70...160)
            buddySay(b, b.kind.lines.randomElement()!, 3)
        }
        switch b.kind.id {
        case "photo":
            if time > b.nextFlash {
                b.nextFlash = time + Double.random(in: 4...9)
                v.flashAt = time
                sfx("Tink", every: 3)
            }
            let lens = pet.owned.contains("lens")
            if b.workSeconds >= (lens ? 10 : 15) * 60 {
                b.workSeconds = 0
                earnCoins(lens ? 25 : 15)
                buddySay(b, "Готова фотосесия! +\(lens ? 25 : 15) монети", 3.5)
            }
        case "music":
            if time > b.nextDance && !pet.asleep && !pet.working && !busyMoving && action == .none {
                b.nextDance = time + Double.random(in: 90...180)
                start(.wave, length: 3)
                say(["Каква музика! Танцувам!", "Пусни я по-силно!", "Това е за следващия ми клип!"].randomElement()!, seconds: 2.5)
            }
            if b.workSeconds >= 15 * 60 {
                b.workSeconds = 0
                earnCoins(15)
                buddySay(b, "Концертът свърши! +15 монети", 3.5)
            }
        case "chef":
            if b.workSeconds >= 10 * 60 {
                b.workSeconds = 0
                if foods.count < 10 {
                    let pr = petScreenRect()
                    let f = FoodPixel(color: foodColors.randomElement()!, at: NSPoint(x: pr.midX + 40, y: pr.maxY + 20), game: self)
                    foods.append(f)
                }
                buddySay(b, "Сготвих ти пиксел, \(pet.name)!", 3)
                if !pet.asleep { say("Ммм, мирише страхотно!", seconds: 2.5) }
            }
        case "gamer":
            if b.workSeconds >= 15 * 60 {
                b.workSeconds = 0
                earnCoins(12)
                buddySay(b, "Стриймът свърши! +12 монети", 3.5)
            }
        case "artist":
            if b.workSeconds >= 12 * 60 {
                b.workSeconds = 0
                paintPlatform(b)
            }
        default:
            break
        }
        if time - b.workStart > 20 * 60 && !pet.working {
            b.working = false
            buddySay(b, "Стига работа за днес.", 2.5)
        }
    }

    /// Художничката рисува малка платформа близо до Пиксчо.
    private func paintPlatform(_ b: Buddy) {
        let pr = petScreenRect()
        let x0 = Int(floor((pr.midX + CGFloat.random(in: -160...160)) / drawCell))
        let y = Int(floor((feetScreenY + CGFloat.random(in: 90...160)) / drawCell))
        for dx in 0..<8 { drawCells[cellKey(x0 + dx, y)] = b.kind.color }
        redrawDrawing()
        saveDrawing()
        drawingChanged()
        buddySay(b, "Нарисувах ти платформа!", 3)
        if !pet.asleep { say("Ооо, нова платформа! Благодаря!", seconds: 2.5) }
    }

    // --- клик, меню, храна ---

    func buddyClicked(_ b: Buddy) {
        sfx("Purr")
        attentionToOthers()
        if buddyAsleep(b) { buddySay(b, "Ммм… остави ме да спя…", 2); return }
        if b.guest { buddySay(b, ["Здрасти!", "Хубаво е тук!", "\(pet.name) е много сладък!"].randomElement()!, 2.5); return }
        if b.full < 30 { buddySay(b, "Гладн\(b.kind.female ? "а" : "ен") съм… пусни ми пиксел!", 2.5); return }
        buddySay(b, ["Хи-хи!", "Аз съм приятел на \(pet.name)!", "Гъдел!", "Кажи му да ми даде пиксел!"].randomElement()!, 2.5)
    }

    func buddyMenu(_ b: Buddy) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        func item(_ title: String, _ code: Int) {
            let it = NSMenuItem(title: title, action: #selector(buddyMenuAction(_:)), keyEquivalent: "")
            it.target = self
            it.tag = code
            it.representedObject = b.kind.id
            menu.addItem(it)
        }
        let info = NSMenuItem(title: "\(buddyName(b.kind)) · \(b.kind.job)" + (b.guest ? " · на гости" : " · ситост \(Int(b.full))%"),
                              action: nil, keyEquivalent: "")
        info.isEnabled = false
        menu.addItem(info)
        menu.addItem(.separator())
        if b.guest {
            item("Покани да остане", 6)
        } else {
            item(b.working ? "Спри работа" : "Работи (\(b.kind.job))", 1)
            item(b.sleeping ? "Събуди" : "Приспи", 2)
            item("Нахрани с пиксел", 3)
            item("Състезание с \(pet.name)", 7)
            item("Смени името…", 5)
        }
        item("Прегърни \(pet.name)", 4)
        return menu
    }

    @objc func buddyMenuAction(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String, let b = buddy(id) else { return }
        switch sender.tag {
        case 1:
            if b.working { b.working = false; buddySay(b, "Почивка!", 2) }
            else if buddyAsleep(b) { buddySay(b, "Спя…", 1.5) } else { startBuddyWork(b) }
        case 2:
            b.sleeping.toggle()
            if b.sleeping { b.working = false; buddySay(b, "Лека нощ…", 2) } else { buddySay(b, "Добро утро!", 2) }
        case 3:
            if buddyAsleep(b) { buddySay(b, "Спя…", 1.5); return }
            if b.full > 90 { buddySay(b, "Пъл\(b.kind.female ? "на" : "ен") съм!", 2); return }
            b.full = min(100, b.full + 30)
            buddySay(b, "Ням! Благодаря!", 2)
            sfx("Pop")
        case 4:
            if buddyAsleep(b) { buddySay(b, "Спя…", 1.5); return }
            buddySay(b, "Прегръдка!", 2)
            start(.love, length: 2)
            if !pet.asleep { say("Ооо, и аз те обичам, \(buddyName(b.kind))!", seconds: 2.5) }
            sfx("Purr")
        case 5:
            askName(id)
        case 6:
            buddyJoins(b)
        case 7:
            offerRace(with: b)
        default:
            break
        }
    }

    func buddyJoins(_ b: Buddy) {
        guard b.guest else { return }
        b.guest = false
        b.leaving = false
        if !joinedBuddies.contains(b.kind.id) { joinedBuddies.append(b.kind.id) }
        confettiStart = time
        start(.love, length: 2.5)
        buddySay(b, "Ураа! Оставам!", 3)
        sfx("Hero")
        if !buddyHasName(b.kind.id) { nextNameAsk = time + 5 }
    }

    func buddyAnswer(stay: Bool) {
        guard let id = pendingBuddy, let b = buddy(id) else { return }
        pendingBuddy = nil
        if stay { buddyJoins(b) } else {
            b.leaving = true
            buddySay(b, "Добре… чао!", 2.5)
        }
    }

    /// Пусна пиксел върху приятел.
    func tryFeedFriend(_ food: FoodPixel) -> Bool {
        let f = food.panel.frame
        for b in buddies where !buddyAsleep(b) && b.panel.frame.insetBy(dx: 50, dy: 30).contains(NSPoint(x: f.midX, y: f.midY)) {
            food.remove()
            foods.removeAll { $0 === food }
            b.full = min(100, b.full + 30)
            buddySay(b, "Ням! Благодаря!", 2)
            sfx("Pop")
            attentionToOthers()
            return true
        }
        return false
    }

    func updateFriendReply() {
        guard let r = pendingReply, time > r.at else { return }
        pendingReply = nil
        if r.angry { start(.angry, length: 2) }
        if hidePhase == .off && seekPhase == .off && !pet.asleep { say(r.text, seconds: 3) }
        buddies.forEach { $0.view.face = .normal }
    }
}
