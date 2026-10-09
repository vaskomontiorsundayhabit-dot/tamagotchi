// Преяждане, развалени пиксели, болест, кафе и прозорците на другите програми.

import AppKit

let overeatLines = ["Не трябваше… но е толкова вкусно!", "Коремчето ми расте!", "Още един… и спирам. Може би.",
                    "Пълнея, ама кой брои?", "Ох, тежко ми е…"]
let spoiledLines = ["Бляк! Развален пиксел!", "Фуу, тоя е черен!", "Това вони на стар кеш!", "Защо ми даде развален?!"]
let drunkLines = ["Хик!", "Виждам звуци…", "Монтирам в 3D!", "Обичам всички!", "Кой премести екрана?",
                  "Таймлайнът танцува!", "Още едно кафе! Хик!", "Колко пиксела виждаш? Аз виждам двойно."]
let sickLines = ["Апчих!", "Не ми е добре…", "Тече ми носът…", "Искам чай…", "Падат ми пикселите…", "Апчиии!"]
let windowSnackLines = ["Ням! Вкусен прозорец!", "Тоя прозорец е хрупкав!", "Ммм, вкус на браузър.",
                        "Отхапах малко от програмата ти.", "Пикселите тук са пресни!"]

let iconBelly = grid([
    "..KKKK..",
    ".KBBBBK.",
    "KBBBBBBK",
    "KBBRRBBK",
    "KBBRRBBK",
    "KBBBBBBK",
    ".KBBBBK.",
    "..KKKK..",
])
let iconTea = grid([
    "...WW...",
    "....W...",
    "WWWWWW..",
    "WGGGGWWW",
    "WGGGGW.W",
    "WGGGGWWW",
    ".WWWW...",
    "........",
])

/// Пиксел, паднал от тялото при лудост: лети, лежи на земята и се връща.
struct LostPixel {
    var cx: Int
    var cy: Int
    var start: Double
    var vx: CGFloat
    var vy: CGFloat
}

/// Отхапано парче от прозорец (само рисунка отгоре; истинската програма не се пипа).
final class BiteMark: NSObject {
    let panel: NSPanel
    let created: Double

    init(at origin: NSPoint, time: Double) {
        created = time
        panel = overlayPanel(NSRect(origin: origin, size: NSSize(width: 34, height: 16)), key: false)
        super.init()
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
        panel.ignoresMouseEvents = true
        let v = BiteView(frame: NSRect(x: 0, y: 0, width: 34, height: 16))
        panel.contentView = v
        panel.orderFrontRegardless()
    }

    func remove() { panel.orderOut(nil); panel.close() }
}

final class BiteView: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        // назъбена „дупка“ откъм горния ръб
        NSColor(hex: 0x1b1b24, alpha: 0.85).setFill()
        let cols: [CGFloat] = [4, 8, 12, 14, 12, 14, 10, 6]
        for (i, h) in cols.enumerated() {
            NSRect(x: 1 + CGFloat(i) * 4, y: 0, width: 4, height: h).fill()
        }
    }
}

extension Game {
    var isSick: Bool { (pet.sickUntil ?? .distantPast) > Date() }
    var isDrunk: Bool { time < drunkUntil }
    var bellyPixels: Int { Int((pet.overfull / 100 * 6).rounded()) }
    /// колко клетки има тялото сега: ниво + коремче − паднали при болест
    var bodyCells: Int { max(1, pet.level + bellyPixels - (isSick ? 6 : 0)) }

    // --- ядене ---

    /// Яде; връща false, ако откаже.
    @discardableResult
    func eatFood(color: Int, spoiled: Bool) -> Bool {
        if spoiled {
            lastFoodColor = 0x2b2b2b
            start(.angry, length: 1.5)
            say(pick(spoiledLines, avoiding: &lastLine), seconds: 2.5)
            pet.fullness = (pet.fullness + 5).clamped()
            pet.fun = (pet.fun - 5).clamped()
            let today = dayKey()
            if pet.badDay != today { pet.badDay = today; pet.badToday = 0 }
            pet.badToday += 1
            if pet.badToday >= 2 && !isSick { getSick() }
            save()
            return true
        }
        if pet.fullness >= 90 && want != .color(color) {
            // преяжда: коремчето расте с пиксели
            if pet.overfull >= 100 {
                start(.angry, length: 1.2)
                say("Не! Ще се пръсна!", seconds: 2.5)
                return false
            }
            pet.overfull = min(100, pet.overfull + 25)
            pet.fullness = 100
            lastFoodColor = color
            start(.eat, length: 1.6)
            say(pick(overeatLines, avoiding: &lastLine), seconds: 2.5)
            addXP(2)
            save()
            return true
        }
        return eat(color: color)
    }

