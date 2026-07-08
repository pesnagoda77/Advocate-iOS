import SwiftUI
import SwiftData

// MARK: - Экран учета времени (TimeView)

struct TimeView: View {
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingAddEvent = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Период
                    PeriodPicker(selectedPeriod: $selectedPeriod)
                    
                    // Статистика за период
                    TimeStatsSection(events: filteredEvents, period: selectedPeriod)
                    
                    // Список событий
                    EventsListSection(events: filteredEvents)
                }
                .padding()
            }
            .navigationTitle("Учет времени")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView()
            }
        }
    }
    
    var filteredEvents: [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        return events.filter { event in
            switch selectedPeriod {
            case .today:
                return calendar.isDate(event.date, inSameDayAs: now)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return event.date >= weekAgo
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return event.date >= monthAgo
            case .year:
                guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) else { return false }
                return event.date >= yearAgo
            }
        }
    }
}

enum TimePeriod: String, CaseIterable {
    case today = "Сегодня"
    case week = "Неделя"
    case month = "Месяц"
    case year = "Год"
}

struct PeriodPicker: View {
    @Binding var selectedPeriod: TimePeriod
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(.caption)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedPeriod == period ? Color.indigo : Color(.systemGray6))
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                        .cornerRadius(16)
                }
            }
        }
    }
}

struct TimeStatsSection: View {
    let events: [Event]
    let period: TimePeriod
    
    var totalHours: Double {
        events.compactMap { $0.durationHours }.reduce(0, +)
    }
    
    var totalEarnings: Double {
        events.compactMap { event in
            if let duration = event.durationHours, let rate = event.rate {
                return duration * rate
            }
            return event.fixedAmount
        }.reduce(0, +)
    }
    
    var completedEvents: Int {
        events.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Часов",
                    value: String(format: "%.1f", totalHours),
                    icon: "clock.fill",
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
                title: "Завершено событий",
                value: "\(completedEvents)",
                icon: "checkmark.circle.fill",
                color: .blue,
                isWide: true
            )
        }
    }
}

struct EventsListSection: View {
    let events: [Event]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("События")
                .font(.headline)
            
            if events.isEmpty {
                Text("Нет событий за выбранный период")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(events) { event in
                    TimeEventRow(event: event)
                }
            }
        }
    }
}

struct TimeEventRow: View {
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
                
                if let caseItem = event.case {
                    Text(caseItem.number)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(event.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let duration = event.durationHours {
                    Text(String(format: "%.1f ч", duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if event.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Добавление события

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    
    @State private var title = ""
    @State private var selectedType: EventType = .meeting
    @State private var selectedCase: Case?
    @State private var date = Date()
    @State private var durationHours: String = ""
    @State private var rate: String = ""
    @State private var fixedAmount: String = ""
    @State private var isCompleted = false
    @State private var useFixedAmount = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $title)
                    
                    Picker("Тип", selection: $selectedType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    
                    Picker("Дело", selection: $selectedCase) {
                        Text("Без дела")
                            .tag(nil as Case?)
                        
                        ForEach(cases) { caseItem in
                            Text(caseItem.number)
                                .tag(caseItem as Case?)
                        }
                    }
                }
                
                Section("Дата и время") {
                    DatePicker("Дата", selection: $date)
                }
                
                Section("Оплата") {
                    Toggle("Фиксированная сумма", isOn: $useFixedAmount)
                    
                    if useFixedAmount {
                        TextField("Сумма (₽)", text: $fixedAmount)
                            .keyboardType(.decimalPad)
                    } else {
                        HStack {
                            TextField("Часы", text: $durationHours)
                                .keyboardType(.decimalPad)
                            
                            TextField("Ставка (₽/ч)", text: $rate)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Section("Статус") {
                    Toggle("Завершено", isOn: $isCompleted)
                }
            }
            .navigationTitle("Новое событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    func saveEvent() {
        let event = Event(
            type: selectedType,
            title: title,
            date: date,
            case: selectedCase
        )
        
        event.durationHours = Double(durationHours.replacingOccurrences(of: ",", with: "."))
        event.rate = Double(rate.replacingOccurrences(of: ",", with: "."))
        event.fixedAmount = Double(fixedAmount.replacingOccurrences(of: ",", with: "."))
        event.isCompleted = isCompleted
        
        modelContext.insert(event)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }
}
