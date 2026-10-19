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
            (4, "swing", "Някой върза люлка на клона", "Някой ми върза ЛЮЛКА на клона! Кой ли ще се люлее?"),
            (7, "fireflies", "Светулки нощуват в короната", "Нощем в короната ми вече светят СВЕТУЛКИ!"),
            (11, "treehouse", "На дървото се появи къщичка", "На ствола ми някой построи КЪЩИЧКА! С прозорче и покрив!"),
            (16, "ancient", "Стана вековно дърво", "Вече съм ВЕКОВНО ДЪРВО. Короната ми е най-голямата в квартала."),
        ]
        for s in steps where y >= s.0 && !hasAge(s.1) && userActive {
            d.set(true, forKey: "pot_age_" + s.1)
            discover("age_" + s.1, s.2)
            announce(s.3, 5)
            break
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
}
