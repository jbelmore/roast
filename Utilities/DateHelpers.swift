import Foundation

enum DateHelpers {
    static func startOfDay(_ date: Date = Date()) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    static func endOfDay(_ date: Date = Date()) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay(date)) ?? date
    }

    static func startOfWeek(_ date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    static func endOfWeek(_ date: Date = Date()) -> Date {
        var components = DateComponents()
        components.day = 7
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek(date)) ?? date
    }

    static func previousWeekStart(_ date: Date = Date()) -> Date {
        var components = DateComponents()
        components.day = -7
        return Calendar.current.date(byAdding: components, to: startOfWeek(date)) ?? date
    }

    static func previousWeekEnd(_ date: Date = Date()) -> Date {
        var components = DateComponents()
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek(date)) ?? date
    }

    static func daysInRange(start: Date, end: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startOfDay(start)
        let endDate = startOfDay(end)

        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return dates
    }

    static func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    static func isThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    static func hourOfDay(_ date: Date) -> Int {
        Calendar.current.component(.hour, from: date)
    }

    static func hoursAgo(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
    }
}
