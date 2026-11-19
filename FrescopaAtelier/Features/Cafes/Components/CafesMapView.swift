import MapKit
import SwiftUI

/// MapKit view of the filtered cafés with branded pins and a selected-café card.
struct CafesMapView: View {
    let cafes: [Cafe]
    var userLocation: CLLocation?
    let openStatus: (Cafe) -> (label: String, isOpen: Bool)
    let distance: (Cafe) -> String?
    var onOpen: (Cafe) -> Void = { _ in }

    @State private var selection: Cafe.ID?
    @State private var position: MapCameraPosition = .automatic

    private var selectedCafe: Cafe? { cafes.first { $0.id == selection } }

    var body: some View {
        Map(position: $position, selection: $selection) {
            ForEach(cafes) { cafe in
                Annotation(cafe.neighbourhood, coordinate: cafe.coordinate, anchor: .bottom) {
                    CafePin(isFlagship: cafe.isFlagship, isSelected: selection == cafe.id)
                }
                .tag(cafe.id)
                .annotationTitles(selection == cafe.id ? .visible : .hidden)
            }
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .tint(Color.terracotta)
        .overlay(alignment: .bottom) {
            if let cafe = selectedCafe {
                Button { onOpen(cafe) } label: {
                    CafeRow(cafe: cafe, openStatus: openStatus(cafe), distance: distance(cafe))
                        .padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Color.paper))
                        .elevation(.md)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.985))
                .padding(12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Motion.quint, value: selection)
        .onAppear { position = fittedPosition() }
        .onChange(of: cafes.map(\.id)) { _, _ in
            if let selection, !cafes.contains(where: { $0.id == selection }) { self.selection = nil }
            withAnimation(Motion.quint) { position = fittedPosition() }
        }
        .onChange(of: userLocation) { _, _ in
            withAnimation(Motion.quint) { position = fittedPosition() }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    /// Frames the user and their nearest café when we know where they are; otherwise
    /// fits the visible cafés, leaving far-flung international ones out of a mixed set.
    private func fittedPosition() -> MapCameraPosition {
        let distances = userLocation.map { here in cafes.map { $0.location.distance(from: here) }.sorted() } ?? []
        if let userLocation, !distances.isEmpty {
            // Frame the two nearest cafés so there's always a choice in view.
            let reach = distances[min(1, distances.count - 1)]
            let span = min(max(reach * 2.4, 4_000), 3_000_000)
            return .region(MKCoordinateRegion(center: userLocation.coordinate,
                                              latitudinalMeters: span, longitudinalMeters: span))
        }
        let domestic = cafes.filter { $0.cafeRegion != .international }
        let focus = domestic.isEmpty ? cafes : domestic
        guard !focus.isEmpty else { return .automatic }
        let lats = focus.map(\.latitude), lons = focus.map(\.longitude)
        let center = CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2,
                                            longitude: (lons.min()! + lons.max()!) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((lats.max()! - lats.min()!) * 1.3, 0.05),
                                    longitudeDelta: max((lons.max()! - lons.min()!) * 1.3, 0.05))
        return .region(MKCoordinateRegion(center: center, span: span))
    }
}

/// Burgundy pin with a cup glyph; the flagship gets an amber ring.
struct CafePin: View {
    var isFlagship = false
    var isSelected = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.terracottaDeep : Color.burgundy)
                    .overlay(Circle().strokeBorder(isFlagship ? Color.amber : Color.cream, lineWidth: isFlagship ? 3 : 2))
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: isSelected ? 14 : 11, weight: .semibold))
                    .foregroundStyle(Color.cream)
            }
            .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
            Triangle()
                .fill(isSelected ? Color.terracottaDeep : Color.burgundy)
                .frame(width: 10, height: 6)
        }
        .elevation(.sm)
        .animation(Motion.quint, value: isSelected)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

#Preview {
    CafesMapView(cafes: MockCafeService.cafes, openStatus: { _ in ("Open · until 7pm", true) }, distance: { _ in nil })
        .frame(height: 440)
}
