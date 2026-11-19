import Foundation
import Testing
@testable import FrescopaAtelier

@MainActor
struct HomeViewModelTests {
    /// Thursday 19 November 2026, 08:30 local time.
    static let morning: Date = {
        var components = DateComponents(year: 2026, month: 11, day: 19, hour: 8, minute: 30)
        components.calendar = .current
        return components.date!
    }()

    private func makeModel(now: Date = morning) -> HomeViewModel {
        let service = MockHomeService(latency: .zero, now: { now })
        let machine = MachineController(service: MockBrewService(latency: .zero, timeScale: 0.001))
        return HomeViewModel(service: service, machine: machine, now: { now })
    }

    @Test func loadsContentAndGreetsByTimeOfDay() async {
        let model = makeModel()
        await model.load()
        #expect(model.content != nil)
        #expect(model.greeting == "Good morning, Mark.")
        #expect(model.dateLine == "Thursday 19 November")
    }

    @Test func eveningGreeting() async {
        let evening = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Self.morning)!
        let model = makeModel(now: evening)
        await model.load()
        #expect(model.greeting == "Good evening, Mark.")
    }

    @Test func brewMovesThroughStates() async {
        let model = makeModel()
        await model.load()
        #expect(model.brewButtonTitle == "Brew now")
        #expect(model.machineStatus == .ready)
        await model.brew()
        #expect(model.brewState == .ready)
        #expect(model.machineStatus == .cupReady)
        #expect(model.brewButtonTitle == "Enjoy. Brew another?")
        #expect(model.levels.beans < 0.18)
    }

    @Test func expeditingDeliveryUpdatesSupplyCopy() async {
        let model = makeModel()
        await model.load()
        #expect(model.supplyDetail == "Next delivery Tue 1 Dec. Want it sooner?")
        #expect(model.supplyActionTitle == "Send now")
        await model.expediteDelivery()
        #expect(model.supplyDetail == "Arriving tomorrow, Fri 20 Nov.")
        #expect(model.supplyActionTitle == "Done")
    }
}
