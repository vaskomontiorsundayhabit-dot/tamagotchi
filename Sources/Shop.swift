// Магазинът: монети, облекло, неща за ядене/пиене и подобрения.

import AppKit

enum ShopKind { case wear, use, upgrade }

struct ShopItem {
    let id: String
    let name: String
    let price: Int
    let kind: ShopKind
    let slot: String          // за облеклото: само едно на място
    let info: String
    let icon: Grid
}

let hatParty = grid([
    "..YY..",
    "..RR..",
    ".RYYR.",
    ".RRRR.",
    "RYYYYR",
])
let hatBeanie = grid([
    "....OO....",
    "..NNNNNN..",
    ".NNNNNNNN.",
    "OOOOOOOOOO",
])
let hatCrown = grid([
    "Y..YY..Y",
    "YY.YY.YY",
    "YYYYYYYY",
    "YRYYYYCY",
])
let hatBow = grid([
    "PP.PP",
    "PPRPP",
    "PP.PP",
])
let hatCap = grid([
    "..RRRRR...",
    ".RRRRRRR..",
    ".RRWRRRR..",
    "RRRRRRRRRR",
])
let hatChef = grid([
    ".WW.WW.",
    "WWWWWWW",
    "WWWWWWW",
    ".WWWWW.",
    ".EEEEE.",
])
let hatHalo = grid([
    ".YYYYYY.",
    "Y......Y",
    ".YYYYYY.",
])
let hatCatEars = grid([
    "KK......KK",
    "KPK....KPK",
    "KPPK..KPPK",
])
let lipMustache = grid([
    "KK..KK",
    "KKKKKK",
    ".K..K.",
])
let iconPizza = grid([
    "OOOOOOOO",
    ".YRYYRY.",
    ".YYYYYY.",
    "..YRYY..",
    "..YYYY..",
    "...YY...",
    "...YY...",
    "........",
])
let iconCandy = grid([
    "........",
    "P.....P.",
    "PP.RR.PP",
    "PPRWRRPP",
    "PPRRRRPP",
    "PP.RR.PP",
    "P.....P.",
    "........",
])
let iconEnergyDrink = grid([
    "..EEEE..",
    ".CCCCCC.",
    ".CYYYYC.",
    ".CCCYCC.",
    ".CCYCCC.",
    ".CYYYYC.",
    ".CCCCCC.",
    "..EEEE..",
])
let iconVitamins = grid([
    "..WWWW..",
    ".WWWWWW.",
    ".GGGGGG.",
    ".GWGGGG.",
    ".GGGGGG.",
    ".GGGGGG.",
    ".GGGGGG.",
    "........",
])
let iconChair = grid([
    ".NNNNN..",
    ".NNNNN..",
    ".NNNNN..",
    ".NNNNN..",
    "NNNNNNN.",
    "...E....",
    "..EEE...",
    ".E.E.E..",
])
let iconPiggy = grid([
    "........",
    ".PPPPPP.",
    "PPKPPPPP",
    "PPPPPPPR",
    "PPPPPPPP",
    ".PPPPPP.",
    ".P.PP.P.",
    "........",
])
let iconBag = grid([
    "..KKKK..",
    ".K....K.",
    "OOOOOOOO",
    "OYYYYYYO",
    "OYYKKYYO",
    "OYYYYYYO",
    "OYYYYYYO",
    "OOOOOOOO",
])
let neckBowtie = grid([
    "RR.RR",
    "RRKRR",
    "RR.RR",
])

