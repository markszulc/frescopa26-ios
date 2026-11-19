import SwiftUI

/// "Reasons to make the trip." — horizontal rail of four reason cards.
struct VisitReasonsRail: View {
    let reasons: [VisitReason]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("Why come in")
                Text("Reasons to make the trip.")
                    .textStyle(.sectionTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, Spacing.headingInset)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(reasons) { reason in
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: reason.systemImage)
                                .font(.system(size: 19))
                                .foregroundStyle(Color.burgundy)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                                        .fill(Color.amber.opacity(0.30))
                                )
                                .accessibilityHidden(true)
                            Text(reason.title)
                                .textStyle(.productTitle)
                                .foregroundStyle(Color.ink)
                                .padding(.top, 4)
                            Text(reason.detail)
                                .textStyle(.caption)
                                .foregroundStyle(Color.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(width: 220, alignment: .topLeading)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
                        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
                        .accessibilityElement(children: .combine)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, 14)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

/// "Three rooms, one long morning." — numbered rooms with links.
struct CafeRoomsSection: View {
    let rooms: [CafeRoom]
    var onLink: (CafeRoom) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("The experience")
                Text("Three rooms, one long morning.")
                    .textStyle(.sectionTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, Spacing.headingInset)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(rooms) { room in
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(String(format: "%02d · %@", room.number, room.name), size: 10, trackingEm: 0.14)
                        Text(room.headline)
                            .textStyle(.insight)
                            .foregroundStyle(Color.ink)
                        Text(room.detail)
                            .textStyle(.caption)
                            .lineSpacing(2)
                            .foregroundStyle(Color.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        ArrowLink(title: room.linkTitle) { onLink(room) }
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 16)
                    .overlay(alignment: .top) {
                        if room.number > 1 { Rectangle().fill(Color.line).frame(height: 1) }
                    }
                }
            }
            .padding(.horizontal, Spacing.headingInset)
            .padding(.top, 4)
        }
    }
}

/// "Book an Atelier tour" promo.
struct TourPromoCard: View {
    var onBook: () -> Void = {}

    private let points = [
        "45 minutes, one-to-one with a specialist",
        "Taste the full range, dialled to your palate",
        "Free, and yours to book whenever suits",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Book an Atelier tour")
            Text("A guided hour with the machine that learns you.")
                .textStyle(.bannerTitle)
                .foregroundStyle(Color.burgundy)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.terracotta)
                        Text(point)
                            .textStyle(.caption)
                            .foregroundStyle(Color.ink)
                    }
                }
            }
            .padding(.top, 14)
            Button("Choose a showroom", action: onBook)
                .buttonStyle(.pill(.outline, height: 44, horizontalPadding: 18))
                .padding(.top, 18)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Color.amber.opacity(0.18))
                .background(Color.paper, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        )
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.amberSoft, lineWidth: 1))
        .padding(.horizontal, Spacing.screenInset)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 28) {
            VisitReasonsRail(reasons: MockCafeService.reasons)
            CafeRoomsSection(rooms: MockCafeService.rooms)
            TourPromoCard()
        }
        .padding(.vertical)
    }
    .background(Color.paper)
}
