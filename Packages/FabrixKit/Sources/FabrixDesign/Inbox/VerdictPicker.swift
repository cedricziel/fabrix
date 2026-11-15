import SwiftUI

public enum VerdictChoice: CaseIterable, Hashable, Sendable {
    case approve, reject, `defer`

    nonisolated var title: String {
        switch self {
        case .approve: String(localized: "Approve", bundle: .module)
        case .reject: String(localized: "Reject", bundle: .module)
        case .defer: String(localized: "Defer", bundle: .module)
        }
    }

    var symbol: String {
        switch self {
        case .approve: "checkmark"
        case .reject: "xmark"
        case .defer: "clock"
        }
    }
}

/// Approve, Reject or Defer for one item, with a reason field when the chosen verdict needs one.
public struct VerdictPicker: View {
    @Binding private var selection: VerdictChoice?
    @Binding private var reason: String
    private let requiresReasonFor: Set<VerdictChoice>
    private let reader: String

    public init(
        selection: Binding<VerdictChoice?>, reason: Binding<String>, requiresReasonFor: Set<VerdictChoice>,
        reader: String
    ) {
        _selection = selection
        _reason = reason
        self.requiresReasonFor = requiresReasonFor
        self.reader = reader
    }

    nonisolated static func requiresReason(_ verdict: VerdictChoice?, in required: Set<VerdictChoice>) -> Bool {
        verdict.map(required.contains) ?? false
    }

    nonisolated static func isComplete(verdict: VerdictChoice?, reason: String, requiredFor: Set<VerdictChoice>) -> Bool {
        guard verdict != nil else { return false }
        return ReasonField.validate(reason, isRequired: requiresReason(verdict, in: requiredFor)) == .valid
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            AdaptiveStack(spacing: Spacing.s, rowAlignment: .center) {
                ForEach(VerdictChoice.allCases, id: \.self) { choice in
                    let isOn = selection == choice
                    Button { selection = choice } label: {
                        Label(choice.title, systemImage: choice.symbol)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.fabrixSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                            .strokeBorder(Palette.graphite, lineWidth: isOn ? 2 : 0)
                    )
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            if Self.requiresReason(selection, in: requiresReasonFor) {
                ReasonField(reader: reader, isRequired: true, text: $reason)
            }
        }
    }
}

private struct VerdictPickerPreview: View {
    @State private var none: VerdictChoice?
    @State private var reject: VerdictChoice? = .reject
    @State private var reason = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VerdictPicker(selection: $none, reason: $reason, requiresReasonFor: [.reject], reader: "the CTO agent")
                VerdictPicker(selection: $reject, reason: $reason, requiresReasonFor: [.reject], reader: "the CTO agent")
            }
            .padding()
        }
        .background(Palette.paper)
    }
}

#Preview("VerdictPicker") { VerdictPickerPreview() }

#Preview("VerdictPicker · dark") { VerdictPickerPreview().preferredColorScheme(.dark) }

#Preview("VerdictPicker · accessibility") { VerdictPickerPreview().dynamicTypeSize(.accessibility3) }
