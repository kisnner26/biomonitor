import SwiftUI
import WatchKit

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
    @State private var booted = false

    var body: some View {
        let palette = paletteID.palette
        let cond = Condition(bpm: vitals.snapshot.bpm)
        ZStack {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                TabView(selection: $page) {
                    MonitorView(snapshot: vitals.snapshot, palette: palette, engine: engine, now: ctx.date, use24h: use24h, dimmed: dimmed,
                                onTap: { WKInterfaceDevice.current().play(.click) })
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
            if !dimmed {
                ScanlineOverlay()
                GlitchOverlay(trigger: page, color: palette.trace)
            }
            if !booted && !dimmed {
                BootView(palette: palette)
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            }
        }
        .background(Color.black)
        .onAppear { engine.prefill(bpm: vitals.snapshot.bpm) }
        .task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            withAnimation(.easeIn(duration: 0.35)) { booted = true }
        }
        .onChange(of: page) { _, _ in WKInterfaceDevice.current().play(.click) }
        .onChange(of: cond) { old, new in
            switch new {
            case .danger: WKInterfaceDevice.current().play(.failure)
            case .caution: WKInterfaceDevice.current().play(.notification)
            case .fine: if old == .caution || old == .danger { WKInterfaceDevice.current().play(.success) }
            case .noSignal: break
            }
        }
    }
}
