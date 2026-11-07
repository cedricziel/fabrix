import FabrixCore
import FabrixDesign
import SwiftUI

// Local stand-ins until FabrixDesign ships its components under the same names.
// Delete each one here once the design-system version lands.

struct StatusPill: View {
    let status: AgentStatus

    var body: some View {
        HStack(spacing: 6) {
            StatusDot(color: status.color, hollow: status.isHollow)
            Text(status.label)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.steel)
    }
}

/// Status is never color alone: hollow rings mark states that wait (paused, needs you, offline).
struct StatusDot: View {
    let color: Color
    var hollow = false
    var size: CGFloat = 8

    var body: some View {
        Group {
            if hollow {
                Circle().strokeBorder(color, lineWidth: 1.5)
            } else {
                Circle().fill(color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct AvatarBadge: View {
    let initials: String
    var size: CGFloat = 32
    var tint: Color = Palette.graphite

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint, in: .rect(cornerRadius: size / 4))
            .accessibilityHidden(true)
    }
}

struct KindTag: View {
    let kind: ApprovalKind

    var body: some View {
        Text(kind.label.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(0.6)
            .foregroundStyle(Palette.signalInk)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Palette.signalTint, in: .rect(cornerRadius: 4))
    }
}

struct BudgetBar: View {
    let fraction: Double
    var height: CGFloat = 6

    var body: some View {
        Capsule()
            .fill(Palette.rail)
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(fraction >= Budget.nearCap ? Palette.signal : Palette.graphite)
                        .frame(width: proxy.size.width * min(max(fraction, 0), 1))
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Budget used")
            .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

struct MetricCard<Footer: View>: View {
    let title: LocalizedStringKey
    let value: String
    var total: String?
    var valueColor: Color = Palette.graphite
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.steel)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(valueColor)
                if let total {
                    Text("/ \(total)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            footer
                .font(.caption)
                .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .fabrixCard()
    }
}

struct SectionCard<Trailing: View, Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                trailing.font(.caption.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            Divider().overlay(Palette.rail)
            content
        }
        .fabrixCard()
    }
}

extension SectionCard where Trailing == EmptyView {
    init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(title: title, trailing: { EmptyView() }, content: content)
    }
}

struct FabrixButtonStyle: ButtonStyle {
    enum Role { case primary, signal, secondary }

    var role: Role = .primary
    var fullWidth = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(role == .secondary ? .medium : .semibold))
            .foregroundStyle(role == .secondary ? Palette.graphite : .white)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(background, in: .rect(cornerRadius: 8))
            .overlay {
                if role == .secondary {
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Palette.hairline)
                }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
            .contentShape(.rect)
    }

    private var background: Color {
        switch role {
        case .primary: Palette.graphite
        case .signal: Palette.signal
        case .secondary: Palette.card
        }
    }
}

extension ButtonStyle where Self == FabrixButtonStyle {
    static var fabrixPrimary: FabrixButtonStyle { FabrixButtonStyle(role: .primary) }
    static var fabrixSignal: FabrixButtonStyle { FabrixButtonStyle(role: .signal) }
    static var fabrixSecondary: FabrixButtonStyle { FabrixButtonStyle(role: .secondary) }
}

extension View {
    func fabrixCard(cornerRadius: CGFloat = 12, selected: Bool = false) -> some View {
        background(Palette.card, in: .rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(selected ? Palette.signal : Palette.hairline, lineWidth: selected ? 2 : 1)
            )
    }
}

/// Ticks once a second while visible.
struct ElapsedText: View {
    let since: Date

    var body: some View {
        TimelineView(.periodic(from: since, by: 1)) { context in
            Text(Elapsed.string(from: since, to: context.date))
                .monospacedDigit()
        }
    }
}

struct EmptyRow: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .foregroundStyle(Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
    }
}
