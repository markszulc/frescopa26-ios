import Foundation

/// Source of curated brew recipes.
protocol RecipeService: Sendable {
    func recipes() async throws -> [AEMRecipe]
}

/// Reads recipes from the AEM `frescopa/RecipeList` persisted GraphQL query
/// (Recipe Content Fragments under /content/dam/frescopa/en/recipes).
struct AEMRecipeService: RecipeService {
    static let recipeList = URL(string: "https://publish-p137825-e1511252.adobeaemcloud.com/graphql/execute.json/frescopa/RecipeList")!

    var endpoint: URL = recipeList
    var session: URLSession = .shared

    enum ServiceError: LocalizedError {
        case http(Int)
        var errorDescription: String? {
            switch self { case .http(let code): "Recipes are unavailable right now (\(code))." }
        }
    }

    func recipes() async throws -> [AEMRecipe] {
        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ServiceError.http(http.statusCode)
        }
        return try JSONDecoder().decode(RecipeListResponse.self, from: data).data.recipeList.items
    }
}

struct RecipeListResponse: Decodable, Sendable {
    struct Payload: Decodable, Sendable { let recipeList: List }
    struct List: Decodable, Sendable { let items: [AEMRecipe] }
    let data: Payload
}

/// A Recipe Content Fragment as delivered by the persisted query.
struct AEMRecipe: Decodable, Equatable, Sendable {
    let path: String
    let name: String
    /// Slug, e.g. "latte", "cortado", "espresso-martini".
    let drinkStyle: String
    let description: String?
    /// 1...10 scales.
    let body: Int?
    let sweetness: Int?
    let acidity: Int?
    let beanName: String?
    let beanTastingNotes: String?
    /// "small" | "regular" | "large"
    let size: String?
    /// Final drink volume in ml.
    let recipeYield: Int?
    /// "mild" | "balanced" | "strong" (descriptive; the dose carries the actual strength).
    let strength: String?
    let coffeeDose: Double?
    let brewTemperature: Double?
    /// "none" | "dairy" | "oat" | "almond"
    let milkType: String?
    let milkTemperature: Double?

    enum CodingKeys: String, CodingKey {
        case path = "_path", name, drinkStyle, description, body, sweetness, acidity, beanName, beanTastingNotes,
             size, recipeYield, strength, coffeeDose, brewTemperature, milkType, milkTemperature
    }

    /// Stable ID from the fragment path ("…/recipes/sunday-cortado" → "sunday-cortado").
    var id: String { path.split(separator: "/").last.map(String.init) ?? path }
}

/// Brew service that reads curated recipes from AEM and delegates everything else
/// (menu, machine, history) to `base`.
struct AEMRecipesBrewService: BrewService {
    var base: BrewService
    var recipeService: RecipeService = AEMRecipeService()

    func loadMenu() async throws -> BrewMenu {
        async let menuResult = base.loadMenu()
        async let recipesResult = Result { try await recipeService.recipes() }
        var menu = try await menuResult
        switch await recipesResult {
        case .success(let recipes):
            menu = RecipeMapper.apply(recipes, to: menu)
        case .failure:
            menu.recipes = []
            menu.recipesUnavailable = true
        }
        return menu
    }

    func brew(_ order: BrewOrder) -> AsyncThrowingStream<BrewProgress, Error> { base.brew(order) }
    func saveRecipe(_ recipe: BrewRecipe) async throws { try await base.saveRecipe(recipe) }
    func rate(_ entryID: BrewHistoryEntry.ID, rating: Int) async throws { try await base.rate(entryID, rating: rating) }
}

private extension Result where Failure == Error {
    init(catching body: () async throws -> Success) async {
        do { self = .success(try await body()) } catch { self = .failure(error) }
    }
}

