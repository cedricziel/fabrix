import Foundation

extension LocalizedStringResource {
    /// Copy that only appears in Xcode previews. It's built from a runtime string, so
    /// string extraction skips it and it stays out of the catalog.
    static func preview(_ text: String) -> LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(text))
    }
}
