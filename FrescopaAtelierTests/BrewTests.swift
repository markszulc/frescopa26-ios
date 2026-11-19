import Foundation
import Testing
@testable import FrescopaAtelier

@MainActor
struct BrewTests {
    private func makeModel() async -> BrewViewModel {
        let service = MockBrewService(latency: .zero, timeScale: 0.001)
        let model = BrewViewModel(service: service, machine: MachineController(service: service))
        await model.load()
        return model
    }

    @Test func menuLoadsAndFiltersByCategory() async {
        let model = await makeModel()
        #expect(model.drinks.count == MockBrewService.drinks.count)
        model.category = .milk
        #expect(model.drinks.allSatisfy { $0.category == .milk })
        #expect(model.usualOrder?.drink.id == "flat-white")
    }

    @Test func brewingRecordsHistoryAndDrainsLevels() async {
        let model = await makeModel()
        let before = model.machine.levels
        let historyCount = model.menu?.history.count ?? 0
        await model.brew(model.usualOrder!)
        #expect(model.machine.status == .cupReady)
        #expect(model.menu?.history.count == historyCount + 1)
        #expect(model.machine.levels.beans < before.beans)
        #expect(model.machine.levels.water < before.water)
        let entry = model.lastEntryID!
        await model.rate(entry, 4)
        #expect(model.rating(for: entry) == 4)
    }

    @Test func cancellingReturnsToIdle() async {
        let service = MockBrewService(latency: .zero, timeScale: 1)
        let machine = MachineController(service: service)
        let drink = MockBrewService.drinks[0]
        let brew = Task { await machine.brew(BrewOrder(drink: drink, settings: drink.defaults)) }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(machine.isBrewing)
        machine.cancel()
        await brew.value
        #expect(machine.phase == .idle)
        #expect(machine.completedCount == 0)
    }

    @Test func savingARecipePutsItFirst() async {
        let model = await makeModel()
        model.customize(MockBrewService.drinks.first { $0.id == "cortado" }!)
        let draft = model.customizing!
        draft.settings.doseGrams = 20
        await model.saveRecipe(named: "Strong cortado", from: draft)
        #expect(model.menu?.recipes.first?.name == "Strong cortado")
        #expect(model.menu?.recipes.first?.settings.doseGrams == 20)
    }

    @Test func tasteRespondsToSettings() {
        let drink = MockBrewService.drinks.first { $0.id == "espresso" }!
        let bean = MockBrewService.beans[0]
        var gentle = drink.defaults; gentle.doseGrams = 14
        var bold = drink.defaults; bold.doseGrams = 22
        #expect(TastePrediction(settings: bold, drink: drink, bean: bean).body
                > TastePrediction(settings: gentle, drink: drink, bean: bean).body)
        let filter = MockBrewService.drinks.first { $0.id == "slow-pour" }!
        let guji = MockBrewService.beans[1]
        #expect(TastePrediction(settings: filter.defaults, drink: filter, bean: guji).acidity
                > TastePrediction(settings: drink.defaults, drink: drink, bean: bean).acidity)
    }
}
