import SwiftUI

/// "Your recipes" — horizontal rail of saved settings with a one-tap brew.
struct SavedRecipesRail: View {
    let recipes: [BrewRecipe]
    var isUnavailable = false
    let drinkName: (BrewRecipe) -> String
    let summary: (BrewRecipe) -> String
    let isBrewing: Bool
    var onBrew: (BrewRecipe) -> Void = { _ in }
    var onEdit: (BrewRecipe) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Your recipes")

            if recipes.isEmpty {
                Text(isUnavailable
                     ? "Fréscopa's recipes couldn't load. Pull down to try again."
                     : "Adjust any drink and save it here for next time.")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .padding(.horizontal, Spacing.headingInset)
                    .padding(.top, 10)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(recipes) { recipe in
                            RecipeCard(recipe: recipe, drinkName: drinkName(recipe), summary: summary(recipe),
                                       isBrewing: isBrewing,
                                       onBrew: { onBrew(recipe) }, onEdit: { onEdit(recipe) })
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, Spacing.screenInset)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollClipDisabled()
            }
        }
    }
}

struct RecipeCard: View {
    let recipe: BrewRecipe
    let drinkName: String
    let summary: String
    let isBrewing: Bool
    var onBrew: () -> Void = {}
    var onEdit: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(drinkName, size: 10, trackingEm: 0.12)
            Text(recipe.name)
                .textStyle(.productTitle)
                .foregroundStyle(Color.ink)
                .lineLimit(2, reservesSpace: true)
                .padding(.top, 5)
            Text(recipe.description ?? summary)
                .textStyle(.caption)
                .foregroundStyle(Color.inkSoft)
                .lineLimit(3, reservesSpace: true)
                .padding(.top, 4)
            if recipe.description != nil {
                Text(summary)
                    .font(BrandFont.body(11, weight: .medium, relativeTo: .caption2))
                    .foregroundStyle(Color.terracottaDeep)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.top, 8)
            }
            HStack {
                Button("Edit", action: onEdit)
                    .font(BrandFont.body(13, weight: .medium, relativeTo: .footnote))
                    .foregroundStyle(Color.terracottaDeep)
                    .buttonStyle(.pressable)
                Spacer()
                Button(action: onBrew) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.cream)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.burgundy))
                        .padding(6).contentShape(Circle()).padding(-6)
                }
                .buttonStyle(.pressable)
                .disabled(isBrewing)
                .opacity(isBrewing ? 0.5 : 1)
                .accessibilityLabel("Brew \(recipe.name)")
            }
            .padding(.top, 12)
        }
        .padding(14)
        .frame(width: 210, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
    }
}

/// "Recent brews" with a five-bean rating per cup.
struct RecentBrewsList: View {
    let history: [BrewHistoryEntry]
    let relativeTime: (Date) -> String
    var onRate: (BrewHistoryEntry, Int) -> Void = { _, _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Recent brews")
            VStack(spacing: 0) {
                ForEach(history.prefix(5)) { entry in
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.drinkName)
                                .textStyle(.bodyStrong)
                                .foregroundStyle(Color.ink)
                            Text("\(entry.detail) · \(relativeTime(entry.date))")
                                .textStyle(.caption)
                                .foregroundStyle(Color.inkSoft)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        BeanRating(rating: entry.rating, size: 16) { onRate(entry, $0) }
                    }
                    .padding(.vertical, 12)
                    if entry.id != history.prefix(5).last?.id {
                        Rectangle().fill(Color.line).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, Spacing.headingInset)
            .padding(.top, 6)
        }
    }
}

/// Five coffee beans; tap to rate. Unrated shows hollow beans.
struct BeanRating: View {
    let rating: Int?
    var size: CGFloat = 16
    var onRate: (Int) -> Void = { _ in }

    @Environment(\.colorScheme) private var colorScheme
    private var emptyColor: Color { colorScheme == .dark ? .creamSoft : .sand }

    var body: some View {
        HStack(spacing: size * 0.25) {
            ForEach(1...5, id: \.self) { value in
                Button { onRate(value) } label: {
                    Group {
                        if value <= (rating ?? 0) {
                            FilledBean(size: size).foregroundStyle(Color.terracotta)
                        } else {
                            BrandIconView(icon: .bean, size: size).foregroundStyle(emptyColor)
                        }
                    }
                    .padding(2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle(scale: 0.85))
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
        .accessibilityElement()
        .accessibilityLabel("Rating")
        .accessibilityValue(rating.map { "\($0) of 5" } ?? "Not rated")
        .accessibilityAdjustableAction { direction in
            let current = rating ?? 0
            switch direction {
            case .increment: onRate(min(current + 1, 5))
            case .decrement: onRate(max(current - 1, 1))
            @unknown default: break
            }
        }
    }
}

#Preview {
    let menu = MockBrewService.menu(now: .now)
    return ScrollView {
        VStack(spacing: 28) {
            SavedRecipesRail(recipes: menu.recipes, drinkName: { menu.drink($0.drinkID)?.name ?? "" },
                             summary: { _ in "House blend · 18 g · 93°" }, isBrewing: false)
            RecentBrewsList(history: menu.history, relativeTime: { _ in "2 hours ago" })
        }
        .padding(.vertical)
    }
    .background(Color.paper)
}
