// Истинското време навън: местоположението се взима приблизително по IP адреса (ipwho.is),
// а времето от Open-Meteo (без ключ). Дъжд, сняг, мъгла, облаци и гръмотевици по екрана.

import AppKit

enum WeatherKind { case clear, clouds, fog, rain, snow, storm }

struct WeatherDrop {
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var drift: CGFloat
}

final class WeatherView: NSView {
    weak var game: Game?
    var drops: [WeatherDrop] = []
    var flashAt: Double = -10

    override func draw(_ dirtyRect: NSRect) {
        guard let game else { return }
        let t = game.time
        switch game.weatherKind {
        case .rain, .storm:
            NSColor(hex: 0x5dade2, alpha: 0.55).setFill()
            for d in drops { NSRect(x: d.x, y: d.y, width: 2, height: 9).fill() }
        case .snow:
            NSColor(white: 1, alpha: 0.9).setFill()
            for d in drops { NSRect(x: d.x + CGFloat(sin(t + Double(d.drift))) * 6, y: d.y, width: 4, height: 4).fill() }
        case .fog:
            for i in 0..<4 {
                NSColor(white: 0.85, alpha: 0.07).setFill()
                NSRect(x: 0, y: 0, width: bounds.width, height: 120 + CGFloat(i) * 60).fill()
            }
        case .clouds:
            for (i, d) in drops.prefix(4).enumerated() {
                let x = (d.x + CGFloat(t * 8)).truncatingRemainder(dividingBy: bounds.width + 200) - 100
                let y = bounds.height - 60 - CGFloat(i % 2) * 40
                NSColor(white: 1, alpha: 0.35).setFill()
                for (dx, dy, w, h) in [(0.0, 0.0, 90.0, 22.0), (18.0, 14.0, 50.0, 20.0), (50.0, 8.0, 30.0, 18.0)] {
                    NSRect(x: x + CGFloat(dx), y: y + CGFloat(dy), width: CGFloat(w), height: CGFloat(h)).fill()
                }
            }
        case .clear:
            break
        }
        if t - flashAt < 0.15 {
            NSColor(white: 1, alpha: 0.35).setFill()
            bounds.fill()
        }
    }
}

