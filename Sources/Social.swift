// Компилации, гледания, клиенти, часът на деня, звуци, файлове върху него,
// следене на мишката, приятел и пиксел плъх.

import AppKit

let clientJobs = ["видео за сватба", "реклама за пекарна", "клип за рожден ден", "влог за пътуване",
                  "трейлър за игра", "интервю с котка", "музикален клип за група", "видео за фитнес",
                  "реклама за пица", "клип за абитуриентски бал"]
let fileDropLines = ["Да, да, почвам!", "Ооо, нов материал! Почвам!", "Кой е снимал това? Добре, монтирам!",
                     "Дай да видим… почвам!", "Чудесно! Тъкмо ми беше скучно!", "Хвърли го в таймлайна! Почвам!"]
let friendTalks: [(String, String)] = [
    ("Как върви монтажът?", "Бавно, рендерът пак забива."),
    ("Искаш ли пиксел?", "Винаги!"),
    ("Видя ли новия ми клип?", "Да, сложи повече експлозии."),
    ("Кой е по-жълт, аз или ти?", "Аз, очевидно."),
    ("Да избягаме зад монитора?", "Само ако там има пиксели."),
    ("Днес ще ставаме ли вайръл?", "Ако някой ни гледа…"),
]
let friendJobLines = ["Щрак! Каква светлина!", "Още една от този ъгъл…", "Тази снимка е за корица!",
                      "Не мърдай! Щрак!", "Обективът ми е запотен…", "Фокус… фокус… ЩРАК!", "Ще я пусна в портфолиото!"]
let friendFights: [(String, String)] = [
    ("Ти ми изяде пиксела!", "Не съм! Ти си го изял!"),
    ("Моят клип е по-хубав!", "Хаха, твоят е в 480p!"),
    ("Мести се, тук съм аз!", "Ти се мести!"),
]

// MARK: - Логиката

extension Game {
    // --- звуци ---

