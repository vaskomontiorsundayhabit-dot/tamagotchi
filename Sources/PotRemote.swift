// Дистанционно от телефона: страницата remote/index.html праща команди (полей, тор…) през ntfy.sh,
// а саксията на Mac-а ги изпълнява и връща кратко състояние. Растението си живее само тук.

import AppKit
import CoreImage

let potRemotePage = "https://raw.githack.com/vaskomontiorsundayhabit-dot/tamagotchi/main/remote/index.html"

/// Дълга връзка към ntfy.sh: всяка нова команда идва веднага; при прекъсване се свързва пак.
final class PotRemoteLink: NSObject, URLSessionDataDelegate {
    let topic: String
    var onCommand: (String) -> Void = { _ in }
    private var session: URLSession!
    private var task: URLSessionDataTask?
    private var buffer = Data()
    private var lastId: String {
        get { UserDefaults.standard.string(forKey: "pot_remoteLast") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "pot_remoteLast") }
    }

    init(topic: String) {
        self.topic = topic
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    func start() {
        task?.cancel()
        buffer = Data()
        let since = lastId.isEmpty ? "10m" : lastId
        guard let url = URL(string: "https://ntfy.sh/\(topic)/json?since=\(since)") else { return }
        var req = URLRequest(url: url)
        req.timeoutInterval = 120          // ntfy праща „жив съм“ на всеки 45 с
        task = session.dataTask(with: req)
        task?.resume()
    }

    func stop() { let t = task; task = nil; t?.cancel() }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard dataTask === task else { return }
        buffer.append(data)
        while let nl = buffer.firstIndex(of: 10) {
            let line = Data(buffer[buffer.startIndex..<nl])
            buffer.removeSubrange(buffer.startIndex...nl)
            guard let obj = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any],
                  obj["event"] as? String == "message",
                  let id = obj["id"] as? String, let msg = obj["message"] as? String else { continue }
            lastId = id
            onCommand(msg.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard task === self.task else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, self.task === task else { return }
            self.start()
        }
    }
}

private var remoteLink: PotRemoteLink?
private var remoteQueue: [String] = []
private var remoteStatusAt: Double = -1000
private var remoteStatusPending = false

extension PotGame {
    var remoteKey: String {
        if let k = d.string(forKey: "pot_remoteKey"), !k.isEmpty { return k }
        let chars = Array("abcdefghijkmnpqrstuvwxyz23456789")
        let k = String((0..<22).map { _ in chars.randomElement()! })
        d.set(k, forKey: "pot_remoteKey")
        return k
    }
    var remoteURL: String { potRemotePage + "#" + remoteKey }

    func setUpRemote() {
        remoteLink?.stop()
        let link = PotRemoteLink(topic: "pot-\(remoteKey)-c")
        link.onCommand = { [weak self] cmd in self?.queueRemote(cmd) }
        link.start()
        remoteLink = link
        publishRemoteStatus()
    }

    /// Команди, дошли накуп (напр. след сън), се изпълняват една по една.
    private func queueRemote(_ cmd: String) {
        remoteQueue.append(cmd)
        if remoteQueue.count == 1 { runRemoteQueue() }
    }

    private func runRemoteQueue() {
        guard let cmd = remoteQueue.first else { return }
        handleRemote(cmd)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            if !remoteQueue.isEmpty { remoteQueue.removeFirst() }
            self?.runRemoteQueue()
        }
    }

    func handleRemote(_ cmd: String) {
        switch cmd {
        case "water": waterIt()
        case "fert": fertilize()
        case "weeds": pullAllWeeds(); if !weedPanels.isEmpty { pullAllFloorWeeds() }
        case "ants": shooAllAnts()
        case "pick": pickFruit()
        case "feed":
            if fruitsCollected > 0 { fruitsCollected -= 1; feedFruit() } else { say("Кофата е празна!", 2) }
        case "feedc":
            if fruitsCollected > 0 && creature != nil { fruitsCollected -= 1; feedCreature() }
        case "pet": petCreature()
        case "pet2": petCreature2()
        case "egg": warmEgg()
        case "bell": ringBell()
        case "wish": if wishReady { grantWish() }
        case "ping": break
        default: return
        }
        requestRemoteStatus()
    }

    /// Пресни данни за телефона след команда (събрани, не повече от веднъж на 15 с).
    func requestRemoteStatus() {
        guard !remoteStatusPending else { return }
        remoteStatusPending = true
        let wait = max(2.5, 15 - (time - remoteStatusAt))
        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
            remoteStatusPending = false
            self?.publishRemoteStatus()
        }
    }

    /// Всяка минута от тика: на 30 мин праща състояние, за да знае телефонът, че Mac-ът е буден.
    func updateRemote() {
        if time - remoteStatusAt > 30 * 60 { publishRemoteStatus() }
    }

    func publishRemoteStatus() {
        remoteStatusAt = time
        let j = (d.array(forKey: "pot_journal") as? [[String: Any]] ?? []).suffix(5).reversed().map { e -> [String: Any] in
            let text = (e["text"] as? String ?? "").replacingOccurrences(of: #" от \d+:"#, with: ":", options: .regularExpression)
            return ["t": e["t"] as? Double ?? 0, "x": String(text.prefix(110))]
        }
        var s: [String: Any] = [
            "v": 1, "t": Date().timeIntervalSince1970,
            "stage": potStageNames[stage], "st": stage, "pct": Int(stageProgress * 100),
            "water": Int(water), "health": Int(health),
            "fruits": fruitsOnPlant, "bucket": fruitsCollected,
            "weeds": weeds.count + weedPanels.count, "ants": ants.count,
            "fert": Date().timeIntervalSince(lastFert) > 2 * 3600,
            "wish": wishReady, "egg": hasEgg ? Int(eggCare) : -1,
            "hidden": hidden, "j": j,
        ]
        if creature != nil { s["c1"] = creatureName }
        if creature2 != nil { s["c2"] = creature2Name }
        guard let body = try? JSONSerialization.data(withJSONObject: s),
              let url = URL(string: "https://ntfy.sh/pot-\(remoteKey)-s") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        URLSession.shared.dataTask(with: req).resume()
    }

    @objc func showRemote() {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = "📱 Дистанционно от телефона"
        a.informativeText = "Насочи камерата на телефона към кода и отвори линка. "
            + "Оттам можеш да поливаш, ториш и береш, а саксията тук го прави веднага.\n\n"
            + "На iPhone: Сподели → „Добави към началния екран“, за да го имаш като иконка."
        if let img = qrImage(remoteURL) {
            let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: 220, height: 220))
            iv.image = img
            iv.imageScaling = .scaleProportionallyUpOrDown
            a.accessoryView = iv
        }
        a.addButton(withTitle: "Готово")
        a.addButton(withTitle: "Копирай линка")
        a.addButton(withTitle: "Нов код (старият телефон спира)")
        switch a.runModal() {
        case .alertSecondButtonReturn:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(remoteURL, forType: .string)
        case .alertThirdButtonReturn:
            d.removeObject(forKey: "pot_remoteKey")
            d.removeObject(forKey: "pot_remoteLast")
            setUpRemote()
            showRemote()
        default: break
        }
    }

    private func qrImage(_ text: String) -> NSImage? {
        guard let f = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        f.setValue(text.data(using: .utf8), forKey: "inputMessage")
        f.setValue("M", forKey: "inputCorrectionLevel")
        guard let ci = f.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        let rep = NSCIImageRep(ciImage: ci)
        let img = NSImage(size: rep.size)
        img.addRepresentation(rep)
        return img
    }
}
