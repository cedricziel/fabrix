import SwiftUI

/// How an agent or run status looks. Status always pairs a dot shape with a
/// label, never color alone. Features map their own status models onto this.
public enum StatusStyle: CaseIterable, Sendable {
    case running, idle, paused, needsYou, blocked, done

    public enum Dot: Sendable { case filled, hollow }

    public var label: String {
        switch self {
        case .running: String(localized: "Running", bundle: .module)
        case .idle: String(localized: "Idle", bundle: .module)
        case .paused: String(localized: "Paused", bundle: .module)
        case .needsYou: String(localized: "Needs you", bundle: .module)
        case .blocked: String(localized: "Blocked", bundle: .module)
        case .done: String(localized: "Done", bundle: .module)
        }
    }

    public var dot: Dot {
        switch self {
        case .paused, .needsYou: .hollow
        default: .filled
        }
    }

    public var tone: Tone {
        switch self {
        case .running: .run
        case .idle, .paused: .neutral
        case .needsYou: .signal
        case .blocked: .halt
        case .done: .done
        }
    }

    public var dotColor: Color {
        switch self {
        case .idle: Palette.idle
        case .paused: Palette.muted
        default: tone.color
        }
    }
}

/// The status dot: filled for active states, a ring for paused and needs-you.
public struct StatusDot: View {
    private let style: StatusStyle
    @ScaledMetric private var size: CGFloat

    public init(_ style: StatusStyle, size: CGFloat = 7) {
        self.style = style
        _size = ScaledMetric(wrappedValue: size, relativeTo: .caption)
    }

    public var body: some View {
        Group {
            switch style.dot {
            case .filled: Circle().fill(style.dotColor)
            case .hollow: Circle().strokeBorder(style.dotColor, lineWidth: max(1.5, size * 0.2))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A capsule with a status dot and label, e.g. "Running · heartbeat every 5 min".
public struct StatusPill: View {
    private let style: StatusStyle
    private let text: String

    public init(_ style: StatusStyle) {
        self.init(style, verbatim: nil)
    }

    public init(_ style: StatusStyle, detail: LocalizedStringResource) {
        self.init(style, verbatim: String(localized: detail))
    }

    @_disfavoredOverload
    public init(_ style: StatusStyle, detail: String?) {
        self.init(style, verbatim: detail)
    }

    private init(_ style: StatusStyle, verbatim detail: String?) {
        self.style = style
        text = [style.label, detail].compactMap(\.self).joined(separator: " · ")
    }

    /// The style's look with another label, for statuses of other things (projects).
    public init(_ style: StatusStyle, title: String) {
        self.style = style
        text = title
    }

    public var body: some View {
        Pill(verbatim: text, tone: style.tone) { StatusDot(style) }
    }
}

#Preview("Status") {
    VStack(alignment: .leading, spacing: Spacing.s) {
        ForEach(StatusStyle.allCases, id: \.self) { StatusPill($0) }
        StatusPill(.done, detail: .preview("heartbeat every 5 min"))
        HStack { ForEach(StatusStyle.allCases, id: \.self) { StatusDot($0, size: 8) } }
    }
    .padding()
    .background(Palette.paper)
}
