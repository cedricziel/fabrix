import SwiftUI

/// One answer option: a radio or checkbox mark, label, description, a "Recommended" tag and, when on, a free-text field.
public struct ChoiceRow: View {
    private let label: String
    private let detail: String?
    private let allowsMultiple: Bool
    private let isOn: Bool
    private let isRecommended: Bool
    private let freeText: Binding<String>?
    private let onToggle: () -> Void

    /// - Parameters:
    ///   - allowsMultiple: a checkbox instead of a radio.
    ///   - freeText: shows a text field under the option while it is on, for "Other".
    public init(
        label: String, detail: String? = nil, allowsMultiple: Bool, isOn: Bool, isRecommended: Bool = false,
        freeText: Binding<String>? = nil, onToggle: @escaping () -> Void
    ) {
        self.label = label
        self.detail = detail
        self.allowsMultiple = allowsMultiple
        self.isOn = isOn
        self.isRecommended = isRecommended
        self.freeText = freeText
        self.onToggle = onToggle
    }

    nonisolated static func accessibilityLabel(label: String, description: String?, isRecommended: Bool) -> String {
        [label, description, isRecommended ? String(localized: "Recommended", bundle: .module) : nil]
            .compactMap { $0 }.spokenSentences()
    }

    private var symbol: String {
        switch (allowsMultiple, isOn) {
        case (false, false): "circle"
        case (false, true): "circle.inset.filled"
        case (true, false): "square"
        case (true, true): "checkmark.square.fill"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button(action: onToggle) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
                    Image(systemName: symbol)
                        .foregroundStyle(isOn ? Palette.graphite : Palette.steel)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(verbatim: label).font(.fabrix(.headline)).foregroundStyle(Palette.graphite)
                        if let detail {
                            Text(verbatim: detail).font(.fabrix(.subheadline)).foregroundStyle(Palette.steel)
                        }
                        if isRecommended {
                            Text("Recommended", bundle: .module)
                                .font(.fabrix(.label))
                                .foregroundStyle(Palette.signalInk)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: minimumTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: Self.accessibilityLabel(label: label, description: detail, isRecommended: isRecommended)))
            .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
            if isOn, let freeText {
                TextField(text: freeText) { Text(verbatim: label) }
                    .textFieldStyle(.fabrix)
                    .padding(.leading, Spacing.xl)
            }
        }
    }
}

private struct ChoiceRowPreview: View {
    @State private var other = "Something else"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ChoiceRow(label: "Courier", detail: "Cheaper at our volume.", allowsMultiple: false, isOn: true, isRecommended: true) {}
            ChoiceRow(label: "OneSignal", detail: "Better dashboards.", allowsMultiple: false, isOn: false) {}
            ChoiceRow(label: "Other", allowsMultiple: false, isOn: true, freeText: $other) {}
            Divider()
            ChoiceRow(label: "iOS", allowsMultiple: true, isOn: true) {}
            ChoiceRow(label: "Android", allowsMultiple: true, isOn: false) {}
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("ChoiceRow") { ChoiceRowPreview() }

#Preview("ChoiceRow · dark") { ChoiceRowPreview().preferredColorScheme(.dark) }

#Preview("ChoiceRow · accessibility") { ChoiceRowPreview().dynamicTypeSize(.accessibility3) }
