import SwiftUI

/// "This week at the table" — long-table classes with seat saving.
struct WhatsOnSection: View {
    let events: [CafeEvent]
    let dayLabel: (CafeEvent) -> String
    let isSaved: (CafeEvent) -> Bool
    let inFlight: CafeEvent.ID?
    var onToggleSeat: (CafeEvent) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow("What's on")
                Text("This week at the table")
                    .textStyle(.sectionTitle)
                    .foregroundStyle(Color.burgundy)
                    .accessibilityAddTraits(.isHeader)
                Text("Free with a drink unless noted")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
            }
            .padding(.horizontal, Spacing.headingInset)

            VStack(spacing: 0) {
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    if index > 0 { Rectangle().fill(Color.line).frame(height: 1) }
                    EventRow(
                        event: event,
                        dayLabel: dayLabel(event),
                        isSaved: isSaved(event),
                        isWorking: inFlight == event.id,
                        onToggleSeat: { onToggleSeat(event) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
            .padding(.horizontal, Spacing.screenInset)
            .padding(.top, 14)
        }
    }
}

struct EventRow: View {
    let event: CafeEvent
    let dayLabel: String
    let isSaved: Bool
    let isWorking: Bool
    var onToggleSeat: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(dayLabel, size: 10, trackingEm: 0.14)
                Text(event.title)
                    .textStyle(.productTitle)
                    .foregroundStyle(Color.ink)
                Text(event.detail)
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Label(event.timeLabel, systemImage: "clock")
                        .labelStyle(CompactLabelStyle())
                    Text("·").foregroundStyle(Color.inkSoft)
                    Text(priceLabel)
                        .foregroundStyle(event.price == nil ? Color.inkSoft : Color.terracottaDeep)
                }
                .font(BrandFont.body(12, weight: .medium, relativeTo: .caption))
                .foregroundStyle(Color.inkSoft)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            seatButton
        }
        .padding(.vertical, 14)
    }

    private var priceLabel: String {
        guard let price = event.price else { return "Free" }
        return price.formatted(.currency(code: "USD").presentation(.narrow).precision(.fractionLength(0)))
    }

    @ViewBuilder
    private var seatButton: some View {
        if event.requiresBooking {
            Button(action: onToggleSeat) {
                ZStack {
                    Label(isSaved ? "Saved" : "Save a seat", systemImage: isSaved ? "checkmark" : "plus")
                        .labelStyle(CompactLabelStyle())
                        .opacity(isWorking ? 0 : 1)
                    if isWorking { ProgressView().controlSize(.mini).tint(Color.burgundy) }
                }
            }
            .buttonStyle(.pill(.outline, height: 34, horizontalPadding: 12))
            .disabled(isWorking)
            .sensoryFeedback(.success, trigger: isSaved) { _, new in new }
            .accessibilityLabel(isSaved ? "Seat saved for \(event.title). Double-tap to cancel." : "Save a seat for \(event.title)")
        } else {
            TagLabel(text: "Drop in")
                .padding(.top, 6)
        }
    }
}

/// Icon + title with a tight gap, sized to the surrounding font.
struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.imageScale(.small)
            configuration.title
        }
    }
}

#Preview {
    let events = MockCafeService.directory.events
    return WhatsOnSection(events: events, dayLabel: { $0.weekdayName }, isSaved: { $0.id == "latte-art-lab" }, inFlight: nil)
        .padding(.vertical)
        .background(Color.paper)
}
