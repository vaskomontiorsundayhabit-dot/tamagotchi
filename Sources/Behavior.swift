// Скокове, страх от затваряне, въпроси, сутрешен поздрав и стрелящи пиксели.

import AppKit

let fallLines = ["Ауч! Внимавай!", "ЕЙ! Изпусна ме!", "Боли ме пикселът!", "Ще ти се сърдя за това!", "Не ме пускай така!"]
let scaredLines = [
    "Пуснете ме! Страх ме е!", "Затворен съм! ПОМОЩ!", "Клаустрофобия! Махни това!",
    "Тук е тъмно и тясно!", "Ще глична от страх!", "Защо ме затвори?!", "Искам навън! ВЕДНАГА!",
]
let drawRequests = ["сърце", "къща", "дърво", "стълбичка", "слънце", "котка", "ракета", "цвете", "кораб", "звезда"]

enum Reaction { case happy, angry(Double), work, shop, clip, play, nothing }

struct Question {
    let text: String
    let answers: [(String, String, Reaction)]   // бутон, отговор на Пиксчо, ефект
}

let questions: [Question] = [
    Question(text: "Обичаш ли ме?", answers: [
        ("ДА", "И аз теб!", .happy), ("НЕ", "Как така?! ГРРР!", .angry(20))]),
    Question(text: "Кое е по-хубаво: кафе или чай?", answers: [
        ("КАФЕ", "Знаех си! Брат!", .happy), ("ЧАЙ", "Чай?! Сериозно ли?", .angry(5))]),
    Question(text: "Да монтирам ли още едно видео?", answers: [
        ("ДА", "Отварям таймлайна!", .work), ("НЕ", "Добре, почивка!", .nothing)]),
    Question(text: "Харесва ли ти как изглеждам днес?", answers: [
        ("ДА", "Знам, знам, красавец съм.", .happy), ("НЕ", "Ти също не си много пикселен!", .angry(15))]),
    Question(text: "Кой е най-сладкият пиксел?", answers: [
        ("ТИ", "Аз! Аз съм!", .happy), ("АЗ", "Хм. Не съм съгласен.", .angry(5))]),
    Question(text: "Колко голям съм според теб?", answers: [
        ("МАЛЪК", "Ще порасна и ще видиш!", .angry(8)), ("ОГРОМЕН", "Ехее, наистина ли?!", .happy)]),
    Question(text: "Ще ми купиш ли нещо от магазина?", answers: [
        ("ДА", "Урааа! Отварям магазина!", .shop), ("НЕ", "Стиснат си…", .angry(10))]),
    Question(text: "Искаш ли да видиш нов клип?", answers: [
        ("ДА", "Гледай!", .clip), ("НЕ", "Добре, сам ще си го гледам.", .angry(5))]),
    Question(text: "Скучно ли ти е?", answers: [
        ("ДА", "Хайде да играем!", .play), ("НЕ", "На мен пък ми е…", .nothing)]),
    Question(text: "Добър монтажист ли съм?", answers: [
        ("ДА", "Знаех си! Най-добрият!", .happy), ("НЕ", "Ще видиш ти!", .angry(20))]),
    Question(text: "Какво да ям днес?", answers: [
        ("ПИКСЕЛИ", "Пак пиксели. Обичам ги!", .happy), ("НИЩО", "Искаш да гладувам?!", .angry(15))]),
    Question(text: "Ще ме гледаш ли, докато работя?", answers: [
        ("ДА", "Тогава ще се постарая!", .happy), ("НЕ", "Никой не ме оценява…", .angry(8))]),
]

// MARK: - Прозорче с въпрос

final class QuestionView: NSView {
    weak var game: Game?
    var question: Question?
    var angry = false

