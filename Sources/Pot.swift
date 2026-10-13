// Саксията: кълн, който расте с грижа (кълн → стъбло → листа → цъфтеж → храст → дърво).
// Бурени, мравки, пчели, птичка с гнездо и тайнствено яйце, градинар, крачета при тревога,
// танц, когато компютърът свири. Всичко е в едно прозорче, без пиксели по целия екран.

import AppKit
import CoreAudio

let potStageNames = ["Кълн", "Стъбло", "Стъбло с листа", "Цъфтеж", "Храст", "Дърво"]
/// Точки растеж за всеки етап (≈ минути добра грижа): бързо в началото, бавно и интересно после.
let potThresholds: [Double] = [0, 6, 20, 50, 160, 480]

struct PotAnt {
    var t: CGFloat          // 0 = на ръба на саксията, 1 = горе на растението
    var side: CGFloat       // -1 / 1
    var speed: CGFloat
}

struct PotBee {
    var phase: Double
    var radius: CGFloat
    var until: Double
}

final class PotGame: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var panel: NSPanel!
    var view: PotView!
    var time: Double = 0
    var lastTick = Date()
    let d = UserDefaults.standard

    // --- пази се ---
    // често менящите се стойности са в паметта и се записват на 10 секунди
    var growth: Double = UserDefaults.standard.double(forKey: "pot_growth")
    var water: Double = UserDefaults.standard.object(forKey: "pot_water") as? Double ?? 70 { didSet { water = min(100, max(0, water)) } }
    var health: Double = UserDefaults.standard.object(forKey: "pot_health") as? Double ?? 90 { didSet { health = min(100, max(0, health)) } }
    var overgrowth: Double = UserDefaults.standard.double(forKey: "pot_overgrowth") { didSet { overgrowth = min(100, max(0, overgrowth)) } }
    var lastSave: Double = 0

    func saveState() {
        d.set(growth, forKey: "pot_growth")
        d.set(water, forKey: "pot_water")
        d.set(health, forKey: "pot_health")
        d.set(overgrowth, forKey: "pot_overgrowth")
        d.set(Date(), forKey: "pot_lastSeen")
        lastSave = time
    }
    var fruitsOnPlant: Int { get { d.integer(forKey: "pot_fruitsOn") } set { d.set(max(0, newValue), forKey: "pot_fruitsOn") } }
    var fruitsCollected: Int { get { d.integer(forKey: "pot_fruits") } set { d.set(max(0, newValue), forKey: "pot_fruits") } }
    var weeds: [Double] { get { d.array(forKey: "pot_weeds") as? [Double] ?? [] } set { d.set(newValue, forKey: "pot_weeds") } }
    var fertUntil: Date { get { d.object(forKey: "pot_fert") as? Date ?? .distantPast } set { d.set(newValue, forKey: "pot_fert") } }
    var lastFert: Date { get { d.object(forKey: "pot_lastFert") as? Date ?? .distantPast } set { d.set(newValue, forKey: "pot_lastFert") } }
    var born: Date {
        if let b = d.object(forKey: "pot_born") as? Date { return b }
        d.set(Date(), forKey: "pot_born")
        return Date()
    }
    var hasNest: Bool { get { d.bool(forKey: "pot_nest") } set { d.set(newValue, forKey: "pot_nest") } }
    var hasEgg: Bool { get { d.bool(forKey: "pot_egg") } set { d.set(newValue, forKey: "pot_egg") } }
    var eggCare: Double { get { d.object(forKey: "pot_eggCare") as? Double ?? 30 } set { d.set(min(100, max(0, newValue)), forKey: "pot_eggCare") } }
    var eggLaid: Date { get { d.object(forKey: "pot_eggLaid") as? Date ?? Date() } set { d.set(newValue, forKey: "pot_eggLaid") } }
    var creature: String? { get { d.string(forKey: "pot_creature") } set { d.set(newValue, forKey: "pot_creature") } }
    var potX: Double? { get { d.object(forKey: "pot_x") as? Double } set { d.set(newValue, forKey: "pot_x") } }
    var bellOn: Bool { get { d.object(forKey: "pot_bell") as? Bool ?? true } set { d.set(newValue, forKey: "pot_bell") } }
    var soundsOn: Bool { get { d.object(forKey: "pot_sounds") as? Bool ?? true } set { d.set(newValue, forKey: "pot_sounds") } }
    var hidden: Bool { get { d.bool(forKey: "pot_hidden") } set { d.set(newValue, forKey: "pot_hidden") } }

    // --- само докато върви ---
    var ants: [PotAnt] = []
    var bees: [PotBee] = []
    var nextWeed: Double = 15 * 60
    var nextAnts: Double = 25 * 60
    var nextBees: Double = 3 * 60
    var nextFruit: Double = 5 * 60
    var nextBird: Double = 40 * 60
    var nextGardener: Double = 20 * 60
    var nextAudioCheck: Double = 0
    var musicPlaying = false
    var musicApps: [String] = []
    var musicSeconds = 0
    var eyesUntil: Double = 0
    var wateringUntil: Double = 0
    var trimmingUntil: Double = 0
    var bubble: String?
    var bubbleUntil: Double = 0
    var lastEggPet: Double = -100
    var fallSpeed: CGFloat = 0
    // тревога: крачета и бягане
    var hidePhase = 0           // 0 няма, 1 бяга, 2 скрит, 3 връща се
    var hideGoal: CGFloat = 0
    var hideHome: CGFloat = 0
    var hideUntil: Double = 0
    var bellPanel: NSPanel?
    var cardPanel: NSPanel?
    var cardOpened: Double = 0
    var visitor: PotVisitor?
    // обновяване
    var availableBuild = 0
    var availableURL: URL?
    var updating = false
    var nextUpdateCheck: Double = 20
    let currentBuild = Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0

    var stage: Int { (0..<potThresholds.count).last { growth >= potThresholds[$0] } ?? 0 }
    /// Колко е напреднал в текущия етап (0…1); дървото расте и след това.
    var stageProgress: Double {
        let s = stage
        if s >= potThresholds.count - 1 { return min(1, (growth - potThresholds[s]) / 1500) }
        return (growth - potThresholds[s]) / (potThresholds[s + 1] - potThresholds[s])
    }
    var weedsCount: Int { weeds.count }

    // MARK: - стартиране

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = born
        offlineCatchUp()
        let s = PotView.size(for: self)
        let vf = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let x = CGFloat(potX ?? Double(vf.midX + 200))
        panel = overlayPanel(NSRect(x: x - s.width / 2, y: vf.minY, width: s.width, height: s.height), key: false)
        panel.level = .floating
        view = PotView(frame: NSRect(origin: .zero, size: s))
        view.autoresizingMask = [.width, .height]
        view.game = self
        panel.contentView = view
        if !hidden { panel.orderFrontRegardless() }
        keepOnScreen()
        if bellOn { setUpBell() }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let b = statusItem.button {
            b.image = potStatusIcon()
            b.target = self
            b.action = #selector(statusClicked)
            b.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        let timer = Timer(timeInterval: 1.0 / 30, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        if growth == 0 { say("Здрасти! Аз съм кълнче. Полей ме!", 4) } else { say(["Здрасти!", "Пак сме заедно!", "Слънце!"].randomElement()!, 2.5) }
    }

    func applicationWillTerminate(_ notification: Notification) { savePosition(); saveState() }

    /// Докато програмата е била спряна: водата е намаляла, а растението е пораснало малко (най-много 8 часа).
    func offlineCatchUp() {
        guard let last = d.object(forKey: "pot_lastSeen") as? Date else { return }
        let mins = min(8 * 60, Date().timeIntervalSince(last) / 60)
        let drain = mins * drainPerMinute
        if water > 20 { growth += min(mins, water / drainPerMinute) * 0.4 }
        water = max(8, water - drain)
    }

    var drainPerMinute: Double { 100 / 240 * (1 + Double(stage) * 0.15) }

    // MARK: - всеки кадър

    @objc func tick() {
        let now = Date()
        let dt = min(0.5, now.timeIntervalSince(lastTick))
        lastTick = now
        time += dt
        let m = dt / 60
        if time - lastSave > 10 { saveState() }

        // вода и здраве
        water -= drainPerMinute * m
        if water < 15 { health -= 0.7 * m } else if ants.isEmpty { health += 0.5 * m }
        health -= Double(ants.count) * 0.4 * m
        // растеж
        var rate = 1.0
        if water < 15 { rate = 0 } else if water < 35 { rate = 0.5 }
        rate *= max(0, 1 - 0.25 * Double(weedsCount))
        rate *= health / 100
        if Date() < fertUntil { rate *= 2 }
        if stage >= 4 && overgrowth > 60 { rate *= 0.6 }
        if hidePhase == 0 {
            let before = stage
            growth += rate * m
            if stage > before { stageReached(stage) }
        }
        if stage >= 4 { overgrowth += m / 6 }

        updateNature(m)
        updateVisitor(dt)
        updateHiding(dt)
        updateMusic()
        updatePanel()
        updateCard()
        if time > nextUpdateCheck { nextUpdateCheck = time + 30 * 60; checkForUpdate(manual: false) }
        view.needsDisplay = true
        bellPanel?.contentView?.needsDisplay = true
    }

    func stageReached(_ s: Int) {
        let lines = ["", "Пораснах! Вече имам стъбло!", "Пуснах листа!", "Цъфнах! Скоро ще имам плодове!",
                     "Станах ХРАСТ! Сега ще идва и градинар.", "Станах ДЪРВО! Птичките ще ме обичат!"]
        say(lines[s], 4)
        sfx("Hero")
        journal("Стана: \(potStageNames[s].lowercased())")
    }

    // MARK: - природата: бурени, мравки, пчели, плодове, птичка

    func updateNature(_ m: Double) {
        guard hidePhase == 0 else { return }
        if stage >= 1 && time > nextWeed {
            nextWeed = time + Double.random(in: 25 * 60...55 * 60)
            if weeds.count < 3 {
                weeds = weeds + [Double.random(in: -0.8...0.8)]
                say(["Бурен ми поникна! Махни го!", "Ох, бурени!", "Някой ми краде водата… бурен!"].randomElement()!, 3)
            }
        }
        if stage >= 2 && time > nextAnts {
            nextAnts = time + Double.random(in: 35 * 60...70 * 60)
            if ants.isEmpty {
                for _ in 0..<Int.random(in: 1...3) {
                    ants.append(PotAnt(t: 0, side: Bool.random() ? -1 : 1, speed: CGFloat.random(in: 0.008...0.02)))
                }
                say("Мравки! Гъделичкат ме! Изгони ги!", 3)
            }
        }
        // мравките пълзят нагоре и надолу
        for i in ants.indices {
            ants[i].t += ants[i].speed / 30
            if ants[i].t > 1 || ants[i].t < 0 { ants[i].speed = -ants[i].speed; ants[i].t = min(1, max(0, ants[i].t)) }
        }
        // пчели: опрашват цветовете → плодове
        if stage >= 3 && time > nextBees {
            nextBees = time + Double.random(in: 8 * 60...18 * 60)
            for _ in 0..<Int.random(in: 1...2) { bees.append(PotBee(phase: Double.random(in: 0...6), radius: CGFloat.random(in: 25...45), until: time + 60)) }
            if Bool.random() { say("Бззз! Пчелички!", 2) }
        }
        let leaving = bees.filter { time > $0.until }.count
        if leaving > 0 {
            bees.removeAll { time > $0.until }
            nextFruit = min(nextFruit, time + 20)
        }
        if stage >= 3 && time > nextFruit {
            nextFruit = time + Double.random(in: 12 * 60...22 * 60) / (bees.isEmpty ? 1 : 2)
            let cap = [0, 0, 0, 3, 6, 10][min(5, stage)]
            if fruitsOnPlant < cap && water > 20 {
                fruitsOnPlant += 1
                if fruitsCollected == 0 && fruitsOnPlant == 1 { journal("Първият плод!") ; say("Родих плод! Откъсни го!", 3.5) }
            }
        }
        // птичка с гнездо (храст или дърво)
        if stage >= 4 && !hasNest && creature == nil && time > nextBird && visitor == nil {
            nextBird = time + Double.random(in: 2 * 3600...4 * 3600)
            startVisitor(.bird)
        }
        // яйцето: ако не го гледаш, изстива; ако го гледаш, се излюпва нещо тайнствено
        if hasEgg {
            eggCare -= 8.0 / 60 * m   // изстива с ~8 на час
            if eggCare >= 100 && Date().timeIntervalSince(eggLaid) > 45 * 60 { hatchEgg() }
            if eggCare <= 0 && Date().timeIntervalSince(eggLaid) > 3 * 3600 {
                hasEgg = false
                say("Птичката си взе яйцето… не го гледахме.", 3.5)
                journal("Птичката си отнесе яйцето")
            }
        }
        // градинар, когато храстът е разрошен
        if stage >= 4 && overgrowth > 60 && time > nextGardener && visitor == nil {
            nextGardener = time + Double.random(in: 60 * 60...120 * 60)
            startVisitor(.gardener)
        }
    }

    func hatchEgg() {
        hasEgg = false
        let kinds = PotCreature.all.map { $0.id }
        let k = kinds.randomElement()!
        creature = k
        sfx("Hero")
        let name = PotCreature.find(k)?.name ?? "нещо"
        say("Яйцето се излюпи! Това е… \(name)?!", 4.5)
        journal("От яйцето се излюпи: \(name)")
    }

    // MARK: - грижи

    func waterIt() {
        if water > 90 { say("Пих достатъчно, благодаря!", 2); return }
        water = 100
        wateringUntil = time + 2.5
        health += 3
        sfx("Bottle")
        say(["Ааах, вода!", "Благодаря!", "Мммм, освежително!"].randomElement()!, 2)
    }

    func fertilize() {
        let wait = 2 * 3600 - Date().timeIntervalSince(lastFert)
        if wait > 0 { say("Тор може пак след \(Int(wait / 60) + 1) мин.", 2.5); return }
        lastFert = Date()
        fertUntil = Date().addingTimeInterval(30 * 60)
        sfx("Pop")
        say("Тор! Половин час раста двойно по-бързо!", 3)
    }

    func pullWeed(_ i: Int) {
        guard weeds.indices.contains(i) else { return }
        var w = weeds
        w.remove(at: i)
        weeds = w
        sfx("Pop")
        say(["Ох, олекна ми!", "Махай се, бурен!", "Благодаря!"].randomElement()!, 2)
    }

    func pullAllWeeds() { if weeds.isEmpty { return }; weeds = []; sfx("Pop"); say("Чисто! Благодаря!", 2) }

    func shooAnt(_ i: Int) {
        guard ants.indices.contains(i) else { return }
        ants.remove(at: i)
        sfx("Tink")
        if ants.isEmpty { say("Мравките избягаха!", 2) }
    }

    func shooAllAnts() { if ants.isEmpty { return }; ants = []; sfx("Tink"); say("Мравките избягаха!", 2) }

    func pickFruit() {
        guard fruitsOnPlant > 0 else { return }
        fruitsOnPlant -= 1
        fruitsCollected += 1
        sfx("Pop")
        say(["Ням! Плод!", "Заповядай!", "Още ще родя!"].randomElement()!, 2)
    }

    func warmEgg() {
        guard hasEgg else { return }
        if time - lastEggPet < 15 { say("Яйцето е топличко, остави го малко.", 2); return }
        lastEggPet = time
        eggCare += 15
        sfx("Purr")
        say(eggCare >= 100 ? "Яйцето мърда! Скоро ще се излюпи!" : "Стоплих яйцето. Пази го!", 2.5)
    }

    func clickedPlant() {
        if stage >= 4 {
            eyesUntil = time + 5
            say(["Хи! Видя ме!", "Здрасти!", "Гъдел!", "Аз съм храст с очи!"].randomElement()!, 2)
            sfx("Purr")
        } else {
            openCard()
        }
    }

    // MARK: - звук от компютъра → танцува

    /// Танцува само когато някоя програма наистина пуска звук поне 3 секунди
    /// (без собствените звуци и без програмите, на които си казал „не танцувай“).
    func updateMusic() {
        guard time > nextAudioCheck else { return }
        nextAudioCheck = time + 1
        let players = danceOn ? audioPlayers().filter { !danceIgnore.contains($0) } : []
        musicApps = players
        musicSeconds = players.isEmpty ? 0 : musicSeconds + 1
        let playing = musicSeconds >= 3
        if playing && !musicPlaying && hidePhase == 0 { say(["Музика! Танцувам!", "Ооо, обичам тази песен!", "Ла-ла-лааа!"].randomElement()!, 2.5) }
        musicPlaying = playing
    }

    var danceOn: Bool { get { d.object(forKey: "pot_dance") as? Bool ?? true } set { d.set(newValue, forKey: "pot_dance") } }
    var danceIgnore: [String] { get { d.stringArray(forKey: "pot_danceIgnore") ?? [] } set { d.set(newValue, forKey: "pot_danceIgnore") } }

    /// Кои програми пускат звук в момента (на macOS 14+ по програми; на по-старите само „нещо свири“).
    func audioPlayers() -> [String] {
        if #available(macOS 14.0, *) {
            let sys = AudioObjectID(kAudioObjectSystemObject)
            var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList,
                                                  mScope: kAudioObjectPropertyScopeGlobal, mElement: 0)
            var size: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(sys, &addr, 0, nil, &size) == noErr, size > 0 else { return [] }
            var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
            guard AudioObjectGetPropertyData(sys, &addr, 0, nil, &size, &ids) == noErr else { return [] }
            let me = ProcessInfo.processInfo.processIdentifier
            var names: [String] = []
            for id in ids {
                var a = AudioObjectPropertyAddress(mSelector: kAudioProcessPropertyIsRunningOutput,
                                                   mScope: kAudioObjectPropertyScopeGlobal, mElement: 0)
                var running: UInt32 = 0
                var s = UInt32(MemoryLayout<UInt32>.size)
                guard AudioObjectGetPropertyData(id, &a, 0, nil, &s, &running) == noErr, running != 0 else { continue }
                a.mSelector = kAudioProcessPropertyPID
                var pid: pid_t = 0
                s = UInt32(MemoryLayout<pid_t>.size)
                guard AudioObjectGetPropertyData(id, &a, 0, nil, &s, &pid) == noErr, pid != me else { continue }
                let name = NSRunningApplication(processIdentifier: pid)?.localizedName ?? "процес \(pid)"
                if !names.contains(name) { names.append(name) }
            }
            return names
        }
        return audioIsPlaying() ? ["звук"] : []
    }

    func audioIsPlaying() -> Bool {
        var dev = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                              mScope: kAudioObjectPropertyScopeGlobal, mElement: 0)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &dev) == noErr else { return false }
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        addr.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        guard AudioObjectGetPropertyData(dev, &addr, 0, nil, &size, &running) == noErr else { return false }
        return running != 0
    }

    // MARK: - прозорчето

    func updatePanel() {
        guard let panel, let view else { return }
        let s = PotView.size(for: self)
        if panel.frame.size != s {
            let x = panel.frame.midX - s.width / 2
            panel.setFrame(NSRect(x: x, y: panel.frame.minY, width: s.width, height: s.height), display: true)
        }
        if view.drag.active || hidePhase != 0 { return }
        let vf = screenFloor()
        if panel.frame.minY > vf.minY + 0.5 {
            fallSpeed = min(fallSpeed + 1.2, 30)
            panel.setFrameOrigin(NSPoint(x: panel.frame.minX, y: max(vf.minY, panel.frame.minY - fallSpeed)))
        } else {
            fallSpeed = 0
            if panel.frame.minY < vf.minY - 0.5 { panel.setFrameOrigin(NSPoint(x: panel.frame.minX, y: vf.minY)) }
        }
    }

    func screenFloor() -> NSRect {
        let c = NSPoint(x: panel.frame.midX, y: panel.frame.minY + 10)
        return (NSScreen.screens.first { $0.frame.contains(c) } ?? NSScreen.screens.first { $0.frame.minX <= c.x && $0.frame.maxX > c.x }
                ?? NSScreen.main)?.visibleFrame ?? .zero
    }

    func keepOnScreen() {
        let vf = screenFloor()
        let x = min(max(panel.frame.minX, vf.minX), vf.maxX - panel.frame.width)
        panel.setFrameOrigin(NSPoint(x: x, y: max(vf.minY, panel.frame.minY)))
    }

    func savePosition() { potX = Double(panel.frame.midX) }

    func dropped() {
        keepOnScreen()
        savePosition()
    }

    func say(_ text: String, _ seconds: Double) {
        bubble = text
        bubbleUntil = time + max(seconds, Double(text.count) / 14 + 1.5)
    }

    func sfx(_ name: String) {
        guard soundsOn, !hidden else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    // MARK: - дневник

    func journal(_ text: String) {
        var j = d.array(forKey: "pot_journal") as? [[String: Any]] ?? []
        j.append(["t": Date().timeIntervalSince1970, "text": text])
        if j.count > 80 { j.removeFirst(j.count - 80) }
        d.set(j, forKey: "pot_journal")
    }

    @objc func showJournal() {
        NSApp.activate(ignoringOtherApps: true)
        let f = DateFormatter()
        f.dateFormat = "d.MM HH:mm"
        let j = d.array(forKey: "pot_journal") as? [[String: Any]] ?? []
        let lines = j.reversed().prefix(25).map { e in
            "\(f.string(from: Date(timeIntervalSince1970: e["t"] as? Double ?? 0))) · \(e["text"] as? String ?? "")"
        }
        let a = NSAlert()
        a.messageText = "Дневник на саксията"
        let age = Int(Date().timeIntervalSince(born) / 3600)
        a.informativeText = "Възраст: \(age / 24) дни и \(age % 24) ч · набрани плодове: \(fruitsCollected)\n\n"
            + (lines.isEmpty ? "Още нищо не се е случило." : lines.joined(separator: "\n"))
        a.runModal()
    }
}
