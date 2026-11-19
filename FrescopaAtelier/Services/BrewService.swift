import Foundation

/// Backend + machine boundary for brewing.
protocol BrewService: Sendable {
    func loadMenu() async throws -> BrewMenu
    /// Starts a brew and streams progress until the cup is ready. Cancelling the
    /// consuming task asks the machine to stop.
    func brew(_ order: BrewOrder) -> AsyncThrowingStream<BrewProgress, Error>
    func saveRecipe(_ recipe: BrewRecipe) async throws
    func rate(_ entryID: BrewHistoryEntry.ID, rating: Int) async throws
}

struct MockBrewService: BrewService {
    var latency: Duration = .milliseconds(300)
    /// Real machine seconds are scaled by this so demos don't take half a minute.
    var timeScale: Double = 0.22

    func loadMenu() async throws -> BrewMenu {
        try await Task.sleep(for: latency)
        return Self.menu(now: .now)
    }

    func brew(_ order: BrewOrder) -> AsyncThrowingStream<BrewProgress, Error> {
        let stages = BrewStage.stages(for: order.drink)
        let total = Double(order.drink.brewSeconds) * order.settings.size.multiplier * timeScale
        let ticksPerStage = 8
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for (index, stage) in stages.enumerated() {
                        for tick in 0..<ticksPerStage {
                            try await Task.sleep(for: .seconds(total / Double(stages.count * ticksPerStage)))
                            let done = Double(index * ticksPerStage + tick + 1) / Double(stages.count * ticksPerStage)
                            continuation.yield(BrewProgress(stage: stage, fraction: done))
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func saveRecipe(_ recipe: BrewRecipe) async throws {
        try await Task.sleep(for: .milliseconds(250))
    }

    func rate(_ entryID: BrewHistoryEntry.ID, rating: Int) async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    // MARK: - Sample menu

    static let beans: [Bean] = [
        Bean(id: "house", name: "House blend", notes: "Cocoa, toasted hazelnut, round", roast: 0.65),
        Bean(id: "guji", name: "Ethiopia Guji", notes: "Bergamot, peach, bright", roast: 0.25),
        Bean(id: "decaf", name: "Swiss Water decaf", notes: "Brown sugar, soft", roast: 0.55),
        Bean(id: "honeybush", name: "Honeybush & orange", notes: "Loose leaf, caffeine-free", roast: 0.4),
    ]

    static let drinks: [Drink] = [
        Drink(id: "espresso", name: "Espresso", category: .espresso,
              summary: "A short, syrupy shot. The heart of everything else.", volumeML: 30, brewSeconds: 28,
              systemImage: "cup.and.saucer", defaults: .init(beanID: "house", doseGrams: 18, temperatureC: 93)),
        Drink(id: "ristretto", name: "Ristretto", category: .espresso,
              summary: "Shorter and sweeter, with the edges rounded off.", volumeML: 20, brewSeconds: 22,
              systemImage: "cup.and.saucer", defaults: .init(beanID: "house", doseGrams: 19, temperatureC: 92)),
        Drink(id: "lungo", name: "Lungo", category: .espresso,
              summary: "A longer pull for a lighter, more open cup.", volumeML: 90, brewSeconds: 40,
              systemImage: "cup.and.saucer", defaults: .init(beanID: "house", doseGrams: 17, temperatureC: 94)),
        Drink(id: "americano", name: "Americano", category: .espresso,
              summary: "Espresso lengthened with hot water.", volumeML: 200, brewSeconds: 36,
              systemImage: "mug", defaults: .init(beanID: "house", doseGrams: 18, temperatureC: 93)),
        Drink(id: "flat-white", name: "Flat white", category: .milk,
              summary: "Double ristretto under a thin layer of silky milk.", volumeML: 160, brewSeconds: 48,
              systemImage: "cup.and.saucer.fill",
              defaults: .init(beanID: "house", doseGrams: 18, temperatureC: 93, milk: .oat, milkTemperatureC: 60, foam: .silky)),
        Drink(id: "cappuccino", name: "Cappuccino", category: .milk,
              summary: "Equal parts espresso, milk and airy foam.", volumeML: 180, brewSeconds: 50,
              systemImage: "cup.and.saucer.fill",
              defaults: .init(beanID: "house", doseGrams: 18, temperatureC: 93, milk: .dairy, milkTemperatureC: 62, foam: .airy)),
        Drink(id: "latte", name: "Latte", category: .milk,
              summary: "A gentle shot in plenty of warm milk.", volumeML: 260, brewSeconds: 55,
              systemImage: "mug.fill",
              defaults: .init(beanID: "house", doseGrams: 17, temperatureC: 92, milk: .dairy, milkTemperatureC: 60, foam: .silky)),
        Drink(id: "cortado", name: "Cortado", category: .milk,
              summary: "Espresso cut with a splash of warm milk.", volumeML: 110, brewSeconds: 42,
              systemImage: "cup.and.saucer.fill",
              defaults: .init(beanID: "house", doseGrams: 18, temperatureC: 93, milk: .dairy, milkTemperatureC: 58, foam: .flat)),
        Drink(id: "slow-pour", name: "Slow-pour filter", category: .filter,
              summary: "Clean and tea-like. Best with a single origin.", volumeML: 300, brewSeconds: 180,
              systemImage: "drop", defaults: .init(beanID: "guji", doseGrams: 18, temperatureC: 94)),
        Drink(id: "cold-brew", name: "Cold brew", category: .cold,
              summary: "Steeped cool and slow. Chocolatey, low in acid.", volumeML: 250, brewSeconds: 90,
              systemImage: "snowflake", defaults: .init(beanID: "house", doseGrams: 20, temperatureC: 86)),
        Drink(id: "iced-latte", name: "Iced latte", category: .cold,
              summary: "A double shot over cold milk and ice.", volumeML: 300, brewSeconds: 45,
              systemImage: "snowflake",
              defaults: .init(beanID: "house", doseGrams: 18, temperatureC: 93, milk: .oat, milkTemperatureC: 50, foam: .flat)),
        Drink(id: "loose-leaf", name: "Loose-leaf tea", category: .tea,
              summary: "Water at exactly the right heat for the leaf.", volumeML: 250, brewSeconds: 120,
              systemImage: "leaf", defaults: .init(beanID: "honeybush", doseGrams: 14, temperatureC: 95)),
    ]

    static func menu(now: Date) -> BrewMenu {
        let hour: TimeInterval = 3600
        let flatWhite = drinks.first { $0.id == "flat-white" }!
        var tuned = flatWhite.defaults
        tuned.doseGrams = 18
        tuned.temperatureC = 92
        return BrewMenu(
            drinks: drinks,
            beans: beans,
            usual: BrewRecipe(id: "usual", name: "Flat white, a touch rounder.", drinkID: flatWhite.id, settings: tuned),
            usualReason: "Cooler morning, early meeting. House blend, 18 g, oat milk at 60°.",
            recipes: [
                BrewRecipe(id: "sunday-cortado", name: "Sunday cortado", drinkID: "cortado",
                           settings: .init(beanID: "guji", doseGrams: 19, temperatureC: 92, milk: .dairy, milkTemperatureC: 56, foam: .flat)),
                BrewRecipe(id: "afternoon-decaf", name: "Afternoon decaf", drinkID: "latte",
                           settings: .init(beanID: "decaf", size: .large, doseGrams: 17, temperatureC: 92, milk: .oat, milkTemperatureC: 62, foam: .silky)),
                BrewRecipe(id: "bright-pour", name: "Bright slow-pour", drinkID: "slow-pour",
                           settings: .init(beanID: "guji", doseGrams: 16, temperatureC: 95)),
            ],
            history: [
                BrewHistoryEntry(id: "h1", drinkName: "Flat white", detail: "House blend · oat", date: now.addingTimeInterval(-9 * hour), rating: 5),
                BrewHistoryEntry(id: "h2", drinkName: "Slow-pour filter", detail: "Ethiopia Guji", date: now.addingTimeInterval(-28 * hour), rating: 4),
                BrewHistoryEntry(id: "h3", drinkName: "Afternoon decaf", detail: "Swiss Water decaf · oat", date: now.addingTimeInterval(-32 * hour), rating: nil),
            ]
        )
    }
}
