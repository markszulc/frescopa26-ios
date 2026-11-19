import CoreLocation
import Foundation
import Testing
@testable import FrescopaAtelier

@MainActor
struct CafesViewModelTests {
    private func loadedModel(now: Date = .now) async -> CafesViewModel {
        let model = CafesViewModel(service: MockCafeService(latency: .zero), now: { now })
        await model.load()
        return model
    }

    @Test func listExcludesFlagshipAndShowsAllOthers() async {
        let model = await loadedModel()
        #expect(model.filteredCafes.count == MockCafeService.cafes.count - 1)
        #expect(model.filteredCafes.filter(\.isFlagship).isEmpty)
        #expect(model.mapCafes.filter(\.isFlagship).count == 1)
    }

    @Test func regionAndAmenityFiltersCombine() async {
        let model = await loadedModel()
        model.region = .midwest
        model.toggle(.workshops)
        #expect(model.filteredCafes.map(\.id).sorted() == ["north-loop", "west-loop"])
        model.clearFilters()
        #expect(!model.hasActiveFilters)
    }

    @Test func sortsByDistanceWhenLocationKnown() async {
        let model = await loadedModel()
        model.userLocation = CLLocation(latitude: 47.61, longitude: -122.33) // Seattle
        #expect(model.filteredCafes.first?.id == "capitol-hill")
        #expect(model.resultsTitle.hasSuffix("near you"))
        #expect(model.nearest()?.id == "capitol-hill")
    }

    @Test func openStatusUsesCafeTimeZone() {
        let cafe = MockCafeService.cafes.first { $0.id == "soho" }!  // 7am–8pm New York
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let morning = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 9))!
        let night = calendar.date(from: DateComponents(year: 2026, month: 11, day: 19, hour: 21))!
        #expect(cafe.isOpen(at: morning))
        #expect(!cafe.isOpen(at: night))
        #expect(cafe.openStatus(at: night) == "Closed · opens 7am")
        #expect(cafe.hours.rangeLabel == "7am–8pm")
    }

    @Test func savingAndCancellingASeat() async {
        let model = await loadedModel()
        let event = MockCafeService.directory.events[1]
        await model.toggleSeat(event)
        #expect(model.isSaved(event))
        await model.toggleSeat(event)
        #expect(!model.isSaved(event))
    }

    @Test func dropInEventsCannotBeBooked() async {
        let model = await loadedModel()
        let dropIn = MockCafeService.directory.events.first { !$0.requiresBooking }!
        await model.toggleSeat(dropIn)
        #expect(!model.isSaved(dropIn))
    }
}

@MainActor
struct TourBookingModelTests {
    private func makeModel() -> TourBookingModel {
        TourBookingModel(showrooms: MockCafeService.directory.showrooms, preselected: nil, service: MockCafeService(latency: .zero))
    }

    @Test func defaultsToFirstShowroomAndTomorrow() {
        let model = makeModel()
        #expect(model.request.cafeID == "soho")
        #expect(model.request.date > .now)
    }

    @Test func validationAppearsOnlyAfterSubmit() async {
        let model = makeModel()
        #expect(model.emailError == nil)
        await model.submit()
        #expect(model.emailError != nil)
        #expect(model.nameError != nil)
        #expect(model.slotError != nil)
        #expect(model.phase == .editing)
    }

    @Test func completeRequestIsConfirmed() async {
        let model = makeModel()
        model.request.slot = TourRequest.slots[0]
        model.request.name = "Mark"
        model.request.email = "mark@example.com"
        await model.submit()
        guard case .confirmed(let confirmation) = model.phase else {
            Issue.record("Expected confirmation, got \(model.phase)")
            return
        }
        #expect(confirmation.cafeName == "Fréscopa SoHo")
    }
}
