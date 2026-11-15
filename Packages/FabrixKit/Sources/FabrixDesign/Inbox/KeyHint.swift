import SwiftUI

/// Displays a keyboard shortcut and provides a spoken version for assistive technology.
public struct KeyHint: View {
    private let chord: String
    private let spokenChord: String

    public init(_ chord: String) {
        self.chord = chord
        self.spokenChord = Self.keyHintChord(chord)
    }

    nonisolated static func keyHintChord(_ chord: String) -> String {
        chord.replacingOccurrences(of: "⌥", with: String(localized: "Option-", bundle: .module))
            .replacingOccurrences(of: "⌘", with: String(localized: "Command-", bundle: .module))
            .replacingOccurrences(of: "⇧", with: String(localized: "Shift-", bundle: .module))
            .replacingOccurrences(of: "⌃", with: String(localized: "Control-", bundle: .module))
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    public var body: some View {
        Text(verbatim: chord)
            .font(.fabrix(.monoCaption))
            .foregroundStyle(Palette.steel)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: Radius.tag, style: .continuous))
            .accessibilityLabel(Text(verbatim: spokenChord))
    }
}

#Preview("Key hint light") { KeyHint("⌥⌘S").padding().background(Palette.paper) }
#Preview("Key hint dark") { KeyHint("⌥⌘S").padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Key hint accessibility") { KeyHint("⌥⌘S").padding().background(Palette.paper).dynamicTypeSize(.accessibility3) }

#Preview("Key hint") {
    KeyHint("⌥⌘S").padding().background(Palette.paper)
}
