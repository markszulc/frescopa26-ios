import SwiftUI

/// Selectable filter chip: burgundy when on, hairline outline when off.
struct FilterChip: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool
    /// Stretch to fill the proposed width (e.g. inside a grid).
    var expands = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 12, weight: .medium))
                }
                Text(title)
            }
            .font(BrandFont.body(13, weight: .semibold, relativeTo: .footnote))
            .foregroundStyle(isSelected ? Color.cream : Color.ink)
            .padding(.horizontal, 14)
            .frame(maxWidth: expands ? .infinity : nil, minHeight: 34)
            .background(Capsule().fill(isSelected ? Color.burgundy : Color.paper))
            .overlay(Capsule().strokeBorder(isSelected ? Color.burgundy : Color.line, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.pressable)
        .animation(Motion.quint, value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Small uppercase tag, e.g. "SHOWROOM".
struct TagLabel: View {
    let text: String
    var onDark = false

    var body: some View {
        Text(text.uppercased())
            .font(BrandFont.body(10, weight: .semibold, relativeTo: .caption2))
            .tracking(1.1)
            .foregroundStyle(onDark ? Color.cream : Color.inkSoft)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(onDark ? Color.charcoal2 : Color.paper2))
            .overlay(Capsule().strokeBorder(onDark ? Color.lineDark : Color.line, lineWidth: 1))
    }
}

/// Hairline-bordered text input in the brand style.
struct BrandTextField: View {
    let label: String
    @Binding var text: String
    var prompt: String = ""
    var error: String?
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Eyebrow(label, color: .inkSoft, size: 10, trackingEm: 0.12)
            TextField(label, text: $text, prompt: Text(prompt).foregroundStyle(Color.inkSoft.opacity(0.6)))
                .font(BrandFont.body(16, relativeTo: .body))
                .foregroundStyle(Color.ink)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).fill(Color.paper))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(error == nil ? Color.line : Color.terracotta, lineWidth: 1)
                )
            if let error {
                Text(error)
                    .textStyle(.caption)
                    .foregroundStyle(Color.terracottaDeep)
                    .transition(.opacity)
            }
        }
        .animation(Motion.quint, value: error)
    }
}

/// Inline text link with a trailing arrow, e.g. "Get directions →".
struct ArrowLink: View {
    let title: String
    var color: Color = .terracottaDeep
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "arrow.right").font(.system(size: 12, weight: .semibold))
            }
            .font(BrandFont.body(14, weight: .semibold, relativeTo: .subheadline))
            .foregroundStyle(color)
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        HStack {
            FilterChip(title: "All", isSelected: true) {}
            FilterChip(title: "Showroom", systemImage: "cube", isSelected: false) {}
        }
        HStack { TagLabel(text: "Café"); TagLabel(text: "Showroom") }
        BrandTextField(label: "Email", text: .constant(""), prompt: "you@example.com", error: "Add a valid email")
        ArrowLink(title: "Get directions") {}
    }
    .padding()
    .background(Color.paper)
}
