import SwiftUI

/// Top of the Cafés tab — "Come taste the whole of Fréscopa."
struct CafesHero: View {
    var imageName = "cafe-hero"
    var fallbackImageName = "offer-single-origin"
    var onFindNearest: () -> Void = {}
    var onBookTour: () -> Void = {}

    private var resolvedImage: String {
        UIImage(named: imageName) != nil ? imageName : fallbackImageName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("The café & showroom", color: .amber)
            Text("Come taste the whole of Fréscopa.")
                .textStyle(.cardTitle)
                .foregroundStyle(Color.cream)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
            Text("Part coffee bar, part showroom, part gathering place. Sit with a cup, get hands-on with the machines, and stay for a class — no purchase, no pressure.")
                .textStyle(.bodySmall)
                .lineSpacing(3)
                .foregroundStyle(Color.cream.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            HStack(spacing: 10) {
                Button("Find your nearest café", action: onFindNearest)
                    .buttonStyle(.pill(.primary, fullWidth: true))
                Button("Book a tour", action: onBookTour)
                    .buttonStyle(.pill(.ghostOnDark))
            }
            .padding(.top, 20)
        }
        .padding(20)
        .padding(.top, 90)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                FocalImage(name: resolvedImage, focusY: 0.35)
                LinearGradient(
                    stops: [
                        .init(color: Color.scrim.opacity(0.15), location: 0),
                        .init(color: Color.scrim.opacity(0.70), location: 0.45),
                        .init(color: Color.scrim.opacity(0.94), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, Spacing.screenInset)
    }
}

#Preview {
    CafesHero().padding(.vertical).background(Color.paper)
}
