import SwiftUI

/// Fabrix color tokens from the Foundations board: graphite and warm paper,
/// one signal orange for anything that waits on a human.
///
/// Every token adapts to dark mode. Dark mode puts the UI on a graphite
/// ground, flips ink to paper, and keeps signal orange unchanged.
public enum Palette {
    // MARK: Ink

    /// Primary text and the fill of primary (confirm) buttons.
    public static let graphite = Color(light: 0x18181B, dark: 0xF4F4F5)
    /// Secondary text.
    public static let steel = Color(light: 0x52525B, dark: 0xA1A1AA)
    /// Tertiary text: captions, timestamps, counts.
    public static let muted = Color(light: 0x5F5F66, dark: 0x8E8E96)
    /// Text and icons placed on a `graphite` fill.
    public static let onGraphite = Color(light: 0xFFFFFF, dark: 0x18181B)

    // MARK: Surfaces

    /// Window and screen background.
    public static let paper = Color(light: 0xF5F4F0, dark: 0x111113)
    /// Sidebar, search fields, empty budget track.
    public static let rail = Color(light: 0xECEAE4, dark: 0x1C1C1F)
    /// Toolbars and tab bars.
    public static let chrome = Color(light: 0xFBFAF8, dark: 0x161618)
    /// Selected sidebar row.
    public static let selection = Color(light: 0xE2DFD7, dark: 0x2A2A2E)
    /// Cards and sections.
    public static let card = Color(light: 0xFFFFFF, dark: 0x1C1C1F)
    /// Card borders and control outlines.
    public static let hairline = Color(light: 0xDEDBD3, dark: 0x2E2E33)
    /// Separators between rows inside a card.
    public static let divider = Color(light: 0xF1EFEA, dark: 0x26262A)
    /// Dark card that stays dark in both modes, e.g. the current-run card.
    public static let inverseSurface = Color(light: 0x18181B, dark: 0x27272A)
    /// Text on `inverseSurface`.
    public static let onInverse = Color.white
    /// Secondary text on `inverseSurface`.
    public static let onInverseMuted = Color(hex: 0xD4D4D8)

    // MARK: Signal and status

    /// Only for things that wait on a human: approvals, budget caps, primary wake.
    public static let signal = Color(hex: 0xC2410C)
    public static let onSignal = Color.white
    public static let signalInk = Color(light: 0x9A3412, dark: 0xFDBA74)
    public static let signalTint = Color(light: 0xFFEDD5, dark: 0x3B1A0B)

    public static let run = Color(light: 0x1D4ED8, dark: 0x60A5FA)
    public static let runInk = Color(light: 0x1E3A8A, dark: 0xBFDBFE)
    public static let runTint = Color(light: 0xDBEAFE, dark: 0x172554)

    public static let done = Color(light: 0x15803D, dark: 0x4ADE80)
    public static let doneInk = Color(light: 0x14532D, dark: 0xBBF7D0)
    public static let doneTint = Color(light: 0xDCFCE7, dark: 0x052E16)

    public static let halt = Color(light: 0xB91C1C, dark: 0xF87171)
    public static let haltInk = Color(light: 0x991B1B, dark: 0xFECACA)
    public static let haltTint = Color(light: 0xFEE2E2, dark: 0x450A0A)

    /// Dot for idle agents.
    public static let idle = Color(light: 0xA1A1AA, dark: 0x71717A)
    public static let neutralInk = Color(light: 0x3F3F46, dark: 0xD4D4D8)
    public static let neutralTint = Color(light: 0xF1EFEA, dark: 0x27272A)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: hex.red, green: hex.green, blue: hex.blue)
    }

    init(light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
            let light = UIColor(hex: light), dark = UIColor(hex: dark)
            self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
        #else
            let light = NSColor(hex: light), dark = NSColor(hex: dark)
            self.init(nsColor: NSColor(name: nil) {
                $0.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            })
        #endif
    }
}

#if canImport(UIKit)
    import UIKit

    extension UIColor {
        convenience init(hex: UInt32) {
            self.init(red: hex.red, green: hex.green, blue: hex.blue, alpha: 1)
        }
    }
#else
    import AppKit

    extension NSColor {
        convenience init(hex: UInt32) {
            self.init(srgbRed: hex.red, green: hex.green, blue: hex.blue, alpha: 1)
        }
    }
#endif

private extension UInt32 {
    var red: CGFloat {
        CGFloat((self >> 16) & 0xFF) / 255
    }

    var green: CGFloat {
        CGFloat((self >> 8) & 0xFF) / 255
    }

    var blue: CGFloat {
        CGFloat(self & 0xFF) / 255
    }
}
