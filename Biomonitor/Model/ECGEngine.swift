import Foundation

/// genera el trazo del monitor. la forma de la onda es sintetica (p, qrs, t) y su frecuencia sigue
/// el pulso real; no es un electrocardiograma medido.
/// el trazo avanza de izquierda a derecha y se sobreescribe, como un monitor de hospital.
final class ECGEngine {
    let columns = 150
    let windowSeconds = 3.4
    private(set) var buffer: [Double?]
    private(set) var cursor = 0
    private var phase = 0.0
    private var accumulator = 0.0
    private var lastDate: Date?
    /// momento del ultimo pico R; las animaciones se sincronizan con el
    private(set) var lastBeat: Date?
    /// cuenta de latidos; quien quiera reaccionar compara con el ultimo valor visto
    private(set) var beatCount = 0
    private var seed: UInt64 = 0x9E3779B97F4A7C15

    init() { buffer = Array(repeating: nil, count: columns) }

    /// anchura del hueco que borra delante del cursor
    var gapColumns: Int { columns / 14 }

    static func wave(_ p: Double) -> Double {
        func g(_ x: Double, _ mu: Double, _ s: Double) -> Double { exp(-pow(x - mu, 2) / (2 * s * s)) }
        return 0.15 * g(p, 0.16, 0.035)
            - 0.13 * g(p, 0.34, 0.012)
            + 1.00 * g(p, 0.37, 0.011)
            - 0.30 * g(p, 0.40, 0.012)
            + 0.27 * g(p, 0.62, 0.05)
    }

    private func noise() -> Double {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return (Double(seed >> 40) / Double(1 << 24) - 0.5) * 0.03
    }

    func advance(to date: Date, bpm: Int?) {
        guard let last = lastDate else { lastDate = date; return }
        var dt = date.timeIntervalSince(last)
        lastDate = date
        if dt > 1 || dt < 0 { dt = 0.05 }
        let step = windowSeconds / Double(columns)
        accumulator += dt
        while accumulator >= step {
            accumulator -= step
            push(bpm: bpm, step: step)
        }
    }

    private func push(bpm: Int?, step: Double) {
        if let bpm {
            buffer[cursor] = Self.wave(phase) + noise() * 0.5
            let raw = phase + step * Double(bpm) / 60
            if (raw - 0.37).rounded(.down) > (phase - 0.37).rounded(.down) { lastBeat = lastDate; beatCount += 1 }
            phase = raw - raw.rounded(.down)
        } else {
            buffer[cursor] = noise()   // sin señal: linea plana
        }
        cursor = (cursor + 1) % columns
    }

    /// llena la pantalla de golpe (para el modo de poco brillo y para capturas)
    func prefill(bpm: Int?) {
        let step = windowSeconds / Double(columns)
        for _ in 0..<(columns - gapColumns - 2) { push(bpm: bpm, step: step) }
    }

    /// true si la columna esta en el hueco delante del cursor
    func isGap(_ i: Int) -> Bool {
        let d = (i - cursor + columns) % columns
        return d < gapColumns
    }
}
