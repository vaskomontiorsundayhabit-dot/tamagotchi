// Разговори на няколко реплики между Пиксчо и приятелите (и между самите приятели).
// Помнят за какво са си говорили и дали са се карали.

import AppKit

let buddyIdleLines = ["Гледам облаците…", "Правя упражнения! Едно, две…", "Чета книжка.", "Тананикам си.",
                      "Броя пикселите по пода.", "Почивам си малко.", "Мисля си за пиксели.", "Ох, хубаво място е тук."]

/// Общи разговори: тема и реплики (първата е на приятеля, после редуват с Пиксчо).
let talkTopics: [(topic: String, lines: [String])] = [
    ("времето", ["Видя ли какво е времето навън?", "Да! Затова си стоя вътре.", "Аз пък искам да изляза.", "Вземи ми пиксел, като излизаш."]),
    ("пикселите", ["Кой е най-вкусният цвят пиксел?", "Жълтият, очевидно.", "Не, розовият!", "Ще трябва да ги опитаме пак."]),
    ("клиентите", ["Как върви монтажът?", "Клиентът иска още експлозии.", "Пак ли?", "Винаги искат още експлозии."]),
    ("сънищата", ["Какво сънува снощи?", "Валяха пиксели!", "Аз сънувах, че съм огромна!", "Някой ден ще бъдеш."]),
    ("купона", ["Да направим купон довечера?", "Ако има торта, да!", "Ще има и музика!", "Тогава съм вътре!"]),
    ("плъха", ["Плъхчето пак ли е гладно?", "Винаги е гладно.", "Като теб.", "Хей!"]),
    ("рисунките", ["Тези платформи ти ли ги нарисува?", "Не, някой друг рисува тук…", "Мистерия!", "Пиксел-призраци."]),
]

/// Какво дразни Пиксчо във всяка професия: (тема, реплики, като първата е на Пиксчо).
let annoyances: [String: (topic: String, lines: [String])] = [
    "music": ("шума", ["Може ли по-тихо? Монтирам!", "Но това е новата ми песен!", "Слушам я за десети път!", "Добре де… ще свиря по-тихо."]),
    "photo": ("снимките", ["Спри да ме снимаш в лицето!", "Но светлината е перфектна!", "Виждам само звезди!", "Добре, последна снимка."]),
    "chef": ("кухнята", ["Пак си разхвърляла навсякъде!", "Готвя изкуство!", "Изкуство с трохи навсякъде!", "Ще почистя… утре."]),
    "gamer": ("крясъците", ["Стига вика на играта!", "Но бях на последното ниво!", "Аз съм на последния кадър!", "Добре, слагам слушалки."]),
    "artist": ("платформите", ["Пак си рисувала върху платформата ми!", "Стана по-красива!", "Беше си хубава и преди!", "Добре, ще рисувам до нея."]),
]

extension Game {
    func buddyFriendship(_ id: String) -> Int {
        UserDefaults.standard.object(forKey: "buddyFriend_\(id)") as? Int ?? 60
    }

    func changeFriendship(_ id: String, _ d: Int) {
        UserDefaults.standard.set(max(0, min(100, buddyFriendship(id) + d)), forKey: "buddyFriend_\(id)")
    }

    func remember(_ id: String, topic: String, fight: Bool) {
        UserDefaults.standard.set(topic, forKey: "buddyTopic_\(id)")
        UserDefaults.standard.set(fight, forKey: "buddyFight_\(id)")
    }

    /// Пуска разговор: (кой: "pet" или id на приятел, реплика).
    func startDialog(_ lines: [(String, String)]) {
        dialog = lines
        dialogAt = time
        for b in buddies { b.chatting = lines.contains { $0.0 == b.kind.id } }
    }

    func updateDialog() {
        guard !dialog.isEmpty, time >= dialogAt else { return }
        let (who, text) = dialog.removeFirst()
        if who == "pet" {
            if !pet.asleep && hidePhase == .off { say(text, seconds: 2.8) }
        } else if let b = buddy(who) {
            buddySay(b, text, 2.8)
        }
        dialogAt = time + 3
        if dialog.isEmpty { buddies.forEach { $0.chatting = false } }
    }

    /// Разговор с Пиксчо: понякога си спомнят за последния, ако са се карали, се сдобряват.
    func buddyConversation(_ b: Buddy) {
        let id = b.kind.id
        let lastTopic = UserDefaults.standard.string(forKey: "buddyTopic_\(id)")
        let lastFight = UserDefaults.standard.bool(forKey: "buddyFight_\(id)")
        let friendly = buddyFriendship(id) >= 50
        if let t = lastTopic, lastFight {
            // помнят, че са се скарали за това
            startDialog([(id, "Още ли ми се сърдиш за \(t)?"),
                         ("pet", friendly ? "Малко… но мина." : "Да! Още ми е криво."),
                         (id, friendly ? "Мир?" : "Хайде де, съжалявам."),
                         ("pet", friendly ? "Мир!" : "…Добре. Мир.")])
            changeFriendship(id, 15)
            remember(id, topic: t, fight: false)
            pendingMakeUp = time + 12
            return
        }
        if let t = lastTopic, Int.random(in: 0..<10) < 4 {
            startDialog([(id, "Помниш ли, като си говорихме за \(t)?"),
                         ("pet", friendly ? "Да! Беше забавно." : "Помня… не ми беше много забавно."),
                         (id, friendly ? "Да си говорим пак!" : "Е, днес ще е по-добре!")])
            changeFriendship(id, 3)
            return
        }
        let topic = talkTopics.randomElement()!
        var lines: [(String, String)] = []
        for (n, l) in topic.lines.enumerated() { lines.append((n % 2 == 0 ? id : "pet", l)) }
        startDialog(lines)
        changeFriendship(id, 4)
        remember(id, topic: topic.topic, fight: false)
    }

    /// Пиксчо се дразни от нещо и се карат.
    func buddyArgument(_ b: Buddy) {
        let id = b.kind.id
        guard let a = annoyances[id] else { buddyConversation(b); return }
        var lines: [(String, String)] = []
        for (n, l) in a.lines.enumerated() { lines.append((n % 2 == 0 ? "pet" : id, l)) }
        startDialog(lines)
        start(.angry, length: 2)
        b.view.face = .angry
        changeFriendship(id, -12)
        remember(id, topic: a.topic, fight: true)
        annoy(5, reason: "\(buddyName(b.kind)) ме ядоса с \(a.topic)")
    }
}
