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