    static let size = NSSize(width: 300, height: 96)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private func buttonRects() -> [NSRect] {
        let n = CGFloat(question?.answers.count ?? 2)
        let w: CGFloat = 96, gap: CGFloat = 10
        let x0 = (bounds.width - (n * w + (n - 1) * gap)) / 2
        return (0..<Int(n)).map { NSRect(x: x0 + CGFloat($0) * (w + gap), y: 54, width: w, height: 28) }
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        for (i, r) in buttonRects().enumerated() where r.contains(p) { game?.answerQuestion(i) }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let q = question else { return }
        let b = bounds
        NSColor(hex: 0x1b1b24, alpha: 0.97).setFill(); b.fill()
        NSColor(hex: angry ? 0xe63946 : 0xffffff).setFill()
        for r in [NSRect(x: 0, y: 0, width: b.width, height: 3), NSRect(x: 0, y: b.height - 3, width: b.width, height: 3),
                  NSRect(x: 0, y: 0, width: 3, height: b.height), NSRect(x: b.width - 3, y: 0, width: 3, height: b.height)] { r.fill() }
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
                                                .foregroundColor: NSColor(hex: angry ? 0xff8fab : 0xffffff)]
        let text = (angry ? "ОТГОВОРИ МИ! " : "") + q.text.uppercased()
        (text as NSString).draw(with: NSRect(x: 12, y: 10, width: b.width - 24, height: 40),
                                options: [.usesLineFragmentOrigin], attributes: a)
        for (i, r) in buttonRects().enumerated() {
            NSColor(hex: i == 0 ? 0x52b788 : (i == 1 ? 0xe63946 : 0x48cae4)).setFill(); r.fill()
            let la: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
                                                     .foregroundColor: NSColor.white]
            let ns = q.answers[i].0 as NSString
            let sz = ns.size(withAttributes: la)
            ns.draw(at: NSPoint(x: r.midX - sz.width / 2, y: r.midY - sz.height / 2), withAttributes: la)
        }
    }
}

// MARK: - Логиката

extension Game {
    func annoy(_ amount: Double, reason: String? = nil) {
        anger = (anger + amount).clamped()
        if let reason { angerReason = reason; angerReasonTime = time }
    }

    /// Какво му е, когато го питаш (клик, докато е сърдит).
    func whatsWrong() -> String {
        if enclosed { return "Затвори ме! Страх ме е!" }
        if let w = want { return "Сърдит съм, защото искам \(wantText(w)) и никой не ми дава!" }
        if questionPanel != nil { return "Не ми отговаряш на въпроса!" }
        if pet.fullness < 25 { return "Гладен съм! Затова съм сърдит!" }
        if pet.energy < 20 { return "Уморен съм и ми се спи!" }
        if let r = angerReason, time - angerReasonTime < 20 * 60 { return "Сърдит съм, защото \(r)!" }
        if pet.fun < 25 { return "Скучно ми е и никой не играе с мен!" }
        return "Просто съм в лошо настроение…"
    }

    // --- затворен в нарисуваното ---

    func drawingChanged() { checkEnclosure() }

    func checkEnclosure() {
        let wasEnclosed = enclosed
        enclosed = isEnclosed()
        if enclosed && !wasEnclosed {
            annoy(15, reason: "ме затвори")
            start(.angry, length: 2)
            glitchUntil = time + 0.8
            say(pick(scaredLines, avoiding: &lastLine), seconds: 3)
            lastScared = time
        } else if !enclosed && wasEnclosed {
            anger = (anger - 10).clamped()
            say("Уф! Свободен съм!", seconds: 2.5)
        }
    }

