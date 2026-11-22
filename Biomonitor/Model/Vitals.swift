import SwiftUI

/// un punto del historial de pulso
struct HRPoint: Equatable {
    var date: Date
    var bpm: Int
}

/// lo que muestran las pantallas. valores simples para que las vistas no dependan de healthkit.
struct VitalsSnapshot: Equatable {
    var bpm: Int?
    var steps = 0
    var distanceKm = 0.0
    var kcal = 0
    var minHR: Int?
    var maxHR: Int?
    var avgHR: Int?
    var restingHR: Int?
    var history: [HRPoint] = []
}

/// estado de salud al estilo de la saga: fine, caution, danger.
enum Condition {
    case fine, caution, danger, noSignal

    init(bpm: Int?) {
        guard let bpm else { self = .noSignal; return }
        switch bpm {
        case ..<40: self = .danger
        case 40..<120: self = .fine
        case 120..<160: self = .caution
        default: self = .danger
        }
    }

    var label: String {
        switch self {
        case .fine: "FINE"
        case .caution: "CAUTION"
        case .danger: "DANGER"
        case .noSignal: "NO SIGNAL"
        }
    }

    var color: Color {
        switch self {
        case .fine: Color(red: 0.20, green: 0.85, blue: 0.30)
        case .caution: Color(red: 0.98, green: 0.72, blue: 0.14)
        case .danger: Color(red: 0.93, green: 0.18, blue: 0.16)
        case .noSignal: Color(white: 0.45)
        }
    }
}

/// zona 0...4 segun el pulso, para las barritas junto al numero
func heartZone(_ bpm: Int?) -> Int {
    guard let bpm else { return 0 }
    switch bpm {
    case ..<60: return 1
    case 60..<100: return 2
    case 100..<140: return 3
    default: return 4
    }
}

enum PaletteID: String, CaseIterable, Identifiable {
    case fitbit, codex
    var id: String { rawValue }
    var title: String { self == .fitbit ? "VERDE" : "CIAN" }
    var palette: Palette { self == .fitbit ? .fitbit : .codex }
}

/// dos looks: el reloj de la escena de la caja (verde) y el de la pantalla del genoma (cian y azul).
struct Palette {
    var text: Color
    var dim: Color
    var trace: Color
    var frame: Color
    var accent: Color

    static let fitbit = Palette(
        text: Color(red: 0.88, green: 0.93, blue: 1.0),
        dim: Color(red: 0.45, green: 0.52, blue: 0.62),
        trace: Color(red: 0.18, green: 0.84, blue: 0.27),
        frame: Color(red: 0.62, green: 0.78, blue: 1.0),
        accent: Color(red: 0.90, green: 0.14, blue: 0.16))

    static let codex = Palette(
        text: Color(red: 0.72, green: 0.97, blue: 0.93),
        dim: Color(red: 0.25, green: 0.50, blue: 0.55),
        trace: Color(red: 0.26, green: 0.93, blue: 0.80),
        frame: Color(red: 0.25, green: 0.55, blue: 0.95),
        accent: Color(red: 0.90, green: 0.14, blue: 0.16))
}

/// fuente condensada y ancha de numeros, como la del reloj
extension Font {
    static func monitor(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight).width(.condensed)
    }
}
