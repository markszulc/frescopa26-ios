import SwiftUI

/// Cafés tab: the café & showroom story, what's on, and the café finder.
struct CafesView: View {
    @State private var model: CafesViewModel
    @State private var location: LocationProvider
    @State private var path: [Cafe] = []
    @State private var booking: TourSheetRequest?

    @Environment(\.openURL) private var openURL

    init(model: CafesViewModel, location: LocationProvider) {
        _model = State(initialValue: model)
        _location = State(initialValue: location)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                ScrollView {
                    switch model.state {
                    case .loading:
                        ProgressView()
                            .tint(Color.burgundy)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 200)
                    case .failed(let message):
                        Text(message)
                            .textStyle(.bodySmall)
                            .foregroundStyle(Color.inkSoft)
                            .padding(.top, 200)
                    case .loaded(let directory):
                        content(directory, proxy: proxy)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .background(Color.paper)
            .refreshable { await model.load() }
            .task { if model.directory == nil { await model.load() } }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Cafe.self) { cafe in
                CafeDetailView(
                    cafe: cafe,
                    model: model,
                    onDirections: { directions(to: cafe) },
                    onBookTour: { book(at: cafe) }
                )
            }
        }
        .tint(Color.burgundy)
        .onChange(of: location.location, initial: true) { _, new in
            withAnimation(Motion.quint) { model.userLocation = new }
        }
        .sheet(item: $booking) { request in
            TourBookingView(model: TourBookingModel(
                showrooms: request.showrooms,
                preselected: request.cafe,
                service: model.service
            ))
        }
    }

    @ViewBuilder
    private func content(_ directory: CafeDirectory, proxy: ScrollViewProxy) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            CafesHero(
                onFindNearest: {
                    if location.status != .denied { location.request() }
                    withAnimation(Motion.expo) { proxy.scrollTo(FinderAnchor.id, anchor: .top) }
                },
                onBookTour: { book(at: nil) }
            )
            .padding(.top, 8)
            .reveal()

            WhatsOnSection(
                events: directory.events,
                dayLabel: model.dayLabel(for:),
                isSaved: model.isSaved(_:),
                inFlight: model.seatInFlight,
                onToggleSeat: { event in Task { await model.toggleSeat(event) } }
            )
            .padding(.top, 28)
            .reveal(delay: 0.08)

            finder(directory)
                .id(FinderAnchor.id)
                .padding(.top, 32)

            VisitReasonsRail(reasons: MockCafeService.reasons)
                .padding(.top, 32)

            CafeRoomsSection(rooms: MockCafeService.rooms) { room in
                if room.number == 3 {
                    withAnimation(Motion.expo) { proxy.scrollTo(FinderAnchor.id, anchor: .top) }
                }
            }
            .padding(.top, 28)

            TourPromoCard { book(at: nil) }
                .padding(.top, 12)
                .padding(.bottom, Spacing.md)
        }
    }

    @ViewBuilder
    private func finder(_ directory: CafeDirectory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Find us")
                Text("There's a Fréscopa in your town.")
                    .textStyle(.sectionTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
                Text("Every café pours the full range — showrooms and workshop tables vary by location.")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.headingInset)

            CafeStatsRow(stats: directory.stats)
                .padding(.top, 14)

            if let flagship = directory.flagship {
                FlagshipCafeCard(
                    cafe: flagship,
                    openStatus: model.openStatus(for: flagship),
                    distance: model.distanceLabel(for: flagship),
                    onOpen: { path.append(flagship) },
                    onDirections: { directions(to: flagship) },
                    onBookTour: { book(at: flagship) }
                )
                .padding(.top, 16)
            }

            CafeFilterBar(
                mode: $model.displayMode,
                region: $model.region,
                amenities: model.requiredAmenities,
                locationStatus: location.status,
                hasLocation: model.userLocation != nil,
                onToggleAmenity: { amenity in withAnimation(Motion.quint) { model.toggle(amenity) } },
                onUseLocation: { location.request() }
            )
            .padding(.top, 22)

            switch model.displayMode {
            case .list:
                cafeList
            case .map:
                CafesMapView(
                    cafes: model.mapCafes,
                    userLocation: model.userLocation,
                    openStatus: model.openStatus(for:),
                    distance: model.distanceLabel(for:),
                    onOpen: { path.append($0) }
                )
                .frame(height: 460)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, 14)
            }
        }
        .animation(Motion.quint, value: model.displayMode)
    }

    @ViewBuilder
    private var cafeList: some View {
        let cafes = model.filteredCafes
        HStack {
            Eyebrow(model.resultsTitle, color: .inkSoft, size: 10, trackingEm: 0.14)
                .contentTransition(.numericText())
            Spacer()
            if model.hasActiveFilters {
                Button("Clear filters") { withAnimation(Motion.quint) { model.clearFilters() } }
                    .font(BrandFont.body(13, weight: .medium, relativeTo: .footnote))
                    .foregroundStyle(Color.terracottaDeep)
            }
        }
        .padding(.horizontal, Spacing.headingInset)
        .padding(.top, 18)

        if cafes.isEmpty {
            Text("No cafés match those filters yet. Try another region.")
                .textStyle(.caption)
                .foregroundStyle(Color.inkSoft)
                .padding(.horizontal, Spacing.headingInset)
                .padding(.vertical, 24)
        } else {
            VStack(spacing: 0) {
                ForEach(cafes) { cafe in
                    Button { path.append(cafe) } label: {
                        CafeRow(cafe: cafe, openStatus: model.openStatus(for: cafe), distance: model.distanceLabel(for: cafe))
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.99))
                    if cafe.id != cafes.last?.id {
                        Rectangle().fill(Color.line).frame(height: 1).padding(.leading, 58)
                    }
                }
            }
            .padding(.horizontal, Spacing.headingInset)
            .padding(.top, 4)
        }
    }

    // MARK: Actions

    private func book(at cafe: Cafe?) {
        guard let showrooms = model.directory?.showrooms, !showrooms.isEmpty else { return }
        booking = TourSheetRequest(cafe: cafe, showrooms: showrooms)
    }

    private func directions(to cafe: Cafe) {
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(cafe.latitude),\(cafe.longitude)"),
            URLQueryItem(name: "q", value: cafe.name),
        ]
        if let url = components.url { openURL(url) }
    }

    private enum FinderAnchor { static let id = "cafe-finder" }
}

/// Identifiable payload for the tour-booking sheet.
private struct TourSheetRequest: Identifiable {
    let id = UUID()
    let cafe: Cafe?
    let showrooms: [Cafe]
}

#Preview {
    CafesView(model: CafesViewModel(service: MockCafeService()), location: LocationProvider())
}
