import SwiftUI

/// Parses a project colour as Paperclip stores it (`#RRGGBB`).
enum ProjectColor {
    nonisolated static func rgb(_ hex: String?) -> UInt32? {
        guard var text = hex?.trimmingCharacters(in: .whitespaces) else { return nil }
        if text.hasPrefix("#") {
            text.removeFirst()
        }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        return value
    }

    static func color(_ hex: String?) -> Color {
        rgb(hex).map { Color(hex: $0) } ?? Palette.idle
    }
}

/// A project's colour as a rounded square. Square, so it never reads as a status dot.
public struct ProjectSwatch: View {
    private let colorHex: String?
    @ScaledMetric private var size: CGFloat

    public init(colorHex: String?, size: CGFloat = 10) {
        self.colorHex = colorHex
        _size = ScaledMetric(wrappedValue: size, relativeTo: .caption)
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            .fill(ProjectColor.color(colorHex))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// The project tag on a task card or row. The text stays neutral, so legibility never
/// depends on the project's colour.
public struct ProjectChip: View {
    private let name: String
    private let colorHex: String?

    public init(name: String, colorHex: String?) {
        self.name = name
        self.colorHex = colorHex
    }

    public var body: some View {
        HStack(spacing: 5) {
            ProjectSwatch(colorHex: colorHex, size: 8)
            Text(name).lineLimit(1)
        }
        .font(.fabrix(.label))
        .foregroundStyle(Palette.neutralInk)
        .padding(.horizontal, 7)
        .frame(minHeight: 20)
        .background(Palette.neutralTint, in: RoundedRectangle(cornerRadius: Radius.tag, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Project \(name)", bundle: .module))
    }
}

/// How a project status looks. Features map their project model onto this.
public enum ProjectStatusStyle: CaseIterable, Sendable {
    case backlog, planned, inProgress, completed, cancelled

    public var label: String {
        switch self {
        case .backlog: String(localized: "Backlog", bundle: .module)
        case .planned: String(localized: "Planned", bundle: .module)
        case .inProgress: String(localized: "In progress", bundle: .module)
        case .completed: String(localized: "Completed", bundle: .module)
        case .cancelled: String(localized: "Cancelled", bundle: .module)
        }
    }

    var tone: StatusStyle.Tone {
        switch self {
        case .backlog, .planned, .cancelled: .neutral
        case .inProgress: .run
        case .completed: .done
        }
    }

    var dotColor: Color {
        switch self {
        case .backlog, .cancelled: Palette.idle
        case .planned: Palette.steel
        case .inProgress, .completed: tone.color
        }
    }
}

public struct ProjectStatusPill: View {
    private let style: ProjectStatusStyle

    public init(_ style: ProjectStatusStyle) {
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle().fill(style.dotColor).frame(width: 7, height: 7).accessibilityHidden(true)
            Text(style.label).lineLimit(1)
        }
        .font(.fabrix(.label))
        .foregroundStyle(style.tone.ink)
        .padding(.horizontal, 10)
        .frame(minHeight: 28)
        .background(style.tone.tint, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(style.label)
    }
}

/// Done, blocked and open tasks as a bar, with the counts as text. The text carries the
/// meaning; the bar is decoration.
public struct TaskCountsBar: View {
    private let open: Int
    private let blocked: Int
    private let done: Int

    public init(open: Int, blocked: Int, done: Int) {
        self.open = open
        self.blocked = blocked
        self.done = done
    }

    /// Fractions of the bar for done, blocked and open; all zero when there are no tasks.
    nonisolated static func fractions(open: Int, blocked: Int, done: Int) -> (done: Double, blocked: Double, open: Double) {
        let total = Double(max(0, open) + max(0, blocked) + max(0, done))
        guard total > 0 else { return (0, 0, 0) }
        return (Double(max(0, done)) / total, Double(max(0, blocked)) / total, Double(max(0, open)) / total)
    }

    public var body: some View {
        let parts = Self.fractions(open: open, blocked: blocked, done: done)
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Palette.done.frame(width: proxy.size.width * parts.done)
                    Palette.halt.frame(width: proxy.size.width * parts.blocked)
                    Palette.idle.frame(width: proxy.size.width * parts.open)
                }
            }
            .frame(height: 6)
            .background(Palette.rail)
            .clipShape(Capsule())
            .accessibilityHidden(true)

            HStack(spacing: 0) {
                Text("\(open) open · ", bundle: .module)
                Text("\(blocked) blocked", bundle: .module)
                    .foregroundStyle(blocked > 0 ? Palette.haltInk : Palette.steel)
                    .fontWeight(blocked > 0 ? .semibold : .regular)
                Text(" · \(done) done", bundle: .module)
            }
            .font(.fabrix(.caption))
            .foregroundStyle(Palette.steel)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Projects") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        HStack {
            ProjectChip(name: "Mobile app", colorHex: "#0F766E")
            ProjectChip(name: "Platform", colorHex: "#7C3AED")
            ProjectChip(name: "Billing", colorHex: nil)
        }
        HStack { ForEach(ProjectStatusStyle.allCases, id: \.self) { ProjectStatusPill($0) } }
        TaskCountsBar(open: 7, blocked: 1, done: 4).frame(width: 260)
    }
    .padding()
    .background(Palette.paper)
}
