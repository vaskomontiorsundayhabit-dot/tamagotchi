// Снимките на Пикселка: снима Пиксчо в различни моменти и после ги показва (албум).

import AppKit

struct Photo {
    let scene: String
    let date: Date
    let level: Int
}

let photoCaptions: [String: String] = [
    "work": "МОНТИРА", "sleep": "СПИ", "eat": "ЯДЕ", "drunk": "СЛЕД КАФЕ", "sick": "БОЛЕН", "rat": "С ПЛЪХЧЕТО",
    "friends": "С ПРИЯТЕЛИ", "play": "ИГРАЕ", "rain": "В ДЪЖДА", "pose": "ПОЗИРА", "gold": "ЗЛАТЕН",
]

final class AlbumView: NSView {
    weak var game: Game?
    var page = 0
    var single: Photo?          // показва само една снимка (когато Пикселка я покаже сама)
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    var photos: [Photo] { game?.photos ?? [] }
    var pages: Int { max(1, (photos.count + 5) / 6) }
    var prevRect: NSRect { NSRect(x: 12, y: bounds.height - 30, width: 30, height: 22) }
    var nextRect: NSRect { NSRect(x: bounds.width - 42, y: bounds.height - 30, width: 30, height: 22) }
    var closeRect: NSRect { NSRect(x: bounds.width - 30, y: 8, width: 22, height: 22) }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        if closeRect.contains(p) || single != nil { game?.closeAlbum(); return }
        if prevRect.contains(p) && page > 0 { page -= 1; needsDisplay = true }
        if nextRect.contains(p) && page < pages - 1 { page += 1; needsDisplay = true }
    }

    func drawPhoto(_ ph: Photo, in r: NSRect) {
        guard let game else { return }
        // полароид: бяла рамка, отдолу надпис
        NSColor.white.setFill(); r.fill()
        let pic = NSRect(x: r.minX + 6, y: r.minY + 6, width: r.width - 12, height: r.height - 30)
        let bgs: [String: Int] = ["sleep": 0x1d3557, "rain": 0x457b9d, "drunk": 0x6a1b3a, "sick": 0x52734d, "gold": 0x7a5c00]
        let bg = bgs[ph.scene] ?? 0x2b2d42
        NSColor(hex: bg).setFill(); pic.fill()
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: pic).setClip()
        let faces: [String: Face] = ["sleep": .sleep, "eat": .eatOpen, "drunk": .crazy, "sick": .sick, "work": .focus]
        let poses: [String: Pose] = ["sleep": .sleep, "work": .type, "play": .wave, "friends": .wave, "drunk": .wobble]
        let face = faces[ph.scene] ?? .happy
        let pose = poses[ph.scene] ?? .idle
        let sp = buildSprite(level: max(1, ph.level), face: face, pose: pose, frame: 0, working: ph.scene == "work", worn: game.pet.worn,
                             variant: game.bodyVariant)
        let span = CGFloat(max(sp.maxX - sp.minX + 1, sp.maxY - sp.minY + 1))
        let s = min(3, (pic.height - 8) / span)
        let gx = pic.midX - CGFloat(sp.minX + sp.maxX + 1) / 2 * s
        let gy = pic.maxY - 4 - CGFloat(sp.groundY + 1) * s
        drawGrid(sp.grid, x: gx, y: gy, s: s, palette: game.color)
        switch ph.scene {
        case "rat":
            drawGrid(RatView.ratGrid(frame: 0, running: false), x: pic.maxX - 34, y: pic.maxY - 14, s: 1.8, palette: { c in
                c == "R" ? NSColor(hex: 0xff8fab) : game.color(c) })
        case "eat":
            NSColor(hex: 0xffca3a).setFill(); NSRect(x: pic.midX + 10, y: pic.midY - 4, width: 8, height: 8).fill()
        case "rain":
            NSColor(hex: 0x5dade2, alpha: 0.7).setFill()
            for i in 0..<14 { NSRect(x: pic.minX + CGFloat((i * 37) % Int(pic.width)), y: pic.minY + CGFloat((i * 23) % Int(pic.height)), width: 2, height: 6).fill() }
        case "friends":
            drawGrid(heartGrid, x: pic.maxX - 22, y: pic.minY + 6, s: 2, palette: game.color)
        case "gold":
            NSColor(hex: 0xffd166).setFill()
            for i in 0..<8 { NSRect(x: pic.minX + CGFloat((i * 29) % Int(pic.width)), y: pic.minY + CGFloat((i * 17) % Int(pic.height)), width: 3, height: 3).fill() }
        default: break
        }
        NSGraphicsContext.current?.restoreGraphicsState()
        let f = DateFormatter()
        f.dateFormat = "d.MM HH:mm"
        let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 8, weight: .heavy),
                                                .foregroundColor: NSColor(hex: 0x2b2b3a)]
        let cap = "\(photoCaptions[ph.scene] ?? "") · \(f.string(from: ph.date))" as NSString
        let cs = cap.size(withAttributes: a)
        cap.draw(at: NSPoint(x: r.midX - cs.width / 2, y: r.maxY - 18), withAttributes: a)
    }

    override func draw(_ dirtyRect: NSRect) {
        let b = bounds
        NSColor(hex: 0x1b1b24, alpha: 0.97).setFill(); b.fill()
        NSColor.white.setFill()
        for r in [NSRect(x: 0, y: 0, width: b.width, height: 3), NSRect(x: 0, y: b.height - 3, width: b.width, height: 3),
                  NSRect(x: 0, y: 0, width: 3, height: b.height), NSRect(x: b.width - 3, y: 0, width: 3, height: b.height)] { r.fill() }
        let title: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
                                                    .foregroundColor: NSColor.white]
        if let one = single {
            ("ВИЖ ТАЗИ СНИМКА!" as NSString).draw(at: NSPoint(x: 12, y: 10), withAttributes: title)
            drawPhoto(one, in: NSRect(x: 16, y: 32, width: b.width - 32, height: b.height - 44))
            return
        }
        var owner = "ПИКСЕЛКА"
        if let g = game, let k = g.buddyKind("photo") { owner = g.buddyName(k).uppercased() }
        ("АЛБУМЪТ НА \(owner)" as NSString).draw(at: NSPoint(x: 12, y: 10), withAttributes: title)
        ("X" as NSString).draw(at: NSPoint(x: closeRect.minX + 6, y: closeRect.minY + 2),
                               withAttributes: [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .heavy),
                                                .foregroundColor: NSColor(hex: 0xe63946)])
        let list = Array(photos.reversed())
        if list.isEmpty {
            ("ОЩЕ НЯМА СНИМКИ. ПИКСЕЛКА СНИМА, ДОКАТО РАБОТИ." as NSString).draw(at: NSPoint(x: 12, y: 60), withAttributes: title)
            return
        }
        let w = (b.width - 48) / 3, h = (b.height - 80) / 2
        for i in 0..<6 {
            let n = page * 6 + i
            guard n < list.count else { break }
            let r = NSRect(x: 12 + CGFloat(i % 3) * (w + 12), y: 34 + CGFloat(i / 3) * (h + 8), width: w, height: h)
            drawPhoto(list[n], in: r)
        }
        let nav: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .heavy),
                                                  .foregroundColor: NSColor(hex: 0xffd166)]
        if page > 0 { ("◀" as NSString).draw(at: NSPoint(x: prevRect.minX + 8, y: prevRect.minY + 2), withAttributes: nav) }
        if page < pages - 1 { ("▶" as NSString).draw(at: NSPoint(x: nextRect.minX + 8, y: nextRect.minY + 2), withAttributes: nav) }
        let pg = "\(page + 1)/\(pages)" as NSString
        pg.draw(at: NSPoint(x: b.midX - pg.size(withAttributes: nav).width / 2, y: b.height - 28), withAttributes: nav)
    }
}

