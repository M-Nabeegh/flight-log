import Foundation
import CoreLocation

// MARK: - Core types

struct Airport: Identifiable, Hashable {
    let code: String
    let city: String
    let name: String
    let country: String
    let lat: Double
    let lon: Double

    var id: String { code }
    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
}

struct Flight: Identifiable, Hashable {
    let date: String          // yyyy-MM-dd
    let from: String
    let to: String
    let airline: String
    let number: String
    let aircraft: String
    let km: Int
    let hours: Double
    let note: String?

    var id: String { "\(date)-\(from)-\(to)-\(number)" }

    var day: Date { Self.parser.date(from: date) ?? .distantPast }
    var year: Int { Self.calendar.component(.year, from: day) }
    var month: Int { Self.calendar.component(.month, from: day) }

    var origin: Airport { Registry.airport(from) }
    var destination: Airport { Registry.airport(to) }

    var isInternational: Bool { origin.country != destination.country }
    var isLongHaul: Bool { km >= 3_000 }

    /// A note that records a departure time rather than a reading of an ambiguous entry.
    var departureTime: String? {
        guard let note, note.hasPrefix("Dep ") else { return nil }
        return String(note.dropFirst(4))
    }

    /// A note explaining how an ambiguous log entry was read.
    var interpretation: String? {
        guard let note, !note.hasPrefix("Dep ") else { return nil }
        return note
    }

    var route: String { "\(from) → \(to)" }

    static let parser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .gmt
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Log dates carry no time zone, so they are read in GMT throughout — with a
    /// local calendar a date like 2026-04-01 slips into March west of Greenwich.
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .gmt
        return c
    }()
}

/// An unordered city pair — A→B and B→A are the same route.
struct Route: Identifiable, Hashable {
    let a: Airport
    let b: Airport
    let count: Int
    let km: Int

    var id: String { "\(a.code)-\(b.code)" }
    var label: String { "\(a.code) ⇄ \(b.code)" }
    var totalKm: Int { km * count }
    var isLongHaul: Bool { km >= 3_000 }
}

// MARK: - Registry

enum Registry {
    private static let byCode: [String: Airport] = Dictionary(
        uniqueKeysWithValues: FlightData.airports.map { ($0.code, $0) }
    )

    static func airport(_ code: String) -> Airport {
        byCode[code] ?? Airport(code: code, city: code, name: code, country: "—", lat: 0, lon: 0)
    }
}

// MARK: - Derived statistics

struct Tally: Identifiable, Hashable {
    let name: String
    let detail: String
    let count: Int
    var id: String { name }
}

enum Stats {
    static let flights = FlightData.flights.sorted { $0.date < $1.date }

    static var count: Int { flights.count }
    static var totalKm: Int { flights.reduce(0) { $0 + $1.km } }
    static var totalMiles: Int { Int((Double(totalKm) * 0.621371).rounded()) }
    static var totalHours: Double { flights.reduce(0) { $0 + $1.hours } }
    static var totalDays: Double { totalHours / 24 }

    static var equatorLaps: Double { Double(totalKm) / 40_075 }
    static var moonPercent: Double { Double(totalKm) / 384_400 * 100 }

    static var internationalCount: Int { flights.filter(\.isInternational).count }
    static var domesticCount: Int { count - internationalCount }
    static var internationalKm: Int { flights.filter(\.isInternational).reduce(0) { $0 + $1.km } }

    static var longest: Flight { flights.max { $0.km < $1.km }! }
    static var shortest: Flight { flights.min { $0.km < $1.km }! }
    static var first: Flight { flights.first! }
    static var latest: Flight { flights.last! }

    static var years: [Int] {
        let all = flights.map(\.year)
        guard let lo = all.min(), let hi = all.max() else { return [] }
        return Array(lo...hi)
    }

    static func flights(in year: Int) -> [Flight] { flights.filter { $0.year == year } }

    static var byYear: [(year: Int, count: Int, km: Int)] {
        years.map { y in
            let f = flights(in: y)
            return (y, f.count, f.reduce(0) { $0 + $1.km })
        }
    }

    static var airportsTouched: [Airport] {
        Set(flights.flatMap { [$0.from, $0.to] }).map(Registry.airport)
            .sorted { movements($0.code) > movements($1.code) }
    }

    static func movements(_ code: String) -> Int {
        flights.reduce(0) { $0 + (($1.from == code ? 1 : 0) + ($1.to == code ? 1 : 0)) }
    }

