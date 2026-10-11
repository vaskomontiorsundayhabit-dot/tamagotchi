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
    ("часа", ["Колко е часът?", "{час}. Защо?", "Време ли е за пиксели?", "Винаги е време за пиксели!"]),
    ("филмите", ["Кой е любимият ти филм?", "Онзи с гигантския пиксел!", "Гледах го пет пъти.", "Аз заспах по средата."]),
    ("ваканцията", ["Къде би отишъл на почивка?", "На другия монитор!", "Там е по-светло ли?", "И има повече прозорци."]),
    ("суперсилите", ["Ако имаше суперсила, каква щеше да е?", "Да рендерирам за секунда!", "Аз бих летяла.", "Ти и без това скачаш високо."]),
    ("готвенето", ["Можеш ли да готвиш?", "Пържени пиксели. Само това.", "Звучи хрупкаво.", "Ела утре, ще ти направя."]),
    ("музиката", ["Каква музика слушаш?", "Пиксел-рок!", "Аз обичам тиха музика.", "Тогава ще слушаме на ниско."]),
    ("спомените", ["Помниш ли първия ни ден тук?", "Беше страшно, всичко беше празно.", "А сега има толкова неща!", "И приятели!"]),
    ("мечтите", ["За какво мечтаеш?", "За монитор колкото стена.", "Аз за огромна торта.", "Звучи като добър план."]),
    ("модата", ["Харесва ли ти шапката ми?", "Много ти отива!", "Наистина ли?", "Е, малко е странна, но е хубава."]),
    ("животните", ["Какво животно би бил?", "Котка. Спи по цял ден.", "Аз охлюв, бавно и спокойно.", "Аз пък плъх, за сиренето!"]),
    ("игрите", ["Коя игра ти е любима?", "Гоненицата!", "Аз обичам балона.", "Да поиграем после!"]),
    ("шегите", ["Знаеш ли виц?", "Защо пикселът отиде на лекар? Беше размазан!", "Хахаха!", "Това беше ужасно. Разкажи още!"]),
    ("утрото", ["Ти ставаш ли рано?", "Само ако има кафе.", "Аз се будя с птичките.", "Тук няма птички… има папагал!"]),
    ("тайните", ["Мога ли да ти кажа тайна?", "Разбира се!", "Понякога ям пиксели насън.", "Всички го правим."]),
    ("работата", ["Уморително ли е да монтираш?", "Понякога, но обичам да е готово.", "А аз обичам да гледам.", "Значи сме добър екип."]),
]

/// Когато и други се включат в разговора.
let groupInterjections = ["Аз също!", "Сериозно ли?", "Не знаех!", "Разкажете ми повече!", "Хи-хи!", "Точно това си мислех!",
                          "А аз пък…", "Ей, не ме забравяйте!", "И аз така мисля!", "Хаха, точно!", "Не съм съгласна!", "Аз пък мисля другояче…", "Ооо, интересно!",
                          "Може ли и аз да кажа нещо?", "Вие двамата сте смешни!", "Кой иска пиксел?", "Чакайте, за какво говорим?"]

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
        // събират се близо: първо се приближават, после говорят
        let ids = Set(lines.map { $0.0 })
        let pr = petScreenRect()
        let anchor: CGFloat = ids.contains("pet") ? pr.midX : (buddy(lines.first?.0 ?? "").map { buddyScreenBox($0).midX } ?? pr.midX)
        var n = 0
        for b in buddies where ids.contains(b.kind.id) {
            let side: CGFloat = n % 2 == 0 ? -1 : 1
            let dist: CGFloat = ids.contains("pet") ? pr.width / 2 + 60 + CGFloat(n / 2) * 90 : 70 + CGFloat(n / 2) * 90
            if !(lines.first?.0 == b.kind.id && !ids.contains("pet")) {
                b.wanderX = anchor + side * dist
            }
            b.nextWander = time + 40
            n += 1
        }
        dialogAt = time + 2.5
        for b in buddies { b.chatting = lines.contains { $0.0 == b.kind.id } }
    }

    func updateDialog() {
        guard !dialog.isEmpty, time >= dialogAt else { return }
        let (who, raw) = dialog.removeFirst()
        // {час} → истинския час
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let text = raw.replacingOccurrences(of: "{час}", with: f.string(from: Date()))
        if who == "rat" {
            if ratIsOut { ratSay(text, 2.8) }
        } else if who == "pet" {
            if !pet.asleep && hidePhase == .off { say(text, seconds: 2.8) }
        } else if let b = buddy(who) {
            buddySay(b, text, 2.8)
        } else if !pet.asleep && hidePhase == .off {
            // този, който трябваше да отговори, го няма: отговаря Пиксчо
            say(text, seconds: 2.8)
        }
        dialogAt = time + readTime(text, 3) + 0.4
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
        // тема, за която не са говорили скоро
        let fresh = talkTopics.filter { !recentTopics.contains($0.topic) }
        let topic = (fresh.isEmpty ? talkTopics : fresh).randomElement()!
        recentTopics.append(topic.topic)
        if recentTopics.count > 8 { recentTopics.removeFirst() }
        var lines: [(String, String)] = []
        for (n, l) in topic.lines.enumerated() { lines.append((n % 2 == 0 ? id : "pet", l)) }
        // всички, които са наоколо, се включват
        let others = buddies.filter { $0 !== b && !$0.leaving && !buddyAsleep($0) }.map { $0.kind.id }
        for (n, o) in others.prefix(3).enumerated() {
            let at = min(lines.count, 2 + n * 2)
            lines.insert((o, groupInterjections.randomElement()!), at: at)
        }
        if ratIsOut && Bool.random() { lines.append(("rat", ["Цик!", "Цик-цик! (и аз!)", "Цик? Цик."].randomElement()!)) }
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
        // след караницата си отива сърдит(а) до вкъщи
        b.leaveAt = time + 2.5 + Double(lines.count) * 4
        start(.angry, length: 2)
        b.view.face = .angry
        changeFriendship(id, -12)
        remember(id, topic: a.topic, fight: true)
        annoy(5, reason: "\(buddyName(b.kind)) ме ядоса с \(a.topic)")
    }
}
