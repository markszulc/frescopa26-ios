import Foundation
import Observation

@MainActor
@Observable
final class BrewViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded(BrewMenu)
        case failed(String)
    }

    private(set) var state: LoadState = .loading
    var category: DrinkCategory?
    /// The drink being customised in the sheet, if any.
    var customizing: DrinkCustomizerModel?
    /// Shows the full-screen brewing view for brews started from this tab.
    var showsProgress = false
    /// History entry for the most recent cup brewed from this tab (rated on the progress screen).
    private(set) var lastEntryID: BrewHistoryEntry.ID?

    let machine: MachineController
    private let service: BrewService
    private let now: () -> Date

    init(service: BrewService, machine: MachineController, now: @escaping () -> Date = { .now }) {
        self.service = service
        self.machine = machine
        self.now = now
    }

    var menu: BrewMenu? {
        if case .loaded(let menu) = state { return menu }
        return nil
    }

    func load() async {
        if menu == nil { state = .loading }
        do {
            state = .loaded(try await service.loadMenu())
            if wantsUsualCustomizer {
                wantsUsualCustomizer = false
                customizeUsual()
            }
        } catch is CancellationError {
            return
        } catch {
            if menu == nil { state = .failed("We couldn't reach your Atelier. Pull to try again.") }
        }
    }

    // MARK: Menu

    var drinks: [Drink] {
        guard let menu else { return [] }
        guard let category else { return menu.drinks }
        return menu.drinks.filter { $0.category == category }
    }

    var usualOrder: BrewOrder? {
        guard let menu, let drink = menu.drink(menu.usual.drinkID) else { return nil }
        return BrewOrder(drink: drink, settings: menu.usual.settings, recipeName: "Your usual")
    }

    func order(for recipe: BrewRecipe) -> BrewOrder? {
        guard let drink = menu?.drink(recipe.drinkID) else { return nil }
        return BrewOrder(drink: drink, settings: recipe.settings, recipeName: recipe.name,
                         recipeDescription: recipe.description)
    }

    func summary(for order: BrewOrder) -> String {
        let beanName = menu?.bean(order.settings.beanID)?.name ?? ""
        return order.settings.summary(beanName: beanName, isTea: order.drink.isTea)
    }

    // MARK: Customise

    func customize(_ drink: Drink) {
        guard let menu else { return }
        customizing = DrinkCustomizerModel(drink: drink, settings: drink.defaults, beans: menu.beans)
    }

    func customize(_ order: BrewOrder) {
        guard let menu else { return }
        customizing = DrinkCustomizerModel(drink: order.drink, settings: order.settings, beans: menu.beans,
                                           recipeName: order.recipeName, recipeDescription: order.recipeDescription)
    }

    func customizeUsual() {
        if let usualOrder { customize(usualOrder) }
    }

    /// Opens the usual in the customiser, waiting for the menu if it hasn't loaded yet
    /// (e.g. when "Adjust" is tapped on Home before the Brew tab was ever opened).
    func requestUsualCustomizer() {
        if menu != nil { customizeUsual() } else { wantsUsualCustomizer = true }
    }

    @ObservationIgnored private var wantsUsualCustomizer = false

    func saveRecipe(named name: String, from draft: DrinkCustomizerModel) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, case .loaded(var menu) = state else { return }
        let recipe = BrewRecipe(id: UUID().uuidString, name: trimmed, drinkID: draft.drink.id, settings: draft.settings)
        do {
            try await service.saveRecipe(recipe)
            menu.recipes.insert(recipe, at: 0)
            state = .loaded(menu)
        } catch {
            // Saving is best-effort; the brew itself is unaffected.
        }
    }

    // MARK: Brew

    func brew(_ order: BrewOrder, showProgress: Bool = true) async {
        guard !machine.isBrewing else { return }
        customizing = nil
        showsProgress = showProgress
        await machine.brew(order)
        if case .ready(let finished) = machine.phase {
            record(finished)
        }
    }

    func cancelBrew() {
        machine.cancel()
        showsProgress = false
    }

    func dismissProgress() {
        showsProgress = false
        machine.acknowledge()
    }

    private func record(_ order: BrewOrder) {
        guard case .loaded(var menu) = state else { return }
        let beanName = menu.bean(order.settings.beanID)?.name ?? ""
        let detail = [beanName, order.settings.milk?.title.lowercased()].compactMap { $0 }.joined(separator: " · ")
        let entry = BrewHistoryEntry(id: UUID().uuidString, drinkName: order.title, detail: detail, date: now(), rating: nil)
        menu.history.insert(entry, at: 0)
        state = .loaded(menu)
        lastEntryID = entry.id
    }

    // MARK: Ratings

    func rate(_ entryID: BrewHistoryEntry.ID, _ rating: Int) async {
        guard case .loaded(var menu) = state, let index = menu.history.firstIndex(where: { $0.id == entryID }) else { return }
        menu.history[index].rating = rating
        state = .loaded(menu)
        try? await service.rate(entryID, rating: rating)
    }

    func rating(for entryID: BrewHistoryEntry.ID) -> Int? {
        menu?.history.first { $0.id == entryID }?.rating
    }

    func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now())
    }
}

/// Editable state for the drink customiser sheet.
@MainActor
@Observable
final class DrinkCustomizerModel: Identifiable {
    let id = UUID()
    let drink: Drink
    let beans: [Bean]
    var settings: BrewSettings
    let recipeName: String?
    let recipeDescription: String?

    init(drink: Drink, settings: BrewSettings, beans: [Bean], recipeName: String? = nil, recipeDescription: String? = nil) {
        self.drink = drink
        self.settings = settings
        self.beans = beans
        self.recipeName = recipeName
        self.recipeDescription = recipeDescription
    }

    /// Tea uses leaf hoppers; coffee drinks use bean hoppers.
    var availableBeans: [Bean] {
        drink.isTea ? beans.filter { $0.id == "honeybush" } : beans.filter { $0.id != "honeybush" }
    }

    var selectedBean: Bean? { beans.first { $0.id == settings.beanID } }

    var temperatureRange: ClosedRange<Double> {
        drink.isTea ? BrewSettings.teaTemperatureRange : BrewSettings.temperatureRange
    }

    var taste: TastePrediction { TastePrediction(settings: settings, drink: drink, bean: selectedBean) }

    var order: BrewOrder { BrewOrder(drink: drink, settings: settings, recipeName: recipeName, recipeDescription: recipeDescription) }

    var volumeLabel: String { "\(order.volumeML) ml" }

    /// "Stronger" / "Balanced" / "Gentler" for the dose slider.
    var strengthLabel: String {
        switch settings.doseGrams {
        case ..<16: "Gentler"
        case 20...: "Stronger"
        default: "Balanced"
        }
    }

    var isModified: Bool { settings != drink.defaults }

    func reset() { settings = drink.defaults }
}
