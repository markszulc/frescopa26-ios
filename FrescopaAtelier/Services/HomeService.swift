import Foundation

/// Backend boundary for the home screen. Swap `MockHomeService` for a networked
/// implementation without touching any view code.
protocol HomeService: Sendable {
    func loadHome() async throws -> HomeContent
    /// Asks fulfilment to ship the next delivery now. Returns the new arrival date.
    func expediteNextDelivery() async throws -> Date
}

struct MockHomeService: HomeService {
    var latency: Duration = .milliseconds(350)
    var now: @Sendable () -> Date = { .now }

    func loadHome() async throws -> HomeContent {
        try await Task.sleep(for: latency)
        return Self.sample(now: now())
    }

    func expediteNextDelivery() async throws -> Date {
        try await Task.sleep(for: .milliseconds(450))
        return Calendar.current.date(byAdding: .day, value: 1, to: now()) ?? now()
    }

    static func sample(now: Date = .now) -> HomeContent {
        let calendar = Calendar.current
        let nextDelivery = calendar.date(byAdding: .day, value: 12, to: now) ?? now
        let brewMenu = MockBrewService.menu(now: now)
        let usualOrder = BrewOrder(drink: brewMenu.drink(brewMenu.usual.drinkID)!,
                                   settings: brewMenu.usual.settings,
                                   recipeName: "Your usual")

        return HomeContent(
            user: UserProfile(firstName: "Mark", unreadNotifications: 1),
            machine: Machine(
                name: "The Atelier",
                room: "Kitchen",
                status: .ready,
                levels: .init(water: 0.72, beans: 0.18, filter: 0.60)
            ),
            recommendation: BrewRecommendation(
                eyebrow: "Your usual, tuned for today",
                title: "Flat white, a touch rounder.",
                rationale: "Cooler morning, early meeting. House blend, 18 g, oat milk at 60°.",
                order: usualOrder
            ),
            supply: SupplyStatus(
                blendName: "House blend",
                cupsRemaining: 6,
                nextDelivery: nextDelivery,
                expeditedDelivery: nil
            ),
            offers: [
                Offer(
                    id: "single-origin-20",
                    badge: "Members' offer",
                    title: "20% off your first single origin.",
                    detail: "Ethiopia Guji, roasted Monday.",
                    callToAction: "Claim offer",
                    artwork: .image(name: "offer-single-origin", focusY: 0.4),
                    deepLink: URL(string: "frescopa://offers/single-origin-20")
                ),
                Offer(
                    id: "descale-kit",
                    badge: "Care",
                    title: "Your descale kit ships free this month.",
                    detail: "Keeps the Atelier pulling sweet shots.",
                    callToAction: "Add to next box",
                    artwork: .gradient,
                    deepLink: URL(string: "frescopa://offers/descale-kit")
                ),
                Offer(
                    id: "cafe-tasting",
                    badge: "Cafés",
                    title: "A winter tasting flight, on us.",
                    detail: "Show this at any Fréscopa café.",
                    callToAction: "See cafés",
                    artwork: .gradient,
                    deepLink: URL(string: "frescopa://offers/cafe-tasting")
                ),
            ],
            picks: [
                ProductPick(id: "ethiopia-guji", matchLabel: "94% match", title: "Ethiopia Guji single origin",
                            price: 22, currencyCode: "USD", imageName: "pick-espresso-pour",
                            imageDescription: "Espresso pouring into a glass.", kind: .coffee),
                ProductPick(id: "honeybush-orange", matchLabel: "For evenings", title: "Honeybush and orange peel",
                            price: 14, currencyCode: "USD", imageName: "pick-tea-moment",
                            imageDescription: "Amber tea beside loose leaves.", kind: .tea),
                ProductPick(id: "cold-pressed-citrus", matchLabel: "Pairs with brunch", title: "Cold-pressed citrus",
                            price: 10, currencyCode: "USD", imageName: "pick-citrus-juice",
                            imageDescription: "Cold-pressed citrus juice.", kind: .juice),
            ],
            taste: TasteProfile(
                headline: "Drifting rounder and a little sweeter as the mornings cool.",
                attributes: [
                    .init(label: "Body", value: 0.78),
                    .init(label: "Sweetness", value: 0.64),
                    .init(label: "Acidity", value: 0.38),
                ]
            )
        )
    }
}
