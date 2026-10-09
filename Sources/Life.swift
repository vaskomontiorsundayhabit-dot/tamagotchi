// Желания, тоалетна и приказки: неща, които Пиксчо прави сам.

import AppKit

enum Want: Equatable {
    case color(Int), play, coffee, pet, platform, work, draw(String), buy(String)
}

let colorNames: [Int: String] = [
    0xff595e: "червен", 0xffca3a: "жълт", 0x8ac926: "зелен", 0x1982c4: "син",
    0x6a4c93: "лилав", 0xff924c: "оранжев", 0x52d1dc: "тюркоазен", 0xf15bb5: "розов",
]

func wantText(_ w: Want) -> String {
    switch w {
    case .color(let c): return "\(colorNames[c] ?? "цветен") пиксел"
    case .play: return "да поиграем"
    case .coffee: return "кафе от магазина"
    case .pet: return "да ме погалиш"
    case .platform: return "да ми нарисуваш нещо, на което да стъпя"
    case .work: return "да монтирам"
    case .draw(let what): return "да ми нарисуваш \(what)"
    case .buy(let id): return "да ми купиш \((shopItems.first { $0.id == id }?.name ?? id).lowercased())"
    }
}

let idleLines = [
    "Знаеш ли, че съм направен изцяло от пиксели?",
    "Днес се чувствам особено квадратен.",
    "Ако бях по-голям, щях да съм 4K.",
    "Мисля си да стана режисьор.",
    "Някой виждал ли е моя изгубен пиксел?",
    "Скучно ми е… ама приятно скучно.",
    "Тук горе гледката е хубава.",
    "Обичам да те гледам как работиш.",
    "Ти също ли имаш крачета?",
    "Колко ли пиксела има на този екран?",
    "Сънувах, че съм GIF.",
    "Курсорът ти е много бърз днес.",
    "Не съм дебел, просто съм с висока резолюция.",
    "Мисля, че ще вали пиксели.",
    "Аз съм най-сладкият бъг в системата.",
    "Някога ще имам собствен канал.",
    "Чу ли това? Вентилаторът пак пее.",
    "Хайде да си направим почивка.",
    "Обичам миризмата на нов таймлайн сутрин.",
    "Може ли да ми купиш нещо от магазина?",
    "Един ден ще съм 100 пиксела!",
    "Тоя прозорец ме гледа странно.",
    "Скачам ли, или ми се струва?",
    "Ако ме пипнеш три пъти, ще глична.",
    "Колко е часът? Аха, време за пиксели.",
    "Вече съм ниво… чакай да погледна.",
    "Пиксел на ден държи лекаря далеч.",
    "Обичам кафе. И пиксели. И теб.",
    "Може ли да нарисуваш стълбичка?",
    "Шшт, мисля по сценарий.",
]

let clipDislikeLines = [
    "Как така?! Монтирах го цяла нощ!",
    "Ти нищо не разбираш от изкуство!",
    "Добре… следващия път ще е по-добре. ГРРР.",
    "Не ти харесва?! Отивам да плача в таймлайна.",
]
let clipLikeLines = ["Знаех си!", "Ти си най-добрият зрител!", "Ще го кача навсякъде!", "Ура! Още ще монтирам!"]

enum ToiletPhase { case off, going, doing, returning }

// MARK: - Акото и локвичката

final class MessPixel: NSObject {
    let poop: Bool
    let panel: NSPanel
    let view: MessView
    let created: Double

    init(poop: Bool, at origin: NSPoint, game: Game) {
        self.poop = poop
        created = game.time
        let size = poop ? NSSize(width: 30, height: 26) : NSSize(width: 44, height: 12)
        panel = overlayPanel(NSRect(origin: origin, size: size), key: false)
        view = MessView(frame: NSRect(origin: .zero, size: size))
        super.init()
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
        panel.ignoresMouseEvents = !poop
        view.mess = self
        view.game = game
        panel.contentView = view
        panel.orderFrontRegardless()
    }

    func remove() {
        panel.orderOut(nil)
        panel.close()
    }
}

final class MessView: NSView {
    weak var mess: MessPixel?
    weak var game: Game?

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { if let mess { game?.cleanMess(mess) } }

    override func draw(_ dirtyRect: NSRect) {
        guard let mess, let game else { return }
        if mess.poop {
            let g = grid([
                "...UU...",
                "..UQQU..",
                ".UQQQQU.",
                ".UQWQQU.",
                "UQQQQQQU",
                "UQQQQQWU",
                "UUUUUUUU",
            ])
            drawGrid(g, x: 3, y: 4, s: 3, palette: game.color)
            if Int(game.time * 2) % 2 == 0 {
                NSColor(hex: 0x8d99ae).setFill()
                NSRect(x: 4, y: 0, width: 2, height: 3).fill()
                NSRect(x: 22, y: 1, width: 2, height: 3).fill()
            }
        } else {
            let age = game.time - mess.created
            let alpha = max(0, 0.8 - age / 30)
            NSColor(hex: 0xffe066, alpha: alpha).setFill()
            NSBezierPath(ovalIn: bounds.insetBy(dx: 2, dy: 2)).fill()
        }
    }
}

// MARK: - Логиката

