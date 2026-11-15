import SwiftUI

public struct CountedPicker<ID: Hashable>: View {
    public struct Item: Identifiable {
        public let id: ID
        public let title: String
        public let count: Int
        public init(id: ID, title: String, count: Int) { self.id = id; self.title = title; self.count = count }
    }

    private let options: [Item]
    @Binding private var selection: ID
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(options: [Item], selection: Binding<ID>) { self.options = options; self._selection = selection }

    nonisolated static func countedPickerStyle(forAccessibilitySize isAccessibilitySize: Bool) -> Bool { isAccessibilitySize }
    nonisolated static func hidesZeroCount(_ count: Int) -> Bool { count > 0 }
    private var useMenu: Bool { Self.countedPickerStyle(forAccessibilitySize: dynamicTypeSize >= .accessibility1) }

    public var body: some View {
        Group {
            if useMenu {
                Picker(selection: $selection) { choices } label: { selectedLabel }
                    .pickerStyle(.menu)
            } else {
                Picker("", selection: $selection) { choices }
                    .pickerStyle(.segmented)
                    .labelsHidden()
            }
        }
    }

    @ViewBuilder private var choices: some View {
        ForEach(options) { option in
            choiceLabel(option).tag(option.id)
        }
    }

    @ViewBuilder private var selectedLabel: some View {
        if let option = options.first(where: { $0.id == selection }) { choiceLabel(option) }
    }

    private func choiceLabel(_ option: Item) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(verbatim: option.title)
            if Self.hidesZeroCount(option.count) { Text(verbatim: String(option.count)).foregroundStyle(Palette.muted) }
        }
    }
}

#Preview("Counted picker light") { CountedPicker<UUID>(options: [.init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, title: "All", count: 8), .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, title: "Mine", count: 0)], selection: .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)).padding().preferredColorScheme(.light) }
#Preview("Counted picker dark") { CountedPicker<UUID>(options: [.init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, title: "All", count: 8), .init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, title: "Mine", count: 0)], selection: .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)).padding().preferredColorScheme(.dark) }
#Preview("Counted picker accessibility") { CountedPicker<UUID>(options: [.init(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, title: "All", count: 8)], selection: .constant(UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)).dynamicTypeSize(.accessibility3).padding() }
