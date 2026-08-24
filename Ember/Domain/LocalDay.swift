import Foundation

// MARK: - LocalDay
//
// Canonical local calendar date — the identity of a daily session.
//
// RULES:
//   * A "day" is a CALENDAR date in the user's current timezone, never a
//     24-hour interval. Midnight transitions, DST shifts and travel are
//     handled by Calendar semantics, not arithmetic.
//   * Stable string form "yyyy-MM-dd" is what gets PERSISTED (timezone-
//     independent once written; a stored day never mutates).
//   * Deterministic and injectable: every API takes a Calendar so tests can
//     simulate midnight crossings, DST boundaries and timezone travel.
//
// EMBER never counts missed days. A LocalDay answers exactly one question:
// "is this the same day as that other day?"

nonisolated struct LocalDay: Equatable, Comparable, Hashable, Sendable, Codable {
    /// Canonical form "yyyy-MM-dd" in the Gregorian calendar. Readable for
    /// assertions and persistence; construction stays validated.
    let storageKey: String

    /// Failable factory — validates and normalizes via real calendar math
    /// (rejects e.g. 2026-02-31). Test/simulation/migration entry point.
    nonisolated static func validating(_ key: String) -> LocalDay? {
        parseKey(key)
    }

    static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        lhs.storageKey < rhs.storageKey
    }

    var description: String { storageKey }

    /// Internal unchecked init for trusted internal callers (LocalCalendar,
    /// next(), Codable). Key MUST already be canonical yyyy-MM-dd.
    fileprivate init(unchecked key: String) {
        self.storageKey = key
    }

    /// Same-domain trusted factory (DailyEngine epoch). Not for parsing user
    /// or persisted data — that path is `validating(_:)`.
    nonisolated static func unchecked(_ key: String) -> LocalDay {
        LocalDay(unchecked: key)
    }
}

nonisolated enum LocalCalendar {

    /// The canonical calendar used for day identity. Gregorian proleptic,
    /// UTC-based arithmetic on Y-M-D components — deliberately NOT the
    /// device calendar, so a stored key never depends on locale settings.
    nonisolated static var identity: Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "UTC")!
        return gregorian
    }

    /// The LocalDay for a moment, observed in the given timezone.
    /// Production passes Calendar.current; tests pass fixed zones.
    static func day(for date: Date, in calendar: Calendar) -> LocalDay {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return LocalDay(unchecked: LocalCalendar.format(year: components.year ?? 2000,
                                           month: components.month ?? 1,
                                           day: components.day ?? 1))
    }

    /// The LocalDay right now, in the given calendar.
    static func today(in calendar: Calendar) -> LocalDay {
        day(for: Date(), in: calendar)
    }

    static func format(year: Int, month: Int, day: Int) -> String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}

// MARK: - Test/simulation helpers

extension LocalDay {

    /// The day after this one (pure calendar arithmetic on the key itself).
    func next() -> LocalDay {
        guard let date = Self.parseToUTCDate(storageKey),
              let next = LocalCalendar.identity.date(byAdding: .day, value: 1, to: date) else {
            return self
        }
        let comps = LocalCalendar.identity.dateComponents([.year, .month, .day], from: next)
        return LocalDay(unchecked: Self.formatKey(comps))
    }

    /// Days between two LocalDays (absolute). Pure key arithmetic.
    func days(since other: LocalDay) -> Int {
        guard let a = Self.parseToUTCDate(other.storageKey),
              let b = Self.parseToUTCDate(storageKey) else {
            return 0
        }
        return max(0, Int(b.timeIntervalSince(a) / 86_400))
    }

    private static func parseToUTCDate(_ key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        return LocalCalendar.identity.date(from: comps)
    }

    fileprivate static func formatKey(_ comps: DateComponents) -> String {
        LocalCalendar.format(year: comps.year ?? 2000, month: comps.month ?? 1, day: comps.day ?? 1)
    }

    static func parse(_ storageKey: String) -> LocalDay? {
        parseKey(storageKey)
    }

    fileprivate static func parseKey(_ key: String) -> LocalDay? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        let y = parts[0], m = parts[1], d = parts[2]
        guard y > 0, (1...12).contains(m), (1...31).contains(d) else {
            return nil
        }
        // Normalize via real calendar arithmetic (rejects e.g. 2026-02-31).
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        guard let date = LocalCalendar.identity.date(from: comps) else { return nil }
        let roundTrip = LocalCalendar.identity.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.day == d, roundTrip.month == m, roundTrip.year == y else {
            return nil
        }
        return LocalDay(unchecked: LocalCalendar.format(year: y, month: m, day: d))
    }
}
