import SwiftUI

/// Editable in one place: everything on the About screen that is about the
/// person rather than the data.
enum Profile {
    static let name = "John Carter"
    static let tagline = "London → wherever the schedule allows"
    static let initials = "J"

    /// Drop a file named `portrait` (PNG or JPG) into Assets.xcassets and this
    /// picks it up; until then the screen draws a monogram instead.
    static let portraitAsset = "portrait"

    static let bio = """
    Ten years of boarding passes, kept by hand since March 2016. \
    This app is that notebook, plotted — every leg, every aircraft, \
    every airport, counted properly for the first time.
    """

    static let links: [(label: String, value: String, icon: String)] = [
        ("Home base", "London, United Kingdom", "house.fill"),
        ("Logging since", "March 2016", "calendar"),
    ]
}

struct AboutScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    header
                    numbers
                    story
                    linkList
                    colophon
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 16) {
            portrait
            VStack(spacing: 6) {
                Text(Profile.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(Profile.tagline)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 26)
    }

    private var portrait: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Palette.accent, Palette.longHaul],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 124, height: 124)
                .blur(radius: 13)
                .opacity(0.42)

            Group {
                if let image = UIImage(named: Profile.portraitAsset) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(colors: [Palette.accent.opacity(0.9), Palette.longHaul.opacity(0.9)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        Text(Profile.initials)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.82))
                    }
                }
            }
            .frame(width: 118, height: 118)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Palette.hairline, lineWidth: 1))
        }
    }

    // MARK: Numbers

    private var numbers: some View {
        HStack(spacing: 10) {
            chip("\(Stats.count)", "flights")
            chip(Stats.totalKm.formatted(), "km")
            chip("\(Stats.countries.count)", "countries")
        }
    }

    private func chip(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.figure(19))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Palette.card, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.hairline))
    }

    // MARK: Story

    private var story: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "The log")
            Card {
                Text(Profile.bio)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Links

    private var linkList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Details")
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(Profile.links.enumerated()), id: \.offset) { index, link in
                        HStack(spacing: 12) {
                            Image(systemName: link.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(Palette.accent)
                                .frame(width: 22)
                            Text(link.label)
                                .font(.system(size: 15, weight: .medium))
                            Spacer(minLength: 12)
                            Text(link.value)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        if index < Profile.links.count - 1 {
                            Divider().overlay(Palette.hairline).padding(.leading, 50)
                        }
                    }
                }
            }
        }
    }

    // MARK: Colophon

    private var colophon: some View {
        VStack(spacing: 7) {
            HStack(spacing: 5) {
                Text("Made with")
                Image(systemName: "heart.fill").foregroundStyle(Palette.flag)
            }
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)

            Text("Distances are great-circle. Times are estimated block times, not logged.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }
}

#Preview { AboutScreen().tint(Palette.accent) }
