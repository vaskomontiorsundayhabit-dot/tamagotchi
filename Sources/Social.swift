// Компилации, гледания, клиенти, часът на деня, звуци, файлове върху него,
// следене на мишката, приятел и пиксел плъх.

import AppKit

let clientJobs = ["видео за сватба", "реклама за пекарна", "клип за рожден ден", "влог за пътуване",
                  "трейлър за игра", "интервю с котка", "музикален клип за група", "видео за фитнес",
                  "реклама за пица", "клип за абитуриентски бал"]
let fileDropLines = ["Да, да, почвам!", "Ооо, нов материал! Почвам!", "Кой е снимал това? Добре, монтирам!",
                     "Дай да видим… почвам!", "Чудесно! Тъкмо ми беше скучно!", "Хвърли го в таймлайна! Почвам!"]
let friendTalks: [(String, String)] = [
    ("Как върви монтажът?", "Бавно, рендерът пак забива."),
    ("Искаш ли пиксел?", "Винаги!"),
    ("Видя ли новия ми клип?", "Да, сложи повече експлозии."),
    ("Кой е по-жълт, аз или ти?", "Аз, очевидно."),
    ("Да избягаме зад монитора?", "Само ако там има пиксели."),
    ("Днес ще ставаме ли вайръл?", "Ако някой ни гледа…"),
]
let friendFights: [(String, String)] = [
    ("Ти ми изяде пиксела!", "Не съм! Ти си го изял!"),
    ("Моят клип е по-хубав!", "Хаха, твоят е в 480p!"),
    ("Мести се, тук съм аз!", "Ти се мести!"),
]

// MARK: - Приятелят и плъхът (отделни малки прозорчета)

final class FriendView: NSView {
    weak var game: Game?
    var text: String?
    var textUntil: Double = 0
    var face: Face = .normal
    var walking = false
    var facingLeft = false
    static let size = NSSize(width: 210, height: 190)
    static let scale: CGFloat = 1.5
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.friendClicked() }

    var feetY: CGFloat { 30 + CGFloat(canvasH) * FriendView.scale }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time
        let sp = buildSprite(level: 14, face: face, pose: walking ? .walk : .idle, frame: Int(t * (walking ? 7 : 2)), working: false)
        let s = FriendView.scale
        let ox = (bounds.width - CGFloat(canvasW) * s) / 2
        // розов приятел: собствени цветове за тялото
        let pink = NSColor(hex: 0xff8fab)
        drawGrid(sp.grid, x: ox, y: 30, s: s, flip: walking && facingLeft, palette: { c in
            switch c {
            case "B": return pink
            case "D": return pink.blended(withFraction: 0.22, of: .black)
            case "L": return pink.blended(withFraction: 0.45, of: .white)
            case "A": return pink.blended(withFraction: 0.08, of: .black)
            case "P": return NSColor(hex: 0xe63946)
            default: return game.color(c)
            }
        })
        if let text, t < textUntil {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .bold),
                                                    .foregroundColor: NSColor.white]
            let str = text.uppercased() as NSString
            let size = str.boundingRect(with: NSSize(width: bounds.width - 16, height: 60), options: [.usesLineFragmentOrigin],
                                        attributes: a).size
            let w = ceil(size.width) + 10, h = ceil(size.height) + 6
            let r = NSRect(x: (bounds.width - w) / 2, y: max(0, 30 + CGFloat(sp.minY) * s - h - 4), width: w, height: h)
            NSColor(hex: 0x6a1b3a, alpha: 0.95).setFill(); r.fill()
            str.draw(with: r.insetBy(dx: 5, dy: 3), options: [.usesLineFragmentOrigin], attributes: a)
        }
    }
}

final class RatView: NSView {
    weak var game: Game?
    var facingLeft = false
    var running = false
    static let size = NSSize(width: 46, height: 26)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.sfx("Purr"); game?.say("Това е моят плъх Пикселчо!", seconds: 2) }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let frame = Int(game.time * (running ? 12 : 3))
        var g = grid([
            "....KK..........",
            "...KEEK.........",
            "..KEEEEKKKK.....",
            ".KEWKEEEEEEKK...",
            "KREEEEEEEEEEEK.P",
            ".KEEEEEEEEEEK.P.",
            "..KKK.KK.KKKPP..",
        ])
        if frame % 2 == 1 { g[6] = Array("...KK.KK..KK.P..") }
        drawGrid(g, x: 0, y: 2, s: 3 - 0.25, flip: !facingLeft, palette: { c in
            c == "R" ? NSColor(hex: 0xff8fab) : game.color(c)
        })
    }
}

