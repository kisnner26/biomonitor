import SwiftUI

/// pantalla principal. dos disposiciones:
/// - verde: marco punteado como el reloj de la caja
/// - cian: barras azules arriba y abajo, como la pantalla del genoma
/// toca la grafica para alternar entre el trazo de ecg y el historial en escalones.
struct MonitorView: View {
    let snapshot: VitalsSnapshot
    let palette: Palette
    let engine: ECGEngine
    let now: Date
    let use24h: Bool
    var dimmed = false          // pantalla siempre activa
    var onTap: () -> Void = {}
    @State private var showTrend = false
    @State private var line = 0.0
    @State private var appeared = false

    private func format(_ pattern: String) -> String {
        let f = DateFormatter()
        f.dateFormat = pattern
        return f.string(from: now)
    }

    var body: some View {
        let ink = dimmed ? palette.text.opacity(0.7) : palette.text
        let frame = palette.frame.opacity(dimmed ? 0.6 : 1)
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text(format("dd.MM."))
                    .font(.monitor(19, weight: .medium))
                    .offset(x: appeared ? 0 : -14)
                Spacer()
                Text(format(use24h ? "HH:mm" : "h:mm"))
                    .font(.monitor(30, weight: .semibold))
                    .offset(x: appeared ? 0 : 14)
            }
            .foregroundStyle(ink)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, 4)

            chart(frame: frame)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                    withAnimation(.easeInOut(duration: 0.28)) { showTrend.toggle() }
                }

            footer(ink: ink)
                .padding(.top, 5)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
        }
        .padding(.horizontal, 6)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.15)) { line = 1 }
        }
        .onDisappear { appeared = false; line = 0 }
    }

    // MARK: grafica

    @ViewBuilder private func chart(frame: Color) -> some View {
        let trace = Group {
            if showTrend {
                TrendView(history: snapshot.history, color: palette.trace)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.94)), removal: .opacity))
            } else {
                ECGTraceView(engine: engine, bpm: snapshot.bpm, color: palette.trace, paused: dimmed)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.06)), removal: .opacity))
            }
        }
        .opacity(dimmed ? 0.75 : 1)

        switch palette.layout {
        case .box:
            ZStack {
                VStack {
                    DotShape(progress: line).stroke(frame, style: dotStyle).frame(height: 2)
                    Spacer()
                    DotShape(progress: line).stroke(frame, style: dotStyle).frame(height: 2)
                }
                HStack {
                    DotShape(vertical: true, progress: line).stroke(frame, style: dotStyle).frame(width: 2)
                    Spacer()
                }
                trace.padding(.vertical, 8).padding(.leading, 6)
            }
        case .bars:
            VStack(spacing: 0) {
                bar(frame: frame, long: true).padding(.bottom, 3)
                bar(frame: palette.trace.opacity(0.9), long: false)
                trace.padding(.vertical, 4)
                bar(frame: frame, long: true).padding(.bottom, 3)
                bar(frame: palette.trace.opacity(0.9), long: false)
            }
        }
    }

    private var dotStyle: StrokeStyle { StrokeStyle(lineWidth: 1.4, dash: [1.4, 2.2]) }

    /// barra larga azul con un tramo corto brillante a la derecha
    private func bar(frame: Color, long: Bool) -> some View {
        GeometryReader { g in
            if long {
                Rectangle().fill(frame.opacity(0.85))
                    .frame(width: g.size.width * line, height: 2.5)
            } else {
                Rectangle().fill(frame)
                    .frame(width: g.size.width * 0.34 * line, height: 2.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(height: 3)
        .shadow(color: frame.opacity(0.7), radius: 3)
    }

    // MARK: pie

    private func footer(ink: Color) -> some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 5) {
                if palette.layout == .bars {
                    Circle().fill(palette.accent).frame(width: 6, height: 6)
                        .opacity(dimmed ? 1 : (Int(now.timeIntervalSince1970) % 2 == 0 ? 1 : 0.25))
                        .animation(.easeInOut(duration: 0.3), value: Int(now.timeIntervalSince1970) % 2)
                }
                BeatHeart(engine: engine, color: palette.layout == .bars ? palette.trace : palette.accent, paused: dimmed)
                ZoneBars(lit: heartZone(snapshot.bpm), color: palette.text, dim: palette.dim)
                Text(snapshot.bpm.map(String.init) ?? "--")
                    .font(.monitor(24, weight: .medium))
                    .foregroundStyle(ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: snapshot.bpm)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 4) {
                    PixelIcon(rows: PixelIcon.steps, color: palette.text, pixel: 2.2)
                    Text(String(snapshot.steps))
                        .font(.monitor(24, weight: .medium))
                        .foregroundStyle(ink)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: snapshot.steps)
                }
                Rectangle().fill(palette.accent).frame(height: 2)
                    .scaleEffect(x: line, anchor: .trailing)
            }
        }
    }
}
