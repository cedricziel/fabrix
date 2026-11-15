import SwiftUI

/// One row of an approval's payload.
public struct KeyValueItem: Identifiable, Sendable {
    public let id: Int
    let label: String
    let value: String
    let isMono: Bool

    public init(id: Int, label: String, value: String, isMono: Bool = false) {
        self.id = id
        self.label = label
        self.value = value
        self.isMono = isMono
    }
}

/// A payload as label and value rows, values optionally mono, with a disclosure for the raw JSON.
/// Label and value stack at accessibility text sizes.
public struct KeyValueList: View {
    private let items: [KeyValueItem]
    private let rawJSON: String?
    @State private var showsRaw: Bool
    @Environment(\.dynamicTypeSize) private var typeSize

    public init(items: [KeyValueItem], rawJSON: String? = nil, showsRaw: Bool = false) {
        self.items = items
        self.rawJSON = rawJSON
        _showsRaw = State(initialValue: showsRaw)
    }

    nonisolated static func stacks(forAccessibilitySize isAccessibilitySize: Bool) -> Bool {
        isAccessibilitySize
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { item in
                row(item)
                Divider().overlay(Palette.divider)
            }
            if let rawJSON {
                DisclosureGroup(isExpanded: $showsRaw) {
                    Text(verbatim: rawJSON)
                        .font(.fabrix(.monoCaption))
                        .foregroundStyle(Palette.steel)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.s)
                } label: {
                    Text("Raw JSON", bundle: .module)
                        .font(.fabrix(.subheadline))
                        .foregroundStyle(Palette.steel)
                }
                .padding(.vertical, Spacing.s)
            }
        }
    }

    private func row(_ item: KeyValueItem) -> some View {
        let layout = Self.stacks(forAccessibilitySize: typeSize.isAccessibilitySize)
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.m))
        return layout {
            Text(verbatim: item.label)
                .font(.fabrix(.caption))
                .foregroundStyle(Palette.muted)
                .frame(minWidth: 96, alignment: .leading)
            Text(verbatim: item.value)
                .font(.fabrix(item.isMono ? .mono : .body))
                .foregroundStyle(Palette.graphite)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.s)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: item.label))
        .accessibilityValue(Text(verbatim: item.value))
    }
}

private struct KeyValueListPreview: View {
    var body: some View {
        KeyValueList(
            items: [
                .init(id: 0, label: "Role", value: "Designer"),
                .init(id: 1, label: "Adapter", value: "claude-code", isMono: true),
                .init(id: 2, label: "Monthly budget", value: "$40.00", isMono: true),
                .init(id: 3, label: "Reports to", value: "CEO"),
            ],
            rawJSON: "{\n  \"role\": \"Designer\"\n}"
        )
        .padding()
        .background(Palette.card)
    }
}

#Preview("KeyValueList") { KeyValueListPreview() }

#Preview("KeyValueList · dark") { KeyValueListPreview().preferredColorScheme(.dark) }

#Preview("KeyValueList · accessibility") { KeyValueListPreview().dynamicTypeSize(.accessibility3) }
