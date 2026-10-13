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

let propCan = grid([
    ".....C..",
    "KKKKK.C.",
    "KGGGKK.C",
    "KGGGK.KK",
    "KGGGK...",
    "KKKKK...",
])
let propLetter = grid([
    "WWWWWWWW",
    "WRWWWWRW",
    "WWRWWRWW",
    "WWWRRWWW",
    "WWWWWWWW",
])
let propFlask = grid([
    "..KKK..",
    "..KCK..",
    "..KCK..",
    ".KCCCK.",
    "KCCGCCK",
    "KCGGGCK",
    ".KKKKK.",
])
let propRibbon = grid([
    "PP......",
    "..P.....",
    "...PP...",
    ".....P.U",
    "......U.",
    ".....U..",
    "....U...",
])
let propLens = grid([
    ".KKK....",
    "KCCCK...",
    "KCWCK...",
    "KCCCK...",
    ".KKKU...",
    "....UU..",
    ".....UU.",
])

/// Приятел с приятел си говорят.
let buddyChats: [(String, String)] = [
    ("Видя ли какво монтира пак?", "Да! Пак експлозии!"),
    ("Искаш ли да играем на гоненица?", "Само ако аз гоня!"),
    ("Мислиш ли, че ще завали?", "Нося си чадър, за всеки случай."),
    ("Кой изяде последния пиксел?", "Плъхът! Не аз!"),
    ("Тази платформа твоя ли е?", "Нарисувах я сутринта!"),
    ("Да направим купон довечера?", "Аз нося музиката!"),
    ("Ти ли си най-бързият тук?", "След Пиксчо… може би."),
    ("Колко е часът?", "{час}! Време за пиксели!"),
]

