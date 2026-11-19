import Foundation
import Testing
@testable import FrescopaAtelier

@MainActor
struct AccountTests {
    private func makeModel() async -> AccountViewModel {
        let model = AccountViewModel(service: MockAccountService(latency: .zero),
                                     machine: MachineController(service: MockBrewService(latency: .zero, timeScale: 0.001)))
        await model.load()
        return model
    }

    @Test func loadsOverview() async {
        let model = await makeModel()
        #expect(model.overview?.profile.initials == "M")
        #expect(model.memberSinceLine.hasPrefix("Member since"))
        #expect(model.overview?.tasteHistory.count == 8)
        #expect(model.nextDeliveryLine.hasPrefix("Next delivery"))
    }

    @Test func skippingMovesDeliveryByCadence() async {
        let model = await makeModel()
        let before = model.overview!.subscription
        await model.skipNext()
        let after = model.overview!.subscription
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: before.nextDelivery, to: after.nextDelivery).weekOfYear
        #expect(weeks == before.cadence.weeks)
        #expect(model.toast != nil)
    }

    @Test func pauseAndResume() async {
        let model = await makeModel()
        await model.pause(weeks: 4)
        #expect(model.overview?.subscription.isPaused == true)
        #expect(model.nextDeliveryLine.hasPrefix("Paused until"))
        await model.resume()
        #expect(model.overview?.subscription.isPaused == false)
    }

    @Test func changingCadenceRepricesDelivery() async {
        let model = await makeModel()
        await model.update(cadence: .weekly, bags: 3)
        #expect(model.overview?.subscription.cadence == .weekly)
        #expect(model.overview?.subscription.bags == 3)
        #expect(model.overview?.subscription.pricePerDelivery == 54)
    }

    @Test func cupsBrewedIncludesThisSession() async {
        let model = await makeModel()
        let before = model.cupsBrewed
        let drink = MockBrewService.drinks[0]
        await model.machine.brew(BrewOrder(drink: drink, settings: drink.defaults))
        #expect(model.cupsBrewed == before + 1)
    }

    @Test func signOutAndBackIn() async {
        let model = await makeModel()
        await model.signOut()
        #expect(model.isSignedOut)
        await model.signBackIn()
        #expect(!model.isSignedOut)
        #expect(model.overview != nil)
    }
}
