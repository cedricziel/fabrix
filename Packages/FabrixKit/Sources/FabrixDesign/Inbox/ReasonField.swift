import SwiftUI

public enum ReasonValidation: Equatable, Sendable {
    case valid
    case missing
    case tooLong(excess: Int)

    nonisolated var message: String? {
        switch self {
        case .valid: nil
        case .missing: String(localized: "Add a reason.", bundle: .module)
        case let .tooLong(excess): String(localized: "\(excess) characters too long.", bundle: .module)
        }
    }
}

/// A multiline field for a reason or note. It says who reads the text, whether it is required, and when it is too long.
public struct ReasonField: View {
    static let limit = 4000

    private let title: LocalizedStringResource
    private let reader: String
    private let isRequired: Bool
    @Binding private var text: String
    @State private var hasEdited = false

    /// - Parameters:
    ///   - reader: who reads the text, such as "the CEO agent".
    public init(
        _ title: LocalizedStringResource, reader: String, isRequired: Bool, text: Binding<String>
    ) {
        self.title = title
        self.reader = reader
        self.isRequired = isRequired
        _text = text
    }

    public init(reader: String, isRequired: Bool, text: Binding<String>) {
        self.init(LocalizedStringResource("Reason", bundle: .module), reader: reader, isRequired: isRequired, text: text)
    }

    nonisolated static func validate(_ text: String, isRequired: Bool) -> ReasonValidation {
        if text.count > limit { return .tooLong(excess: text.count - limit) }
        if isRequired, text.allSatisfy(\.isWhitespace) { return .missing }
        return .valid
    }

    nonisolated static func hint(reader: String) -> String {
        String(localized: "Read by \(reader).", bundle: .module)
    }

    nonisolated static func requirementText(isRequired: Bool) -> String {
        isRequired ? String(localized: "Required", bundle: .module) : String(localized: "Optional", bundle: .module)
    }

    private var validation: ReasonValidation {
        let result = Self.validate(text, isRequired: isRequired)
        return result == .missing && !hasEdited ? .valid : result
    }

    public var body: some View {
        let hint = Self.hint(reader: reader)
        let validation = validation
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                FieldTitle(title)
                Spacer(minLength: Spacing.s)
                Text(verbatim: Self.requirementText(isRequired: isRequired))
                    .font(.fabrix(.caption))
                    .foregroundStyle(isRequired ? Palette.signalInk : Palette.muted)
            }
            TextField(text: $text, axis: .vertical) { Text(title) }
                .textFieldStyle(.fabrix)
                .lineLimit(3...8)
                .onChange(of: text) { if !hasEdited { hasEdited = true } }
                .accessibilityHint(Text(verbatim: hint))
            Text(verbatim: hint)
                .font(.fabrix(.caption))
                .foregroundStyle(Palette.muted)
                .accessibilityHidden(true)
            if let message = validation.message {
                Label { Text(verbatim: message) } icon: { Image(systemName: "exclamationmark.circle.fill") }
                    .font(.fabrix(.caption))
                    .foregroundStyle(Palette.haltInk)
            }
        }
    }
}

private struct ReasonFieldPreview: View {
    @State private var empty = ""
    @State private var filled = "The budget is already spent."
    @State private var long = String(repeating: "a", count: 4012)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                ReasonField(reader: "the CEO agent", isRequired: true, text: $empty)
                ReasonField(reader: "the CEO agent", isRequired: false, text: $filled)
                ReasonField(reader: "the board", isRequired: false, text: $long)
            }
            .padding()
        }
        .background(Palette.paper)
    }
}

#Preview("ReasonField") { ReasonFieldPreview() }

#Preview("ReasonField · dark") { ReasonFieldPreview().preferredColorScheme(.dark) }

#Preview("ReasonField · accessibility") { ReasonFieldPreview().dynamicTypeSize(.accessibility3) }
