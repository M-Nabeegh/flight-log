import SwiftUI
import Charts

struct StatsScreen: View {
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    headline
                    tiles
                    yearChart
                    leaderboard("Countries", Stats.countries, suffix: " visits",
                                note: "A visit is one arrival or one departure, so a return trip counts twice.")
                    leaderboard("Cities", Stats.cities, suffix: " visits",
                                note: "Same count, split by city rather than country.")
                    leaderboard("Airlines", Stats.airlines, suffix: " flights")
                    leaderboard("Aircraft", Stats.aircraft, suffix: " flights")
                    superlatives
                    method
                }
                .padding(16)
            }
            .background(Palette.ground)
            .navigationTitle("Stats")
        }
    }

    // MARK: Headline

    private var headline: some View {
        Card(padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Total distance")
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(Stats.totalKm.formatted())
                        .font(.figure(42))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("km")
                        .font(.figure(18, .semibold))
                        .foregroundStyle(.secondary)
                }
                Text("\(String(format: "%.2f", Stats.equatorLaps)) laps of the equator, or \(String(format: "%.0f", Stats.moonPercent))% of the way to the Moon.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var tiles: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatTile(value: String(Stats.count), unit: nil, label: "Flights")
            StatTile(value: String(format: "%.0f", Stats.totalHours), unit: "h",
                     label: "Est. airborne", tint: Palette.accent)
            StatTile(value: String(Stats.airportsTouched.count), unit: nil, label: "Airports")
            StatTile(value: String(Stats.cities.count), unit: nil, label: "Cities")
            StatTile(value: String(Stats.countries.count), unit: nil, label: "Countries")
            StatTile(value: String(Stats.airlines.count), unit: nil, label: "Airlines")
            StatTile(value: String(Stats.aircraft.count), unit: nil, label: "Aircraft types")
            StatTile(value: String(Stats.internationalCount), unit: "of \(Stats.count)",
                     label: "International", tint: Palette.longHaul)
        }
    }

    // MARK: Chart

    private var yearChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Flights per year")
            Card(padding: 14) {
                Chart(Stats.byYear, id: \.year) { entry in
                    BarMark(
                        x: .value("Year", String(entry.year % 100).padded),
                        y: .value("Flights", entry.count)
                    )
                    .foregroundStyle(Palette.accent)
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        if entry.count > 0 {
                            Text("\(entry.count)")
                                .font(.figure(10, .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text("’\(label)").font(.system(size: 10, weight: .medium))
                            }
                        }
                    }
                }
                .frame(height: 170)
            }
            Text("2013 and 2015 are the only years with nothing logged.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Leaderboards

    private func leaderboard(_ title: String, _ items: [Tally], suffix: String,
                             note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
            if let note {
                Text(note)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, -4)
            }
            Card(padding: 14) {
                let maximum = items.map(\.count).max() ?? 1
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        TallyRow(tally: item, maximum: maximum, suffix: suffix)
                    }
                }
            }
        }
    }

    // MARK: Superlatives

    private var superlatives: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Superlatives")
            LazyVGrid(columns: columns, spacing: 12) {
                superlative("Longest leg", Stats.longest.route,
                            "\(Stats.longest.km.formatted()) km · \(Stats.longest.formattedDuration)\n\(Stats.longest.aircraft)",
                            tint: Palette.longHaul)
                superlative("Shortest leg", Stats.shortest.route,
                            "\(Stats.shortest.km.formatted()) km · \(Stats.shortest.formattedDuration)\n\(Stats.shortest.aircraft)")
                if let gap = Stats.longestGap {
                    superlative("Longest grounding", "\(gap.days) days",
                                "\(gap.from.formattedDate)\nto \(gap.to.formattedDate)")
                }
                superlative("Busiest month", Stats.busiestMonth.name,
                            "\(Stats.busiestMonth.count) flights across the years")
                superlative("Time in the air", String(format: "%.1f days", Stats.totalDays),
                            "\(String(format: "%.1f", Stats.totalHours)) estimated block hours",
                            tint: Palette.accent)
                superlative("Widebody legs", "\(Stats.widebodyCount) of \(Stats.count)",
                            "777 · 787 · A330 · A380")
            }
        }
    }

    private func superlative(_ label: String, _ value: String, _ detail: String,
                             tint: Color = .primary) -> some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: label)
                Text(value)
                    .font(.figure(19))
                    .foregroundStyle(tint)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Method

    private var method: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "How the numbers were made")
            Card(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Distances are great-circle, airport to airport. Times are estimated block times — great-circle distance ÷ 780 km/h, plus 27 minutes for taxi, climb and descent — so they track the schedule but are not your logged times.")
                    Text("Four entries recorded the same airport twice and were read against the flight number's usual rotation; they are marked in the flight detail. The missed Airblue PA111 on 15 Jul 2025 is excluded from every total.")
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private extension String {
    var padded: String { count < 2 ? "0" + self : self }
}