let iconCoin = grid([
    "..OOOO..",
    ".OYYYYO.",
    "OYWYYYYO",
    "OYYOOYYO",
    "OYYOOYYO",
    "OYYYYYYO",
    ".OYYYYO.",
    "..OOOO..",
])
let iconCoffee = grid([
    "........",
    ".W.W....",
    "..W.W...",
    "WWWWWW..",
    "WUUUUWWW",
    "WUUUUW.W",
    "WUUUUWWW",
    ".WWWW...",
])
let iconCake = grid([
    "...R....",
    "...Y....",
    ".PPPPPP.",
    "PWPWPWPP",
    "YYYYYYYY",
    "OOOOOOOO",
    "YYYYYYYY",
    "OOOOOOOO",
])
let iconGold = grid([
    "........",
    ".KKKKKK.",
    ".KYYYYK.",
    ".KYWYYK.",
    ".KYYYYK.",
    ".KYYYYK.",
    ".KKKKKK.",
    "........",
])
let iconGlasses = grid([
    "........",
    "........",
    "KKK..KKK",
    "K.KKKK.K",
    "KKK..KKK",
    "........",
    "........",
    "........",
])
let iconSunglasses = grid([
    "........",
    "........",
    "KKK..KKK",
    "KSKKKKSK",
    "KKK..KKK",
    "........",
    "........",
    "........",
])
let iconHeadphones = grid([
    "..NNNN..",
    ".N....N.",
    "N......N",
    "N......N",
    "CC....CC",
    "CC....CC",
    "CC....CC",
    "........",
])
let iconScarf = grid([
    "........",
    "OOOOOOOO",
    "OOOOOOOO",
    "....OO..",
    "....OO..",
    "....OO..",
    "........",
    "........",
])
let iconMagnet = grid([
    "RR...EE.",
    "RR...EE.",
    "RR...EE.",
    "RR...EE.",
    "RRR.EEE.",
    ".RRRRE..",
    "..RRE...",
    "........",
])
let iconShop = grid([
    "RWRWRWRW",
    "RWRWRWRW",
    "........",
    "EYYYYYYE",
    "EYKKYYYE",
    "EYKKYYYE",
    "EYKKYYYE",
    "EEEEEEEE",
])
let iconPencil = grid([
    "......PP",
    ".....YYP",
    "....YYY.",
    "...YYY..",
    "..YYY...",
    ".OYY....",
    "KOO.....",
    "KK......",
])

let shopItems: [ShopItem] = [
    ShopItem(id: "coffee", name: "Кафе", price: 15, kind: .use, slot: "", info: "+30 енергия", icon: iconCoffee),
    ShopItem(id: "cake", name: "Торта", price: 25, kind: .use, slot: "", info: "+40 ситост, +10 радост", icon: iconCake),
    ShopItem(id: "tea", name: "Чай", price: 10, kind: .use, slot: "", info: "лекува по-бързо, +5 енергия", icon: iconTea),
    ShopItem(id: "pill", name: "Лекарство", price: 20, kind: .use, slot: "", info: "+35 здраве", icon: iconPill),
    ShopItem(id: "pizza", name: "Пица", price: 30, kind: .use, slot: "", info: "+60 ситост", icon: iconPizza),
    ShopItem(id: "candy", name: "Бонбон", price: 8, kind: .use, slot: "", info: "+15 радост, +5 ситост", icon: iconCandy),
    ShopItem(id: "energy", name: "Енергийна напитка", price: 35, kind: .use, slot: "", info: "+50 енергия, но се напива за 5 мин", icon: iconEnergyDrink),
    ShopItem(id: "vitamins", name: "Витамини", price: 25, kind: .use, slot: "", info: "+20 здраве, лекува по-бързо", icon: iconVitamins),
    ShopItem(id: "gold", name: "Златен пиксел", price: 60, kind: .use, slot: "", info: "+40 опит", icon: iconGold),
    ShopItem(id: "party", name: "Парти шапка", price: 40, kind: .wear, slot: "hat", info: "за купон", icon: hatParty),
    ShopItem(id: "beanie", name: "Зимна шапка", price: 60, kind: .wear, slot: "hat", info: "топло е", icon: hatBeanie),
    ShopItem(id: "bow", name: "Панделка", price: 30, kind: .wear, slot: "hat", info: "сладко", icon: hatBow),
    ShopItem(id: "cap", name: "Шапка с козирка", price: 35, kind: .wear, slot: "hat", info: "спортно", icon: hatCap),
    ShopItem(id: "chef", name: "Готварска шапка", price: 45, kind: .wear, slot: "hat", info: "за кулинарното шоу", icon: hatChef),
    ShopItem(id: "catears", name: "Котешки уши", price: 70, kind: .wear, slot: "hat", info: "мяу", icon: hatCatEars),
    ShopItem(id: "halo", name: "Ореол", price: 150, kind: .wear, slot: "hat", info: "ангелче (уж)", icon: hatHalo),
    ShopItem(id: "crown", name: "Корона", price: 300, kind: .wear, slot: "hat", info: "кралят на монтажа", icon: hatCrown),
    ShopItem(id: "glasses", name: "Очила", price: 50, kind: .wear, slot: "face", info: "умен вид", icon: iconGlasses),
    ShopItem(id: "sunglasses", name: "Слънчеви очила", price: 80, kind: .wear, slot: "face", info: "супер готин", icon: iconSunglasses),
    ShopItem(id: "headphones", name: "Слушалки", price: 120, kind: .wear, slot: "ears", info: "за монтаж на звук", icon: iconHeadphones),
    ShopItem(id: "mustache", name: "Мустаци", price: 40, kind: .wear, slot: "lip", info: "сериозен монтажист", icon: lipMustache),
    ShopItem(id: "bowtie", name: "Папийонка", price: 40, kind: .wear, slot: "neck", info: "официално", icon: neckBowtie),
    ShopItem(id: "scarf", name: "Шал", price: 50, kind: .wear, slot: "neck", info: "уютно", icon: iconScarf),
    ShopItem(id: "monitor2", name: "Втори монитор", price: 250, kind: .upgrade, slot: "", info: "още един монитор на бюрото; двойно монети от работа", icon: iconMonitor),
    ShopItem(id: "chair", name: "Удобен стол", price: 180, kind: .upgrade, slot: "", info: "работата го изморява с 30% по-малко", icon: iconChair),
    ShopItem(id: "piggy", name: "Касичка", price: 220, kind: .upgrade, slot: "", info: "+25% монети от всичко", icon: iconPiggy),
    ShopItem(id: "fastedit", name: "Бърз монтаж", price: 200, kind: .upgrade, slot: "", info: "видео за 20 минути вместо 30", icon: iconEnergy),
    ShopItem(id: "magnet", name: "Пикселен магнит", price: 150, kind: .upgrade, slot: "", info: "пикселите-храна идват по-често", icon: iconMagnet),
]

