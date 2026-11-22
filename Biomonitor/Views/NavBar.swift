import SwiftUI

/// barra superior propia: nombre de la pagina y cuatro segmentos. sustituye los puntos del sistema.
struct NavBar: View {
    let page: Int
    let palette: Palette
    @Environment(\.lang) private var lang

    private var title: String {
        switch page {
        case 0: tr(.monitor, lang)
        case 1: tr(.status, lang)
        case 2: tr(.activity, lang)
        default: tr(.settings, lang)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.monitor(11, weight: .semibold))
                .foregroundStyle(palette.dim)
                .id(title)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            Spacer(minLength: 4)
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(i == page ? palette.trace : palette.dim.opacity(0.3))
                        .frame(width: i == page ? 14 : 7, height: 3)
                        .shadow(color: i == page ? palette.trace.opacity(0.9) : .clear, radius: 3)
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: page)
    }
}
