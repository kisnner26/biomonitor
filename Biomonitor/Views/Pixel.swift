import SwiftUI

/// iconos de pixeles, como los de la pantalla del reloj
struct PixelIcon: View {
    let rows: [String]
    let color: Color
    var pixel: CGFloat = 2

    var body: some View {
        Canvas { ctx, _ in
            for (y, row) in rows.enumerated() {
                for (x, ch) in row.enumerated() where ch == "#" {
                    ctx.fill(Path(CGRect(x: CGFloat(x) * pixel, y: CGFloat(y) * pixel, width: pixel, height: pixel)), with: .color(color))
                }
            }
        }
        .frame(width: CGFloat(rows.first?.count ?? 0) * pixel, height: CGFloat(rows.count) * pixel)
    }

    static let heart = [
        ".##.##.",
        "#######",
        "#######",
        ".#####.",
        "..###..",
        "...#...",
    ]

    static let steps = [
        ".##.....",
        "####.##.",
        "####.###",
        "####.###",
        ".##..###",
        ".##...##",
        "####....",
        ".##.....",
    ]

    static let flame = [
        "...#...",
        "..##...",
        ".####.#",
        ".######",
        "#######",
        "#######",
        ".#####.",
    ]

    static let route = [
        "##.....",
        "##.....",
        ".#.....",
        ".##....",
        "..###..",
        "....##.",
        ".....##",
        ".....##",
    ]
}

/// barritas de zona junto al pulso: se encienden segun el esfuerzo
struct ZoneBars: View {
    let lit: Int
    let color: Color
    let dim: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1.5) {
            ForEach((0..<4).reversed(), id: \.self) { i in
                Rectangle()
                    .fill(i < lit ? color : dim.opacity(0.45))
                    .frame(width: 9 + CGFloat(i) * 1, height: 2)
            }
        }
    }
}

/// linea punteada horizontal o vertical
struct DottedLine: View {
    let color: Color
    var vertical = false

    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            if vertical {
                p.move(to: CGPoint(x: size.width / 2, y: 0))
                p.addLine(to: CGPoint(x: size.width / 2, y: size.height))
            } else {
                p.move(to: CGPoint(x: 0, y: size.height / 2))
                p.addLine(to: CGPoint(x: size.width, y: size.height / 2))
            }
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 1.4, dash: [1.4, 2.2]))
        }
        .frame(width: vertical ? 2 : nil, height: vertical ? nil : 2)
    }
}
