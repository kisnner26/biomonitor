import SwiftUI

/// estado de salud: fine, caution o danger, con el trazo en el color del estado
struct StatusView: View {
    let snapshot: VitalsSnapshot
    let palette: Palette
    let engine: ECGEngine
    var paused = false

    var body: some View {
        let cond = Condition(bpm: snapshot.bpm)
        VStack(spacing: 4) {
            Text("CONDITION")
                .font(.monitor(12, weight: .medium))
                .foregroundStyle(palette.dim)
            Text(cond.label)
                .font(.monitor(34, weight: .bold))
                .foregroundStyle(cond.color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
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
    }

    private func stat(_ title: String, _ v: Int?) -> some View {
        VStack(spacing: 0) {
            Text(v.map(String.init) ?? "--")
                .font(.monitor(22, weight: .medium))
                .foregroundStyle(palette.text)
            Text(title)
                .font(.monitor(11, weight: .medium))
                .foregroundStyle(palette.dim)
        }
    }
}

/// actividad del dia con barras segmentadas hacia la meta
struct ActivityView: View {
    let snapshot: VitalsSnapshot
    let palette: Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            row(PixelIcon.steps, "\(snapshot.steps)", "PASOS", Double(snapshot.steps) / 10_000)
            row(PixelIcon.route, String(format: "%.2f", snapshot.distanceKm), "KM", snapshot.distanceKm / 8)
            row(PixelIcon.flame, "\(snapshot.kcal)", "KCAL", Double(snapshot.kcal) / 500)
        }
        .padding(.horizontal, 10)
    }

    private func row(_ icon: [String], _ value: String, _ unit: String, _ progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                PixelIcon(rows: icon, color: palette.text, pixel: 2.2)
                Text(value)
                    .font(.monitor(26, weight: .medium))
                    .foregroundStyle(palette.text)
                Text(unit)
                    .font(.monitor(12, weight: .medium))
                    .foregroundStyle(palette.dim)
            }
            SegmentBar(progress: progress, color: palette.trace, dim: palette.dim)
        }
    }
}

struct SegmentBar: View {
    let progress: Double
    let color: Color
    let dim: Color
    private let segments = 20

    var body: some View {
        let lit = Int((min(max(progress, 0), 1) * Double(segments)).rounded(.down))
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                Rectangle()
                    .fill(i < lit ? color : dim.opacity(0.35))
                    .frame(height: 5)
            }
        }
    }
}
