// Истински видеа: за всяко монтирано видео Пиксчо записва компилация (.mp4) от своите
// клипове в папка „Пиксчо“ в Movies.

import AppKit
import AVFoundation

final class CompilationWriter: NSObject {
    let writer: AVAssetWriter
    let input: AVAssetWriterInput
    let adaptor: AVAssetWriterInputPixelBufferAdaptor
    let view: ClipView
    var frames: [(clip: Int, t: Double)] = []
    var index = 0
    let fps: Int32 = 15
    let size = NSSize(width: 320, height: 240)
    var timer: Timer?
    weak var game: Game?
    let url: URL
    let number: Int

    init?(url: URL, clips: [Int], game: Game, number: Int) {
        guard let w = try? AVAssetWriter(outputURL: url, fileType: .mp4) else { return nil }
        writer = w
        self.url = url
        self.number = number
        input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 320,
            AVVideoHeightKey: 240,
        ])
        input.expectsMediaDataInRealTime = false
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: 320,
            kCVPixelBufferHeightKey as String: 240,
        ])
        view = ClipView(frame: NSRect(x: 0, y: 0, width: 320, height: 240))
        self.game = game
        super.init()
        view.game = game
        guard writer.canAdd(input) else { return nil }
        writer.add(input)
        // всеки клип: кратко заглавие + 2,4 с от сцената; накрая „КРАЙ“
        for (i, c) in clips.enumerated() {
            var t = 0.4
            while t < 3.3 { frames.append((c, t)); t += 1.0 / Double(fps) }
            if i == clips.count - 1 {
                var e = ClipView.length - 0.9
                while e < ClipView.length - 0.05 { frames.append((c, e)); e += 1.0 / Double(fps) }
            }
        }
    }

    func start() {
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        let t = Timer(timeInterval: 0.03, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// По няколко кадъра наведнъж, за да не спира Пиксчо да се движи.
    @objc func step() {
        var done = 0
        while done < 4 && index < frames.count && input.isReadyForMoreMediaData {
            let f = frames[index]
            if let buffer = render(clip: f.clip, t: f.t) {
                adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: fps))
            }
            index += 1
            done += 1
        }
        if index >= frames.count {
            timer?.invalidate()
            timer = nil
            input.markAsFinished()
            let url = self.url, n = number, w = writer, g = game
            writer.finishWriting {
                let ok = w.status == .completed
                DispatchQueue.main.async { g?.compilationFinished(url: url, number: n, ok: ok) }
            }
        }
    }

    private func render(clip: Int, t: Double) -> CVPixelBuffer? {
        view.clip = clip
        view.fixedTime = t
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let cg = rep.cgImage else { return nil }
        var pb: CVPixelBuffer?
        guard let pool = adaptor.pixelBufferPool,
              CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pb) == kCVReturnSuccess, let buffer = pb else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: 320, height: 240, bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: 320, height: 240))
        return buffer
    }
}

extension Game {
    var videosFolder: URL {
        let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Movies")
        return movies.appendingPathComponent("Пиксчо", isDirectory: true)
    }

    /// Нова компилация от 3 различни клипа, докато монтира.
    func exportCompilation() {
        guard compilationWriter == nil else { return }
        let folder = videosFolder
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let n = pet.videos
        let url = folder.appendingPathComponent("Пиксчо компилация \(n).mp4")
        try? FileManager.default.removeItem(at: url)
        var pool = Array(0..<clipTitles.count)
        pool.shuffle()
        guard let w = CompilationWriter(url: url, clips: Array(pool.prefix(3)), game: self, number: n) else { return }
        compilationWriter = w
        w.start()
    }

    func compilationFinished(url: URL, number: Int, ok: Bool) {
        compilationWriter = nil
        guard ok else { return }
        if bubbleText == nil || pet.working {
            say("Готова е компилация №\(number)! Виж папката с видеата.", seconds: 4)
        }
    }

    @objc func openVideosFolder() {
        try? FileManager.default.createDirectory(at: videosFolder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(videosFolder)
    }
}
