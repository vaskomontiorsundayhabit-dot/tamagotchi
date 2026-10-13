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
    "gamer": ("крясъците", ["Стига вика на играта! Монтирам!", "Но бях на последното ниво!", "Аз съм на последния кадър!", "Добре, слагам слушалки."]),
    "artist": ("платформите", ["Пак си рисувала върху платформата ми!", "Стана по-красива!", "Беше си хубава и преди!", "Добре, ще рисувам до нея."]),
    "garden": ("пръстта", ["Пак има пръст по пода!", "Това е хубава пръст!", "По пода ли?!", "Добре, ще измета."]),
    "post": ("звънеца", ["Стига звъни на вратата!", "Но имам писмо!", "Пети път днес!", "Добре, ще го пускам в кутията."]),
    "science": ("експлозиите", ["Пак ли гърмя нещо?!", "Беше научно!", "Изгори ми монитора!", "Ще ти купя нов… някой ден."]),
    "dancer": ("тропането", ["Може ли да не тропаш? Монтирам!", "Но това е танц!", "Подът се клати!", "Добре, ще танцувам на пръсти."]),
    "detective": ("разпитите", ["Стига ме разпитва!", "Само още един въпрос…", "Каза го преди час!", "Добре, случаят е затворен."]),
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
    /// Застават в редица един до друг (не един зад друг) и се гледат.
    func startDialog(_ lines: [(String, String)]) {
        dialog = lines
        var ids: [String] = []
        for (who, _) in lines where who != "rat" && !ids.contains(who) { ids.append(who) }
        let pr = petScreenRect()
        let withPet = ids.contains("pet")
        let talkers = ids.compactMap { buddy($0) }
        // центърът: Пиксчо, ако участва; иначе първият, който заговори
        let anchor: CGFloat = withPet ? pr.midX : (talkers.first.map { buddyScreenBox($0).midX } ?? pr.midX)
        var leftEdge = anchor - (withPet ? pr.width / 2 : (talkers.first.map { buddyScreenBox($0).width / 2 } ?? 40))
        var rightEdge = anchor + (withPet ? pr.width / 2 : (talkers.first.map { buddyScreenBox($0).width / 2 } ?? 40))
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        for (n, b) in talkers.enumerated() {
            let w = buddyScreenBox(b).width
            if !withPet && n == 0 { b.wanderX = buddyScreenBox(b).midX; b.nextWander = time + 40; continue }
            // редуват се отляво и отдясно; ако няма място, отиват от другата страна
            var right = n % 2 == 1
            if right && rightEdge + 20 + w > vf.maxX { right = false }
            if !right && leftEdge - 20 - w < vf.minX { right = true }
            if right { b.wanderX = rightEdge + 20 + w / 2; rightEdge += 20 + w }
            else { b.wanderX = leftEdge - 20 - w / 2; leftEdge -= 20 + w }
            b.nextWander = time + 40
        }
        dialogAt = time + 2.5
        dialogCenter = (leftEdge + rightEdge) / 2
        for b in buddies { b.chatting = lines.contains { $0.0 == b.kind.id } }
    }

    /// Докато си говорят: всеки гледа към средата на групата.
    func updateDialogLooks() {
        for b in buddies {
            if b.chatting && !dialog.isEmpty {
                let dx = dialogCenter - buddyScreenBox(b).midX
                b.view.lookX = abs(dx) < 15 ? 0 : (dx > 0 ? 2 : -2)
            } else if b.view.lookX != 0 {
                b.view.lookX = 0
            }
        }
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
        if dialog.isEmpty { buddies.forEach { $0.chatting = false; $0.view.lookX = 0 } }
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
        // спомнят си за последния разговор рядко и само веднъж за тема
        if let t = lastTopic, UserDefaults.standard.string(forKey: "buddyRecalled_\(id)") != t, Int.random(in: 0..<10) < 2 {
            UserDefaults.standard.set(t, forKey: "buddyRecalled_\(id)")
            startDialog([(id, "Помниш ли, като си говорихме за \(t)?"),
                         ("pet", friendly ? "Да! Беше забавно." : "Помня… не ми беше много забавно."),
                         (id, friendly ? "Да си говорим пак!" : "Е, днес ще е по-добре!")])
            changeFriendship(id, 3)
            return
        }
        // тема, за която не са говорили скоро
        // ново от шаблон, за нещо около тях или някоя от готовите теми, за която не са говорили скоро
        let fresh = talkTopics.filter { !recentTopics.contains($0.topic) }
        var topic = (fresh.isEmpty ? talkTopics : fresh).randomElement()!
        let r = Int.random(in: 0..<10)
        if r < 5 { topic = generatedTalk(female: b.kind.female, exclude: [id]) }
        else if r < 7, let st = situationTalk(), !recentTopics.contains(st.topic) { topic = st }
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
        // казва, че монтира, а не монтира: веднага го хващат в лъжа
        if !pet.working && a.lines[0].contains("онтира") {
            let other = buddies.first { $0 !== b && !$0.leaving && !buddyAsleep($0) }
            lines = [("pet", a.lines[0]),
                     (other?.kind.id ?? id, "Ама ти не монтираш! Лъжеш!"),
                     ("pet", "…Ами… мислех си за монтажа."),
                     (id, "Хаха! Хванахме те!"),
                     ("pet", "Добре де, просто ми е шумно.")]
            startDialog(lines)
            changeFriendship(id, -2)
            remember(id, topic: a.topic, fight: false)
            return
        }
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

// --- генератор на разговори: шаблони × думи → десетки хиляди различни разговори ---

let genThings = ["нов монитор", "златен пиксел", "гигантска торта", "летяща чиния", "невидима шапка", "пиксел-ракета",
                 "вълшебен молив", "говорещ кактус", "робот-прахосмукачка", "музикална кутийка", "розов облак", "скейтборд",
                 "телескоп", "балон с хелий", "пиксел-динозавър", "тайна карта", "магнит за пиксели", "шоколадов пиксел",
                 "чадър с крила", "мъничък дракон", "светеща топка", "компас, който сочи към храна", "огромна кутия",
                 "стара дискета", "лъскав бутон", "часовник, който върви назад", "пиксел-пеперуда", "мистериозно писмо"]
let genPlaces = ["на другия монитор", "зад кошчето", "горе при часовника", "в една папка", "на дъното на екрана",
                 "в облака", "при плъха", "върху прозореца на браузъра", "в кошчето", "на Луната", "под цветето",
                 "в ъгъла на екрана", "в менюто горе", "зад тапета", "в една стара снимка", "на най-високата платформа"]
let genFoods = ["жълти пиксели", "розови пиксели", "сирене", "торта", "пуканки", "пиксел-супа", "пица от пиксели",
                "сладолед", "палачинки", "ягоди", "шоколад", "кексчета", "бонбони", "печени ябълки", "палачинки с мед"]
let genActsWe = ["да танцуваме", "да рисуваме", "да строим кула", "да броим звездите", "да пеем", "да играем на криеница",
                 "да снимаме клип", "да готвим", "да правим пикселен снежен човек", "да гоним балони", "да организираме парад",
                 "да построим къщичка", "да тренираме за състезанието", "да пишем песен", "да направим изложба"]
let genDreams = ["летях над екрана", "плувах в море от пиксели", "карах ракета", "пеех на огромна сцена", "ядях торта колкото къща",
                 "яздех динозавър", "бях невидим", "станах кралят на пикселите", "се изгубих в една папка", "говорех с плъха",
                 "намерих съкровище", "бях огромен като монитор"]
let genAdj = ["Страхотно", "Странно", "Смешно", "Страшничко", "Вълшебно", "Невероятно", "Шантаво", "Прекрасно"]
let genAnimals = ["котка", "охлюв", "папагал", "рибка", "куче", "сова", "пеперуда", "костенурка", "делфин", "мравка"]
let genActsI = ["да танцувам", "да рисувам", "да пея", "да скачам", "да ям пиксели", "да строя кули", "да гоня балони",
                "да снимам", "да гледам облаците", "да спя", "да плувам", "да летя"]

private let genTemplates: [(String, [String])] = [
    ("находката", ["Знаеш ли, видях {нещо} {място}!", "Сериозно? И какво правеше там?", "Стоеше си и светеше.", "Утре ще отидем да го видим!"]),
    ("плановете", ["Хайде днес {ние}!", "Само ако после има {храна}.", "Дадено! Аз нося {храна}.", "Тогава съм вътре!"]),
    ("мистерията", ["Някой е скрил {храна} {място}.", "Плъхът!", "Не, този път не е плъхът.", "Тогава е мистерия!"]),
    ("сънищата", ["Снощи сънувах, че {сън}.", "И как беше?", "{прил}! Но после се събудих.", "Тази нощ ще сънуваш продължението."]),
    ("вкусовете", ["Кое е по-хубаво: {храна} или {храна2}?", "{Храна2}, разбира се!", "Не съм съгласн{а}! {Храна}!", "Ще опитаме и двете."]),
    ("слуховете", ["Чух, че {място} има {нещо}.", "Кой ти каза?", "{друг}.", "Значи сигурно е вярно… или не."]),
    ("животните", ["Ако бях {животно}, щях цял ден {аз}.", "А аз щях да спя.", "Ти и сега все спиш!", "Хей!"]),
    ("подаръците", ["Какво да подарим на {друг}?", "{нещо}?", "Добра идея! Къде ще го намерим?", "{място}. Там има всичко."]),
    ("желанията", ["Ако можеше да имаш {нещо}, какво щеше да правиш?", "Щях {аз} цял ден.", "Звучи {прилм}.", "Нали!"]),
    ("днешния ден", ["Днес ми се случи нещо {прилм}.", "Какво?", "Намерих {нещо} {място}!", "Покажи ми после!"]),
    ("рецептите", ["Знаеш ли как се правят {храна}?", "Не. Как?", "Смесваш пиксели и малко магия.", "Утре ще опитам!"]),
    ("скуката", ["Скучно ми е…", "Хайде {ние}!", "Или {ние2}?", "И двете! Първо едното, после другото."]),
    ("приключенията", ["Да отидем {място}?", "Там не е ли страшно?", "Само малко. Ще вземем {нещо}.", "Добре, но аз съм отзад!"]),
    ("изобретенията", ["Ще изобретя {нещо}!", "За какво ще служи?", "За да {аз2} по-бързо!", "Гений!"]),
]

extension Game {
    /// Нов разговор от шаблон: никога не е съвсем същият.
    func generatedTalk(female: Bool, exclude: [String] = []) -> (topic: String, lines: [String]) {
        let t = genTemplates.randomElement()!
        let foods = genFoods.shuffled()
        let acts = genActsWe.shuffled()
        // „кой ти каза?“ — някой друг, не тези, които си говорят
        let others = buddies.filter { !exclude.contains($0.kind.id) }.map { buddyName($0.kind) } + [hasRat ? (ratName ?? "плъхът") : "плъхът"]
        let actI = genActsI.randomElement()!
        let fill: [String: String] = [
            "{нещо}": genThings.randomElement()!, "{място}": genPlaces.randomElement()!,
            "{храна}": foods[0], "{храна2}": foods[1], "{Храна}": foods[0].capitalizedFirst, "{Храна2}": foods[1].capitalizedFirst,
            "{ние}": acts[0], "{ние2}": acts[1], "{сън}": genDreams.randomElement()!, "{прил}": genAdj.randomElement()!,
            "{прилм}": genAdj.randomElement()!.lowercased(), "{животно}": genAnimals.randomElement()!, "{аз}": actI,
            "{аз2}": String(actI.dropFirst(3)), "{друг}": others.randomElement() ?? pet.name, "{а}": female ? "а" : "ен",
        ]
        let lines = t.1.map { line -> String in
            var l = line
            for (k, v) in fill { l = l.replacingOccurrences(of: k, with: v) }
            return l.capitalizedFirst
        }
        return (t.0, lines)
    }

    /// Разговор за истинските неща наоколо: времето, видеата, нивото, цветето, часа.
    func situationTalk() -> (topic: String, lines: [String])? {
        var options: [(String, [String])] = []
        if pet.videos > 0 {
            options.append(("видеата", ["\(pet.name), колко видеа си монтирал вече?", "\(pet.videos)!", "Ехаа, ти си звезда!", "Знам."]))
        }
        options.append(("нивото", ["Ставаш все по-голям! Вече си ниво \(pet.level)!", "Ям си пикселите.", "Личи си!", "Хей!"]))
        if plantStage > 0 {
            options.append(("цветето", ["Видя ли как расте \(plantDefinite(plantStage))?",
                                        "Да! Хвърлям му развалените пиксели.", "И вече има \(plantBlossoms(plantStage)) цвята!",
                                        "Някой ден ще стане огромно дърво."]))
        }
        switch weatherKind {
        case .rain, .storm: options.append(("дъжда", ["Чуваш ли дъжда навън?", "Да, добре че сме вътре.", "Ще направя чай.", "С пиксели!"]))
        case .snow: options.append(("снега", ["Навън вали сняг!", "Да направим пикселен снежен човек!", "Ще ни замръзнат пикселите!", "Ще се стоплим после."]))
        case .clear: options.append(("слънцето", ["Навън е слънчево!", "Тогава защо сме пред компютъра?", "Защото тук има пиксели.", "Вярно."]))
        default: break
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "bg_BG")
        f.dateFormat = "EEEE"
        let day = f.string(from: Date())
        options.append(("деня", ["Днес е \(day).", "Обичам \(day)!", "Ти обичаш всеки ден.", "Защото всеки ден има пиксели!"]))
        return options.randomElement()
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// --- караници между самите приятели ---

private let buddyFightTemplates: [(String, [String])] = [
    ("изядения пиксел", ["Ти ли изяде моя пиксел?!", "Не съм аз!", "Видях те с жълто по устата!", "Добре де… беше много вкусен."]),
    ("мястото", ["Махни се, това е моето място!", "Не е написано твое!", "Аз стоя тук от сутринта!", "Добре, ама утре е мое."]),
    ("музиката", ["Пак ли пускаш тая песен?!", "Тя е най-хубавата!", "Чух я сто пъти днес!", "Сто и един!"]),
    ("играта", ["Ти излъга в гоненицата!", "Не съм! Ти просто не можеш да тичаш!", "Пипнах те три пъти!", "Не се брои!"]),
    ("рисунката", ["Някой стъпка по рисунката ми!", "Не съм аз!", "Има ти следи по краката!", "Ох… извинявай."]),
    ("{нещо}", ["Върни ми {нещо}!", "Какво {нещо}? Нямам такова!", "Сигурно си го скрил{а} {място}!", "Нищо не съм крил{а}!"]),
]

extension Game {
    /// Двама приятели се карат; понякога единият си тръгва сърдит.
    func buddiesArgue(_ a: Buddy, _ b: Buddy) {
        let t = buddyFightTemplates.randomElement()!
        let thing = genThings.randomElement()!, place = genPlaces.randomElement()!
        var lines: [(String, String)] = []
        for (n, l) in t.1.enumerated() {
            let speaker = n % 2 == 0 ? a : b
            let other = n % 2 == 0 ? b : a
            var text = l.replacingOccurrences(of: "{нещо}", with: thing).replacingOccurrences(of: "{място}", with: place)
            text = text.replacingOccurrences(of: "{а}", with: (n % 2 == 0 ? other : speaker).kind.female ? "а" : "")
            lines.append((speaker.kind.id, text.capitalizedFirst))
        }
        // Пиксчо понякога се намесва
        if !pet.asleep && hidePhase == .off && Bool.random() {
            lines.append(("pet", ["Стига сте се карали!", "Хайде, сдобрете се!", "Мир, моля ви!"].randomElement()!))
            lines.append((a.kind.id, ["Добре… мир.", "Само заради теб, \(pet.name)."].randomElement()!))
        } else if Int.random(in: 0..<3) == 0 {
            // единият се сърди и си отива
            b.leaveAt = time + 2.5 + Double(lines.count) * 4
        }
        startDialog(lines)
        a.view.face = .angry
        b.view.face = .angry
    }
}
