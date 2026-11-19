import Foundation
import Observation

@MainActor
@Observable
final class AccountViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded(AccountOverview)
        case failed(String)
    }

    private(set) var state: LoadState = .loading
    /// Name of the subscription action currently in flight ("skip", "pause"…), for button spinners.
    private(set) var busyAction: String?
    private(set) var toast: String?
    private(set) var isSignedOut = false

    private let service: AccountService
    let machine: MachineController
    private let now: () -> Date

    init(service: AccountService, machine: MachineController, now: @escaping () -> Date = { .now }) {
        self.service = service
        self.machine = machine
        self.now = now
    }

    var overview: AccountOverview? {
        if case .loaded(let overview) = state { return overview }
        return nil
    }

    func load() async {
        if overview == nil { state = .loading }
        do {
            state = .loaded(try await service.loadAccount())
        } catch is CancellationError {
            return
        } catch {
            if overview == nil { state = .failed("We couldn't load your account. Pull to try again.") }
        }
    }

    // MARK: Membership

    var memberSinceLine: String {
        guard let since = overview?.membership.memberSince else { return "" }
        return "Member since " + since.formatted(.dateTime.month(.wide).year())
    }

    /// Cups brewed on the machine, including any made this session.
    var cupsBrewed: Int { (overview?.machine.cupsBrewed ?? 0) + machine.completedCount }

    // MARK: Subscription

    var nextDeliveryLine: String {
        guard let sub = overview?.subscription else { return "" }
        let date = BrandDateFormat.long.string(from: sub.nextDelivery)
        if case .paused = sub.status { return "Paused until \(date)" }
        return "Next delivery \(date)"
    }

    func skipNext() async { await mutate("skip", success: "Skipped. We'll send the next one as usual.") { try await $0.skipNextDelivery() } }

    func pause(weeks: Int) async {
        await mutate("pause", success: "Paused for \(weeks) weeks.") { try await $0.pauseSubscription(weeks: weeks) }
    }

    func resume() async { await mutate("resume", success: "Welcome back. Your next box ships soon.") { try await $0.resumeSubscription() } }

    func update(cadence: DeliveryCadence, bags: Int) async {
        await mutate("update", success: "Subscription updated.") { try await $0.updateSubscription(cadence: cadence, bags: bags) }
    }

    private func mutate(_ action: String, success: String,
                        _ call: @escaping (AccountService) async throws -> Subscription) async {
        guard busyAction == nil else { return }
        busyAction = action
        defer { busyAction = nil }
        do {
            let subscription = try await call(service)
            if case .loaded(var overview) = state {
                overview.subscription = subscription
                state = .loaded(overview)
            }
            showToast(success)
        } catch {
            showToast("That didn't go through. Please try again.")
        }
    }

    // MARK: Notifications

    func setNotifications(_ preferences: NotificationPreferences) async {
        guard case .loaded(var overview) = state else { return }
        let previous = overview.notifications
        overview.notifications = preferences
        state = .loaded(overview)
        do {
            try await service.updateNotifications(preferences)
        } catch {
            overview.notifications = previous
            state = .loaded(overview)
            showToast("Couldn't save notification settings.")
        }
    }

    // MARK: Machine care

    /// The account's machine, with live care state from the shared controller.
    func liveMachine(_ machine: OwnedMachine) -> OwnedMachine {
        var copy = machine
        copy.care = self.machine.care
        return copy
    }

    // MARK: Session

    func signBackIn() async {
        isSignedOut = false
        await load()
    }


    func signOut() async {
        do {
            try await service.signOut()
            isSignedOut = true
        } catch {
            showToast("Couldn't sign out. Please try again.")
        }
    }

    // MARK: Toast

    private func showToast(_ message: String) {
        toast = message
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            if self?.toast == message { self?.toast = nil }
        }
    }

    func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now())
    }
}
