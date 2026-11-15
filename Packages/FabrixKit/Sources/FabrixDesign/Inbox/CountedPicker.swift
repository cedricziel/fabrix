import SwiftUI

public enum CountedPickerStyle: Equatable, Sendable {
    case segmented, menu
}

/// The For you / Unassigned / Company switch, with a count on each choice. It becomes a menu at
/// accessibility text sizes, and a count of 0 is not shown.
public struct CountedPicker<Selection: Hashable>: View {
    public struct Option: Identifiable {
        public let id: Selection
        let title: String
        let count: Int

        public init(id: Selection, title: String, count: Int) {
            self.id = id
            self.title = title
            self.count = count
        }
    }

    private let accessibilityTitle: LocalizedStringResource
    private let options: [Option]
    @Binding private var selection: Selection
    @Environment(\.dynamicTypeSize) private var typeSize

    /// - Parameter accessibilityTitle: what VoiceOver calls the switch, such as "View".
    public init(_ accessibilityTitle: LocalizedStringResource, selection: Binding<Selection>, options: [Option]) {
        self.accessibilityTitle = accessibilityTitle
        _selection = selection
        self.options = options
    }

    nonisolated static func style(forAccessibilitySize isAccessibilitySize: Bool) -> CountedPickerStyle {
        isAccessibilitySize ? .menu : .segmented
    }

    nonisolated static func label(title: String, count: Int) -> String {
        CountBadge.text(for: count).map { "\(title) \($0)" } ?? title
    }

    nonisolated static func spokenLabel(title: String, count: Int) -> String {
        CountBadge.text(for: count).map { "\(title), \($0)" } ?? title
    }

    public var body: some View {
        let picker = Picker(selection: $selection) {
            ForEach(options) { option in
                Text(verbatim: Self.label(title: option.title, count: option.count))
                    .accessibilityLabel(Text(verbatim: Self.spokenLabel(title: option.title, count: option.count)))
                    .tag(option.id)
            }
        } label: {
            Text(accessibilityTitle)
        }
        switch Self.style(forAccessibilitySize: typeSize.isAccessibilitySize) {
        case .segmented: picker.pickerStyle(.segmented).labelsHidden()
        case .menu: picker.pickerStyle(.menu)
        }
    }
}

private struct CountedPickerPreview: View {
    @State private var selection = 0

    var body: some View {
        VStack(spacing: Spacing.l) {
            CountedPicker(.preview("View"), selection: $selection, options: [
                .init(id: 0, title: "For you", count: 3),
                .init(id: 1, title: "Unassigned", count: 0),
                .init(id: 2, title: "Company", count: 140),
            ])
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("CountedPicker") { CountedPickerPreview() }

#Preview("CountedPicker · dark") { CountedPickerPreview().preferredColorScheme(.dark) }

#Preview("CountedPicker · accessibility") { CountedPickerPreview().dynamicTypeSize(.accessibility3) }
