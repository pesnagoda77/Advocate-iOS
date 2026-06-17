import Foundation

// MARK: - Аналитика и статистика

struct Analytics {
    
    // MARK: - Финансовая аналитика
    
    static func monthlyEarnings(payments: [Payment], months: Int = 12) -> [(month: String, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(String, Double)] = []
        
        for i in 0..<months {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let monthPayments = payments.filter {
                calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            
            let total = monthPayments.reduce(0) { $0 + $1.amount }
            let monthName = monthDate.formatted("MMM yyyy")
            
            result.append((monthName, total))
        }
        
        return result.reversed()
    }
    
    static func yearlyEarnings(payments: [Payment], years: Int = 3) -> [(year: String, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(String, Double)] = []
        
        for i in 0..<years {
            guard let yearDate = calendar.date(byAdding: .year, value: -i, to: now) else { continue }
            
            let yearPayments = payments.filter {
                calendar.isDate($0.date, equalTo: yearDate, toGranularity: .year)
            }
            
            let total = yearPayments.reduce(0) { $0 + $1.amount }
            let yearName = yearDate.formatted("yyyy")
            
            result.append((yearName, total))
        }
        
        return result.reversed()
    }
    
    static func averagePayment(payments: [Payment]) -> Double {
        guard !payments.isEmpty else { return 0 }
        return payments.reduce(0) { $0 + $1.amount } / Double(payments.count)
    }
    
    static func totalByPaymentMethod(cases: [Case]) -> [(method: String, amount: Double)] {
        var result: [String: Double] = [:]
        
        for caseItem in cases {
            let method = caseItem.paymentMethod.displayName
            let total = caseItem.payments?.reduce(0) { $0 + $1.amount } ?? 0
            result[method, default: 0] += total
        }
        
        return result.map { ($0.key, $0.value) }.sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Аналитика времени
    
    static func monthlyHours(events: [Event], months: Int = 12) -> [(month: String, hours: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(String, Double)] = []
        
        for i in 0..<months {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let monthEvents = events.filter {
                calendar.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            
            let hours = monthEvents.reduce(0) { $0 + ($1.durationHours ?? 0) }
            let monthName = monthDate.formatted("MMM yyyy")
            
            result.append((monthName, hours))
        }
        
        return result.reversed()
    }
    
    static func averageEventDuration(events: [Event]) -> Double {
        let durations = events.compactMap { $0.durationHours }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    static func eventsByType(events: [Event]) -> [(type: String, count: Int, hours: Double)] {
        var result: [String: (count: Int, hours: Double)] = [:]
        
        for event in events {
            let type = event.type.displayName
            let duration = event.durationHours ?? 0
            result[type, default: (0, 0)].count += 1
            result[type, default: (0, 0)].hours += duration
        }
        
        return result.map { ($0.key, $0.value.count, $0.value.hours) }
            .sorted { $0.count > $1.count }
    }
    
    // MARK: - Аналитика дел
    
    static func casesByStatus(cases: [Case]) -> [(status: String, count: Int, percentage: Double)] {
        let total = cases.count
        guard total > 0 else { return [] }
        
        var counts: [String: Int] = [:]
        for caseItem in cases {
            let status = caseItem.status.displayName
            counts[status, default: 0] += 1
        }
        
        return counts.map { ($0.key, $0.value, Double($0.value) / Double(total) * 100) }
            .sorted { $0.count > $1.count }
    }
    
    static func casesByMonth(cases: [Case], months: Int = 12) -> [(month: String, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(String, Int)] = []
        
        for i in 0..<months {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            
            let monthCases = cases.filter {
                calendar.isDate($0.createdAt, equalTo: monthDate, toGranularity: .month)
            }
            
            let monthName = monthDate.formatted("MMM yyyy")
            result.append((monthName, monthCases.count))
        }
        
        return result.reversed()
    }
    
    static func topClientsByCases(clients: [Client], limit: Int = 10) -> [(client: String, cases: Int, earnings: Double)] {
        let sorted = clients.sorted { ($0.cases?.count ?? 0) > ($1.cases?.count ?? 0) }
        
        return sorted.prefix(limit).map { client in
            let caseCount = client.cases?.count ?? 0
            let earnings = client.cases?.reduce(0) { $0 + ($1.payments?.reduce(0) { $0 + $1.amount } ?? 0) } ?? 0
            return (client.fullName, caseCount, earnings)
        }
    }
    
    // MARK: - Прогнозирование
    
    static func projectedMonthlyEarnings(payments: [Payment]) -> Double {
        let monthlyData = monthlyEarnings(payments: payments, months: 6)
        guard monthlyData.count >= 3 else { return 0 }
        
        // Простое линейное сглаживание
        let recentMonths = monthlyData.suffix(3)
        let average = recentMonths.reduce(0) { $0 + $1.amount } / Double(recentMonths.count)
        
        return average
    }
    
    static func projectedYearlyEarnings(payments: [Payment]) -> Double {
        projectedMonthlyEarnings(payments: payments) * 12
    }
    
    // MARK: - KPI
    
    struct KPIs {
        let totalEarnings: Double
        let totalHours: Double
        let averageHourlyRate: Double
        let activeCases: Int
        let completedCases: Int
        let clientRetention: Double
        let averageCaseDuration: Double
    }
    
    static func calculateKPIs(cases: [Case], events: [Event], payments: [Payment], clients: [Client]) -> KPIs {
        let totalEarnings = payments.reduce(0) { $0 + $1.amount }
        let totalHours = events.reduce(0) { $0 + ($1.durationHours ?? 0) }
        let averageHourlyRate = totalHours > 0 ? totalEarnings / totalHours : 0
        let activeCases = cases.filter { $0.status == .active }.count
        let completedCases = cases.filter { $0.status == .closed }.count
        
        // Удержание клиентов (клиенты с более чем 1 делом)
        let returningClients = clients.filter { ($0.cases?.count ?? 0) > 1 }.count
        let clientRetention = clients.isEmpty ? 0 : Double(returningClients) / Double(clients.count) * 100
        
        // Средняя длительность дела (в днях)
        let caseDurations = cases.compactMap { caseItem -> Double? in
            guard let events = caseItem.events, let firstEvent = events.first, let lastEvent = events.last else { return nil }
            return lastEvent.date.timeIntervalSince(firstEvent.date) / 86400
        }
        let averageCaseDuration = caseDurations.isEmpty ? 0 : caseDurations.reduce(0, +) / Double(caseDurations.count)
        
        return KPIs(
            totalEarnings: totalEarnings,
            totalHours: totalHours,
            averageHourlyRate: averageHourlyRate,
            activeCases: activeCases,
            completedCases: completedCases,
            clientRetention: clientRetention,
            averageCaseDuration: averageCaseDuration
        )
    }
}

// MARK: - Генерация отчётов

struct ReportGenerator {
    
    static func generateMonthlyReport(cases: [Case], events: [Event], payments: [Payment], month: Date) -> String {
        let calendar = Calendar.current
        
        let monthCases = cases.filter { calendar.isDate($0.createdAt, equalTo: month, toGranularity: .month) }
        let monthEvents = events.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
        let monthPayments = payments.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
        
        let totalEarnings = monthPayments.reduce(0) { $0 + $1.amount }
        let totalHours = monthEvents.reduce(0) { $0 + ($1.durationHours ?? 0) }
        
        var report = """
        ОТЧЁТ ЗА \(month.formatted("MMMM yyyy"))
        
        ФИНАНСЫ:
        - Всего заработано: \(FormatUtils.formatCurrency(totalEarnings))
        - Количество платежей: \(monthPayments.count)
        - Средний платёж: \(FormatUtils.formatCurrency(monthPayments.isEmpty ? 0 : totalEarnings / Double(monthPayments.count)))
        
        ВРЕМЯ:
        - Всего часов: \(String(format: "%.1f", totalHours))
        - Количество событий: \(monthEvents.count)
        - Средняя длительность: \(String(format: "%.1f", Analytics.averageEventDuration(events: monthEvents))) ч
        
        ДЕЛА:
        - Новых дел: \(monthCases.count)
        - Активных дел: \(cases.filter { $0.status == .active }.count)
        
        """
        
        // Топ клиентов
        let topClients = Analytics.topClientsByCases(clients: cases.compactMap { $0.client }, limit: 5)
        if !topClients.isEmpty {
            report += "\nТОП КЛИЕНТЫ:\n"
            for (index, client) in topClients.enumerated() {
                report += "\(index + 1). \(client.client) — \(client.cases) дел, \(FormatUtils.formatCurrency(client.earnings))\n"
            }
        }
        
        return report
    }
    
    static func generateYearlyReport(cases: [Case], events: [Event], payments: [Payment]) -> String {
        let yearlyEarnings = Analytics.yearlyEarnings(payments: payments)
        let kpis = Analytics.calculateKPIs(cases: cases, events: events, payments: payments, clients: [])
        
        var report = """
        ГОДОВОЙ ОТЧЁТ
        
        КЛЮЧЕВЫЕ ПОКАЗАТЕЛИ:
        - Общий доход: \(FormatUtils.formatCurrency(kpis.totalEarnings))
        - Всего часов: \(String(format: "%.1f", kpis.totalHours))
        - Средняя ставка: \(FormatUtils.formatCurrency(kpis.averageHourlyRate))/ч
        - Активных дел: \(kpis.activeCases)
        - Завершённых дел: \(kpis.completedCases)
        - Удержание клиентов: \(String(format: "%.1f", kpis.clientRetention))%
        
        ДОХОДЫ ПО ГОДАМ:
        """
        
        for yearData in yearlyEarnings {
            report += "\n- \(yearData.year): \(FormatUtils.formatCurrency(yearData.amount))"
        }
        
        return report
    }
}