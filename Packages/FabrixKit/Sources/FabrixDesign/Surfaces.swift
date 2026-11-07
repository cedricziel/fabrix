import SwiftUI

/// A card with a heading and rows below a divider: "Live runs", "Activity".
public struct SectionCard<Content: View>: View {
    private let title: LocalizedStringResource
    private let action: (title: LocalizedStringResource, perform: () -> Void)?
    private let content: Content

    public init(_ title: LocalizedStringResource, @ViewBuilder content: () -> Content) {
        self.title = title
        action = nil
        self.content = content()
    }

    public init(
        _ title: LocalizedStringResource,
        actionTitle: LocalizedStringResource,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.action = (actionTitle, action)
        self.content = content()
    }

    public var body: some View {
        Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Group {
                    if let action {
                        SectionHeader(title, actionTitle: action.title, action: action.perform)
                    } else {
                        SectionHeader(title)
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
                Divider().overlay(Palette.divider)
                content
            }
        }
    }
}

/// The muted line a section card shows when it has nothing to list.
public struct EmptyRow: View {
    private let text: LocalizedStringResource

    public init(_ text: LocalizedStringResource) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .foregroundStyle(Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.l)
    }
}

public extension View {
    /// Puts content on the standard card surface, full width, with the selection
    /// outline when `selected` is true: task cards, org chart nodes, banners.
    func fabrixCard(selected: Bool = false) -> some View {
        Card(padding: 0) { self }
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Palette.signal, lineWidth: 2)
                }
            }
    }
}

#Preview("Surfaces") {
    @Previewable @State var selected = true
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionCard("Live runs", actionTitle: "All runs", action: {}) {
                Text("CTO · ATL-142").padding(Spacing.l)
            }
            SectionCard("Needs your decision") {
                EmptyRow("Nothing is waiting on you.")
            }
            Text("Unselected card").padding(Spacing.m).fabrixCard()
            Text("Selected card · tap to toggle")
                .padding(Spacing.m)
                .fabrixCard(selected: selected)
                .onTapGesture { selected.toggle() }
        }
        .padding()
    }
    .background(Palette.paper)
}

#Preview("Surfaces · dark") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        SectionCard("Activity") { EmptyRow("No activity yet.") }
        Text("Selected card").padding(Spacing.m).fabrixCard(selected: true)
    }
    .padding()
    .background(Palette.paper)
    .preferredColorScheme(.dark)
}
