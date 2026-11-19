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
    @State private var shopModel: ShopViewModel
    @State private var location = LocationProvider()
    @State private var pendingRoute: HomeRoute?
    @State private var showsCare = false

    init(services: AppServices) {
        self.services = services
        // One machine shared by every tab, so a brew started anywhere shows everywhere.
        let machine = MachineController(service: services.brew)
        _homeModel = State(initialValue: HomeViewModel(service: services.home, machine: machine))
        _cafesModel = State(initialValue: CafesViewModel(service: services.cafes))
        _brewModel = State(initialValue: BrewViewModel(service: services.brew, machine: machine))
        _accountModel = State(initialValue: AccountViewModel(service: services.account, machine: machine))
        _shopModel = State(initialValue: ShopViewModel(service: services.shop, bag: BagStore()))
    }

    var body: some View {
        ZStack {
            switch selection {
            case .home:
                HomeView(model: homeModel) { route in handle(route) }
            case .brew:
                BrewView(model: brewModel)
            case .shop:
                ShopView(model: shopModel)
            case .cafes:
                CafesView(model: cafesModel, location: location)
            case .account:
                AccountView(model: accountModel) { selection = .shop }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if let message = accountModel.toast, selection == .account {
                    ToastView(message: message)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                BrandTabBar(selection: $selection, badges: [.shop: shopModel.bag.itemCount])
            }
            .animation(Motion.quint, value: accountModel.toast)
        }
        // Keep the tab bar anchored to the bottom like a system tab bar when the keyboard shows.
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(alignment: .top) { StatusBarScrim() }
        .background(Color.paper)
        .tint(Color.terracotta)
        .sheet(isPresented: $showsCare) {
            MachineCareView(machine: homeModel.machine) { selection = .shop }
        }
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
        case .quickAction(.reorder), .allPicks: selection = .shop
        case .quickAction(.care): showsCare = true
        case .adjustBrew:
            selection = .brew
            brewModel.requestUsualCustomizer()
        default: pendingRoute = route
        }
    }
}

/// Paper-tinted blur behind the system status bar (the design's 54pt status strip).
/// Soft edge behind the system status bar: solid enough under the clock to stay legible,
/// then blur and paper tint ease out so scrolling content dissolves instead of being cut off.
private struct StatusBarScrim: View {
    /// How far below the status bar the fade extends.
    var fade: CGFloat = 32

    var body: some View {
        GeometryReader { proxy in
            let top = proxy.safeAreaInsets.top
            let height = top + fade
            // Fully opaque through ~80% of the status bar, transparent at the bottom of the fade.
            let solidUntil = (top * 0.8) / max(height, 1)

            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(
                    stops: [
                        .init(color: Color.paper.opacity(0.94), location: 0),
                        .init(color: Color.paper.opacity(0.85), location: solidUntil),
                        .init(color: Color.paper.opacity(0.0), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .frame(height: height)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: solidUntil),
                        .init(color: .black.opacity(0.6), location: solidUntil + (1 - solidUntil) * 0.45),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            }
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
