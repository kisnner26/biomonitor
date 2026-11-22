import HealthKit
import SwiftUI
import WidgetKit

struct VitalsEntry: TimelineEntry {
    let date: Date
    let bpm: Int?
    let steps: Int
}

/// lee el ultimo pulso y los pasos de hoy directamente de healthkit
struct VitalsProvider: TimelineProvider {
    func placeholder(in context: Context) -> VitalsEntry { VitalsEntry(date: .now, bpm: 72, steps: 2459) }

    func getSnapshot(in context: Context, completion: @escaping (VitalsEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)) } else { fetch(completion) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VitalsEntry>) -> Void) {
        fetch { entry in
            completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(10 * 60))))
        }
    }

    private func fetch(_ done: @escaping (VitalsEntry) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { done(VitalsEntry(date: .now, bpm: nil, steps: 0)); return }
        let store = HKHealthStore()
        let group = DispatchGroup()
        var bpm: Int?
        var steps = 0

        group.enter()
        let hr = HKQuantityType(.heartRate)
        let recent = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-6 * 3600), end: nil)
        store.execute(HKSampleQuery(sampleType: hr, predicate: recent, limit: 1,
                                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, r, _ in
            if let q = (r?.first as? HKQuantitySample)?.quantity {
                bpm = Int(q.doubleValue(for: .count().unitDivided(by: .minute())).rounded())
            }
            group.leave()
        })

        group.enter()
        let today = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: nil)
        store.execute(HKStatisticsQuery(quantityType: HKQuantityType(.stepCount), quantitySamplePredicate: today, options: .cumulativeSum) { _, s, _ in
            steps = Int(s?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            group.leave()
        })

        group.notify(queue: .main) { done(VitalsEntry(date: .now, bpm: bpm, steps: steps)) }
    }
}

/// un latido dibujado con la misma onda del monitor
struct PulseShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 70
        for i in 0..<n {
            let t = Double(i) / Double(n - 1)
            let v = ECGEngine.wave(0.04 + t * 0.7)
            let pt = CGPoint(x: r.minX + r.width * t, y: r.minY + r.height * (0.7 - 0.62 * v))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}

struct VitalsView: View {
    let entry: VitalsEntry
    @Environment(\.widgetFamily) private var family

    private var bpmText: String { entry.bpm.map(String.init) ?? "--" }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(min(max(entry.bpm ?? 40, 40), 180)), in: 40...180) {
                Image(systemName: "heart.fill")
            } currentValueLabel: {
                Text(bpmText).font(.monitor(20, weight: .bold))
            }
            .gaugeStyle(.accessoryCircular)
        case .accessoryRectangular:
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("BIOMONITOR").font(.monitor(10, weight: .semibold)).opacity(0.7)
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(bpmText).font(.monitor(30, weight: .bold))
                        Text("BPM").font(.monitor(11, weight: .medium)).opacity(0.7)
                    }
                    Text("\(entry.steps)").font(.monitor(12, weight: .medium)).opacity(0.8)
                }
                PulseShape()
                    .stroke(style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .widgetAccentable()
                    .frame(maxWidth: .infinity)
            }
        case .accessoryCorner:
            Text(bpmText)
                .font(.monitor(24, weight: .bold))
                .widgetLabel { Text("BPM") }
        default:
            Text("\(Image(systemName: "heart.fill")) \(bpmText)  \(entry.steps)")
        }
    }
}

struct BiomonitorComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "biomonitor.vitals", provider: VitalsProvider()) { entry in
            VitalsView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Biomonitor")
        .description("Pulso y pasos. Heart rate and steps.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

@main
struct BiomonitorWidgetBundle: WidgetBundle {
    var body: some Widget { BiomonitorComplication() }
}
