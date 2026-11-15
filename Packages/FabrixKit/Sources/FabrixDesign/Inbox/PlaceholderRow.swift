import SwiftUI

/// Static loading placeholder shaped like an inbox row.
public struct PlaceholderRow: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            skeleton(width: 92, height: 14)
            skeleton(width: 210, height: 20)
            skeleton(width: 160, height: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Loading", bundle: .module))
    }

    private func skeleton(width: CGFloat, height: CGFloat) -> some View {
        Capsule().fill(Palette.neutralTint).frame(width: width, height: height)
    }
}

#Preview("Placeholder light") { PlaceholderRow().background(Palette.paper).preferredColorScheme(.light) }
#Preview("Placeholder dark") { PlaceholderRow().background(Palette.paper).preferredColorScheme(.dark) }
#Preview("Placeholder accessibility") { PlaceholderRow().dynamicTypeSize(.accessibility3).background(Palette.paper) }
