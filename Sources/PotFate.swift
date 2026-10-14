// Тайно: създанието расте и получава сили; растението може да тръгне по различни пътища.
// Не го описвай в README.

import AppKit

extension PotGame {
    var creatureXP: Double { get { d.double(forKey: "pot_cxp") } set { d.set(newValue, forKey: "pot_cxp") } }
    /// 0 бебе, 1 малко, 2 голямо (със сила), 3 легендарно
    var creatureStage: Int { creatureXP < 60 ? 0 : (creatureXP < 200 ? 1 : (creatureXP < 600 ? 2 : 3)) }
    var lastCreatureLove: Date {
        get { d.object(forKey: "pot_cLove") as? Date ?? Date() }
        set { d.set(newValue, forKey: "pot_cLove") }
    }
    var creatureSulking: Bool { creature != nil && Date().timeIntervalSince(lastCreatureLove) > 48 * 3600 }
    var creatureName: String { creature.flatMap { PotCreature.find($0)?.name } ?? "създанието" }

    func creatureGrow(_ n: Double) {
        guard creature != nil else { return }
        let before = creatureStage
        creatureXP += n
        let s = creatureStage
        guard s > before else { return }
        sfx("Hero")
        creatureSay = ["", "Пораснах!", "Вече съм голям и имам СИЛА!", "АЗ СЪМ ЛЕГЕНДА!"][s]
        creatureSayUntil = time + 4
        switch s {
        case 1: discover("c_young", "\(creatureName.capitalizedFirst) порасна")
        case 2:
            discover("c_adult", "\(creatureName.capitalizedFirst) стана голямо и получи сила")
            say("\(creatureName.capitalizedFirst) отключи своята сила! Ще ми помага!", 4)
        default:
            discover("c_legend", "\(creatureName.capitalizedFirst) стана легендарно")
            say("ЛЕГЕНДАРНО! Около него свети златно!", 4)
        }
    }

    func petCreature() {
        guard creature != nil else { return }
        lastCreatureLove = Date()
        creatureHeartsUntil = time + 2
        if time - lastCreaturePet > 30 { lastCreaturePet = time; creatureGrow(3) }
        sfx("Purr")
        creatureSay = PotCreature.find(creature!)?.sound ?? "♥"
        creatureSayUntil = time + 2
    }

    func feedCreature() {
        lastCreatureLove = Date()
        creatureHeartsUntil = time + 3
        creatureGrow(15)
        sfx("Pop")
        creatureSay = ["Ням!", "Още!", "Вкусно!"].randomElement()!
        creatureSayUntil = time + 2
    }

    /// Всяка минута: създанието расте само, използва силата си, сърди се, ако е забравено.
    func updateFate(_ m: Double) {
        guard time > nextFateCheck else { return }
        nextFateCheck = time + 60
        let mins = 1.0
        // --- създанието ---
        if creature != nil {
            if health > 50 && !creatureSulking { creatureGrow(0.5 * mins) }
            let away = Date().timeIntervalSince(lastCreatureLove)
            if creatureSulking && !d.bool(forKey: "pot_cSulkSaid") {
                d.set(true, forKey: "pot_cSulkSaid")
                creatureSay = "Никой не ме обича…"
                creatureSayUntil = time + 5
                say("\(creatureName.capitalizedFirst) се сърди, че никой не го гали.", 3.5)
            }
            if !creatureSulking { d.set(false, forKey: "pot_cSulkSaid") }
            if away > 96 * 3600 {
                journal("\(creatureName.capitalizedFirst) избяга, защото никой не го обичаше")
                say("\(creatureName.capitalizedFirst) си събра багажа и отлетя… Остави бележка: „Сбогом“.", 5)
                creature = creature2
                creature2 = nil
                creatureXP = 0
                lastCreatureLove = Date()
            } else if creatureStage >= 2 && !creatureSulking {
                useCreaturePower()
            }
        }
        // --- пътищата на растението ---
        // сухо дълго време, а после полято: става издръжливо като кактус
        if water <= 1 { d.set(d.double(forKey: "pot_dryMin") + mins, forKey: "pot_dryMin") }
        if !d.bool(forKey: "pot_cactus") && d.double(forKey: "pot_dryMin") >= 360 && water > 50 {
            d.set(true, forKey: "pot_cactus")
            discover("cactus", "Оцеля след дълга суша и стана бодливо и издръжливо")
            say("Преживях сушата! Пуснах бодли и вече пия наполовина по-малко.", 4.5)
        }
        // дърво на желанията
        if !d.bool(forKey: "pot_wish") && stage >= 5 && stageProgress > 0.9 && creatureStage >= 2 && weeds.isEmpty && weedPanels.isEmpty {
            d.set(true, forKey: "pot_wish")
            discover("wish", "Стана Дърво на желанията")
            say("Нещо се промени… аз съм ДЪРВО НА ЖЕЛАНИЯТА!", 4.5)
        }
        if d.bool(forKey: "pot_wish") && d.string(forKey: "pot_wishDay") != dayKey() && Int.random(in: 0..<30) == 0 {
            d.set(dayKey(), forKey: "pot_wishDay")
            fruitsCollected += 10
            say("Желанието ми днес: 10 златни плода в кофата!", 4)
        }
        // месоядно: ако мравките често си тръгват сами (никой не ги гони)
        if carnivore && !ants.isEmpty && Int.random(in: 0..<3) == 0 {
            ants.removeLast()
            health += 5
            say(["Ням! Мравка!", "Хрус! Още една мравка!", "Вкусни мравчици!"].randomElement()!, 2)
        }
    }

