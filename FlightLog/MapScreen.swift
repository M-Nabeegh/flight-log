import SwiftUI
import MapKit

/// Every route drawn as a true great circle, weighted by how often it was flown.
struct RouteMap: View {
    let routes: [Route]
    var interactive = true

    private var maximum: Int { routes.map(\.count).max() ?? 1 }

    private var airports: [Airport] {
        Array(Set(routes.flatMap { [$0.a, $0.b] }))
    }

    var body: some View {
        Map(initialPosition: .camera(camera), interactionModes: interactive ? .all : []) {
            ForEach(routes) { route in
                MapPolyline(coordinates: [route.a.coordinate, route.b.coordinate],
                            contourStyle: .geodesic)
                    .stroke(route.isLongHaul ? Palette.longHaul : Palette.accent,
                            style: StrokeStyle(lineWidth: width(for: route),
                                               lineCap: .round))
            }

            ForEach(airports) { airport in
                Annotation(airport.code, coordinate: airport.coordinate) {
                    AirportPin(code: airport.code, labelled: interactive)
                }
                .annotationTitles(.hidden)
            }
        }
        // `.realistic` matters: with `.flat`, MapKit refuses to pull back far
        // enough to curve into a globe, and a flat Mercator view physically
        // cannot hold 223° of longitude on a portrait screen.
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
    }

    private func width(for route: Route) -> CGFloat {
        1.2 + 3.6 * sqrt(CGFloat(route.count) / CGFloat(maximum))
    }

    /// A camera pulled back far enough to hold every airport in the set.
    ///
    /// Neither a lat/lon region nor a fitted map rect survives this data: the
    /// network spans 223° of longitude and MapKit quietly clamps both down until
    /// the far ends fall off screen. An explicit camera distance is the one
    /// framing it honours, so the span is converted to ground kilometres and the
    /// camera backed off to match.
    private var camera: MapCamera {
        let lats = airports.map(\.lat), lons = airports.map(\.lon)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return MapCamera(centerCoordinate: .init(latitude: 25, longitude: 67),
                             distance: 5_000_000)
        }
        let centre = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let widthKm = (maxLon - minLon) / 360 * 40_075 * cos(centre.latitude * .pi / 180)
        let heightKm = (maxLat - minLat) / 180 * 20_037
        // Portrait, so height needs more room per degree than width does.
        let reach = max(widthKm, heightKm * 1.9) * 1.25
        return MapCamera(centerCoordinate: centre, distance: max(reach * 1_000, 300_000))
    }
}

/// A ringed dot with its IATA code beneath — legible against both map styles.
private struct AirportPin: View {
    let code: String
    let labelled: Bool

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(Palette.ground)
                .frame(width: 9, height: 9)
                .overlay(Circle().strokeBorder(Palette.accent, lineWidth: 2.5))
            if labelled {
                Text(code)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.thinMaterial, in: .rect(cornerRadius: 4))
                    .fixedSize()
            }
        }
    }
}

struct MapScreen: View {
    @State private var year: Int?

    private var routes: [Route] {
        guard let year else { return Stats.routes }
        var grouped: [String: (Airport, Airport, Int, Int)] = [:]
        for flight in Stats.flights(in: year) {
            let pair = [flight.from, flight.to].sorted()
            let key = pair.joined(separator: "-")
            grouped[key] = (Registry.airport(pair[0]), Registry.airport(pair[1]),
                            (grouped[key]?.2 ?? 0) + 1, flight.km)
        }
        return grouped.values.map { Route(a: $0.0, b: $0.1, count: $0.2, km: $0.3) }
    }

    private var shownFlights: [Flight] {
        year.map { Stats.flights(in: $0) } ?? Stats.flights
    }

    private var shownAirports: [Airport] {
        Array(Set(routes.flatMap { [$0.a, $0.b] }))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WorldMap(routes: routes, airports: shownAirports)
                    .overlay(Rectangle().strokeBorder(Palette.hairline))
                    .padding(.top, 4)
                topRoutes
                Spacer(minLength: 0)
            }
                // An inset rather than an overlay: the map still draws full-bleed
                // behind the controls, but lays its legal attribution out above
                // them instead of underneath.
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 10) {
                        summary
                        yearPicker
                    }
                    .padding(.bottom, 6)
                }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// The map can only be as tall as 300° of longitude allows, so the space it
    /// leaves goes to the ranking the map itself cannot show: which lines are
    /// thick because they were flown, not because they are long.
    private var topRoutes: some View {
        let ranked = routes.sorted { $0.count > $1.count }.prefix(9)
        let maximum = ranked.first?.count ?? 1
        return VStack(alignment: .leading, spacing: 0) {
            legend
                .padding(.horizontal, 20)
                .padding(.top, 12)

            SectionLabel(text: year.map { "Most flown · \(String($0))" } ?? "Most flown")
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(Array(ranked), id: \.id) { route in
                HStack(spacing: 12) {
                    Text("\(route.a.code) ⇄ \(route.b.code)")
                        .font(.figure(14, .semibold))
                        .foregroundStyle(route.isLongHaul ? Palette.longHaul : Palette.accent)
                    GeometryReader { geo in
                        Capsule()
                            .fill(route.isLongHaul ? Palette.longHaul : Palette.accent)
                            .opacity(0.32)
                            .frame(width: max(3, geo.size.width * CGFloat(route.count) / CGFloat(maximum)),
                                   height: 4)
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 14)
                    Text("\(route.count)×")
                        .font(.figure(13, .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 34, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            key(Palette.accent, "Regional")
            key(Palette.longHaul, "Long-haul")
            Text("Line weight = times flown")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func key(_ colour: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(colour).frame(width: 16, height: 2.5)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var summary: some View {
        HStack(spacing: 14) {
            figure(String(shownFlights.count), "flights")
            Divider().frame(height: 22).overlay(Palette.hairline)
            figure(shownFlights.reduce(0) { $0 + $1.km }.formatted(), "km")
            Divider().frame(height: 22).overlay(Palette.hairline)
            figure(String(Set(shownFlights.flatMap { [$0.from, $0.to] }).count), "airports")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(.thickMaterial, in: .capsule)
        .overlay(Capsule().strokeBorder(Palette.hairline))
        .shadow(color: .black.opacity(0.16), radius: 10, y: 3)
    }

    private func figure(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.figure(16))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var yearPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                pill(title: "All", active: year == nil) { year = nil }
                ForEach(Stats.years, id: \.self) { candidate in
                    let flown = !Stats.flights(in: candidate).isEmpty
                    pill(title: String(candidate % 100).padded,
                         active: year == candidate,
                         enabled: flown) { year = candidate }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func pill(title: String, active: Bool, enabled: Bool = true,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.figure(14, .semibold))
                .monospacedDigit()
                .foregroundStyle(active ? Color.black : (enabled ? Color.primary : Color.secondary.opacity(0.4)))
                .frame(minWidth: 38)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(active ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(.thickMaterial),
                            in: .capsule)
                .overlay(Capsule().strokeBorder(Palette.hairline))
                .shadow(color: .black.opacity(0.14), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

private extension String {
    /// "5" → "05", so the year pills all sit on the same width.
    var padded: String { count < 2 ? "0" + self : self }
}
