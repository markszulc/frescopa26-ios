import SwiftUI

/// Icon set used by the app. Most map to SF Symbols that match the design's
/// 1.6pt rounded line icons; the coffee bean has no SF Symbol and is drawn natively.
enum BrandIcon: Hashable {
    case bell, brewCup, reorder, care, location, home, bag, account, bean

    var systemName: String? {
        switch self {
        case .bell: "bell"
        case .brewCup: "cup.and.saucer"
        case .reorder: "arrow.trianglehead.2.clockwise"
        case .care: "drop"
        case .location: nil
        case .home: "house"
        case .bag: "bag"
        case .account: "person"
        case .bean: nil
        }
    }
}

struct BrandIconView: View {
    let icon: BrandIcon
    var size: CGFloat = 22
    var weight: Font.Weight = .regular

    var body: some View {
        if let name = icon.systemName {
            Image(systemName: name)
                .font(.system(size: size * 0.86, weight: weight))
                .frame(width: size, height: size)
        } else {
            let stroke = StrokeStyle(lineWidth: 1.6 * size / 24 * (weight == .medium ? 1.25 : 1), lineCap: .round, lineJoin: .round)
            Group {
                switch icon {
                case .location: MapPinShape().stroke(style: stroke)
                default: CoffeeBeanShape().stroke(style: stroke)
                }
            }
            .frame(width: size, height: size)
        }
    }
}

/// Port of the design's map pin: a teardrop with a hollow centre.
struct MapPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        var path = Path()
        // M12 21 s-7-6.2-7-11.5 a7 7 0 0 1 14 0 C19 14.8 12 21 12 21z
        path.move(to: p(12, 21))
        path.addCurve(to: p(5, 9.5), control1: p(12, 21), control2: p(5, 14.8))
        path.addArc(center: p(12, 9.5), radius: 7 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addCurve(to: p(12, 21), control1: p(19, 14.8), control2: p(12, 21))
        path.closeSubpath()
        path.addEllipse(in: CGRect(x: 9.5 * s, y: 7 * s, width: 5 * s, height: 5 * s))
        let origin = CGPoint(x: rect.midX - 12 * s, y: rect.midY - 12 * s)
        return path.offsetBy(dx: origin.x, dy: origin.y)
    }
}

/// Coffee bean glyph: a tilted oval with an S-shaped crease, drawn in a 24pt grid.
struct CoffeeBeanShape: Shape {
    enum Part { case outline, body, crease }
    var part: Part = .outline

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let rotate = CGAffineTransform(translationX: 12 * s, y: 12 * s)
            .rotated(by: .pi / 6)
            .translatedBy(x: -12 * s, y: -12 * s)

        let body = Path(ellipseIn: CGRect(x: 6 * s, y: 3.5 * s, width: 12 * s, height: 17 * s))
        var crease = Path()
        crease.move(to: CGPoint(x: 12 * s, y: 5.5 * s))
        crease.addCurve(to: CGPoint(x: 12 * s, y: 18.5 * s),
                        control1: CGPoint(x: 9 * s, y: 10 * s),
                        control2: CGPoint(x: 15 * s, y: 14 * s))

        var path = Path()
        switch part {
        case .outline:
            path.addPath(body, transform: rotate)
            path.addPath(crease, transform: rotate)
        case .body:
            path.addPath(body, transform: rotate)
        case .crease:
            path.addPath(crease, transform: rotate)
        }
        return path.offsetBy(dx: rect.midX - 12 * s, dy: rect.midY - 12 * s)
    }
}

/// Solid bean with the crease cut out, for filled states (e.g. ratings).
struct FilledBean: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            CoffeeBeanShape(part: .body).fill()
            CoffeeBeanShape(part: .crease)
                .stroke(style: StrokeStyle(lineWidth: 1.8 * size / 24, lineCap: .round))
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        ForEach([BrandIcon.bell, .brewCup, .reorder, .care, .location, .bean], id: \.self) {
            BrandIconView(icon: $0)
        }
    }
    .foregroundStyle(Color.burgundy)
    .padding()
}
