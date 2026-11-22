import SwiftUI

/// trazo de ecg que barre la pantalla
struct ECGTraceView: View {
    let engine: ECGEngine
    let bpm: Int?
    let color: Color
    var paused = false
    var lineWidth: CGFloat = 1.8

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { ctx in
            Canvas { gc, size in
                if !paused { engine.advance(to: ctx.date, bpm: bpm) }
                let base = size.height * 0.66
                let amp = size.height * 0.58
                let n = engine.columns
                let dx = size.width / CGFloat(n - 1)

                var path = Path()
                var pen = false
                for i in 0..<n {
                    guard !engine.isGap(i), let v = engine.buffer[i] else { pen = false; continue }
                    let pt = CGPoint(x: CGFloat(i) * dx, y: base - CGFloat(v) * amp)
                    if pen { path.addLine(to: pt) } else { path.move(to: pt); pen = true }
                }
                var glow = gc
                glow.addFilter(.blur(radius: 3))
                glow.stroke(path, with: .color(color.opacity(0.7)), style: StrokeStyle(lineWidth: lineWidth + 1.5, lineCap: .round, lineJoin: .round))
                gc.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                // punto brillante en la cabeza del trazo
                let head = (engine.cursor - 1 + n) % n
                if !paused, let v = engine.buffer[head] {
                    let c = CGPoint(x: CGFloat(head) * dx, y: base - CGFloat(v) * amp)
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

    var body: some View {
        Canvas { gc, size in
            guard history.count > 1 else {
                var flat = Path()
                flat.move(to: CGPoint(x: 0, y: size.height * 0.7))
                flat.addLine(to: CGPoint(x: size.width, y: size.height * 0.7))
                gc.stroke(flat, with: .color(color), lineWidth: 1.8)
                return
            }
            let vals = history.map(\.bpm)
            let lo = Double(min(vals.min()! , 60) - 5)
            let hi = Double(max(vals.max()!, 100) + 5)
            let n = history.count
            func y(_ v: Int) -> CGFloat { size.height - CGFloat((Double(v) - lo) / (hi - lo)) * size.height * 0.9 - size.height * 0.05 }
            func x(_ i: Int) -> CGFloat { CGFloat(i) / CGFloat(n - 1) * size.width }

            var p = Path()
            p.move(to: CGPoint(x: 0, y: y(vals[0])))
            for i in 1..<n {
                p.addLine(to: CGPoint(x: x(i), y: y(vals[i - 1])))   // horizontal
                p.addLine(to: CGPoint(x: x(i), y: y(vals[i])))       // escalon
            }
            var glow = gc
            glow.addFilter(.blur(radius: 3))
            glow.stroke(p, with: .color(color.opacity(0.7)), lineWidth: 3)
            gc.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineJoin: .miter))
        }
    }
}
