import SwiftUI

/// estado de salud: fine, caution o danger. el marco y el texto laten segun la gravedad.
struct StatusView: View {
    let snapshot: VitalsSnapshot
    let palette: Palette
    let engine: ECGEngine
    var paused = false

    var body: some View {
        let cond = Condition(bpm: snapshot.bpm)
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: paused)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let speed: Double = cond == .danger ? 9 : (cond == .caution ? 3.5 : 1.4)
                let pulse = paused ? 0.2 : (sin(t * speed) + 1) / 2
                let weight: Double = (cond == .noSignal) ? 0 : (cond == .fine ? 0.25 : 0.75)
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .strokeBorder(cond.color.opacity(0.08 + weight * 0.7 * pulse), lineWidth: 3)
                    .shadow(color: cond.color.opacity(weight * 0.6 * pulse), radius: 8)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            VStack(spacing: 4) {
                Text("CONDITION")
                    .font(.monitor(12, weight: .medium))
                    .foregroundStyle(palette.dim)
                TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: paused || cond != .danger)) { ctx in
                    let blink = cond == .danger && !paused ? (sin(ctx.date.timeIntervalSinceReferenceDate * 9) > -0.2 ? 1.0 : 0.35) : 1.0
                    Text(cond.label)
                        .font(.monitor(34, weight: .bold))
                        .foregroundStyle(cond.color)
                        .shadow(color: cond.color.opacity(0.7), radius: 7)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .opacity(blink)
                }
                .id(cond.label)
                .transition(.scale(scale: 1.35).combined(with: .opacity))
                ECGTraceView(engine: engine, bpm: snapshot.bpm, color: cond.color, paused: paused)
                    .frame(height: 54)
                HStack(spacing: 14) {
                    stat("MIN", snapshot.minHR)
                    stat("PROM", snapshot.avgHR)
                    stat("MAX", snapshot.maxHR)
                }
                HStack(spacing: 4) {
                    Text("REPOSO")
                        .font(.monitor(11, weight: .medium))
                        .foregroundStyle(palette.dim)
                    Text(snapshot.restingHR.map(String.init) ?? "--")
                        .font(.monitor(15, weight: .semibold))
                        .foregroundStyle(palette.text)
                }
            }
            .padding(.horizontal, 8)
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: cond.label)
        }
    }

    private func stat(_ title: String, _ v: Int?) -> some View {
        VStack(spacing: 0) {
            Text(v.map(String.init) ?? "--")
                .font(.monitor(22, weight: .medium))
                .foregroundStyle(palette.text)
                .contentTransition(.numericText())
                .animation(.snappy, value: v)
            Text(title)
                .font(.monitor(11, weight: .medium))
                .foregroundStyle(palette.dim)
        }
    }
}

/// actividad del dia: las barras se encienden segmento a segmento al entrar
struct ActivityView: View {
    let snapshot: VitalsSnapshot
    let palette: Palette
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            row(PixelIcon.steps, String(snapshot.steps), "PASOS", Double(snapshot.steps) / 10_000, 0)
            row(PixelIcon.route, String(format: "%.2f", snapshot.distanceKm), "KM", snapshot.distanceKm / 8, 1)
            row(PixelIcon.flame, String(snapshot.kcal), "KCAL", Double(snapshot.kcal) / 500, 2)
        }
        .padding(.horizontal, 10)
        .onAppear { shown = true }
        .onDisappear { shown = false }
    }

    private func row(_ icon: [String], _ value: String, _ unit: String, _ progress: Double, _ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                PixelIcon(rows: icon, color: palette.text, pixel: 2.2)
                Text(value)
                    .font(.monitor(26, weight: .medium))
                    .foregroundStyle(palette.text)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.monitor(12, weight: .medium))
                    .foregroundStyle(palette.dim)
            }
            .opacity(shown ? 1 : 0)
            .offset(x: shown ? 0 : -16)
            .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.12), value: shown)
            SegmentBar(progress: shown ? progress : 0, color: palette.trace, dim: palette.dim, delay: Double(index) * 0.12)
        }
    }
}

struct SegmentBar: View {
    let progress: Double
    let color: Color
    let dim: Color
    var delay = 0.0
    private let segments = 20

    var body: some View {
        let lit = Int((min(max(progress, 0), 1) * Double(segments)).rounded(.down))
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                Rectangle()
                    .fill(i < lit ? color : dim.opacity(0.35))
                    .shadow(color: i < lit ? color.opacity(0.8) : .clear, radius: 2)
                    .frame(height: 5)
                    .animation(.easeOut(duration: 0.12).delay(delay + 0.2 + Double(i) * 0.035), value: lit)
            }
        }
    }
}
