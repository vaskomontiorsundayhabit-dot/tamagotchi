// Задачи, които Пиксчо върши пеша: носи си монитора, прибира го, слага плъха в клетката,
// ляга да спи, стъпва на нарисуваното. Плюс: недоспиване, имена на любимците и писма с поръчки.

import AppKit

enum Errand: Equatable { case fetchMonitor, storeMonitor, feedRat, cuddleRat, ratToCage, ratOut, sleep, stepOn(NSPoint) }

let petNames = [
    "Бобо", "Чочо", "Пипи", "Фъстък", "Бисер", "Мики", "Зузу", "Тошко", "Кексче", "Пухчо",
    "Рики", "Коко", "Лулу", "Нуни", "Бубу", "Гошо", "Цици", "Мишо", "Пипер", "Сиси",
    "Шушу", "Динко", "Фифи", "Тики", "Мочи", "Боби", "Лъки", "Чипи", "Захарчо", "Кифла",
    "Бонбон", "Пешо", "Ники", "Дъмпи", "Буци", "Тофу", "Мъфин", "Чипс", "Гъмчо", "Пико",
    "Рошко", "Сънчо", "Шоко", "Кокос", "Фифо", "Бамби", "Жужу", "Тото", "Кирчо", "Пуф",
    "Мимо", "Носко", "Опашко", "Зъбчо", "Сирене", "Кюфте", "Бисквит", "Перко",
]

let clientNames = ["Иван от пекарната", "Мария (булката)", "Студио Пиксел", "Гошо Геймъра", "Баба Пена",
                   "Фитнес Титан", "Пицария „Мама Мия“", "Група „Глич“", "Влогърката Ники", "Котката Мурка",
                   "Агенция „Реклама+“", "Чичо Стефан"]

struct Letter {
    let from: String
    let job: String
    let reward: Int
    let minutes: Int
    let arrived: Double
}

// MARK: - Писмо с поръчка

final class EnvelopeView: NSView {
    weak var game: Game?
    static let size = NSSize(width: 58, height: 46)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.openLetter() }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let g = grid([
            "KKKKKKKKKKKK",
            "KWLWWWWWWLWK",
            "KWWLWWWWLWWK",
            "KWWWLWWLWWWK",
            "KWWWWLLWWWWK",
            "KWWWWWWWWWWK",
            "KWWWWWWWWWWK",
            "KKKKKKKKKKKK",
        ])
        drawGrid(g, x: 2, y: 10, s: 4, palette: { c in c == "L" ? NSColor(hex: 0x8d99ae) : game.color(c) })
        // червена точка: ново писмо
        if Int(game.time * 2) % 2 == 0 {
            NSColor(hex: 0xe63946).setFill()
            NSBezierPath(ovalIn: NSRect(x: bounds.width - 16, y: 2, width: 14, height: 14)).fill()
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .heavy),
                                                    .foregroundColor: NSColor.white]
            ("1" as NSString).draw(at: NSPoint(x: bounds.width - 12, y: 3), withAttributes: a)
        }
    }
}