// MARK: - Изглед на магазина

final class ShopView: NSView {
    weak var game: Game?
    var hover: Int?

    static let cols = 6
    static let tileW: CGFloat = 112
    static let tileH: CGFloat = 94
    static let pad: CGFloat = 14
    static let header: CGFloat = 44
    static var size: NSSize {
        let rows = (shopItems.count + cols - 1) / cols
        return NSSize(width: pad * 2 + tileW * CGFloat(cols), height: header + tileH * CGFloat(rows) + 44)
    }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    private func tileRect(_ i: Int) -> NSRect {
        NSRect(x: ShopView.pad + CGFloat(i % ShopView.cols) * ShopView.tileW,
               y: ShopView.header + CGFloat(i / ShopView.cols) * ShopView.tileH,
               width: ShopView.tileW - 6, height: ShopView.tileH - 6)
    }

    private var closeRect: NSRect { NSRect(x: bounds.width - 34, y: 10, width: 22, height: 22) }

    private func hit(_ p: NSPoint) -> Int? { shopItems.indices.first { tileRect($0).contains(p) } }

    override func mouseMoved(with event: NSEvent) {
        let h = hit(convert(event.locationInWindow, from: nil))
        if h != hover { hover = h; needsDisplay = true }
    }

    override func mouseExited(with event: NSEvent) { hover = nil; needsDisplay = true }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if closeRect.contains(p) { game?.closeShop(); return }
        if let i = hit(p) {
            let item = shopItems[i]
            if p.y > tileRect(i).minY + 70, item.kind != .use, game?.pet.owned.contains(item.id) == true {
                game?.sell(item)
            } else {
                game?.shopAction(item)
            }
            needsDisplay = true
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { game?.closeShop() } else { super.keyDown(with: event) }
    }

