import SwiftUI

/// Spend against a cap. A missing or non-positive cap reads as empty.
public struct BudgetMeter: Equatable, Sendable {
    /// From this share of the cap on, the bar turns signal orange.
    public static let warningThreshold = 0.9

    public var spent: Double
    public var limit: Double

    public init(spent: Double, limit: Double) {
        self.spent = spent
        self.limit = limit
    }

    /// `spent / limit`, clamped to `0...1`.
    public var ratio: Double {
        guard limit > 0 else { return 0 }
        return min(max(spent / limit, 0), 1)
    }

    public var percent: Int {
        Int((ratio * 100).rounded(.down))
    }

    public var isNearLimit: Bool {
        ratio >= Self.warningThreshold
    }
}

/// A thin track that fills with spend; graphite normally, signal near the cap.
public struct BudgetBar: View {
    private let meter: BudgetMeter
    private let height: CGFloat

    public init(spent: Double, limit: Double, height: CGFloat = 8) {
        meter = BudgetMeter(spent: spent, limit: limit)
        self.height = height
    }

    public var body: some View {
        Capsule()
            .fill(Palette.rail)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(meter.isNearLimit ? Palette.signal : Palette.graphite)
                        .frame(width: proxy.size.width * meter.ratio)
                }
            }
            .clipShape(Capsule())
            .frame(height: height)
            .accessibilityElement()
            .accessibilityLabel(Text("Budget used", bundle: .module))
            .accessibilityValue(Text(meter.ratio, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview("Budget") {
    VStack(spacing: Spacing.l) {
        BudgetBar(spent: 412, limit: 1000, height: 6)
        BudgetBar(spent: 188, limit: 200)
        BudgetBar(spent: 300, limit: 200)
        BudgetBar(spent: 10, limit: 0)
    }
    .padding()
    .background(Palette.card)
}
