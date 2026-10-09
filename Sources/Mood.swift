// Запазване на настроението (ядосване, желание, кафе, въпрос), за да не се губи
// при обновяване или рестарт. И разместването на пикселите след 250.

import AppKit

struct Mood: Codable {
    var anger: Double = 0
    var angerReason: String?
    var drunkLeft: Double = 0
    var coffeeAgo: [Double] = []
    var want: String?
    var wantAge: Double = 0
    var unanswered: Int?
    var enclosed = false
    var saved = Date()
}

/// Цветове, през които минава след 250 пиксела (първият е обичайният жълт).
let bodyColors = [0xffd23f, 0xff924c, 0xff8fab, 0x52d1dc, 0x8ac926, 0xc77dff, 0x48cae4, 0xf15bb5, 0xffca3a, 0x6a994e]

/// Кеш на формите: след 250 пиксела всяко ниво размества пикселите по нов начин.
var blobCache: [Int: [(Int, Int)]] = [0: blobOrder]

func shapeOrder(variant: Int) -> [(Int, Int)] {
    if let c = blobCache[variant] { return c }
    let order = makeBlobOrder(8 + 250 + 6, seed: variant)
    blobCache[variant] = order
    return order
}

func encodeWant(_ w: Want) -> String {
    switch w {
    case .color(let c): return "color:\(c)"
    case .play: return "play"
    case .coffee: return "coffee"
    case .pet: return "pet"
    case .platform: return "platform"
    case .work: return "work"
    case .draw(let s): return "draw:\(s)"
    case .buy(let s): return "buy:\(s)"
    }
}

func decodeWant(_ s: String) -> Want? {
    let parts = s.split(separator: ":", maxSplits: 1).map(String.init)
    switch parts[0] {
    case "color": return parts.count > 1 ? Int(parts[1]).map { .color($0) } : nil
    case "play": return .play
    case "coffee": return .coffee
    case "pet": return .pet
    case "platform": return .platform
    case "work": return .work
    case "draw": return parts.count > 1 ? .draw(parts[1]) : nil
    case "buy": return parts.count > 1 ? .buy(parts[1]) : nil
    default: return nil
    }
}

extension Game {
    /// Вариант на формата и цвета след 250 пиксела.
    var bodyVariant: Int { max(0, pet.level - 250) }
    var bodyColor: Int { bodyColors[bodyVariant % bodyColors.count] }

    func saveMood() {
        var m = Mood()
        m.anger = anger
        m.angerReason = angerReason
        m.drunkLeft = max(0, drunkUntil - time)
        m.coffeeAgo = coffeeTimes.map { time - $0 }
        if let w = want { m.want = encodeWant(w); m.wantAge = time - wantSince }
        m.unanswered = unansweredQuestion
        m.enclosed = enclosed
        if let data = try? JSONEncoder().encode(m) { UserDefaults.standard.set(data, forKey: "mood") }
    }

    func loadMood() {
        guard let data = UserDefaults.standard.data(forKey: "mood"),
              let m = try? JSONDecoder().decode(Mood.self, from: data) else { return }
        // колкото повече време е минало, толкова повече е отминало
        let away = Date().timeIntervalSince(m.saved)
        anger = max(0, m.anger - away / 60 * 3)
        angerReason = m.angerReason
        angerReasonTime = time
        drunkUntil = time + max(0, m.drunkLeft - away)
        coffeeTimes = m.coffeeAgo.map { time - $0 - away }.filter { time - $0 < 60 * 60 }
        if let s = m.want, let w = decodeWant(s), away < 20 * 60 {
            want = w
            wantSince = time - m.wantAge - away
            lastWantNag = time
        }
        unansweredQuestion = m.unanswered
        enclosed = m.enclosed
    }
}

// MARK: - Още реплики

let moreIdleLines = [
    "Мисля да си направя канал за ASMR с пиксели.",
    "Днес ще бъда продуктивен. След малко.",
    "Пикселите ми блестят днес, нали?",
    "Ако бях видео, щях да съм в 60fps.",
    "Някой ден ще монтирам филм за Оскар.",
    "Обичам звука на клавиатурата ти.",
    "Колко прозореца имаш отворени? Много са.",
    "Този курсор пак ме гони.",
    "Чудя се какво има зад десктопа.",
    "Видях бъг. Беше сладък.",
    "Аз съм малък, но амбициозен.",
    "Ще ми купиш ли шапка някой ден?",
    "Знаеш ли, че имам и чувства? Пикселни.",
    "Днес ми е ден за експорт.",
    "Тихо е… прекалено тихо.",
    "Хайде да гледаме клип заедно.",
    "Искам да скоча на онзи прозорец.",
    "Ти работиш, аз работя, всички работим.",
    "Понякога сънувам в 8 бита.",
    "Тренирам за олимпийски скок от прозорци.",
    "Ако ме преместиш, ще се сърдя. Малко.",
    "Брой ми пикселите, ако можеш.",
    "Чувствам се като рендер на 50%.",
    "Тук живея, тук монтирам, тук ям.",
    "Пак ли е понеделник? Винаги е понеделник.",
]
let moreEditingLines = [
    "Цветокорекция: жълто. Винаги жълто.",
    "Тоя кадър е разфокусиран. Не, аз съм.",
    "Добавям 47-ми слой. Всичко е под контрол.",
    "Кой е сложил музика с 3 минути интро?",
    "Режа тишината. Много тишина.",
    "Таймлайнът прилича на дъга.",
    "Ще кача ли днес? Ще кача. Може би.",
    "Монтажът е като пъзел без картинка.",
    "Клиентът каза „финалната“ за пети път.",
    "Рендерът ще свърши, когато свърши.",
]
let moreHappyLines = ["Обичам те, човеко!", "Ти си моят любим потребител!", "Хиии!", "Ощеее!", "Гъди-гъди!"]
let moreAngryLines = ["Аз съм уморен пиксел!", "ЗЗЗ… не, будя се и съм ядосан.", "Ще те докладвам на ъпдейта!"]
