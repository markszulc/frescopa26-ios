import SwiftUI

@main
struct FrescopaAtelierApp: App {
    private let services: AppServices = .mock

    init() {
        BrandFont.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            RootView(services: services)
                .preferredColorScheme(.light)
        }
    }
}

/// Dependency container. Replace `.mock` with live implementations as the backend comes online.
struct AppServices: Sendable {
    var home: HomeService
    var cafes: CafeService
    var brew: BrewService
    var account: AccountService
    var shop: ShopService

    /// Mock data except the live Fréscopa Commerce catalog (Shop) and AEM recipes (Brew).
    static let mock = AppServices(home: MockHomeService(), cafes: MockCafeService(),
                                  brew: AEMRecipesBrewService(base: MockBrewService()), account: MockAccountService(),
                                  shop: CommerceShopService())
}