    var soundsOn: Bool {
        get { UserDefaults.standard.object(forKey: "soundsOn") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundsOn") }
    }

    @objc func toggleSounds() { soundsOn.toggle() }

    func sfx(_ name: String, every: Double = 0.4) {
        guard soundsOn, window.isVisible, !hideAll else { return }
        if let last = lastSounds[name], time - last < every { return }
        lastSounds[name] = time
        NSSound(named: NSSound.Name(name))?.play()
    }

    // --- компилации и гледания ---

    func createCompilation() {
        var pool = Array(0..<clipTitles.count)
        pool.shuffle()
        pet.compilations.append(Array(pool.prefix(3)))
        if pet.compilations.count > 30 { pet.compilations.removeFirst() }
        // гледанията идват след малко
        let viral = Int.random(in: 0..<100) < 7
        let views = viral ? Int.random(in: 50_000...500_000) : Int.random(in: 40...4_000)
        pendingRatings.append((pet.videos, views, Int(Double(views) * Double.random(in: 0.03...0.09)), viral,
                               time + Double.random(in: 120...300)))
    }

    func updateRatings() {
        guard let i = pendingRatings.firstIndex(where: { time > $0.at }), window.isVisible, !pet.asleep else { return }
        let r = pendingRatings.remove(at: i)
        pet.views += r.views
        let coins = r.viral ? 150 : max(1, r.views / 300)
        earnCoins(coins)
        if r.viral {
            confettiStart = time
            start(.love, length: 3)
            sfx("Hero")
            photoMoment("viral")
            say("СТАНАХ ВАЙРЪЛ! Видео №\(r.video): \(r.views) гледания! +\(coins) монети", seconds: 5)
        } else {
            say("Видео №\(r.video): \(r.views) гледания, \(r.likes) харесвания. +\(coins) монети", seconds: 4)
        }
    }

    // --- клиенти ---

    func updateClients(_ idle: Bool) {
        if let deadline = pet.orderDeadline, Date() > deadline, let job = pet.orderText {
            pet.orderText = nil
            pet.orderDeadline = nil
            pet.orderWorkDone = 0
            pet.orderWorkNeeded = 0
            nextOrder = time + Double.random(in: 10 * 60...20 * 60)
            annoy(20, reason: "изтървах срока на клиента")
            start(.angry, length: 2)
            say("Клиентът е бесен! Изтървах срока за \(job)!", seconds: 4)
            return
        }
        updateLetter()
        guard pet.orderText == nil, letter == nil, idle, time > nextOrder else { return }
        sendLetter()
    }

    /// Готово видео: ако има поръчка в срок, клиентът плаща.
    func completeOrderIfAny() {
        guard let job = pet.orderText, let deadline = pet.orderDeadline, Date() <= deadline else { return }
        earnCoins(pet.orderReward)
        confettiStart = time
        sfx("Glass")
        addXP(30)
        say("Поръчката „\(job)“ е готова! Клиентът е доволен! +\(pet.orderReward) монети", seconds: 4)
        pet.orderText = nil
        pet.orderDeadline = nil
        pet.orderWorkDone = 0
        pet.orderWorkNeeded = 0
        nextOrder = time + Double.random(in: 10 * 60...20 * 60)
    }

    var orderText: String? {
        guard let job = pet.orderText, let d = pet.orderDeadline else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "ПОРЪЧКА: \(job.uppercased()) ДО \(f.string(from: d))"
    }

    // --- часът на деня ---

    func updateDayTalk(_ idle: Bool) {
        guard idle, !pet.working, time > nextDayTalk, bubbleText == nil, dialog.isEmpty else { return }
        // по-рядко, за да не се застъпва с разговорите на приятелите
        nextDayTalk = time + Double.random(in: 70 * 60...120 * 60)
        let c = Calendar.current
        let h = c.component(.hour, from: Date())
        let friday = c.component(.weekday, from: Date()) == 6
        switch h {
        case 6..<10:
            start(.wave, length: 3)
            say("Ааах, протягам се! Хубава сутрин!", seconds: 3)
        case 12..<14:
            say("Обедна почивка! Къде са пикселите?", seconds: 3)
        case 17..<20 where friday:
            confettiStart = time
            start(.wave, length: 4)
            say("Петък вечер! Купон!", seconds: 3)
        case 17..<20:
            say("Почти край на деня…", seconds: 3)
        case 21..<24:
            blinkUntil = time + 1.5
            say("Ааахъм… късно става.", seconds: 3)
        case 0..<5:
            say("Защо още си буден? Утре пак е ден!", seconds: 3.5)
        default:
            break
        }
    }

    // --- файл, пуснат върху него ---

    func fileDropped(_ names: [String]) {
        let name = names.first ?? "файл"
        if pet.dead { return }
        let ext = (name as NSString).pathExtension.lowercased()
        let video = ["mp4", "mov", "m4v", "avi", "mkv"].contains(ext)
        let audio = ["mp3", "wav", "m4a", "aac"].contains(ext)
        if pet.asleep {
            pet.asleep = false
            say("Сега ли?! Добре, добре… ставам.", seconds: 2.5)
        }
        // не е видео или музика: ядосва се
        guard video || audio else {
            annoy(10, reason: "ми даде грешен файл")
            start(.angry, length: 2)
            glitchUntil = time + 0.4
            sfx("Funk", every: 1)
            let lines: [String]
            switch ext {
            case "jpg", "jpeg", "png", "gif", "heic", "webp":
                lines = ["Снимка?! Аз монтирам видео, не албуми!", "Една снимка не е клип! Дай ми .mp4!",
                         "Това е за приятелката, тя е фотографът!"]
            case "pdf", "doc", "docx", "txt", "pages", "rtf":
                lines = ["Документ?! Аз съм монтажист, не счетоводител!", "Не чета, аз монтирам!", "Махни тоя .\(ext)!"]
            case "xls", "xlsx", "csv", "numbers":
                lines = ["Таблица?! Цифри не се монтират!", "Ще ми се завие свят от тия клетки!"]
            case "zip", "rar", "7z", "dmg":
                lines = ["Архив? Разопаковай го сам!", "Какво има вътре? Не искам да знам!"]
            case "":
                lines = ["Папка?! Аз искам файл с видео!", "Какво е това без разширение?!"]
            default:
                lines = ["„.\(ext)“?! Дай ми .mp4, .mov или .mp3!", "Това не е видео! ГРРР!", "С това не мога да монтирам!"]
            }
            say(lines.randomElement()!, seconds: 3.5)
            return
        }
        if isSick { say("Болен съм… но ще го погледна по-късно.", seconds: 3); return }
        start(.love, length: 1.5)
        sfx("Pop")
        anger = (anger - 5).clamped()
        let happy = audio
            ? ["Музика! Ще я сложа за фон!", "Ооо, какъв бийт! Монтирам по него!", "„\(name)“ ще звучи страхотно в клипа!"]
            : (ext == "mov" ? ["О, .mov! Направо от камерата! Почвам!", "Качествен материал! Обичам .mov!"]
                : ["Видео! Ура! Почвам!", "Ооо, нов материал! Почвам!", "Кой е снимал това? Добре, монтирам!"])
        if pet.working {
            say(audio ? "Слагам „\(name)“ за музика в таймлайна!" : "Добавям „\(name)“ в таймлайна!", seconds: 3)
            return
        }
        say(happy.randomElement()!, seconds: 3)
        toggleWork()
    }
}
