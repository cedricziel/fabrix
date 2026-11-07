import SwiftUI

/// A plain text field on a card-colored, hairline-bordered rounded rectangle.
/// Applies to `SecureField` too.
public struct FabrixTextFieldStyle: TextFieldStyle {
    public init() {}

    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(10)
            .background(Palette.card, in: .rect(cornerRadius: Radius.row))
            .overlay(RoundedRectangle(cornerRadius: Radius.row).strokeBorder(Palette.hairline))
    }
}

public extension TextFieldStyle where Self == FabrixTextFieldStyle {
    static var fabrix: FabrixTextFieldStyle { FabrixTextFieldStyle() }
}

/// A small caption above a form field: "Factory address".
public struct FieldTitle: View {
    private let title: LocalizedStringResource

    public init(_ title: LocalizedStringResource) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.steel)
    }
}

/// A field with its title above it, styled with `FabrixTextFieldStyle`.
public struct LabeledField<Field: View>: View {
    private let title: LocalizedStringResource
    private let field: Field

    public init(_ title: LocalizedStringResource, @ViewBuilder field: () -> Field) {
        self.title = title
        self.field = field()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldTitle(title)
            field.textFieldStyle(.fabrix)
        }
    }
}

private struct FieldsPreview: View {
    @State private var address = ""
    @State private var key = "secret"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            LabeledField("Factory address") {
                TextField("https://factory.example.com", text: $address)
            }
            LabeledField("Paperclip API key") {
                SecureField("Paste the key from your Paperclip board", text: $key)
            }
            LabeledField("Disabled") {
                TextField("Not editable", text: .constant("fabrix"))
            }
            .disabled(true)
        }
        .padding()
        .background(Palette.paper)
    }
}

#Preview("Fields") { FieldsPreview() }

#Preview("Fields · dark") { FieldsPreview().preferredColorScheme(.dark) }
