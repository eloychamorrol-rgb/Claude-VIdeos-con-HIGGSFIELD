import Foundation

public enum PeriodKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case day, week, month, quarter, year, custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .day: return "Día"
        case .week: return "Semana"
        case .month: return "Mes"
        case .quarter: return "Trimestre"
        case .year: return "Año"
        case .custom: return "Rango"
        }
    }
}

/// Intervalo [start, end) con su tipo.
public struct Period: Hashable, Codable, Sendable {
    public let kind: PeriodKind
    public let start: Date
    public let end: Date

    public init(kind: PeriodKind, start: Date, end: Date) {
        self.kind = kind
        self.start = start
        self.end = max(start, end)
    }

    public func contains(_ date: Date) -> Bool { date >= start && date < end }
}

/// Calendario financiero chileno: zona horaria de Santiago y semanas que empiezan el lunes.
public struct FinanceCalendar: Sendable {
    public let calendar: Calendar

    public init(timeZone: TimeZone = TimeZone(identifier: "America/Santiago") ?? .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "es_CL")
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        self.calendar = calendar
    }

    public static let chile = FinanceCalendar()

    public static let monthNames = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
                                    "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
    public static let monthShortNames = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
    /// Índice 0 = lunes.
    public static let weekdayNames = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
    public static let weekdayShortNames = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]

    public func startOfDay(_ date: Date) -> Date { calendar.startOfDay(for: date) }

    public func period(_ kind: PeriodKind, containing date: Date) -> Period {
        switch kind {
        case .day, .custom:
            let start = startOfDay(date)
            return Period(kind: .day, start: start, end: adding(days: 1, to: start))
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(date)
            return Period(kind: .week, start: start, end: adding(days: 7, to: start))
        case .month:
            let start = startOfMonth(date)
            return Period(kind: .month, start: start, end: adding(months: 1, to: start))
        case .quarter:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let quarterStartMonth = (((comps.month ?? 1) - 1) / 3) * 3 + 1
            let start = calendar.date(from: DateComponents(year: comps.year, month: quarterStartMonth, day: 1)) ?? startOfMonth(date)
            return Period(kind: .quarter, start: start, end: adding(months: 3, to: start))
        case .year:
            let year = calendar.component(.year, from: date)
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? startOfDay(date)
            return Period(kind: .year, start: start, end: adding(months: 12, to: start))
        }
    }

    /// Rango personalizado con ambos días incluidos.
    public func customPeriod(from: Date, through: Date) -> Period {
        let first = startOfDay(min(from, through))
        let last = startOfDay(max(from, through))
        return Period(kind: .custom, start: first, end: adding(days: 1, to: last))
    }

    public func shifted(_ period: Period, by steps: Int) -> Period {
        switch period.kind {
        case .day:
            return Period(kind: .day, start: adding(days: steps, to: period.start), end: adding(days: steps, to: period.end))
        case .week:
            return Period(kind: .week, start: adding(days: 7 * steps, to: period.start), end: adding(days: 7 * steps, to: period.end))
        case .month:
            let start = adding(months: steps, to: period.start)
            return Period(kind: .month, start: start, end: adding(months: 1, to: start))
        case .quarter:
            let start = adding(months: 3 * steps, to: period.start)
            return Period(kind: .quarter, start: start, end: adding(months: 3, to: start))
        case .year:
            let start = adding(months: 12 * steps, to: period.start)
            return Period(kind: .year, start: start, end: adding(months: 12, to: start))
        case .custom:
            let length = numberOfDays(in: period)
            return Period(kind: .custom, start: adding(days: length * steps, to: period.start),
                          end: adding(days: length * steps, to: period.end))
        }
    }

    public func previous(_ period: Period) -> Period { shifted(period, by: -1) }
    public func next(_ period: Period) -> Period { shifted(period, by: 1) }

    public func numberOfDays(in period: Period) -> Int {
        max(1, calendar.dateComponents([.day], from: period.start, to: period.end).day ?? 1)
    }

    /// Días transcurridos del período a la fecha `now` (mínimo 1, máximo el total).
    public func elapsedDays(in period: Period, now: Date) -> Int {
        let total = numberOfDays(in: period)
        if now >= period.end { return total }
        if now < period.start { return 0 }
        let full = calendar.dateComponents([.day], from: period.start, to: startOfDay(now)).day ?? 0
        return min(total, max(1, full + 1))
    }

    public func days(in period: Period) -> [Date] {
        (0..<numberOfDays(in: period)).map { adding(days: $0, to: period.start) }
    }

    /// 0 = lunes … 6 = domingo.
    public func weekdayIndex(_ date: Date) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    public func hour(_ date: Date) -> Int { calendar.component(.hour, from: date) }

    public func startOfMonth(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: 1)) ?? startOfDay(date)
    }

    public func adding(days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date.addingTimeInterval(Double(days) * 86_400)
    }

    public func adding(months: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: months, to: date) ?? date
    }

    /// Los últimos `count` meses completos anteriores al mes de `date` (del más antiguo al más reciente).
    public func completedMonths(before date: Date, count: Int) -> [Period] {
        let current = period(.month, containing: date)
        return (1...max(1, count)).reversed().map { shifted(current, by: -$0) }
    }

    // MARK: Textos

    public func title(for period: Period, now: Date = Date()) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: period.start)
        let year = comps.year ?? 0
        let month = (comps.month ?? 1) - 1
        let day = comps.day ?? 1
        let currentYear = calendar.component(.year, from: now)
        switch period.kind {
        case .day:
            let today = startOfDay(now)
            if period.start == today { return "Hoy" }
            if period.start == adding(days: -1, to: today) { return "Ayer" }
            let weekday = FinanceCalendar.weekdayNames[weekdayIndex(period.start)]
            let base = "\(weekday.capitalizedFirst) \(day) de \(FinanceCalendar.monthNames[month])"
            return year == currentYear ? base : "\(base) \(year)"
        case .week:
            if period.contains(now) { return "Esta semana" }
            let lastDay = adding(days: -1, to: period.end)
            return "\(shortDate(period.start)) – \(shortDate(lastDay))"
        case .month:
            let name = FinanceCalendar.monthNames[month].capitalizedFirst
            return year == currentYear ? name : "\(name) \(year)"
        case .quarter:
            return "T\(month / 3 + 1) \(year)"
        case .year:
            return "\(year)"
        case .custom:
            let lastDay = adding(days: -1, to: period.end)
            return "\(shortDate(period.start)) – \(shortDate(lastDay))"
        }
    }

    /// "12 oct"
    public func shortDate(_ date: Date) -> String {
        let comps = calendar.dateComponents([.month, .day], from: date)
        return "\(comps.day ?? 1) \(FinanceCalendar.monthShortNames[(comps.month ?? 1) - 1])"
    }

    /// "12 oct 2026"
    public func mediumDate(_ date: Date) -> String {
        "\(shortDate(date)) \(calendar.component(.year, from: date))"
    }

    /// "Lunes 12 de octubre"
    public func longDayTitle(_ date: Date, now: Date = Date()) -> String {
        title(for: period(.day, containing: date), now: now)
    }

    /// "14:05"
    public func timeString(_ date: Date) -> String {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        func pad(_ value: Int) -> String { value < 10 ? "0\(value)" : "\(value)" }
        return "\(pad(comps.hour ?? 0)):\(pad(comps.minute ?? 0))"
    }

    public func monthShortName(_ date: Date) -> String {
        FinanceCalendar.monthShortNames[calendar.component(.month, from: date) - 1]
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