    var carnivore: Bool { d.bool(forKey: "pot_carnivore") }
    var cactus: Bool { d.bool(forKey: "pot_cactus") }
    var lunar: Bool { d.bool(forKey: "pot_lunar") }

    /// Мравките си тръгнаха сами.
    func antsLeftAlone() {
        let n = d.integer(forKey: "pot_antsIgnored") + 1
        d.set(n, forKey: "pot_antsIgnored")
        if n >= 4 && !carnivore {
            d.set(true, forKey: "pot_carnivore")
            discover("carnivore", "Стана месоядно растение")
            say("Писна ми от мравки… отсега нататък ГИ ЯМ! Хрус!", 4.5)
        }
    }

    /// Тор при пълнолуние: лунна мутация.
    func fertilizedNow() {
        if fullMoon && isNight && !lunar {
            d.set(true, forKey: "pot_lunar")
            discover("lunar", "Лунна мутация: торено при пълнолуние")
            say("Торът и луната… листата ми станаха СРЕБЪРНИ завинаги!", 4.5)
        }
    }

    /// Силата на създанието (голямо и легендарно); легендарното я ползва по-често.
    func useCreaturePower() {
        guard let c = creature else { return }
        let legend = creatureStage >= 3
        guard Int.random(in: 0..<(legend ? 5 : 10)) == 0 else { return }
        var line: String?
        switch c {
        case "dragon":
            if !ants.isEmpty { ants = []; line = "Пфууу! (изгори мравките)" }
        case "phoenix":
            if health < 50 { health = legend ? 100 : 80; line = "Пиу! (лекува растението)" }
        case "ghost":
            if let v = visitor, v.kind == .raccoon, v.stage < 2 { caughtRaccoon(); line = "БУУУ! (крадецът избяга)" }
            else if weedKingPanel != nil { hitWeedKing(); line = "Буу! (плаши краля на бурените)" }
        case "robot":
            if water < 35 { water = 100; wateringUntil = time + 2.5; line = "Бип! (полива)" }
        case "fairy":
            let cap = [0, 0, 0, 6, 9, 13][min(5, stage)]
            if stage >= 3 && fruitsOnPlant < cap { fruitsOnPlant += 1; line = "Тин! (разцъфтява плод)" }
        case "unicorn":
            health += legend ? 10 : 5
            if legend && !d.bool(forKey: "pot_rainbow") { d.set(true, forKey: "pot_rainbow") }
            line = "Иии! (дъга)"
        case "octopus":
            if !weeds.isEmpty { weeds = Array(weeds.dropLast()); line = "Блуп! (изскубна бурен)" }
            else if !weedPanels.isEmpty, let w = weedPanels.last { pullFloorWeed(w); line = "Блуп! (бурен от пода)" }
        default: break
        }
        if let line { creatureSay = line; creatureSayUntil = time + 3 }
    }
}
