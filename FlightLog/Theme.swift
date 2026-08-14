import SwiftUI

/// The app's visual language: near-black grounds, a chart-cyan accent for regional
/// flying and marigold for anything that crosses a border.
enum Palette {
    static let accent = Color(red: 0.37, green: 0.84, blue: 0.82)     // #5FD6D2
    static let longHaul = Color(red: 0.94, green: 0.66, blue: 0.24)   // #F0A93E
    static let flag = Color(red: 0.89, green: 0.47, blue: 0.60)       // #E4779A

    static let ground = Color(uiColor: .systemBackground)
    static let card = Color(uiColor: .secondarySystemBackground)
    static let raised = Color(uiColor: .tertiarySystemBackground)
    static let hairline = Color.primary.opacity(0.09)

    // The flat overview chart. Muted on purpose: the routes are the subject,
    // the continents only place them.
    static let sea = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.07, blue: 0.08, alpha: 1)
            : UIColor(red: 0.91, green: 0.88, blue: 0.83, alpha: 1)
    })
    static let land = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.13, blue: 0.15, alpha: 1)
            : UIColor(red: 0.86, green: 0.83, blue: 0.76, alpha: 1)
    })
    static let coast = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.21, blue: 0.24, alpha: 1)
            : UIColor(red: 0.75, green: 0.70, blue: 0.61, alpha: 1)
    })
    static let graticule = Color.primary.opacity(0.07)
    static let mapInk = Color.primary.opacity(0.75)
}

extension Font {
    /// Rounded, tabular figures — the face used for every number in the app.
    static func figure(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// The airport-code face: wide, flat, unmistakably a departure board.
    static func code(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Building blocks

/// A rounded surface with a hairline edge — the app's only container.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: .rect(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Palette.hairline))
    }
}

/// A small uppercase label used above every group of content.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .tracking(0.9)
            .foregroundStyle(.secondary)
    }
}

/// One headline number with a caption — the unit of the Stats screen.
struct StatTile: View {
    let value: String
    let unit: String?
    let label: String
    var tint: Color = .primary

    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(text: label)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.figure(27))
                        .foregroundStyle(tint)
                        .monospacedDigit()
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if let unit {
                        Text(unit)
                            .font(.figure(14, .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

/// A ranked row with a magnitude bar underneath — used by every leaderboard.
struct TallyRow: View {
    let tally: Tally
    let maximum: Int
    var suffix: String = "×"

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(tally.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer(minLength: 12)
                Text("\(tally.count)\(suffix)")
                    .font(.figure(15, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if !tally.detail.isEmpty {
                Text(tally.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.hairline)
                    Capsule()
                        .fill(Palette.accent)
                        .frame(width: max(3, geo.size.width * ratio))
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, 9)
    }

    private var ratio: CGFloat {
        maximum > 0 ? CGFloat(tally.count) / CGFloat(maximum) : 0
    }
}