final class LetterView: NSView {
    weak var game: Game?
    var letter: Letter?
    static let size = NSSize(width: 340, height: 200)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    var acceptRect: NSRect { NSRect(x: bounds.midX - 128, y: bounds.height - 44, width: 120, height: 30) }
    var declineRect: NSRect { NSRect(x: bounds.midX + 8, y: bounds.height - 44, width: 120, height: 30) }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if acceptRect.contains(p) { game?.answerLetter(true) }
        else if declineRect.contains(p) { game?.answerLetter(false) }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let l = letter else { return }
        let b = bounds
        NSColor(hex: 0xfff8e7).setFill(); b.fill()
        NSColor(hex: 0x2b2b3a).setFill()
        for r in [NSRect(x: 0, y: 0, width: b.width, height: 3), NSRect(x: 0, y: b.height - 3, width: b.width, height: 3),
                  NSRect(x: 0, y: 0, width: 3, height: b.height), NSRect(x: b.width - 3, y: 0, width: 3, height: b.height)] { r.fill() }
        let head: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 10, weight: .heavy),
                                                   .foregroundColor: NSColor(hex: 0x8d99ae)]
        let body: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold),
                                                   .foregroundColor: NSColor(hex: 0x2b2b3a)]
        ("ПИСМО ОТ: \(l.from.uppercased())" as NSString).draw(at: NSPoint(x: 14, y: 12), withAttributes: head)
        let name = game?.pet.name ?? "Пиксчо"
        let text = "Здравей, \(name)!\nТрябва ми \(l.job). Можеш ли да го монтираш до \(l.minutes) минути?\nПлащам \(l.reward) монети."
        (text as NSString).draw(with: NSRect(x: 14, y: 32, width: b.width - 28, height: 100),
                                options: [.usesLineFragmentOrigin], attributes: body)
        for (r, title, color) in [(acceptRect, "ПРИЕМИ", 0x52b788), (declineRect, "ОТКАЖИ", 0xe63946)] {
            NSColor(hex: color).setFill(); r.fill()
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 12, weight: .heavy),
                                                    .foregroundColor: NSColor.white]
            let ns = title as NSString
            let sz = ns.size(withAttributes: a)
            ns.draw(at: NSPoint(x: r.midX - sz.width / 2, y: r.midY - sz.height / 2), withAttributes: a)
        }
    }
}

// MARK: - Логиката

extension Game {
    // --- задачи ---

    func runErrands(_ list: [Errand]) {
        errands = list
        errandStage = 0
        walkTarget = nil
    }

    func nextErrand() {
        if !errands.isEmpty { errands.removeFirst() }
        errandStage = 0
        walking = false
        if errands.isEmpty { saveWindowPosition() }
    }

    func cancelErrands() {
        errands.removeAll()
        errandStage = 0
        hideCarriedMonitor()
        walking = false
    }

    var goingToWork: Bool { errands.first == .fetchMonitor }

    /// Къде е прозорецът, за да е Пиксчо изцяло зад ръба на екрана.
    func offscreenOrigin(left: Bool) -> NSPoint {
        let pr = petScreenRect()
        let sf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.frame ?? .zero
        let x = left ? sf.minX - view.bodyX1 - 30 : sf.maxX - view.bodyX0 + 30
        return NSPoint(x: x, y: window.frame.minY)
    }

    func nearerEdgeIsLeft() -> Bool {
        let pr = petScreenRect()
        let sf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.frame ?? .zero
        return pr.midX - sf.minX < sf.maxX - pr.midX
    }

    /// Отива така, че краката му да са до точката (отстрани, не върху нея). true, когато стигне.
    func walkTo(feet p: NSPoint, speed: Double, _ step: Double) -> Bool {
        let pr = petScreenRect()
        let side: CGFloat = pr.midX < p.x ? -1 : 1
        let lift = window.frame.height - view.feetY
        let target = NSPoint(x: p.x + side * (pr.width / 2 + 14) - bodyCenterOffset, y: p.y - lift)
        walking = true
        if moveWindow(toward: target, speed: CGFloat(speed * step)) {
            walking = false
            facingLeft = side > 0
            return true
        }
        return false
    }

