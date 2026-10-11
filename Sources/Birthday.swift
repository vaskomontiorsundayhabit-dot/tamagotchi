// Рожденият ден на Пиксчо: парти шапка, торта със свещички (цъкни, за да ги духне),
// подарък, приятелите идват и пеят.

import AppKit

final class CakeView: NSView {
    weak var game: Game?
    var candles = 1
    var blown = false
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.blowCandles() }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let b = bounds
        let base = NSRect(x: 8, y: b.height - 34, width: b.width - 16, height: 30)
        NSColor(hex: 0xff8fab).setFill(); base.fill()
        NSColor(hex: 0xffffff).setFill()
        NSRect(x: base.minX, y: base.minY, width: base.width, height: 6).fill()
        NSColor(hex: 0xe63946).setFill()
        var x = base.minX + 4
        while x < base.maxX - 4 { NSRect(x: x, y: base.minY + 14, width: 4, height: 4).fill(); x += 10 }
        NSColor(hex: 0x8d99ae).setFill()
        NSRect(x: 2, y: b.height - 4, width: b.width - 4, height: 4).fill()
        let n = min(9, max(1, candles))
        let gap = (base.width - 8) / CGFloat(n)
        for i in 0..<n {
            let cx = base.minX + 4 + gap * (CGFloat(i) + 0.5)
            NSColor(hex: [0x48cae4, 0xffd166, 0x52b788][i % 3]).setFill()
            NSRect(x: cx - 2, y: base.minY - 14, width: 4, height: 14).fill()
            if !blown {
                let flick = CGFloat(sin(game.time * 12 + Double(i))) * 1.5
                NSColor(hex: 0xf4a261).setFill()
                NSRect(x: cx - 2 + flick, y: base.minY - 22, width: 4, height: 7).fill()
                NSColor(hex: 0xffd166).setFill()
                NSRect(x: cx - 1 + flick, y: base.minY - 20, width: 2, height: 4).fill()
            } else if game.time - game.cakeBlownAt < 3 {
                NSColor(white: 0.8, alpha: 0.6).setFill()
                NSRect(x: cx - 1, y: base.minY - 22 - CGFloat(game.time - game.cakeBlownAt) * 8, width: 3, height: 5).fill()
            }
        }
        if !blown {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .heavy),
                                                    .foregroundColor: NSColor.white]
            NSColor(hex: 0x1b1b24, alpha: 0.85).setFill()
            NSRect(x: 0, y: 0, width: b.width, height: 12).fill()
            ("ЦЪКНИ: ДУХНИ" as NSString).draw(at: NSPoint(x: 4, y: 1), withAttributes: a)
        }
    }
}

extension Game {
    var birthday: Date {
        get { UserDefaults.standard.object(forKey: "birthday") as? Date ?? pet.born }
        set { UserDefaults.standard.set(newValue, forKey: "birthday") }
    }

    var isBirthdayToday: Bool {
        let c = Calendar.current
        let a = c.dateComponents([.month, .day], from: birthday), b = c.dateComponents([.month, .day], from: Date())
        return a.month == b.month && a.day == b.day
    }

    var petAge: Int {
        max(0, Calendar.current.dateComponents([.year], from: pet.born, to: Date()).year ?? 0)
    }

    var birthdayHat: Bool { isBirthdayToday && !pet.dead }

    /// Веднъж годишно, на рождения ден: празненство.
    func updateBirthday() {
        if let p = cakePanel {
            p.contentView?.needsDisplay = true
            if cakeBlown && time - cakeBlownAt > 90 { p.orderOut(nil); cakePanel = nil }
        }
        guard time > nextBirthdayCheck else { return }
        nextBirthdayCheck = time + 60
        guard isBirthdayToday, !pet.dead, !pet.asleep, window.isVisible, hidePhase == .off else { return }
        let year = Calendar.current.component(.year, from: Date())
        if UserDefaults.standard.integer(forKey: "birthdayYear") == year {
            // през деня от време на време се хвали
            if Int.random(in: 0..<25) == 0 && bubbleText == nil {
                say(["Днес ми е рожден ден!", "Някой да ми каже „честит рожден ден“!", "Аз съм рожденикът!"].randomElement()!, seconds: 3)
            }
            return
        }
        UserDefaults.standard.set(year, forKey: "birthdayYear")
        celebrateBirthday()
    }

