import SwiftUI
import SwiftData

// MARK: - Календарь

struct CalendarView: View {
    @Query(sort: \Event.date) private var events: [Event]
    
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false
    
    var eventsForSelectedDate: [Event] {
        events.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    var upcomingEvents: [Event] {
        events.filter { $0.date >= Date() && !$0.isCompleted }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // DatePicker
                    DatePicker(
                        "Выберите дату",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    
                    // События на выбранную дату
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(selectedDate, style: .date)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingAddEvent = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.indigo)
                            }
                        }
                        
                        if eventsForSelectedDate.isEmpty {
                            Text("Нет событий")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(eventsForSelectedDate) { event in
                                EventRow(event: event)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Ближайшие события
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ближайшие")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(upcomingEvents.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if upcomingEvents.isEmpty {
                            Text("Нет предстоящих событий")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(upcomingEvents.prefix(5)) { event in
                                EventRow(event: event)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Календарь")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventStandaloneView()
            }
        }
    }
}

// MARK: - Добавление события (standalone)

struct AddEventStandaloneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    
    @State private var selectedCase: Case?
    @State private var title = ""
    @State private var type: EventType = .meeting
    @State private var date = Date()
    @State private var duration = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Дело") {
                    Picker("Дело", selection: $selectedCase) {
                        Text("Без дела").tag(nil as Case?)
                        ForEach(cases) { caseItem in
                            Text("\(caseItem.number) — \(caseItem.title)").tag(caseItem as Case?)
                        }
                    }
                }
                
                Section("Информация") {
                    TextField("Название", text: $title)
                    
                    Picker("Тип", selection: $type) {
                        ForEach(EventType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }
                
                Section("Время") {
                    DatePicker("Дата и время", selection: $date)
                    
                    TextField("Длительность (часов)", text: $duration)
                        .keyboardType(.decimalPad)
                }
                
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Новое событие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
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
    
    private func saveEvent() {
        let event = Event(
            type: type,
            title: title,
            notes: notes,
            date: date,
            durationHours: Double(duration),
            case: selectedCase
        )
        modelContext.insert(event)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Учёт времени

struct TimeView: View {
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingAddTime = false
    
    var filteredEvents: [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        return events.filter { event in
            guard event.isCompleted else { return false }
            
            switch selectedPeriod {
            case .today:
                return calendar.isDate(event.date, inSameDayAs: now)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return event.date >= weekAgo
            case .month:
                return calendar.isDate(event.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(event.date, equalTo: now, toGranularity: .year)
            }
        }
    }
    
    var totalHours: Double {
        filteredEvents.compactMap { $0.durationHours }.reduce(0, +)
    }
    
    var totalEarnings: Double {
        filteredEvents.reduce(0) { total, event in
            guard let caseItem = event.case,
                  caseItem.paymentMethod == .hourly else { return total }
            return total + (event.durationHours ?? 0) * caseItem.hourlyRate
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Период
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Статистика
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Часов",
                            value: String(format: "%.1f ч", totalHours),
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
                    .padding(.horizontal)
                    
                    // Список записей
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Записи")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingAddTime = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.indigo)
                            }
                        }
                        
                        if filteredEvents.isEmpty {
                            Text("Нет записей за период")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(filteredEvents) { event in
                                TimeRow(event: event)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Учёт времени")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTime = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTime) {
                AddEventStandaloneView()
            }
        }
    }
}

struct TimeRow: View {
    let event: Event
    
    var earnings: Double {
        guard let caseItem = event.case,
              caseItem.paymentMethod == .hourly else { return 0 }
        return (event.durationHours ?? 0) * caseItem.hourlyRate
    }
    
    var body: some View {
        HStack(spacing: 12) {
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
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if earnings > 0 {
                    Text(String(format: "%.0f ₽", earnings))
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

enum TimePeriod: CaseIterable {
    case today, week, month, year
    
    var displayName: String {
        switch self {
        case .today: return "День"
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .year: return "Год"
        }
    }
}