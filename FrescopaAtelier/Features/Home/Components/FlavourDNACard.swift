import SwiftUI

/// Section 6 — weekly flavour profile with attribute bars.
struct FlavourDNACard: View {
    let taste: TasteProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Your flavour DNA this week")
            Text(taste.headline)
                .textStyle(.insight)
                .lineSpacing(2)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            VStack(spacing: 9) {
                ForEach(taste.attributes) { attribute in
                    HStack(spacing: 10) {
                        Text(attribute.label)
                            .textStyle(.caption)
                            .foregroundStyle(Color.inkSoft)
                            .frame(width: 64, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        LevelBar(value: attribute.value, fill: .terracotta, track: .paper3, height: 6)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(attribute.label)
                    .accessibilityValue(Text(attribute.value, format: .percent.precision(.fractionLength(0))))
                }
            }
            .padding(.top, 14)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2)
        )
        .padding(.horizontal, Spacing.screenInset)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your taste this week")
    }
}

#Preview {
    FlavourDNACard(taste: MockHomeService.sample().taste)
        .padding(.vertical)
        .background(Color.paper)
}
