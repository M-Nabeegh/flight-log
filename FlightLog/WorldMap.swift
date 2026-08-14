import SwiftUI

/// A flat equirectangular world drawn with Canvas, with every route as a true
/// great circle.
///
/// This exists because MapKit cannot do it. The network spans 223° of longitude
/// (San Francisco to Bangkok); a Mercator map view on a portrait screen tops out
/// near 180° before it would need more than a whole world of latitude to match,
/// so MapKit silently clamps and the far ends fall off screen. A fixed
/// projection has no such limit — and it renders with no network at all.
struct WorldMap: View {
    let routes: [Route]
    /// Airports to mark. Pass the filtered set so dimmed years drop their pins.
    let airports: [Airport]

    /// Frame of the projection. Chosen to hold the whole network with margin.
    private let lon0 = -145.0, lon1 = 155.0
    private let latTop = 84.0, latBottom = -44.0

    private var maximum: Int { routes.map(\.count).max() ?? 1 }

    var body: some View {
        Canvas { context, size in
            let project = projector(in: size)

            paintGraticule(&context, size: size, project: project)
            paintLand(&context, project: project)
            paintRoutes(&context, project: project)
            paintAirports(&context, project: project)
        }
        .aspectRatio((lon1 - lon0) / (latTop - latBottom), contentMode: .fit)
        .background(Palette.sea)
    }

    // MARK: - Projection

    private func projector(in size: CGSize) -> (Double, Double) -> CGPoint {
        { lon, lat in
            CGPoint(x: (lon - lon0) / (lon1 - lon0) * size.width,
                    y: (latTop - lat) / (latTop - latBottom) * size.height)
        }
    }

    // MARK: - Layers

    private func paintGraticule(_ context: inout GraphicsContext, size: CGSize,
                                project: (Double, Double) -> CGPoint) {
        for lat in stride(from: -40.0, through: 80.0, by: 20.0) {
            var line = Path()
            line.move(to: CGPoint(x: 0, y: project(lon0, lat).y))
            line.addLine(to: CGPoint(x: size.width, y: project(lon0, lat).y))
            context.stroke(line, with: .color(Palette.graticule),
                           lineWidth: lat == 0 ? 0.9 : 0.5)
        }
        for lon in stride(from: -150.0, through: 150.0, by: 30.0) {
            var line = Path()
            line.move(to: CGPoint(x: project(lon, 0).x, y: 0))
            line.addLine(to: CGPoint(x: project(lon, 0).x, y: size.height))
            context.stroke(line, with: .color(Palette.graticule), lineWidth: 0.5)
        }
    }

    private func paintLand(_ context: inout GraphicsContext,
                           project: (Double, Double) -> CGPoint) {
        for ring in WorldOutline.land {
            let path = ring.asPath(project)
            context.fill(path, with: .color(Palette.land))
            context.stroke(path, with: .color(Palette.coast), lineWidth: 0.6)
        }
        for ring in WorldOutline.water {
            let path = ring.asPath(project)
            context.fill(path, with: .color(Palette.sea))
            context.stroke(path, with: .color(Palette.coast), lineWidth: 0.6)
        }
    }

    private func paintRoutes(_ context: inout GraphicsContext,
                             project: (Double, Double) -> CGPoint) {
        for route in routes {
            let path = greatCircle(from: route.a, to: route.b, project: project)
            context.stroke(
                path,
                with: .color(route.isLongHaul ? Palette.longHaul : Palette.accent),
                style: StrokeStyle(lineWidth: 0.7 + 2.6 * sqrt(Double(route.count) / Double(maximum)),
                                   lineCap: .round, lineJoin: .round))
        }
    }

    private func paintAirports(_ context: inout GraphicsContext,
                               project: (Double, Double) -> CGPoint) {
        // Busiest first, so when two airports are too close to both carry a
        // label the more-used one keeps it.
        let ranked = airports.sorted { traffic($0) > traffic($1) }
        var taken: [CGPoint] = []

        for airport in ranked {
            let point = project(airport.lon, airport.lat)
            let dot = Path(ellipseIn: CGRect(x: point.x - 2.4, y: point.y - 2.4,
                                             width: 4.8, height: 4.8))
            context.fill(dot, with: .color(Palette.sea))
            context.stroke(dot, with: .color(Palette.accent), lineWidth: 1.4)

            // A label needs roughly this much clear space around it; anything
            // tighter turns a cluster into mush.
            let clear = taken.allSatisfy { hypot($0.x - point.x, $0.y - point.y) > 22 }
            guard clear else { continue }
            taken.append(point)

            var text = context.resolve(
                Text(airport.code)
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded)))
            text.shading = .color(Palette.mapInk)
            context.draw(text,
                         at: CGPoint(x: point.x + 8, y: point.y - 5),
                         anchor: .leading)
        }
    }

    /// How many of the drawn routes touch this airport.
    private func traffic(_ airport: Airport) -> Int {
        routes.reduce(0) { total, route in
            total + ((route.a == airport || route.b == airport) ? route.count : 0)
        }
    }

    /// Interpolates along the sphere, so a route bends the way a flight does.
    /// Splits the path when it crosses the frame's seam.
    private func greatCircle(from a: Airport, to b: Airport,
                             project: (Double, Double) -> CGPoint) -> Path {
        let radians = Double.pi / 180
        func vector(_ lat: Double, _ lon: Double) -> (Double, Double, Double) {
            (cos(lat * radians) * cos(lon * radians),
             cos(lat * radians) * sin(lon * radians),
             sin(lat * radians))
        }
        let p = vector(a.lat, a.lon), q = vector(b.lat, b.lon)
        let dot = min(1, max(-1, p.0 * q.0 + p.1 * q.1 + p.2 * q.2))
        let omega = acos(dot)

        var path = Path()
        guard omega > 1e-6 else { return path }

        let steps = max(24, Int(omega / radians / 2))
        var previousLon: Double?
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let s1 = sin((1 - t) * omega) / sin(omega)
            let s2 = sin(t * omega) / sin(omega)
            let x = s1 * p.0 + s2 * q.0
            let y = s1 * p.1 + s2 * q.1
            let z = s1 * p.2 + s2 * q.2
            let lat = atan2(z, (x * x + y * y).squareRoot()) / radians
            let lon = atan2(y, x) / radians

            let wrapped = previousLon.map { abs(lon - $0) > 180 } ?? false
            if step == 0 || wrapped {
                path.move(to: project(lon, lat))
            } else {
                path.addLine(to: project(lon, lat))
            }
            previousLon = lon
        }
        return path
    }

}

private extension Array where Element == Double {
    /// Interprets the array as lon/lat pairs and closes the ring.
    func asPath(_ project: (Double, Double) -> CGPoint) -> Path {
        var path = Path()
        var index = 0
        while index + 1 < count {
            let point = project(self[index], self[index + 1])
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            index += 2
        }
        path.closeSubpath()
        return path
    }
}
