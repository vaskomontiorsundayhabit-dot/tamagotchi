// Още тайни (без брой) и „да не пропускаш“: важните неща чакат да си на компютъра,
// а пропуснатото се брои до иконката горе. Не го описвай в README.

import AppKit

extension PotGame {
    /// Размер на всичко (от Настройки): 1, 0.75, 0.5, 0.35.
    var scale: CGFloat {
        get { CGFloat(d.object(forKey: "pot_scale") as? Double ?? 1) }
        set { d.set(Double(newValue), forKey: "pot_scale") }
    }

    /// Прозорчето става по-малко, а рисунката вътре се смалява заедно с него.
    func fitScaled(_ p: NSPanel, _ size: NSSize) {
        let f = NSRect(x: p.frame.minX, y: p.frame.minY, width: size.width * scale, height: size.height * scale)
        p.setFrame(f, display: false)
        p.contentView?.frame = NSRect(origin: .zero, size: f.size)
        p.contentView?.setBoundsSize(size)
    }

    @objc func setScaleAction(_ sender: NSMenuItem) {
        guard let v = sender.representedObject as? Double else { return }
        scale = CGFloat(v)
        // всичко се прави наново в новия размер
        let mid = panel.frame.midX
        let s = PotView.size(for: self)
        panel.setFrame(NSRect(x: mid - s.width * scale / 2, y: panel.frame.minY, width: s.width * scale, height: s.height * scale), display: true)
        view.setBoundsSize(s)
        canPanel?.orderOut(nil); canPanel = nil
        bucketPanel?.orderOut(nil); bucketPanel = nil
        bellPanel?.orderOut(nil); bellPanel = nil
        weedPanels.forEach { $0.orderOut(nil) }; weedPanels = []
        setUpTools()
        if bellOn { setUpBell() }
        syncWeedPanels()
        say("Вече съм \(Int(v * 100))%!", 2)
    }

