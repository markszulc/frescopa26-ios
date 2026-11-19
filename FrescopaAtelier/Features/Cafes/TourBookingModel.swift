import Foundation
import Observation

/// Drives the "Book an Atelier tour" sheet.
@MainActor
@Observable
final class TourBookingModel {
    enum Phase: Equatable {
        case editing
        case submitting
        case confirmed(TourConfirmation)
        case failed(String)
    }

    var request: TourRequest
    private(set) var phase: Phase = .editing
    /// Set after the first submit attempt so validation hints only appear once relevant.
    private(set) var showsValidation = false

    let showrooms: [Cafe]
    private let service: CafeService

    init(showrooms: [Cafe], preselected: Cafe?, service: CafeService, now: Date = .now) {
        self.showrooms = showrooms
        self.service = service
        let start = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) ?? now
        let cafeID = (preselected?.hasShowroom == true ? preselected?.id : nil) ?? showrooms.first?.id ?? ""
        request = TourRequest(cafeID: cafeID, date: start)
        earliestDate = start
    }

    let earliestDate: Date
    var latestDate: Date { Calendar.current.date(byAdding: .day, value: 60, to: earliestDate) ?? earliestDate }

    var selectedCafe: Cafe? { showrooms.first { $0.id == request.cafeID } }

    var nameError: String? {
        showsValidation && request.name.trimmingCharacters(in: .whitespaces).isEmpty ? "Add your name" : nil
    }

    var emailError: String? {
        showsValidation && !request.isEmailValid ? "Add a valid email so we can confirm" : nil
    }

    var slotError: String? {
        showsValidation && request.slot == nil ? "Pick a time" : nil
    }

    var isSubmitting: Bool { phase == .submitting }

    func toggle(_ interest: TourInterest) {
        if request.interests.contains(interest) {
            request.interests.remove(interest)
        } else {
            request.interests.insert(interest)
        }
    }

    func submit() async {
        showsValidation = true
        guard request.isComplete, phase != .submitting else { return }
        phase = .submitting
        do {
            phase = .confirmed(try await service.requestTour(request))
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func dismissError() {
        if case .failed = phase { phase = .editing }
    }
}
