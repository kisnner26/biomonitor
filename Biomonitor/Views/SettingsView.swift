import SwiftUI

struct SettingsView: View {
    @Binding var paletteID: PaletteID
    @Binding var lang: Lang
    @Binding var haptic: Bool
    @Binding var beep: Bool
    @Binding var sound: Bool
    @Binding var live: Bool
    @Binding var use24h: Bool
    let palette: Palette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Picker(tr(.color, lang), selection: $paletteID) {
                    ForEach(PaletteID.allCases) { Text($0.title(lang)).tag($0) }
                }
                .pickerStyle(.navigationLink)

                Picker(tr(.language, lang), selection: $lang) {
                    ForEach(Lang.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.navigationLink)

                Toggle(tr(.liveHR, lang), isOn: $live)
                Toggle(tr(.haptic, lang), isOn: $haptic)
                Toggle(tr(.beep, lang), isOn: $beep)
                Toggle(tr(.sound, lang), isOn: $sound)
                Toggle(tr(.clock24, lang), isOn: $use24h)

                Text(tr(.note, lang))
                    .font(.system(size: 11))
                    .foregroundStyle(palette.dim)
                    .padding(.top, 4)
                Text("BIOMONITOR 1.0")
                    .font(.monitor(11, weight: .medium))
                    .foregroundStyle(palette.dim.opacity(0.7))
            }
            .tint(palette.trace)
            .padding(.horizontal, 6)
        }
    }
}
