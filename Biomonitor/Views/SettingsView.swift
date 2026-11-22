import SwiftUI

struct SettingsView: View {
    @Binding var paletteID: PaletteID
    @Binding var haptic: Bool
    @Binding var live: Bool
    @Binding var use24h: Bool
    let palette: Palette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("AJUSTES")
                    .font(.monitor(12, weight: .medium))
                    .foregroundStyle(palette.dim)

                Picker("Color", selection: $paletteID) {
                    ForEach(PaletteID.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.navigationLink)

                Toggle("Pulso en vivo", isOn: $live)
                Toggle("Latido tactil", isOn: $haptic)
                Toggle("Reloj 24 h", isOn: $use24h)

                Text("El pulso en vivo abre una sesion de entrenamiento temporal que no se guarda en Salud. La onda es sintetica y sigue tu pulso real; no es un electrocardiograma.")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.dim)
                    .padding(.top, 4)
            }
            .tint(palette.trace)
            .padding(.horizontal, 6)
        }
    }
}
