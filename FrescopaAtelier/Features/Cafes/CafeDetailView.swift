import MapKit
import SwiftUI

/// A single café: map header, address, hours, what's inside, and actions.
struct CafeDetailView: View {
    let cafe: Cafe
    let model: CafesViewModel
    var onDirections: () -> Void = {}
    var onBookTour: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                mapHeader

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        if cafe.isFlagship {
                            Text("FLAGSHIP")
                                .font(BrandFont.body(10, weight: .bold, relativeTo: .caption2))
                                .tracking(1.4)
                                .foregroundStyle(Color.charcoal)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.amber))
                        }
                        Eyebrow(cafe.cityLine)
                    }
                    Text(cafe.name)
                        .textStyle(.greetingTitle)
                        .foregroundStyle(Color.burgundy)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)
                    if let summary = cafe.summary {
                        Text(summary)
                            .textStyle(.bodySmall)
                            .lineSpacing(3)
                            .foregroundStyle(Color.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                    }

                    infoCard.padding(.top, 20)

                    HStack(spacing: 10) {
                        if cafe.hasShowroom {
                            Button("Book an Atelier tour", action: onBookTour)
                                .buttonStyle(DarkPrimaryPill())
                        }
                        Button("Directions", action: onDirections)
                            .buttonStyle(.pill(.outline, height: 48, horizontalPadding: 20))
                    }
                    .padding(.top, 18)

                    Text("What's inside")
                        .textStyle(.sectionTitle)
                        .foregroundStyle(Color.burgundy)
                        .padding(.top, 32)
                    VStack(spacing: 10) {
                        ForEach(cafe.sortedAmenities) { amenity in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: amenity.systemImage)
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.burgundy)
                                    .frame(width: 40, height: 40)
                                    .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Color.amber.opacity(0.3)))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(amenity.title).textStyle(.productTitle).foregroundStyle(Color.ink)
                                    Text(amenity.blurb).textStyle(.caption).foregroundStyle(Color.inkSoft)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.top, 14)

                    if cafe.hasWorkshops, let events = model.directory?.events {
                        Text("At the table this week")
                            .textStyle(.sectionTitle)
                            .foregroundStyle(Color.burgundy)
                            .padding(.top, 32)
                        VStack(spacing: 0) {
                            ForEach(events) { event in
                                EventRow(
                                    event: event,
                                    dayLabel: model.dayLabel(for: event),
                                    isSaved: model.isSaved(event),
                                    isWorking: model.seatInFlight == event.id,
                                    onToggleSeat: { Task { await model.toggleSeat(event) } }
                                )
                                if event.id != events.last?.id { Rectangle().fill(Color.line).frame(height: 1) }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.headingInset)
                .padding(.top, 20)
                .padding(.bottom, Spacing.lg)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color.paper, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(cafe.neighbourhood)
                    .font(BrandFont.display(17, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(Color.ink)
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: URL(string: "https://www.frescopacoffee.com/cafe#\(cafe.id)")!,
                          subject: Text(cafe.name),
                          message: Text(cafe.fullAddress))
            }
        }
    }

    private var mapHeader: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: cafe.coordinate,
            latitudinalMeters: 1400,
            longitudinalMeters: 1400
        )), interactionModes: []) {
            Annotation(cafe.name, coordinate: cafe.coordinate, anchor: .bottom) {
                CafePin(isFlagship: cafe.isFlagship, isSelected: true)
            }
            .annotationTitles(.hidden)
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .padding(.horizontal, Spacing.screenInset)
        .padding(.top, 8)
        .accessibilityLabel("Map showing \(cafe.name)")
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow("mappin", cafe.fullAddress, distance: model.distanceLabel(for: cafe))
            Rectangle().fill(Color.line).frame(height: 1)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "clock").frame(width: 20).foregroundStyle(Color.burgundy)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mon–Sun · \(cafe.hours.rangeLabel)").foregroundStyle(Color.ink)
                    OpenStatusLabel(status: model.openStatus(for: cafe)).foregroundStyle(Color.inkSoft)
                }
            }
            .accessibilityElement(children: .combine)
        }
        .textStyle(.bodySmall)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
    }

    private func infoRow(_ icon: String, _ text: String, distance: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).frame(width: 20).foregroundStyle(Color.burgundy)
            Text(text).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            if let distance { Text(distance).foregroundStyle(Color.inkSoft) }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Burgundy-filled pill for primary actions on light surfaces.
struct DarkPrimaryPill: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BrandFont.body(15, weight: .semibold, relativeTo: .subheadline))
            .foregroundStyle(Color.cream)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Capsule().fill(configuration.isPressed ? Color.burgundyDeep : Color.burgundy))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        CafeDetailView(cafe: MockCafeService.directory.flagship!, model: CafesViewModel(service: MockCafeService()))
    }
}