    func dayKey() -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    // --- болест ---

    func getSick() {
        pet.sickUntil = Date().addingTimeInterval(Double.random(in: 2 * 3600...3 * 3600))
        pet.health = min(pet.health, 50)
        pet.working = false
        start(.angry, length: 2)
        say("Не ми е добре… разболях се! Падат ми пикселите!", seconds: 4)
        save()
    }

    /// Лекарство, чай или сън скъсяват болестта.
    func cure(minutes: Double) {
        guard let until = pet.sickUntil else { return }
        let left = until.addingTimeInterval(-minutes * 60)
        if left <= Date() {
            pet.sickUntil = nil
            say("Оздравях! Пикселите ми се върнаха!", seconds: 3.5)
            start(.love, length: 2)
        } else {
            pet.sickUntil = left
            let m = Int(left.timeIntervalSinceNow / 60)
            say("По-добре съм… още около \(m) мин.", seconds: 3)
        }
        save()
    }

    func updateHealth(_ step: Double) {
        // коремчето спада за ~10 минути
        if pet.overfull > 0 { pet.overfull = max(0, pet.overfull - 10 * step / 60) }

        if let until = pet.sickUntil {
            if until <= Date() {
                pet.sickUntil = nil
                say("Оздравях! Пикселите ми се върнаха!", seconds: 3.5)
                start(.love, length: 2)
            } else {
                if pet.working { pet.working = false; say("Болен съм, не мога да монтирам…", seconds: 3) }
                if pet.asleep { pet.sickUntil = until.addingTimeInterval(-step * 2) }   // дрямката лекува 3 пъти по-бързо
                if bubbleText == nil && time > nextSickLine {
                    nextSickLine = time + Double.random(in: 40...90)
                    say(pick(sickLines, avoiding: &lastLine), seconds: 2.5)
                }
            }
        }

        updateDrunkActs()
        // повръщане от много кафе
        if vomitAt > 0 && time > vomitAt && !pet.asleep {
            vomitAt = 0
            vomitUntil = time + 2.5
            say("Бле… прекалих с кафето…", seconds: 2.5)
        }
        if vomitUntil > 0 && time > vomitUntil {
            vomitUntil = 0
            let pr = petScreenRect()
            let feet = window.frame.maxY - view.feetY
            messes.append(MessPixel(poop: false, vomit: true, at: NSPoint(x: pr.midX + (facingLeft ? -60 : 14), y: feet - 2), game: self))
            pet.fullness = (pet.fullness - 30).clamped()
            pet.overfull = 0
            drunkUntil = max(time + 60, drunkUntil - 3 * 60)
            say("Уф… по-добре съм. Почисти, моля.", seconds: 3)
        }
        if isDrunk && bubbleText == nil && time > nextDrunkLine {
            nextDrunkLine = time + Double.random(in: 15...30)
            say(pick(drunkLines, avoiding: &lastLine), seconds: 2.5)
            if Bool.random() { glitchUntil = time + 0.3 }
        }

        // развалени пиксели
        for f in foods where !f.spoiled && time > f.spoilAt {
            f.spoiled = true
            f.view.needsDisplay = true
        }

        // прозорците на другите програми
        if time - lastWindowScan > 1 {
            lastWindowScan = time
            refreshWindows()
        }
        let gone = bites.filter { time - $0.created > 90 }
        gone.forEach { $0.remove() }
        bites.removeAll { b in gone.contains { $0 === b } }

        // хапва от прозореца, на който стои
        if let w = standingOnWindow, !pet.asleep, !pet.dead, !pet.working, !busyMoving, !isDragging,
           pet.fullness < 85 || isDrunk, time > nextWindowSnack, action == .none {
            nextWindowSnack = time + (isDrunk ? Double.random(in: 30...60) : Double.random(in: 3 * 60...8 * 60))
            let pr = petScreenRect()
            let x = min(max(pr.midX + (facingLeft ? -40 : 10), w.minX + 2), w.maxX - 36)
            bites.append(BiteMark(at: NSPoint(x: x, y: w.maxY - 16), time: time))
            lastFoodColor = [0x48cae4, 0xffffff, 0x8d99ae, 0x1982c4].randomElement()!
            pet.fullness = (pet.fullness + 12).clamped()
            start(.eat, length: 1.8)
            say(pick(windowSnackLines, avoiding: &lastLine), seconds: 2.5)
            addXP(3)
        }
    }