// MARK: - Логиката

extension Game {
    // --- звуци ---

    var soundsOn: Bool {
        get { UserDefaults.standard.object(forKey: "soundsOn") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundsOn") }
    }

    @objc func toggleSounds() { soundsOn.toggle() }

    func sfx(_ name: String, every: Double = 0.4) {
        guard soundsOn, window.isVisible else { return }
        if let last = lastSounds[name], time - last < every { return }
        lastSounds[name] = time
        NSSound(named: NSSound.Name(name))?.play()
    }

    // --- компилации и гледания ---

    func createCompilation() {
        var pool = Array(0..<clipTitles.count)
        pool.shuffle()
        pet.compilations.append(Array(pool.prefix(3)))
        if pet.compilations.count > 30 { pet.compilations.removeFirst() }
        // гледанията идват след малко
        let viral = Int.random(in: 0..<100) < 7
        let views = viral ? Int.random(in: 50_000...500_000) : Int.random(in: 40...4_000)
        pendingRatings.append((pet.videos, views, Int(Double(views) * Double.random(in: 0.03...0.09)), viral,
                               time + Double.random(in: 120...300)))
    }

    func updateRatings() {
        guard let i = pendingRatings.firstIndex(where: { time > $0.at }), window.isVisible, !pet.asleep else { return }
        let r = pendingRatings.remove(at: i)
        pet.views += r.views
        let coins = r.viral ? 150 : max(1, r.views / 300)
        earnCoins(coins)
        if r.viral {
            confettiStart = time
            start(.love, length: 3)
            sfx("Hero")
            say("СТАНАХ ВАЙРЪЛ! Видео №\(r.video): \(r.views) гледания! +\(coins) монети", seconds: 5)
        } else {
            say("Видео №\(r.video): \(r.views) гледания, \(r.likes) харесвания. +\(coins) монети", seconds: 4)
        }
    }

    // --- клиенти ---

    func updateClients(_ idle: Bool) {
        if let deadline = pet.orderDeadline, Date() > deadline, let job = pet.orderText {
            pet.orderText = nil
            pet.orderDeadline = nil
            nextOrder = time + Double.random(in: 40 * 60...90 * 60)
            annoy(20, reason: "изтървах срока на клиента")
            start(.angry, length: 2)
            say("Клиентът е бесен! Изтървах срока за \(job)!", seconds: 4)
            return
        }
        guard pet.orderText == nil, idle, time > nextOrder else { return }
        let job = clientJobs.randomElement()!
        pet.orderText = job
        pet.orderDeadline = Date().addingTimeInterval(Double.random(in: 45 * 60...90 * 60))
        pet.orderReward = Int.random(in: 4...15) * 10
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        sfx("Glass")
        say("Нов клиент: \(job) до \(f.string(from: pet.orderDeadline!))! Награда \(pet.orderReward) монети.", seconds: 5)
    }

    /// Готово видео: ако има поръчка в срок, клиентът плаща.
    func completeOrderIfAny() {
        guard let job = pet.orderText, let deadline = pet.orderDeadline, Date() <= deadline else { return }
        earnCoins(pet.orderReward)
        say("Клиентът е доволен от „\(job)“! +\(pet.orderReward) монети", seconds: 4)
        pet.orderText = nil
        pet.orderDeadline = nil
        nextOrder = time + Double.random(in: 40 * 60...90 * 60)
    }

    var orderText: String? {
        guard let job = pet.orderText, let d = pet.orderDeadline else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "ПОРЪЧКА: \(job.uppercased()) ДО \(f.string(from: d))"
    }

    // --- часът на деня ---

    func updateDayTalk(_ idle: Bool) {
        guard idle, !pet.working, time > nextDayTalk, bubbleText == nil else { return }
        nextDayTalk = time + Double.random(in: 25 * 60...45 * 60)
        let c = Calendar.current
        let h = c.component(.hour, from: Date())
        let friday = c.component(.weekday, from: Date()) == 6
        switch h {
        case 6..<10:
            start(.wave, length: 3)
            say("Ааах, протягам се! Хубава сутрин!", seconds: 3)
        case 12..<14:
            say("Обедна почивка! Къде са пикселите?", seconds: 3)
        case 17..<20 where friday:
            confettiStart = time
            start(.wave, length: 4)
            say("Петък вечер! Купон!", seconds: 3)
        case 17..<20:
            say("Почти край на деня…", seconds: 3)
        case 21..<24:
            blinkUntil = time + 1.5
            say("Ааахъм… късно става.", seconds: 3)
        case 0..<5:
            say("Защо още си буден? Утре пак е ден!", seconds: 3.5)
        default:
            break
        }
    }

    // --- файл, пуснат върху него ---

    func fileDropped(_ names: [String]) {
        let name = names.first ?? "файл"
        if pet.dead { return }
        if pet.asleep {
            pet.asleep = false
            say("Сега ли?! Добре, добре… ставам.", seconds: 2.5)
        }
        if isSick { say("Болен съм… но ще го погледна по-късно.", seconds: 3); return }
        sfx("Pop")
        if pet.working {
            say("Добавям „\(name)“ в таймлайна!", seconds: 3)
            return
        }
        toggleWork()
        if pet.working {
            let line = Bool.random() ? "„\(name)“? " + fileDropLines.randomElement()! : fileDropLines.randomElement()!
            say(line, seconds: 3)
        }
    }

    // --- приятел ---

    func updateFriend(_ step: Double) {
        let has = pet.owned.contains("friend") && window.isVisible
        if !has {
            friendPanel?.orderOut(nil); friendPanel = nil; friendView = nil
            return
        }
        if friendPanel == nil {
            let p = overlayPanel(NSRect(origin: window.frame.origin, size: FriendView.size), key: false)
            p.level = .floating
            let v = FriendView(frame: NSRect(origin: .zero, size: FriendView.size))
            v.game = self
            p.contentView = v
            p.orderFrontRegardless()
            friendPanel = p
            friendView = v
            friendSay("Здрасти! Аз съм Пиксчочка!", 3)
        }
        guard let p = friendPanel, let v = friendView else { return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let y = vf.minY - (FriendView.size.height - v.feetY)
        var o = p.frame.origin
        if let target = friendTarget {
            // тича към пиксел-храната
            let dx = target.x - o.x, dy = target.y - o.y
            let d = hypot(dx, dy)
            let sp = CGFloat(500 * step)
            v.walking = true
            v.facingLeft = dx < 0
            if d < sp {
                friendTarget = nil
                if let f = friendFood, foods.contains(where: { $0 === f }) {
                    f.remove(); foods.removeAll { $0 === f }
                    friendSay("Ням! Мое е!", 2)
                    say("ЕЙ! Това беше мое!", seconds: 2.5)
                    annoy(5, reason: "приятелят ми ми открадна пиксела")
                    sfx("Pop")
                }
                friendFood = nil
            } else {
                o.x += dx / d * sp; o.y += dy / d * sp
            }
        } else {
            let side: CGFloat = o.x + FriendView.size.width / 2 < pr.midX ? -1 : 1
            let goal = pr.midX + side * (pr.width / 2 + 70) - FriendView.size.width / 2
            let gx = min(max(goal, vf.minX - 40), vf.maxX - FriendView.size.width + 40)
            let dx = gx - o.x
            v.walking = abs(dx) > 3 || abs(o.y - y) > 3
            if abs(dx) > 3 { v.facingLeft = dx < 0; o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(50 * step)) }
            if abs(o.y - y) > 3 { o.y += (y > o.y ? 1 : -1) * min(abs(y - o.y), CGFloat(300 * step)) } else { o.y = y }
        }
        p.setFrameOrigin(o)
        v.needsDisplay = true

        guard time > nextFriendAct, !pet.asleep, hidePhase == .off else { return }
        nextFriendAct = time + Double.random(in: 60...150)
        let r = Int.random(in: 0..<10)
        if r < 2, let food = foods.randomElement() {
            friendFood = food
            friendTarget = NSPoint(x: food.panel.frame.midX - FriendView.size.width / 2, y: food.panel.frame.minY - v.feetY + 40)
            friendSay("Пиксел!", 1.5)
        } else if r < 4 {
            let (a, b) = friendFights.randomElement()!
            friendSay(a, 3); v.face = .angry
            pendingReply = (b, time + 2.5, true)
        } else if r < 5 {
            friendSay("Прегръдка!", 2); start(.love, length: 2)
            sfx("Purr")
        } else {
            let (a, b) = friendTalks.randomElement()!
            friendSay(a, 3); v.face = .happy
            pendingReply = (b, time + 2.5, false)
        }
    }

    func friendSay(_ text: String, _ seconds: Double) {
        friendView?.text = text
        friendView?.textUntil = time + seconds
    }

    func updateFriendReply() {
        guard let r = pendingReply, time > r.at else { return }
        pendingReply = nil
        if r.angry { start(.angry, length: 2) }
        say(r.text, seconds: 3)
        friendView?.face = .normal
    }

    func friendClicked() {
        friendSay(["Хи-хи!", "Аз съм приятелят на Пиксчо!", "Гъдел!", "Кажи му да ми даде пиксел!"].randomElement()!, 2.5)
        sfx("Purr")
    }

    // --- пиксел плъх ---

    func updateRat(_ step: Double) {
        let has = pet.owned.contains("rat") && window.isVisible
        if !has {
            ratPanel?.orderOut(nil); ratPanel = nil; ratView = nil; chasing = false
            return
        }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        if ratPanel == nil {
            let p = overlayPanel(NSRect(x: pr.midX + 80, y: vf.minY, width: RatView.size.width, height: RatView.size.height), key: false)
            p.level = .floating
            let v = RatView(frame: NSRect(origin: .zero, size: RatView.size))
            v.game = self
            p.contentView = v
            p.orderFrontRegardless()
            ratPanel = p
            ratView = v
        }
        guard let p = ratPanel, let v = ratView else { return }
        var o = p.frame.origin
        o.y = vf.minY
        if chasing {
            // бяга от Пиксчо
            let away: CGFloat = o.x + 20 > pr.midX ? 1 : -1
            var nx = o.x + away * CGFloat(170 * step)
            if nx < vf.minX + 5 || nx > vf.maxX - 50 { nx = o.x - away * CGFloat(400 * step) }
            o.x = nx
            v.facingLeft = away < 0
            v.running = true
            // Пиксчо тича след него
            let target = NSPoint(x: o.x + 20 - bodyCenterOffset, y: window.frame.minY)
            _ = moveWindow(toward: target, speed: CGFloat(160 * step))
            walking = true
            if abs(pr.midX - (o.x + 20)) < pr.width / 2 || time > chaseUntil {
                chasing = false
                walking = false
                let caught = abs(pr.midX - (o.x + 20)) < pr.width / 2
                say(caught ? "Хванах те! Добро плъхче!" : "Избяга ми! Пак ще те гоня!", seconds: 2.5)
                if caught { start(.love, length: 2); sfx("Purr") }
                saveWindowPosition()
            }
        } else {
            if ratTarget == nil || abs(ratTarget! - o.x) < 3 {
                ratTarget = Double.random(in: 0..<1) < 0.02 ? CGFloat.random(in: (vf.minX + 10)...(vf.maxX - 60)) : nil
            }
            v.running = false
            if let tx = ratTarget {
                let dx = tx - o.x
                v.facingLeft = dx < 0
                v.running = true
                o.x += (dx > 0 ? 1 : -1) * min(abs(dx), CGFloat(70 * step))
            }
            let onFloor = abs(feetScreenY - vf.minY) < 6
            if time > nextChase && onFloor && !pet.asleep && !pet.working && !busyMoving && !isDragging && hidePhase == .off {
                nextChase = time + Double.random(in: 120...300)
                chasing = true
                chaseUntil = time + 8
                say("Плъхче! Ела тук!", seconds: 2)
                sfx("Pop")
            }
        }
        p.setFrameOrigin(o)
        v.needsDisplay = true
    }
}
