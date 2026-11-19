import SwiftUI

/// Sheet for tuning a drink before brewing: bean, size, strength, temperature,
/// milk and foam, with a live taste prediction.
struct DrinkCustomizerView: View {
    @Bindable var model: DrinkCustomizerModel
    let isMachineBusy: Bool
    var onBrew: (BrewOrder) -> Void = { _ in }
    var onSave: (String) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var showsSavePrompt = false
    @State private var recipeName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    TastePreviewCard(taste: model.taste)
                        .padding(.top, 18)

                    control("Beans") {
                        VStack(spacing: 8) {
                            ForEach(model.availableBeans) { bean in
                                BeanOption(bean: bean, isSelected: model.settings.beanID == bean.id) {
                                    model.settings.beanID = bean.id
                                }
                            }
                        }
                    }

                    control("Size", value: model.volumeLabel) {
                        Picker("Size", selection: $model.settings.size) {
                            ForEach(CupSize.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }

                    if !model.drink.isTea {
                        control("Strength", value: "\(model.strengthLabel) · \(Int(model.settings.doseGrams.rounded())) g") {
                            BrandSlider(value: $model.settings.doseGrams, range: BrewSettings.doseRange, step: 0.5,
                                        minLabel: "Gentle", maxLabel: "Bold")
                        }
                    }

                    control(model.drink.isTea ? "Water temperature" : "Brew temperature",
                            value: "\(Int(model.settings.temperatureC.rounded()))°C") {
                        BrandSlider(value: $model.settings.temperatureC, range: model.temperatureRange, step: 1,
                                    minLabel: "Cooler", maxLabel: "Hotter")
                    }

                    if model.drink.usesMilk || model.drink.id == "iced-latte" {
                        control("Milk") {
                            HStack(spacing: 8) {
                                ForEach(MilkKind.allCases) { milk in
                                    FilterChip(title: milk.title, isSelected: model.settings.milk == milk, expands: true) {
                                        model.settings.milk = milk
                                    }
                                }
                            }
                        }
                        if !model.drink.isCold {
                            control("Milk temperature", value: "\(Int(model.settings.milkTemperatureC.rounded()))°C") {
                                BrandSlider(value: $model.settings.milkTemperatureC, range: BrewSettings.milkTemperatureRange,
                                            step: 1, minLabel: "Warm", maxLabel: "Hot")
                            }
                            control("Texture") {
                                HStack(spacing: 8) {
                                    ForEach(FoamLevel.allCases) { foam in
                                        FilterChip(title: foam.title, isSelected: model.settings.foam == foam, expands: true) {
                                            model.settings.foam = foam
                                        }
                                    }
                                }
                            }
                        }
                    }

                    actions.padding(.top, 28)
                }
                .padding(.horizontal, Spacing.headingInset)
                .padding(.bottom, Spacing.lg)
            }
            .scrollIndicators(.hidden)
            .background(Color.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.burgundy)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") { withAnimation(Motion.quint) { model.reset() } }
                        .foregroundStyle(Color.terracottaDeep)
                        .disabled(!model.isModified)
                }
            }
            .alert("Save as a recipe", isPresented: $showsSavePrompt) {
                TextField("Recipe name", text: $recipeName)
                Button("Save") { onSave(recipeName); recipeName = "" }
                Button("Cancel", role: .cancel) { recipeName = "" }
            } message: {
                Text("It'll appear under Your recipes for one-tap brewing.")
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.xl)
        .presentationBackground(Color.paper)
        .sensoryFeedback(.selection, trigger: model.settings)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(model.recipeName ?? model.drink.category.title)
            Text(model.drink.name)
                .textStyle(.greetingTitle)
                .foregroundStyle(Color.burgundy)
                .accessibilityAddTraits(.isHeader)
            Text(model.drink.summary)
                .textStyle(.bodySmall)
                .foregroundStyle(Color.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                onBrew(model.order)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 13, weight: .bold))
                    Text(isMachineBusy ? "The Atelier is busy" : "Brew \(model.volumeLabel)")
                }
            }
            .buttonStyle(DarkPrimaryPill())
            .disabled(isMachineBusy)

            Button("Save as a recipe") { showsSavePrompt = true }
                .buttonStyle(.pill(.outline, height: 44, fullWidth: true))
        }
    }

    private func control<Content: View>(_ title: String, value: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(title, color: .inkSoft, size: 10, trackingEm: 0.12)
                Spacer()
                if let value {
                    Text(value)
                        .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
                        .foregroundStyle(Color.ink)
                        .contentTransition(.numericText())
                        .animation(Motion.quint, value: value)
                }
            }
            content()
        }
        .padding(.top, 22)
    }
}

/// Selectable bean row with tasting notes.
struct BeanOption: View {
    let bean: Bean
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                BrandIconView(icon: .bean, size: 20)
                    .foregroundStyle(isSelected ? Color.cream : Color.burgundy)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(isSelected ? Color.burgundy : Color.amber.opacity(0.3)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(bean.name).textStyle(.bodyStrong).foregroundStyle(Color.ink)
                    Text(bean.notes).textStyle(.caption).foregroundStyle(Color.inkSoft)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.burgundy : Color.line)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(isSelected ? Color.paper2 : Color.paper))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(isSelected ? Color.burgundy.opacity(0.5) : Color.line, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99))
        .animation(Motion.quint, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Terracotta slider with end labels.
struct BrandSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var minLabel: String
    var maxLabel: String

    var body: some View {
        VStack(spacing: 4) {
            Slider(value: $value, in: range, step: step)
                .tint(Color.terracotta)
            HStack {
                Text(minLabel)
                Spacer()
                Text(maxLabel)
            }
            .font(BrandFont.body(11, relativeTo: .caption2))
            .foregroundStyle(Color.inkSoft)
            .accessibilityHidden(true)
        }
    }
}

/// "Predicted cup" — body / sweetness / acidity from the current settings.
struct TastePreviewCard: View {
    let taste: TastePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Predicted cup")
            ForEach([("Body", taste.body), ("Sweetness", taste.sweetness), ("Acidity", taste.acidity)], id: \.0) { label, value in
                HStack(spacing: 10) {
                    Text(label)
                        .textStyle(.caption)
                        .foregroundStyle(Color.inkSoft)
                        .frame(width: 72, alignment: .leading)
                    LevelBar(value: value, fill: .terracotta, track: .paper3, height: 6)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
    }
}

#Preview {
    let drink = MockBrewService.drinks.first { $0.id == "flat-white" }!
    return DrinkCustomizerView(model: DrinkCustomizerModel(drink: drink, settings: drink.defaults, beans: MockBrewService.beans),
                               isMachineBusy: false)
}
