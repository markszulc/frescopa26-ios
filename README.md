# Fréscopa Atelier — iOS

SwiftUI app built from the Claude Design export *Frescopa Atelier customer journey – AppHome*.
iOS 18+, Swift 6 (strict concurrency), no third-party dependencies.

## Generate & run

```bash
xcodegen generate
open FrescopaAtelier.xcodeproj
```

`FrescopaAtelier.xcodeproj` is generated from `project.yml`. Edit the spec, not the project.

## Layout

| Path | What lives there |
|---|---|
| `App/` | App entry, `RootView` shell, `BrandTabBar`, `AppServices` DI container |
| `DesignSystem/` | Colour, type, spacing/radius/elevation/motion tokens + shared components (`Eyebrow`, pill buttons, `LevelBar`, `reveal()`, icons) |
| `Models/` | Plain value types for the home payload |
| `Services/` | `HomeService` protocol + `MockHomeService` (swap for a live client) |
| `Features/Home/` | `HomeView`, `HomeViewModel`, and one file per section in `Components/` |
| `Resources/` | Asset catalogue, brand fonts (Schibsted Grotesk, Hanken Grotesk; OFL) |

### Home sections → components

1. `GreetingHeader` (+ `NotificationBellButton`)
2. `AtelierMachineCard` (+ `MachineLevelsView`)
3. `QuickActionsRow` (+ `QuickActionTile`)
4. `SupplyNudgeCard`
5. `OfferBannerCarousel` (+ `OfferBanner`, `PageDots`)
6. `TastePicksRail` (+ `SectionHeader`, `ProductPickCard`, `ProductArtwork`)
7. `FlavourDNACard`

### Machine care (Home → Care, Account → Start descale)

- `MachineCareView` — health ring, supplies (water/beans/filter with actions), care schedule, tips
- `CareGuideView` + `CareGuideModel` — step-by-step descale, filter and milk-rinse routines; machine
  cycles are simulated and time-scaled. Completing one resets the reminder on `MachineController.care`,
  which Account's "Your machine" section also reads.

### Shop tab → live Adobe Commerce catalog

The Shop reads the real Fréscopa catalog from the same Adobe Commerce (Catalog Service) GraphQL
endpoint the frescopacoffee.com storefront uses, with the store headers from its public `/config.json`:

| Query | Used for |
|---|---|
| `categories { name urlPath }` | Category chips (direct children of `frescopa/`) |
| `productSearch(phrase, filter, sort, page_size, current_page)` | Grid, search, category filter, sort, infinite scroll |
| `products(skus:)` | Product page (description, attributes, finish options) and the featured Atelier |

- `GraphQLClient` — small typed GraphQL-over-HTTP client
- `CommerceShopService` — queries + DTOs for the `ProductView` union; `MockShopService` for previews/tests
- Images come from AEM asset delivery (`…/as/{sku}.jpg?width=`); products without imagery get branded placeholders
- Prices decode via their decimal string so cents are exact
- The bag (`BagStore`) is on-device for now. Commerce cart mutations (`createGuestCart`,
  `addProductsToCart`) would write to the live store, so checkout isn't wired yet.
- Run `LiveCommerceTests` with `LIVE_COMMERCE=1` in the test environment to hit the real endpoint.

Components: `ShopHeader` (+ search, `BagButton`), `FeaturedProductCard`, `CategorySortBar`, `ProductTile`,
`ProductImage`, `FinishSwatch`, `QuantityStepper`; screens `ShopView`, `ProductDetailView`, `BagView`.

### Brew tab → components

1. `BrewHeader` (+ `MachineStatusPill`) — live status and water/bean levels
2. `UsualBrewCard` — today's tuned usual with inline progress
3. `SavedRecipesRail` (+ `RecipeCard`) — one-tap brew or edit
4. `DrinkMenuSection` (+ `DrinkCard`) — 12 drinks with category filters
5. `RecentBrewsList` (+ `BeanRating`) — history with five-bean ratings
6. Screens: `BrewView`, `DrinkCustomizerView` (sheet, with `TastePreviewCard`), `BrewProgressView` (full screen)

`MachineController` is the single source of truth for the machine and is shared by Home and Brew:
a brew started on either tab shows on both, and water/bean levels drop with each cup. Machine I/O goes
through `BrewService.brew(_:)`, an `AsyncThrowingStream` of stage progress; cancelling stops the machine.

### Account tab → components

1. `ProfileHeader`, `MembershipCard` — rewards beans, progress to next reward, cups brewed (live from the machine)
2. `SubscriptionCard` + `SubscriptionEditor` (sheet) — skip, pause/resume, change cadence and bags
3. `MachineCareSection` (+ `CareTaskRow`) — descale, filter and milk-system status
4. `TasteHistoryChart` — eight weeks of flavour DNA (Swift Charts)
5. `RecentOrdersSection`, `AccountSettingsSection` — notification toggles, settings links, sign out
6. Confirmations use the shared `ToastView`, shown by `RootView` above the tab bar

#### Recipes from AEM

"Your recipes" comes from the AEM persisted query
`https://publish-p137825-e1511252.adobeaemcloud.com/graphql/execute.json/frescopa/RecipeList`
(Recipe Content Fragments). `AEMRecipesBrewService` wraps the brew service and `RecipeMapper` maps each
fragment onto the menu: `drinkStyle` → existing drink (or a recipe-only drink such as the espresso
martini, kept out of the menu grid), `beanName` → bean, plus size, dose, temperatures and milk.
If the feed can't be reached the rail says so and the rest of the tab keeps working. Recipes saved in
the app stay on-device. Run `LiveAEMRecipeTests` with `LIVE_AEM=1` to hit the real endpoint.

### Cafés tab → components

Content and functions adapted from frescopacoffee.com/cafe.

1. `CafesHero` — "Come taste the whole of Fréscopa." with Find nearest / Book a tour
2. `WhatsOnSection` (+ `EventRow`) — this week at the table, with seat saving
3. Finder: `CafeStatsRow`, `FlagshipCafeCard`, `CafeFilterBar`, `CafeRow`, `CafesMapView` (+ `CafePin`)
4. `VisitReasonsRail`, `CafeRoomsSection`, `TourPromoCard`
5. Screens: `CafesView`, `CafeDetailView`, `TourBookingView` (sheet)

Location is optional (`LocationProvider`, when-in-use, asked only on "Find your nearest café" or
"Use my location"); without it the list keeps its regional order. Open/closed status is computed in
each café's own time zone. Drop a photo named `cafe-hero` into the asset catalogue to replace the
hero's fallback image.

## Notes

- Colours are exact sRGB conversions of the design's OKLCH tokens.
- Product photography for the picks rail wasn't included in the export. Drop images named
  `pick-espresso-pour`, `pick-tea-moment`, `pick-citrus-juice` into `Assets.xcassets` and they
  replace the branded placeholders automatically.
