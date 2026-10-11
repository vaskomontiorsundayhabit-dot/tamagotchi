// Пиксел-телевизор: вечер всички се събират и гледат компилациите на Пиксчо, а приятелите коментират.

import AppKit

let tvComments = ["Ха! Тази част е най-хубава!", "Пусни я пак!", "Кой е монтирал това? Гениално!", "Ооо, експлозия!",
                  "Ще ми дадеш ли пуканки?", "Сега плачех ли? Не, пиксел ми влезе в окото.", "Тук трябва още музика!",
                  "Това съм аз ли?!", "Шшш, гледам!", "Звукът е твърде силен!", "Най-добрият канал!"]
let tvPetLines = ["Това съм го монтирал аз!", "Гледайте сега какво става!", "Тази компилация ми е любимата.",
                  "Тук рендерът ми заби три пъти…", "Харесва ли ви?"]

final class TVView: NSView {
    weak var game: Game?
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { game?.toggleTV() }

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time
        let b = bounds
        // антена, кутия, крачета
        NSColor(hex: 0x2b2b3a).setFill()
        NSRect(x: b.midX - 20, y: 2, width: 3, height: 16).fill()
        NSRect(x: b.midX + 17, y: 2, width: 3, height: 16).fill()
        let box = NSRect(x: 6, y: 18, width: b.width - 12, height: b.height - 30)
        NSColor(hex: 0x5c3a1e).setFill(); box.fill()
        NSRect(x: 16, y: b.height - 12, width: 6, height: 12).fill()
        NSRect(x: b.width - 22, y: b.height - 12, width: 6, height: 12).fill()
        let scr = NSRect(x: box.minX + 8, y: box.minY + 8, width: box.width - 30, height: box.height - 16)
        NSColor(hex: 0x1b1b24).setFill(); scr.fill()
        // копчета
        NSColor(hex: 0xffd166).setFill()
        NSRect(x: box.maxX - 16, y: box.minY + 12, width: 8, height: 8).fill()
        NSColor(hex: 0x8d99ae).setFill()
        NSRect(x: box.maxX - 16, y: box.minY + 26, width: 8, height: 8).fill()
        // програмата: сменя се на няколко секунди
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: scr).setClip()
        let show = Int(t / 6) % 4
        let k = CGFloat((t / 6).truncatingRemainder(dividingBy: 1))
        switch show {
        case 0: // скачащ Пиксчо
            let sp = buildSprite(level: game.bodyCells, face: .happy, pose: .wave, frame: Int(t * 4), working: false, variant: game.bodyVariant)
            let s = min(1.5, (scr.height - 6) / CGFloat(max(1, sp.maxY - sp.minY + 1)))
            let hop = abs(CGFloat(sin(t * 5))) * 8
            drawGrid(sp.grid, x: scr.midX - CGFloat(sp.cx) * s, y: scr.maxY - 3 - CGFloat(sp.groundY + 1) * s - hop, s: s, palette: game.color)
        case 1: // експлозия от пиксели
            for i in 0..<18 {
                let a = Double(i) * 0.35
                let r = k * scr.width * 0.5
                NSColor(hex: foodColors[i % foodColors.count]).setFill()
                NSRect(x: scr.midX + CGFloat(cos(a)) * r, y: scr.midY + CGFloat(sin(a)) * r * 0.6, width: 4, height: 4).fill()
            }
        case 2: // залез
            NSColor(hex: 0xf4a261).setFill(); NSRect(x: scr.minX, y: scr.minY, width: scr.width, height: scr.height).fill()
            NSColor(hex: 0xffd166).setFill()
            NSBezierPath(ovalIn: NSRect(x: scr.midX - 12, y: scr.minY + 10 + k * 20, width: 24, height: 24)).fill()
            NSColor(hex: 0x1d3557).setFill(); NSRect(x: scr.minX, y: scr.maxY - 12, width: scr.width, height: 12).fill()
        default: // заглавие
            let title = clipTitles[Int(t / 24) % clipTitles.count].uppercased()
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .heavy),
                                                    .foregroundColor: NSColor.white]
            (title as NSString).draw(with: scr.insetBy(dx: 4, dy: 8), options: [.usesLineFragmentOrigin], attributes: a)
        }
        // шум и отблясък
        if Int(t * 10) % 17 == 0 {
            NSColor(white: 1, alpha: 0.25).setFill()
            NSRect(x: scr.minX, y: scr.minY + CGFloat(Int(t * 50) % Int(max(1, scr.height))), width: scr.width, height: 2).fill()
        }
        NSGraphicsContext.current?.restoreGraphicsState()
    }
}

extension Game {
    @objc func toggleTV() {
        if tvPanel != nil { endTV(); return }
        startTV()
    }

    func startTV() {
        guard tvPanel == nil, !pet.dead else { return }
        let pr = petScreenRect()
        let vf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.visibleFrame ?? .zero
        let s = NSSize(width: 130, height: 110)
        let x = min(max(pr.midX + (pr.midX > vf.midX ? -260 : 160), vf.minX + 20), vf.maxX - s.width - 20)
        let p = overlayPanel(NSRect(x: x, y: vf.minY, width: s.width, height: s.height), key: false)
        p.level = .floating
        let v = TVView(frame: NSRect(origin: .zero, size: s))
        v.game = self
        p.contentView = v
        p.orderFrontRegardless()
        tvPanel = p
        tvUntil = time + 3 * 60
        nextTVLine = time + 4
        sfx("Tink")
        if !pet.asleep { say("ТВ вечер! Елате да гледаме компилациите ми!", seconds: 3) }
        // всички се събират пред телевизора
        let tvX = p.frame.midX
        for (i, b) in buddies.enumerated() where !b.leaving && !buddyAsleep(b) {
            b.wanderX = tvX + (i % 2 == 0 ? -1 : 1) * CGFloat(110 + (i / 2) * 90)
            b.nextWander = time + 3 * 60
        }
        if !pet.working && !busyMoving { walkTarget = tvX - 70 - bodyCenterOffset }
        photoMoment("tv")
    }

    func endTV() {
        tvPanel?.orderOut(nil)
        tvPanel = nil
        for b in buddies { b.nextWander = time }
        if !pet.asleep && hidePhase == .off { say(["Хубав филм беше!", "Лека нощ, телевизоре!", "Утре пак!"].randomElement()!, seconds: 2.5) }
    }

    func updateTV() {
        // вечер сам пуска телевизора (веднъж на вечер)
        let h = Calendar.current.component(.hour, from: Date())
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = f.string(from: Date())
        if tvPanel == nil && h >= 19 && h <= 22 && tvDay != today && !pet.asleep && !pet.working && window.isVisible
            && hidePhase == .off && errands.isEmpty && !playingGame && Int.random(in: 0..<3000) == 0 {
            tvDay = today
            startTV()
        }
        guard let p = tvPanel else { return }
        p.contentView?.needsDisplay = true
        if time > tvUntil || pet.dead || hidePhase != .off || minimalMode { endTV(); return }
        guard time > nextTVLine, dialog.isEmpty else { return }
        nextTVLine = time + Double.random(in: 8...15)
        let watchers = buddies.filter { !$0.leaving && !buddyAsleep($0) }
        if let b = watchers.randomElement(), Bool.random() {
            buddySay(b, tvComments.randomElement()!, 3)
        } else if !pet.asleep {
            say(tvPetLines.randomElement()!, seconds: 3)
        }
        if hasRat && ratIsOut && Int.random(in: 0..<5) == 0 { ratSay("Цик! (гледа)", 2) }
    }
}