    func updateErrands(_ step: Double) {
        positionCarriedMonitor()
        guard let e = errands.first else { return }
        if pet.dead || hidePhase != .off { cancelErrands(); return }
        switch e {
        case .fetchMonitor:
            switch errandStage {
            case 0:
                errandHome = window.frame.origin
                errandTarget = offscreenOrigin(left: nearerEdgeIsLeft())
                errandStage = 1
                if bubbleText == nil {
                    say(["Отивам да си донеса монитора!", "Чакай, ей сега идвам с монитора!", "Мониторът е отзад, носим го!"]
                        .randomElement()!, seconds: 2.5)
                }
            case 1:
                walking = true
                if moveWindow(toward: errandTarget, speed: CGFloat(420 * step)) {
                    showCarriedMonitor()
                    errandStage = 2
                    errandStart = time
                }
            case 2:
                walking = false
                if time - errandStart > 0.8 { errandStage = 3 }
            default:
                walking = true
                if moveWindow(toward: errandHome, speed: CGFloat(240 * step)) {
                    hideCarriedMonitor()
                    beginWork()
                    nextErrand()
                }
            }
        case .storeMonitor:
            switch errandStage {
            case 0:
                pet.working = false
                autoWorking = false
                if monitorDetached { reattachMonitor() }
                errandHome = window.frame.origin
                errandTarget = offscreenOrigin(left: nearerEdgeIsLeft())
                showCarriedMonitor()
                errandStage = 1
            case 1:
                walking = true
                if moveWindow(toward: errandTarget, speed: CGFloat(260 * step)) {
                    hideCarriedMonitor()
                    errandStage = 2
                    errandStart = time
                }
            case 2:
                walking = false
                if time - errandStart > 0.6 { errandStage = 3 }
            default:
                walking = true
                if moveWindow(toward: errandHome, speed: CGFloat(420 * step)) { nextErrand() }
            }
        case .feedRat, .cuddleRat, .ratToCage, .ratOut:
            updateRatErrand(e, step)
        case .sleep:
            fallAsleep()
            nextErrand()
        case .stepOn(let spot):
            if errandStage == 0 {
                jump(toFeet: spot)
                errandStage = 1
            } else if !jumping {
                say(["Стъпих! Държи!", "Ехее, оттук се вижда всичко!", "Здрава платформа! Благодаря!"].randomElement()!, seconds: 2.5)
                start(.love, length: 1.5)
                nextErrand()
            }
        }
    }

    // --- мониторът в ръцете му ---

    func showCarriedMonitor() {
        guard carriedMonitorPanel == nil else { return }
        let sp = buildSprite(level: bodyCells, face: .focus, pose: .type, frame: 0, working: true, variant: bodyVariant,
                             monitors: monitorCount, monitorLevel: pet.monitorLevel)
        let size = NSSize(width: CGFloat(sp.monW) * PetView.scale, height: CGFloat(sp.monH) * PetView.scale)
        guard size.width > 0, size.height > 0 else { return }
        let v = MonitorView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        let p = overlayPanel(NSRect(origin: .zero, size: size), key: false)
        p.level = .floating
        p.ignoresMouseEvents = true
        p.contentView = v
        carriedMonitorPanel = p
        positionCarriedMonitor()
        p.orderFrontRegardless()
    }

    func positionCarriedMonitor() {
        guard let p = carriedMonitorPanel else { return }
        let pr = petScreenRect()
        let x = facingLeft ? pr.minX - p.frame.width * 0.55 : pr.maxX - p.frame.width * 0.45
        let y = pr.minY + pr.height * 0.2 + CGFloat(abs(sin(time * 9))) * 3
        p.setFrameOrigin(NSPoint(x: x, y: y))
        p.contentView?.needsDisplay = true
    }

    func hideCarriedMonitor() {
        carriedMonitorPanel?.orderOut(nil)
        carriedMonitorPanel = nil
    }

    // --- работа ---

    func beginWork() {
        guard !pet.asleep, !pet.dead else { return }
        pet.working = true
        walkTarget = nil
        nextWorkLine = time + Double.random(in: 20...50)
        say("Отварям таймлайна…", seconds: 2.5)
        fulfill(.work)
        save()
    }

    /// Спира работа и отнася монитора зад кадър.
    func stopWork() {
        guard pet.working else { return }
        runErrands([.storeMonitor])
        say(["Пауза! Прибирам монитора.", "Изключвам и отнасям монитора.", "Стига за днес… прибирам."].randomElement()!, seconds: 2.5)
        save()
    }

    /// Бутонът за изключване на монитора.
    func monitorPowerPressed() {
        guard pet.working else { return }
        sfx("Tink")
        stopWork()
    }

    // --- сън ---

