import SwiftUI

/// A bordered surface for grouping content: metric tiles, sections, decisions.
public struct Card<Content: View>: View {
    public enum Style: Sendable {
        /// White card with a hairline border.
        case standard
        /// Dark card that stays dark in both modes, e.g. the current run.
        case inverse
    }

    private let style: Style
    private let padding: CGFloat
    private let content: Content

    public init(style: Style = .standard, padding: CGFloat = Spacing.l, @ViewBuilder content: () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(style == .inverse ? Palette.onInverse : Palette.graphite)
            .background(style == .inverse ? Palette.inverseSurface : Palette.card, in: shape)
            .overlay {
                if style == .standard {
                    shape.strokeBorder(Palette.hairline)
                }
            }
    }
}

/// A heading for a group of content.
public struct SectionHeader: View {
    public enum Style: Sendable {
        /// Card heading: "Live runs", optionally with a trailing link.
        case card
        /// Small uppercase label: "FACTORIES".
        case eyebrow
    }

    private let title: String
    private let style: Style
    private let action: (title: String, perform: () -> Void)?

    public init(_ title: String, style: Style = .card) {
        self.title = title
        self.style = style
        action = nil
    }

    public init(_ title: String, actionTitle: String, action: @escaping () -> Void) {
        self.title = title
        style = .card
        self.action = (actionTitle, action)
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            switch style {
            case .card:
                Text(title)
                    .font(.fabrix(.headline))
                    .foregroundStyle(Palette.graphite)
            case .eyebrow:
                Text(title.uppercased())
                    .font(.fabrix(.eyebrow))
                    .tracking(0.66)
                    .foregroundStyle(Palette.muted)
            }
            Spacer(minLength: Spacing.s)
            if let action {
                Button(action.title, action: action.perform)
                    .buttonStyle(.plain)
                    .font(.fabrix(.link))
                    .foregroundStyle(Palette.signal)
                    .frame(minHeight: minimumTapTarget)
                    .contentShape(Rectangle())
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A headline number with a caption: "Agents working 4 / 7".
public struct MetricCard<Footer: View>: View {
    private let title: String
    private let value: String
    private let total: String?
    private let emphasis: Bool
    private let footer: Footer

    /// - Parameters:
    ///   - total: Shown muted after the value, e.g. "/ 7".
    ///   - emphasis: Colors the value signal orange. Use only for things waiting on a human.
    public init(
        _ title: String, value: String, total: String? = nil, emphasis: Bool = false,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.value = value
        self.total = total
        self.emphasis = emphasis
        self.footer = footer()
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.fabrix(.subheadline))
                    .foregroundStyle(Palette.steel)
                valueText
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                footer
                    .font(.fabrix(.caption))
                    .foregroundStyle(Palette.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var valueText: Text {
        let number = Text(value)
            .font(.fabrix(.metric))
            .foregroundStyle(emphasis ? Palette.signal : Palette.graphite)
        guard let total else { return number }
        let suffix = Text(" \(total)")
            .font(.fabrix(.title))
            .foregroundStyle(Palette.muted)
        return Text("\(number)\(suffix)")
    }
}

public extension MetricCard where Footer == Text {
    init(_ title: String, value: String, total: String? = nil, detail: String, emphasis: Bool = false) {
        self.init(title, value: value, total: total, emphasis: emphasis) { Text(detail) }
    }
}

#Preview("Containers") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Factories", style: .eyebrow)
            MetricCard("Agents working", value: "4", total: "/ 7", detail: "2 idle · 1 paused")
            MetricCard("Waiting on you", value: "3", detail: "1 hire · 1 strategy · 1 budget", emphasis: true)
            MetricCard("Spend this month", value: "$412", total: "/ $1,000") {
                BudgetBar(spent: 412, limit: 1000, height: 6)
            }
            Card {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader("Live runs", actionTitle: "All runs") {}
                    Text("CTO · ATL-142").font(.fabrix(.body))
                }
            }
            Card(style: .inverse) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("ATL-151").font(.fabrix(.monoCaption)).foregroundStyle(Palette.onInverseMuted)
                    Text("Offline cache for task list").font(.fabrix(.headline))
                }
            }
        }
        .padding()
    }
    .background(Palette.paper)
}
