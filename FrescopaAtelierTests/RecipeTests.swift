import Foundation
import Testing
@testable import FrescopaAtelier

private final class RecipeBundleToken {}

private struct StubRecipes: RecipeService {
    var result: Result<[AEMRecipe], Error>
    func recipes() async throws -> [AEMRecipe] { try result.get() }
}

struct RecipeTests {
    /// Real response captured from the AEM `frescopa/RecipeList` persisted query.
    private func fixture() throws -> [AEMRecipe] {
        let url = try #require(Bundle(for: RecipeBundleToken.self).url(forResource: "aem-recipe-list", withExtension: "json"))
        return try JSONDecoder().decode(RecipeListResponse.self, from: Data(contentsOf: url)).data.recipeList.items
    }

    private func menu(with recipes: [AEMRecipe]) -> BrewMenu {
        RecipeMapper.apply(recipes, to: MockBrewService.menu(now: .now))
    }

    @Test func decodesRecipeFragments() throws {
        let recipes = try fixture()
        #expect(recipes.map(\.id) == ["afternoon-decaf", "friday-espresso-martini", "sunday-cortado"])
        #expect(recipes[1].milkTemperature == nil)
    }

    @Test func mapsOntoExistingDrinksAndBeans() throws {
        let menu = menu(with: try fixture())
        let decaf = try #require(menu.recipes.first { $0.id == "afternoon-decaf" })
        #expect(decaf.drinkID == "latte")
        #expect(decaf.settings.beanID == "decaf")
        #expect(decaf.settings.size == .large)
        #expect(decaf.settings.milk == .oat)
        #expect(decaf.settings.milkTemperatureC == 62)
        #expect(decaf.settings.doseGrams == 17)
        #expect(decaf.source == .aem)
        #expect(decaf.description?.hasPrefix("A mellow oat latte") == true)
        #expect(decaf.profile == RecipeProfile(body: 0.6, sweetness: 0.7, acidity: 0.2))
    }

    @Test func createsRecipeOnlyDrinkForUnknownStyle() throws {
        let menu = menu(with: try fixture())
        let martini = try #require(menu.recipes.first { $0.id == "friday-espresso-martini" })
        let drink = try #require(menu.drink(martini.drinkID))
        #expect(drink.name == "Espresso martini")
        #expect(martini.settings.milk == nil)
        #expect(!menu.drinks.contains { $0.id == drink.id }, "recipe-only drinks stay out of the menu grid")
        #expect(BrewOrder(drink: drink, settings: martini.settings).volumeML == 120)
    }

    @Test func unknownBeanIsAddedToHoppers() {
        let custom = AEMRecipe(path: "/r/x", name: "X", drinkStyle: "espresso", description: nil, body: nil, sweetness: nil,
                               acidity: nil, beanName: "Kenya AA", beanTastingNotes: "Blackcurrant", size: nil,
                               recipeYield: nil, strength: nil, coffeeDose: 25, brewTemperature: nil, milkType: nil,
                               milkTemperature: nil)
        let menu = menu(with: [custom])
        #expect(menu.bean("kenya-aa")?.notes == "Blackcurrant")
        #expect(menu.recipes[0].settings.doseGrams == BrewSettings.doseRange.upperBound, "dose is clamped to the machine range")
    }

    @Test func feedFailureLeavesMenuUsable() async throws {
        let service = AEMRecipesBrewService(base: MockBrewService(latency: .zero),
                                            recipeService: StubRecipes(result: .failure(URLError(.notConnectedToInternet))))
        let menu = try await service.loadMenu()
        #expect(menu.recipes.isEmpty)
        #expect(menu.recipesUnavailable)
        #expect(!menu.drinks.isEmpty)
    }

    @Test func feedReplacesSampleRecipes() async throws {
        let service = AEMRecipesBrewService(base: MockBrewService(latency: .zero),
                                            recipeService: StubRecipes(result: .success(try fixture())))
        let menu = try await service.loadMenu()
        #expect(menu.recipes.map(\.name) == ["Afternoon decaf", "Friday espresso martini", "Sunday cortado"])
        #expect(!menu.recipesUnavailable)
    }
}

/// Hits the real AEM endpoint. Run with LIVE_AEM=1 in the test environment.
struct LiveAEMRecipeTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["LIVE_AEM"] != nil))
    func liveRecipeListResponds() async throws {
        #expect(!(try await AEMRecipeService().recipes()).isEmpty)
    }
}