    func goToSleep() {
        if pet.dead || pet.asleep || errands.contains(.sleep) { return }
        if isDrunk {
            say("Не мога да спя! Изпих \(recentCoffees) кафета! Очите ми са отворени завинаги!", seconds: 3.5)
            return
        }
        let carrying = carriedMonitorPanel != nil
        clearForGame()
        closeQuestion()
        cancelErrands()
        var plan: [Errand] = []
        if pet.working || carrying { plan.append(.storeMonitor) }
        if ratIsOut { plan.append(.ratToCage) }
        plan.append(.sleep)
        runErrands(plan)
        if plan.count > 1 {
            say(plan.first == .storeMonitor ? "Прибирам монитора и лягам…" : "Прибирам \(ratLabel) в клетката и лягам…", seconds: 3)
        }
    }

    func fallAsleep() {
        pet.asleep = true
        pet.working = false
        action = .none
        walking = false
        say("Лека нощ…", seconds: 2)
        save()
    }

    /// Недоспал (червени очи): иска да спи, а ако е много уморен, ляга сам.
    func updateTired(_ idle: Bool) {
        guard pet.tired > 3, !pet.asleep, !pet.dead, window.isVisible, hidePhase == .off, seekPhase == .off, !isDrunk,
              errands.isEmpty, questionPanel == nil, letterPanel == nil, !playingGame, toiletPhase == .off,
              time > nextTiredAsk else { return }
        nextTiredAsk = time + Double.random(in: 6 * 60...10 * 60)
        let h = Int(pet.tired)
        if pet.tired > 6 || pet.energy < 10 {
            say("Не издържам… не съм спал \(h) часа. Лягам си!", seconds: 3.5)
            goToSleep()
            return
        }
        blinkUntil = time + 1.2
        ask(Question(text: "Не съм спал \(h) часа… очите ми горят. Може ли да поспя?", answers: [
            ("ДА", "Благодаря… лека нощ!", .sleep), ("НЕ", "Ама очите ми се затварят…", .angry(8)),
        ]), index: -1)
    }

    // --- имена на любимците ---

    var ratName: String? { UserDefaults.standard.string(forKey: "ratName") }
    var ratLabel: String { ratName ?? "плъхчето" }
    var friendName: String { UserDefaults.standard.string(forKey: "friendName") ?? "Пиксчочка" }

    func updateNames(_ idle: Bool) {
        guard idle, questionPanel == nil, letterPanel == nil, errands.isEmpty, !playingGame, time > nextNameAsk else { return }
        if pet.owned.contains("rat") && ratName == nil { askName("rat") }
        else if pet.owned.contains("friend") && UserDefaults.standard.string(forKey: "friendName") == nil { askName("friend") }
    }

    @objc func renameRat() { askName("rat") }
    @objc func renameFriend() { askName("friend") }

    func askName(_ who: String) {
        nextNameAsk = time + 10 * 60
        pendingNameFor = who
        var n = petNames.randomElement()!
        while n == pendingName { n = petNames.randomElement()! }
        pendingName = n
        let what = who == "rat" ? "плъхчето" : "приятелката ми"
        ask(Question(text: "Как да кръстим \(what)? Харесва ли ти „\(n)“?", answers: [
            ("ХАРЕСВА МИ", "„\(n)“! Чудесно име!", .acceptName), ("ДРУГО", "Хм… чакай да помисля.", .nextName),
        ]), index: -1)
    }

    func acceptName() {
        let n = pendingName
        guard !n.isEmpty else { return }
        if pendingNameFor == "rat" {
            UserDefaults.standard.set(n, forKey: "ratName")
            ratSay("Цик! Аз съм \(n)!", 3)
        } else {
            UserDefaults.standard.set(n, forKey: "friendName")
            friendSay("Аз съм \(n)! Харесва ми!", 3)
        }
        start(.love, length: 1.5)
    }

    // --- писма с поръчки ---

