import SwiftUI

/// App home: composes the section components in the order set by the design.
struct HomeView: View {
    @State private var model: HomeViewModel
    var onNavigate: (HomeRoute) -> Void = { _ in }

    init(model: HomeViewModel, onNavigate: @escaping (HomeRoute) -> Void = { _ in }) {
        _model = State(initialValue: model)
        self.onNavigate = onNavigate
    }

    var body: some View {
        ScrollView {
            switch model.state {
            case .loading:
                HomeLoadingView()
            case .failed(let message):
                HomeErrorView(message: message) { Task { await model.load() } }
            case .loaded(let content):
                sections(content)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.paper)
        .refreshable { await model.load() }
        .task { if model.content == nil { await model.load() } }
    }

    @ViewBuilder
    private func sections(_ content: HomeContent) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            GreetingHeader(
                dateLine: model.dateLine,
                greeting: model.greeting,
                unreadCount: content.user.unreadNotifications,
                onNotifications: { onNavigate(.notifications) }
            )
            .reveal()

            AtelierMachineCard(
                machine: { var machine = content.machine; machine.levels = model.levels; return machine }(),
                status: model.machineStatus,
                recommendation: content.recommendation,
                brewTitle: model.brewButtonTitle,
                isBrewing: model.brewState == .brewing,
                onBrew: { Task { await model.brew() } },
                onAdjust: { onNavigate(.adjustBrew) }
            )
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 16)
            .reveal(delay: 0.06)

            QuickActionsRow { onNavigate(.quickAction($0)) }
                .padding(.top, 18)
                .reveal(delay: 0.12)

            SupplyNudgeCard(
                headline: model.supplyHeadline,
                detail: model.supplyDetail,
                actionTitle: model.supplyActionTitle,
                isComplete: content.supply.isExpedited,
                isWorking: model.isExpediting,
                onAction: { Task { await model.expediteDelivery() } }
            )
            .padding(.top, 22)
            .reveal(delay: 0.18)

            if model.showsOfferSlot, !content.offers.isEmpty {
                OfferBannerCarousel(offers: content.offers) { onNavigate(.offer($0)) }
                    .padding(.top, 22)
                    .reveal(delay: 0.24)
            }

            TastePicksRail(
                title: "Picked for your taste",
                picks: content.picks,
                onSeeAll: { onNavigate(.allPicks) },
                onSelect: { onNavigate(.product($0)) },
                onAdd: { onNavigate(.addToBag($0)) }
            )
            .padding(.top, 26)
            .reveal(delay: 0.3)

            FlavourDNACard(taste: content.taste)
                .padding(.top, 24)
                .padding(.bottom, Spacing.md)
                .reveal(delay: 0.36)
        }
    }
}

/// Navigation intents raised by the home screen. The coordinator decides where they go.
enum HomeRoute: Hashable {
    case notifications
    case adjustBrew
    case quickAction(QuickAction.Destination)
    case offer(Offer)
    case allPicks
    case product(ProductPick)
    case addToBag(ProductPick)
}

extension Offer: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension ProductPick: Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Loading & error states

private struct HomeLoadingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GreetingHeader(dateLine: "Thursday 19 November", greeting: "Good morning, Mark.", unreadCount: 0)
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .fill(Color.charcoal)
                .frame(height: 300)
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, 16)
            QuickActionsRow().padding(.top, 18)
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Color.paper2)
                .frame(height: 76)
                .padding(.horizontal, Spacing.screenInset)
                .padding(.top, 22)
        }
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
        .accessibilityLabel("Loading your Atelier")
    }
}

private struct HomeErrorView: View {
    let message: String
    var retry: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            BrandIconView(icon: .brewCup, size: 40, weight: .light)
                .foregroundStyle(Color.burgundy)
            Text(message)
                .textStyle(.bodySmall)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
            Button("Try again", action: retry)
                .buttonStyle(.pill(.outline, height: 40))
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }
}

#Preview {
    HomeView(model: HomeViewModel(service: MockHomeService(), machine: MachineController(service: MockBrewService())))
}