    func celebrateBirthday() {
        let age = petAge
        confettiStart = time
        sfx("Hero")
        start(.wave, length: 5)
        say(age == 0 ? "ДНЕС МИ Е ПЪРВИЯТ РОЖДЕН ДЕН!" : "ЧЕСТИТ РОЖДЕН ДЕН НА МЕН! Навърших \(age)!", seconds: 5)
        showAlert("ЧЕСТИТ РОЖДЕН ДЕН!", pet.name.uppercased(), happy: true)
        earnCoins(100)
        addXP(50)
        // торта със свещички
        let pr = petScreenRect()
        let s = NSSize(width: 90, height: 66)
        let x = pr.midX + (facingLeft ? -pr.width / 2 - 100 : pr.width / 2 + 10)
        let p = overlayPanel(NSRect(x: x, y: floorY, width: s.width, height: s.height), key: false)
        p.level = .floating
        let v = CakeView(frame: NSRect(origin: .zero, size: s))
        v.game = self
        v.candles = max(1, age)
        p.contentView = v
        p.orderFrontRegardless()
        cakePanel?.orderOut(nil)
        cakePanel = p
        cakeBlown = false
        // приятелите идват и пеят
        for k in buddyKinds where joinedBuddies.contains(k.id) { UserDefaults.standard.removeObject(forKey: "buddyAway_\(k.id)") }
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        if let k = buddyKinds.first(where: { !joinedBuddies.contains($0.id) && buddy($0.id) == nil
            && UserDefaults.standard.integer(forKey: "buddyVisits_\($0.id)") > 0 }) {
            arriveAsGuest(k, vf: vf)
        }
        var song: [(String, String)] = []
        for b in buddies.prefix(3) { song.append((b.kind.id, ["Честит рожден ден, \(pet.name)!", "Много здраве и пиксели!", "Ура за рожденика!"].randomElement()!)) }
        song.append(("pet", "Благодаря ви! Обичам ви!"))
        dialog = song
        dialogAt = time + 4
        if hasRat { ratSay("Цик-цик-честит-цик!", 3) }
    }

    func blowCandles() {
        guard let v = cakePanel?.contentView as? CakeView, !v.blown else { return }
        v.blown = true
        cakeBlown = true
        cakeBlownAt = time
        sfx("Pop")
        start(.love, length: 3)
        lastFoodColor = 0xff8fab
        pet.fullness = (pet.fullness + 30).clamped()
        pet.fun = (pet.fun + 30).clamped()
        say("Фууу! Духнах ги всичките! Пожелах си… тайна!", seconds: 3.5)
        for b in buddies { buddySay(b, "Ураааа!", 2) }
        v.needsDisplay = true
    }

    /// Показва рождения ден и дава да се смени.
    func birthdayInfo() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        let f = DateFormatter()
        f.dateFormat = "d.MM"
        alert.messageText = "Рожденият ден на \(pet.name) е на \(f.string(from: birthday))"
        alert.informativeText = "Тогава има торта, парти шапка, подарък и гости. Можеш да смениш датата:"
        let picker = NSDatePicker(frame: NSRect(x: 0, y: 0, width: 160, height: 24))
        picker.datePickerStyle = .textFieldAndStepper
        picker.datePickerElements = .yearMonthDay
        picker.dateValue = birthday
        alert.accessoryView = picker
        alert.addButton(withTitle: "Запази")
        alert.addButton(withTitle: "Отказ")
        if alert.runModal() == .alertFirstButtonReturn {
            birthday = picker.dateValue
            UserDefaults.standard.removeObject(forKey: "birthdayYear")
            nextBirthdayCheck = 0
            say(isBirthdayToday ? "Днес?! Тогава ПАРТИ!" : "Записах си рождения ден!", seconds: 3)
        }
    }
}