extension Game {
    var photos: [Photo] {
        let raw = UserDefaults.standard.array(forKey: "photos") as? [[String: Any]] ?? []
        return raw.compactMap { d in
            guard let s = d["scene"] as? String, let t = d["t"] as? Double else { return nil }
            return Photo(scene: s, date: Date(timeIntervalSince1970: t), level: d["level"] as? Int ?? pet.level)
        }
    }

    /// Какво се случва сега (за снимката).
    var currentScene: String {
        if time < goldUntil { return "gold" }
        if pet.asleep { return "sleep" }
        if pet.working { return "work" }
        if action == .eat { return "eat" }
        if isDrunk { return "drunk" }
        if isSick { return "sick" }
        if playingGame || fetchPhase != .off { return "play" }
        if raining && !petRoofed { return "rain" }
        if ratIsOut && Bool.random() { return "rat" }
        if buddies.count > 1 { return "friends" }
        return "pose"
    }

    func takePhoto() {
        var raw = UserDefaults.standard.array(forKey: "photos") as? [[String: Any]] ?? []
        raw.append(["scene": currentScene, "t": Date().timeIntervalSince1970, "level": bodyCells])
        if raw.count > 60 { raw.removeFirst(raw.count - 60) }
        UserDefaults.standard.set(raw, forKey: "photos")
    }

    func openAlbum(single: Photo? = nil, near p: NSPoint? = nil) {
        closeAlbum()
        let size = single == nil ? NSSize(width: 480, height: 330) : NSSize(width: 200, height: 210)
        let vf = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        var o = p.map { NSPoint(x: $0.x - size.width / 2, y: $0.y + 10) } ?? NSPoint(x: vf.midX - size.width / 2, y: vf.midY - size.height / 2)
        o.x = min(max(o.x, vf.minX + 4), vf.maxX - size.width - 4)
        o.y = min(max(o.y, vf.minY + 4), vf.maxY - size.height - 4)
        let v = AlbumView(frame: NSRect(origin: .zero, size: size))
        v.game = self
        v.single = single
        let panel = overlayPanel(NSRect(origin: o, size: size), key: false)
        panel.contentView = v
        panel.orderFrontRegardless()
        albumPanel = panel
        albumOpened = time
        albumUntil = single == nil ? .greatestFiniteMagnitude : time + 7
    }

    func closeAlbum() {
        albumPanel?.orderOut(nil)
        albumPanel = nil
    }

    func updateAlbum() {
        guard let p = albumPanel else { return }
        if time > albumUntil || NSEvent.pressedMouseButtons != 0 && !p.frame.contains(NSEvent.mouseLocation) && time - albumOpened > 0.4 {
            closeAlbum()
        }
    }

    /// Пикселка понякога сама показва някоя снимка.
    func maybeShowPhoto(_ b: Buddy) {
        guard albumPanel == nil, let ph = photos.randomElement(), !pet.asleep else { return }
        buddySay(b, ["Виж тази снимка!", "Помниш ли това?", "Тази ми е любимата!"].randomElement()!, 3)
        let box = buddyScreenBox(b)
        openAlbum(single: ph, near: NSPoint(x: box.midX, y: box.maxY))
        pendingReply = (["Хаха, колко съм сладък тук!", "Леле, това бях аз?!", "Изтрий я! Шегувам се, запази я!"].randomElement()!,
                        time + 3, false)
    }
}
