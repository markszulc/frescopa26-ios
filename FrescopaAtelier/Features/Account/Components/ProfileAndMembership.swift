import SwiftUI

/// Avatar, name and email at the top of the Account tab.
struct ProfileHeader: View {
    let profile: AccountProfile
    let memberSince: String

    var body: some View {
        HStack(spacing: 14) {
            Text(profile.initials)
                .font(BrandFont.display(22, relativeTo: .title2))
                .foregroundStyle(Color.cream)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color.burgundy))
                .overlay(Circle().strokeBorder(Color.amber, lineWidth: 2).padding(-3))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Eyebrow(memberSince)
                Text(profile.fullName)
                    .textStyle(.greetingTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
                Text("\(profile.email) · \(profile.city)")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.headingInset)
        .padding(.top, 14)
    }
}

/// Dark rewards card: tier, beans earned, progress to the next reward, and cups brewed.
struct MembershipCard: View {
    let membership: Membership
    let cupsBrewed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(membership.tier.uppercased())
                    .font(BrandFont.body(10, weight: .bold, relativeTo: .caption2))
                    .tracking(1.4)
                    .foregroundStyle(Color.charcoal)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.amber))
                Spacer()
                Label("\(cupsBrewed) cups brewed", systemImage: "cup.and.saucer")
                    .labelStyle(CompactLabelStyle())
                    .font(BrandFont.body(12, weight: .medium, relativeTo: .caption))
                    .foregroundStyle(Color.creamSoft)
                    .contentTransition(.numericText())
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(membership.points)")
                    .font(BrandFont.display(40, relativeTo: .largeTitle))
                    .tracking(-0.8)
                    .foregroundStyle(Color.cream)
                    .contentTransition(.numericText())
                Text("reward beans")
                    .textStyle(.bodySmall)
                    .foregroundStyle(Color.creamSoft)
            }
            .padding(.top, 16)

            LevelBar(value: membership.progress, fill: .amber, track: .charcoal2, height: 6)
                .padding(.top, 10)
            Text("\(membership.pointsToGo) more for \(membership.nextRewardTitle).")
                .textStyle(.caption)
                .foregroundStyle(Color.creamSoft)
                .padding(.top, 8)
        }
        .padding(20)
        .background {
            ZStack {
                Color.charcoal
                RadialGradient(colors: [Color.amber.opacity(0.22), .clear], center: .topTrailing, startRadius: 0, endRadius: 300)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, Spacing.screenInset)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let overview = MockAccountService.sample(now: .now)
    return VStack(spacing: 20) {
        ProfileHeader(profile: overview.profile, memberSince: "Member since September 2025")
        MembershipCard(membership: overview.membership, cupsBrewed: 412)
    }
    .background(Color.paper)
}
