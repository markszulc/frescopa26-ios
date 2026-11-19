import Foundation

protocol AccountService: Sendable {
    func loadAccount() async throws -> AccountOverview
    func updateSubscription(cadence: DeliveryCadence, bags: Int) async throws -> Subscription
    func skipNextDelivery() async throws -> Subscription
    func pauseSubscription(weeks: Int) async throws -> Subscription
    func resumeSubscription() async throws -> Subscription
    func updateNotifications(_ preferences: NotificationPreferences) async throws
    func signOut() async throws
}

/// In-memory account backend. An actor so mutations from concurrent calls stay consistent.
actor MockAccountService: AccountService {
    private var overview: AccountOverview
    private let latency: Duration
    private let now: @Sendable () -> Date

    init(latency: Duration = .milliseconds(300), now: @escaping @Sendable () -> Date = { .now }) {
        self.latency = latency
        self.now = now
        self.overview = Self.sample(now: now())
    }

    func loadAccount() async throws -> AccountOverview {
        try await Task.sleep(for: latency)
        return overview
    }

    func updateSubscription(cadence: DeliveryCadence, bags: Int) async throws -> Subscription {
        try await Task.sleep(for: latency)
        overview.subscription.cadence = cadence
        overview.subscription.bags = min(max(bags, 1), 4)
        overview.subscription.pricePerDelivery = Decimal(18 * overview.subscription.bags)
        return overview.subscription
    }

    func skipNextDelivery() async throws -> Subscription {
        try await Task.sleep(for: latency)
        let sub = overview.subscription
        overview.subscription.nextDelivery = Calendar.current.date(
            byAdding: .weekOfYear, value: sub.cadence.weeks, to: sub.nextDelivery) ?? sub.nextDelivery
        return overview.subscription
    }

    func pauseSubscription(weeks: Int) async throws -> Subscription {
        try await Task.sleep(for: latency)
        let until = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: now()) ?? now()
        overview.subscription.status = .paused(until: until)
        overview.subscription.nextDelivery = until
        return overview.subscription
    }

    func resumeSubscription() async throws -> Subscription {
        try await Task.sleep(for: latency)
        overview.subscription.status = .active
        let soonest = Calendar.current.date(byAdding: .day, value: 3, to: now()) ?? now()
        overview.subscription.nextDelivery = soonest
        return overview.subscription
    }

    func updateNotifications(_ preferences: NotificationPreferences) async throws {
        try await Task.sleep(for: .milliseconds(150))
        overview.notifications = preferences
    }

    func signOut() async throws {
        try await Task.sleep(for: latency)
    }

    // MARK: - Sample

    static func sample(now: Date) -> AccountOverview {
        let calendar = Calendar.current
        func daysAgo(_ days: Int) -> Date { calendar.date(byAdding: .day, value: -days, to: now) ?? now }
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        // Eight weeks drifting rounder and sweeter as the mornings cool (ends at the home card's 78/64/38).
        let body: [Double] = [0.58, 0.60, 0.63, 0.66, 0.70, 0.72, 0.75, 0.78]
        let sweet: [Double] = [0.50, 0.52, 0.51, 0.55, 0.58, 0.60, 0.62, 0.64]
        let acid: [Double] = [0.55, 0.54, 0.50, 0.48, 0.45, 0.42, 0.40, 0.38]
        let history = (0..<8).map { index in
            TasteWeek(weekStart: calendar.date(byAdding: .weekOfYear, value: index - 7, to: weekStart) ?? weekStart,
                      body: body[index], sweetness: sweet[index], acidity: acid[index])
        }

        return AccountOverview(
            profile: AccountProfile(firstName: "Mark", lastName: "", email: "mark@example.com", city: "New York"),
            membership: Membership(tier: "Atelier member", memberSince: calendar.date(byAdding: .month, value: -14, to: now) ?? now,
                                   points: 340, nextRewardAt: 500, nextRewardTitle: "a free bag of single origin"),
            subscription: Subscription(productName: "House blend", bagSizeGrams: 250, bags: 2, cadence: .fortnightly,
                                       pricePerDelivery: 36,
                                       nextDelivery: calendar.date(byAdding: .day, value: 12, to: now) ?? now,
                                       status: .active),
            machine: OwnedMachine(
                name: "The Atelier", model: "Atelier · Cream", room: "Kitchen", serial: "FA-24-118203",
                firmware: "3.2.1", cupsBrewed: 412,
                care: [
                    CareTask(id: "descale", title: "Descale", detail: "Keeps shots sweet and the boiler healthy.",
                             remaining: 0.12, dueIn: "Due in 4 days", systemImage: "drop.triangle"),
                    CareTask(id: "filter", title: "Water filter", detail: "Swap the cartridge for softer water.",
                             remaining: 0.60, dueIn: "About 5 weeks left", systemImage: "line.3.horizontal.decrease.circle"),
                    CareTask(id: "milk", title: "Milk system rinse", detail: "Runs automatically after each milk drink.",
                             remaining: 0.95, dueIn: "Rinsed today", systemImage: "sparkles"),
                ]
            ),
            tasteHistory: history,
            orders: [
                OrderSummary(id: "FR-20931", title: "House blend subscription", itemCount: 2, total: 36,
                             date: daysAgo(2), status: .shipped),
                OrderSummary(id: "FR-20518", title: "Ethiopia Guji + descale kit", itemCount: 2, total: 34,
                             date: daysAgo(19), status: .delivered),
                OrderSummary(id: "FR-20102", title: "House blend subscription", itemCount: 2, total: 36,
                             date: daysAgo(30), status: .delivered),
            ],
            notifications: NotificationPreferences()
        )
    }
}
