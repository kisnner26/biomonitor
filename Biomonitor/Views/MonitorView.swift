import SwiftUI

/// pantalla principal: fecha y hora, grafica en marco punteado, pulso y pasos.
/// toca la grafica para alternar entre el trazo de ecg y el historial en escalones.
struct MonitorView: View {
    let snapshot: VitalsSnapshot
    let palette: Palette
    let engine: ECGEngine
    let now: Date
    let use24h: Bool
    var dimmed = false          // pantalla siempre activa
    @State private var showTrend = false

    private var dateText: String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM."
        return f.string(from: now)
    }

    private var timeText: String {
        let f = DateFormatter()
        f.dateFormat = use24h ? "HH:mm" : "h:mm"
        return f.string(from: now)
    }

    var body: some View {
        let ink = dimmed ? palette.text.opacity(0.7) : palette.text
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(dateText)
                    .font(.monitor(19, weight: .medium))
                Spacer()
                Text(timeText)
                    .font(.monitor(30, weight: .semibold))
            }
            .foregroundStyle(ink)
            .padding(.bottom, 4)

            // marco punteado
            ZStack {
                VStack {
                    DottedLine(color: palette.frame.opacity(dimmed ? 0.6 : 1))
                    Spacer()
                    DottedLine(color: palette.frame.opacity(dimmed ? 0.6 : 1))
                }
                HStack {
                    DottedLine(color: palette.frame.opacity(dimmed ? 0.6 : 1), vertical: true)
                    Spacer()
                }
                Group {
                    if showTrend {
                        TrendView(history: snapshot.history, color: palette.trace)
                    } else {
                        ECGTraceView(engine: engine, bpm: snapshot.bpm, color: palette.trace, paused: dimmed)
                    }
                }
                .padding(.vertical, 8)
                .padding(.leading, 6)
                .opacity(dimmed ? 0.75 : 1)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { showTrend.toggle() }

            HStack(alignment: .bottom) {
                HStack(spacing: 5) {
                    PixelIcon(rows: PixelIcon.heart, color: palette.accent, pixel: 2.6)
                    ZoneBars(lit: heartZone(snapshot.bpm), color: palette.text, dim: palette.dim)
                    Text(snapshot.bpm.map(String.init) ?? "--")
                        .font(.monitor(24, weight: .medium))
                        .foregroundStyle(ink)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(spacing: 4) {
                        PixelIcon(rows: PixelIcon.steps, color: palette.text, pixel: 2.2)
                        Text(String(snapshot.steps))
                            .font(.monitor(24, weight: .medium))
                            .foregroundStyle(ink)
                    }
                    Rectangle().fill(palette.accent).frame(height: 2)
                }
            }
            .padding(.top, 5)
        }
        .padding(.horizontal, 6)
    }
}
