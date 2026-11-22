import SwiftUI

/// trazo de ecg que barre la pantalla, con estela de fosforo: lo viejo se apaga poco a poco
struct ECGTraceView: View {
    let engine: ECGEngine
    let bpm: Int?
    let color: Color
    var paused = false
    var lineWidth: CGFloat = 1.8

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { ctx in
            Canvas { gc, size in
                _ = ctx.date   // fuerza el redibujo; el motor avanza en RootView
                let base = size.height * 0.66
                let amp = size.height * 0.58
                let n = engine.columns
                let dx = size.width / CGFloat(n - 1)
                func pt(_ i: Int, _ v: Double) -> CGPoint { CGPoint(x: CGFloat(i) * dx, y: base - CGFloat(v) * amp) }

                var glow = Path()
                var segs: [(Path, Double)] = []
                for i in 0..<(n - 1) {
                    guard !engine.isGap(i), !engine.isGap(i + 1), let a = engine.buffer[i], let b = engine.buffer[i + 1] else { continue }
                    var seg = Path()
                    seg.move(to: pt(i, a))
                    seg.addLine(to: pt(i + 1, b))
                    glow.addPath(seg)
                    let age = Double((engine.cursor - 1 - i + n) % n) / Double(n)
                    segs.append((seg, paused ? 0.85 : 0.22 + 0.78 * pow(1 - age, 1.8)))
                }
                var g = gc
                g.addFilter(.blur(radius: 3.2))
                g.stroke(glow, with: .color(color.opacity(paused ? 0.35 : 0.5)), style: StrokeStyle(lineWidth: lineWidth + 1.6, lineCap: .round, lineJoin: .round))
                for (seg, a) in segs {
                    gc.stroke(seg, with: .color(color.opacity(a)), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }

                let head = (engine.cursor - 1 + n) % n
                if !paused, let v = engine.buffer[head] {
                    let c = pt(head, v)
                    var h = gc
                    h.addFilter(.blur(radius: 2))
                    h.fill(Path(ellipseIn: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)), with: .color(color))
                    gc.fill(Path(ellipseIn: CGRect(x: c.x - 2.2, y: c.y - 2.2, width: 4.4, height: 4.4)), with: .color(.white))
                }
            }
        }
    }
}

/// historial de pulso en escalones, como la grafica del reloj de la caja
struct TrendView: View {
    let history: [HRPoint]
    let color: Color
    @State private var progress = 0.0

    var body: some View {
        TrendShape(history: history, progress: progress)
            .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineJoin: .miter))
            .shadow(color: color.opacity(0.8), radius: 4)
            .onAppear { withAnimation(.easeOut(duration: 0.9)) { progress = 1 } }
            .onDisappear { progress = 0 }
    }
}

struct TrendShape: Shape {
    var history: [HRPoint]
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in r: CGRect) -> Path {
        var p = Path()
        let vals = history.map(\.bpm)
        guard vals.count > 1 else {
            p.move(to: CGPoint(x: r.minX, y: r.height * 0.7))
            p.addLine(to: CGPoint(x: r.minX + r.width * progress, y: r.height * 0.7))
            return p
        }
        let lo = Double(min(vals.min()!, 60) - 5)
        let hi = Double(max(vals.max()!, 100) + 5)
        let n = vals.count
        func y(_ v: Int) -> CGFloat { r.maxY - CGFloat((Double(v) - lo) / (hi - lo)) * r.height * 0.9 - r.height * 0.05 }
        func x(_ i: Int) -> CGFloat { r.minX + CGFloat(i) / CGFloat(n - 1) * r.width * progress }
        p.move(to: CGPoint(x: x(0), y: y(vals[0])))
        for i in 1..<n {
            p.addLine(to: CGPoint(x: x(i), y: y(vals[i - 1])))
            p.addLine(to: CGPoint(x: x(i), y: y(vals[i])))
        }
        return p
    }
}
