import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded(HomeContent)
        case failed(String)
    }

    enum BrewState: Equatable { case idle, brewing, ready }

    private(set) var state: LoadState = .loading
    private(set) var isExpediting = false
    /// Mirrors the design's `showOffer` prop: the merchandising slot can be switched off remotely.
    var showsOfferSlot = true

    private let service: HomeService
    let machine: MachineController
    private let now: () -> Date

    init(service: HomeService, machine: MachineController, now: @escaping () -> Date = { .now }) {
        self.service = service
        self.machine = machine
        self.now = now
    }

    var brewState: BrewState {
        switch machine.phase {
        case .brewing: .brewing
        case .ready: .ready
        case .idle, .failed: .idle
        }
    }

    /// Live levels from the machine (they drop as cups are made).
    var levels: Machine.Levels { machine.levels }

    var content: HomeContent? {
        if case .loaded(let content) = state { return content }
        return nil
    }

    // MARK: Loading

    func load() async {
        if content == nil { state = .loading }
        do {
            state = .loaded(try await service.loadHome())
        } catch is CancellationError {
            return
        } catch {
            if content == nil { state = .failed("We couldn't reach your Atelier. Pull to try again.") }
        }
    }

    // MARK: Greeting

    var greeting: String {
        let name = content?.user.firstName ?? ""
        let hour = Calendar.current.component(.hour, from: now())
        let part = switch hour {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
        return name.isEmpty ? "\(part)." : "\(part), \(name)."
    }

    var dateLine: String {
        BrandDateFormat.long.string(from: now())
    }

    // MARK: Brew

    var machineStatus: Machine.Status {
        switch brewState {
        case .idle: content?.machine.status ?? .ready
        case .brewing: .brewing
        case .ready: .cupReady
        }
    }

    var brewButtonTitle: String {
        switch brewState {
        case .idle: "Brew now"
        case .brewing: "Brewing…"
        case .ready: "Enjoy. Brew another?"
        }
    }

    func brew() async {
        guard !machine.isBrewing, let order = content?.recommendation.order else { return }
        await machine.brew(order)
    }

    // MARK: Supplies

    var supplyHeadline: String {
        guard let supply = content?.supply else { return "" }
        return "About \(supply.cupsRemaining) cups of \(supply.blendName) left"
    }

    var supplyDetail: String {
        guard let supply = content?.supply else { return "" }
        if let arriving = supply.expeditedDelivery {
            let isTomorrow = Calendar.current.isDate(arriving, inSameDayAs: Calendar.current.date(byAdding: .day, value: 1, to: now()) ?? now())
            let date = BrandDateFormat.short.string(from: arriving)
            return isTomorrow ? "Arriving tomorrow, \(date)." : "Arriving \(date)."
        }
        let date = BrandDateFormat.short.string(from: supply.nextDelivery)
        return "Next delivery \(date). Want it sooner?"
    }

    var supplyActionTitle: String {
        content?.supply.isExpedited == true ? "Done" : "Send now"
    }

    func expediteDelivery() async {
        guard !isExpediting, case .loaded(var content) = state, !content.supply.isExpedited else { return }
        isExpediting = true
        defer { isExpediting = false }
        do {
            content.supply.expeditedDelivery = try await service.expediteNextDelivery()
            state = .loaded(content)
        } catch {
            // Leave the nudge as-is; the user can retry.
        }
    }
}

/// The brand writes dates day-first ("Thursday 19 November", "Tue 1 Dec") regardless of region.
enum BrandDateFormat {
    static let long: DateFormatter = make("EEEE d MMMM")
    static let short: DateFormatter = make("EEE d MMM")

    private static func make(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = format
        return formatter
    }
}