    static var cities: [Tally] {
        var grouped: [String: (country: String, codes: [String], n: Int)] = [:]
        for airport in FlightData.airports where movements(airport.code) > 0 {
            var entry = grouped[airport.city] ?? (airport.country, [], 0)
            entry.codes.append(airport.code)
            entry.n += movements(airport.code)
            grouped[airport.city] = entry
        }
        return grouped
            .map { Tally(name: $0.key, detail: "\($0.value.country) · \($0.value.codes.joined(separator: " / "))", count: $0.value.n) }
            .sorted { $0.count > $1.count }
    }

    static var countries: [Tally] {
        var grouped: [String: (cities: Set<String>, n: Int)] = [:]
        for airport in FlightData.airports where movements(airport.code) > 0 {
            var entry = grouped[airport.country] ?? ([], 0)
            entry.cities.insert(airport.city)
            entry.n += movements(airport.code)
            grouped[airport.country] = entry
        }
        return grouped
            .map { Tally(name: $0.key,
                         detail: $0.value.cities.sorted().joined(separator: ", "),
                         count: $0.value.n) }
            .sorted { $0.count > $1.count }
    }

    static var airlines: [Tally] {
        tally(by: \.airline) { group in
            let km = group.reduce(0) { $0 + $1.km }
            let types = Set(group.map(\.aircraft)).sorted()
            return "\(km.formatted()) km · \(types.joined(separator: ", "))"
        }
    }

    static var aircraft: [Tally] {
        tally(by: \.aircraft) { group in
            let km = group.reduce(0) { $0 + $1.km }
            let lines = Set(group.map(\.airline)).sorted()
            return "\(km.formatted()) km · \(lines.joined(separator: ", "))"
        }
    }

    static var families: [Tally] {
        tally(by: { family(of: $0.aircraft) }) { group in
            "\(group.reduce(0) { $0 + $1.km }.formatted()) km"
        }
    }

    static func family(of aircraft: String) -> String {
        if aircraft.contains("777") { return "Boeing 777" }
        if aircraft.contains("787") { return "Boeing 787" }
        if aircraft.contains("737 MAX") { return "Boeing 737 MAX" }
        if aircraft.contains("737") { return "Boeing 737NG" }
        if aircraft.contains("A380") { return "Airbus A380" }
        if aircraft.contains("A330") { return "Airbus A330" }
        if aircraft.contains("A32") { return "Airbus A320 family" }
        return "Bombardier CRJ"
    }

    private static func tally(by key: (Flight) -> String,
                              detail: ([Flight]) -> String) -> [Tally] {
        Dictionary(grouping: flights, by: key)
            .map { Tally(name: $0.key, detail: detail($0.value), count: $0.value.count) }
            .sorted { $0.count == $1.count ? $0.name < $1.name : $0.count > $1.count }
    }

    static var routes: [Route] {
        var grouped: [String: (Airport, Airport, Int, Int)] = [:]
        for flight in flights {
            let pair = [flight.from, flight.to].sorted()
            let key = pair.joined(separator: "-")
            let a = Registry.airport(pair[0]), b = Registry.airport(pair[1])
            let existing = grouped[key]
            grouped[key] = (a, b, (existing?.2 ?? 0) + 1, flight.km)
        }
        return grouped.values
            .map { Route(a: $0.0, b: $0.1, count: $0.2, km: $0.3) }
            .sorted { $0.count > $1.count }
    }

    /// The longest stretch of days with no flying.
    static var longestGap: (days: Int, from: Flight, to: Flight)? {
        guard flights.count > 1 else { return nil }
        var best: (Int, Flight, Flight)?
        for i in 1..<flights.count {
            let days = Flight.calendar.dateComponents([.day],
                        from: flights[i - 1].day, to: flights[i].day).day ?? 0
            if days > (best?.0 ?? 0) { best = (days, flights[i - 1], flights[i]) }
        }
        return best.map { (days: $0.0, from: $0.1, to: $0.2) }
    }

    static var busiestMonth: (name: String, count: Int) {
        let months = Dictionary(grouping: flights, by: \.month)
        // Ties resolve to the earlier month so the answer is stable run to run.
        let top = months.max { ($0.value.count, $1.key) < ($1.value.count, $0.key) }!
        let names = DateFormatter().monthSymbols ?? []
        return (names.indices.contains(top.key - 1) ? names[top.key - 1] : "—", top.value.count)
    }

    static var widebodyCount: Int {
        flights.filter { flight in
            ["777", "787", "A330", "A380"].contains { flight.aircraft.contains($0) }
        }.count
    }
}

// MARK: - Formatting

extension Flight {
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.timeZone = .gmt
        return f.string(from: day)
    }

    var shortDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.timeZone = .gmt
        return f.string(from: day)
    }

    var formattedDuration: String {
        let minutes = Int((hours * 60).rounded())
        return "\(minutes / 60)h \(String(format: "%02d", minutes % 60))m"
    }
}
