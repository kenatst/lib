import Foundation

/// User-facing calendar labels for persisted LocalDay values.
///
/// LocalDay remains a stable storage identity. This boundary is where that
/// identity becomes a locale-aware label, so raw ISO keys never reach a view.
enum EmberDateFormatting {

    static func display(
        _ day: LocalDay,
        reference: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let date = date(for: day, calendar: calendar) ?? .distantPast
        let targetStart = calendar.startOfDay(for: date)
        let referenceStart = calendar.startOfDay(for: reference)
        let dayDelta = calendar.dateComponents([.day], from: targetStart, to: referenceStart).day ?? 2

        if dayDelta == 0 {
            return String(localized: "date.today")
        }

        if abs(dayDelta) == 1 {
            let now = Date()
            let relativeDate = calendar.date(
                bySettingHour: calendar.component(.hour, from: now),
                minute: calendar.component(.minute, from: now),
                second: calendar.component(.second, from: now),
                of: date
            ) ?? date
            return relativeDate.formatted(
                Date.RelativeFormatStyle(presentation: .named).locale(locale)
            )
        }

        return date.formatted(.dateTime.month(.wide).day().locale(locale))
    }

    private static func date(for day: LocalDay, calendar: Calendar) -> Date? {
        let parts = day.storageKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }

        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        // Noon keeps the calendar date stable across timezone presentation.
        components.hour = 12
        return calendar.date(from: components)
    }
}
