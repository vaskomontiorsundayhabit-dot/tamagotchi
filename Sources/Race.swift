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
        guard racePhase == .off, questionPanel == nil, !pet.asleep, !pet.dead, errands.isEmpty,
              hidePhase == .off, seekPhase == .off, !playingGame else { return }
        if b == nil && !hasRat { return }
        raceBuddy = b
        let other = raceOpponentName
        if pet.coins >= 10 {
            ask(Question(text: "Състезание до другия край на екрана: \(pet.name) срещу \(other)! На кого залагаш 10 монети?",
                         answers: [(pet.name.uppercased(), "Знаех си! Ще те направя богат!", .raceBetPet),
                                   (other.uppercased(), "Какво?! Срещу мен?! Ще видиш!", .raceBetOther),
                                   ("БЕЗ ЗАЛОГ", "Добре, само за кеф!", .raceNoBet),
                                   ("НЕ", "Добре, друг път.", .nothing)]), index: -1)
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
        // не тича с мониторите: те си остават на бюрото
        if pet.working && !takeWorkBreak() {
            pet.working = false
            raceStoppedWork = true
        }
        raceBet = bet
        if bet >= 0 {
            if pet.coins < 10 { raceBet = -1 } else { pet.coins -= 10 }
        }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        raceFloor = vf.minY
        // тръгва от по-близкия край към другия
        let fromLeft = pr.midX - vf.minX < vf.maxX - pr.midX
        raceDir = fromLeft ? 1 : -1
        raceStartX = fromLeft ? vf.minX + 110 : vf.maxX - 110
        raceFinishX = fromLeft ? vf.maxX - 110 : vf.minX + 110
        raceOppX = raceStartX - raceDir * 60
        racePhase = .lineup
        if raceBuddy == nil {
            if ratInCage { ratInCage = false }
            ratGoal = nil
            dropRatLoot(caught: false)
        }
        // слиза на пода (ако е на платформа), после тича до старта
        if feetScreenY - vf.minY > 8 { jump(toFeet: NSPoint(x: pr.midX, y: vf.minY)) }
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
            let hop = time - raceOppHop < 0.5 ? CGFloat(sin((time - raceOppHop) / 0.5 * .pi)) * 60 : 0
            b.panel.setFrameOrigin(NSPoint(x: raceOppX - w.width / 2, y: raceFloor - (w.height - b.view.feetY) + hop))
            b.view.walking = running
            b.view.facingLeft = raceDir < 0
        } else if let p = ratPanel, let v = ratView {
            p.setFrameOrigin(NSPoint(x: raceOppX - RatView.size.width / 2, y: raceFloor))
            if !p.isVisible { p.orderFrontRegardless() }
            v.running = running
            v.facingLeft = raceDir < 0
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
                // тича по пода до старта
                let target = NSPoint(x: window.frame.minX + raceStartX - petScreenRect().midX, y: window.frame.minY)
                walking = true
                if moveWindow(toward: target, speed: CGFloat(320 * step)) {
                    walking = false
                    racePhase = .countdown
                    raceT0 = time
                    raceCount = -1
                    facingLeft = raceDir < 0
                }
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
            facingLeft = raceDir < 0
            if !jumping {
                let dx = CGFloat(racePetSpeed * step) * raceDir
                if bodyHitsDrawing(dx: dx + 2 * raceDir) {
                    // нарисувана стена: ниска → прескача, висока → пробива
                    let pr = petScreenRect()
                    let front = NSRect(x: raceDir > 0 ? pr.maxX - 6 : pr.minX - 34, y: feetScreenY + 3, width: 40, height: 400)
                    let top = drawingTop(in: front) ?? feetScreenY
                    if top - feetScreenY <= 90 {
                        jump(toFeet: NSPoint(x: pr.midX + 110 * raceDir, y: raceFloor))
                        say("Хоп! Прескачам!", seconds: 1)
                    } else {
                        smashCells(in: NSRect(x: raceDir > 0 ? pr.maxX - 10 : pr.minX - 20, y: feetScreenY + 3, width: 30, height: pr.height),
                                   from: NSPoint(x: pr.midX, y: pr.midY), limit: 30)
                        say("Пробивам!", seconds: 1)
                    }
                } else {
                    var o = window.frame.origin
                    o.x += dx
                    window.setFrameOrigin(o)
                }
            }
            let ox = raceOppX + CGFloat(raceOppSpeed * step) * raceDir
            if raceBuddy == nil {
                // плъхът прояжда рисунката
                if ratBlocked(ox - RatView.size.width / 2, raceFloor) { ratChew(ox - RatView.size.width / 2, raceFloor) } else { raceOppX = ox }
            } else if buddyBlockedAt(ox, raceFloor) && time - raceOppHop > 0.6 {
                raceOppHop = time
                raceOppX += 90 * raceDir
            } else {
                raceOppX = ox
            }
            placeOpponent(running: true)
            // колко е изминал всеки към финала
            let petGo = (petScreenRect().midX - raceFinishX) * raceDir
            let oppGo = (raceOppX - raceFinishX) * raceDir
            if petGo >= 0 || oppGo >= 0 {
                finishRace(petWon: petGo >= oppGo)
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
        if petWon { photoMoment("race") }
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
        if workBreak && monitorDetached { runErrands([.backToDesk]) }
        else if raceStoppedWork { raceStoppedWork = false; toggleWork() }
    }

    /// Най-горният нарисуван пиксел в правоъгълника (или nil).
    func drawingTop(in r: NSRect) -> CGFloat? {
        guard !drawCells.isEmpty else { return nil }
        let x0 = Int(floor(r.minX / drawCell)), x1 = Int(floor(r.maxX / drawCell))
        let y0 = Int(floor(r.minY / drawCell)), y1 = Int(floor(r.maxY / drawCell))
        guard x1 >= x0, y1 >= y0, (x1 - x0 + 1) * (y1 - y0 + 1) < 40000 else { return nil }
        var top: CGFloat?
        for cy in y0...y1 {
            for cx in x0...x1 where drawCells[cellKey(cx, cy)] != nil { top = max(top ?? 0, CGFloat(cy + 1) * drawCell) }
        }
        return top
    }

    /// Нарисувано ли е там, където би стъпил приятел (средата му е x, краката на y)?
    func buddyBlockedAt(_ x: CGFloat, _ feet: CGFloat) -> Bool {
        drawingTop(in: NSRect(x: x - 18, y: feet + 3, width: 36, height: 30)) != nil
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
