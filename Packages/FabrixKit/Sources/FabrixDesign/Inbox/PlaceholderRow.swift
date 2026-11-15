import SwiftUI

/// A skeleton in the shape of `InboxRow`, for the first load. It pulses, or stays still with Reduce Motion.
public struct PlaceholderRow: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            bar(width: 120, height: 12)
            bar(width: 240, height: 16)
            bar(width: 180, height: 12)
            bar(width: 80, height: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.m)
        .padding(.horizontal, Spacing.l)
        .fabrixPulse()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Loading", bundle: .module))
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Radius.tag, style: .continuous)
            .fill(Palette.rail)
            .frame(maxWidth: width, minHeight: height, maxHeight: height)
    }
}

private struct PlaceholderRowPreview: View {
    var body: some View {
        VStack(spacing: 0) {
            PlaceholderRow()
            Divider()
            PlaceholderRow()
        }
        .background(Palette.card)
    }
}

#Preview("PlaceholderRow") { PlaceholderRowPreview() }

#Preview("PlaceholderRow · dark") { PlaceholderRowPreview().preferredColorScheme(.dark) }

#Preview("PlaceholderRow · accessibility") { PlaceholderRowPreview().dynamicTypeSize(.accessibility3) }
