import SwiftUI

public enum ReasonFieldValidation: Equatable, Sendable {
    case valid
    case required
    case tooLong

    public static func validate(_ text: String, required: Bool) -> Self {
        if text.count > 4_000 { return .tooLong }
        if required && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .required }
        return .valid
    }
}

public struct ReasonField: View {
    @Binding private var text: String
    private let audience: String
    private let required: Bool

    public init(text: Binding<String>, audience: String, required: Bool) {
        _text = text
        self.audience = audience
        self.required = required
    }

    private var validation: ReasonFieldValidation { .validate(text, required: required) }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xs) {
                Text(audience).font(.fabrix(.subheadline)).foregroundStyle(Palette.steel)
                if required { Text(String(localized: "Required", bundle: .module)).font(.fabrix(.caption)).foregroundStyle(Palette.steel) }
            }
            TextEditor(text: $text)
                .font(.fabrix(.body))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 112)
                .background(Palette.card, in: .rect(cornerRadius: Radius.row))
                .overlay(RoundedRectangle(cornerRadius: Radius.row).strokeBorder(validation == .valid ? Palette.hairline : Palette.signal))
                .accessibilityLabel(audience)
            if let message = errorMessage {
                Text(message).font(.fabrix(.caption)).foregroundStyle(Palette.signal)
            }
        }
    }

    private var errorMessage: String? {
        switch validation {
        case .valid: nil
        case .required: String(localized: "Enter a reason.", bundle: .module)
        case .tooLong: String(localized: "Reason must be 4,000 characters or fewer.", bundle: .module)
        }
    }
}

private struct ReasonFieldPreview: View {
    @State private var text = "Please clarify the delivery timeline."
    var body: some View { ReasonField(text: $text, audience: "Visible to the requester", required: true).padding().background(Palette.paper) }
}

#Preview("Reason · light") { ReasonFieldPreview() }
#Preview("Reason · dark") { ReasonFieldPreview().preferredColorScheme(.dark) }
#Preview("Reason · accessibility") { ReasonFieldPreview().dynamicTypeSize(.accessibility3) }