extension Game {
    var weatherOn: Bool {
        get { UserDefaults.standard.object(forKey: "weatherOn") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "weatherOn") }
    }

    @objc func toggleWeather() {
        weatherOn.toggle()
        if weatherOn { nextWeatherFetch = 0 } else { weatherKind = .clear; closeWeather() }
    }

    var weatherText: String? {
        guard weatherOn, let temp = weatherTemp else { return nil }
        let names: [WeatherKind: String] = [.clear: "ясно", .clouds: "облачно", .fog: "мъгла", .rain: "дъжд", .snow: "сняг",
                                            .storm: "буря"]
        return "\(weatherCity.isEmpty ? "Навън" : weatherCity): \(Int(temp.rounded()))°, \(names[weatherKind] ?? "")"
    }

    /// Пита за времето на всеки 30 минути.
    func fetchWeather() {
        guard weatherOn, !weatherLoading else { return }
        weatherLoading = true
        let lat = weatherLat, lon = weatherLon
        if lat == nil || lon == nil {
            URLSession.shared.dataTask(with: URL(string: "https://ipwho.is/")!) { data, _, _ in
                var la: Double?
                var lo: Double?
                var city = ""
                if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    la = json["latitude"] as? Double
                    lo = json["longitude"] as? Double
                    city = json["city"] as? String ?? ""
                }
                let (a, b, c) = (la, lo, city)
                DispatchQueue.main.async { self.gotLocation(lat: a, lon: b, city: c) }
            }.resume()
            return
        }
        loadWeather(lat: lat!, lon: lon!)
    }

    func gotLocation(lat: Double?, lon: Double?, city: String) {
        weatherLoading = false
        guard let lat, let lon else { nextWeatherFetch = time + 10 * 60; return }
        weatherLat = lat
        weatherLon = lon
        weatherCity = city
        weatherLoading = true
        loadWeather(lat: lat, lon: lon)
    }

    func loadWeather(lat: Double, lon: Double) {
        let s = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code,is_day"
        guard let url = URL(string: s) else { weatherLoading = false; return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var code: Int?
            var temp: Double?
            if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let cur = json["current"] as? [String: Any] {
                code = (cur["weather_code"] as? NSNumber)?.intValue
                temp = (cur["temperature_2m"] as? NSNumber)?.doubleValue
            }
            let (c, t) = (code, temp)
            DispatchQueue.main.async { self.gotWeather(code: c, temp: t) }
        }.resume()
    }

    func gotWeather(code: Int?, temp: Double?) {
        weatherLoading = false
        guard let code, let temp else { nextWeatherFetch = time + 10 * 60; return }
        let old = weatherKind
        let kind: WeatherKind
        switch code {
        case 0: kind = .clear
        case 1...3: kind = .clouds
        case 45, 48: kind = .fog
        case 51...67, 80...82: kind = .rain
        case 71...77, 85, 86: kind = .snow
        case 95...99: kind = .storm
        default: kind = .clouds
        }
        weatherKind = kind
        let firstTime = weatherTemp == nil
        weatherTemp = temp
        if kind != old || firstTime { weatherChanged(firstTime: firstTime) }
    }

    /// Казва нещо за времето, когато се смени.
    func weatherChanged(firstTime: Bool) {
        guard !pet.asleep, window.isVisible, hidePhase == .off else { return }
        let temp = Int((weatherTemp ?? 15).rounded())
        let line: String
        switch weatherKind {
        case .rain: line = ["Вали навън! Вадя чадъра.", "Дъжд… перфектно време за монтаж.", "Капе! Добре, че съм вътре."].randomElement()!
        case .storm: line = ["Буря! Гръмотевици! Страх ме е!", "Бум! Чу ли това?!"].randomElement()!
        case .snow: line = ["Сняг! Брр, студено ми е!", "Вали сняг! Искам да правя снежен пиксел!"].randomElement()!
        case .fog: line = "Мъгла навън… нищо не се вижда."
        case .clouds: line = firstTime ? "Навън е облачно, \(temp)°." : "Облаци… дано не завали."
        case .clear: line = temp >= 28 ? "Жега! \(temp)°! Искам сладолед!" : (temp <= 0 ? "Ясно, но \(temp)°! Брр!" : "Слънчево навън! \(temp)°.")
        }
        say(line, seconds: 3.5)
    }

    func closeWeather() {
        weatherPanel?.orderOut(nil)
        weatherPanel = nil
        weatherView = nil
    }

    func updateWeather(_ step: Double) {
        if weatherOn && time > nextWeatherFetch {
            nextWeatherFetch = time + 30 * 60
            fetchWeather()
        }
        let shows = weatherOn && window.isVisible && weatherKind != .clear && !minimalMode
        guard shows else { if weatherPanel != nil { closeWeather() }; return }
        let pr = petScreenRect()
        guard let sf = screenAt(NSPoint(x: pr.midX, y: pr.midY))?.frame else { return }
        if weatherPanel == nil || weatherPanel?.frame != sf {
            closeWeather()
            let p = overlayPanel(sf, key: false)
            p.level = .floating
            p.ignoresMouseEvents = true
            let v = WeatherView(frame: NSRect(origin: .zero, size: sf.size))
            v.game = self
            p.contentView = v
            p.orderFrontRegardless()
            p.order(.below, relativeTo: window.windowNumber)
            weatherPanel = p
            weatherView = v
        }
        guard let v = weatherView else { return }
        // капки и снежинки
        let want = weatherKind == .rain || weatherKind == .storm ? 120 : (weatherKind == .snow ? 80 : 4)
        while v.drops.count < want {
            v.drops.append(WeatherDrop(x: CGFloat.random(in: 0...sf.width), y: CGFloat.random(in: 0...sf.height),
                                       speed: weatherKind == .snow ? CGFloat.random(in: 40...90) : CGFloat.random(in: 600...900),
                                       drift: CGFloat.random(in: 0...6)))
        }
        if v.drops.count > want { v.drops.removeLast(v.drops.count - want) }
        if weatherKind == .rain || weatherKind == .storm || weatherKind == .snow {
            for i in v.drops.indices {
                v.drops[i].y -= v.drops[i].speed * CGFloat(step)
                v.drops[i].x -= (weatherKind == .snow ? 0 : 60) * CGFloat(step)
                // капките спират в нарисуваното (покрив)
                let sx = sf.minX + v.drops[i].x, sy = sf.minY + v.drops[i].y
                let hitsDrawing = !drawCells.isEmpty && drawCells[cellKey(Int(floor(sx / drawCell)), Int(floor(sy / drawCell)))] != nil
                if v.drops[i].y < 0 || hitsDrawing {
                    v.drops[i].y = sf.height + 10
                    v.drops[i].x = CGFloat.random(in: 0...sf.width + 100)
                }
            }
        }
        updateRainShelter()
        if weatherKind == .storm && time > nextThunder {
            nextThunder = time + Double.random(in: 25...70)
            v.flashAt = time
            sfx("Submarine", every: 5)
            if !pet.asleep && hidePhase == .off && Bool.random() {
                glitchUntil = time + 0.4
                start(.angry, length: 1)
                say(["БУМ! Мамо!", "Гръмотевица! Крия се под монитора!", "Аааа! Светкавица!"].randomElement()!, seconds: 2)
            }
        }
        v.needsDisplay = true
    }

    var raining: Bool { weatherOn && (weatherKind == .rain || weatherKind == .storm) }

    /// Чадър над него, когато вали и няма покрив.
    var umbrellaUp: Bool { raining && !petRoofed && !pet.asleep && hidePhase == .off }

    /// Има ли нарисуван покрив над правоъгълника.
    func roofOver(_ r: NSRect) -> Bool {
        guard !drawCells.isEmpty else { return false }
        let c0 = Int(floor(r.minX / drawCell)), c1 = Int(floor(r.maxX / drawCell))
        let top = Int(floor(r.maxY / drawCell))
        for (k, _) in drawCells {
            let (x, y) = cellFromKey(k)
            if x >= c0 && x <= c1 && y >= top - 1 { return true }
        }
        return false
    }

    /// Място под покрив (нарисувано достатъчно високо над пода) най-близо до x.
    func roofSpot(near x: CGFloat, floor: CGFloat, height: CGFloat) -> CGFloat? {
        var best: CGFloat?
        for (k, _) in drawCells {
            let (cx, cy) = cellFromKey(k)
            let cellY = CGFloat(cy) * drawCell
            guard cellY > floor + height + 4, cellY < floor + height + 400 else { continue }
            let px = (CGFloat(cx) + 0.5) * drawCell
            if best == nil || abs(px - x) < abs(best! - x) { best = px }
        }
        return best
    }

    /// Вали: буди ги, искат покрив; ако има нарисуван, отиват под него.
    func updateRainShelter() {
        guard time > nextRoofCheck else { return }
        nextRoofCheck = time + 1
        guard raining else { petRoofed = false; return }
        let pr = petScreenRect()
        let wasRoofed = petRoofed
        petRoofed = roofOver(pr.insetBy(dx: 10, dy: 0))
        if petRoofed && !wasRoofed && !pet.asleep { say("Ааа, сухо! Благодаря за покрива!", seconds: 2.5) }
        if !petRoofed {
            if pet.asleep && time > nextRainWake {
                nextRainWake = time + 10 * 60
                pet.asleep = false
                say("Мокър съм! Вали върху мен! Нарисувай ми покрив!", seconds: 3.5)
                annoy(8, reason: "валеше върху мен")
            } else if !pet.asleep && time > nextRoofAsk && hidePhase == .off {
                nextRoofAsk = time + 8 * 60
                if let x = roofSpot(near: pr.midX, floor: floorY, height: pr.height), !busyMoving && !pet.working {
                    walkTarget = x - bodyCenterOffset
                    say("Отивам под покрива!", seconds: 2)
                } else {
                    say(["Вали! Нарисувай ми покрив!", "Капе ми на главата! Искам покрив!"].randomElement()!, seconds: 3)
                }
            }
        }
        // приятелите също искат покрив
        for b in buddies where !b.leaving {
            let box = buddyScreenBox(b)
            if roofOver(box.insetBy(dx: 6, dy: 0)) { continue }
            if b.sleeping && Int.random(in: 0..<30) == 0 {
                b.sleeping = false
                b.energy = max(b.energy, 40)
                buddySay(b, "Вали! Събудих се мокр\(b.kind.female ? "а" : "")! Искам покрив!", 3)
            } else if !b.sleeping && Int.random(in: 0..<40) == 0 {
                if let x = roofSpot(near: box.midX, floor: floorY, height: box.height) { b.wanderX = x }
                else { buddySay(b, "Вали! Някой да нарисува покрив!", 2.5) }
            }
        }
    }
}
