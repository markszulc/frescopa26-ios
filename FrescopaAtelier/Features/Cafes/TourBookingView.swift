import SwiftUI

/// "Book an Atelier tour" — a free 45-minute private tour at a showroom café.
struct TourBookingView: View {
    @State private var model: TourBookingModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field { case name, email, phone }

    init(model: TourBookingModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .confirmed(let confirmation) = model.phase {
                    TourConfirmationView(confirmation: confirmation) { dismiss() }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    form
                }
            }
            .animation(Motion.quint, value: model.phase)
            .background(Color.paper)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.burgundy)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationCornerRadius(Radius.xl)
        .presentationBackground(Color.paper)
        .alert("Couldn't send your request", isPresented: Binding(
            get: { if case .failed = model.phase { true } else { false } },
            set: { if !$0 { model.dismissError() } }
        )) {
            Button("OK", role: .cancel) { model.dismissError() }
        } message: {
            if case .failed(let message) = model.phase { Text(message) }
        }
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow("Book an Atelier tour")
                Text("A guided hour with the machine that learns you.")
                    .textStyle(.cardTitle)
                    .foregroundStyle(Color.burgundy)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
                Text("A specialist walks you through the Atelier line, dials a shot to your taste, and answers everything a spec sheet can't. No obligation to buy.")
                    .textStyle(.bodySmall)
                    .lineSpacing(3)
                    .foregroundStyle(Color.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                section("Café") {
                    Menu {
                        Picker("Showroom café", selection: $model.request.cafeID) {
                            ForEach(model.showrooms) { cafe in
                                Text(cafe.isFlagship ? "\(cafe.name) — Flagship" : "\(cafe.name) — \(cafe.cityLine)")
                                    .tag(cafe.id)
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.selectedCafe?.name ?? "Choose a showroom café")
                                    .textStyle(.bodyStrong)
                                    .foregroundStyle(Color.ink)
                                if let cafe = model.selectedCafe {
                                    Text(cafe.isFlagship ? "Flagship — \(cafe.cityLine)" : cafe.cityLine)
                                        .textStyle(.caption)
                                        .foregroundStyle(Color.inkSoft)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.inkSoft)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Color.paper2))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(Color.line, lineWidth: 1))
                    }
                }

                section("Date") {
                    DatePicker("Tour date", selection: $model.request.date,
                               in: model.earliestDate...model.latestDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Color.terracotta)
                        .padding(.horizontal, 6)
                        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
                }

                section("Time", error: model.slotError) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(TourRequest.slots, id: \.self) { slot in
                            FilterChip(title: OpeningHours.clock(slot).uppercased(), isSelected: model.request.slot == slot, expands: true) {
                                model.request.slot = slot
                            }
                        }
                    }
                    .sensoryFeedback(.selection, trigger: model.request.slot)
                }

                section("Guests") {
                    HStack(spacing: 8) {
                        ForEach(TourGuests.allCases) { guests in
                            FilterChip(title: guests.title, isSelected: model.request.guests == guests) {
                                model.request.guests = guests
                            }
                        }
                    }
                }

                VStack(spacing: 14) {
                    BrandTextField(label: "Name", text: $model.request.name, prompt: "Your name",
                                   error: model.nameError, contentType: .name, autocapitalization: .words)
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }
                    BrandTextField(label: "Email", text: $model.request.email, prompt: "you@example.com",
                                   error: model.emailError, keyboard: .emailAddress, contentType: .emailAddress,
                                   autocapitalization: .never)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .phone }
                    BrandTextField(label: "Phone (optional)", text: $model.request.phone, prompt: "For a reminder text",
                                   keyboard: .phonePad, contentType: .telephoneNumber)
                        .focused($focus, equals: .phone)
                }
                .padding(.top, 24)

                section("I'd most like to see (optional)") {
                    FlowLayout(spacing: 8) {
                        ForEach(TourInterest.allCases) { interest in
                            FilterChip(title: interest.title, isSelected: model.request.interests.contains(interest)) {
                                model.toggle(interest)
                            }
                        }
                    }
                }

                Button {
                    focus = nil
                    Task { await model.submit() }
                } label: {
                    HStack(spacing: 8) {
                        if model.isSubmitting { ProgressView().controlSize(.small).tint(Color.cream) }
                        Text(model.isSubmitting ? "Sending…" : "Request this tour")
                    }
                }
                .buttonStyle(DarkPrimaryPill())
                .disabled(model.isSubmitting)
                .padding(.top, 28)

                Text("We'll confirm by email within one business day. No payment needed to book.")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkSoft)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
            .padding(.horizontal, Spacing.headingInset)
            .padding(.bottom, Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func section<Content: View>(_ title: String, error: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Eyebrow(title, color: .inkSoft, size: 10, trackingEm: 0.12)
                Spacer()
                if let error {
                    Text(error).textStyle(.caption).foregroundStyle(Color.terracottaDeep)
                }
            }
            content()
        }
        .padding(.top, 24)
        .animation(Motion.quint, value: error)
    }
}

private struct TourConfirmationView: View {
    let confirmation: TourConfirmation
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.cream)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.burgundy))
            Text("Request sent.")
                .textStyle(.greetingTitle)
                .foregroundStyle(Color.burgundy)
            Text("Your tour at \(confirmation.cafeName) on \(BrandDateFormat.long.string(from: confirmation.date)) at \(OpeningHours.clock(confirmation.slot)) is pencilled in. We'll confirm to \(confirmation.email) within one business day.")
                .textStyle(.bodySmall)
                .foregroundStyle(Color.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Eyebrow("Reference \(confirmation.reference)", color: .terracottaDeep, size: 10)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(DarkPrimaryPill())
        }
        .padding(Spacing.md)
        .sensoryFeedback(.success, trigger: true)
    }
}

/// Wraps children onto new lines when they run out of width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !rows[rows.count - 1].indices.isEmpty, rows[rows.count - 1].width + spacing + size.width > width {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width += (row.indices.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

#Preview {
    TourBookingView(model: TourBookingModel(
        showrooms: MockCafeService.directory.showrooms,
        preselected: nil,
        service: MockCafeService()
    ))
}
