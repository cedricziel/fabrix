import Foundation

extension LocalizedStringResource {
    /// A string from the FabrixFeatures catalog. A bare literal resolves against the
    /// app's main bundle instead, so feature copy passed to Design components goes
    /// through here. Xcode still extracts the literal.
    static func features(_ value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(value, bundle: .module)
    }
}
