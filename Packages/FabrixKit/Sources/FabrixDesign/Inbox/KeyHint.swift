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
        var key = chord[...]
        var parts: [String] = []
        while let symbol = key.first {
            let modifier: String
            switch symbol {
            case "⌥": modifier = String(localized: "Option", bundle: .module)
            case "⌘": modifier = String(localized: "Command", bundle: .module)
            case "⇧": modifier = String(localized: "Shift", bundle: .module)
            case "⌃": modifier = String(localized: "Control", bundle: .module)
            default:
                parts.append(key == "-" ? String(localized: "Minus", bundle: .module) : String(key))
                return parts.joined(separator: "-")
            }
            parts.append(modifier)
            key.removeFirst()
        }
        return parts.joined(separator: "-")
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
