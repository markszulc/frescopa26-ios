import Foundation
import Observation

/// One step in a guided maintenance routine.
struct CareStep: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let detail: String
    let systemImage: String
    /// When set, the machine runs a cycle for this long (real-world seconds).
    let machineSeconds: Int?

    var isMachineCycle: Bool { machineSeconds != nil }
}

enum CareGuide {
    static func title(for taskID: CareTask.ID) -> String {
        switch taskID {
        case "descale": "Descale"
        case "filter": "Replace water filter"
        default: "Rinse milk system"
        }
    }

    static func steps(for taskID: CareTask.ID) -> [CareStep] {
        switch taskID {
        case "descale":
            [
                CareStep(id: 1, title: "Empty and rinse", detail: "Empty the drip tray and grounds bin, then rinse both under warm water.",
                         systemImage: "tray", machineSeconds: nil),
                CareStep(id: 2, title: "Add descaler", detail: "Remove the water filter. Pour one sachet of Fréscopa descaler into the tank and fill with water to MAX.",
                         systemImage: "drop.triangle", machineSeconds: nil),
                CareStep(id: 3, title: "Place a jug", detail: "Put a container that holds at least 1 litre under both the coffee and milk spouts.",
                         systemImage: "takeoutbag.and.cup.and.straw", machineSeconds: nil),
                CareStep(id: 4, title: "Run the descale cycle", detail: "The Atelier flushes descaler through the boiler and both spouts. Stay nearby to empty the jug if needed.",
                         systemImage: "arrow.triangle.2.circlepath", machineSeconds: 1200),
                CareStep(id: 5, title: "Rinse", detail: "Empty the jug, rinse and refill the tank with fresh water, and refit the filter. The Atelier runs a clean-water rinse.",
                         systemImage: "sparkles", machineSeconds: 300),
            ]
        case "filter":
            [
                CareStep(id: 1, title: "Remove the old cartridge", detail: "Lift the tank off, pull the cartridge straight up and recycle it.",
                         systemImage: "line.3.horizontal.decrease.circle", machineSeconds: nil),
                CareStep(id: 2, title: "Soak the new one", detail: "Submerge the new cartridge in cold water for five minutes, tapping it to release air bubbles.",
                         systemImage: "drop", machineSeconds: nil),
                CareStep(id: 3, title: "Fit and fill", detail: "Push the cartridge into its socket, fill the tank to MAX and seat it back on the machine.",
                         systemImage: "checkmark.circle", machineSeconds: nil),
                CareStep(id: 4, title: "Flush", detail: "Place a jug under the spout. The Atelier flushes half a litre through the new filter.",
                         systemImage: "arrow.down.to.line", machineSeconds: 90),
            ]
        default:
            [
                CareStep(id: 1, title: "Connect the milk line", detail: "Move the milk line from the milk container into a glass of fresh water.",
                         systemImage: "link", machineSeconds: nil),
                CareStep(id: 2, title: "Rinse", detail: "The Atelier pushes hot water and steam through the milk system.",
                         systemImage: "sparkles", machineSeconds: 60),
            ]
        }
    }
}

/// Drives a guided routine: step navigation plus simulated machine cycles.
@MainActor
@Observable
final class CareGuideModel {
    let task: CareTask
    let steps: [CareStep]
    private(set) var index = 0
    /// 0...1 while a machine cycle runs.
    private(set) var cycleProgress: Double?
    private(set) var isComplete = false

    private let machine: MachineController
    /// Machine seconds are scaled down so a 20-minute descale runs in a few seconds in the demo.
    private let timeScale: Double
    @ObservationIgnored private var cycleTask: Task<Void, Never>?

    init(task: CareTask, machine: MachineController, timeScale: Double = 0.006) {
        self.task = task
        self.steps = CareGuide.steps(for: task.id)
        self.machine = machine
        self.timeScale = timeScale
    }

    var title: String { CareGuide.title(for: task.id) }
    var step: CareStep { steps[index] }
    var isRunning: Bool { cycleProgress != nil }
    var canGoBack: Bool { index > 0 && !isRunning }
    var isMachineBusy: Bool { machine.isBrewing }
    /// Overall progress through the routine, 0...1.
    var overallProgress: Double {
        if isComplete { return 1 }
        return (Double(index) + (cycleProgress ?? 0)) / Double(steps.count)
    }

    var remainingLabel: String? {
        guard let seconds = step.machineSeconds, let progress = cycleProgress else {
            return step.machineSeconds.map { "About \(Self.duration($0))" }
        }
        return "\(Self.duration(Int(Double(seconds) * (1 - progress)))) left"
    }

    var primaryTitle: String {
        if step.isMachineCycle { return isRunning ? "Running…" : "Start cycle" }
        return index == steps.count - 1 ? "Finish" : "Next"
    }

    func primary() {
        if step.isMachineCycle { startCycle() } else { advance() }
    }

    func back() {
        guard canGoBack else { return }
        index -= 1
    }

    func cancel() {
        cycleTask?.cancel()
        cycleTask = nil
        cycleProgress = nil
    }

    private func advance() {
        if index < steps.count - 1 {
            index += 1
        } else {
            isComplete = true
            machine.completeCare(task.id)
        }
    }

    private func startCycle() {
        guard !isRunning, !machine.isBrewing, let seconds = step.machineSeconds else { return }
        cycleProgress = 0
        let total = max(Double(seconds) * timeScale, 0.5)
        let ticks = 40
        cycleTask = Task { [weak self] in
            for tick in 1...ticks {
                try? await Task.sleep(for: .seconds(total / Double(ticks)))
                guard !Task.isCancelled else { return }
                self?.cycleProgress = Double(tick) / Double(ticks)
            }
            self?.cycleProgress = nil
            self?.advance()
        }
    }

    /// 1200 → "20 min", 90 → "1 min 30 s", 45 → "45 s"
    static func duration(_ seconds: Int) -> String {
        let minutes = seconds / 60, rest = seconds % 60
        if minutes == 0 { return "\(rest) s" }
        return rest == 0 ? "\(minutes) min" : "\(minutes) min \(rest) s"
    }
}
