import SwiftUI

/// App shell: the selected tab's content with the branded tab bar pinned to the bottom,
/// and a translucent strip behind the status bar so content scrolls under it softly.
struct RootView: View {
    let services: AppServices

    @State private var selection: AppTab = .home
    @State private var homeModel: HomeViewModel
    @State private var cafesModel: CafesViewModel
    @State private var brewModel: BrewViewModel
    @State private var accountModel: AccountViewModel
    @State private var location = LocationProvider()
    @State private var pendingRoute: HomeRoute?

    init(services: AppServices) {
        self.services = services
        // One machine shared by every tab, so a brew started anywhere shows everywhere.
        let machine = MachineController(service: services.brew)
        _homeModel = State(initialValue: HomeViewModel(service: services.home, machine: machine))
        _cafesModel = State(initialValue: CafesViewModel(service: services.cafes))
        _brewModel = State(initialValue: BrewViewModel(service: services.brew, machine: machine))
        _accountModel = State(initialValue: AccountViewModel(service: services.account, machine: machine))
    }

    var body: some View {
        ZStack {
            switch selection {
            case .home:
                HomeView(model: homeModel) { route in handle(route) }
            case .brew:
                BrewView(model: brewModel)
            case .cafes:
                CafesView(model: cafesModel, location: location)
            case .account:
                AccountView(model: accountModel)
            default:
                ComingSoonView(title: selection.title, icon: selection.icon)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if let message = accountModel.toast, selection == .account {
                    ToastView(message: message)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                BrandTabBar(selection: $selection)
            }
            .animation(Motion.quint, value: accountModel.toast)
        }
        .overlay(alignment: .top) { StatusBarScrim() }
        .background(Color.paper)
        .tint(Color.terracotta)
        .sheet(item: $pendingRoute) { route in
            ComingSoonView(title: route.title)
                .presentationDetents([.medium])
                .presentationCornerRadius(Radius.xl)
        }
    }

    private func handle(_ route: HomeRoute) {
        switch route {
        case .quickAction(.cafes): selection = .cafes
        case .quickAction(.brewMenu): selection = .brew
        case .adjustBrew:
            selection = .brew
            brewModel.requestUsualCustomizer()
        default: pendingRoute = route
        }
    }
}

/// Paper-tinted blur behind the system status bar (the design's 54pt status strip).
private struct StatusBarScrim: View {
    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.paper.opacity(0.85))
                .frame(height: proxy.safeAreaInsets.top)
                .ignoresSafeArea(edges: .top)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension HomeRoute: Identifiable {
    var id: Self { self }

    var title: String {
        switch self {
        case .notifications: "Notifications"
        case .adjustBrew: "Adjust your cup"
        case .quickAction(.reorder): "Reorder"
        case .quickAction(.care): "Machine care"
        case .quickAction: "Brew"
        case .offer(let offer): offer.title
        case .allPicks: "Picked for your taste"
        case .product(let pick): pick.title
        case .addToBag(let pick): "Added \(pick.title)"
        }
    }
}

#Preview {
    RootView(services: .mock)
}
