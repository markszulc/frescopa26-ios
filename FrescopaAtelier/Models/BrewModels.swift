import Foundation

enum DrinkCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case espresso, milk, filter, cold, tea

    var id: String { rawValue }

    var title: String {
        switch self {
        case .espresso: "Espresso"
        case .milk: "With milk"
        case .filter: "Filter"
        case .cold: "Cold"
        case .tea: "Tea"
        }
    }
}

enum MilkKind: String, CaseIterable, Identifiable, Hashable, Sendable {
    case dairy, oat, almond

    var id: String { rawValue }
    var title: String {
        switch self {
        case .dairy: "Dairy"
        case .oat: "Oat"
        case .almond: "Almond"
        }
    }
}

enum FoamLevel: String, CaseIterable, Identifiable, Hashable, Sendable {
    case flat, silky, airy

    var id: String { rawValue }
    var title: String {
        switch self {
        case .flat: "Flat"
        case .silky: "Silky"
        case .airy: "Airy"
        }
    }
}

enum CupSize: String, CaseIterable, Identifiable, Hashable, Sendable {
    case small, regular, large

    var id: String { rawValue }
    var title: String {
        switch self {
        case .small: "Small"
        case .regular: "Regular"
        case .large: "Large"
        }
    }
    var multiplier: Double {
        switch self {
        case .small: 0.75
        case .regular: 1
        case .large: 1.35
        }
    }
}

/// A bean (or leaf) in one of the machine's hoppers.
struct Bean: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    var notes: String
    /// 0...1 — lighter roasts carry more acidity.
    var roast: Double
}

/// Everything the machine needs to make one cup.
struct BrewSettings: Equatable, Hashable, Sendable {
    var beanID: String
    var size: CupSize = .regular
    /// Grams of coffee. Ignored for tea.
    var doseGrams: Double
    var temperatureC: Double
    var milk: MilkKind?
    var milkTemperatureC: Double = 60
    var foam: FoamLevel = .silky

    static let doseRange: ClosedRange<Double> = 14...22
    static let temperatureRange: ClosedRange<Double> = 86...96
    static let teaTemperatureRange: ClosedRange<Double> = 70...100
    static let milkTemperatureRange: ClosedRange<Double> = 50...70

    /// "House blend · 18 g · 93° · oat at 60°"
    func summary(beanName: String, isTea: Bool) -> String {
        var parts = [beanName]
        if !isTea { parts.append("\(Int(doseGrams.rounded())) g") }
        parts.append("\(Int(temperatureC.rounded()))°")
        if let milk { parts.append("\(milk.title.lowercased()) at \(Int(milkTemperatureC.rounded()))°") }
        return parts.joined(separator: " · ")
    }
}

struct Drink: Identifiable, Equatable, Hashable, Sendable {
    var id: String
    var name: String
    var category: DrinkCategory
    var summary: String
    /// Regular-size volume in ml.
    var volumeML: Int
    /// Machine time at regular size.
    var brewSeconds: Int
    var systemImage: String
    var defaults: BrewSettings
    /// Whether milk settings apply (and can be changed).
    var usesMilk: Bool { category == .milk }
    var isTea: Bool { category == .tea }
    var isCold: Bool { category == .cold }
}

/// A named set of settings the customer saved.
struct BrewRecipe: Identifiable, Equatable, Hashable, Sendable {
    enum Source: Hashable, Sendable { case local, aem }

    var id: String
    var name: String
    var drinkID: Drink.ID
    var settings: BrewSettings
    /// Editorial blurb (from AEM recipes).
    var description: String? = nil
    /// Authored flavour profile, 0...1 each (from AEM recipes).
    var profile: RecipeProfile? = nil
    var source: Source = .local
}

struct RecipeProfile: Hashable, Sendable {
    var body: Double
    var sweetness: Double
    var acidity: Double
}

struct BrewOrder: Equatable, Sendable {
    var drink: Drink
    var settings: BrewSettings
    var recipeName: String?
    var recipeDescription: String? = nil

    var volumeML: Int { Int((Double(drink.volumeML) * settings.size.multiplier).rounded()) }
    var title: String { recipeName ?? drink.name }
}

struct BrewHistoryEntry: Identifiable, Equatable, Sendable {
    var id: String
    var drinkName: String
    var detail: String
    var date: Date
    /// 1...5, `nil` until rated.
    var rating: Int?
}

/// The Atelier's machine stages, in order.
enum BrewStage: Int, CaseIterable, Comparable, Sendable {
    case grinding, preInfusion, extracting, steaming, finishing

    static func < (lhs: BrewStage, rhs: BrewStage) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .grinding: "Grinding"
        case .preInfusion: "Blooming"
        case .extracting: "Extracting"
        case .steaming: "Texturing milk"
        case .finishing: "Finishing"
        }
    }

    /// Stages the machine runs for a drink.
    static func stages(for drink: Drink) -> [BrewStage] {
        if drink.isTea { return [.preInfusion, .extracting, .finishing] }
        return allCases.filter { $0 != .steaming || drink.usesMilk }
    }
}

struct BrewProgress: Equatable, Sendable {
    var stage: BrewStage
    /// 0...1 across the whole brew.
    var fraction: Double
}

struct BrewMenu: Equatable, Sendable {
    var drinks: [Drink]
    var beans: [Bean]
    var usual: BrewRecipe
    var usualReason: String
    var recipes: [BrewRecipe]
    var history: [BrewHistoryEntry]
    /// Drinks that only exist through a recipe (e.g. an espresso martini). Not shown in the menu grid.
    var recipeDrinks: [Drink] = []
    /// True when the recipe feed couldn't be reached; recipes saved on-device still show.
    var recipesUnavailable = false

    func drink(_ id: Drink.ID) -> Drink? { drinks.first { $0.id == id } ?? recipeDrinks.first { $0.id == id } }
    func bean(_ id: Bean.ID) -> Bean? { beans.first { $0.id == id } }
}

/// Predicted flavour of a cup, 0...1 each. A friendly heuristic, not chemistry.
struct TastePrediction: Equatable, Sendable {
    var body: Double
    var sweetness: Double
    var acidity: Double

    init(settings: BrewSettings, drink: Drink, bean: Bean?) {
        let roast = bean?.roast ?? 0.5
        let doseNorm = (settings.doseGrams - BrewSettings.doseRange.lowerBound)
            / (BrewSettings.doseRange.upperBound - BrewSettings.doseRange.lowerBound)
        let tempNorm = (settings.temperatureC - BrewSettings.temperatureRange.lowerBound)
            / (BrewSettings.temperatureRange.upperBound - BrewSettings.temperatureRange.lowerBound)
        let milk = settings.milk == nil ? 0.0 : 1.0
        let dilution = drink.category == .filter || drink.isCold ? 0.25 : 0
        let sizeThin = (settings.size.multiplier - 1) * 0.3

        func clamp(_ value: Double) -> Double { min(max(value, 0.05), 1) }
        body = clamp(0.35 + doseNorm * 0.35 + milk * 0.2 + roast * 0.15 - dilution - sizeThin)
        sweetness = clamp(0.3 + milk * (settings.milk == .oat ? 0.3 : 0.2) + (1 - abs(tempNorm - 0.55)) * 0.2
                          + (settings.foam == .silky ? 0.05 : 0) - (drink.isTea ? 0.1 : 0))
        acidity = clamp(0.6 - roast * 0.35 - tempNorm * 0.2 - milk * 0.15 + dilution * 0.6)
    }
}
