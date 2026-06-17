import SwiftUI
import SwiftData

// MARK: - Главный экран с табами

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
            
            ClientsView()
                .tabItem {
                    Label("Клиенты", systemImage: "person.2.fill")
                }
            
            CasesView()
                .tabItem {
                    Label("Дела", systemImage: "briefcase.fill")
                }
            
            DocumentsView()
                .tabItem {
                    Label("Документы", systemImage: "doc.text.fill")
                }
            
            CalendarView()
                .tabItem {
                    Label("Календарь", systemImage: "calendar")
                }
        }
        .accentColor(.indigo)
    }
}

// MARK: - Главный экран (Dashboard)

struct HomeView: View {
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    @Query(sort: \Payment.date, order: .reverse) private var payments: [Payment]
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Статистика
                    StatsSection(cases: cases, events: events, payments: payments)
                    
                    // Ближайшие события
                    UpcomingEventsSection(events: events.filter { !$0.isCompleted }.prefix(5))
                    
                    // Последние дела
                    RecentCasesSection(cases: cases.prefix(5))
                }
                .padding()
            }
            .navigationTitle("Advocate")
            .searchable(text: $searchText, prompt: "Поиск по делам, клиентам, документам")
        }
    }
}

// MARK: - Секция статистики

struct StatsSection: View {
    let cases: [Case]
    let events: [Event]
    let payments: [Payment]
    
    var activeCases: Int {
        cases.filter { $0.status == .active }.count
    }
    
    var totalEarnings: Double {
        payments.reduce(0) { $0 + $1.amount }
    }
    
    var hoursThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        return events
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .compactMap { $0.durationHours }
            .reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Активные дела",
                    value: "\(activeCases)",
                    icon: "briefcase.fill",
                    color: .indigo
                )
                
                StatCard(
                    title: "Заработано",
                    value: String(format: "%.0f ₽", totalEarnings),
                    icon: "rublesign.circle.fill",
                    color: .green
                )
            }
            
            StatCard(
                title: "Часов в этом месяце",
                value: String(format: "%.1f ч", hoursThisMonth),
                icon: "clock.fill",
                color: .orange,
                isWide: true
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isWide: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: isWide ? .infinity : nil, minHeight: 100)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Ближайшие события

struct UpcomingEventsSection: View {
    let events: ArraySlice<Event>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ближайшие события")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("Все") {
                    CalendarView()
                }
                .font(.caption)
            }
            
            if events.isEmpty {
                Text("Нет предстоящих событий")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(events) { event in
                    EventRow(event: event)
                }
            }
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.icon)
                .font(.title3)
                .foregroundColor(.indigo)
                .frame(width: 40, height: 40)
                .background(Color.indigo.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let duration = event.durationHours {
                Text(String(format: "%.1f ч", duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Последние дела

struct RecentCasesSection: View {
    let cases: ArraySlice<Case>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Последние дела")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("Все") {
                    CasesView()
                }
                .font(.caption)
            }
            
            ForEach(cases) { caseItem in
                CaseRow(caseItem: caseItem)
            }
        }
    }
}

struct CaseRow: View {
    let caseItem: Case
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caseItem.number)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(caseItem.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let client = caseItem.client {
                    Text(client.fullName)
                        .font(.caption2)
                        .foregroundColor(.indigo)
                }
            }
            
            Spacer()
            
            StatusBadge(status: caseItem.status)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: CaseStatus
    
    var color: Color {
        switch status {
        case .active: return .green
        case .archived: return .orange
        case .closed: return .gray
        }
    }
    
    var text: String {
        switch status {
        case .active: return "Активно"
        case .archived: return "Архив"
        case .closed: return "Закрыто"
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}