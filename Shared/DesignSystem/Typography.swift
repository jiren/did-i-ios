import SwiftUI

/// The design's type: Bricolage Grotesque for display, DM Sans for text, each scaled with Dynamic Type.
/// Sizes are the design's (at the default text size); `relativeTo` picks how they grow.
enum Typography {
    enum Display: String {
        case semibold = "BricolageGrotesque-SemiBold"
        case bold = "BricolageGrotesque-Bold"
        case extraBold = "BricolageGrotesque-ExtraBold"
    }

    enum Text: String {
        case regular = "DMSans-Regular"
        case semibold = "DMSans-SemiBold"
        case bold = "DMSans-Bold"
    }

    static func display(_ size: CGFloat, _ weight: Display = .extraBold, relativeTo style: Font.TextStyle) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static func text(_ size: CGFloat, _ weight: Text = .regular, relativeTo style: Font.TextStyle) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }
}

extension Font {
    /// "Did I?" on Today, 52.
    static let didHero = Typography.display(52, relativeTo: .largeTitle)
    /// "Door locked." on Logged, 48.
    static let didLoggedTitle = Typography.display(48, relativeTo: .largeTitle)
    /// Detail's "Locked at 8:42 AM" and screen titles, 36–38.
    static let didScreenTitle = Typography.display(36, relativeTo: .largeTitle)
    /// Sheet titles ("Add checks"), 28.
    static let didSheetTitle = Typography.display(28, relativeTo: .title)
    /// A tile's check name, 21.
    static let didTileName = Typography.display(21, .bold, relativeTo: .title2)
    /// Section headings ("Recent", "History"), 20.
    static let didSection = Typography.display(20, .bold, relativeTo: .title3)
    /// The Add checks tile's label, 18.
    static let didTileAction = Typography.display(18, .bold, relativeTo: .headline)

    /// A tile's logged time, 21.
    static let didTileTime = Typography.text(21, .bold, relativeTo: .title2)
    /// Buttons, 17.
    static let didButton = Typography.text(17, .bold, relativeTo: .headline)
    /// Row titles, 16.
    static let didRowTitle = Typography.text(16, .bold, relativeTo: .callout)
    /// Body copy, 16.
    static let didBody = Typography.text(16, relativeTo: .callout)
    /// Emphasised small text (summary, chips, dates), 15.
    static let didEmphasis = Typography.text(15, .bold, relativeTo: .subheadline)
    /// Medium-weight small text, 15.
    static let didSubheadline = Typography.text(15, .semibold, relativeTo: .subheadline)
    /// Small regular text, 15.
    static let didCaptionBody = Typography.text(15, relativeTo: .subheadline)
    /// Pills and badges, 14.
    static let didPill = Typography.text(14, .bold, relativeTo: .footnote)
    /// Secondary lines, 13.
    static let didFootnote = Typography.text(13, .semibold, relativeTo: .footnote)
    /// Regular secondary lines, 13.
    static let didFootnoteRegular = Typography.text(13, relativeTo: .footnote)
    /// Uppercase section labels, 13.
    static let didLabel = Typography.text(13, .bold, relativeTo: .caption)

    /// The New category preview's name, 26.
    static let didPreviewTitle = Typography.display(26, relativeTo: .title)
    /// Today's title ("Today", "Sat"), 26.
    static let didDayTitle = Typography.display(26, relativeTo: .title)
    /// The progress bar's main line and a section's name, 17.
    static let didBarTitle = Typography.display(17, relativeTo: .headline)
    /// A day number in the 7-day strip, 17.
    static let didStripDay = Typography.display(17, relativeTo: .headline)
    /// A strip day's letter, 11.
    static let didStripWeekday = Typography.text(11, .bold, relativeTo: .caption2)
    /// A section's meta line ("Every Friday"), 12.
    static let didMeta = Typography.text(12, .semibold, relativeTo: .caption)
    /// A task's name on a square tile, 14.
    static let didSmallTileName = Typography.display(14, .bold, relativeTo: .subheadline)
    /// Strip weekdays, the bar's scope and a tile's status line, 12.
    static let didMicro = Typography.text(12, .bold, relativeTo: .caption2)
}