    // --- кафе ---

    func drankCoffee() {
        coffeeTimes.append(time)
        coffeeTimes.removeAll { time - $0 > 60 * 60 }
        let n = recentCoffees
        let inHalfHour = coffeeTimes.filter { time - $0 < 30 * 60 }.count
        if inHalfHour >= 2 || isDrunk {
            // всяко следващо кафе удължава лудостта
            drunkUntil = max(drunkUntil, time) + (isDrunk ? 5 * 60 : 10 * 60)
            nextDrunkLine = time + 6
            nextDrunkAct = time + 8
        }
        let text: String
        switch n {
        case 1: text = "Кафеее! Сега мога да монтирам цяла нощ!"
        case 2: text = "Второ кафе! Хик! Светът се върти…"
        case 3: text = "ТРЕТО КАФЕ?! Виждам звуци и чувам цветове!"
        case 4: text = "ЧЕТВЪРТО! Сърцето ми бие в 120 fps!"
        default: text = "\(n) КАФЕТА! АЗ СЪМ КАФЕ! КАФЕТО СЪМ АЗ!"
        }
        say(text, seconds: 3.5)
        if n >= 3 { glitchUntil = time + 1.5 }
        if n >= 5 { vomitAt = time + 3 }
    }

    // --- лудости от много кафе ---

    func updateDrunkActs() {
        guard isDrunk, time > nextDrunkAct, !pet.asleep, !pet.dead, !isDragging, !busyMoving,
              catchPanel == nil, clipPanel == nil, shopPanel == nil, !drawing else { return }
        nextDrunkAct = time + (isHyper ? Double.random(in: 8...18) : Double.random(in: 15...30))
        var acts = ["closeup", "confetti", "shout", "rain", "snack"]
        if !pet.working { acts += ["zoomies", "zoomies", "roll", "jump", "dance"] }
        switch acts.randomElement()! {
        case "closeup":
            // идва „по-близо до екрана“ и пита как си
            closeUpUntil = time + 5
            if questionPanel == nil {
                ask(Question(text: "КАК СИ? КАК СИ?! КАК СИИИ?!", answers: [
                    ("ДОБРЕ", "Аз също! МНОГО ДОБРЕ! МНОГО!", .happy),
                    ("ЗЛЕ", "Искаш ли кафе?! Аз искам! Още!", .nothing),
                    ("ХИК", "Хик! Ти също ли?!", .happy),
                ]), index: -1)
            }
        case "confetti":
            confettiStart = time
            say("ПИКСЕЛНО ПАРТИ!", seconds: 2)
        case "shout":
            say(["ААААА!", "КОЙ СЪМ АЗ?!", "МОНТИРАМ БЕЗ РЪЦЕ!", "ВСИЧКО Е 4K!", "НЕ МОГА ДА СПРА!"].randomElement()!, seconds: 2)
            glitchUntil = time + 0.6
        case "rain":
            // хвърля пиксели наоколо
            let pr = petScreenRect()
            for _ in 0..<3 {
                foods.append(FoodPixel(color: foodColors.randomElement()!,
                                       at: NSPoint(x: pr.midX + CGFloat.random(in: -200...200), y: pr.maxY + CGFloat.random(in: 40...200)),
                                       game: self))
            }
            say("Пиксели за всички!", seconds: 2)
        case "snack":
            nextWindowSnack = 0
            if standingOnWindow == nil && !pet.working { _ = tryJump() }
        case "zoomies":
            zoomiesUntil = time + 6
            walkTarget = nil
            say("ЗУУУУМ!", seconds: 1.5)
        case "roll":
            startRoll()
        case "jump":
            _ = tryJump()
        default:
            start(.wave, length: 4)
            say("Танцувам! Не мога да спра!", seconds: 2.5)
        }
    }

    // --- прозорците като платформи ---

    func refreshWindows() {
        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return }
        let mainH = NSScreen.screens.first?.frame.height ?? 0
        let me = ProcessInfo.processInfo.processIdentifier
        var rects: [NSRect] = []
        for w in info {
            guard (w[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  (w[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value != me,
                  let bd = w[kCGWindowBounds as String] as? NSDictionary,
                  let r = CGRect(dictionaryRepresentation: bd as CFDictionary),
                  r.width > 120, r.height > 60 else { continue }
            rects.append(NSRect(x: r.minX, y: mainH - r.maxY, width: r.width, height: r.height))
        }
        windowRects = rects
    }
}
