import SwiftUI

/// A button on the decision bar.
public struct DecisionBarAction {
    let title: String
    let perform: () -> Void

    public init(_ title: String, perform: @escaping () -> Void) {
        self.title = title
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

    nonisolated static func statusLine(status: String?, disabledReason: String?, isSending: Bool) -> String? {
        disabledReason ?? (isSending ? String(localized: "Sending…", bundle: .module) : status)
    }

    public var body: some View {
        let disabled = Self.isDisabled(disabledReason: disabledReason, isSending: isSending)
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
                    Button(action: tertiary.perform) { Text(verbatim: tertiary.title) }
                        .buttonStyle(.borderless)
                        .font(.fabrix(.headline))
                        .foregroundStyle(Palette.steel)
                        .frame(minHeight: minimumTapTarget)
                }
                Spacer(minLength: 0)
                if let secondary {
                    Button(action: secondary.perform) { Text(verbatim: secondary.title).frame(maxWidth: .infinity) }
                        .buttonStyle(.fabrixSecondary)
                }
                Button(action: primary.perform) { Text(verbatim: primary.title).frame(maxWidth: .infinity) }
                    .buttonStyle(.fabrixPrimary)
            }
            .disabled(disabled)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.chrome)
        .overlay(alignment: .top) { Divider().overlay(Palette.hairline) }
    }
}

private struct DecisionBarPreview: View {
    var body: some View {
        VStack(spacing: Spacing.l) {
            DecisionBar(
                primary: .init("Approve") {}, secondary: .init("Reject") {}, tertiary: .init("Request revision") {},
                status: "Waiting on you"
            )
            DecisionBar(primary: .init("Approve") {}, secondary: .init("Reject") {}, disabledReason: "You're offline")
            DecisionBar(primary: .init("Approve") {}, secondary: .init("Reject") {}, isSending: true)
        }
        .background(Palette.paper)
    }
}

#Preview("DecisionBar") { DecisionBarPreview() }

#Preview("DecisionBar · dark") { DecisionBarPreview().preferredColorScheme(.dark) }

#Preview("DecisionBar · accessibility") { ScrollView { DecisionBarPreview() }.dynamicTypeSize(.accessibility3) }
