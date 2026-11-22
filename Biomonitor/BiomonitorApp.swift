import SwiftUI
import WatchKit

@main
struct BiomonitorApp: App {
    @StateObject private var vitals = VitalsModel()
    @AppStorage("palette") private var paletteID: PaletteID = .fitbit
    @AppStorage("lang") private var lang: Lang = .system
    @AppStorage("haptic") private var haptic = false
    @AppStorage("beep") private var beep = false
    @AppStorage("sound") private var sound = true
    @AppStorage("live") private var live = true
    @AppStorage("use24h") private var use24h = false
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView(vitals: vitals, paletteID: $paletteID, lang: $lang, haptic: $haptic, beep: $beep,
                     sound: $sound, live: $live, use24h: $use24h)
                .environment(\.lang, lang)
                .onAppear { vitals.start(live: live) }
                .onChange(of: live) { _, new in vitals.setLive(new) }
                .onChange(of: phase) { _, p in if p == .active { vitals.resume() } }
        }
    }
}

struct RootView: View {
    @ObservedObject var vitals: VitalsModel
    @Binding var paletteID: PaletteID
    @Binding var lang: Lang
    @Binding var haptic: Bool
    @Binding var beep: Bool
    @Binding var sound: Bool
    @Binding var live: Bool
    @Binding var use24h: Bool
    @Environment(\.isLuminanceReduced) private var dimmed

    @State private var engine = ECGEngine()
    @State private var page = 0
    @State private var direction = 1
    @State private var crown = 0.0
    @State private var booted = false
    @State private var seenBeats = 0

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let lastPage = 3

    var body: some View {
        let palette = paletteID.palette
        let cond = Condition(bpm: vitals.snapshot.bpm)
        ZStack {
            VStack(spacing: 0) {
                NavBar(page: page, palette: palette)
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    ZStack {
                        pageView(page, palette: palette, now: ctx.date)
                            .id(page)
                            .transition(.asymmetric(
                                insertion: .move(edge: direction > 0 ? .trailing : .leading).combined(with: .opacity),
                                removal: .move(edge: direction > 0 ? .leading : .trailing).combined(with: .opacity)))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                }
            }
            .gesture(DragGesture(minimumDistance: 24).onEnded { v in
                guard abs(v.translation.width) > abs(v.translation.height), abs(v.translation.width) > 36 else { return }
                go(v.translation.width < 0 ? page + 1 : page - 1)
            })
            .focusable(page != lastPage)
            .digitalCrownRotation($crown, from: 0, through: Double(lastPage), by: 1, sensitivity: .low,
                                  isContinuous: false, isHapticFeedbackEnabled: true)
            .onChange(of: crown) { _, v in
                let target = Int(v.rounded())
                if target != page { go(target, fromCrown: true) }
            }

            if !dimmed {
                ScanlineOverlay()
                GlitchOverlay(trigger: page, color: palette.trace)
            }
            if !booted && !dimmed {
                BootView(palette: palette)
                    .transition(.opacity.combined(with: .scale(scale: 1.06)))
            }
        }
        .background(Color.black)
        .onAppear {
            engine.prefill(bpm: vitals.snapshot.bpm)
            SoundFX.shared.enabled = sound
            SoundFX.shared.beatEnabled = beep
        }
        .task {
            SoundFX.shared.play(.boot)
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            withAnimation(.easeIn(duration: 0.35)) { booted = true }
        }
        .onReceive(ticker) { date in
            guard !dimmed else { return }
            engine.advance(to: date, bpm: vitals.snapshot.bpm)
            if engine.beatCount != seenBeats {
                seenBeats = engine.beatCount
                SoundFX.shared.playBeat()
                if haptic { lubDub() }
            }
        }
        .onChange(of: sound) { _, v in SoundFX.shared.enabled = v }
        .onChange(of: beep) { _, v in SoundFX.shared.beatEnabled = v }
        .onChange(of: cond) { old, new in
            switch new {
            case .danger:
                WKInterfaceDevice.current().play(.failure); SoundFX.shared.play(.danger)
            case .caution:
                WKInterfaceDevice.current().play(.notification); SoundFX.shared.play(.caution)
            case .fine:
                if old == .caution || old == .danger {
                    WKInterfaceDevice.current().play(.success); SoundFX.shared.play(.fine)
                }
            case .noSignal: break
            }
        }
    }

    @ViewBuilder private func pageView(_ p: Int, palette: Palette, now: Date) -> some View {
        switch p {
        case 0:
            MonitorView(snapshot: vitals.snapshot, palette: palette, engine: engine, now: now, use24h: use24h, dimmed: dimmed,
                        onTap: { WKInterfaceDevice.current().play(.click); SoundFX.shared.play(.tap) })
        case 1:
            StatusView(snapshot: vitals.snapshot, palette: palette, engine: engine, paused: dimmed)
        case 2:
            ActivityView(snapshot: vitals.snapshot, palette: palette)
        default:
            SettingsView(paletteID: $paletteID, lang: $lang, haptic: $haptic, beep: $beep, sound: $sound,
                         live: $live, use24h: $use24h, palette: palette)
        }
    }

    private func go(_ target: Int, fromCrown: Bool = false) {
        let t = min(max(target, 0), lastPage)
        guard t != page else { return }
        direction = t > page ? 1 : -1
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { page = t }
        crown = Double(t)
        SoundFX.shared.play(.page)
        if !fromCrown { WKInterfaceDevice.current().play(.click) }
    }

    private func lubDub() {
        let d = WKInterfaceDevice.current()
        d.play(.click)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { d.play(.click) }
    }
}
