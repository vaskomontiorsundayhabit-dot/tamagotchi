// Тайно: какво прави дървото на желанията и още неща. Не го описвай в README.

import AppKit

extension PotGame {
    var isWishTree: Bool { d.bool(forKey: "pot_wish") }
    /// Едно желание на ден; чака, докато не го поискаш.
    var wishReady: Bool { isWishTree && d.string(forKey: "pot_wishDay") != dayKey() }

    /// Всяка минута (от updateFate).
    func updateWishTree() {
        if wishReady && userActive && d.string(forKey: "pot_wishSaid") != dayKey() {
            d.set(dayKey(), forKey: "pot_wishSaid")
            announce("Клоните ми светят… днес мога да изпълня едно желание. Цъкни ме!", 4)
        }
        // падаща звезда в нощта
        if isNight && userActive && time > starUntil + 60 && d.string(forKey: "pot_starDay") != dayKey() && Int.random(in: 0..<150) == 0 {
            d.set(dayKey(), forKey: "pot_starDay")
            starUntil = time + 12
            sfx("Glass")
        }
    }

    /// Цъкнато дърво с готово желание: изпълнява това, от което най-много има нужда.
    func grantWish() {
        d.set(dayKey(), forKey: "pot_wishDay")
        sfx("Hero")
        danceUntil = time + 4
        let text: String
        if !weeds.isEmpty || !weedPanels.isEmpty {
            weeds = []
            for w in weedPanels { pullFloorWeed(w) }
            text = "Пожелах си чиста градина… и всички бурени изчезнаха!"
        } else if health < 70 || water < 50 {
            health = 100; water = 100; wateringUntil = time + 2.5
            text = "Пожелах си да съм здраво… и ето ме като ново!"
        } else if creature != nil && creatureSulking {
            lastCreatureLove = Date(); creatureHeartsUntil = time + 4
            text = "Пожелах си \(creatureName) да не е тъжно… и вече се усмихва!"
        } else if hasEgg && eggCare < 95 {
            eggCare = 100
            text = "Пожелах си яйцето да е топло… и то е готово да се излюпи!"
        } else {
            switch Int.random(in: 0..<4) {
            case 0:
                fruitsCollected += 10
                text = "Пожелах си 10 плода… и кофата се напълни!"
            case 1 where creature != nil:
                creatureGrow(120); creature2Grow(60)
                text = "Пожелах си създанията да пораснат… и те пораснаха!"
            case 2:
                let cap = [0, 0, 0, 6, 9, 13][min(5, stage)]
                fruitsOnPlant = max(fruitsOnPlant, cap)
                text = "Пожелах си да родя… и всички клони са в плодове!"
            default:
                fertUntil = Date().addingTimeInterval(3 * 3600)
                text = "Пожелах си да раста… три часа раста двойно по-бързо!"
            }
        }
        announce("✦ " + text, 4.5)
        journal("Дървото изпълни желание: " + text)
        let n = d.integer(forKey: "pot_wishCount") + 1
        d.set(n, forKey: "pot_wishCount")
        if n == 7 {
            d.set(true, forKey: "pot_goldBloom")
            discover("wish7", "Седмото желание дървото пожела за себе си")
            announce("Седмото желание… този път си пожелах нещо за МЕН. Цъфтя в злато завинаги!", 5)
        }
    }

    /// Цъкнато по време на падаща звезда.
    func caughtStar() {
        starUntil = 0
        health = 100
        creatureGrow(50)
        sfx("Hero")
        discover("star", "Хвана падаща звезда")
        announce("Хвана падащата звезда! Пожелах си… няма да ти кажа, иначе няма да се сбъдне.", 4.5)
    }

    /// Цъкнато в полунощ.
    func midnightWhisper() -> Bool {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        guard c.hour == 0, (c.minute ?? 99) < 10, !secrets.contains("midnight") else { return false }
        health += 20
        discover("midnight", "В полунощ растението прошепна клюка")
        announce("Шшт… в полунощ всички растения по света си говорят. Чух, че кактусът на съседката е влюбен в мен. И че гъбата лъже за възрастта си.", 6)
        return true
    }

    /// Всеки откъснат плод.
    func countHarvest() {
        let n = d.integer(forKey: "pot_pickedTotal") + 1
        d.set(n, forKey: "pot_pickedTotal")
        if n == 150 {
            d.set(true, forKey: "pot_medal")
            discover("harvest", "Градинарят връчи медал за 150 плода")
            announce("Градинарят мина и закачи МЕДАЛ на саксията: „Най-плодородно растение на квартала“!", 5)
        }
    }

    /// Звънче посред нощ.
    func bellAtNight() {
        let h = Calendar.current.component(.hour, from: Date())
        guard h >= 1 && h < 5, !secrets.contains("nightbell") else { return }
        discover("nightbell", "Звънна посред нощ и събуди всички")
        announce("КОЙ ЗВЪНИ В " + "\(h)" + " ЧАСА?! Събуди всички! Даже съседите светнаха лампите.", 4.5)
        if creature != nil { creatureSay = "Спях!!!"; creatureSayUntil = time + 4 }
    }
}
