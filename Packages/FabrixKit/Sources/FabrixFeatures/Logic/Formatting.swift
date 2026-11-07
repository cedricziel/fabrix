import Foundation

enum Elapsed {
    static func string(from start: Date, to now: Date) -> String {
        let total = max(0, Int(now.timeIntervalSince(start)))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}

/// Paperclip reports budgets and costs in US cents.
enum Money {
    static func dollars(_ cents: Int, locale: Locale = .current) -> String {
        format(cents, fractionDigits: 0, locale: locale)
    }

    static func usage(_ budget: Budget, locale: Locale = .current) -> String {
        guard let cap = budget.capCents else { return dollars(budget.spentCents, locale: locale) }
        return "\(dollars(budget.spentCents, locale: locale)) / \(dollars(cap, locale: locale))"
    }

    static func exact(_ cents: Int, locale: Locale = .current) -> String {
        format(cents, fractionDigits: 2, locale: locale)
    }

    private static func format(_ cents: Int, fractionDigits: Int, locale: Locale) -> String {
        (Decimal(cents) / 100).formatted(
            .currency(code: "USD").presentation(.narrow).precision(.fractionLength(fractionDigits)).locale(locale)
        )
    }
}
