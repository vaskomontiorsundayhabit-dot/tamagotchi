// Живот и смърт: всичко живо остарява и може да умре, ако никой не се грижи за него.
// Любимците живеят определен брой дни; гладни дълго — умират. Цветето изсъхва без вода.
// Развалените пиксели изгниват и изчезват. Приятел, с когото сте скарани, се мести завинаги.
// Отлетялото духче и „Спомени“ (десен бутон на иконката горе) пазят паметта за тях.

import AppKit

let ghostGrid = grid([
    "..WWWW..",
    ".WWWWWW.",
    "WWKWWKWW",
    "WWKWWKWW",
    "WWWWWWWW",
    "WWWKKWWW",
    "WWWWWWWW",
    "W.WW.WW.",
])

final class GhostView: NSView {
    var start: Double = 0
    var happy = false
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let k = CGFloat(min(1, (game.time - start) / 4))
        let alpha = 1 - k
        let y = bounds.height - 30 - k * (bounds.height - 40)
        if happy {
            // тръгва си щастливо: сърца
            for i in 0..<3 {
                drawGrid(heartGrid, x: bounds.midX - 20 + CGFloat(i) * 14, y: y - CGFloat(i % 2) * 10, s: 2.5,
                         palette: { c in game.color(c)?.withAlphaComponent(alpha) })
            }
            return
        }
        let wob = CGFloat(sin(game.time * 5)) * 4
        drawGrid(ghostGrid, x: bounds.midX - 12 + wob, y: y, s: 3, palette: { c in
            c == "W" ? NSColor(white: 1, alpha: alpha * 0.85) : NSColor(hex: 0x2b2b3a).withAlphaComponent(alpha)
        })
    }
}

extension Game {
    // --- духчета и спомени ---

    func spawnGhost(at p: NSPoint, happy: Bool) {
        let size = NSSize(width: 70, height: 160)
        let panel = overlayPanel(NSRect(x: p.x - size.width / 2, y: p.y, width: size.width, height: size.height), key: false)
        panel.ignoresMouseEvents = true
        let v = GhostView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        v.start = time
        v.happy = happy
        panel.contentView = v
        panel.orderFrontRegardless()
        ghosts.append(panel)
        sfx(happy ? "Glass" : "Submarine")
    }

    func updateGhosts() {
        for g in ghosts { g.contentView?.needsDisplay = true }
        let done = ghosts.filter { ($0.contentView as? GhostView).map { time - $0.start > 4.2 } ?? true }
        for g in done { g.orderOut(nil) }
        ghosts.removeAll { g in done.contains { $0 === g } }
    }

