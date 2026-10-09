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
let friendJobLines = ["Щрак! Каква светлина!", "Още една от този ъгъл…", "Тази снимка е за корица!",
                      "Не мърдай! Щрак!", "Обективът ми е запотен…", "Фокус… фокус… ЩРАК!", "Ще я пусна в портфолиото!"]
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
    var flashAt: Double = -10
    static let size = NSSize(width: 210, height: 190)
    static let scale: CGFloat = 1.5
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.friendClicked() }
    override func rightMouseDown(with event: NSEvent) {
        guard let game else { return }
        NSMenu.popUpContextMenu(game.friendMenu(), with: event, for: self)
    }

    var feetY: CGFloat { 30 + CGFloat(canvasH) * FriendView.scale }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time
        let asleep = game.friendAsleep
        let working = game.friendWorking && !asleep
        let flashing = t - flashAt < 0.25
        let pose: Pose = asleep ? .sleep : (walking ? .walk : (flashing ? .wave : .idle))
        let f: Face = asleep ? .sleep : (working && !flashing ? .focus : face)
        let sp = buildSprite(level: 14, face: f, pose: pose, frame: Int(t * (walking ? 7 : 2)), working: false)
        let s = FriendView.scale
        let ox = (bounds.width - CGFloat(canvasW) * s) / 2
        let flip = walking && facingLeft
        // розова приятелка: собствени цветове за тялото
        let pink = NSColor(hex: 0xff8fab)
        drawGrid(sp.grid, x: ox, y: 30, s: s, flip: flip, palette: { c in
            switch c {
            case "B": return pink
            case "D": return pink.blended(withFraction: 0.22, of: .black)
            case "L": return pink.blended(withFraction: 0.45, of: .white)
            case "A": return pink.blended(withFraction: 0.08, of: .black)
            case "P": return NSColor(hex: 0xe63946)
            default: return game.color(c)
            }
        })
        let cx = ox + CGFloat(sp.cx) * s
        let midY = 30 + CGFloat(sp.top + sp.bottom) / 2 * s
        if working {
            // фотоапарат в ръцете ѝ
            let cam = grid([
                "..KKK.....",
                "KKKKKKKKKK",
                "KSSSKKKSSK",
                "KSSKCCKSSK",
                "KSSKCCKSSK",
                "KSSSKKSSSK",
                "KKKKKKKKKK",
            ])
            let camX = facingLeft ? cx - 34 : cx + 4
            drawGrid(cam, x: camX, y: midY - 6, s: 3, palette: game.color)
            if flashing {
                NSColor(white: 1, alpha: 0.85).setFill()
                NSBezierPath(ovalIn: NSRect(x: camX + 6, y: midY - 22, width: 20, height: 20)).fill()
            }
        }
        if asleep {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: 0xff8fab)]
            for i in 0..<2 {
                let ph = (t * 0.5 + Double(i) / 2).truncatingRemainder(dividingBy: 1)
                ("z" as NSString).draw(at: NSPoint(x: cx + 20 + CGFloat(ph) * 14, y: 30 + CGFloat(sp.minY) * s - CGFloat(ph) * 20),
                                       withAttributes: a)
            }
        }
        let shown = text.flatMap { t < textUntil ? $0 : nil } ?? (game.friendHover ? game.friendName : nil)
        if let shown {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 9, weight: .bold),
                                                    .foregroundColor: NSColor.white]
            let str = shown.uppercased() as NSString
            let size = str.boundingRect(with: NSSize(width: bounds.width - 16, height: 60), options: [.usesLineFragmentOrigin],
                                        attributes: a).size
            let w = ceil(size.width) + 10, h = ceil(size.height) + 6
            let r = NSRect(x: (bounds.width - w) / 2, y: max(0, 30 + CGFloat(sp.minY) * s - h - 4), width: w, height: h)
            NSColor(hex: 0x6a1b3a, alpha: 0.95).setFill(); r.fill()
            str.draw(with: r.insetBy(dx: 5, dy: 3), options: [.usesLineFragmentOrigin], attributes: a)
        }
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
        updateLetter()
        guard pet.orderText == nil, letter == nil, idle, time > nextOrder else { return }
        sendLetter()
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
        if goingToWork {
            let line = Bool.random() ? "„\(name)“? " + fileDropLines.randomElement()! : fileDropLines.randomElement()!
            say(line, seconds: 3)
        }
    }

    // --- приятелка: фотограф (храни се, спи, работи, кръщава се) ---

    var friendAsleep: Bool { pet.owned.contains("friend") && (friendSleeping || pet.asleep) }
    var friendHover: Bool { friendPanel?.frame.insetBy(dx: 50, dy: 30).contains(NSEvent.mouseLocation) ?? false }

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
            friendSay(UserDefaults.standard.string(forKey: "friendName") == nil ? "Здрасти! Как ще ме кръстите?"
                      : "Здрасти! Аз съм \(friendName)!", 3)
        }
        guard let p = friendPanel, let v = friendView else { return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let y = vf.minY - (FriendView.size.height - v.feetY)
        var o = p.frame.origin

        // гладува бавно; спи, когато спи и Пиксчо
        if !friendAsleep { friendFull = max(0, friendFull - step / 180) }
        if friendFull < 30 && time > nextFriendHungry && !friendAsleep {
            nextFriendHungry = time + Double.random(in: 4 * 60...7 * 60)
            friendSay("Гладна съм! Дай ми пиксел!", 3)
        }
        // работа: снима
        if friendWorking && !friendAsleep {
            friendWorkSeconds += step
            if time > nextFriendFlash {
                nextFriendFlash = time + Double.random(in: 4...9)
                v.flashAt = time
                sfx("Tink", every: 3)
            }
            if friendWorkSeconds >= 60 {
                friendWorkSeconds -= 60
                earnCoins(1)
                friendShots += 1
                if friendShots % 15 == 0 {
                    earnCoins(15)
                    friendSay("Готова фотосесия! +15 монети", 3.5)
                }
            }
            if time > nextFriendLine && time > v.textUntil {
                nextFriendLine = time + Double.random(in: 70...160)
                friendSay(friendJobLines.randomElement()!, 3)
            }
            if time - friendWorkStart > 20 * 60 && !pet.working { friendWorking = false; friendSay("Стига снимки за днес.", 2.5) }
        } else if !friendAsleep && !friendWorking && time > nextFriendWork && friendFull > 20 {
            nextFriendWork = time + Double.random(in: 15 * 60...30 * 60)
            if pet.working || Bool.random() { startFriendWork() }
        }

        if friendAsleep {
            v.walking = false
        } else if let target = friendTarget {
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
                    friendFull = min(100, friendFull + 30)
                    friendSay("Ням! Мое е!", 2)
                    say("ЕЙ! Това беше мое!", seconds: 2.5)
                    annoy(5, reason: "приятелката ми ми открадна пиксела")
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
            if !v.walking && friendWorking { v.facingLeft = pr.midX < o.x + FriendView.size.width / 2 }
        }
        p.setFrameOrigin(o)
        v.needsDisplay = true
        let hit = friendHover
        if p.ignoresMouseEvents == hit { p.ignoresMouseEvents = !hit }

        guard time > nextFriendAct, !pet.asleep, !friendAsleep, hidePhase == .off else { return }
        nextFriendAct = time + Double.random(in: 60...150)
        let r = Int.random(in: 0..<10)
        if (r < 2 || friendFull < 30), let food = foods.randomElement() {
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
        } else if r < 6 && friendWorking {
            friendSay("Усмихни се, \(pet.name)! Щрак!", 2.5)
            v.flashAt = time
            pendingReply = ("Ееей, дай да видя снимката!", time + 2.5, false)
        } else {
            let (a, b) = friendTalks.randomElement()!
            friendSay(a, 3); v.face = .happy
            pendingReply = (b, time + 2.5, false)
        }
    }

    func startFriendWork() {
        guard !friendAsleep else { return }
        friendWorking = true
        friendWorkStart = time
        friendSay(["Вадя фотоапарата!", "Време за фотосесия!", "Щрак-щрак, почвам!"].randomElement()!, 2.5)
    }

    func friendSay(_ text: String, _ seconds: Double) {
        friendView?.text = text
        friendView?.textUntil = time + seconds
    }

    func updateFriendReply() {
        guard let r = pendingReply, time > r.at else { return }
        pendingReply = nil
        if r.angry { start(.angry, length: 2) }
        if hidePhase == .off && seekPhase == .off { say(r.text, seconds: 3) }
        friendView?.face = .normal
    }

    func friendClicked() {
        sfx("Purr")
        if friendAsleep {
            friendSay("Ммм… остави ме да спя…", 2)
            return
        }
        if friendFull < 30 { friendSay("Гладна съм… пусни ми пиксел!", 2.5); return }
        friendSay(["Хи-хи!", "Аз съм приятелката на \(pet.name)!", "Гъдел!", "Кажи му да ми даде пиксел!",
                   "Искаш ли снимка?"].randomElement()!, 2.5)
    }

    func friendMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        func item(_ title: String, _ sel: Selector) {
            let it = NSMenuItem(title: title, action: sel, keyEquivalent: "")
            it.target = self
            menu.addItem(it)
        }
        let info = NSMenuItem(title: "\(friendName) · фотограф · ситост \(Int(friendFull))% · снимки \(friendShots)", action: nil,
                              keyEquivalent: "")
        info.isEnabled = false
        menu.addItem(info)
        menu.addItem(.separator())
        item(friendWorking ? "Спри снимането" : "Снимай (работи)", #selector(friendToggleWork))
        item(friendSleeping ? "Събуди" : "Приспи", #selector(friendToggleSleep))
        item("Нахрани с пиксел", #selector(friendFeed))
        item("Прегърни \(pet.name)", #selector(friendHug))
        item("Смени името…", #selector(renameFriend))
        return menu
    }

    @objc func friendToggleWork() {
        if friendWorking { friendWorking = false; friendSay("Прибирам фотоапарата.", 2); return }
        if friendAsleep { friendSay("Спя…", 1.5); return }
        startFriendWork()
    }

    @objc func friendToggleSleep() {
        friendSleeping.toggle()
        if friendSleeping { friendWorking = false; friendSay("Лека нощ…", 2) } else { friendSay("Добро утро!", 2) }
    }

    @objc func friendFeed() {
        if friendAsleep { friendSay("Спя…", 1.5); return }
        if friendFull > 90 { friendSay("Пълна съм!", 2); return }
        friendFull = min(100, friendFull + 30)
        friendSay("Ням! Благодаря!", 2)
        sfx("Pop")
    }

    @objc func friendHug() {
        if friendAsleep { friendSay("Спя…", 1.5); return }
        friendSay("Прегръдка!", 2)
        start(.love, length: 2)
        say("Ооо, и аз те обичам, \(friendName)!", seconds: 2.5)
        sfx("Purr")
    }

    /// Пусна пиксел върху приятелката.
    func tryFeedFriend(_ food: FoodPixel) -> Bool {
        guard let p = friendPanel, !friendAsleep else { return false }
        let f = food.panel.frame
        guard p.frame.insetBy(dx: 50, dy: 30).contains(NSPoint(x: f.midX, y: f.midY)) else { return false }
        food.remove()
        foods.removeAll { $0 === food }
        friendFull = min(100, friendFull + 30)
        friendSay("Ням! Благодаря!", 2)
        sfx("Pop")
        return true
    }
}
