import SwiftUI

/// A mono key cap for shortcut hints in buttons, menus and the legend: "J", "⌥⌘S".
public struct KeyHint: View {
    public enum Modifier: CaseIterable, Comparable, Sendable {
        case control, option, shift, command

        nonisolated var symbol: String {
            switch self {
            case .control: "⌃"
            case .option: "⌥"
            case .shift: "⇧"
            case .command: "⌘"
            }
        }

        nonisolated var spoken: String {
            switch self {
            case .control: String(localized: "Control", bundle: .module)
            case .option: String(localized: "Option", bundle: .module)
            case .shift: String(localized: "Shift", bundle: .module)
            case .command: String(localized: "Command", bundle: .module)
            }
        }
    }

    private let key: String
    private let modifiers: [Modifier]

    public init(_ key: String, modifiers: Set<Modifier> = []) {
        self.key = key
        self.modifiers = modifiers.sorted()
    }

    nonisolated static func symbols(key: String, modifiers: Set<Modifier>) -> String {
        modifiers.sorted().map(\.symbol).joined() + key
    }

    nonisolated static func spokenChord(key: String, modifiers: Set<Modifier>) -> String {
        (modifiers.sorted().map(\.spoken) + [spokenKey(key)]).joined(separator: "-")
    }

    private nonisolated static func spokenKey(_ key: String) -> String {
        switch key {
        case "↩": String(localized: "Return", bundle: .module)
        case "⌫": String(localized: "Delete", bundle: .module)
        case "⎋": String(localized: "Escape", bundle: .module)
        case "↑": String(localized: "Up Arrow", bundle: .module)
        case "↓": String(localized: "Down Arrow", bundle: .module)
        default: key
        }
    }

    public var body: some View {
        Text(verbatim: Self.symbols(key: key, modifiers: Set(modifiers)))
            .font(.fabrix(.monoCaption))
            .foregroundStyle(Palette.steel)
            .padding(.horizontal, 6)
            .frame(minWidth: 20, minHeight: 20)
            .background(Palette.rail, in: RoundedRectangle(cornerRadius: Radius.tag, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.tag, style: .continuous).strokeBorder(Palette.hairline))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: Self.spokenChord(key: key, modifiers: Set(modifiers))))
    }
}

private struct KeyHintPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                KeyHint("J")
                KeyHint("K")
                KeyHint("↩", modifiers: [.command])
                KeyHint("S", modifiers: [.option, .command])
            }
            Button {} label: {
                HStack {
                    Text(verbatim: "Approve")
                    KeyHint("↩", modifiers: [.command])
                }
            }
            .buttonStyle(.fabrixSecondary)
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("KeyHint") { KeyHintPreview() }

#Preview("KeyHint · dark") { KeyHintPreview().preferredColorScheme(.dark) }

#Preview("KeyHint · accessibility") { KeyHintPreview().dynamicTypeSize(.accessibility3) }
