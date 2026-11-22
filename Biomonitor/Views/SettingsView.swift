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
    @Binding var doubleTap: Bool
    let palette: Palette
    var onGuide: () -> Void = {}

    /// una sola pantalla de fichas, sin scroll: asi la corona sigue navegando entre pantallas.
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                tile(tr(.color, lang), paletteID.title(lang), true) { paletteID = paletteID == .fitbit ? .codex : .fitbit }
                tile(tr(.language, lang), lang.title, true) { lang = lang == .es ? .en : .es }
            }
            HStack(spacing: 6) {
                switchTile(tr(.liveHR, lang), $live)
                switchTile(tr(.sound, lang), $sound)
            }
            HStack(spacing: 6) {
                switchTile(tr(.haptic, lang), $haptic)
                switchTile(tr(.beep, lang), $beep)
            }
            HStack(spacing: 6) {
                switchTile(tr(.clock24, lang), $use24h)
                switchTile(tr(.doubleTap, lang), $doubleTap)
            }
            HStack(spacing: 6) {
                tile(tr(.guide, lang), tr(.show, lang), true, action: onGuide)
                tile(tr(.info, lang), "1.0", false) {}
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private func switchTile(_ label: String, _ b: Binding<Bool>) -> some View {
        tile(label, b.wrappedValue ? tr(.on, lang) : tr(.off, lang), b.wrappedValue) { b.wrappedValue.toggle() }
    }

    private func tile(_ label: String, _ value: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            SoundFX.shared.play(.tap)
            WKInterfaceDevice.current().play(.click)
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.monitor(12, weight: .medium))
                    .foregroundStyle(palette.dim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(value)
                    .font(.monitor(17, weight: .bold))
                    .foregroundStyle(active ? palette.trace : palette.dim)
                    .shadow(color: active ? palette.trace.opacity(0.6) : .clear, radius: 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 7)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(palette.dim.opacity(0.12))
            .overlay(Rectangle().stroke(active ? palette.trace.opacity(0.7) : palette.dim.opacity(0.35), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
