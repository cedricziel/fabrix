import FabrixDesign
import SwiftUI

// Colors the Foundations board uses that Palette doesn't name yet. Delete this file once
// FabrixDesign adds them; the compiler then points at every call site.
extension Palette {
    static let idle = Color(red: 0.631, green: 0.631, blue: 0.667)
    static let review = Color(red: 0.427, green: 0.157, blue: 0.851)
    static let connector = Color(red: 0.788, green: 0.773, blue: 0.733)
    static let signalInk = Color(red: 0.604, green: 0.204, blue: 0.071)
    static let signalTint = Color(red: 1, green: 0.929, blue: 0.835)
    static let doneInk = Color(red: 0.078, green: 0.325, blue: 0.176)
    static let doneTint = Color(red: 0.863, green: 0.988, blue: 0.906)
}

extension View {
    /// Palette has no dark variants yet, so the app stays light until FabrixDesign adapts.
    func lightUntilPaletteAdapts() -> some View {
        preferredColorScheme(.light)
    }
}

extension Binding {
    /// Shows a presentation while an optional selection is set; dismissing clears it.
    func isPresent<Wrapped: Sendable>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool> { wrappedValue != nil } set: { if !$0 { wrappedValue = nil } }
    }
}
