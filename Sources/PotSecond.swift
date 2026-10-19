// Второто създание до първото: расте, гали се, яде от кофата и има своя сила.
// Тайно: какво става, когато са двама. Не го описвай в README.

import AppKit

extension PotGame {
    var creature2XP: Double { get { d.double(forKey: "pot_cxp2") } set { d.set(newValue, forKey: "pot_cxp2") } }
    var creature2Stage: Int { [60.0, 200, 600, 1500, 4000].filter { creature2XP >= $0 }.count }
    var lastCreature2Love: Date {
        get { d.object(forKey: "pot_c2Love") as? Date ?? Date() }
        set { d.set(newValue, forKey: "pot_c2Love") }
    }
    var creature2Name: String { creature2.flatMap { PotCreature.find($0)?.name } ?? "малкото" }

    /// Второто расте до легендарно; по-нататък, чак когато остане само в гнездото.
    func creature2Grow(_ n: Double) {
        guard creature2 != nil else { return }
        let before = creature2Stage
        creature2XP = min(1499, creature2XP + n)
        let s = creature2Stage
        guard s > before else { return }
        sfx("Hero")
        creature2Say = ["", "Пораснах!", "И аз имам СИЛА!", "И АЗ СЪМ ЛЕГЕНДА!"][min(3, s)]
        creature2SayUntil = time + 4
        let name = creature2Name.capitalizedFirst
        journal(["", "\(name) порасна", "\(name) стана голямо и получи сила", "\(name) стана легендарно"][min(3, s)])
        if s == 2 && creature != nil && creatureStage >= 3 {
            discover("mentor", "\(creatureName.capitalizedFirst) научи \(creature2Name) на своята сила")
            announce("\(creatureName.capitalizedFirst) научи \(creature2Name) да ползва силата си! Учител и ученик!", 4.5)
        }
    }

    func petCreature2() {
        guard let c = creature2 else { return }
        lastCreature2Love = Date()
        creature2HeartsUntil = time + 2
        if time - lastCreature2Pet > 30 { lastCreature2Pet = time; creature2Grow(3) }
        sfx("Purr")
        creature2Say = PotCreature.find(c)?.sound ?? "♥"
        creature2SayUntil = time + 2
    }

    func feedCreature2() {
        lastCreature2Love = Date()
        creature2HeartsUntil = time + 3
        creature2Grow(15)
        sfx("Pop")
        creature2Say = ["Ням!", "Още!", "Вкусно!"].randomElement()!
        creature2SayUntil = time + 2
    }

    /// Всяка минута (от updateFate).
    func updateSecond() {
        guard let c2 = creature2 else { return }
        if d.object(forKey: "pot_c2Love") == nil { lastCreature2Love = Date() }
        // расте само; по-бързо, когато голямото го учи
        let teach = creature != nil && creatureStage >= 3 && !creatureAway
        if health > 50 { creature2Grow(teach ? 1.0 : 0.5) }
        if creature2Stage >= 2 && Int.random(in: 0..<10) == 0, let line = creaturePower(c2, legend: creature2Stage >= 3) {
            creature2Say = line; creature2SayUntil = time + 3
        }
        guard creature != nil else { return }
        // заедно цял ден: стават приятели
        if d.object(forKey: "pot_togetherSince") == nil { d.set(Date(), forKey: "pot_togetherSince") }
        let together = Date().timeIntervalSince(d.object(forKey: "pot_togetherSince") as? Date ?? Date())
        if !d.bool(forKey: "pot_friends") && together > 86400 && userActive && !creatureSulking {
            d.set(true, forKey: "pot_friends")
            discover("friends", "\(creatureName.capitalizedFirst) и \(creature2Name) станаха най-добри приятели")
            announce("\(creatureName.capitalizedFirst) и \(creature2Name) се прегърнаха… вече са НАЙ-ДОБРИ ПРИЯТЕЛИ!", 4.5)
        }
        // приятелите понякога си играят на гоненица
        if d.bool(forKey: "pot_friends") && userActive && !creatureAway && !creatureHidden && Int.random(in: 0..<40) == 0 {
            creatureHeartsUntil = time + 3; creature2HeartsUntil = time + 3
            creatureGrow(2); creature2Grow(2)
            let lines = [("Гони ме!", "Хванах те!"), ("Аз съм по-голям!", "Ама аз съм по-бърз!"), ("Ти си гонещ!", "Не, ти!")]
            let l = lines.randomElement()!
            creatureSay = l.0; creatureSayUntil = time + 3
            creature2Say = l.1; creature2SayUntil = time + 3.5
        }
        // ревност: голямото е галено, малкото е забравено цял ден
        if userActive && Date().timeIntervalSince(lastCreature2Love) > 86400 && Date().timeIntervalSince(lastCreatureLove) < 3600
            && d.string(forKey: "pot_jealousDay") != dayKey() {
            d.set(dayKey(), forKey: "pot_jealousDay")
            let stolen = min(3, fruitsCollected)
            fruitsCollected -= stolen
            creature2Say = "А МЕН КОЙ МЕ ГАЛИ?!"; creature2SayUntil = time + 4
            discover("jealous", "\(creature2Name.capitalizedFirst) ревнува и открадна от кофата")
            announce("\(creature2Name.capitalizedFirst) ревнува, че галиш само \(creatureName)!"
                     + (stolen > 0 ? " Открадна \(stolen) плода от кофата и се цупи." : " Цупи се в ъгъла на гнездото."), 4.5)
        }
    }

    func overCreature2(_ p: NSPoint) -> Bool {
        let r = view.creature2Rect
        guard creature2 != nil, r != .zero else { return false }
        let sr = NSRect(x: panel.frame.minX + r.minX * scale, y: panel.frame.maxY - r.maxY * scale, width: r.width * scale, height: r.height * scale)
        return sr.insetBy(dx: -8, dy: -8).contains(p)
    }
}
