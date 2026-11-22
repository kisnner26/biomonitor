import SwiftUI
import WatchKit

/// ajustes con filas propias: tocar una fila cambia su valor. sin listas ni pilas de navegacion del sistema.
struct SettingsView: View {
    @Binding var paletteID: PaletteID
    @Binding var lang: Lang
    @Binding var haptic: Bool
    @Binding var beep: Bool
    @Binding var sound: Bool
    @Binding var live: Bool
    @Binding var use24h: Bool
    let palette: Palette
    var onGuide: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                row(tr(.color, lang), paletteID.title(lang), true) {
                    paletteID = paletteID == .fitbit ? .codex : .fitbit
                }
                row(tr(.language, lang), lang.title, true) {
                    lang = lang == .es ? .en : .es
                }
                toggle(tr(.liveHR, lang), $live)
                toggle(tr(.haptic, lang), $haptic)
                toggle(tr(.beep, lang), $beep)
                toggle(tr(.sound, lang), $sound)
                toggle(tr(.clock24, lang), $use24h)
                row(tr(.guide, lang), tr(.show, lang), true, action: onGuide)

                Text(tr(.note, lang))
                    .font(.system(size: 11))
                    .foregroundStyle(palette.dim)
                    .padding(.vertical, 8)
                Text("BIOMONITOR 1.0")
                    .font(.monitor(11, weight: .medium))
                    .foregroundStyle(palette.dim.opacity(0.7))
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 8)
        }
    }

    private func toggle(_ label: String, _ b: Binding<Bool>) -> some View {
        row(label, b.wrappedValue ? tr(.on, lang) : tr(.off, lang), b.wrappedValue) { b.wrappedValue.toggle() }
    }

    private func row(_ label: String, _ value: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            SoundFX.shared.play(.tap)
            WKInterfaceDevice.current().play(.click)
        } label: {
            VStack(spacing: 0) {
                HStack {
                    Text(label)
                        .font(.monitor(16, weight: .medium))
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 6)
                    Text(value)
                        .font(.monitor(14, weight: .bold))
                        .foregroundStyle(active ? palette.trace : palette.dim)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .overlay(Rectangle().stroke(active ? palette.trace.opacity(0.8) : palette.dim.opacity(0.5), lineWidth: 1))
                        .contentTransition(.identity)
                }
                .padding(.vertical, 8)
                Rectangle().fill(palette.frame.opacity(0.25)).frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
