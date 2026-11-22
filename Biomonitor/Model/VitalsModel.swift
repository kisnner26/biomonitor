import Foundation
import HealthKit

/// lee el pulso en vivo (con una sesion de entrenamiento temporal que no se guarda) y los datos del dia.
final class VitalsModel: NSObject, ObservableObject {
    @Published private(set) var snapshot = VitalsSnapshot()
    @Published private(set) var isLive = false
    @Published private(set) var healthAvailable = HKHealthStore.isHealthDataAvailable()

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var authorized = false
    private var wantLive = true

    private let bpmUnit = HKUnit.count().unitDivided(by: .minute())
    private let hrType = HKQuantityType(.heartRate)

    private var readTypes: Set<HKObjectType> {
        [hrType, HKQuantityType(.stepCount), HKQuantityType(.distanceWalkingRunning),
         HKQuantityType(.activeEnergyBurned), HKQuantityType(.restingHeartRate)]
    }

    // MARK: ciclo de vida

    func start(live: Bool) {
        wantLive = live
        guard healthAvailable else { return }
        if authorized {
            refresh()
            if live { startLive() }
            return
        }
        store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: readTypes) { [weak self] ok, _ in
            DispatchQueue.main.async {
                guard let self, ok else { return }
                self.authorized = true
                self.refresh()
                if self.wantLive { self.startLive() }
            }
        }
    }

    func setLive(_ on: Bool) {
        wantLive = on
        guard authorized else { return }
        if on { startLive() } else { stopLive() }
    }

    func resume() {
        guard authorized else { return }
        refresh()
        if wantLive { startLive() }
    }

    // MARK: pulso en vivo

    private func startLive() {
        guard session == nil else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .indoor
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: config)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            s.delegate = self
            b.delegate = self
            session = s
            builder = b
            let now = Date()
            s.startActivity(with: now)
            b.beginCollection(withStart: now) { _, _ in }
            isLive = true
        } catch {
            session = nil
            builder = nil
            isLive = false
        }
    }

    private func stopLive() {
        session?.end()
        // el generador se descarta al terminar la sesion (ver didChangeTo)
        isLive = false
    }

    private func publish(bpm: Int) {
        DispatchQueue.main.async {
            var s = self.snapshot
            s.bpm = bpm
            s.history.append(HRPoint(date: Date(), bpm: bpm))
            if s.history.count > 90 { s.history.removeFirst(s.history.count - 90) }
            self.snapshot = s
        }
    }

    // MARK: datos del dia

    func refresh() {
        guard authorized else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: nil)

        sum(.stepCount, unit: .count(), pred: pred) { [weak self] v in self?.update { $0.steps = Int(v) } }
        sum(.distanceWalkingRunning, unit: .meterUnit(with: .kilo), pred: pred) { [weak self] v in self?.update { $0.distanceKm = v } }
        sum(.activeEnergyBurned, unit: .kilocalorie(), pred: pred) { [weak self] v in self?.update { $0.kcal = Int(v) } }

        let hrStats = HKStatisticsQuery(quantityType: hrType, quantitySamplePredicate: pred,
                                        options: [.discreteMin, .discreteMax, .discreteAverage]) { [weak self] _, stats, _ in
            guard let self, let stats else { return }
            let u = self.bpmUnit
            let lo = stats.minimumQuantity()?.doubleValue(for: u)
            let hi = stats.maximumQuantity()?.doubleValue(for: u)
            let av = stats.averageQuantity()?.doubleValue(for: u)
            self.update {
                $0.minHR = lo.map { Int($0.rounded()) }
                $0.maxHR = hi.map { Int($0.rounded()) }
                $0.avgHR = av.map { Int($0.rounded()) }
            }
        }
        store.execute(hrStats)

        // ultimo reposo
        let restType = HKQuantityType(.restingHeartRate)
        let byDate = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        store.execute(HKSampleQuery(sampleType: restType, predicate: nil, limit: 1, sortDescriptors: byDate) { [weak self] _, r, _ in
            guard let self, let q = (r?.first as? HKQuantitySample)?.quantity else { return }
            let v = Int(q.doubleValue(for: self.bpmUnit).rounded())
            self.update { $0.restingHR = v }
        })

        // historial reciente y ultimo valor mientras llega el pulso en vivo
        let recent = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-30 * 60), end: nil)
        store.execute(HKSampleQuery(sampleType: hrType, predicate: recent, limit: 60, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { [weak self] _, r, _ in
            guard let self, let samples = r as? [HKQuantitySample], !samples.isEmpty else { return }
            let pts = samples.map { HRPoint(date: $0.endDate, bpm: Int($0.quantity.doubleValue(for: self.bpmUnit).rounded())) }
            self.update {
                if $0.history.isEmpty { $0.history = pts }
                if $0.bpm == nil { $0.bpm = pts.last?.bpm }
            }
        })
    }

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, pred: NSPredicate, done: @escaping (Double) -> Void) {
        let q = HKStatisticsQuery(quantityType: HKQuantityType(id), quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
            done(stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
        }
        store.execute(q)
    }

    private func update(_ change: @escaping (inout VitalsSnapshot) -> Void) {
        DispatchQueue.main.async {
            var s = self.snapshot
            change(&s)
            self.snapshot = s
        }
    }
}

extension VitalsModel: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        guard toState == .ended, let b = builder else { return }
        b.endCollection(withEnd: date) { [weak self] _, _ in
            b.discardWorkout()   // no ensucia el historial de salud
            DispatchQueue.main.async {
                self?.session = nil
                self?.builder = nil
                self?.isLive = false
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.session = nil
            self.builder = nil
            self.isLive = false
        }
    }
}

extension VitalsModel: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard collectedTypes.contains(hrType),
              let v = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity()?.doubleValue(for: bpmUnit)
        else { return }
        publish(bpm: Int(v.rounded()))
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