    /// Flood fill от мястото на Пиксчо: ако не може да излезе на 40 клетки, значи е затворен.
    func isEnclosed() -> Bool {
        guard !drawCells.isEmpty, window.isVisible else { return false }
        let r = petScreenRect().insetBy(dx: 6, dy: 6)
        let cx = Int(floor(r.midX / drawCell)), cy = Int(floor(r.midY / drawCell))
        let radius = 40
        let screens = NSScreen.screens.map { $0.frame }
        func wall(_ x: Int, _ y: Int) -> Bool {
            if drawCells[cellKey(x, y)] != nil { return true }
            let p = NSPoint(x: (CGFloat(x) + 0.5) * drawCell, y: (CGFloat(y) + 0.5) * drawCell)
            return !screens.contains { $0.contains(p) }
        }
        var seen = Set<Int>([cellKey(cx, cy)])
        var queue = [(cx, cy)]
        var head = 0
        while head < queue.count {
            let (x, y) = queue[head]; head += 1
            if abs(x - cx) >= radius || abs(y - cy) >= radius { return false }
            for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let nx = x + dx, ny = y + dy
                let k = cellKey(nx, ny)
                if seen.contains(k) || wall(nx, ny) { continue }
                seen.insert(k)
                queue.append((nx, ny))
            }
            if queue.count > 20000 { return false }
        }
        return true
    }

    // --- въпроси ---

    func updateQuestions(_ idle: Bool) {
        if let p = questionPanel, let v = questionView {
            positionQuestion(p)
            if time - questionAsked > 45 {
                questionAsked = time
                questionNags += 1
                annoy(8 + Double(questionNags) * 4, reason: "не ми отговори на въпроса")
                start(.angry, length: 1.5)
                glitchUntil = time + 0.4
                v.angry = true
                v.needsDisplay = true
                if questionNags >= 3 {
                    closeQuestion()
                    annoy(15)
                    say("Добре, не ми говори! Сърдит съм!", seconds: 3)
                    nextQuestion = time + Double.random(in: 10 * 60...20 * 60)
                } else {
                    say("Отговори ми!", seconds: 2)
                }
            }
            return
        }
        guard idle, time > nextQuestion, want == nil, clipPanel == nil, shopPanel == nil, !pet.working else { return }
        nextQuestion = time + Double.random(in: 10 * 60...20 * 60)
        ask(questions.randomElement()!)
    }

    func ask(_ q: Question) {
        let v = QuestionView(frame: NSRect(origin: .zero, size: QuestionView.size))
        v.game = self
        v.question = q
        let p = overlayPanel(NSRect(origin: .zero, size: QuestionView.size), key: false)
        p.contentView = v
        positionQuestion(p)
        p.orderFrontRegardless()
        questionPanel = p
        questionView = v
        questionAsked = time
        questionNags = 0
    }

    func positionQuestion(_ p: NSPanel) {
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        var o = NSPoint(x: pr.midX - QuestionView.size.width / 2, y: pr.maxY + 8)
        o.x = min(max(o.x, vf.minX + 4), vf.maxX - QuestionView.size.width - 4)
        o.y = min(max(o.y, vf.minY + 4), vf.maxY - QuestionView.size.height - 4)
        if abs(p.frame.minX - o.x) > 0.5 || abs(p.frame.minY - o.y) > 0.5 { p.setFrameOrigin(o) }
    }

    func answerQuestion(_ i: Int) {
        guard let q = questionView?.question, i < q.answers.count else { return }
        closeQuestion()
        let (_, reply, effect) = q.answers[i]
        say(reply, seconds: 3)
        switch effect {
        case .happy:
            pet.fun = (pet.fun + 8).clamped()
            anger = (anger - 10).clamped()
            start(.love, length: 1.6)
        case .angry(let a):
            annoy(a, reason: "ми отговори „\(q.answers[i].0.lowercased())“")
            start(.angry, length: 2)
            glitchUntil = time + 0.5
        case .work: if !pet.working { toggleWork() }
        case .shop: openShop()
        case .clip: playClip()
        case .play: toggleFetch()
        case .nothing: break
        }
        addXP(2)
    }

    func closeQuestion() {
        questionPanel?.orderOut(nil)
        questionPanel = nil
        questionView = nil
    }

    // --- скокове: до платформите и до другия екран ---

    var feetScreenY: CGFloat { window.frame.maxY - view.feetY }
    var bodyCenterOffset: CGFloat { (view.bodyX0 + view.bodyX1) / 2 }

    /// Опитва да скочи някъде; връща true, ако е намерил къде.
    func tryJump() -> Bool {
        let wf = window.frame
        let feet = feetScreenY
        let cx = wf.minX + bodyCenterOffset
        var spots: [NSPoint] = []
        // върхове на нарисувани пиксели, достатъчно близо
        for (k, _) in drawCells {
            let (x, y) = cellFromKey(k)
            if drawCells[cellKey(x, y + 1)] != nil { continue }
            let top = CGFloat(y + 1) * drawCell
            let px = (CGFloat(x) + 0.5) * drawCell
            if abs(px - cx) < 380 && abs(px - cx) > 30 && top - feet < 320 && feet - top < 500 {
                spots.append(NSPoint(x: px, y: top))
            }
        }
        // другият екран
        if NSScreen.screens.count > 1, Double.random(in: 0..<1) < 0.35,
           let here = screenAt(NSPoint(x: cx, y: feet + 5)) {
            let others = NSScreen.screens.filter { $0 != here }
            if let other = others.randomElement() {
                let vf = other.visibleFrame
                let x = other.frame.midX < here.frame.midX ? vf.maxX - 120 : vf.minX + 120
                spots = [NSPoint(x: x, y: vf.minY)]
            }
        }
        guard let spot = spots.randomElement() else { return false }
        jumpFrom = wf.origin
        jumpTo = NSPoint(x: spot.x - bodyCenterOffset, y: spot.y - (wf.height - view.feetY))
        let dist = hypot(jumpTo.x - jumpFrom.x, jumpTo.y - jumpFrom.y)
        jumpDuration = min(1.6, 0.55 + Double(dist) / 1400)
        jumpHeight = max(70, jumpTo.y - jumpFrom.y + 90)
        jumpStart = time
        jumping = true
        facingLeft = jumpTo.x < jumpFrom.x
        say(["Хоп!", "Скачам!", "Йеее!", "Гледай сега!"].randomElement()!, seconds: 1.5)
        return true
    }

    func updateJump() {
        guard jumping else { return }
        let p = min(1, (time - jumpStart) / jumpDuration)
        let t = CGFloat(p)
        let x = jumpFrom.x + (jumpTo.x - jumpFrom.x) * t
        let y = jumpFrom.y + (jumpTo.y - jumpFrom.y) * t + 4 * jumpHeight * t * (1 - t)
        window.setFrameOrigin(NSPoint(x: x, y: y))
        walking = true
        if p >= 1 {
            jumping = false
            walking = false
            saveWindowPosition()
        }
    }

    // --- пиксел, изстрелян към него с клик ---

    func shootFood(_ food: FoodPixel) {
        food.flying = true
        food.flyFrom = food.panel.frame.origin
        food.flyStart = time
    }

    func updateFlyingFood() {
        for food in foods where food.flying {
            let p = CGFloat(min(1, (time - food.flyStart) / 0.35))
            let pr = petScreenRect()
            let target = NSPoint(x: pr.midX - FoodView.size.width / 2, y: pr.midY - FoodView.size.height / 2)
            let o = NSPoint(x: food.flyFrom.x + (target.x - food.flyFrom.x) * p,
                            y: food.flyFrom.y + (target.y - food.flyFrom.y) * p + 60 * p * (1 - p))
            food.panel.setFrameOrigin(o)
            if p >= 1 {
                food.flying = false
                foodDropped(food)
            }
        }
    }

    /// Нарисувал си нещо, след като го е поискал.
    func fulfillDrawRequest() {
        if let w = want, case .draw = w {
            fulfill(w)
            say("Уау, прекрасно е! Благодаря! +10 монети", seconds: 3)
        }
    }

    // --- поздрав при пускане ---

    func greet() {
        let h = Calendar.current.component(.hour, from: Date())
        let title = h >= 5 && h < 12 ? "ДОБРО УТРО!" : (h < 18 && h >= 12 ? "ДОБЪР ДЕН!" : "ДОБЪР ВЕЧЕР!")
        showAlert(title, "\(pet.name.uppercased()) ТИ МАХА!", happy: true)
    }

    // --- сам отива да монтира ---

    func updateAutoWork(_ idle: Bool) {
        if autoWorking && pet.working && time - autoWorkStart > 25 * 60 {
            autoWorking = false
            pet.working = false
            say("Стига толкова монтаж за сега.", seconds: 3)
        }
        if !pet.working { autoWorking = false }
        guard idle, !pet.working, time > nextAutoWork, pet.energy > 40, toiletPhase == .off,
              fetchPhase == .off, !jumping, questionPanel == nil else { return }
        nextAutoWork = time + Double.random(in: 20 * 60...40 * 60)
        if pet.work < 60 || Bool.random() {
            toggleWork()
            if pet.working {
                autoWorking = true
                autoWorkStart = time
                say("Отивам да монтирам малко…", seconds: 3)
            }
        }
    }
}