    func sendLetter() {
        letter = Letter(from: clientNames.randomElement()!, job: clientJobs.randomElement()!,
                        reward: Int.random(in: 4...15) * 10, minutes: Int.random(in: 45...90), arrived: time)
        let vf = NSScreen.main?.visibleFrame ?? .zero
        let s = EnvelopeView.size
        let p = overlayPanel(NSRect(x: vf.maxX - s.width - 30, y: vf.maxY - s.height - 20, width: s.width, height: s.height), key: false)
        p.level = .floating
        let v = EnvelopeView(frame: NSRect(origin: .zero, size: s))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        envelopePanel = p
        sfx("Glass")
        say(["Писмо! Нова поръчка! Отвори го!", "Имаме поща! Цъкни писмото горе вдясно!", "Клиент ни пише! Виж писмото!"]
            .randomElement()!, seconds: 4)
    }

    func updateLetter() {
        guard let l = letter else { return }
        if let p = envelopePanel {
            let vf = NSScreen.main?.visibleFrame ?? .zero
            let s = EnvelopeView.size
            p.setFrameOrigin(NSPoint(x: vf.maxX - s.width - 30, y: vf.maxY - s.height - 20 + CGFloat(abs(sin(time * 3))) * 6))
            p.contentView?.needsDisplay = true
        }
        if letterPanel == nil && time - l.arrived > 15 * 60 {
            closeLetter()
            letter = nil
            nextOrder = time + Double.random(in: 8 * 60...15 * 60)
            annoy(5, reason: "изпуснахме клиент")
            if !pet.asleep { say("Клиентът писа на друг монтажист… Изпуснахме поръчката.", seconds: 3.5) }
        }
    }

    func openLetter() {
        guard let l = letter else { return }
        envelopePanel?.orderOut(nil)
        envelopePanel = nil
        let s = LetterView.size
        let vf = NSScreen.main?.visibleFrame ?? .zero
        let v = LetterView(frame: NSRect(origin: .zero, size: s))
        v.game = self
        v.letter = l
        let p = overlayPanel(NSRect(x: vf.maxX - s.width - 30, y: vf.maxY - s.height - 20, width: s.width, height: s.height), key: false)
        p.level = .floating
        p.contentView = v
        p.orderFrontRegardless()
        letterPanel = p
        sfx("Pop")
    }

    func answerLetter(_ accept: Bool) {
        guard let l = letter else { return }
        closeLetter()
        letter = nil
        if accept {
            pet.orderText = l.job
            pet.orderDeadline = Date().addingTimeInterval(Double(l.minutes) * 60)
            pet.orderReward = l.reward
            sfx("Glass")
            say("Приемам „\(l.job)“! Ще го направя навреме!", seconds: 3)
            if !pet.working && !pet.asleep && !pet.dead && errands.isEmpty && hidePhase == .off && !isSick && pet.energy >= 15 {
                toggleWork()
            }
            save()
        } else {
            nextOrder = time + Double.random(in: 8 * 60...15 * 60)
            if !pet.asleep { say("Добре, ще чакаме по-добра поръчка.", seconds: 2.5) }
        }
    }

    func closeLetter() {
        envelopePanel?.orderOut(nil)
        envelopePanel = nil
        letterPanel?.orderOut(nil)
        letterPanel = nil
    }
}

// MARK: - Какво се е променило, докато е спал

struct SleepSnapshot {
    let origin: NSPoint
    let cells: Int
    let cellSum: Int
    let worn: [String]
    let foods: Int
    let coins: Int
    let owned: Int
    let cageX: CGFloat
    let ratInCage: Bool
    let messes: Int
    let hasOrder: Bool
}

let wakeMovedLines = ["Ей… това не е мястото, където заспах!", "Кой ме премести?! Лунатик ли съм?",
                      "Хм… заспах там, събудих се тук. Мистерия!", "Летял ли съм насън?!", "Къде съм? Това не е моето ъгълче!"]
let wakeDrawnLines = ["Кой е рисувал, докато спях?!", "Ооо, нови пиксели! Откъде се взеха?", "Някой ми е пипал платформите…",
                      "Чакай, тук нямаше нищо нарисувано!", "Пиксели?! Духове ли рисуват нощем?"]
let wakeErasedLines = ["Къде ми изчезнаха платформите?!", "Някой е трил, докато спя! Видях го насън!",
                       "Рисунките… ги няма! Сънувал ли съм ги?"]
