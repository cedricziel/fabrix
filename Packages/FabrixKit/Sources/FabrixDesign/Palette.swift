import SwiftUI

/// Fabrix color tokens from the Foundations board: graphite and warm paper,
/// one signal orange for anything that waits on a human.
public enum Palette {
    public static let graphite = Color(hex: 0x18181B)
    public static let steel = Color(hex: 0x52525B)
    public static let muted = Color(hex: 0x5F5F66)
    public static let paper = Color(hex: 0xF5F4F0)
    public static let rail = Color(hex: 0xECEAE4)
    public static let hairline = Color(hex: 0xDEDBD3)
    public static let card = Color.white
    public static let signal = Color(hex: 0xC2410C)
    public static let run = Color(hex: 0x1D4ED8)
    public static let done = Color(hex: 0x15803D)
    public static let halt = Color(hex: 0xB91C1C)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
