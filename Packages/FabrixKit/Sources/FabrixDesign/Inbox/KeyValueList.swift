import SwiftUI

public struct KeyValueList: View {
    public struct Entry: Identifiable, Hashable {
        public let label: String
        public let value: String
        public var id: String { label + "\u{0}" + value }

        public init(label: String, value: String) {
            self.label = label
            self.value = value
        }
    }

    private let entries: [Entry]
    private let rawJSON: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var isAccessibilitySize: Bool { Self.stacksAtAccessibilitySize(dynamicTypeSize) }

    public init(entries: [Entry], rawJSON: String? = nil) {
        self.entries = entries
        self.rawJSON = rawJSON
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                Group {
                    if isAccessibilitySize {
                        VStack(alignment: .leading, spacing: Spacing.xs) { label(entry.label); value(entry.value) }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.m) { label(entry.label).frame(minWidth: 96, alignment: .leading); value(entry.value) }
                    }
                }
            }
            if let rawJSON {
                DisclosureGroup {
                    Text(verbatim: rawJSON).font(.fabrix(.caption)).textSelection(.enabled)
                } label: {
                    Text("Raw JSON", bundle: .module).font(.fabrix(.subheadline))
                }
            }
        }
    }

    @ViewBuilder private func label(_ text: String) -> some View {
        Text(verbatim: text).font(.fabrix(.caption)).foregroundStyle(Palette.muted)
    }
    @ViewBuilder private func value(_ text: String) -> some View {
        Text(verbatim: text).font(.fabrix(.body)).foregroundStyle(Palette.graphite).textSelection(.enabled)
    }

    nonisolated static func stacksAtAccessibilitySize(_ size: DynamicTypeSize) -> Bool {
        size >= .accessibility1
    }
}

#Preview("Key values light") { KeyValueList(entries: [.init(label: "Status", value: "Pending"), .init(label: "Owner", value: "Alex")], rawJSON: "{\n  \"status\": \"pending\"\n}").padding().background(Palette.paper).preferredColorScheme(.light) }
#Preview("Key values dark") { KeyValueList(entries: [.init(label: "Status", value: "Pending"), .init(label: "Owner", value: "Alex")], rawJSON: "{\"status\":\"pending\"}").padding().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Key values accessibility") { KeyValueList(entries: [.init(label: "Status", value: "Pending")], rawJSON: "{}").padding().dynamicTypeSize(.accessibility3) }
