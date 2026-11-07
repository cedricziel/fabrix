import CoreGraphics

/// Spacing steps used across the boards.
public enum Spacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

/// Corner radii. Cards are rounder on touch devices than on the Mac.
public enum Radius {
    /// Kind tags.
    public static let tag: CGFloat = 5
    /// Sidebar rows, small buttons, search fields.
    public static let row: CGFloat = 8
    /// Regular buttons.
    public static let control: CGFloat = 12
    /// Large buttons.
    public static let controlLarge: CGFloat = 14
    #if os(macOS)
        public static let card: CGFloat = 12
    #else
        public static let card: CGFloat = 16
    #endif
}

/// Smallest hit area for anything tappable.
public let minimumTapTarget: CGFloat = 44
