import SwiftUI

public enum VerdictChoice: String, CaseIterable, Hashable, Sendable {
    case approve, reject
    case deferVerdict = "defer"

    public var title: String {
        switch self {
        case .approve: String(localized: "Approve", bundle: .module)
        case .reject: String(localized: "Reject", bundle: .module)
        case .deferVerdict: String(localized: "Defer", bundle: .module)
        }
    }
}

public struct VerdictPicker: View {
    @Binding private var selection: VerdictChoice?
    @Binding private var reason: String
    private let reasonRequiredFor: Set<VerdictChoice>
    private let audience: String

    public init(selection: Binding<VerdictChoice?>, reasonRequiredFor: Set<VerdictChoice>, reason: Binding<String>, audience: String) {
        _selection = selection; _reason = reason; self.reasonRequiredFor = reasonRequiredFor; self.audience = audience
    }

    public nonisolated static func requiresReason(for verdict: VerdictChoice?, requiredFor: Set<VerdictChoice>) -> Bool {
        guard let verdict else { return false }
        return requiredFor.contains(verdict)
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public nonisolated static func usesMenu(forAccessibilitySize value: Bool) -> Bool { value }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            let picker = Picker(String(localized: "Verdict", bundle: .module), selection: $selection) {
                Text(String(localized: "Choose a verdict", bundle: .module)).tag(nil as VerdictChoice?)
                ForEach(VerdictChoice.allCases, id: \.self) { verdict in Text(verdict.title).tag(verdict as VerdictChoice?) }
            }
            if Self.usesMenu(forAccessibilitySize: dynamicTypeSize >= .accessibility1) {
                picker.pickerStyle(.menu)
            } else {
                picker.pickerStyle(.segmented)
            }
            if Self.requiresReason(for: selection, requiredFor: reasonRequiredFor) {
                ReasonField(text: $reason, audience: audience, required: true)
            }
        }
    }
}

private struct VerdictPickerPreview: View {
    @State var selection: VerdictChoice? = .reject
    @State var reason = "Please revise this item."
    var body: some View { VerdictPicker(selection: $selection, reasonRequiredFor: [.reject], reason: $reason, audience: "Visible to the requester").padding().background(Palette.paper) }
}
#Preview("Verdict light") { VerdictPickerPreview() }
#Preview("Verdict dark") { VerdictPickerPreview().preferredColorScheme(.dark) }
#Preview("Verdict accessibility") { VerdictPickerPreview().dynamicTypeSize(.accessibility3) }
