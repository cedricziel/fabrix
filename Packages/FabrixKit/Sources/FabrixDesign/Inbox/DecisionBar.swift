import SwiftUI

/// An action displayed in an inbox decision bar.
public struct DecisionBarAction: Identifiable {
    public let id: String
    public let label: String
    public let style: DecisionBarActionStyle
    public let action: () -> Void

    public init(id: String, label: String, style: DecisionBarActionStyle = .secondary, action: @escaping () -> Void) {
        self.id = id
        self.label = label
        self.style = style
        self.action = action
    }
}

public enum DecisionBarActionStyle {
    case primary
    case secondary
    case signal
}

/// A reusable row of decision actions, with an optional visible explanation when unavailable.
public struct DecisionBar: View {
    public let actions: [DecisionBarAction]
    public let disabledReason: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(actions: [DecisionBarAction], disabledReason: String? = nil) {
        self.actions = actions
        self.disabledReason = disabledReason
    }

    nonisolated static func actionsEnabled(disabledReason: String?) -> Bool { disabledReason == nil }

    nonisolated static func decisionBarDisabledReason(_ reason: String?) -> String? { reason }
    nonisolated static func stacksAtAccessibilitySize(_ size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Group {
                if Self.stacksAtAccessibilitySize(dynamicTypeSize) {
                    VStack(spacing: Spacing.s) { buttons }
                } else {
                    HStack(spacing: Spacing.s) { buttons }
                }
            }
            .frame(maxWidth: .infinity)
            if let reason = Self.decisionBarDisabledReason(disabledReason) {
                Text(reason)
                    .font(.fabrix(.caption))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(reason)
            }
        }
        .padding(Spacing.m)
        .background(Palette.card)
    }

    @ViewBuilder private var buttons: some View {
        ForEach(actions) { action in
            Button(action.label, action: action.action)
                .modifier(DecisionBarButtonStyle(style: action.style))
                .frame(maxWidth: .infinity)
                .disabled(!Self.actionsEnabled(disabledReason: disabledReason))
        }
    }


}

#Preview("Decision bar · light") { DecisionBar(actions: [.init(id: "reject", label: "Reject") { }, .init(id: "approve", label: "Approve", style: .primary) { }]).padding().preferredColorScheme(.light) }
#Preview("Decision bar · dark") { DecisionBar(actions: [.init(id: "reject", label: "Reject") { }, .init(id: "approve", label: "Approve", style: .primary) { }]).padding().preferredColorScheme(.dark) }
#Preview("Decision bar · accessibility") { DecisionBar(actions: [.init(id: "reject", label: "Reject") { }, .init(id: "approve", label: "Approve", style: .primary) { }], disabledReason: "Complete the required fields first.").padding().dynamicTypeSize(.accessibility3) }

private struct DecisionBarButtonStyle: ViewModifier {
    let style: DecisionBarActionStyle
    @ViewBuilder func body(content: Content) -> some View {
        switch style {
        case .primary: content.buttonStyle(.fabrixPrimary)
        case .secondary: content.buttonStyle(.fabrixSecondary)
        case .signal: content.buttonStyle(.fabrixSignal)
        }
    }
}
