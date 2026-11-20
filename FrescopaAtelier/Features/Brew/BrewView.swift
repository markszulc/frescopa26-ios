import SwiftUI

/// Brew tab: the machine's control centre — today's usual, the menu, saved
/// recipes and recent cups.
struct BrewView: View {
    @Bindable var model: BrewViewModel

    var body: some View {
        ScrollView {
            switch model.state {
            case .loading:
                ProgressView()
                    .tint(Color.burgundy)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 220)
            case .failed(let message):
                Text(message)
                    .textStyle(.bodySmall)
                    .foregroundStyle(Color.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 220)
            case .loaded(let menu):
                content(menu)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.paper)
        .refreshable { await model.load() }
        .task { if model.menu == nil { await model.load() } }
        .sheet(item: $model.customizing) { draft in
            DrinkCustomizerView(
                model: draft,
                isMachineBusy: model.machine.isBrewing,
                onBrew: { order in Task { await model.brew(order) } },
                onSave: { name in Task { await model.saveRecipe(named: name, from: draft) } }
            )
        }
        .fullScreenCover(isPresented: $model.showsProgress) {
            BrewProgressView(
                machine: model.machine,
                summary: (model.machine.currentOrder ?? model.machine.lastCompleted).map(model.summary(for:)) ?? "",
                rating: model.lastEntryID.flatMap(model.rating(for:)),
                onCancel: model.cancelBrew,
                onRate: { value in
                    if let id = model.lastEntryID { Task { await model.rate(id, value) } }
                },
                onDone: model.dismissProgress
            )
        }
    }

    @ViewBuilder
    private func content(_ menu: BrewMenu) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            BrewHeader(machineName: "The Atelier", status: model.machine.status, levels: model.machine.levels)
                .reveal()

            if let usual = model.usualOrder {
                UsualBrewCard(
                    title: menu.usual.name,
                    reason: menu.usualReason,
                    summary: model.summary(for: usual),
                    isBrewing: model.machine.isBrewing,
                    progress: model.showsProgress ? nil : model.machine.progress,
                    onBrew: { Task { await model.brew(usual) } },
                    onAdjust: { model.customizeUsual() }
                )
                .padding(.top, 18)
                .reveal(delay: 0.06)
            }

            SavedRecipesRail(
                recipes: menu.recipes,
                isUnavailable: menu.recipesUnavailable,
                drinkName: { menu.drink($0.drinkID)?.name ?? "" },
                summary: { recipe in model.order(for: recipe).map(model.summary(for:)) ?? "" },
                isBrewing: model.machine.isBrewing,
                onBrew: { recipe in
                    if let order = model.order(for: recipe) { Task { await model.brew(order) } }
                },
                onEdit: { recipe in
                    if let order = model.order(for: recipe) { model.customize(order) }
                }
            )
            .padding(.top, 28)
            .reveal(delay: 0.12)

            DrinkMenuSection(drinks: model.drinks, category: $model.category) { model.customize($0) }
                .padding(.top, 28)

            RecentBrewsList(
                history: menu.history,
                relativeTime: model.relativeTime(_:),
                onRate: { entry, value in Task { await model.rate(entry.id, value) } }
            )
            .padding(.top, 30)
            .padding(.bottom, Spacing.md)
        }
    }
}

#Preview {
    let machine = MachineController(service: MockBrewService())
    return BrewView(model: BrewViewModel(service: MockBrewService(), machine: machine))
}
