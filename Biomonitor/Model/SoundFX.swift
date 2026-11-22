import AVFoundation

/// sonidos sinteticos tipo monitor de hospital. se generan al arrancar; no hay archivos de audio.
final class SoundFX {
    static let shared = SoundFX()

    enum Cue: CaseIterable { case beat, tap, page, boot, fine, caution, danger }

    var enabled = true
    var beatEnabled = false

    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    private var buffers: [Cue: AVAudioPCMBuffer] = [:]
    private var running = false

    private init() {
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        buffers[.beat] = make([(1050, 0.075, 0.55)])
        buffers[.tap] = make([(1500, 0.025, 0.25)])
        buffers[.page] = make([(900, 0.03, 0.25), (0, 0.01, 0), (1350, 0.035, 0.25)])
        buffers[.boot] = make([(520, 0.09, 0.4), (0, 0.03, 0), (780, 0.09, 0.4), (0, 0.03, 0), (1040, 0.2, 0.45)])
        buffers[.fine] = make([(880, 0.08, 0.4), (0, 0.02, 0), (1320, 0.16, 0.4)])
        buffers[.caution] = make([(740, 0.1, 0.5), (0, 0.07, 0), (740, 0.1, 0.5)])
        buffers[.danger] = make([(1000, 0.12, 0.6), (700, 0.12, 0.6), (1000, 0.12, 0.6), (700, 0.12, 0.6)])
    }

    /// (frecuencia, duracion, volumen); frecuencia 0 = silencio
    private func make(_ tones: [(Double, Double, Double)]) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let total = Int(tones.reduce(0) { $0 + $1.1 } * rate) + 1
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total))!
        buf.frameLength = AVAudioFrameCount(total)
        let out = buf.floatChannelData![0]
        var i = 0
        for (f, d, v) in tones {
            let n = Int(d * rate)
            for k in 0..<n where i + k < total {
                let t = Double(k) / rate
                let env = min(1, t / 0.003) * exp(-t / (d * 0.55))
                let s = f == 0 ? 0 : (sin(2 * .pi * f * t) + 0.25 * sin(4 * .pi * f * t)) / 1.25
                out[i + k] = Float(s * env * v)
            }
            i += n
        }
        return buf
    }

    private func start() {
        guard !running else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            node.play()
            running = true
        } catch {
            running = false
        }
    }

    func play(_ cue: Cue) {
        guard enabled, let b = buffers[cue] else { return }
        start()
        guard running else { return }
        node.scheduleBuffer(b, at: nil, options: .interrupts)
    }

    func playBeat() {
        guard beatEnabled else { return }
        let was = enabled
        enabled = true
        play(.beat)
        enabled = was
    }
}
