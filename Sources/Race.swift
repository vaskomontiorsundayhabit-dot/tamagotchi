// Състезание до другия край на екрана (срещу плъха или приятел) със залог,
// и ревност, когато галиш другите, а него не.

import AppKit

enum RacePhase { case off, lineup, countdown, running, done }

let jealousLines = ["Ей! А мен?!", "Защо галиш тях, а не мен?!", "Аз съм главният тук!", "Ревнувам! ГРРР!",
                    "Само на тях ли ще обръщаш внимание?", "И аз искам да ме цъкнеш!", "Аз съм ти любимецът, нали?!",
                    "Хмпф. Отивам да се сърдя в ъгъла."]

let flagGrid = grid([
    "KKKKKKKK",
    "KWSWSWSK",
    "KSWSWSWK",
    "KWSWSWSK",
    "KSWSWSWK",
    "KKKKKKKK",
    "K.......",
    "K.......",
    "K.......",
    "K.......",
    "K.......",
    "K.......",
    "K.......",
    "K.......",
    "KK......",
])

final class FlagView: NSView {
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        drawGrid(flagGrid, x: 4, y: 4, s: 4, palette: game.color)
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .heavy),
                                                .foregroundColor: NSColor(hex: 0x2b2b3a)]
        ("ФИНАЛ" as NSString).draw(at: NSPoint(x: 0, y: bounds.height - 10), withAttributes: a)
    }
}

extension Game {
    var raceOpponentName: String { raceBuddy.map { buddyName($0.kind) } ?? ratLabel.capitalized }

    /// Предлага състезание (срещу плъха, ако няма приятел).
    func offerRace(with b: Buddy?) {
        guard racePhase == .off, questionPanel == nil, !pet.asleep, !pet.dead, !pet.working, errands.isEmpty,
              hidePhase == .off, seekPhase == .off, !playingGame else { return }
        if b == nil && !hasRat { return }
        raceBuddy = b
        let other = raceOpponentName
        if pet.coins >= 10 {
            ask(Question(text: "Състезание до другия край на екрана: \(pet.name) срещу \(other)! На кого залагаш 10 монети?",
                         answers: [(pet.name.uppercased(), "Знаех си! Ще те направя богат!", .raceBetPet),
                                   (other.uppercased(), "Какво?! Срещу мен?! Ще видиш!", .raceBetOther),
                                   ("БЕЗ ЗАЛОГ", "Добре, само за кеф!", .raceNoBet)]), index: -1)
        } else {
            ask(Question(text: "Състезание до другия край на екрана: \(pet.name) срещу \(other)! Да почваме ли?",
                         answers: [("ДА", "На старта!", .raceNoBet), ("НЕ", "Ох… друг път.", .nothing)]), index: -1)
        }
    }

    @objc func raceFromMenu() {
        guard checkAwake() else { return }
        if pet.working { busyForGame(); return }
        let pool = buddies.filter { !$0.guest && !buddyAsleep($0) }
        if hasRat && (pool.isEmpty || Bool.random()) { offerRace(with: nil) }
        else if let b = pool.randomElement() { offerRace(with: b) }
        else { say("Нямам с кого да се състезавам… трябва ми приятел или плъх!", seconds: 3) }
    }

    func beginRace(bet: Int) {
        guard racePhase == .off else { return }
        if raceBuddy == nil && !hasRat { return }
        clearForGame()
        cancelErrands()
        chasing = false
        raceBet = bet
        if bet >= 0 {
            if pet.coins < 10 { raceBet = -1 } else { pet.coins -= 10 }
        }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        raceFloor = vf.minY
        raceStartX = vf.minX + 110
        raceFinishX = vf.maxX - 110
        raceOppX = raceStartX - 60
        racePhase = .lineup
        if raceBuddy == nil {
            if ratInCage { ratInCage = false }
            ratGoal = nil
            dropRatLoot(caught: false)
        }
        jump(toFeet: NSPoint(x: raceStartX, y: vf.minY))
        let fs = NSSize(width: 44, height: 80)
        let p = overlayPanel(NSRect(x: raceFinishX - 4, y: vf.minY, width: fs.width, height: fs.height), key: false)
        p.level = .floating
        p.ignoresMouseEvents = true
        let v = FlagView(frame: NSRect(origin: .zero, size: fs))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        raceFlagPanel = p
    }

    /// Поставя съперника там, където е в състезанието.
    private func placeOpponent(running: Bool) {
        if let b = raceBuddy {
            let w = BuddyView.size
            b.panel.setFrameOrigin(NSPoint(x: raceOppX - w.width / 2, y: raceFloor - (w.height - b.view.feetY)))
            b.view.walking = running
            b.view.facingLeft = false
        } else if let p = ratPanel, let v = ratView {
            p.setFrameOrigin(NSPoint(x: raceOppX - RatView.size.width / 2, y: raceFloor))
            if !p.isVisible { p.orderFrontRegardless() }
            v.running = running
            v.facingLeft = false
            v.hanging = false
        }
    }

