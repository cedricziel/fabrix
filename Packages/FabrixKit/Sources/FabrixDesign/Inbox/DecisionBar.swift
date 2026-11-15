import SwiftUI

/// A button on the decision bar.
public struct DecisionBarAction {
    public let title: String
    public let role: ButtonRole?
    public let isEnabled: Bool
    public let shortcut: KeyHint.Chord?
    public let perform: () -> Void

    /// - Parameters:
    ///   - role: `.destructive` for Reject.
    ///   - isEnabled: `false` while this one action can't be taken, such as Submit before every verdict is chosen.
    ///   - shortcut: shown as a key cap and read as a hint to VoiceOver.
    public init(
        _ title: String, role: ButtonRole? = nil, isEnabled: Bool = true, shortcut: KeyHint.Chord? = nil,
        perform: @escaping () -> Void
    ) {
        self.title = title
        self.role = role
        self.isEnabled = isEnabled
        self.shortcut = shortcut
        self.perform = perform
    }
}

/// Primary, secondary and tertiary decision buttons with a status line. Buttons sit in a row, or stack at
/// accessibility text sizes. It can be disabled with a reason, which it shows as text.
public struct DecisionBar: View {
    private let primary: DecisionBarAction
    private let secondary: DecisionBarAction?
    private let tertiary: DecisionBarAction?
    private let status: String?
    private let disabledReason: String?
    private let isSending: Bool

    /// - Parameters:
    ///   - disabledReason: why the buttons are off, such as "You're offline". It replaces the status.
    public init(
        primary: DecisionBarAction, secondary: DecisionBarAction? = nil, tertiary: DecisionBarAction? = nil,
        status: String? = nil, disabledReason: String? = nil, isSending: Bool = false
    ) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
        self.status = status
        self.disabledReason = disabledReason
        self.isSending = isSending
    }

    nonisolated static func isDisabled(disabledReason: String?, isSending: Bool) -> Bool {
        disabledReason != nil || isSending
    }

    nonisolated static func isDisabled(_ action: DecisionBarAction, disabledReason: String?, isSending: Bool) -> Bool {
        !action.isEnabled || isDisabled(disabledReason: disabledReason, isSending: isSending)
    }

    nonisolated static func statusLine(status: String?, disabledReason: String?, isSending: Bool) -> String? {
        disabledReason ?? (isSending ? String(localized: "Sending…", bundle: .module) : status)
    }

    @Environment(\.dynamicTypeSize) private var typeSize

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let line = Self.statusLine(status: status, disabledReason: disabledReason, isSending: isSending) {
                Label {
                    Text(verbatim: line)
                } icon: {
                    if isSending { ProgressView().controlSize(.small) } else if disabledReason != nil {
                        Image(systemName: "exclamationmark.circle")
                    }
                }
                .font(.fabrix(.caption))
                .foregroundStyle(Palette.steel)
            }
            AdaptiveStack(spacing: Spacing.s, rowAlignment: .center) {
                if let tertiary {
                    button(tertiary)
                        .buttonStyle(.borderless)
                        .font(.fabrix(.headline))
                        .foregroundStyle(Palette.steel)
                        .frame(minHeight: minimumTapTarget)
                }
                if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                if let secondary { button(secondary).buttonStyle(.fabrixSecondary) }
                button(primary).buttonStyle(.fabrixPrimary)
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.chrome)
        .overlay(alignment: .top) { Divider().overlay(Palette.hairline) }
    }

    private func button(_ action: DecisionBarAction) -> some View {
        Button(role: action.role, action: action.perform) {
            HStack(spacing: Spacing.xs) {
                Text(verbatim: action.title)
                if let shortcut = action.shortcut { KeyHint(shortcut).accessibilityHidden(true) }
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(Self.isDisabled(action, disabledReason: disabledReason, isSending: isSending))
        .accessibilityHint(action.shortcut.map { Text(verbatim: $0.spoken) } ?? Text(verbatim: ""))
    }
}

private struct DecisionBarPreview: View {
    var body: some View {
        VStack(spacing: Spacing.l) {
            DecisionBar(
                primary: .init("Approve", shortcut: .init("↩", modifiers: [.command])) {},
                secondary: .init("Reject", role: .destructive, shortcut: .init("⌫", modifiers: [.command])) {},
                tertiary: .init("Request revision") {}, status: "Waiting on you"
            )
            DecisionBar(primary: .init("Submit", isEnabled: false) {}, secondary: .init("Reject", role: .destructive) {}, disabledReason: "You're offline")
            DecisionBar(primary: .init("Approve") {}, secondary: .init("Reject") {}, isSending: true)
        }
        .background(Palette.paper)
    }
}

#Preview("DecisionBar") { DecisionBarPreview() }

#Preview("DecisionBar · dark") { DecisionBarPreview().preferredColorScheme(.dark) }

#Preview("DecisionBar · accessibility") { ScrollView { DecisionBarPreview() }.dynamicTypeSize(.accessibility3) }
