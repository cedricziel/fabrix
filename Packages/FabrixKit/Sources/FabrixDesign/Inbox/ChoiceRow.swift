import SwiftUI

public struct ChoiceRow: View {
    public let label: String
    public let detail: String?
    public let recommendation: String?
    public let selected: Bool
    private let action: () -> Void

    public init(label: String, detail: String? = nil, recommendation: String? = nil, selected: Bool, action: @escaping () -> Void) {
        self.label = label; self.detail = detail; self.recommendation = recommendation; self.selected = selected; self.action = action
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    public nonisolated static func stacksLabel(forAccessibilitySize value: Bool) -> Bool { value }

    public var body: some View {
        Button(action: action) {
            let layout = Self.stacksLabel(forAccessibilitySize: dynamicTypeSize >= .accessibility1) ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs)) : AnyLayout(HStackLayout(spacing: Spacing.s))
            layout {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    (Self.stacksLabel(forAccessibilitySize: dynamicTypeSize >= .accessibility1) ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs)) : AnyLayout(HStackLayout(spacing: Spacing.s))) {
                        Text(verbatim: label).font(.fabrix(.body))
                        if let recommendation { Text(verbatim: recommendation).font(.fabrix(.caption)).foregroundStyle(Palette.signalInk) }
                    }
                    if let detail { Text(verbatim: detail).font(.fabrix(.subheadline)).foregroundStyle(Palette.muted) }
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Palette.signal : Palette.steel).accessibilityHidden(true)
            }
            .foregroundStyle(Palette.graphite).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityValue(Text(selected ? String(localized: "Selected", bundle: .module) : String(localized: "Not selected", bundle: .module)))
    }
}

#Preview("Choice light") { ChoiceRow(label: "Option A", detail: "A useful detail", recommendation: "Recommended", selected: true, action: {}).padding().background(Palette.paper) }
#Preview("Choice dark") { ChoiceRow(label: "Option A", detail: "A useful detail", recommendation: "Recommended", selected: true, action: {}).padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Choice accessibility") { ChoiceRow(label: "Option A", detail: "A useful detail", recommendation: "Recommended", selected: true, action: {}).padding().dynamicTypeSize(.accessibility3) }
