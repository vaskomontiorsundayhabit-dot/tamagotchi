// След пълната височина дървото старее: на определени години се случват неща.
// Тайно: кое кога. Не го описвай в README.

import AppKit

extension PotGame {
    /// Растеж след 100% височина.
    var treeAge: Double { max(0, growth - potThresholds[potThresholds.count - 1] - 1500) }
    var treeYears: Int { Int(treeAge / 300) }
    var treeYearProgress: Double { treeAge.truncatingRemainder(dividingBy: 300) / 300 }
    var treeMature: Bool { stage >= potThresholds.count - 1 && stageProgress >= 1 }
    func hasAge(_ k: String) -> Bool { d.bool(forKey: "pot_age_" + k) }

    /// Всяка минута (от updateFate).
    func updateTreeAge() {
        guard treeMature else { return }
        if !d.bool(forKey: "pot_ageSaid") && userActive {
            d.set(true, forKey: "pot_ageSaid")
            journal("Стигна пълна височина. Отсега нататък дървото старее")
            announce("Стигнах пълната си височина! Отсега нататък… ставам по-стар и по-мъдър. Нещо ще се случва с годините.", 5)
        }
        let y = treeYears
        if y > d.integer(forKey: "pot_yearSaid") && userActive {
            d.set(y, forKey: "pot_yearSaid")
            journal("Дървото стана на \(y) " + (y == 1 ? "година" : "години"))
        }
        let steps: [(Int, String, String, String)] = [
            (2, "owl", "В хралупата на дървото се засели бухал", "Чук-чук… в ствола ми се отвори ХРАЛУПА и в нея се нанесе бухал! Ху-ху!"),
            (3, "carved", "Някой издълба сърце в ствола", "СКАНДАЛ! През нощта някой ИЗДЪЛБА сърце с инициали в ствола ми! „Г + С“… кои ли са?!"),
            (4, "swing", "Някой върза люлка на клона", "Някой ми върза ЛЮЛКА на клона! Кой ли ще се люлее?"),
            (5, "wise", "Дървото започна да говори мъдро", "Чувствам се… мъдро. Цъкни ме понякога, ще ти кажа нещо."),
            (6, "moss", "По северната страна поникна мъх", "По ствола ми порасна МЪХ. Гъделичка! Цъкни ме да го изчистиш, като се появи."),
            (7, "fireflies", "Светулки нощуват в короната", "Нощем в короната ми вече светят СВЕТУЛКИ!"),
            (8, "lovers", "Разкри се кой е издълбал сърцето", "РАЗКРИТО! Сърцето в ствола ми го издълбали ГРАДИНАРЯТ и СЪСЕДКАТА! „Г + С“! Целият квартал говори!"),
            (9, "scar", "Буря отчупи клон от дървото", "БУРЯ! Отчупи ми се клон… боли. Поливай ме добре, за да зарасне раната."),
            (11, "treehouse", "На дървото се появи къщичка", "На ствола ми някой построи КЪЩИЧКА! С прозорче и покрив!"),
            (13, "memory", "Дървото започна да си спомня", "Колко години минаха… Започнах да си спомням разни неща. Цъкни ме и ще ти разкажа."),
            (15, "tourists", "Дървото стана туристическа забележителност", "Писаха за мен във вестника! Отсега ще идват ТУРИСТИ да ме снимат!"),
            (16, "ancient", "Стана вековно дърво", "Вече съм ВЕКОВНО ДЪРВО. Короната ми е най-голямата в квартала."),
            (19, "heir", "Дървото даде свое дете", "Пуснах ЖЪЛЪД от най-старото си клонче… това е МОЕТО ДЕТЕ. Посадих го до мен."),
            (24, "sage", "Дървото започна да пророкува", "Сънувах бъдещето. Отсега всяка сутрин ще ти казвам какво ще стане днес. И то ще стане."),
        ]
        for s in steps where y >= s.0 && !hasAge(s.1) && userActive {
            d.set(true, forKey: "pot_age_" + s.1)
            discover("age_" + s.1, s.2)
            announce(s.3, 5)
            break
        }
        // рожден ден на всяка нова година
        if y > d.integer(forKey: "pot_yearGift") && userActive {
            let gift = min(10, y + 1)
            d.set(y, forKey: "pot_yearGift")
            fruitsCollected += gift
            danceUntil = time + 5
            if y >= 1 { announce("🎂 Днес ставам на \(y)! Пуснах \(gift) плода в кофата за празника.", 4) }
        }
        if hasAge("heir") && !d.bool(forKey: "pot_heirPlanted") {
            d.set(true, forKey: "pot_heirPlanted")
            addExtraPot(sort: "oak", x: panel.frame.minX - 60 * scale)
        }
        // мъх: от време на време расте по ствола и бави растежа, докато не го изчистиш
        if hasAge("moss") && !d.bool(forKey: "pot_moss") && Int.random(in: 0..<360) == 0 {
            d.set(true, forKey: "pot_moss")
            announce("Пак ми порасна мъх по ствола… сърби!", 2.5)
        }
        if d.bool(forKey: "pot_moss") { health -= 0.05 }
        // раната от бурята зараства, ако е полято
        if hasAge("scar") && !hasAge("healed") {
            if water > 60 { d.set(d.double(forKey: "pot_scarHeal") + 1, forKey: "pot_scarHeal") }
            if d.double(forKey: "pot_scarHeal") >= 480 && userActive {
                d.set(true, forKey: "pot_age_healed")
                discover("age_healed", "Раната от бурята зарасна")
                announce("Раната ми ЗАРАСНА! На мястото на клона пусна ново, по-силно клонче.", 4.5)
            }
        }
        // туристи веднъж на ден
        if hasAge("tourists") && userActive && d.string(forKey: "pot_touristDay") != dayKey() && Int.random(in: 0..<200) == 0 {
            d.set(dayKey(), forKey: "pot_touristDay")
            let fp = overlayPanel(panel.frame, key: false)
            fp.ignoresMouseEvents = true
            fp.contentView = PotFlashView(frame: NSRect(origin: .zero, size: panel.frame.size))
            fp.orderFrontRegardless()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { fp.orderOut(nil) }
            sfx("Glass")
            if Bool.random() {
                fruitsCollected += 3
                announce("📸 Туристи ме снимаха! Оставиха 3 плода в кофата за благодарност.", 4)
            } else if fruitsOnPlant > 0 {
                fruitsOnPlant -= 1
                announce("📸 Туристи ме снимаха… и един ОТКЪСНА плод за спомен! Безобразие!", 4)
            } else {
                announce("📸 Туристи ме снимаха! Едно дете ме прегърна.", 3.5)
            }
        }
        // пророчество сутрин; сбъдва се до няколко часа
        if hasAge("sage") && userActive && d.string(forKey: "pot_prophecyDay") != dayKey() {
            d.set(dayKey(), forKey: "pot_prophecyDay")
            let kinds: [(String, String)] = [("gardener", "Днес ще дойде градинарят."), ("bird", "Днес птица ще кацне на клоните ми."), ("fruit", "Днес кофата ти ще се напълни.")]
            let k = kinds.randomElement()!
            d.set(k.0, forKey: "pot_prophecy")
            d.set(Date().addingTimeInterval(Double.random(in: 1800...10800)), forKey: "pot_prophecyAt")
            announce("🔮 Пророчество: " + k.1, 4.5)
        }
        if let kind = d.string(forKey: "pot_prophecy"), let at = d.object(forKey: "pot_prophecyAt") as? Date, Date() > at, userActive, visitor == nil {
            switch kind {
            case "gardener": startVisitor(.gardener)
            case "bird": startVisitor(.bird)
            default: fruitsCollected += 7; announce("🔮 Пророчеството се сбъдна: 7 плода в кофата!", 3.5)
            }
            if visitor != nil || kind == "fruit" { d.removeObject(forKey: "pot_prophecy") }
        }
        // бухалът понякога се обажда нощем
        if hasAge("owl") && isNight && userActive && Int.random(in: 0..<45) == 0 {
            announce(["Ху-хууу!", "Бухалът: „Ху е там?“", "Бухалът брои звездите…"].randomElement()!, 2.5)
        }
        // люлката: създанието се люлее
        if hasAge("swing") && creature != nil && !creatureAway && Int.random(in: 0..<30) == 0 {
            swingUntil = time + 20
            creatureSay = "Уииии!"; creatureSayUntil = time + 3
            creatureGrow(2)
        }
    }