    /// Дали човекът е на компютъра (мърдал е мишката или е писал скоро).
    var userActive: Bool {
        let types: [CGEventType] = [.mouseMoved, .keyDown, .leftMouseDown, .scrollWheel, .leftMouseDragged]
        let idle = types.map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }.min() ?? 0
        return idle < 25 && !hidden
    }

    /// Казва нещо важно, но само когато гледаш; иначе го пази за после.
    func announce(_ text: String, _ seconds: Double) {
        if userActive && pendingAnnounce.isEmpty && time > nextAnnounce {
            say(text, seconds)
            nextAnnounce = time + seconds + 0.5
        } else {
            pendingAnnounce.append((text, seconds))
        }
    }

    var unseen: Int { get { d.integer(forKey: "pot_unseen") } set { d.set(newValue, forKey: "pot_unseen") } }

    func updateMore() {
        // пропуснатото: казва го, щом се върнеш
        if userActive && !pendingAnnounce.isEmpty && time > nextAnnounce {
            let (t, s) = pendingAnnounce.removeFirst()
            say(t, s)
            nextAnnounce = time + s + 0.5
        }
        if frameCount % 60 == 0 {
            let title = unseen > 0 ? " ★\(unseen)" : ""
            if statusItem.button?.title != title { statusItem.button?.title = title }
        }
        guard time > nextMoreCheck else { return }
        nextMoreCheck = time + 60
        // създанието порасна, докато те е нямало: казва го сега
        if userActive && creature != nil && creatureStage > d.integer(forKey: "pot_cAnn") {
            d.set(creatureStage, forKey: "pot_cAnn")
            announceCreatureStage(creatureStage)
        }
        // дълбок сън: ако дълго е било без сили
        if health <= 0.5 { d.set(d.integer(forKey: "pot_zeroMin") + 1, forKey: "pot_zeroMin") } else { d.set(0, forKey: "pot_zeroMin") }
        if !dormant && d.integer(forKey: "pot_zeroMin") >= 30 {
            d.set(true, forKey: "pot_dormant")
            announce("Заспах дълбоко… само вода и плод могат да ме събудят…", 4)
            journal("Растението изпадна в дълбок сън")
        }
        guard userActive, hidePhase == 0 else { return }
        let cal = Calendar.current
        let month = cal.component(.month, from: Date())
        // зимна нощ: сняг
        if [12, 1, 2].contains(month) && isNight && !secrets.contains("winter") && stage >= 2 {
            discover("winter", "Първата зимна нощ: снежна шапка")
            say("Брррр! Сняг по листата ми!", 3.5)
        }
        // рожден ден всяка седмица
        let ageDays = Int(Date().timeIntervalSince(born) / 86400)
        if ageDays >= 7 && ageDays % 7 == 0 && d.string(forKey: "pot_bday") != dayKey() {
            d.set(dayKey(), forKey: "pot_bday")
            discover("birthday", "Рожден ден с шапка")
            say("Днес ставам на \(ageDays / 7) седмиц\(ageDays / 7 == 1 ? "а" : "и")! Честит рожден ден на мен!", 4.5)
            if creature != nil { creatureSay = "Честит рожден ден!"; creatureSayUntil = time + 4 }
        }
        // гост от стария живот
        if visitor == nil && stage >= 2 && Date().timeIntervalSince(d.object(forKey: "pot_pixchoAt") as? Date ?? .distantPast) > 2 * 86400
            && Int.random(in: 0..<240) == 0 {
            d.set(Date(), forKey: "pot_pixchoAt")
            startVisitor(.pixcho)
        }
        // кокошка в пълната кофа
        if visitor == nil && stage >= 4 && fruitsCollected >= 30 && !hasEgg && creature2 == nil && !secrets.contains("hen") && Int.random(in: 0..<120) == 0 {
            startVisitor(.hen)
        }
        // напукана саксия: градинарят идва да я поправи
        if d.bool(forKey: "pot_cracked") && visitor == nil && Int.random(in: 0..<20) == 0 { startVisitor(.gardener) }
    }

    var dormant: Bool { d.bool(forKey: "pot_dormant") }

    func announceCreatureStage(_ s: Int) {
        sfx("Hero")
        creatureSay = ["", "Пораснах!", "Вече съм голям и имам СИЛА!", "АЗ СЪМ ЛЕГЕНДА!"][min(3, s)]
        creatureSayUntil = time + 4
        switch s {
        case 1: discover("c_young", "\(creatureName.capitalizedFirst) порасна")
        case 2:
            discover("c_adult", "\(creatureName.capitalizedFirst) стана голямо и получи сила")
            say("\(creatureName.capitalizedFirst) отключи своята сила! Ще ми помага!", 4)
        default:
            discover("c_legend", "\(creatureName.capitalizedFirst) стана легендарно")
            say("ЛЕГЕНДАРНО! Около него свети златно!", 4)
        }
    }

    /// Звъниш много пъти подред: саксията се пука от тревоги.
    func bellRungAgain() {
        bellTimes = bellTimes.filter { time - $0 < 60 } + [time]
        if bellTimes.count >= 5 && !d.bool(forKey: "pot_cracked") && !d.bool(forKey: "pot_gold") {
            d.set(true, forKey: "pot_cracked")
            bellTimes = []
            announce("Стига тревоги!!! Саксията ми се ПУКНА от стрес!", 4)
            journal("Саксията се напука от много тревоги")
        }
    }

    /// Градинарят: поправя напуканата саксия със злато.
    func repairPotIfCracked() -> Bool {
        guard d.bool(forKey: "pot_cracked") else { return false }
        d.set(false, forKey: "pot_cracked")
        d.set(true, forKey: "pot_gold")
        discover("kintsugi", "Напуканата саксия беше поправена със злато")
        announce("Градинарят залепи пукнатините със ЗЛАТО! Сега саксията ми е по-красива отпреди!", 4.5)
        return true
    }

    /// Говорещият плод (рядко, при бране).
    func maybeTalkingFruit() {
        guard !d.bool(forKey: "pot_talking"), Int.random(in: 0..<40) == 0 else { return }
        d.set(true, forKey: "pot_talking")
        announce("Плодът ПРОГОВОРИ: „Не ме яж! Дай ме на някого, който заслужава!“ Златен е, в кофата е.", 5)
        journal("Откъснат беше говорещ златен плод")
    }

    var talkingFruit: Bool { d.bool(forKey: "pot_talking") }

    func talkingFruitGiven(toCreature: Bool) {
        d.set(false, forKey: "pot_talking")
        if toCreature {
            creatureGrow(300)
            discover("talking", "Говорещият плод отиде при създанието")
            announce("Златният плод влезе в \(creatureName)… то светна целият!", 4)
        } else {
            d.set(true, forKey: "pot_crown")
            discover("talking", "Говорещият плод отиде при растението: корона")
            announce("Златният плод ме короняса! Вече съм ЦАРСКО растение!", 4)
        }
    }

    /// Гост от стария живот (идва рядко).
    func pixchoVisitDone() {
        water = 100
        wateringUntil = time + 2.5
        discover("pixcho", "На гости дойде Пиксчо от стария живот")
        if fruitsCollected > 0 && Bool.random() {
            fruitsCollected -= 1
            say("Пиксчо: „Здрасти, саксийке! Полях те!“ … и тайно изяде плод от кофата! Скандал!", 5)
        } else {
            say("Пиксчо: „Здрасти, саксийке! Аз съм Пиксчо от стария живот! Полях те!“", 5)
        }
    }

    func henVisitDone() {
        hasNest = true
        hasEgg = true
        eggCare = 30
        eggLaid = Date()
        discover("hen", "Кокошка снесе яйце, привлечена от пълната кофа")
        announce("Кокошка дойде заради плодовете и… снесе ЯЙЦЕ в гнездото!", 4.5)
    }

    func reviveIfDormant() -> Bool {
        guard dormant, water > 50 else { return false }
        d.set(false, forKey: "pot_dormant")
        d.set(0, forKey: "pot_zeroMin")
        health = 60
        discover("revived", "Събуди се от дълбок сън")
        announce("Събудих се! Мислех, че никога вече няма да видя слънце!", 4)
        return true
    }
}
