#if canImport(AppKit)
    import AppKit
    @testable import FabrixDesign
    import SwiftUI
    import Testing

    /// WCAG 2 contrast for text tokens on the surfaces they sit on, in both modes.
    struct ContrastTests {
        static let textPairs: [(String, Color, Color)] = [
            ("graphite/paper", Palette.graphite, Palette.paper),
            ("graphite/card", Palette.graphite, Palette.card),
            ("steel/card", Palette.steel, Palette.card),
            ("muted/card", Palette.muted, Palette.card),
            ("muted/paper", Palette.muted, Palette.paper),
            ("link/card", SectionHeader.linkColor, Palette.card),
            ("link/paper", SectionHeader.linkColor, Palette.paper),
            ("signalInk/signalTint", Palette.signalInk, Palette.signalTint),
            ("runInk/runTint", Palette.runInk, Palette.runTint),
            ("doneInk/doneTint", Palette.doneInk, Palette.doneTint),
            ("haltInk/haltTint", Palette.haltInk, Palette.haltTint),
            ("neutralInk/neutralTint", Palette.neutralInk, Palette.neutralTint),
            ("onGraphite/graphite", Palette.onGraphite, Palette.graphite),
            ("onInverse/inverseSurface", Palette.onInverse, Palette.inverseSurface),
        ]

        @Test(arguments: textPairs.map(\.0), [NSAppearance.Name.aqua, .darkAqua])
        func normalTextMeetsAA(pair: String, appearance: NSAppearance.Name) throws {
            let (_, text, background) = try #require(Self.textPairs.first { $0.0 == pair })
            let ratio = contrast(text, background, in: appearance)
            #expect(ratio >= 4.5, "\(pair) in \(appearance.rawValue): \(ratio)")
        }

        private func contrast(_ a: Color, _ b: Color, in name: NSAppearance.Name) -> Double {
            var ratio = 0.0
            NSAppearance(named: name)!.performAsCurrentDrawingAppearance {
                let la = luminance(a), lb = luminance(b)
                ratio = (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
            }
            return ratio
        }

        private func luminance(_ color: Color) -> Double {
            let c = NSColor(color).usingColorSpace(.sRGB)!
            func channel(_ v: CGFloat) -> Double {
                let v = Double(v)
                return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(c.redComponent) + 0.7152 * channel(c.greenComponent) + 0.0722 * channel(c.blueComponent)
        }
    }
#endif
