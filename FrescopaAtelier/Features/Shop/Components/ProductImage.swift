import SwiftUI

/// Product photo from AEM asset delivery, with a branded placeholder for products
/// the catalog has no imagery for yet.
struct ProductImage: View {
    let product: ShopProduct
    var width: Int = 600

    var body: some View {
        if let url = product.imageURL(width: width) {
            AsyncImage(url: url, transaction: Transaction(animation: Motion.quint)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    ProductPlaceholder(family: product.family)
                default:
                    ProductPlaceholder(family: product.family, showsGlyph: false)
                        .overlay { ProgressView().tint(Color.cream) }
                }
            }
            .accessibilityLabel(product.name)
        } else {
            ProductPlaceholder(family: product.family)
                .accessibilityLabel(product.name)
        }
    }
}

struct ProductPlaceholder: View {
    let family: ShopProduct.Family
    var showsGlyph = true

    private var style: (Color, Color, String) {
        switch family {
        case .machine: (.charcoal, .charcoal2, "cube")
        case .coffee: (.charcoal2, .terracottaDeep, "cup.and.saucer.fill")
        case .pod: (.burgundy, .terracotta, "circle.hexagongrid.fill")
        case .tea: (.terracottaDeep, .amber, "leaf.fill")
        case .accessory: (.sand, .paper3, "mug")
        }
    }

    var body: some View {
        let (from, to, symbol) = style
        ZStack {
            LinearGradient(colors: [from, to], startPoint: .topLeading, endPoint: .bottomTrailing)
            if family == .machine {
                RadialGradient(colors: [Color.amber.opacity(0.25), .clear], center: .topTrailing, startRadius: 0, endRadius: 220)
            }
            if showsGlyph {
                Image(systemName: symbol)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(family == .accessory ? Color.burgundy.opacity(0.6) : Color.cream.opacity(0.85))
            }
        }
    }
}

/// Colour chips for product finishes ("Cream", "Charcoal", "Terracotta").
struct FinishSwatch: View {
    let value: ProductOptionValue
    let isSelected: Bool
    var size: CGFloat = 30
    var onDark = false
    var action: () -> Void = {}

    static func color(for title: String) -> Color {
        switch title.lowercased() {
        case "cream": .cream
        case "charcoal", "black": .charcoal
        case "terracotta": .terracotta
        case "burgundy": .burgundy
        default: .sand
        }
    }

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Self.color(for: value.title))
                .overlay(Circle().strokeBorder(onDark ? Color.lineDark : Color.line, lineWidth: 1))
                .frame(width: size, height: size)
                .padding(3)
                .overlay(Circle().strokeBorder(isSelected ? (onDark ? Color.amber : Color.burgundy) : .clear, lineWidth: 2))
                .overlay {
                    if !value.inStock {
                        Rectangle().fill(Color.inkSoft).frame(width: 1.5, height: size * 1.1).rotationEffect(.degrees(45))
                    }
                }
        }
        .buttonStyle(.pressable)
        .disabled(!value.inStock)
        .accessibilityLabel(value.title + (value.inStock ? "" : ", out of stock"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// − n + control.
struct QuantityStepper: View {
    @Binding var quantity: Int
    var range: ClosedRange<Int> = 1...99
    var compact = false

    var body: some View {
        HStack(spacing: 0) {
            step("minus", enabled: quantity > range.lowerBound) { quantity -= 1 }
            Text("\(quantity)")
                .font(BrandFont.body(compact ? 14 : 16, weight: .semibold, relativeTo: .body))
                .foregroundStyle(Color.ink)
                .frame(minWidth: compact ? 24 : 32)
                .contentTransition(.numericText())
                .animation(Motion.quint, value: quantity)
            step("plus", enabled: quantity < range.upperBound) { quantity += 1 }
        }
        .padding(.horizontal, 4)
        .frame(height: compact ? 34 : 44)
        .background(Capsule().fill(Color.paper))
        .overlay(Capsule().strokeBorder(Color.line, lineWidth: 1))
        .sensoryFeedback(.selection, trigger: quantity)
        .accessibilityElement()
        .accessibilityLabel("Quantity")
        .accessibilityValue("\(quantity)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if quantity < range.upperBound { quantity += 1 }
            case .decrement: if quantity > range.lowerBound { quantity -= 1 }
            @unknown default: break
            }
        }
    }

    private func step(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: compact ? 11 : 13, weight: .bold))
                .foregroundStyle(enabled ? Color.burgundy : Color.line)
                .frame(width: compact ? 28 : 36, height: compact ? 34 : 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .disabled(!enabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            ForEach([ShopProduct.Family.machine, .coffee, .pod, .tea, .accessory], id: \.self) {
                ProductPlaceholder(family: $0).frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        HStack {
            FinishSwatch(value: .init(id: "1", title: "Cream", inStock: true), isSelected: true)
            FinishSwatch(value: .init(id: "2", title: "Charcoal", inStock: true), isSelected: false)
            FinishSwatch(value: .init(id: "3", title: "Terracotta", inStock: false), isSelected: false)
        }
        QuantityStepper(quantity: .constant(2))
    }
    .padding()
    .background(Color.paper)
}

extension ShopProduct.Family: Hashable {}
