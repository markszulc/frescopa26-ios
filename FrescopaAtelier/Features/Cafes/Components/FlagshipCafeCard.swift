import SwiftUI

/// Featured flagship (SoHo) on a dark card, echoing the home screen's machine card.
struct FlagshipCafeCard: View {
    let cafe: Cafe
    let openStatus: (label: String, isOpen: Bool)
    var distance: String?
    var onOpen: () -> Void = {}
    var onDirections: () -> Void = {}
    var onBookTour: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("FLAGSHIP")
                    .font(BrandFont.body(10, weight: .bold, relativeTo: .caption2))
                    .tracking(1.4)
                    .foregroundStyle(Color.charcoal)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.amber))
                Spacer()
                if let distance {
                    Text(distance)
                        .textStyle(.caption)
                        .foregroundStyle(Color.creamSoft)
                }
            }

            Eyebrow("\(cafe.city) · \(cafe.neighbourhood)", color: .amber, weight: .regular)
                .padding(.top, 18)
            Text("The Fréscopa flagship")
                .textStyle(.cardTitle)
                .foregroundStyle(Color.cream)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)
            if let summary = cafe.summary {
                Text(summary)
                    .textStyle(.bodySmall)
                    .lineSpacing(3)
                    .foregroundStyle(Color.creamSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }

            HStack(spacing: 6) {
                ForEach(cafe.sortedAmenities) { TagLabel(text: $0.title, onDark: true) }
            }
            .padding(.top, 14)

            Rectangle().fill(Color.lineDark).frame(height: 1)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(cafe.fullAddress)
                OpenStatusLabel(status: openStatus, onDark: true)
            }
            .textStyle(.caption)
            .foregroundStyle(Color.cream)
            .padding(.top, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                Button("Book a tour", action: onBookTour)
                    .buttonStyle(.pill(.primary, fullWidth: true))
                Button("Directions", action: onDirections)
                    .buttonStyle(.pill(.ghostOnDark))
            }
            .padding(.top, 18)
        }
        .padding(20)
        .background {
            ZStack {
                Color.charcoal
                RadialGradient(colors: [Color.amber.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 300)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .onTapGesture(perform: onOpen)
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, Spacing.screenInset)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Open café details", onOpen)
    }
}

/// Green/neutral dot + "Open · until 8pm".
struct OpenStatusLabel: View {
    let status: (label: String, isOpen: Bool)
    var onDark = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.isOpen ? Color.statusOnline : (onDark ? Color.creamSoft : Color.inkSoft))
                .frame(width: 6, height: 6)
            Text(status.label)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let cafe = MockCafeService.directory.flagship!
    return FlagshipCafeCard(cafe: cafe, openStatus: (cafe.openStatus(at: .now), cafe.isOpen(at: .now)), distance: "1.2 mi")
        .padding(.vertical)
        .background(Color.paper)
}
