import SwiftUI

enum Lang: String, CaseIterable, Identifiable {
    case es, en
    var id: String { rawValue }
    var title: String { self == .es ? "ESPAÑOL" : "ENGLISH" }
    static var system: Lang { Locale.current.language.languageCode?.identifier == "es" ? .es : .en }
}

private struct LangKey: EnvironmentKey { static let defaultValue = Lang.es }
extension EnvironmentValues {
    var lang: Lang {
        get { self[LangKey.self] }
        set { self[LangKey.self] = newValue }
    }
}

enum L {
    case monitor, face, status, activity, settings, settings2
    case guide, show, on, off, hintTitle, hintBody, hintDismiss
    case condition, min, avg, max, rest
    case steps, km, kcal
    case color, language, liveHR, haptic, beep, sound, clock24, note
    case green, cyan
    case fine, caution, danger, noSignal
    case tipStable, tipHerb, tipAid, tipNoSignal
}

func tr(_ k: L, _ lang: Lang) -> String {
    let es = lang == .es
    switch k {
    case .monitor: return es ? "MONITOR" : "MONITOR"
    case .settings2: return es ? "PULSO Y SONIDO" : "PULSE & SOUND"
    case .face: return es ? "CARATULA" : "WATCH FACE"
    case .status: return es ? "ESTADO" : "STATUS"
    case .activity: return es ? "ACTIVIDAD" : "ACTIVITY"
    case .settings: return es ? "AJUSTES" : "SETTINGS"
    case .condition: return es ? "CONDICION" : "CONDITION"
    case .min: return "MIN"
    case .avg: return es ? "PROM" : "AVG"
    case .max: return "MAX"
    case .rest: return es ? "REPOSO" : "RESTING"
    case .steps: return es ? "PASOS" : "STEPS"
    case .km: return "KM"
    case .kcal: return "KCAL"
    case .color: return "Color"
    case .language: return es ? "Idioma" : "Language"
    case .liveHR: return es ? "Pulso en vivo" : "Live heart rate"
    case .haptic: return es ? "Latido táctil" : "Haptic heartbeat"
    case .beep: return es ? "Bip del pulso" : "Pulse beep"
    case .sound: return es ? "Sonido" : "Sound"
    case .clock24: return es ? "Reloj 24 h" : "24-hour clock"
    case .note: return es
        ? "El pulso en vivo abre una sesión de entrenamiento temporal que no se guarda en Salud. La onda es sintética y sigue tu pulso real; no es un electrocardiograma."
        : "Live heart rate opens a temporary workout session that is never saved to Health. The wave is synthetic and follows your real pulse; it is not an ECG."
    case .guide: return es ? "Guía de la corona" : "Crown guide"
    case .show: return es ? "VER" : "SHOW"
    case .on: return "ON"
    case .off: return "OFF"
    case .hintTitle: return es ? "NAVEGACION" : "NAVIGATION"
    case .hintBody: return es ? "Gira la corona digital para cambiar de pantalla" : "Turn the Digital Crown to switch screens"
    case .hintDismiss: return es ? "TOCA PARA CONTINUAR" : "TAP TO CONTINUE"
    case .green: return es ? "VERDE" : "GREEN"
    case .cyan: return es ? "CIAN" : "CYAN"
    case .fine: return es ? "BIEN" : "FINE"
    case .caution: return es ? "PRECAUCION" : "CAUTION"
    case .danger: return es ? "PELIGRO" : "DANGER"
    case .noSignal: return es ? "SIN SEÑAL" : "NO SIGNAL"
    case .tipStable: return es ? "SIGNOS ESTABLES" : "VITALS STABLE"
    case .tipHerb: return es ? "USA: HIERBA VERDE" : "USE: GREEN HERB"
    case .tipAid: return es ? "USA: BOTIQUIN" : "USE: FIRST AID"
    case .tipNoSignal: return es ? "AJUSTA EL RELOJ" : "TIGHTEN THE STRAP"
    }
}
