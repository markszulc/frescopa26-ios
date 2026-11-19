import SwiftUI

/// Account tab: profile and rewards, subscription, machine care, flavour history,
/// orders and settings.
struct AccountView: View {
    @Bindable var model: AccountViewModel

    @State private var editsSubscription = false
    @State private var choosesPause = false
    /// Care routine to open in the machine-care sheet.
    @State private var careTask: CareTaskRequest?
    var onOrderBeans: () -> Void = {}

    var body: some View {
        NavigationStack {
            Group {
                if model.isSignedOut {
                    SignedOutView { Task { await model.signBackIn() } }
                } else {
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
                        case .loaded(let overview):
                            content(overview)
                        }
                    }
                    .scrollIndicators(.hidden)
                    .refreshable { await model.load() }
                }
            }
            .background(Color.paper)
            .task { if model.overview == nil { await model.load() } }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AccountRoute.self) { route in
                switch route {
                case .settings(let title):
                    ComingSoonView(title: title, icon: .account)
                        .toolbar(.visible, for: .navigationBar)
                }
            }
        }
        .tint(Color.burgundy)
        .sheet(isPresented: $editsSubscription) {
            if let subscription = model.overview?.subscription {
                SubscriptionEditor(subscription: subscription) { cadence, bags in
                    Task { await model.update(cadence: cadence, bags: bags) }
                }
            }
        }
        .sheet(item: $careTask) { request in
            MachineCareView(machine: model.machine, startWith: request.taskID, onOrderBeans: onOrderBeans)
        }
        .confirmationDialog("Pause deliveries for…", isPresented: $choosesPause, titleVisibility: .visible) {
            ForEach([2, 4, 8], id: \.self) { weeks in
                Button("\(weeks) weeks") { Task { await model.pause(weeks: weeks) } }
            }
        } message: {
            Text("Your subscription picks up automatically afterwards.")
        }
    }

    @ViewBuilder
    private func content(_ overview: AccountOverview) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ProfileHeader(profile: overview.profile, memberSince: model.memberSinceLine)
                .reveal()

            MembershipCard(membership: overview.membership, cupsBrewed: model.cupsBrewed)
                .padding(.top, 18)
                .reveal(delay: 0.06)

            SubscriptionCard(
                subscription: overview.subscription,
                nextDeliveryLine: model.nextDeliveryLine,
                busyAction: model.busyAction,
                onSkip: { Task { await model.skipNext() } },
                onChange: { editsSubscription = true },
                onPause: { choosesPause = true },
                onResume: { Task { await model.resume() } }
            )
            .padding(.top, 28)
            .reveal(delay: 0.12)

            MachineCareSection(machine: model.liveMachine(overview.machine)) { task in
                careTask = CareTaskRequest(taskID: task.id)
            }
                .padding(.top, 28)

            TasteHistoryChart(weeks: overview.tasteHistory)
                .padding(.top, 28)

            RecentOrdersSection(orders: overview.orders, relativeDate: model.relativeDate(_:))
                .padding(.top, 28)

            AccountSettingsSection(
                notifications: Binding(
                    get: { model.overview?.notifications ?? overview.notifications },
                    set: { new in Task { await model.setNotifications(new) } }
                ),
                onSignOut: { Task { await model.signOut() } }
            )
            .padding(.top, 28)
            .padding(.bottom, Spacing.md)
        }
    }

}

private struct SignedOutView: View {
    var onSignIn: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            BrandIconView(icon: .bean, size: 44)
                .foregroundStyle(Color.burgundy)
            Text("You're signed out.")
                .textStyle(.sectionTitle)
                .foregroundStyle(Color.burgundy)
            Text("Sign in to manage your subscription, rewards and machine.")
                .textStyle(.bodySmall)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
            Button("Sign in", action: onSignIn)
                .buttonStyle(DarkPrimaryPill())
                .padding(.top, 8)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AccountView(model: AccountViewModel(service: MockAccountService(),
                                        machine: MachineController(service: MockBrewService())))
}

private struct CareTaskRequest: Identifiable {
    let id = UUID()
    let taskID: CareTask.ID
}