/// Turns AEM recipes into menu recipes, matching existing drinks and beans by
/// style and name, and creating ones the menu doesn't have yet.
enum RecipeMapper {
    static func apply(_ recipes: [AEMRecipe], to menu: BrewMenu) -> BrewMenu {
        var menu = menu
        menu.recipes = recipes.map { recipe in
            let drink = drink(for: recipe, in: &menu)
            let bean = bean(for: recipe, in: &menu, isTea: drink.isTea)
            return BrewRecipe(
                id: recipe.id,
                name: recipe.name,
                drinkID: drink.id,
                settings: settings(for: recipe, drink: drink, beanID: bean.id),
                description: recipe.description,
                profile: profile(for: recipe),
                source: .aem
            )
        }
        menu.recipesUnavailable = false
        return menu
    }

    static func settings(for recipe: AEMRecipe, drink: Drink, beanID: Bean.ID) -> BrewSettings {
        var settings = drink.defaults
        settings.beanID = beanID
        settings.size = recipe.size.flatMap(CupSize.init(rawValue:)) ?? settings.size
        if let dose = recipe.coffeeDose {
            settings.doseGrams = min(max(dose, BrewSettings.doseRange.lowerBound), BrewSettings.doseRange.upperBound)
        }
        if let temperature = recipe.brewTemperature { settings.temperatureC = temperature }
        switch recipe.milkType?.lowercased() {
        case nil: break
        case "none", "": settings.milk = nil
        case let type?: settings.milk = MilkKind(rawValue: type) ?? settings.milk
        }
        if let milkTemperature = recipe.milkTemperature { settings.milkTemperatureC = milkTemperature }
        return settings
    }

    static func profile(for recipe: AEMRecipe) -> RecipeProfile? {
        guard let body = recipe.body, let sweetness = recipe.sweetness, let acidity = recipe.acidity else { return nil }
        return RecipeProfile(body: Double(body) / 10, sweetness: Double(sweetness) / 10, acidity: Double(acidity) / 10)
    }

    /// Existing menu drink for the style, or a recipe-only drink built from the fragment.
    private static func drink(for recipe: AEMRecipe, in menu: inout BrewMenu) -> Drink {
        if let existing = menu.drink(recipe.drinkStyle) { return existing }
        let usesMilk = !(recipe.milkType == nil || recipe.milkType == "none")
        let size = recipe.size.flatMap(CupSize.init(rawValue:)) ?? .regular
        let volume = recipe.recipeYield.map { Int((Double($0) / size.multiplier).rounded()) } ?? 120
        let drink = Drink(
            id: recipe.drinkStyle,
            name: title(fromSlug: recipe.drinkStyle),
            category: usesMilk ? .milk : .espresso,
            summary: recipe.description ?? "",
            volumeML: volume,
            brewSeconds: usesMilk ? 50 : 30,
            systemImage: recipe.drinkStyle.contains("martini") ? "wineglass" : (usesMilk ? "cup.and.saucer.fill" : "cup.and.saucer"),
            defaults: BrewSettings(beanID: menu.beans.first?.id ?? "house",
                                   doseGrams: recipe.coffeeDose ?? 18,
                                   temperatureC: recipe.brewTemperature ?? 93,
                                   milk: usesMilk ? (recipe.milkType.flatMap(MilkKind.init(rawValue:)) ?? .dairy) : nil)
        )
        menu.recipeDrinks.append(drink)
        return drink
    }

    /// Bean matched by name, or added to the hopper list if the menu doesn't know it.
    private static func bean(for recipe: AEMRecipe, in menu: inout BrewMenu, isTea: Bool) -> Bean {
        guard let name = recipe.beanName, !name.isEmpty else {
            return menu.beans.first { $0.id == (isTea ? "honeybush" : "house") } ?? menu.beans[0]
        }
        if let match = menu.beans.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) { return match }
        let bean = Bean(id: slug(name), name: name, notes: recipe.beanTastingNotes ?? "", roast: 0.5)
        menu.beans.append(bean)
        return bean
    }

    static func title(fromSlug slug: String) -> String {
        let words = slug.split(separator: "-").map(String.init)
        guard let first = words.first else { return slug }
        return ([first.prefix(1).uppercased() + first.dropFirst()] + words.dropFirst()).joined(separator: " ")
    }

    private static func slug(_ text: String) -> String {
        text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "-")
    }
}
