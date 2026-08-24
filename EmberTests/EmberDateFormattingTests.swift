import Foundation
import Testing
@testable import Ember

@Suite("Locale-aware dates")
struct EmberDateFormattingTests {

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return utc.date(from: components)!
    }

    @Test("Absolute dates use the locale's native month order")
    func absoluteDateUsesLocale() {
        let day = LocalDay.unchecked("2026-08-24")
        let reference = date(2026, 8, 26)

        #expect(
            EmberDateFormatting.display(day, reference: reference, calendar: utc, locale: Locale(identifier: "en_US"))
                == "August 24"
        )
        #expect(
            EmberDateFormatting.display(day, reference: reference, calendar: utc, locale: Locale(identifier: "fr_FR"))
                == "24 août"
        )
    }

    @Test("Near dates use native relative wording")
    func relativeDateUsesLocale() {
        let reference = Date()
        let yesterday = utc.date(byAdding: .day, value: -1, to: reference)!
        let day = LocalCalendar.day(for: yesterday, in: utc)

        #expect(
            EmberDateFormatting.display(day, reference: reference, calendar: utc, locale: Locale(identifier: "en_US"))
                == "yesterday"
        )
        #expect(
            EmberDateFormatting.display(day, reference: reference, calendar: utc, locale: Locale(identifier: "fr_FR"))
                == "hier"
        )
    }
}
