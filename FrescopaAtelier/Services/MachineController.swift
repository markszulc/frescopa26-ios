import Foundation
import Observation

/// Single source of truth for the connected Atelier. Shared by Home and Brew so a
/// brew started anywhere shows everywhere, and levels drop as cups are made.
@MainActor
@Observable
final class MachineController {
    enum Phase: Equatable {
        case idle
        case brewing(BrewOrder, BrewProgress)
        case ready(BrewOrder)
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var levels: Machine.Levels
    /// Bumped after every completed cup, so observers can react (history, haptics).
    private(set) var completedCount = 0
    private(set) var lastCompleted: BrewOrder?

    private let service: BrewService
    @ObservationIgnored private var task: Task<Void, Never>?

    init(service: BrewService, levels: Machine.Levels = .init(water: 0.72, beans: 0.18, filter: 0.60)) {
        self.service = service
        self.levels = levels
    }

    var isBrewing: Bool {
        if case .brewing = phase { return true }
        return false
    }

    var progress: BrewProgress? {
        if case .brewing(_, let progress) = phase { return progress }
        return nil
    }

    var currentOrder: BrewOrder? {
        switch phase {
        case .brewing(let order, _), .ready(let order): order
        default: nil
        }
    }

    var status: Machine.Status {
        switch phase {
        case .idle, .failed: .ready
        case .brewing: .brewing
        case .ready: .cupReady
        }
    }

    /// Starts a brew. Returns once the brew finishes, fails, or is cancelled.
    func brew(_ order: BrewOrder) async {
        guard !isBrewing else { return }
        let stages = BrewStage.stages(for: order.drink)
        phase = .brewing(order, BrewProgress(stage: stages.first ?? .grinding, fraction: 0))
        let work = Task { [service] in
            do {
                for try await progress in service.brew(order) {
                    try Task.checkCancellation()
                    self.phase = .brewing(order, progress)
                }
                try Task.checkCancellation()
                self.finish(order)
            } catch is CancellationError {
                self.phase = .idle
            } catch {
                self.phase = .failed("The Atelier stopped mid-brew. Check the water tank and try again.")
            }
        }
        task = work
        await work.value
    }

    func cancel() {
        task?.cancel()
        task = nil
        phase = .idle
    }

    /// Clears a finished or failed brew back to idle.
    func acknowledge() {
        if !isBrewing { phase = .idle }
    }

    private func finish(_ order: BrewOrder) {
        let volume = Double(order.volumeML)
        levels.water = max(levels.water - volume / 2_000 * 0.2, 0)
        if !order.drink.isTea {
            levels.beans = max(levels.beans - order.settings.doseGrams / 1_000, 0)
        }
        levels.filter = max(levels.filter - 0.005, 0)
        lastCompleted = order
        completedCount += 1
        phase = .ready(order)
    }
}
