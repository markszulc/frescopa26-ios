import SwiftUI

/// "There's a Fréscopa in your town." — network stats.
struct CafeStatsRow: View {
    let stats: CafeNetworkStats

    var body: some View {
        HStack(spacing: 0) {
            stat(stats.cafes, "Cafés")
            divider
            stat(stats.cities, "Cities")
            divider
            stat(stats.states, "States")
            divider
            stat(stats.showrooms, "Showrooms")
        }
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
        .padding(.horizontal, Spacing.screenInset)
    }

    private var divider: some View {
        Rectangle().fill(Color.line).frame(width: 1, height: 34)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(BrandFont.display(20, relativeTo: .title3))
                .tracking(-0.4)
                .foregroundStyle(Color.burgundy)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Eyebrow(label, color: .inkSoft, size: 9, trackingEm: 0.1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// List/Map toggle, location opt-in, region + amenity chips.
struct CafeFilterBar: View {
    @Binding var mode: CafesViewModel.DisplayMode
    @Binding var region: CafeRegion?
    let amenities: Set<CafeAmenity>
    let locationStatus: LocationProvider.Status
    let hasLocation: Bool
    var onToggleAmenity: (CafeAmenity) -> Void = { _ in }
    var onUseLocation: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Picker("View", selection: $mode) {
                    ForEach(CafesViewModel.DisplayMode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)

                Spacer()

                locationButton
            }
            .padding(.horizontal, Spacing.screenInset)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    FilterChip(title: "All regions", isSelected: region == nil) { region = nil }
                    ForEach(CafeRegion.allCases) { item in
                        FilterChip(title: item.title, isSelected: region == item) {
                            region = region == item ? nil : item
                        }
                    }
                    Rectangle().fill(Color.line).frame(width: 1, height: 22).padding(.horizontal, 2)
                    ForEach([CafeAmenity.showroom, .workshops]) { amenity in
                        FilterChip(title: amenity.title, systemImage: amenity.systemImage,
                                   isSelected: amenities.contains(amenity)) { onToggleAmenity(amenity) }
                    }
                }
                .padding(.horizontal, Spacing.screenInset)
            }
            .scrollIndicators(.hidden)
            .sensoryFeedback(.selection, trigger: region)
        }
    }

    @ViewBuilder
    private var locationButton: some View {
        switch (locationStatus, hasLocation) {
        case (_, true):
            Label("Near you", systemImage: "location.fill")
                .labelStyle(CompactLabelStyle())
                .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
                .foregroundStyle(Color.terracottaDeep)
        case (.authorized, false), (.requesting, _):
            Label("Locating…", systemImage: "location")
                .labelStyle(CompactLabelStyle())
                .font(BrandFont.body(13, weight: .medium, relativeTo: .footnote))
                .foregroundStyle(Color.inkSoft)
        case (.denied, _):
            Label("Location off", systemImage: "location.slash")
                .labelStyle(CompactLabelStyle())
                .font(BrandFont.body(13, weight: .medium, relativeTo: .footnote))
                .foregroundStyle(Color.inkSoft)
        default:
            Button(action: onUseLocation) {
                Label("Use my location", systemImage: "location")
                    .labelStyle(CompactLabelStyle())
            }
            .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
            .foregroundStyle(Color.terracottaDeep)
            .buttonStyle(.pressable)
        }
    }
}

/// One café in the finder list.
struct CafeRow: View {
    let cafe: Cafe
    let openStatus: (label: String, isOpen: Bool)
    var distance: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.paper2)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
                BrandIconView(icon: .location, size: 22)
                    .foregroundStyle(Color.burgundy)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(cafe.name)
                        .textStyle(.productTitle)
                        .foregroundStyle(Color.ink)
                    Spacer(minLength: 8)
                    if let distance {
                        Text(distance)
                            .textStyle(.caption)
                            .foregroundStyle(Color.inkSoft)
                    }
                }
                Eyebrow(cafe.cityLine, size: 10, trackingEm: 0.12)
                Text(cafe.street)
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                HStack(spacing: 6) {
                    ForEach(cafe.sortedAmenities) { TagLabel(text: $0.title) }
                }
                .padding(.top, 4)
                OpenStatusLabel(status: openStatus)
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .padding(.top, 4)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkSoft.opacity(0.6))
                .padding(.top, 14)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    let cafes = Array(MockCafeService.cafes.prefix(3))
    return VStack(spacing: 20) {
        CafeStatsRow(stats: MockCafeService.directory.stats)
        CafeFilterBar(mode: .constant(.list), region: .constant(nil), amenities: [.showroom], locationStatus: .unknown, hasLocation: false)
        VStack(spacing: 0) {
            ForEach(cafes) { CafeRow(cafe: $0, openStatus: ("Open · until 8pm", true), distance: "2.4 mi") }
        }
        .padding(.horizontal)
    }
    .background(Color.paper)
}
