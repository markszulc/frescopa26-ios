import Foundation
import Testing
@testable import FrescopaAtelier

@MainActor
struct CareTests {
    private func machine() -> MachineController {
        MachineController(service: MockBrewService(latency: .zero, timeScale: 0.001))
    }

    @Test func descaleIsUrgentAndLowersHealth() {
        let m = machine()
        #expect(m.urgentCare?.id == "descale")
        #expect(m.health < 0.6)
    }

    @Test func guidedDescaleRunsCyclesAndResetsReminder() async throws {
        let m = machine()
        let task = try #require(m.care.first { $0.id == "descale" })
        let guide = CareGuideModel(task: task, machine: m, timeScale: 0.0001)
        // Three manual steps, then two machine cycles that auto-advance.
        guide.primary(); guide.primary(); guide.primary()
        #expect(guide.step.isMachineCycle)
        guide.primary()
        #expect(guide.isRunning)
        try await Task.sleep(for: .milliseconds(1500))
        #expect(guide.index == 4)
        guide.primary()
        try await Task.sleep(for: .milliseconds(1500))
        #expect(guide.isComplete)
        #expect(m.care.first { $0.id == "descale" }?.remaining == 1)
        #expect(m.urgentCare == nil)
    }

    @Test func backIsBlockedWhileRunning() async {
        let m = machine()
        let guide = CareGuideModel(task: m.care.first { $0.id == "milk" }!, machine: m, timeScale: 1)
        guide.primary()
        guide.primary()
        #expect(guide.isRunning)
        #expect(!guide.canGoBack)
        guide.cancel()
        #expect(!guide.isRunning)
        #expect(guide.canGoBack)
    }

    @Test func refillsAndFilterCompletion() {
        let m = machine()
        m.refill(.water)
        #expect(m.levels.water == 1)
        m.completeCare("filter")
        #expect(m.levels.filter == 1)
    }

    @Test func durations() {
        #expect(CareGuideModel.duration(1200) == "20 min")
        #expect(CareGuideModel.duration(90) == "1 min 30 s")
        #expect(CareGuideModel.duration(45) == "45 s")
    }
}
