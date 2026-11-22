import SwiftUI

@main
struct BiomonitorApp: App {
    @StateObject private var vitals = VitalsModel()
    @AppStorage("palette") private var paletteID: PaletteID = .fitbit
    @AppStorage("haptic") private var haptic = false
    @AppStorage("live") private var live = true
    @AppStorage("use24h") private var use24h = false
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView(vitals: vitals, paletteID: $paletteID, haptic: $haptic, live: $live, use24h: $use24h)
                .onAppear { vitals.start(live: live, haptic: haptic) }
                .onChange(of: live) { _, new in vitals.setLive(new) }
                .onChange(of: haptic) { _, new in vitals.setHaptic(new) }
                .onChange(of: phase) { _, p in
                    if p == .active { vitals.resume() } else if p == .background { vitals.pause() }
                }
        }
    }
}

struct RootView: View {
    @ObservedObject var vitals: VitalsModel
    @Binding var paletteID: PaletteID
    @Binding var haptic: Bool
    @Binding var live: Bool
    @Binding var use24h: Bool
    @Environment(\.isLuminanceReduced) private var dimmed
    @State private var engine = ECGEngine()
    @State private var page = 0

    var body: some View {
        let palette = paletteID.palette
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            TabView(selection: $page) {
                MonitorView(snapshot: vitals.snapshot, palette: palette, engine: engine, now: ctx.date, use24h: use24h, dimmed: dimmed)
                    .tag(0)
                StatusView(snapshot: vitals.snapshot, palette: palette, engine: engine, paused: dimmed)
                    .tag(1)
                ActivityView(snapshot: vitals.snapshot, palette: palette)
                    .tag(2)
                SettingsView(paletteID: $paletteID, haptic: $haptic, live: $live, use24h: $use24h, palette: palette)
                    .tag(3)
            }
            .tabViewStyle(.verticalPage)
        }
        .background(Color.black)
        .onAppear { engine.prefill(bpm: vitals.snapshot.bpm) }
    }
}