let wakeWornLines = ["Чакай… с какво съм облечен?!", "Кой ме преоблече, докато спях?!", "Това не е моята шапка… или е?",
                     "Огледало! Трябва ми огледало!"]
let wakeFoodLines = ["Пиксели! Цял бюфет, докато съм спал!", "Откъде толкова храна? Някой ме обича!",
                     "Сънувах пиксели и те… са истински!"]
let wakeCoinLines = ["Монетите ми са други… кой е пазарувал?!", "Броих монетите преди да заспя… не излиза сметката!",
                     "Някой е бъркал в касичката ми!"]
let wakeNewLines = ["Ново нещо! Кога се появи това?!", "Подарък ли е? Докато спях?!", "Ей, тук има нещо ново!"]
let wakeCageLines = ["Клетката е на друго място… кой я е бутал?", "Хм, клетката сама ли се разхожда?"]
let wakeRatLines = ["Как е излязъл плъхът от клетката?!", "Плъхът е в клетката? Аз ли го прибрах насън?"]
let wakeMessLines = ["Някой е чистил, докато спях! Благодаря… май.", "Къде отидоха… хм, неща?"]
let wakeOrderLines = ["Имам поръчка?! Кога съм я приел?", "Поръчката я няма… какво пропуснах?"]
let wakeManyLines = ["Какво е станало тук, докато спях?!", "Всичко е различно! Колко съм спал?!", "Сънувам ли още? Нищо не е същото!",
                     "Някой е купонясвал без мен!"]

extension Game {
    func takeSleepSnapshot() {
        sleepSnapshot = SleepSnapshot(origin: window.frame.origin, cells: drawCells.count,
                                      cellSum: drawCells.keys.reduce(0, &+), worn: pet.worn, foods: foods.count,
                                      coins: pet.coins, owned: pet.owned.count, cageX: cagePanel?.frame.minX ?? 0,
                                      ratInCage: ratInCage, messes: messes.count, hasOrder: pet.orderText != nil)
    }

    /// Буди се и се чуди какво се е променило.
    func noticeChangesAfterSleep() {
        guard let s = sleepSnapshot, !pet.dead else { return }
        sleepSnapshot = nil
        var found: [[String]] = []
        let o = window.frame.origin
        if hypot(o.x - s.origin.x, o.y - s.origin.y) > 40 { found.append(wakeMovedLines) }
        if drawCells.count > s.cells + 3 { found.append(wakeDrawnLines) }
        else if drawCells.count + 3 < s.cells { found.append(wakeErasedLines) }
        else if drawCells.keys.reduce(0, &+) != s.cellSum && drawCells.count != s.cells { found.append(wakeDrawnLines) }
        if Set(pet.worn) != Set(s.worn) { found.append(wakeWornLines) }
        if pet.owned.count > s.owned { found.append(wakeNewLines) }
        if pet.coins != s.coins && abs(pet.coins - s.coins) > 5 { found.append(wakeCoinLines) }
        if foods.count > s.foods + 1 { found.append(wakeFoodLines) }
        if let c = cagePanel, abs(c.frame.minX - s.cageX) > 30 { found.append(wakeCageLines) }
        if hasRat && ratInCage != s.ratInCage { found.append(wakeRatLines) }
        if messes.count < s.messes { found.append(wakeMessLines) }
        if (pet.orderText != nil) != s.hasOrder { found.append(wakeOrderLines) }
        guard let first = found.first else { return }
        // учуден е: оглежда се
        followUntil = time + 6
        blinkUntil = time + 0.6
        glitchUntil = time + 0.3
        sfx("Pop")
        let line = found.count >= 3 ? wakeManyLines.randomElement()! + " " + first.randomElement()!
            : first.randomElement()!
        say(line, seconds: 4)
        if found.count >= 2 {
            let second = found[1].randomElement()!
            pendingWakeLine = (second, time + 4.5)
        }
    }

    func updateWakeLines() {
        guard let w = pendingWakeLine, time > w.at else { return }
        pendingWakeLine = nil
        if !pet.asleep { say(w.text, seconds: 3.5) }
    }
}