    private func label(_ item: ShopItem, _ pet: Pet) -> (String, Int) {
        switch item.kind {
        case .use: return ("КУПИ \(item.price)", pet.coins >= item.price ? 0xffd166 : 0x6a6a80)
        case .upgrade:
            if pet.owned.contains(item.id) { return ("ИМАШ", 0x52b788) }
            return ("КУПИ \(item.price)", pet.coins >= item.price ? 0xffd166 : 0x6a6a80)
        case .wear:
            if pet.worn.contains(item.id) { return ("СВАЛИ", 0x48cae4) }
            if pet.owned.contains(item.id) { return ("СЛОЖИ", 0x52b788) }
            return ("КУПИ \(item.price)", pet.coins >= item.price ? 0xffd166 : 0x6a6a80)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let pet = game.pet
        let b = bounds
        NSColor(hex: 0x1b1b24).setFill(); b.fill()
        NSColor.white.setFill()
        for r in [NSRect(x: 0, y: 0, width: b.width, height: 3), NSRect(x: 0, y: b.height - 3, width: b.width, height: 3),
                  NSRect(x: 0, y: 0, width: 3, height: b.height), NSRect(x: b.width - 3, y: 0, width: 3, height: b.height)] { r.fill() }

        func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: Int, center: Bool = false) {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: size, weight: .heavy),
                                                    .foregroundColor: NSColor(hex: color)]
            let ns = s as NSString
            let w = center ? ns.size(withAttributes: a).width : 0
            ns.draw(at: NSPoint(x: x - w / 2, y: y), withAttributes: a)
        }

        text("МАГАЗИН", 16, 14, 16, 0xffffff)
        drawGrid(iconCoin, x: b.width - 190, y: 12, s: 2.5, palette: game.color)
        text("\(pet.coins) МОНЕТИ", b.width - 164, 14, 13, 0xffd166)
        text("X", closeRect.midX, closeRect.minY + 2, 15, 0xe63946, center: true)

        for (i, item) in shopItems.enumerated() {
            let r = tileRect(i)
            NSColor(hex: hover == i ? 0x3a3a50 : 0x26263a).setFill(); r.fill()
            let w = CGFloat(item.icon[0].count), h = CGFloat(item.icon.count)
            let s = min(3, 26 / max(w, h))
            drawGrid(item.icon, x: r.midX - w * s / 2, y: r.minY + 8 + (26 - h * s) / 2, s: s, palette: game.color)
            text(item.name.uppercased(), r.midX, r.minY + 40, 9, 0xffffff, center: true)
            let (l, c) = label(item, pet)
            text(l, r.midX, r.minY + 54, 10, c, center: true)
            if item.kind != .use && pet.owned.contains(item.id) {
                NSColor(hex: 0x3a2a3a).setFill()
                NSRect(x: r.minX + 6, y: r.minY + 70, width: r.width - 12, height: 14).fill()
                text("ПРОДАЙ \(item.price / 2)", r.midX, r.minY + 71, 9, 0xff8fab, center: true)
            }
        }

        let info: String
        if let h = hover { info = "\(shopItems[h].name): \(shopItems[h].info)".uppercased() }
        else { info = "МОНЕТИ СЕ ПЕЧЕЛЯТ С РАБОТА, ВИДЕА И ИГРИ. КУПЕНОТО СЕ ПРОДАВА ЗА ПОЛОВИН ЦЕНА." }
        text(info, b.width / 2, b.height - 30, 10, hover == nil ? 0x8d99ae : 0xffffff, center: true)
    }
}

// MARK: - Логиката на магазина

