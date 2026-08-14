import SwiftUI

struct FlightsScreen: View {
    @State private var query = ""
    @State private var selection: Flight?

    private var matches: [Flight] {
        let all = Stats.flights.reversed().map { $0 }
        guard !query.isEmpty else { return all }
        let needle = query.lowercased()
        return all.filter { flight in
            [flight.from, flight.to, flight.airline, flight.number, flight.aircraft,
             flight.origin.city, flight.destination.city, String(flight.year)]
                .contains { $0.lowercased().contains(needle) }
        }
    }

    private var grouped: [(year: Int, flights: [Flight])] {
        Dictionary(grouping: matches, by: \.year)
            .map { (year: $0.key, flights: $0.value) }
            .sorted { $0.year > $1.year }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12, pinnedViews: .sectionHeaders) {
                    ForEach(grouped, id: \.year) { group in
                        Section {
                            ForEach(group.flights) { flight in
                                Button { selection = flight } label: {
                                    FlightCard(flight: flight)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            YearHeader(year: group.year, count: group.flights.count)
                        }
                    }

                    if matches.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .padding(.top, 60)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Palette.ground)
            .navigationTitle("Flights")
            .searchable(text: $query, prompt: "Airport, airline, aircraft, year")
            .sheet(item: $selection) { FlightDetail(flight: $0) }
        }
    }
}

private struct YearHeader: View {
    let year: Int
    let count: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(String(year))
                .font(.figure(20))
                .monospacedDigit()
            Text("\(count) flight\(count == 1 ? "" : "s")")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.top, 4)
        .background(Palette.ground)
    }
}

// MARK: - Card

struct FlightCard: View {
    let flight: Flight

    private var tint: Color { flight.isInternational ? Palette.longHaul : Palette.accent }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 10) {
                    endpoint(code: flight.from, city: flight.origin.city, alignment: .leading)

                    VStack(spacing: 3) {
                        RouteRule(tint: tint)
                        Text(flight.formattedDuration)
                            .font(.figure(11, .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    endpoint(code: flight.to, city: flight.destination.city, alignment: .trailing)
                }

                Divider().overlay(Palette.hairline)

                HStack(spacing: 8) {
                    Label(flight.airline, systemImage: "airplane")
                        .font(.system(size: 13, weight: .medium))
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(flight.formattedDate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                HStack(spacing: 6) {
                    Chip(text: flight.number)
                    Chip(text: flight.aircraft)
                    Spacer(minLength: 0)
                    Text("\(flight.km.formatted()) km")
                        .font(.figure(13, .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func endpoint(code: String, city: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(code)
                .font(.code(30))
                .foregroundStyle(tint)
            Text(city)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 92, alignment: alignment == .leading ? .leading : .trailing)
    }
}

private struct RouteRule: View {
    let tint: Color

    var body: some View {
        HStack(spacing: 0) {
            Circle().fill(tint).frame(width: 5, height: 5)
            Rectangle()
                .fill(LinearGradient(colors: [tint.opacity(0.55), tint.opacity(0.2)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 1.5)
            Image(systemName: "airplane")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
        }
    }
}

private struct Chip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Palette.raised, in: .capsule)
            .overlay(Capsule().strokeBorder(Palette.hairline))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

// MARK: - Detail

struct FlightDetail: View {
    let flight: Flight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    RouteMap(routes: [Route(a: flight.origin, b: flight.destination,
                                            count: 1, km: flight.km)],
                             interactive: false)
                        .frame(height: 230)
                        .clipShape(.rect(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Palette.hairline))

                    FlightCard(flight: flight)

                    Card {
                        VStack(spacing: 0) {
                            DetailRow(label: "From", value: "\(flight.origin.name), \(flight.origin.city)")
                            DetailRow(label: "To", value: "\(flight.destination.name), \(flight.destination.city)")
                            DetailRow(label: "Distance", value: "\(flight.km.formatted()) km · \(Int(Double(flight.km) * 0.621371).formatted()) mi")
                            DetailRow(label: "Est. block time", value: flight.formattedDuration)
                            if let time = flight.departureTime {
                                DetailRow(label: "Departure", value: time)
                            }
                            DetailRow(label: "Type", value: flight.isInternational ? "International" : "Domestic",
                                      last: flight.interpretation == nil)
                            if let note = flight.interpretation {
                                DetailRow(label: "Log note", value: note, tint: Palette.flag, last: true)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Palette.ground)
            .navigationTitle(flight.route)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var tint: Color = .primary
    var last = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 16)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tint)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 10)
            if !last { Divider().overlay(Palette.hairline) }
        }
    }
}