extension Game {
    func updateLife(_ step: Double) {
        let idle = !pet.dead && !pet.asleep && catchPanel == nil && !drawing
        updateWant(idle)
        updateToilet(step, idle: idle)
        updateQuestions(idle && toiletPhase == .off && !jumping)
        updateAutoWork(idle)
        if time - lastEnclosureCheck > 2 {
            lastEnclosureCheck = time
            checkEnclosure()
            if enclosed && time - lastScared > 20 {
                lastScared = time
                annoy(5, reason: "ме затвори")
                glitchUntil = time + 0.6
                start(.angry, length: 1.5)
                say(pick(scaredLines, avoiding: &lastLine), seconds: 3)
            }
        }

        // приказки, когато си стои
        if idle && !pet.working && bubbleText == nil && time > nextIdleLine {
            nextIdleLine = time + Double.random(in: 3 * 60...6 * 60)
            say(pick(idleLines, avoiding: &lastLine), seconds: 4)
        }

        for m in messes { m.view.needsDisplay = true }
        let gone = messes.filter { !$0.poop && time - $0.created > 30 }
        gone.forEach { $0.remove() }
        messes.removeAll { m in gone.contains { $0 === m } }
    }

    // --- желания ---

    func updateWant(_ idle: Bool) {
        if let w = want {
            let minutes = (time - wantSince) / 60
            if time - lastWantNag > 60 {
                lastWantNag = time
                // колкото по-дълго чака, толкова повече се ядосва
                annoy(3 + minutes * 2)
                if minutes > 12 {
                    want = nil
                    nextWant = time + Double.random(in: 8 * 60...15 * 60)
                    annoy(10)
                    start(.angry, length: 2)
                    say("Добре, забрави! Сърдит съм!", seconds: 3)
                    return
                }
                let text = wantText(w)
                if minutes < 2 { say("Още чакам… искам \(text).", seconds: 3.5) }
                else if minutes < 5 { start(.angry, length: 1.5); say("ИСКАМ \(text.uppercased())!", seconds: 3.5) }
                else {
                    start(.angry, length: 2)
                    glitchUntil = time + 0.8
                    say("ЩЕ ГЛИЧНА! \(text.uppercased())!!!", seconds: 3.5)
                }
            }
            return
        }
        guard idle, time > nextWant else { return }
        var options: [Want] = [.play, .coffee, .pet, .platform, .draw(drawRequests.randomElement()!),
                               .draw(drawRequests.randomElement()!)]
        // иска конкретни неща от магазина (които още няма)
        let notOwned = shopItems.filter { $0.kind != .use && !pet.owned.contains($0.id) && $0.price <= max(60, pet.coins + 40) }
        if let item = notOwned.randomElement() { options.append(.buy(item.id)) }
        options.append(.buy(["cake", "coffee", "gold"].randomElement()!))
        // пиксел с цвят иска само когато е гладен
        if foodPixelsOn && pet.fullness < 60 { options += [.color(foodColors.randomElement()!), .color(foodColors.randomElement()!)] }
        if !pet.working && pet.energy > 30 { options.append(.work) }
        let w = options.randomElement()!
        want = w
        wantSince = time
        lastWantNag = time
        say("Искам \(wantText(w))!", seconds: 4)
        if case .color(let c) = w, foodPixelsOn { spawnFood(color: c) }
    }

    func fulfill(_ w: Want) {
        guard want == w else { return }
        want = nil
        nextWant = time + Double.random(in: 8 * 60...15 * 60)
        anger = (anger - 20).clamped()
        earnCoins(10)
        say("Благодаря! +10 монети", seconds: 3)
        start(.love, length: 1.6)
        addXP(10)
    }

    // --- тоалетна ---

    func updateToilet(_ step: Double, idle: Bool) {
        switch toiletPhase {
        case .off:
            guard idle, time > nextToilet, !pet.working, fetchPhase == .off, !rolling, !isDragging,
                  let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
            let x = window.frame.minX
            let r = xRange(vf)
            toiletTarget = x - r.lowerBound > r.upperBound - x ? r.lowerBound + 10 : r.upperBound - 10
            toiletPhase = .going
            toiletReturnX = x
            walkTarget = nil
            say("Трябва ми тоалетна! Веднага!", seconds: 2.5)
        case .going:
            walking = true
            let o = window.frame.origin
            if moveWindow(toward: NSPoint(x: toiletTarget, y: o.y), speed: CGFloat(90 * step)) {
                walking = false
                toiletPhase = .doing
                toiletStart = time
                toiletPoop = Bool.random()
                say("Не гледай!", seconds: 2)
            }
        case .doing:
            if time - toiletStart > 3 {
                nextToilet = time + Double.random(in: 10 * 60...20 * 60)
                let pr = petScreenRect()
                let feet = window.frame.maxY - view.feetY
                if toiletPoop {
                    let x = facingLeft ? pr.maxX - 6 : pr.minX - 24
                    messes.append(MessPixel(poop: true, at: NSPoint(x: x, y: feet), game: self))
                } else {
                    messes.append(MessPixel(poop: false, at: NSPoint(x: pr.midX - 22, y: feet - 4), game: self))
                }
                say(toiletPoop ? "Ох, олекна ми! Почисти, моля." : "Ох, олекна ми!", seconds: 3)
                toiletPhase = .returning
            }
        case .returning:
            walking = true
            let o = window.frame.origin
            if moveWindow(toward: NSPoint(x: toiletReturnX, y: o.y), speed: CGFloat(90 * step)) {
                walking = false
                toiletPhase = .off
                saveWindowPosition()
            }
        }
    }

    func cleanMess(_ m: MessPixel) {
        m.remove()
        messes.removeAll { $0 === m }
        earnCoins(2)
        say("Благодаря, че почисти! +2 монети", seconds: 2.5)
    }
}
