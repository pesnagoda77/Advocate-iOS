import SwiftUI
import SwiftData

// MARK: - Дела

struct CasesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    
    @State private var searchText = ""
    @State private var statusFilter: CaseStatus?
    @State private var showingAddCase = false
    
    var filteredCases: [Case] {
        var result = cases
        
        if let filter = statusFilter {
            result = result.filter { $0.status == filter }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.number.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.client?.fullName.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Фильтры по статусу
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "Все",
                            isSelected: statusFilter == nil,
                            action: { statusFilter = nil }
                        )
                        
                        ForEach(CaseStatus.allCases, id: \.self) { status in
                            FilterChip(
                                title: status.displayName,
                                isSelected: statusFilter == status,
                                action: { statusFilter = status }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Список дел
                List {
                    ForEach(filteredCases) { caseItem in
                        NavigationLink {
                            CaseDetailView(caseItem: caseItem)
                        } label: {
                            CaseRow(caseItem: caseItem)
                        }
                    }
                    .onDelete(perform: deleteCases)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Дела")
            .searchable(text: $searchText, prompt: "Поиск по номеру, названию, клиенту")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCase = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCase) {
                AddCaseStandaloneView()
            }
        }
    }
    
    private func deleteCases(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredCases[index])
        }
    }
}

// MARK: - Детали дела

struct CaseDetailView: View {
    let caseItem: Case
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEdit = false
    @State private var showingAddPayment = false
    @State private var showingAddEvent = false
    
    var totalPayments: Double {
        caseItem.payments.reduce(0) { $0 + $1.amount }
    }
    
    var totalHours: Double {
        caseItem.events
            .filter { $0.isCompleted }
            .compactMap { $0.durationHours }
            .reduce(0, +)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Основная информация
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        StatusBadge(status: caseItem.status)
                        Spacer()
                        Text(caseItem.number)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(caseItem.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let client = caseItem.client {
                        NavigationLink {
                            ClientDetailView(client: client)
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.indigo)
                                Text(client.fullName)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if !caseItem.notes.isEmpty {
                        Text(caseItem.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Финансы
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Финансы")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingAddPayment = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Заработано",
                            value: String(format: "%.0f ₽", totalPayments),
                            icon: "rublesign.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Часов",
                            value: String(format: "%.1f ч", totalHours),
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    
                    if caseItem.paymentMethod == .hourly && caseItem.hourlyRate > 0 {
                        Text("Ставка: \(String(format: "%.0f", caseItem.hourlyRate)) ₽/час")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !caseItem.payments.isEmpty {
                        Text("Платежи")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 8)
                        
                        ForEach(caseItem.payments.sorted(by: { $0.date > $1.date })) { payment in
                            PaymentRow(payment: payment)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // События
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("События")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingAddEvent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.indigo)
                        }
                    }
                    
                    if caseItem.events.isEmpty {
                        Text("Нет событий")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(caseItem.events.sorted(by: { $0.date < $1.date })) { event in
                            EventRow(event: event)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Документы
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Документы")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(caseItem.documents.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if caseItem.documents.isEmpty {
                        Text("Нет документов")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(caseItem.documents.prefix(3)) { document in
                            DocumentRow(document: document)
                        }
                        
                        if caseItem.documents.count > 3 {
                            NavigationLink("Все документы") {
                                DocumentsView(caseFilter: caseItem)
                            }
                            .font(.caption)
                            .foregroundColor(.indigo)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Дело")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Изменить") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditCaseView(caseItem: caseItem)
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(caseItem: caseItem)
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(caseItem: caseItem)
        }
    }
}

struct PaymentRow: View {
    let payment: Payment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.notes.isEmpty ? "Платеж" : payment.notes)
                    .font(.subheadline)
                
                Text(payment.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.0f ₽", payment.amount))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Добавление дела (standalone)

struct AddCaseStandaloneView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Client.lastName) private var clients: [Client]
    
    @State private var selectedClient: Client?
    @State private var number = ""
    @State private var title = ""
    @State private var status: CaseStatus = .active
    @State private var paymentMethod: PaymentMethod = .hourly
    @State private var rate: String = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Клиент") {
                    Picker("Клиент", selection: $selectedClient) {
                        Text("Выберите клиента").tag(nil as Client?)
                        ForEach(clients) { client in
                            Text(client.fullName).tag(client as Client?)
                        }
                    }
                }
                
                Section("Информация") {
                    TextField("Номер дела", text: $number)
                    TextField("Название", text: $title)
                }
                
                Section("Статус") {
                    Picker("Статус", selection: $status) {
                        ForEach(CaseStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }
                
                Section("Оплата") {
                    Picker("Метод", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    
                    if paymentMethod == .hourly {
                        TextField("Ставка за час (₽)", text: $rate)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Новое дело")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveCase()
                    }
                    .disabled(number.isEmpty || title.isEmpty || selectedClient == nil)
                }
            }
        }
    }
    
    private func saveCase() {
        guard let client = selectedClient else { return }
        
        let caseItem = Case(
            number: number,
            title: title,
            status: status,
            paymentMethod: paymentMethod,
            hourlyRate: Double(rate) ?? 0,
            notes: notes,
            client: client
        )
        modelContext.insert(caseItem)
        dismiss()
    }
}

struct EditCaseView: View {
    let caseItem: Case
    @Environment(\.dismiss) private var dismiss
    
    @State private var number: String
    @State private var title: String
    @State private var status: CaseStatus
    @State private var paymentMethod: PaymentMethod
    @State private var rate: String
    @State private var notes: String
    
    init(caseItem: Case) {
        self.caseItem = caseItem
        _number = State(initialValue: caseItem.number)
        _title = State(initialValue: caseItem.title)
        _status = State(initialValue: caseItem.status)
        _paymentMethod = State(initialValue: caseItem.paymentMethod)
        _rate = State(initialValue: String(caseItem.hourlyRate))
        _notes = State(initialValue: caseItem.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Информация") {
                    TextField("Номер дела", text: $number)
                    TextField("Название", text: $title)
                }
                
                Section("Статус") {
                    Picker("Статус", selection: $status) {
                        ForEach(CaseStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                }
                
                Section("Оплата") {
                    Picker("Метод", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    
                    if paymentMethod == .hourly {
                        TextField("Ставка за час (₽)", text: $rate)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Изменить дело")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        caseItem.number = number
                        caseItem.title = title
                        caseItem.status = status
                        caseItem.paymentMethod = paymentMethod
                        caseItem.hourlyRate = Double(rate) ?? 0
                        caseItem.notes = notes
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Добавление платежа

struct AddPaymentView: View {
    let caseItem: Case
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Сумма") {
                    TextField("Сумма (₽)", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Дата") {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                }
                
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Новый платеж")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        savePayment()
                    }
                    .disabled(amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
    
    private func savePayment() {
        guard let amountValue = Double(amount) else { return }
        
        let payment = Payment(
            amount: amountValue,
            date: date,
            notes: notes,
            case: caseItem
        )
        modelContext.insert(payment)
        dismiss()
    }
}

// MARK: - Добавление события

struct AddEventView: View {
    let caseItem: Case
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var type: EventType = .meeting
    @State private var date = Date()
    @State private var duration: String = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
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
            title: title,
            type: type,
            date: date,
            durationHours: Double(duration) ?? 0,
            notes: notes,
            case: caseItem
        )
        modelContext.insert(event)
        dismiss()
    }
}
