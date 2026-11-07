import CoreText
import SwiftUI

/// Bundled typefaces: Space Grotesk for titles and numbers, Inter for UI,
/// JetBrains Mono for IDs, adapters, timers and money. All SIL OFL 1.1.
public enum FabrixFonts {
    public enum Face: String, CaseIterable, Sendable {
        case interRegular = "Inter-Regular"
        case interMedium = "Inter-Medium"
        case interSemiBold = "Inter-SemiBold"
        case interBold = "Inter-Bold"
        case spaceGroteskMedium = "SpaceGrotesk-Medium"
        case spaceGroteskSemiBold = "SpaceGrotesk-SemiBold"
        case spaceGroteskBold = "SpaceGrotesk-Bold"
        case jetBrainsMonoRegular = "JetBrainsMono-Regular"
        case jetBrainsMonoMedium = "JetBrainsMono-Medium"

        var weight: Font.Weight {
            switch self {
            case .interRegular, .jetBrainsMonoRegular: .regular
            case .interMedium, .spaceGroteskMedium, .jetBrainsMonoMedium: .medium
            case .interSemiBold, .spaceGroteskSemiBold: .semibold
            case .interBold, .spaceGroteskBold: .bold
            }
        }

        var design: Font.Design {
            switch self {
            case .jetBrainsMonoRegular, .jetBrainsMonoMedium: .monospaced
            default: .default
            }
        }

        var fileURL: URL? {
            let folder = String(rawValue.prefix { $0 != "-" })
            return Bundle.module.url(forResource: rawValue, withExtension: "ttf", subdirectory: "Fonts/\(folder)")
        }
    }

    /// Registers the bundled fonts for this process. Safe to call repeatedly;
    /// the work happens once. Returns `false` if any face failed, in which
    /// case `Font.fabrix` falls back to system fonts.
    @discardableResult
    public static func register() -> Bool {
        registered
    }

    private static let registered: Bool = Face.allCases.allSatisfy(register)

    private static func register(_ face: Face) -> Bool {
        guard let url = face.fileURL else { return false }
        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            return true
        }
        let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
        return code == CTFontManagerError.alreadyRegistered.rawValue
    }
}

/// The Fabrix type scale from the Foundations board.
public enum FabrixTextStyle: CaseIterable, Sendable {
    /// Space Grotesk 700, 34. Screen titles.
    case largeTitle
    /// Space Grotesk 600, 22. Section titles and inline numbers.
    case title
    /// Space Grotesk 600, 32. The big number on a metric card.
    case metric
    /// Inter 600, 15 (13 on Mac).
    case headline
    /// Inter 400, 15 (13 on Mac).
    case body
    /// Inter 500, 13. Secondary labels.
    case subheadline
    /// Inter 400, 12.
    case caption
    /// Inter 600, 12. Status pill labels.
    case label
    /// Inter 500, 12. Inline links such as "All runs".
    case link
    /// Inter 600, 11. Uppercase section labels.
    case eyebrow
    /// Inter 700, 11. Uppercase kind tags.
    case tag
    /// JetBrains Mono 400, 13.
    case mono
    /// JetBrains Mono 400, 12.
    case monoCaption

    struct Spec: Equatable {
        var face: FabrixFonts.Face
        var size: CGFloat
        var relativeTo: Font.TextStyle
    }

    #if os(macOS)
        private static let textSize: CGFloat = 13
    #else
        private static let textSize: CGFloat = 15
    #endif

    var spec: Spec {
        switch self {
        case .largeTitle: Spec(face: .spaceGroteskBold, size: 34, relativeTo: .largeTitle)
        case .title: Spec(face: .spaceGroteskSemiBold, size: 22, relativeTo: .title2)
        case .metric: Spec(face: .spaceGroteskSemiBold, size: 32, relativeTo: .title)
        case .headline: Spec(face: .interSemiBold, size: Self.textSize, relativeTo: .headline)
        case .body: Spec(face: .interRegular, size: Self.textSize, relativeTo: .body)
        case .subheadline: Spec(face: .interMedium, size: 13, relativeTo: .subheadline)
        case .caption: Spec(face: .interRegular, size: 12, relativeTo: .caption)
        case .label: Spec(face: .interSemiBold, size: 12, relativeTo: .caption)
        case .link: Spec(face: .interMedium, size: 12, relativeTo: .caption)
        case .eyebrow: Spec(face: .interSemiBold, size: 11, relativeTo: .caption2)
        case .tag: Spec(face: .interBold, size: 11, relativeTo: .caption2)
        case .mono: Spec(face: .jetBrainsMonoRegular, size: 13, relativeTo: .footnote)
        case .monoCaption: Spec(face: .jetBrainsMonoRegular, size: 12, relativeTo: .caption)
        }
    }
}

public extension Font {
    /// A font from the Fabrix type scale. Scales with Dynamic Type.
    static func fabrix(_ style: FabrixTextStyle) -> Font {
        let spec = style.spec
        guard FabrixFonts.register() else {
            return .system(spec.relativeTo, design: spec.face.design, weight: spec.face.weight)
        }
        return .custom(spec.face.rawValue, size: spec.size, relativeTo: spec.relativeTo)
    }

    /// A bundled face at a fixed size that ignores Dynamic Type, for text
    /// sized by its container (e.g. avatar initials).
    static func fabrix(_ face: FabrixFonts.Face, fixedSize size: CGFloat) -> Font {
        guard FabrixFonts.register() else {
            return .system(size: size, weight: face.weight, design: face.design)
        }
        return .custom(face.rawValue, fixedSize: size)
    }
}

#Preview("Type scale") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        Text(verbatim: "Large title 34").font(.fabrix(.largeTitle))
        Text(verbatim: "Title 22 · Metrics $412").font(.fabrix(.title))
        Text(verbatim: "412").font(.fabrix(.metric))
        Text(verbatim: "Headline semibold").font(.fabrix(.headline))
        Text(verbatim: "Body regular. Agents report, you decide.").font(.fabrix(.body))
        Text(verbatim: "Subheadline").font(.fabrix(.subheadline))
        Text(verbatim: "Caption").font(.fabrix(.caption))
        Text(verbatim: "EYEBROW").font(.fabrix(.eyebrow))
        Text(verbatim: "ATL-142 · claude-code · 07:41 · $6.12").font(.fabrix(.mono))
    }
    .foregroundStyle(Palette.graphite)
    .padding()
    .background(Palette.paper)
}