    var memorials: [[String: Any]] {
        get { UserDefaults.standard.array(forKey: "memorials") as? [[String: Any]] ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "memorials") }
    }

    func addMemorial(_ text: String) {
        var m = memorials
        m.append(["text": text, "t": Date().timeIntervalSince1970])
        if m.count > 50 { m.removeFirst(m.count - 50) }
        memorials = m
    }

    @objc func showMemorials() {
        NSApp.activate(ignoringOtherApps: true)
        let f = DateFormatter()
        f.dateFormat = "d.MM.yyyy"
        let lines = memorials.reversed().prefix(20).map { m -> String in
            let d = Date(timeIntervalSince1970: m["t"] as? Double ?? 0)
            return "\(f.string(from: d)) · \(m["text"] as? String ?? "")"
        }
        let alert = NSAlert()
        alert.messageText = "Спомени"
        alert.informativeText = lines.isEmpty ? "Още никой не си е отишъл. Всички са живи и здрави!" : lines.joined(separator: "\n")
        alert.runModal()
    }

    /// Златен пиксел (подарък): блести в злато 10 минути, двоен опит.
    func goldenPixelEaten() {
        goldUntil = time + 10 * 60
        confettiStart = time
        sfx("Hero")
        say("ЗЛАТЕН СЪМ! 10 минути двоен опит! +40 опит", seconds: 3.5)
        addXP(40)
    }

    // --- колко живеят ---

    /// Дни живот за всеки вид (определя се веднъж, при раждането).
    private func lifespanDays(_ id: String) -> Double {
        let key = "life_\(id)"
        if let d = UserDefaults.standard.object(forKey: key) as? Double { return d }
        let ranges: [String: ClosedRange<Double>] = ["cat": 40...70, "dog": 50...80, "snail": 12...25, "fish": 15...35,
                                                     "parrot": 60...100, "rat": 50...90]
        let d = Double.random(in: ranges[id] ?? 30...60)
        UserDefaults.standard.set(d, forKey: key)
        return d
    }

    private func bornDate(_ id: String) -> Date {
        let key = "born_\(id)"
        if let d = UserDefaults.standard.object(forKey: key) as? Date { return d }
        UserDefaults.standard.set(Date(), forKey: key)
        return Date()
    }

    private func forgetLife(_ id: String) {
        for k in ["life_\(id)", "born_\(id)", "petFed_\(id)", "petName_\(id)", "petX_\(id)", "lifeWarn_\(id)"] {
            UserDefaults.standard.removeObject(forKey: k)
        }
    }

    /// Любимец умира: духче, спомен, Пиксчо е тъжен; изчезва от къщата.
    private func petDies(_ id: String, label: String, at p: NSPoint?, oldAge: Bool, days: Int) {
        if let p { spawnGhost(at: p, happy: false) }
        addMemorial(oldAge ? "\(label.capitalizedFirst) почина от старост (\(days) дни)" : "\(label.capitalizedFirst) почина от глад (\(days) дни)")
        pet.owned.removeAll { $0 == id }
        pet.disabled.removeAll { $0 == id }
        forgetLife(id)
        pet.fun = (pet.fun - 25).clamped()
        if !pet.asleep {
            say(oldAge ? "Сбогом, \(label)… Живя дълго и щастливо. Ще ми липсваш." : "Не! \(label.capitalizedFirst)… Забравихме да го храним…",
                seconds: 4.5)
        }
        save()
    }

    func updateLifecycle() {
        guard time > nextLifeCheck, !pet.dead else { return }
        nextLifeCheck = time + 60
        if !lifeStarted {
            // докато програмата е била спряна, гладът се брои най-много 6 часа (иначе след уикенд всички биха умрели)
            lifeStarted = true
            let floorDate = Date().addingTimeInterval(-6 * 3600)
            for k in smallPetKinds where pet.owned.contains(k.id) && smallPetFedAt(k.id) < floorDate {
                UserDefaults.standard.set(floorDate, forKey: "petFed_\(k.id)")
            }
            if ratFedAt < floorDate { ratFedAt = floorDate }
        }

        // любимците: старост и глад
        for k in smallPetKinds where pet.owned.contains(k.id) {
            let born = bornDate(k.id)
            let days = Date().timeIntervalSince(born) / 86400
            let life = lifespanDays(k.id)
            let hungryH = smallPetHungry(k.id) / 60
            let label = smallPetLabel(k)
            let p = smallPet(k.id)?.panel.frame
            let at = p.map { NSPoint(x: $0.midX, y: $0.minY + 10) }
            if days > life { petDies(k.id, label: label, at: at, oldAge: true, days: Int(days)); continue }
            if hungryH > 20 { petDies(k.id, label: label, at: at, oldAge: false, days: Int(days)); continue }
            if (hungryH > 10 || days > life - 2) && !pet.asleep && time > nextLifeWarn {
                nextLifeWarn = time + 30 * 60
                say(hungryH > 10 ? "\(label.capitalizedFirst) е много гладно и отслабва! Нахрани го!" : "\(label.capitalizedFirst) вече е много старо… спи все повече.",
                    seconds: 3.5)
            }
        }

        // плъхът
        if pet.owned.contains("rat") {
            let days = Date().timeIntervalSince(bornDate("rat")) / 86400
            let life = lifespanDays("rat")
            let at = ratPanel.map { NSPoint(x: $0.frame.midX, y: $0.frame.minY + 10) }
            if days > life || ratHungryMinutes > 24 * 60 {
                let old = days > life
                carryingRat = false
                petDies("rat", label: ratLabel, at: at, oldAge: old, days: Int(days))
                UserDefaults.standard.removeObject(forKey: "ratName")
            } else if ratHungryMinutes > 12 * 60 && !pet.asleep && time > nextLifeWarn {
                nextLifeWarn = time + 30 * 60
                say("\(ratLabel.capitalizedFirst) е от много време гладен! Ако не яде, ще умре!", seconds: 3.5)
            }
        }

        // цветето: без вода изсъхва етап по етап
        if plantStage > 0 {
            if plantWater <= 0.5 {
                let since = UserDefaults.standard.object(forKey: "plantDrySince") as? Date ?? Date()
                if UserDefaults.standard.object(forKey: "plantDrySince") == nil { UserDefaults.standard.set(since, forKey: "plantDrySince") }
                if Date().timeIntervalSince(since) > 3 * 3600 {
                    UserDefaults.standard.set(Date(), forKey: "plantDrySince")
                    plantStage -= 1
                    if plantStage <= 0 {
                        if let p = plantPanel { spawnGhost(at: NSPoint(x: p.frame.midX, y: p.frame.minY + 20), happy: false) }
                        addMemorial("Цветето изсъхна напълно")
                        if !pet.asleep { say("Цветето изсъхна… Трябваше да го поливаме.", seconds: 3.5) }
                    } else if !pet.asleep {
                        say("\(plantDefinite(plantStage + 1).capitalizedFirst) изсъхва! Изгубихме един етап. Полей го!", seconds: 3.5)
                    }
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "plantDrySince")
            }
        }

        // развалените пиксели изгниват и изчезват
        let rotten = foods.filter { $0.spoiled && !$0.view.held && !$0.flying && time > $0.spoilAt + 40 * 60 }
        for f in rotten { f.remove() }
        foods.removeAll { f in rotten.contains { $0 === f } }

        // приятел, с когото сте съвсем скарани, се мести завинаги
        for id in joinedBuddies where buddyFriendship(id) <= 5 {
            guard let k = buddyKind(id) else { continue }
            joinedBuddies = joinedBuddies.filter { $0 != id }
            UserDefaults.standard.set(0, forKey: "buddyVisits_\(id)")
            UserDefaults.standard.set(40, forKey: "buddyFriend_\(id)")
            UserDefaults.standard.set(Date().addingTimeInterval(3 * 86400), forKey: "buddyMoved_\(id)")
            if let b = buddy(id) {
                b.leaving = true
                b.guest = true
                buddySay(b, "Писна ми! Местя се да живея другаде! Сбогом!", 4)
            }
            addMemorial("\(buddyName(k)) се скара с нас и се премести да живее другаде")
            if !pet.asleep { say("\(buddyName(k)) се премести… Май много се карахме.", seconds: 3.5) }
        }
    }

    /// Наскоро преместил се приятел още не идва на гости.
    func buddyMovedAway(_ id: String) -> Bool {
        (UserDefaults.standard.object(forKey: "buddyMoved_\(id)") as? Date ?? .distantPast) > Date()
    }
}