    func updateRace(_ step: Double) {
        if racePhase == .off {
            // понякога сам предлага състезание
            if time > nextRaceOffer && !pet.asleep && window.isVisible && hidePhase == .off && !pet.working {
                nextRaceOffer = time + Double.random(in: 25 * 60...45 * 60)
                let pool = buddies.filter { !$0.guest && !buddyAsleep($0) }
                if hasRat && (pool.isEmpty || Bool.random()) { offerRace(with: nil) }
                else if let b = pool.randomElement() { offerRace(with: b) }
            }
            return
        }
        if raceBuddy == nil && !hasRat || pet.dead || hidePhase != .off { endRace(); return }
        switch racePhase {
        case .lineup:
            placeOpponent(running: false)
            if !jumping {
                racePhase = .countdown
                raceT0 = time
                raceCount = -1
                facingLeft = false
            }
        case .countdown:
            placeOpponent(running: false)
            let n = Int(time - raceT0)
            if n != raceCount {
                raceCount = n
                if n < 3 { say("\(3 - n)…", seconds: 0.9); sfx("Tink") }
                else {
                    say("СТАРТ!", seconds: 1.2)
                    sfx("Glass")
                    racePhase = .running
                    raceNextSpeed = 0
                }
            }
        case .running:
            if time > raceNextSpeed {
                raceNextSpeed = time + 0.6
                racePetSpeed = Double.random(in: 170...300) + Double(min(pet.level, 100)) * 0.3
                raceOppSpeed = raceBuddy == nil ? Double.random(in: 160...320) : Double.random(in: 150...300)
                if Int.random(in: 0..<8) == 0 { racePetSpeed *= 0.4; say(["Ох, спънах се!", "Чакай, връзките ми!"].randomElement()!, seconds: 1) }
            }
            walking = true
            facingLeft = false
            var o = window.frame.origin
            o.x += CGFloat(racePetSpeed * step)
            window.setFrameOrigin(o)
            raceOppX += CGFloat(raceOppSpeed * step)
            placeOpponent(running: true)
            let petX = petScreenRect().midX
            if petX >= raceFinishX || raceOppX >= raceFinishX {
                finishRace(petWon: petX - raceFinishX >= raceOppX - raceFinishX)
            }
        case .done:
            placeOpponent(running: false)
            if time > raceT0 { endRace() }
        case .off:
            break
        }
    }

    private func finishRace(petWon: Bool) {
        racePhase = .done
        raceT0 = time + 3.5
        walking = false
        let other = raceOpponentName
        pet.fun = (pet.fun + 10).clamped()
        addXP(5)
        var line = petWon ? "ПОБЕДА! Бях по-бърз от \(other)!" : "\(other) спечели… РЕВАНШ!"
        if raceBet >= 0 {
            let right = (raceBet == 0) == petWon
            if right { earnCoins(20); line += " Позна! +20 монети" } else { line += " Загуби залога." }
        }
        if petWon { start(.love, length: 2.5); confettiStart = time; sfx("Hero") } else { start(.angry, length: 2) }
        say(line, seconds: 4)
        if let b = raceBuddy { buddySay(b, petWon ? "Ех, следващия път!" : "Хаха! Аз съм първ\(b.kind.female ? "а" : "и")!", 3) }
        else { ratSay(petWon ? "Цик… следващия път." : "Цик-цик! Победа!", 3) }
        fulfill(.play)
    }

    func endRace() {
        racePhase = .off
        raceFlagPanel?.orderOut(nil)
        raceFlagPanel = nil
        raceBuddy = nil
        walking = false
        saveWindowPosition()
    }

    // --- ревност ---

    /// Цъкаш или храниш плъха или приятел.
    func attentionToOthers() {
        othersClicks.append(time)
        othersClicks.removeAll { time - $0 > 120 }
    }

    func updateJealousy() {
        othersClicks.removeAll { time - $0 > 120 }
        guard othersClicks.count >= 4, time - lastPetted > 90, time > nextJealous, !pet.asleep, !pet.dead,
              hidePhase == .off, seekPhase == .off, racePhase == .off, window.isVisible else { return }
        nextJealous = time + 5 * 60
        othersClicks.removeAll()
        jealousAt = time
        annoy(10, reason: "галиш другите, а мен не")
        start(.angry, length: 2)
        glitchUntil = time + 0.4
        sfx("Funk", every: 2)
        say(pick(jealousLines, avoiding: &lastLine), seconds: 3.5)
        // гледа към мишката (към теб)
        followUntil = time + 6
        if let b = buddies.first(where: { !$0.guest }) { buddySay(b, "Ей, \(pet.name) ревнува!", 2.5) }
        else if hasRat { ratSay("Цик?!", 1.5) }
    }

    /// Погалиш ли го след ревността, се успокоява.
    func pettedWhileJealous() {
        lastPetted = time
        guard time - jealousAt < 120 else { return }
        jealousAt = -1000
        anger = (anger - 15).clamped()
        say(["Така е по-добре! Аз съм любимецът!", "Хмпф… добре, прощавам ти.", "Знаех си, че мен обичаш най-много!"]
            .randomElement()!, seconds: 3)
    }
}
