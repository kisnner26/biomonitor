import SwiftUI

/// lineas de barrido de una pantalla lcd antigua
struct ScanlineOverlay: View {
    var body: some View {
        Canvas { gc, size in
            var y: CGFloat = 0
            while y < size.height {
                gc.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.22)))
                y += 3
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// destello de interferencia al cambiar de pagina
struct GlitchOverlay: View {
    let trigger: Int
    let color: Color
    @State private var start = Date.distantPast

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: Date().timeIntervalSince(start) > 0.4)) { ctx in
            let t = ctx.date.timeIntervalSince(start)
            Canvas { gc, size in
                guard t >= 0, t < 0.32 else { return }
                let k = 1 - t / 0.32
                var seed = UInt64(t * 30) &* 2654435761 &+ 12345
                func rnd() -> Double {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return Double(seed >> 33) / Double(1 << 31)
                }
                for _ in 0..<6 {
                    let y = rnd() * size.height
                    let h = 2 + rnd() * 10
                    let off = (rnd() - 0.5) * 26 * k
                    gc.fill(Path(CGRect(x: off, y: y, width: size.width, height: h)), with: .color(color.opacity(0.28 * k)))
                }
                let ly = size.height * rnd()
                gc.fill(Path(CGRect(x: 0, y: ly, width: size.width, height: 1.5)), with: .color(.white.opacity(0.5 * k)))
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: trigger) { _, _ in start = Date() }
    }
}

/// secuencia de arranque del monitor
struct BootView: View {
    let palette: Palette
    @State private var start = Date()

    private let lines: [(Double, String, String)] = [
        (0.30, "SENSOR", "OK"),
        (0.75, "HR LINK", "OK"),
        (1.20, "VITALS", "OK"),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
            let t = ctx.date.timeIntervalSince(start)
            VStack(alignment: .leading, spacing: 6) {
                Text("BIOMONITOR")
                    .font(.monitor(24, weight: .bold))
                    .foregroundStyle(palette.trace)
                    .shadow(color: palette.trace.opacity(0.8), radius: 6)
                    .opacity(t > 0.05 ? 1 : 0)
                ForEach(0..<lines.count, id: \.self) { i in
                    let l = lines[i]
                    HStack(spacing: 0) {
                        Text(l.1)
                        Text(" " + String(repeating: ".", count: 14 - l.1.count) + " ")
                            .foregroundStyle(palette.dim)
                        Text(l.2).foregroundStyle(palette.trace)
                    }
                    .font(.monitor(15, weight: .medium))
                    .foregroundStyle(palette.text)
                    .opacity(t > l.0 ? 1 : 0)
                }
                let lit = Int(min(max(t / 1.5, 0), 1) * 20)
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { i in
                        Rectangle().fill(i < lit ? palette.trace : palette.dim.opacity(0.3)).frame(height: 6)
                    }
                }
                .padding(.top, 6)
                Text(Int(t * 4) % 2 == 0 ? "_" : " ")
                    .font(.monitor(15))
                    .foregroundStyle(palette.trace)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.black)
        }
    }
}

/// linea punteada que se dibuja de un extremo al otro
struct DotShape: Shape {
    var vertical = false
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        if vertical {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * progress))
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX + rect.width * progress, y: rect.midY))
        }
        return p
    }
}

/// corazon de pixeles que late con el pico r del ecg
struct BeatHeart: View {
    let engine: ECGEngine
    let color: Color
    var paused = false
    var pixel: CGFloat = 2.6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { ctx in
            let t = engine.lastBeat.map { ctx.date.timeIntervalSince($0) } ?? 9
            let p = paused ? 0 : exp(-max(t, 0) / 0.15)
            PixelIcon(rows: PixelIcon.heart, color: color, pixel: pixel)
                .scaleEffect(1 + 0.4 * p)
                .shadow(color: color.opacity(0.95 * p), radius: 7 * p)
        }
    }
}
