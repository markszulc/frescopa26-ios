import SwiftUI

/// The bag sheet: lines, quantities, subtotal and checkout.
struct BagView: View {
    let bag: BagStore
    @Environment(\.dismiss) private var dismiss
    @State private var showsCheckoutNote = false

    var body: some View {
        NavigationStack {
            Group {
                if bag.isEmpty {
                    VStack(spacing: Spacing.sm) {
                        BrandIconView(icon: .bag, size: 40, weight: .light)
                            .foregroundStyle(Color.burgundy)
                        Text("Your bag is empty")
                            .textStyle(.sectionTitle)
                            .foregroundStyle(Color.burgundy)
                        Text("Add beans, tea or a new machine from the shop.")
                            .textStyle(.bodySmall)
                            .foregroundStyle(Color.inkSoft)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Your bag")
                                .textStyle(.greetingTitle)
                                .foregroundStyle(Color.burgundy)
                            VStack(spacing: 0) {
                                ForEach(bag.lines) { line in
                                    BagLineRow(line: line,
                                               quantity: Binding(get: { line.quantity },
                                                                 set: { bag.setQuantity($0, for: line.id) }),
                                               onRemove: { withAnimation(Motion.quint) { bag.remove(line.id) } })
                                    if line.id != bag.lines.last?.id { Rectangle().fill(Color.line).frame(height: 1) }
                                }
                            }
                            .padding(.top, 12)
                            .animation(Motion.quint, value: bag.lines)

                            summary.padding(.top, 20)
                        }
                        .padding(.horizontal, Spacing.headingInset)
                        .padding(.bottom, Spacing.lg)
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button("Checkout · \(bag.subtotal.formatted)") { showsCheckoutNote = true }
                            .buttonStyle(DarkPrimaryPill())
                            .padding(.horizontal, Spacing.headingInset)
                            .padding(.vertical, 12)
                            .background(Color.paper)
                    }
                }
            }
            .background(Color.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.burgundy)
                }
            }
            .alert("Checkout is next", isPresented: $showsCheckoutNote) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your bag is saved on this device. Checkout will connect to the Fréscopa store's cart once it's enabled in the app.")
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.xl)
        .presentationBackground(Color.paper)
    }

    private var summary: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Subtotal").foregroundStyle(Color.inkSoft)
                Spacer()
                Text(bag.subtotal.formatted).foregroundStyle(Color.ink)
            }
            HStack {
                Text("Delivery").foregroundStyle(Color.inkSoft)
                Spacer()
                Text(bag.amountToFreeDelivery == 0 ? "Free" : "Calculated at checkout").foregroundStyle(Color.ink)
            }
            if bag.amountToFreeDelivery > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    LevelBar(value: NSDecimalNumber(decimal: bag.subtotal.amount / BagStore.freeDeliveryThreshold).doubleValue,
                             fill: .terracotta, track: .paper3, height: 5)
                    Text("Add \(Money(amount: bag.amountToFreeDelivery, currency: bag.subtotal.currency).formatted) for free delivery.")
                        .textStyle(.caption)
                        .foregroundStyle(Color.inkSoft)
                }
                .padding(.top, 4)
            }
        }
        .textStyle(.bodySmall)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper2))
    }
}

struct BagLineRow: View {
    let line: BagLine
    @Binding var quantity: Int
    var onRemove: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductImage(product: line.product, width: 200)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(line.product.name)
                    .textStyle(.bodyStrong)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                if let option = line.option {
                    Text(option.title).textStyle(.caption).foregroundStyle(Color.inkSoft)
                }
                HStack {
                    QuantityStepper(quantity: $quantity, range: 0...99, compact: true)
                    Spacer()
                    Text(line.lineTotal.formatted)
                        .textStyle(.price)
                        .foregroundStyle(Color.ink)
                }
                .padding(.top, 6)
            }
        }
        .padding(.vertical, 12)
        .contextMenu { Button("Remove", systemImage: "trash", role: .destructive, action: onRemove) }
    }
}

#Preview {
    let bag = BagStore()
    bag.add(MockShopService.products[1], quantity: 2)
    bag.add(MockShopService.products[2])
    return BagView(bag: bag)
}