extension Game {
    @objc func openShop() {
        if let p = shopPanel { p.makeKeyAndOrderFront(nil); return }
        closeRetro()
        guard let vf = (window.screen ?? NSScreen.main)?.visibleFrame else { return }
        let size = ShopView.size
        let v = ShopView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        let p = overlayPanel(NSRect(x: vf.midX - size.width / 2, y: vf.midY - size.height / 2,
                                    width: size.width, height: size.height), key: true)
        p.contentView = v
        p.acceptsMouseMovedEvents = true
        shopPanel = p
        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)
        p.makeFirstResponder(v)
    }

    func closeShop() {
        shopPanel?.orderOut(nil)
        shopPanel = nil
    }

    func shopAction(_ item: ShopItem) {
        switch item.kind {
        case .wear:
            if pet.owned.contains(item.id) {
                if pet.worn.contains(item.id) { pet.worn.removeAll { $0 == item.id } }
                else { wear(item) }
                save()
                return
            }
            guard pay(item) else { return }
            pet.owned.append(item.id)
            wear(item)
            say("Купих си \(item.name.lowercased())! Как ми стои?", seconds: 3)
        case .upgrade:
            if pet.owned.contains(item.id) { return }
            guard pay(item) else { return }
            pet.owned.append(item.id)
            say("Ново: \(item.name.lowercased())!", seconds: 3)
        case .use:
            if pet.dead { return }
            if item.id == "cake" && pet.overfull >= 100 { say("Не! Ще се пръсна!", seconds: 2.5); return }
            guard pay(item) else { return }
            switch item.id {
            case "coffee":
                pet.energy = (pet.energy + 30).clamped()
                say("Кафеее! Сега мога да монтирам цяла нощ!", seconds: 3)
                fulfill(.coffee)
                drankCoffee()
            case "tea":
                pet.energy = (pet.energy + 5).clamped()
                if isSick { cure(minutes: 40) } else { say("Ммм, чаят е топъл.", seconds: 2.5) }
            case "cake":
                if pet.fullness >= 90 { pet.overfull = min(100, pet.overfull + 40) }
                pet.fullness = (pet.fullness + 40).clamped()
                pet.fun = (pet.fun + 10).clamped()
                lastFoodColor = 0xff8fab
                start(.eat, length: 1.6)
                say("Торта! Обичам те!", seconds: 2.5)
            case "pill":
                if isSick { cure(minutes: 60) }
                pet.health = (pet.health + 35).clamped()
                start(.pill, length: 1.6)
                say("Бляк… но помага", seconds: 2.5)
            case "pizza":
                if pet.fullness >= 90 { pet.overfull = min(100, pet.overfull + 50) }
                pet.fullness = (pet.fullness + 60).clamped()
                lastFoodColor = 0xffca3a
                start(.eat, length: 1.8)
                say("Пица! Най-доброто нещо след пикселите!", seconds: 3)
            case "candy":
                pet.fun = (pet.fun + 15).clamped()
                pet.fullness = (pet.fullness + 5).clamped()
                lastFoodColor = 0xff8fab
                start(.eat, length: 1.2)
                say("Сладко! Хи-хи!", seconds: 2)
            case "energy":
                pet.energy = (pet.energy + 50).clamped()
                drunkUntil = time + 5 * 60
                nextDrunkLine = time + 3
                say("ЕНЕРГИЯЯЯ! Хик!", seconds: 2.5)
            case "vitamins":
                pet.health = (pet.health + 20).clamped()
                if isSick { cure(minutes: 20) } else { say("Витамини! Здрав съм като пиксел!", seconds: 2.5) }
            case "gold":
                say("Златен пиксел! +40 опит", seconds: 3)
                addXP(40)
            default: break
            }
        }
        if !pet.asleep && action == .none { start(.love, length: 1.2) }
        fulfill(.buy(item.id))
        save()
    }

    private func pay(_ item: ShopItem) -> Bool {
        if pet.coins < item.price {
            say("Нямаме пари… трябват \(item.price) монети.", seconds: 3)
            return false
        }
        pet.coins -= item.price
        return true
    }

    private func wear(_ item: ShopItem) {
        let sameSlot = shopItems.filter { $0.slot == item.slot }.map { $0.id }
        pet.worn.removeAll { sameSlot.contains($0) }
        pet.worn.append(item.id)
    }

    func earnCoins(_ n: Int) {
        guard n > 0 else { return }
        pet.coins += pet.owned.contains("piggy") ? Int((Double(n) * 1.25).rounded(.up)) : n
    }

    func sell(_ item: ShopItem) {
        guard pet.owned.contains(item.id) else { return }
        pet.owned.removeAll { $0 == item.id }
        pet.worn.removeAll { $0 == item.id }
        pet.coins += item.price / 2
        pet.fun = (pet.fun - 5).clamped()
        say("Продадохме \(item.name.lowercased()) за \(item.price / 2) монети. Сниф…", seconds: 3)
        save()
    }
}
