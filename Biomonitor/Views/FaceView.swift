import SwiftUI

/// pagina de caratula: hora enorme, fecha, trazo y datos. pensada para dejarla en pantalla como un reloj.
struct FaceView: View {
    let snapshot: VitalsSnapshot
    let palette: Palette
    let engine: ECGEngine
    let now: Date
    let use24h: Bool
    var dimmed = false
    @Environment(\.lang) private var lang

    private func fmt(_ pattern: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang.rawValue)
        f.dateFormat = pattern
        return f.string(from: now)
    }

    var body: some View {
        let ink = dimmed ? palette.text.opacity(0.75) : palette.text
        VStack(spacing: 2) {
            Text(fmt("EEE dd MMM").uppercased().replacingOccurrences(of: ".", with: ""))
                .font(.monitor(15, weight: .medium))
                .foregroundStyle(palette.dim)
            HStack(spacing: 0) {
                Text(fmt(use24h ? "HH" : "h"))
                Text(":")
                    .opacity(dimmed || Int(now.timeIntervalSince1970) % 2 == 0 ? 1 : 0.2)
                Text(fmt("mm"))
            }
            .font(.monitor(70, weight: .bold))
            .foregroundStyle(ink)
            .shadow(color: dimmed ? .clear : palette.trace.opacity(0.35), radius: 8)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            ECGTraceView(engine: engine, bpm: snapshot.bpm, color: palette.trace, paused: dimmed)
                .frame(height: 42)
            HStack {
                BeatHeart(engine: engine, color: palette.layout == .bars ? palette.trace : palette.accent, paused: dimmed, pixel: 2.2)
                Text(snapshot.bpm.map(String.init) ?? "--")
                    .font(.monitor(20, weight: .medium))
                    .foregroundStyle(ink)
                Spacer()
                PixelIcon(rows: PixelIcon.steps, color: palette.text, pixel: 1.9)
                Text(String(snapshot.steps))
                    .font(.monitor(20, weight: .medium))
                    .foregroundStyle(ink)
            }
            .padding(.horizontal, 10)
        }
    }
}
