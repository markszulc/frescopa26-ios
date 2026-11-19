import SwiftUI

/// Section 4 — swappable merchandising slot (343 × 168 banner) with page dots.
struct OfferBannerCarousel: View {
    let offers: [Offer]
    var bannerHeight: CGFloat = 168
    var onSelect: (Offer) -> Void = { _ in }

    @State private var currentID: Offer.ID?

    private var currentIndex: Int {
        offers.firstIndex { $0.id == currentID } ?? 0
    }

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(offers) { offer in
                        Button { onSelect(offer) } label: {
                            OfferBanner(offer: offer, height: bannerHeight)
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.985))
                        .padding(.horizontal, Spacing.screenInset)
                        .containerRelativeFrame(.horizontal)
                        .id(offer.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $currentID)
            // Room for the banner's shadow so it isn't clipped by the scroll view.
            .scrollClipDisabled()
            .frame(height: bannerHeight)

            if offers.count > 1 {
                PageDots(count: offers.count, current: currentIndex)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Offers")
    }
}

struct OfferBanner: View {
    let offer: Offer
    var height: CGFloat = 168

    var body: some View {
        ZStack(alignment: .leading) {
            artwork
            // Left-weighted scrim keeps copy legible over photography (95deg in the design).
            LinearGradient(
                stops: [
                    .init(color: Color.scrim.opacity(0.88), location: 0),
                    .init(color: Color.scrim.opacity(0.60), location: 0.52),
                    .init(color: Color.scrim.opacity(0.10), location: 1),
                ],
                startPoint: UnitPoint(x: 0, y: 0.46),
                endPoint: UnitPoint(x: 1, y: 0.54)
            )
            copy
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .elevation(.md)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isLink)
    }

    @ViewBuilder
    private var artwork: some View {
        switch offer.artwork {
        case let .image(name, focusY):
            FocalImage(name: name, focusY: focusY)
                .accessibilityHidden(true)
        case .gradient:
            ZStack {
                LinearGradient(colors: [.burgundy, .burgundyDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Color.amber.opacity(0.55), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 260)
                CoffeeBeanShape()
                    .stroke(Color.amberSoft.opacity(0.35), lineWidth: 1.2)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(x: 30, y: 28)
            }
            .accessibilityHidden(true)
        }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(offer.badge.uppercased())
                .font(BrandFont.body(10, weight: .bold, relativeTo: .caption2))
                .tracking(1.4)
                .foregroundStyle(Color.charcoal)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.amber))

            Spacer(minLength: 8)

            Text(offer.title)
                .textStyle(.bannerTitle)
                .foregroundStyle(Color.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)

            (Text(offer.detail + " ")
                .foregroundStyle(Color.cream.opacity(0.9))
             + Text(offer.callToAction + " →")
                .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
                .foregroundStyle(Color.amber))
                .textStyle(.caption)
                .padding(.top, 6)
                .lineLimit(2)
        }
        .padding(18)
        .frame(maxWidth: 250, maxHeight: .infinity, alignment: .leading)
    }
}

/// Aspect-fill image cropped around a vertical focal point (CSS `object-position: center <y>%`).
struct FocalImage: View {
    let name: String
    /// 0 = top edge, 1 = bottom edge.
    var focusY: Double = 0.5

    var body: some View {
        GeometryReader { proxy in
            let box = proxy.size
            let source = UIImage(named: name)?.size ?? box
            let scale = max(box.width / max(source.width, 1), box.height / max(source.height, 1))
            let rendered = CGSize(width: source.width * scale, height: source.height * scale)
            Image(name)
                .resizable()
                .frame(width: rendered.width, height: rendered.height)
                .offset(x: (box.width - rendered.width) / 2,
                        y: (box.height - rendered.height) * focusY)
        }
        .clipped()
    }
}

/// Pill page indicator: the current page stretches to 18pt in burgundy.
struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.burgundy : Color.sand)
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .animation(Motion.quint, value: current)
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

#Preview {
    OfferBannerCarousel(offers: MockHomeService.sample().offers)
        .padding(.vertical)
        .background(Color.paper)
}
