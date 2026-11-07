import SwiftUI

/// The app icon's mark, drawn from the same path as `scripts/render-app-icons.swift`.
public struct FabrixMark: View {
    private let size: CGFloat

    public init(size: CGFloat = 72) {
        self.size = size
    }

    public var body: some View {
        Canvas { context, canvas in
            let unit = canvas.width / 56
            context.scaleBy(x: unit, y: unit)
            context.fill(Path(CGRect(x: 0, y: 0, width: 56, height: 56)), with: .color(Color(hex: 0x18181B)))

            var stroke = Path()
            stroke.move(to: CGPoint(x: 20, y: 38))
            stroke.addLine(to: CGPoint(x: 20, y: 22))
            stroke.addArc(center: CGPoint(x: 26, y: 22), radius: 6, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            stroke.addLine(to: CGPoint(x: 32, y: 34))
            stroke.addArc(center: CGPoint(x: 35, y: 34), radius: 3, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            stroke.addLine(to: CGPoint(x: 38, y: 20))
            context.stroke(stroke, with: .color(.white), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

            context.fill(Path(ellipseIn: CGRect(x: 34.5, y: 12.5, width: 7, height: 7)), with: .color(Palette.signal))
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.225, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// The mark and app name on the paper background, with optional content below.
/// Covers the app while it is locked or inactive.
public struct BrandCover<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content = { EmptyView() }) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: Spacing.l) {
            FabrixMark()
            Text(verbatim: "Fabrix").font(.fabrix(.title))
            content
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper)
        .foregroundStyle(Palette.graphite)
    }
}

#Preview { BrandCover() }