    /// Цъкнато върху старото дърво: мъх, мъдрост или спомен. Връща true, ако е обработено.
    func treeClicked() -> Bool {
        guard treeMature else { return false }
        if d.bool(forKey: "pot_moss") {
            d.set(false, forKey: "pot_moss")
            health += 5
            sfx("Pop")
            say("Ааах, без мъх! Благодаря!", 2)
            return true
        }
        if hasAge("memory") && Int.random(in: 0..<3) == 0,
           let j = d.array(forKey: "pot_journal") as? [[String: Any]], j.count > 5,
           let e = j.dropLast(3).randomElement(), let text = e["text"] as? String, !text.hasPrefix("★") {
            let f = DateFormatter(); f.dateFormat = "d.MM"
            let when = f.string(from: Date(timeIntervalSince1970: e["t"] as? Double ?? 0))
            say("Помниш ли \(when)? „\(text)“… Ех, какви времена.", 5)
            eyesUntil = time + 5
            return true
        }
        if hasAge("wise") && Int.random(in: 0..<2) == 0 {
            let lines = ["Бавно расте дървото, бързо расте бурено.", "Който полива, той бере.",
                         "Корените не се виждат, но държат всичко.", "Не всяка птица, която пее, носи семе.",
                         "И най-голямото дърво е било кълн.", "Вятърът огъва, но не чупи, ако си гъвкав.",
                         "Мравката е малка, но носи повече от себе си.", "Сянката ми е подарък. Седни.",
                         "Есента не е край, а почивка.", "Ако галиш създанието си, то ще те помни."]
            say(lines.randomElement()!, 4.5)
            eyesUntil = time + 5
            return true
        }
        return false
    }
}