let buddyKinds: [BuddyKind] = [
    BuddyKind(id: "photo", job: "фотографка", defaultName: "Пикселка", color: 0xff8fab, female: true,
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
    // нови непознати: идват на гости като другите и могат да останат
    BuddyKind(id: "garden", job: "градинарка", defaultName: "Листичка", color: 0x95d5b2, female: true,
              lines: ["Как расте цветето?", "Пръстта тук е чудесна!", "Всяко семе е чудо.", "Поливам, поливам…"], prop: propCan),
    BuddyKind(id: "post", job: "пощальон", defaultName: "Пликчо", color: 0xe9c46a, female: false,
              lines: ["Писмо за теб!", "Колетите не се носят сами!", "Подпиши тук, моля.", "Днес пощата е много."],
              prop: propLetter),
    BuddyKind(id: "science", job: "учен", defaultName: "Атомчо", color: 0x4cc9f0, female: false,
              lines: ["Еврика!", "Пикселите са от още по-малки пиксели!", "Експериментът почти стана…", "Бум! Ой."], prop: propFlask),
    BuddyKind(id: "dancer", job: "танцьорка", defaultName: "Пируетка", color: 0xf15bb5, female: true,
              lines: ["Едно, две, три, завъртане!", "Танцувай с мен!", "Ритъмът е навсякъде!", "Оп-па!"], prop: propRibbon),
    BuddyKind(id: "detective", job: "детектив", defaultName: "Лупко", color: 0xadb5bd, female: false,
              lines: ["Хмм… подозрително.", "Тук е минал плъх!", "Следите водят към кошчето.", "Случаят е решен!"], prop: propLens),
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
    var nextHome: Double = 0
    var target: NSPoint?
    var food: FoodPixel?
    var playRat = false
    var chatting = false
    var energy: Double = 90
    var wanderX: CGFloat?
    var nextWander: Double = 0
    var nextSleepCheck: Double = 0
    var growSeconds: Double = 0
    var hugGo = false
    var leaveAt: Double = 0
    var held = false
    var service: String?          // „mail“ или „garden“: идва само по работа
    var serviceDone = false
    var nextGamerThing: Double = 0
    var nextPaint: Double = 0
    var playPlant = false

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
        nextHome = game.time + Double.random(in: 30 * 60...60 * 60)
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
    /// Изражение за няколко секунди (после пак според настроението).
    var face: Face = .normal { didSet { faceUntil = (game?.time ?? 0) + 4 } }
    var faceUntil: Double = 0
    var lookX = 0                     // накъде гледа, докато си говорят
    var walking = false
    var facingLeft = false
    var flashAt: Double = -10
    var heartsUntil: Double = 0
    static let scale: CGFloat = 3     // като Пиксчо: всяко ниво е още едно квадратче
    static let size = NSSize(width: CGFloat(canvasW) * 3 + 20, height: 40 + CGFloat(canvasH) * 3 + 10)
    var spriteBox = NSRect.zero        // заетата част (за кликовете)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    let drag = Dragger()
    override func mouseDown(with event: NSEvent) { drag.down(window) }
    override func mouseDragged(with event: NSEvent) {
        if drag.dragged(window), let buddy, !buddy.held {
            buddy.held = true
            game?.buddySay(buddy, ["Ей! Къде ме носиш?", "Уиии!", "Пусни ме!"].randomElement()!, 1.5)
        }
    }
    override func mouseUp(with event: NSEvent) {
        guard let buddy else { return }
        if drag.up() { buddy.held = false; buddy.wanderX = nil; buddy.nextWander = (game?.time ?? 0) + 30 }
        else { game?.buddyClicked(buddy) }
    }
    override func rightMouseDown(with event: NSEvent) {
        guard let game, let buddy else { return }
        game.openBuddyMenu(buddy)
    }

    var feetY: CGFloat { 40 + CGFloat(canvasH) * BuddyView.scale }

    override func draw(_ dirtyRect: NSRect) {
        guard let game, let buddy else { return }
        let t = game.time
        let asleep = game.buddyAsleep(buddy)
        let working = buddy.working && !asleep
        let flashing = t - flashAt < 0.25
        let pose: Pose = asleep ? .sleep : (walking ? .walk : (flashing ? .wave : .idle))
        // изражения: говори (устата мърда), съсредоточен, гладен, уплашен, мига…
        let talking = text != nil && t < textUntil
        var f: Face = .normal
        if asleep { f = .sleep }
        else if t < faceUntil && face != .normal { f = face }
        else if talking { f = Int(t * 6) % 2 == 0 ? .eatOpen : .normal }
        else if working && !flashing { f = .focus }
        else if game.hidePhase != .off { f = .crazy }
        else if buddy.full < 30 && !buddy.guest { f = .sad }
        else if t.truncatingRemainder(dividingBy: 4.1 + Double(buddy.kind.color % 7) * 0.35) < 0.15 { f = .blink }
        let sp = buildSprite(level: game.buddyLevel(buddy.kind.id), face: f, pose: pose, frame: Int(t * (walking ? 7 : 2)), working: false,
                             lookX: walking ? 0 : lookX)
        let s = BuddyView.scale
        let ox = (bounds.width - CGFloat(canvasW) * s) / 2
        let oy: CGFloat = 40
        let flip = walking && facingLeft
        let body = NSColor(hex: buddy.kind.color)
        let l = flip ? ox + CGFloat(canvasW - 1 - sp.maxX) * s : ox + CGFloat(sp.minX) * s
        spriteBox = NSRect(x: l, y: oy + CGFloat(sp.minY) * s, width: CGFloat(sp.maxX - sp.minX + 1) * s,
                           height: CGFloat(sp.maxY - sp.minY + 1) * s).insetBy(dx: -6, dy: -6)
        if buddy.chatting {
            // говорят си: малки точки над главата
            NSColor(hex: 0x8d99ae).setFill()
            for i in 0..<3 where Int(t * 3) % 3 >= i {
                NSRect(x: spriteBox.midX - 8 + CGFloat(i) * 6, y: spriteBox.minY - 10, width: 3, height: 3).fill()
            }
        }
        drawGrid(sp.grid, x: ox, y: oy, s: s, flip: flip, palette: { c in
            switch c {
            case "B": return body
            case "D": return body.blended(withFraction: 0.22, of: .black)
            case "L": return body.blended(withFraction: 0.45, of: .white)
            case "A": return body.blended(withFraction: 0.08, of: .black)
            default: return game.color(c)
            }
        })
        let cx = ox + CGFloat(flip ? canvasW - 1 - sp.cx : sp.cx) * s
        let midY = oy + CGFloat(sp.top + sp.bottom) / 2 * s
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
        if t < heartsUntil {
            // прегръдка: сърца над двамата
            for i in 0..<3 {
                let ph = CGFloat((t * 0.8 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1))
                drawGrid(heartGrid, x: spriteBox.midX - 24 + CGFloat(i) * 16, y: spriteBox.minY - 6 - ph * 26, s: 2.5, palette: game.color)
            }
        }
        if asleep {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
                                                    .foregroundColor: body]
            for i in 0..<2 {
                let ph = (t * 0.5 + Double(i) / 2).truncatingRemainder(dividingBy: 1)
                ("z" as NSString).draw(at: NSPoint(x: cx + 20 + CGFloat(ph) * 14, y: oy + CGFloat(sp.minY) * s - CGFloat(ph) * 20),
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
            let r = NSRect(x: min(max(2, cx - w / 2), bounds.width - w - 2), y: max(0, oy + CGFloat(sp.minY) * s - h - 4), width: w, height: h)
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
        if k.id == "photo", let n = UserDefaults.standard.string(forKey: "friendName"), n != "Пиксчочка" { return n }
        return k.defaultName
    }

    func buddyHasName(_ id: String) -> Bool {
        UserDefaults.standard.string(forKey: "buddyName_\(id)") != nil
            || id == "photo" && UserDefaults.standard.string(forKey: "friendName") != nil
    }

    /// Спят по свой график (не непременно с Пиксчо).
    func buddyAsleep(_ b: Buddy) -> Bool { b.sleeping }
    func buddyScreenBox(_ b: Buddy) -> NSRect {
        let r = b.view.spriteBox, f = b.panel.frame
        return NSRect(x: f.minX + r.minX, y: f.maxY - r.maxY, width: r.width, height: r.height)
    }
    func buddyHover(_ b: Buddy) -> Bool { buddyScreenBox(b).contains(NSEvent.mouseLocation) }
    var friendPanel: NSPanel? { buddies.first { !$0.guest }?.panel }
    var friendFeetY: CGFloat { buddies.first { !$0.guest }?.view.feetY ?? 0 }
    func buddy(_ id: String) -> Buddy? { buddies.first { $0.kind.id == id } }

    func buddySay(_ b: Buddy, _ text: String, _ seconds: Double) {
        b.view.text = text
        b.view.textUntil = time + readTime(text, seconds)
        if let f = faceFor(text) { b.view.face = f }
    }

    /// Лицето според това, което казва.
    func faceFor(_ text: String) -> Face? {
        let t = text.lowercased()
        if ["лъжеш", "сърдит", "стига", "грр", "махай", "не съм съгласн", "ядоса", "защо не вдигаш"].contains(where: { t.contains($0) }) { return .angry }
        if ["хаха", "хи-хи", "ура", "обичам", "благодаря", "гуш", "браво", "супер", "страхотно", "ооо"].contains(where: { t.contains($0) }) { return .happy }
        if ["ох", "уф", "тъжно", "жалко", "гладн", "уморен", "плача"].contains(where: { t.contains($0) }) { return .sad }
        if ["сериозно?", "какво?!", "ааа", "леле", "уау", "еврика"].contains(where: { t.contains($0) }) { return .crazy }
        return nil
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
        // обаждане по телефона: идва след малко
        if let c = pendingCall, time > c.at {
            pendingCall = nil
            if let k = buddyKind(c.id), buddy(c.id) == nil {
                if joinedBuddies.contains(c.id) {
                    UserDefaults.standard.removeObject(forKey: "buddyAway_\(c.id)")
                    approvedReturn.insert(c.id)
                } else {
                    arriveAsGuest(k, vf: vf)
                }
            }
        }
        // не си отговорил на обаждането: пита пак след малко
        if let id = pendingVisitor, questionPanel == nil { pendingVisitor = nil; missCall(id) }
        for id in joinedBuddies where buddy(id) == nil && !buddyIsAway(id) {
            guard let k = buddyKind(id) else { continue }
            // връща се от вкъщи: първо звъни и пита (при пускане на програмата идва направо)
            if time > 10 && !approvedReturn.contains(id) {
                if pendingVisitor == nil && questionPanel == nil && !pet.asleep && hidePhase == .off { askVisit(k) }
                continue
            }
            approvedReturn.remove(id)
            // идва от ръба на екрана
            let b = Buddy(kind: k, guest: false, origin: NSPoint(x: vf.minX - BuddyView.size.width, y: vf.minY), game: self)
            buddies.append(b)
            if time > 5 {
                buddySay(b, ["Върнах се!", "Ето ме пак!", "Здрасти, \(pet.name)! Вкъщи беше скучно."].randomElement()!, 3)
                afterArrival(b, giftChance: 3)
                // ако си е тръгнал сърдит, сам идва да се сдобрят (после разговорите са нормални)
                if UserDefaults.standard.bool(forKey: "buddyFight_\(id)") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self, weak b] in
                        guard let self, let b, !b.leaving, self.dialog.isEmpty, !self.pet.asleep else { return }
                        self.buddyConversation(b)
                    }
                }
            }
        }
        // гости
        let idle = !pet.asleep && hidePhase == .off && seekPhase == .off && racePhase == .off
        if time > nextVisit && idle && !buddies.contains(where: { $0.guest }) {
            nextVisit = time + Double.random(in: 25 * 60...45 * 60)
            let free = buddyKinds.filter { !joinedBuddies.contains($0.id) && !buddyMovedAway($0.id) }
            if let k = free.randomElement() {
                // гостът първо звъни и пита дали може да дойде
                if pendingVisitor == nil && questionPanel == nil && !pet.asleep { askVisit(k) }
            }
        }
        // препил с кафе: плаши приятелите и те си отиват до вкъщи
        if isHyper && time - scaredBuddiesAt > 20 * 60 && !buddies.isEmpty {
            scaredBuddiesAt = time
            for b in buddies where !b.leaving {
                b.leaving = true
                b.working = false
                if !b.guest { UserDefaults.standard.set(Date().addingTimeInterval(30 * 60), forKey: "buddyAway_\(b.kind.id)") }
                buddySay(b, ["Ох, пак е изпил сто кафета! Отивам си!", "Страшен е така! Чао!", "Ще дойда, като се успокои!"]
                    .randomElement()!, 3)
                changeFriendship(b.kind.id, -5)
            }
        }
        updateServices()
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
        setClickable(p, buddyHover(b))
        // хванат с мишката: не мърда сам; пуснат: пада на пода
        if b.held { v.walking = false; return }
        if o.y > y + 1 && !inBuddyGame(b.kind.id) && !(racePhase != .off && raceBuddy === b) {
            o.y = max(y, o.y - CGFloat(800 * step))
            p.setFrameOrigin(o)
            return
        }

        // тревога: всички бягат зад ръба (към ръба без друг екран до него; иначе изчезват зад него)
        if hidePhase != .off && hidePhase != .returning {
            let sf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.frame ?? vf
            let side = hideSide(x: o.x + p.frame.width / 2, screen: sf)
            let goal = side.left ? vf.minX - p.frame.width - 30 : vf.maxX + 30
            let dx = goal - o.x
            v.walking = abs(dx) > 3
            v.facingLeft = dx < 0
            o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(600 * step))
            o.y = y
            p.setFrameOrigin(o)
            if abs(dx) <= 3 && p.alphaValue != 0 { p.alphaValue = 0 }
            if b.view.text == nil || time > b.view.textUntil, abs(dx) > 200 { buddySay(b, "АААА! Бягам!", 1.5) }
            return
        }
        if p.alphaValue == 0 { p.alphaValue = 1 }
        // докато говори, стои на едно място (за да се чете)
        let talking = v.text != nil && time < v.textUntil

        // понякога си отиват до вкъщи (и после се връщат)
        if !b.guest && !b.leaving && time > b.nextHome {
            b.nextHome = time + Double.random(in: 30 * 60...60 * 60)
            if !b.working && !pet.asleep && racePhase == .off && Int.random(in: 0..<100) < 35 {
                b.leaving = true
                UserDefaults.standard.set(Date().addingTimeInterval(Double.random(in: 20 * 60...60 * 60)), forKey: "buddyAway_\(b.kind.id)")
                buddySay(b, ["Отивам си до вкъщи, ще се върна!", "Мама ме вика за вечеря. Чао!", "Отивам да си почина у дома."]
                    .randomElement()!, 3)
                pendingReply = ("Чао, \(buddyName(b.kind))! Ела пак!", time + 2.5, false)
            }
        }

        // гостът си тръгва (или пита дали може да остане)
        if b.guest && !b.leaving && (time > b.visitUntil || pet.asleep) {
            let visits = UserDefaults.standard.integer(forKey: "buddyVisits_\(b.kind.id)")
            let canAsk = b.service == nil && visits >= visitsNeeded(b.kind.id) && !b.asked && !pet.asleep
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
            if talking { v.walking = false; o.y = y; p.setFrameOrigin(o); return }
            let goal = o.x + p.frame.width / 2 < vf.midX ? vf.minX - p.frame.width - 20 : vf.maxX + 20
            let dx = goal - o.x
            v.walking = true
            v.facingLeft = dx < 0
            o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(90 * step))
            o.y = y
            p.setFrameOrigin(o)
            return
        }
        if b.leaveAt > 0 && time > b.leaveAt && !b.leaving {
            b.leaveAt = 0
            b.leaving = true
            b.working = false
            if !b.guest {
                UserDefaults.standard.set(Date().addingTimeInterval(Double.random(in: 20 * 60...40 * 60)), forKey: "buddyAway_\(b.kind.id)")
            }
            buddySay(b, b.kind.female ? "Сърдита съм! Отивам си вкъщи!" : "Сърдит съм! Отивам си вкъщи!", 3)
            pendingReply = (["Ех… може би прекалих.", "Добре де, върви си!", "Ще ти се обадя по-късно…"].randomElement()!, time + 3, false)
        }
        if racePhase != .off && raceBuddy === b { return }
        if inBuddyGame(b.kind.id) { return }
        // отива да прегърне Пиксчо: допират се и излизат сърца
        if b.hugGo && !asleep && !talking {
            let side: CGFloat = buddyScreenBox(b).midX < pr.midX ? -1 : 1
            let goalMid = pr.midX + side * (pr.width / 2 + buddyScreenBox(b).width / 2 - 14)
            let dx = goalMid - buddyScreenBox(b).midX
            o.y = y
            if abs(dx) > 5 {
                v.walking = true
                v.facingLeft = dx < 0
                o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(160 * step))
            } else {
                b.hugGo = false
                v.walking = false
                v.facingLeft = side > 0
                v.heartsUntil = time + 3
                v.face = .happy
                buddySay(b, "Прегръдка!", 2.5)
                if !pet.asleep {
                    facingLeft = side < 0
                    start(.love, length: 3)
                    say(["Ооо, и аз те обичам, \(buddyName(b.kind))!", "Гуш-гуш!", "Най-добрата прегръдка!"].randomElement()!, seconds: 2.5)
                }
                changeFriendship(b.kind.id, 5)
                sfx("Purr")
            }
            p.setFrameOrigin(o)
            return
        }

        // собствен сън: изморява се (нощем повече), спи си и става
        let hour = Calendar.current.component(.hour, from: Date())
        if b.sleeping {
            b.energy = min(100, b.energy + step / 40)
            if b.energy >= 100 {
                b.sleeping = false
                buddySay(b, ["Добро утро!", "Наспах се!", "Ааах… какво пропуснах?"].randomElement()!, 2.5)
            }
        } else {
            b.energy = max(0, b.energy - step / 300 * ((hour >= 23 || hour < 7) ? 3 : 1))
            if b.energy < 15 && !b.working && !b.guest {
                b.sleeping = true
                buddySay(b, b.kind.female ? "Уморена съм… лягам за малко." : "Уморен съм… лягам за малко.", 2.5)
            }
        }
        // расте с времето, докато живее при вас (на 30 минути по едно квадратче)
        if !b.guest {
            b.growSeconds += step
            if b.growSeconds >= 30 * 60 {
                b.growSeconds = 0
                growBuddy(b, by: 1)
            }
        }

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

        // идва по работа (поща, градина)
        if b.service != nil && !asleep {
            updateService(b, step, pr: pr, vf: vf)
            return
        }
        // плъхът тича: следи го, докато го стигне
        if b.playRat {
            if let rp = ratPanel, ratIsOut { b.target = NSPoint(x: rp.frame.midX - BuddyView.size.width / 2, y: o.y) }
            else { b.playRat = false; b.target = nil }
        }
        // художничката отива до мястото, където рисува
        let painting = b.kind.id == "artist" && !artistQueue.isEmpty
        if painting { b.wanderX = artistTargetX; b.nextWander = time + 20 }
        if asleep || talking {
            v.walking = false
        } else if let target = b.target {
            // тича по пода към пиксела (не лети и не минава през нарисуваното)
            let dx = target.x - o.x
            let sp = CGFloat(260 * step)
            v.walking = true
            v.facingLeft = dx < 0
            o.y = y
            let mid = o.x + BuddyView.size.width / 2
            if abs(dx) >= sp && buddyBlockedAt(mid + (dx > 0 ? sp + 10 : -sp - 10), vf.minY) {
                b.target = nil
                b.food = nil
                buddySay(b, "Не мога да мина оттук…", 1.5)
            } else if abs(dx) < sp + (b.playRat ? 20 : 0) {
                b.target = nil
                if let f = b.food, foods.contains(where: { $0 === f }) {
                    f.remove(); foods.removeAll { $0 === f }
                    b.full = min(100, b.full + 30)
                    buddyAte(b)
                    buddySay(b, "Ням! Мое е!", 2)
                    if !pet.asleep {
                        say("ЕЙ! Това беше мое!", seconds: 2.5)
                        annoy(5, reason: "\(buddyName(b.kind)) ми открадна пиксела")
                    }
                    sfx("Pop")
                }
                b.food = nil
                if b.playRat {
                    // стигна плъха: играят си
                    b.playRat = false
                    ratPlayedAt = Date()
                    ratView?.heartsUntil = time + 2
                    ratSay(["Цик! Гъдел!", "Хи-цик!", "Хвани ме, цик!"].randomElement()!, 2)
                    buddySay(b, ["Гуш, \(ratLabel)!", "Хванах те, \(ratLabel)!", "Какво сладко плъхче!"].randomElement()!, 2.5)
                    v.face = .happy
                    if Bool.random() { ratTarget = (ratPanel?.frame.minX ?? 0) + CGFloat.random(in: -200...200) }
                }
            } else {
                o.x += dx > 0 ? sp : -sp
            }
        } else {
            // свои занимания: ходи си насам-натам, понякога идва при Пиксчо, понякога си стои
            if time > b.nextWander {
                b.nextWander = time + Double.random(in: 25...70)
                let r = Int.random(in: 0..<10)
                let side: CGFloat = i % 2 == 0 ? -1 : 1
                if r < 5 {
                    b.wanderX = CGFloat.random(in: (vf.minX + 60)...max(vf.minX + 61, vf.maxX - 60))
                } else if r < 8 {
                    b.wanderX = pr.midX + side * (pr.width / 2 + 90 + CGFloat(i / 2) * 120)
                } else {
                    b.wanderX = nil
                    if !b.working && Int.random(in: 0..<3) == 0 { buddySay(b, buddyIdleLines.randomElement()!, 3) }
                }
            }
            o.y = y
            if let wx = b.wanderX {
                let gx = min(max(wx - BuddyView.size.width / 2, vf.minX - 60), vf.maxX - BuddyView.size.width + 60)
                let dx = gx - o.x
                v.walking = abs(dx) > 3
                if v.walking {
                    v.facingLeft = dx < 0
                    let nx = o.x + (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat((abs(dx) > 300 ? 160 : 60) * step))
                    if !painting && buddyBlockedAt(nx + BuddyView.size.width / 2 + (dx > 0 ? 12 : -12), vf.minY) {
                        v.walking = false
                        b.wanderX = nil
                    } else { o.x = nx }
                } else {
                    b.wanderX = nil
                }
            } else {
                v.walking = false
            }
        }
        p.setFrameOrigin(o)

        guard time > b.nextAct, !asleep, hidePhase == .off, dialog.isEmpty else { return }
        b.nextAct = time + Double.random(in: 50...130)
        let r = Int.random(in: 0..<14)
        let others = buddies.filter { $0 !== b && !$0.leaving && !buddyAsleep($0) && $0.service == nil }
        let petFree = !pet.asleep && hidePhase == .off
        if (r < 2 || b.full < 30), let food = foods.filter({ $0.onFloor && !$0.view.held && !$0.golden }).randomElement() {
            b.food = food
            b.target = NSPoint(x: food.panel.frame.midX - BuddyView.size.width / 2, y: food.panel.frame.minY - v.feetY + 40)
            buddySay(b, "Пиксел!", 1.5)
        } else if r == 3, buddyGame == nil, !others.isEmpty || ratIsOut {
            startBuddyGame()
        } else if r < 4, let o2 = others.randomElement(), Int.random(in: 0..<5) == 0 {
            // понякога се карат помежду си
            buddiesArgue(b, o2)
        } else if r < 4, let o2 = others.randomElement() {
            // говорят си помежду си (няколко реплики)
            var lines: [(String, String)]
            if Int.random(in: 0..<10) < 7 {
                // нов разговор от шаблон
                let g = generatedTalk(female: b.kind.female, exclude: [b.kind.id, o2.kind.id])
                lines = g.lines.enumerated().map { ($0.offset % 2 == 0 ? b.kind.id : o2.kind.id, $0.element) }
            } else {
                let (a, c) = buddyChats.randomElement()!
                lines = [(b.kind.id, a), (o2.kind.id, c), (b.kind.id, ["Хаха!", "Точно така.", "Ще видим!", "Така е!"].randomElement()!)]
            }
            // и другите (и Пиксчо) се включват
            for o3 in others where o3 !== o2 { lines.append((o3.kind.id, groupInterjections.randomElement()!)) }
            if !pet.asleep && hidePhase == .off && Bool.random() { lines.append(("pet", groupInterjections.randomElement()!)) }
            startDialog(lines)
        } else if r == 6, b.kind.id == "photo", !photos.isEmpty, !pet.asleep {
            maybeShowPhoto(b)
        } else if r < 6, ratIsOut, let rp = ratPanel {
            // отива да си играе с плъха
            b.playRat = true
            b.target = NSPoint(x: rp.frame.midX - BuddyView.size.width / 2, y: o.y)
            buddySay(b, "\(ratLabel.capitalized)! Ела да си играем!", 2)
        } else if r < 7, petFree {
            b.hugGo = true
            buddySay(b, "Идвам да те гушна!", 2)
        } else if r < 8 && b.kind.id == "gamer" && racePhase == .off && petFree {
            buddySay(b, "Хайде на състезание, \(pet.name)!", 3)
            offerRace(with: b)
        } else if petFree && !b.guest && (r < 10 || b.working && r < 11)
                    && Date().timeIntervalSince(UserDefaults.standard.object(forKey: "buddyArgAt_\(b.kind.id)") as? Date ?? .distantPast) > 3 * 3600
                    && Bool.random() {
            // Пиксчо се дразни от нещо (зависи от професията) и се карат, но не по-често от веднъж на 3 часа с един и същ
            UserDefaults.standard.set(Date(), forKey: "buddyArgAt_\(b.kind.id)")
            buddyArgument(b)
        } else if petFree {
            buddyConversation(b)
        }
    }

    /// Гост пристига от ръба на екрана. Ако Пиксчо работи, реагира различно.
    func arriveAsGuest(_ k: BuddyKind, vf: NSRect) {
        let left = Bool.random()
        let x = left ? vf.minX - BuddyView.size.width : vf.maxX
        let b = Buddy(kind: k, guest: true, origin: NSPoint(x: x, y: vf.minY), game: self)
        b.visitUntil = time + Double.random(in: 4 * 60...6 * 60)
        buddies.append(b)
        let visits = UserDefaults.standard.integer(forKey: "buddyVisits_\(k.id)") + 1
        UserDefaults.standard.set(visits, forKey: "buddyVisits_\(k.id)")
        buddySay(b, visits == 1 ? "Здрасти! Аз съм \(buddyName(k)), \(k.job)!" : "Пак съм аз, \(buddyName(k))!", 3)
        sfx("Glass")
        afterArrival(b, giftChance: visits == 1 ? 2 : 3)
        if pet.working || goingToWork {
            switch Int.random(in: 0..<3) {
            case 0:
                pendingReply = ("Сега монтирам! Седни, ще свърша скоро.", time + 3, false)
                b.visitUntil += 5 * 60
            case 1:
                pendingReply = ("\(buddyName(k))! За теб ще спра работа!", time + 3, false)
                stopWork()
            default:
                pendingReply = ("Ох, точно сега съм зает… клиентът чака.", time + 3, false)
                b.visitUntil = time + 8
                buddySay(b, "Виждам, че си зает. Ще мина по-късно!", 3)
            }
            return
        }
        pendingReply = (visits == 1 ? (k.female ? "О, гости! Добре дошла!" : "О, гости! Добре дошъл!")
                        : "\(buddyName(k))! Пак си тук! Радвам се!", time + 3, false)
    }

    /// Приятелят звъни: „Може ли да дойда?“ — ти решаваш.
    func askVisit(_ k: BuddyKind) {
        guard time > nextVisitAsk, !buddyOffended(k.id) else { return }
        if hideAll {
            // звъни, но никой не вдига
            missCall(k.id)
            return
        }
        pendingVisitor = k.id
        phoneUntil = time + 4
        sfx("Glass")
        let home = joinedBuddies.contains(k.id)
        ask(Question(text: home ? "\(buddyName(k)) звъни: иска да се върне от вкъщи. Да дойде ли?"
                                : "\(buddyName(k)) (\(k.job)) звъни: може ли да дойде на гости?", answers: [
            ("ДА", "Ела! Чакаме те!", .visitYes), ("НЕ", "Сега не може, друг път!", .visitNo),
        ]), index: -1)
    }

    func visitAnswer(_ yes: Bool) {
        guard let id = pendingVisitor, let k = buddyKind(id) else { return }
        pendingVisitor = nil
        // вдигна: ще си каже, ако е звъняла много пъти
        let missed = UserDefaults.standard.integer(forKey: "buddyMissed_\(id)")
        UserDefaults.standard.set(0, forKey: "buddyMissed_\(id)")
        if yes && missed >= 2 { UserDefaults.standard.set(missed, forKey: "buddyComplain_\(id)") }
        let home = joinedBuddies.contains(id)
        if yes {
            if home { approvedReturn.insert(id) } else {
                let pr = petScreenRect()
                arriveAsGuest(k, vf: screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero)
            }
        } else if home {
            // остава си вкъщи още малко
            UserDefaults.standard.set(Date().addingTimeInterval(30 * 60), forKey: "buddyAway_\(id)")
        }
    }

    // --- пропуснати обаждания ---

    var missedLog: [String] {
        get { UserDefaults.standard.stringArray(forKey: "missedCalls") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "missedCalls") }
    }

    func missedCount(_ id: String) -> Int { UserDefaults.standard.integer(forKey: "buddyMissed_\(id)") }

    func buddyOffended(_ id: String) -> Bool {
        (UserDefaults.standard.object(forKey: "buddyOffended_\(id)") as? Date ?? .distantPast) > Date()
    }

    /// Звъняха, а никой не вдигна. След 3 пропуснати се сърдят и не звънят 2 часа.
    func missCall(_ id: String) {
        guard let k = buddyKind(id) else { return }
        let d = UserDefaults.standard
        let n = missedCount(id) + 1
        d.set(n, forKey: "buddyMissed_\(id)")
        nextVisitAsk = time + Double.random(in: 8 * 60...14 * 60)
        changeFriendship(id, -2 * min(n, 5))
        if hideAll { missedLog = missedLog + [id] }
        if n >= 3 {
            d.set(Date().addingTimeInterval(2 * 3600), forKey: "buddyOffended_\(id)")
            if joinedBuddies.contains(id) { d.set(Date().addingTimeInterval(2 * 3600), forKey: "buddyAway_\(id)") }
        }
        if !hideAll && !pet.asleep {
            say(n >= 3 ? "\(buddyName(k)) звъня \(n) пъти и вече ни се сърди…" : "Пропуснато обаждане от \(buddyName(k)).", seconds: 3)
        }
    }

    /// Като се покаже пак: кой е звънял, докато го нямаше.
    func reportMissedCalls() {
        let log = missedLog
        guard !log.isEmpty else { return }
        missedLog = []
        var names: [String] = []
        var angry: [String] = []
        for id in log {
            guard let k = buddyKind(id) else { continue }
            let n = buddyName(k)
            if !names.contains(n) { names.append(n) }
            if buddyOffended(id) && !angry.contains(n) { angry.append(n) }
        }
        guard !names.isEmpty else { return }
        var text = "Докато ме нямаше, звъняха: \(names.joined(separator: ", "))."
        if !angry.isEmpty { text += " \(angry.joined(separator: ", ")) вече ни се сърди. Звънни от телефона!" }
        say(text, seconds: 5)
    }

    /// След пристигане: сърди се, ако не си вдигал, и понякога носи подарък.
    func afterArrival(_ b: Buddy, giftChance: Int) {
        let id = b.kind.id
        let complain = UserDefaults.standard.integer(forKey: "buddyComplain_\(id)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self, weak b] in
            guard let self, let b, !b.leaving else { return }
            if complain > 0 {
                UserDefaults.standard.removeObject(forKey: "buddyComplain_\(id)")
                self.buddySay(b, complain >= 3 ? "Звънях ти \(complain) пъти! Защо не вдигаш?!" : "Звънях ти, ама не вдигна…", 3.5)
                if complain >= 3 { b.view.face = .angry }
                if !self.pet.asleep { self.pendingReply = ("Извинявай! Бях много зает.", self.time + 3.5, false) }
                return
            }
            if Int.random(in: 0..<10) < giftChance { self.bringGift(b) }
        }
    }

    // --- идват по работа: пощальонът носи пощата, градинарката полива срещу монети ---

    /// Отива пеша до x; връща true, щом стигне.
    private func walkBuddy(_ b: Buddy, toX gx: CGFloat, _ step: Double, vf: NSRect) -> Bool {
        var o = b.panel.frame.origin
        o.y = vf.minY - (BuddyView.size.height - b.view.feetY)
        let dx = gx - buddyScreenBox(b).midX
        b.view.walking = abs(dx) > 4
        if b.view.walking {
            b.view.facingLeft = dx < 0
            o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(150 * step))
        }
        b.panel.setFrameOrigin(o)
        return !b.view.walking
    }

    func updateService(_ b: Buddy, _ step: Double, pr: NSRect, vf: NSRect) {
        let talking = b.view.text != nil && time < b.view.textUntil
        if b.serviceDone {
            if talking { b.view.walking = false; return }
            // свърши: гостът си тръгва, а живеещият тук продължава по своите неща
            b.service = nil
            b.serviceDone = false
            if b.guest { b.leaving = true }
            return
        }
        if talking { b.view.walking = false; return }
        switch b.service {
        case "mail":
            let side: CGFloat = buddyScreenBox(b).midX < pr.midX ? -1 : 1
            if walkBuddy(b, toX: pr.midX + side * (pr.width / 2 + buddyScreenBox(b).width / 2 + 10), step, vf: vf) {
                b.serviceDone = true
                b.view.facingLeft = side > 0
                buddySay(b, ["Писмо за \(pet.name)! Подпиши тук.", "Поща! Имаш писмо от клиент!", "Препоръчано писмо!"].randomElement()!, 3)
                deliverMail()
            }
        case "garden":
            guard let pp = plantPanel else { b.serviceDone = true; return }
            if walkBuddy(b, toX: pp.frame.midX + 40, step, vf: vf) {
                b.serviceDone = true
                waterPlantNow()
                addCompost(1)
                let price = 8
                buddySay(b, "Полях \(plantStage >= 8 && plantStage < 15 ? "храста" : plantDefinite(plantStage)) и сложих тор! Струва \(price) монети.", 3.5)
                if pet.coins >= price {
                    pet.coins -= price
                    pendingReply = ("Ето ти \(price) монети. Благодаря, \(buddyName(b.kind))!", time + 3.5, false)
                } else {
                    pendingReply = ("Ох, нямам монети… ще ти дължа!", time + 3.5, false)
                    changeFriendship(b.kind.id, -3)
                }
            }
        default:
            b.service = nil
        }
    }

    /// Вика някого по работа: ако е тук, отива; ако не е, идва от ръба (без да пита и без да се брои за гостуване).
    func callService(_ id: String, _ what: String) {
        if let b = buddy(id) {
            guard !buddyAsleep(b), !b.leaving, b.service == nil else { return }
            b.service = what
            b.serviceDone = false
            b.working = false
            return
        }
        guard let k = buddyKind(id), window.isVisible else { return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let left = Bool.random()
        let b = Buddy(kind: k, guest: true, origin: NSPoint(x: left ? vf.minX - BuddyView.size.width : vf.maxX, y: vf.minY), game: self)
        b.service = what
        b.visitUntil = time + 10 * 60
        buddies.append(b)
        sfx("Glass")
    }

    /// Пощата идва само с пощальона.
    func requestMail() {
        guard !mailPending else { return }
        mailPending = true
        mailRequestedAt = time
        callService("post", "mail")
    }

    func deliverMail() {
        guard mailPending else { return }
        mailPending = false
        sendLetter()
    }

    func updateServices() {
        // пощальонът не дойде (скрит, заспал…): писмото все пак пристига
        if mailPending && time - mailRequestedAt > 150 { deliverMail() }
        // градинарката минава понякога, ако цветето е жадно (и не живее при вас)
        if plantStage > 0 && plantWater < 45 && time > nextGardenerVisit && !pet.asleep && hidePhase == .off && !hideAll
            && !(joinedBuddies.contains("garden") && buddy("garden") != nil) {
            nextGardenerVisit = time + Double.random(in: 90 * 60...150 * 60)
            callService("garden", "garden")
            say("Идва градинарката да полее цветето!", seconds: 2.5)
        }
    }

    /// Художничката рисува стена, зад която Пиксчо да отиде до тоалетна.
    func artistBuildToiletWall() {
        guard let a = buddy("artist"), !buddyAsleep(a), !a.leaving, a.service == nil, artistQueue.isEmpty else { return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        var x = pr.midX + (pr.midX < vf.midX ? 1 : -1) * (pr.width / 2 + 70)
        x = min(max(x, vf.minX + 60), vf.maxX - 60)
        let x0 = Int(floor(x / drawCell)), row0 = Int(floor(vf.minY / drawCell))
        for r in 0..<7 {
            for c in 0..<2 { artistQueue.append((cellKey(x0 + c, row0 + r), a.kind.color)) }
        }
        artistWhat = "стена за тоалетната"
        artistTargetX = x
        a.wanderX = x
        buddySay(a, "Чакай! Ще ти нарисувам стена за тоалетната!", 3)
    }

    // --- подаръци ---

    func dropGiftFood(near b: Buddy, count: Int) {
        let box = buddyScreenBox(b)
        for i in 0..<count {
            let f = FoodPixel(color: foodColors.randomElement()!, at: NSPoint(x: box.midX - 20 + CGFloat(i) * 16, y: box.maxY + 10), game: self)
            f.falls = true
            foods.append(f)
        }
    }

    /// Приятелят носи подарък: нещо според професията или монети, пиксели, рядко златен пиксел.
    func bringGift(_ b: Buddy) {
        let id = b.kind.id
        sfx("Hero", every: 5)
        if Int.random(in: 0..<12) == 0 {
            // истински златен пиксел: пада на пода и Пиксчо отива да го изяде
            let box = buddyScreenBox(b)
            let f = FoodPixel(color: 0xffc300, at: NSPoint(x: box.midX - 15, y: box.maxY + 10), game: self)
            f.golden = true
            f.falls = true
            foods.append(f)
            buddySay(b, "Нося ти ЗЛАТЕН ПИКСЕЛ! Изяж го!", 3.5)
            pendingReply = ("Злааато! Благодаря!", time + 3.5, false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self, weak f] in
                guard let self, let f, self.foods.contains(where: { $0 === f }), f.onFloor, self.snackFood == nil, !self.busyMoving,
                      !self.pet.asleep, !self.pet.working else { return }
                self.snackFood = f
            }
            return
        }
        if Bool.random() {
            switch id {
            case "photo":
                takePhoto()
                buddySay(b, "Подарък: снимка за албума!", 3.5)
            case "music", "dancer":
                pet.fun = (pet.fun + 20).clamped()
                buddySay(b, id == "music" ? "Подарък: написах ти песен! Ла-ла-лааа!" : "Подарък: научих те на нов танц!", 3.5)
                start(.wave, length: 3)
            case "chef":
                dropGiftFood(near: b, count: 4)
                buddySay(b, "Донесох ти кексчета от пиксели!", 3.5)
            case "artist":
                paintPlatform(b)
            case "garden":
                if plantStage == 0 { plantStage = 1 } else { addCompost(2) }
                buddySay(b, "Подарък: торба тор за цветето!", 3.5)
            case "science":
                addXP(30)
                buddySay(b, "Подарък: книга с опити! +30 опит", 3.5)
            default:
                let c = Int.random(in: 10...25)
                earnCoins(c)
                buddySay(b, "Нося ти подарък: \(c) монети!", 3.5)
            }
        } else if Bool.random() {
            let c = Int.random(in: 10...25)
            earnCoins(c)
            buddySay(b, "Нося ти подарък: \(c) монети!", 3.5)
        } else {
            dropGiftFood(near: b, count: 3)
            buddySay(b, "Донесох ти вкусни пиксели!", 3.5)
        }
        if !pet.asleep && hidePhase == .off {
            pendingReply = (["Подарък?! Благодаря!", "Ооо, не трябваше!", "Ти си най-добрият приятел!"].randomElement()!, time + 3.8, false)
        }
        changeFriendship(id, 3)
    }

    func visitsNeeded(_ id: String) -> Int {
        let key = "buddyNeed_\(id)"
        var n = UserDefaults.standard.integer(forKey: key)
        if n == 0 { n = Int.random(in: 2...3); UserDefaults.standard.set(n, forKey: key) }
        return n
    }

    func buddyIsAway(_ id: String) -> Bool {
        (UserDefaults.standard.object(forKey: "buddyAway_\(id)") as? Date ?? .distantPast) > Date()
    }

    /// На кого може да звънне: приятелите, които са си вкъщи, и тези, които вече са идвали.
    func callableBuddies() -> [BuddyKind] {
        buddyKinds.filter { k in
            if buddy(k.id) != nil { return false }
            if joinedBuddies.contains(k.id) { return buddyIsAway(k.id) }
            return UserDefaults.standard.integer(forKey: "buddyVisits_\(k.id)") > 0
        }
    }

    @objc func callBuddyMenu(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? String { callBuddy(id) }
    }

    /// От ретро менюто: показва списък и ти избираш на кого да звънне.
    @objc func callFriendFromRetro() {
        guard checkAwake() else { return }
        let list = callableBuddies()
        if list.isEmpty { say("Нямам на кого да звънна… още никой не ни е идвал на гости.", seconds: 3); return }
        let menu = NSMenu()
        let head = NSMenuItem(title: "На кого да звънна?", action: nil, keyEquivalent: "")
        head.isEnabled = false
        menu.addItem(head)
        for k in list {
            let missed = missedCount(k.id)
            let it = NSMenuItem(title: "\(buddyName(k)) (\(k.job)) · ♥ \(buddyFriendship(k.id))%" + (joinedBuddies.contains(k.id) ? " · вкъщи" : "")
                                    + (missed > 0 ? " · пропуснати: \(missed)" : "") + (buddyOffended(k.id) ? " · сърди се" : ""),
                                action: #selector(callBuddyMenu(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = k.id
            menu.addItem(it)
        }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    /// Звъни по телефона; приятелят идва след малко.
    func callBuddy(_ id: String) {
        guard let k = buddyKind(id), buddy(id) == nil, !pet.asleep, pendingCall == nil else { return }
        phoneUntil = time + 4
        sfx("Tink")
        say(["Ало, \(buddyName(k))? Ела у нас!", "Ало? \(buddyName(k))! Скучно ми е, идвай!", "Ринг-ринг… \(buddyName(k)), ела!"]
            .randomElement()!, seconds: 3.5)
        pendingCall = (id, time + Double.random(in: 6...10))
        // връща обаждането: сдобряват се, но ще си каже
        let missed = missedCount(id)
        if missed > 0 || buddyOffended(id) {
            UserDefaults.standard.set(max(missed, 1), forKey: "buddyComplain_\(id)")
            UserDefaults.standard.set(0, forKey: "buddyMissed_\(id)")
            UserDefaults.standard.removeObject(forKey: "buddyOffended_\(id)")
            changeFriendship(id, 5)
        }
    }

    /// Понякога сам звъни на някого, когато му е скучно.
    func maybeCallSomeone() {
        guard time > nextSelfCall, pet.fun < 50, !pet.asleep, !pet.working, hidePhase == .off, window.isVisible,
              questionPanel == nil, pendingCall == nil else { return }
        nextSelfCall = time + Double.random(in: 30 * 60...50 * 60)
        if let k = callableBuddies().randomElement() { callBuddy(k.id) }
    }

    // --- професиите ---

    func startBuddyWork(_ b: Buddy) {
        guard !buddyAsleep(b), !b.guest else { return }
        b.working = true
        b.workStart = time
        b.workSeconds = 0
        let starts: [String: String] = ["photo": "Вадя фотоапарата!", "music": "Настройвам китарата!", "chef": "Пристягам престилката!",
                                        "gamer": "Пускам стрийма!", "artist": "Вадя четките!", "garden": "Вадя лейката!",
                                        "post": "Отварям чантата с писма!", "science": "Слагам очилата!", "dancer": "Загрявам!",
                                        "detective": "Вадя лупата!"]
        buddySay(b, starts[b.kind.id] ?? "Почвам работа!", 2.5)
        // художничката почва да рисува веднага
        if b.kind.id == "artist" { b.workSeconds = 5.5 * 60 }
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
                // от време на време наистина снима Пиксчо
                if Int.random(in: 0..<12) == 0 { takePhoto() }
            }
            let lens = pet.has("lens")
            if b.workSeconds >= (lens ? 10 : 15) * 60 {
                b.workSeconds = 0
                earnCoins(lens ? 25 : 15)
                takePhoto()
                buddySay(b, "Готова фотосесия! +\(lens ? 25 : 15) монети", 3.5)
            }
        case "music":
            // понякога отива да посвири на цветето и то танцува
            if let pp = plantPanel, plantStage > 0 {
                if !b.playPlant && Int.random(in: 0..<(30 * 240)) == 0 {
                    b.playPlant = true
                    b.wanderX = pp.frame.midX + 80
                    b.nextWander = time + 40
                    buddySay(b, "Ще посвиря на цветето!", 2.5)
                } else if b.playPlant && abs(buddyScreenBox(b).midX - pp.frame.midX) < 130 {
                    b.playPlant = false
                    plantDanceUntil = time + 15
                    buddySay(b, "♪ Песен за цветето! ♪", 3)
                    if !pet.asleep { pendingReply = ("Виж! Цветето танцува!", time + 3, false) }
                }
            }
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
            // стриймва: кани някого да играят заедно, чатът пита Пиксчо, радва се на рекорди
            if time > b.nextGamerThing && dialog.isEmpty && hidePhase == .off {
                b.nextGamerThing = time + Double.random(in: 150...280)
                let free = buddies.filter { $0 !== b && !$0.leaving && !buddyAsleep($0) && !$0.working && $0.service == nil }
                let r = Int.random(in: 0..<4)
                if r == 0, let o = free.randomElement() {
                    startDialog([(b.kind.id, "\(buddyName(o.kind)), ела да играем заедно в стрийма!"),
                                 (o.kind.id, "Идвам! Дай ми другия джойстик!"),
                                 (b.kind.id, ["Чатът полудя! Всички ни гледат!", "Двама срещу шефа!", "Ти пази отляво!"].randomElement()!),
                                 (o.kind.id, ["GG! Бяхме страхотни!", "Ох, пак ме убиха!", "Още една игра!"].randomElement()!)])
                    o.view.face = .happy
                } else if r == 1 && !pet.asleep && !pet.working {
                    startDialog([(b.kind.id, "\(pet.name), чатът пита какво ядеш днес!"),
                                 ("pet", ["Пиксели, какво друго!", "Жълти пиксели!", "Тайна!"].randomElement()!),
                                 (b.kind.id, "Чатът пише: „ИСКАМЕ ОЩЕ \(pet.name.uppercased())!“"),
                                 ("pet", "Хаха, здравейте, чат!")])
                } else if r == 2 && ratIsOut {
                    buddySay(b, "\(ratLabel.capitalized) влезе в кадър! Чатът го обожава!", 3)
                    ratSay("Цик! (маха на чата)", 2)
                } else {
                    buddySay(b, ["Нов рекорд!", "Абонирайте се!", "Сто зрители!", "Шефът на нивото! Помощ!", "Кой ще ме победи?"].randomElement()!, 3)
                }
            }
            if b.workSeconds >= 15 * 60 {
                b.workSeconds = 0
                earnCoins(12)
                buddySay(b, "Стриймът свърши! +12 монети", 3.5)
            }
        case "artist":
            // докато работи, рисува непрекъснато; понякога изтрива някоя стара рисунка
            if artistQueue.isEmpty && time > b.nextPaint {
                b.nextPaint = time + Double.random(in: 12...35)
                if drawCells.count > 30 && Int.random(in: 0..<4) == 0 { eraseSomeDrawing(b) } else { paintPlatform(b) }
            }
        case "garden":
            if b.workSeconds >= 8 * 60 {
                b.workSeconds = 0
                if plantStage == 0 {
                    plantStage = 1
                    buddySay(b, "Посадих ти семенце! Хвърляй развалените пиксели в кошчето, за да расте.", 4)
                } else {
                    waterPlantNow()
                    addCompost(1)
                    buddySay(b, "Полях \(plantStage >= 8 && plantStage < 15 ? "храста" : plantDefinite(plantStage)) и сложих тор!", 3)
                }
            }
        case "post":
            if b.workSeconds >= 12 * 60 {
                b.workSeconds = 0
                earnCoins(12)
                buddySay(b, "Писмо с монети за теб! +12", 3)
            }
        case "science":
            if b.workSeconds >= 12 * 60 {
                b.workSeconds = 0
                addXP(25)
                sfx("Pop")
                buddySay(b, "Експериментът успя! +25 опит за \(pet.name)!", 3)
            }
        case "dancer":
            if time > b.nextDance && !pet.asleep && !pet.working && !busyMoving && action == .none {
                b.nextDance = time + Double.random(in: 120...200)
                start(.wave, length: 3)
                pet.fun = (pet.fun + 4).clamped()
                say(["Танцувам с теб!", "Завърти ме!", "Оп-па!"].randomElement()!, seconds: 2.5)
            }
            if b.workSeconds >= 15 * 60 {
                b.workSeconds = 0
                earnCoins(10)
                buddySay(b, "Уроците по танци свършиха! +10 монети", 3.5)
            }
        case "detective":
            if b.workSeconds >= 10 * 60 {
                b.workSeconds = 0
                if Bool.random() {
                    earnCoins(10)
                    buddySay(b, "Разследването разкри изгубени монети! +10", 3.5)
                } else {
                    dropGiftFood(near: b, count: 2)
                    buddySay(b, "Намерих изгубени пиксели зад кошчето!", 3.5)
                }
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
    /// Художничката рисува из екрана: платформа, стълби, сърце, къща, дърво, слънце, звезда, цвете…
    private func paintPlatform(_ b: Buddy) {
        guard artistQueue.isEmpty else { return }
        let shapes: [(String, [String])] = [
            ("платформа", ["##########"]),
            ("стълби", ["......##", "....##..", "..##....", "##......"]),
            ("сърце", [".RR.RR.", "RRRRRRR", "RRRRRRR", ".RRRRR.", "..RRR..", "...R..."]),
            ("къща", ["...RR...", "..RRRR..", ".RRRRRR.", "RRRRRRRR", ".BBBBBB.", ".BBYYBB.", ".BBYYBB.", ".BBBBBB."]),
            ("дърво", ["..GGG..", ".GGGGG.", "GGGGGGG", ".GGGGG.", "...B...", "...B...", "...B..."]),
            ("слънце", ["Y..Y..Y", ".YYYYY.", "YYYYYYY", ".YYYYY.", "Y..Y..Y"]),
            ("звезда", ["...Y...", "..YYY..", "YYYYYYY", ".YYYYY.", ".YY.YY.", "YY...YY"]),
            ("цвете", [".P.P.", "PPYPP", ".P.P.", "..G..", "G.G..", ".GG.."]),
            ("ракета", ["..R..", ".CCC.", ".CWC.", ".CCC.", "CCCCC", "R.R.R"]),
            ("облак", ["..WWW...", ".WWWWWW.", "WWWWWWWW"]),
        ]
        let pick = shapes.randomElement()!
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let w = CGFloat(pick.1[0].count) * drawCell, h = CGFloat(pick.1.count) * drawCell
        let x = CGFloat.random(in: (vf.minX + 40)...max(vf.minX + 41, vf.maxX - w - 40))
        let top = vf.minY + CGFloat.random(in: (h + 80)...max(h + 81, min(vf.height - 60, 420)))
        let colors: [Character: Int] = ["#": b.kind.color, "R": 0xe63946, "B": 0x8b5a2b, "Y": 0xffd166, "G": 0x52b788,
                                        "P": 0xff8fab, "C": 0x48cae4, "W": 0xffffff]
        let x0 = Int(floor(x / drawCell)), y0 = Int(floor(top / drawCell))
        for (r, line) in pick.1.enumerated() {
            for (c, ch) in line.enumerated() where ch != "." {
                artistQueue.append((cellKey(x0 + c, y0 - r), colors[ch] ?? b.kind.color))
            }
        }
        artistWhat = pick.0
        artistTargetX = x + w / 2
        b.wanderX = x + w / 2
        buddySay(b, "Рисувам \(pick.0)!", 3)
    }

    /// Рисува по едно квадратче, като анимация.
    func updateArtistPainting() {
        guard !artistQueue.isEmpty, time > artistNextCell else { return }
        // рисува на живо: само когато е застанала до рисунката, пиксел по пиксел
        guard let artist = buddy("artist"), !buddyAsleep(artist), !artist.leaving else { return }
        if abs(buddyScreenBox(artist).midX - artistTargetX) > 90 {
            artist.wanderX = artistTargetX
            return
        }
        artist.working = true
        artist.view.flashAt = time
        artistNextCell = time + 0.28
        let (k, c) = artistQueue.removeFirst()
        if c < 0 { drawCells.removeValue(forKey: k) } else { drawCells[k] = c }   // отрицателен цвят: трие
        redrawDrawing()
        if artistQueue.isEmpty {
            saveDrawing()
            drawingChanged()
            if let b = buddy("artist") { buddySay(b, "Готово! \(artistWhat.capitalized)!", 3) }
            if !pet.asleep && hidePhase == .off {
                say(artistWhat == "гумичка" ? "Ей, тя изтри една рисунка!" :
                    artistWhat == "стена за тоалетната" ? "Благодаря! Сега никой да не гледа!" :
                    artistWhat == "платформа" || artistWhat == "стълби" ? "Ооо, ново място за скачане! Благодаря!"
                    : "Каква хубава рисунка!", seconds: 2.5)
            }
        }
    }

    /// Художничката изтрива парче от някоя рисунка (квадратче по квадратче).
    func eraseSomeDrawing(_ b: Buddy) {
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let onScreen = drawCells.keys.filter { k in
            let (cx, cy) = cellFromKey(k)
            let x = (CGFloat(cx) + 0.5) * drawCell, y = (CGFloat(cy) + 0.5) * drawCell
            return vf.contains(NSPoint(x: x, y: y))
        }
        guard let seed = onScreen.randomElement() else { paintPlatform(b); return }
        let (sx, sy) = cellFromKey(seed)
        let near = onScreen.filter { k in let (cx, cy) = cellFromKey(k); return abs(cx - sx) <= 3 && abs(cy - sy) <= 3 }
        for k in near { artistQueue.append((k, -1)) }
        artistWhat = "гумичка"
        artistTargetX = (CGFloat(sx) + 0.5) * drawCell
        b.wanderX = artistTargetX
        buddySay(b, ["Тази рисунка не ми харесва… изтривам!", "Малко гумичка тук…", "Ще направя място за нова рисунка!"].randomElement()!, 3)
    }

    /// Облякъл е нещо ново: приятелите коментират (комплименти или подигравки, ако са сърдити).
    func friendsCommentOutfit(_ itemName: String) {
        let watchers = buddies.filter { !$0.leaving && !buddyAsleep($0) && $0.service == nil }
        guard !watchers.isEmpty, !pet.asleep else { return }
        let thing = itemName.lowercased()
        var lines: [(String, String)] = []
        for b in watchers.shuffled().prefix(2) {
            let fr = buddyFriendship(b.kind.id)
            if fr >= 50 {
                lines.append((b.kind.id, ["Ооо, \(thing)! Много ти отива!", "Изглеждаш страхотно!", "Супер стил, \(pet.name)!",
                                          "Леле, колко си модерен!", "Искам и аз такова!"].randomElement()!))
            } else {
                lines.append((b.kind.id, ["Хаха, какво е това на теб?!", "\(thing.capitalizedFirst)? Сериозно ли?", "Приличаш на плашило! Хаха!",
                                          "Кой те облече така?"].randomElement()!))
            }
        }
        let mocked = lines.contains { $0.1.contains("Хаха") || $0.1.contains("Сериозно") || $0.1.contains("плашило") || $0.1.contains("Кой те") }
        lines.append(("pet", mocked ? "Хмпф! На мен ми харесва!" : "Благодаря! Знам!"))
        if dialog.isEmpty { startDialog(lines) }
    }

    /// Списък: с кого колко е приятел.
    @objc func showFriendships() {
        NSApp.activate(ignoringOtherApps: true)
        let known = buddyKinds.filter { joinedBuddies.contains($0.id) || UserDefaults.standard.integer(forKey: "buddyVisits_\($0.id)") > 0 }
        let lines = known.sorted { buddyFriendship($0.id) > buddyFriendship($1.id) }.map { k -> String in
            let f = buddyFriendship(k.id)
            let hearts = String(repeating: "♥", count: max(0, f / 20)) + String(repeating: "♡", count: 5 - max(0, f / 20))
            let state = joinedBuddies.contains(k.id) ? (buddyIsAway(k.id) ? "живее с нас, сега е вкъщи" : "живее с нас")
                : (buddyMovedAway(k.id) ? "премести се" : "идва на гости")
            return "\(buddyName(k)) (\(k.job)): \(hearts) \(f)% · \(state)"
        }
        let alert = NSAlert()
        alert.messageText = "Приятелства"
        alert.informativeText = lines.isEmpty ? "Още никой не е идвал на гости." : lines.joined(separator: "\n")
        alert.runModal()
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
        }
        item("Прегърни \(pet.name)", 4)
        return menu
    }

    func openBuddyMenu(_ b: Buddy) {
        let id = b.kind.id
        var buttons: [MiniButton] = []
        func add(_ icon: Grid, _ label: String, _ code: Int, _ on: Bool = true) {
            buttons.append(MiniButton(icon: icon, label: label, enabled: on, action: { [weak self] in self?.doBuddyAction(id, code) }))
        }
        if b.guest {
            add(iconHouse, "Покани да остане", 6)
            add(iconHug, "Прегърни \(pet.name)", 4)
        } else {
            add(b.kind.prop, b.working ? "Спри работа" : "Работи (\(b.kind.job))", 1)
            add(b.sleeping ? iconSun : iconMoon, b.sleeping ? "Събуди" : "Приспи", 2)
            add(iconFood, "Нахрани", 3)
            add(iconHug, "Прегърни \(pet.name)", 4)
            add(iconFlag, "Състезание с \(pet.name)", 7)
            add(iconTalk, "Да си поговорят", 9)
            if id == "photo" { add(propCamera, "Покажи снимките", 10) }
            add(iconHouse, "Иди си до вкъщи", 8)
        }
        let box = buddyScreenBox(b)
        showMiniMenu(title: "\(buddyName(b.kind)) · \(b.kind.job) · \(buddyLevel(id)) пикс.",
                     stats: b.guest ? [("Приятелство", Double(buddyFriendship(id)) / 100, 0xff8fab)]
                        : [("Ситост", b.full / 100, 0x52b788), ("Енергия", b.energy / 100, 0x48cae4),
                           ("Приятелство", Double(buddyFriendship(id)) / 100, 0xff8fab)],
                     buttons: buttons, above: NSPoint(x: box.midX, y: box.maxY))
    }

    @objc func buddyMenuAction(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        doBuddyAction(id, sender.tag)
    }

    func doBuddyAction(_ id: String, _ code: Int) {
        guard let b = buddy(id) else { return }
        switch code {
        case 1:
            if b.working { b.working = false; buddySay(b, "Почивка!", 2) }
            else if buddyAsleep(b) { buddySay(b, "Спя…", 1.5) } else { startBuddyWork(b) }
        case 2:
            b.sleeping.toggle()
            if b.sleeping { b.working = false; buddySay(b, "Лека нощ…", 2) } else { b.energy = max(b.energy, 50); buddySay(b, "Добро утро!", 2) }
        case 3:
            if buddyAsleep(b) { buddySay(b, "Спя…", 1.5); return }
            if b.full > 90 { buddySay(b, "Пъл\(b.kind.female ? "на" : "ен") съм!", 2); return }
            b.full = min(100, b.full + 30)
            buddyAte(b)
            buddySay(b, "Ням! Благодаря!", 2)
            sfx("Pop")
        case 4:
            if buddyAsleep(b) { buddySay(b, "Спя…", 1.5); return }
            b.hugGo = true
            buddySay(b, "Идвам да те гушна!", 2)
        case 5:
            askName(id)
        case 6:
            let visits = UserDefaults.standard.integer(forKey: "buddyVisits_\(id)")
            if visits >= visitsNeeded(id) { buddyJoins(b) }
            else { buddySay(b, ["Още е рано… може следващия път!", "Хм, нека дойда още веднъж първо!"].randomElement()!, 3) }
        case 7:
            offerRace(with: b)
        case 8:
            b.leaving = true
            b.working = false
            UserDefaults.standard.set(Date().addingTimeInterval(30 * 60), forKey: "buddyAway_\(id)")
            buddySay(b, "Добре, отивам си до вкъщи. Звънни ми!", 3)
        case 9:
            if dialog.isEmpty && !pet.asleep { buddyConversation(b) }
        case 10:
            buddySay(b, photos.isEmpty ? "Още нямам снимки! Ще снимам." : "Ето моите снимки!", 2.5)
            openAlbum()
        default:
            break
        }
    }

    func buddyJoins(_ b: Buddy) {
        guard b.guest else { return }
        photoMoment("newfriend")
        b.guest = false
        b.leaving = false
        if !joinedBuddies.contains(b.kind.id) { joinedBuddies.append(b.kind.id) }
        confettiStart = time
        start(.love, length: 2.5)
        buddySay(b, "Ураа! Оставам!", 3)
        sfx("Hero")
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
        for b in buddies where !buddyAsleep(b) && buddyScreenBox(b).insetBy(dx: -10, dy: -10).contains(NSPoint(x: f.midX, y: f.midY)) {
            food.remove()
            foods.removeAll { $0 === food }
            b.full = min(100, b.full + 30)
            buddyAte(b)
            buddySay(b, "Ням! Благодаря!", 2)
            sfx("Pop")
            attentionToOthers()
            return true
        }
        return false
    }

    /// Колко е пораснал (с храненето).
    func buddyLevel(_ id: String) -> Int { max(1, UserDefaults.standard.integer(forKey: "buddyLevel_\(id)")) }

    func growBuddy(_ b: Buddy, by n: Int) {
        let id = b.kind.id
        let lvl = buddyLevel(id)
        guard lvl < 250 else { return }
        UserDefaults.standard.set(min(250, lvl + n), forKey: "buddyLevel_\(id)")
        buddySay(b, "Пораснах! Вече съм \(lvl + n) пиксела!", 3)
    }

    /// Яде: на всеки 2 хранения пораства малко.
    func buddyAte(_ b: Buddy) {
        guard !b.guest else { return }
        let id = b.kind.id
        let fed = UserDefaults.standard.integer(forKey: "buddyFed_\(id)") + 1
        UserDefaults.standard.set(fed, forKey: "buddyFed_\(id)")
        growBuddy(b, by: 1)
    }

    func updateBuddyReply() {
        guard let r = pendingBuddyReply, time > r.at else { return }
        pendingBuddyReply = nil
        if let o = buddy(r.id) { buddySay(o, r.text, 3); o.view.face = .happy }
    }

    func updateFriendReply() {
        updateBuddyReply()
        guard let r = pendingReply, time > r.at else { return }
        pendingReply = nil
        if r.angry { start(.angry, length: 2) }
        if hidePhase == .off && seekPhase == .off && !pet.asleep { say(r.text, seconds: 3) }
        buddies.forEach { $0.view.face = .normal }
    }
}
