import SwiftUI
import SwiftData

// MARK: - Экран дел

struct CasesView: View {
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    @State private var searchText = ""
    @State private var showingAddCase = false
    @State private var selectedStatus: CaseStatus?
    
    var filteredCases: [Case] {
        var result = cases
        
        if let status = selectedStatus {
            result = result.filter { $0.status == status }
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
                            isSelected: selectedStatus == nil,
                            action: { selectedStatus = nil }
                        )
                        
                        ForEach(CaseStatus.allCases, id: \.self) { status in
                            FilterChip(
                                title: status.displayName,
                                isSelected: selectedStatus == status,
                                action: { selectedStatus = status }
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
                AddCaseView()
            }
        }
    }
}

// MARK: - Детали дела

struct CaseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let caseItem: Case
    
    @State private var showingAddEvent = false
    @State private var showingAddPayment = false
    @State private var showingAddDocument = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Основная информация
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(caseItem.number)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        StatusBadge(status: caseItem.status)
                    }
                    
                    Text(caseItem.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if let client = caseItem.client {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.indigo)
                            Text(client.fullName)
                            Spacer()
                        }
                    }
                    
                    if !caseItem.description.isEmpty {
                        Text(caseItem.description)
                            .font(.body)
                            .padding(.top, 8)
                    }
                    
                    // Метод оплаты и ставка
                    HStack {
                        Label(caseItem.paymentMethod.displayName, systemImage: "creditcard")
                            .font(.caption)
                            .foregroundColor(.indigo)
                        
                        if caseItem.paymentMethod == .hourly {
                            Text("\(String(format: "%.0f", caseItem.hourlyRate)) ₽/ч")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
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
                    
                    if let events = caseItem.events, !events.isEmpty {
                        ForEach(events.sorted { $0.date < $1.date }) { event in
                            EventRow(event: event)
                        }
                    } else {
                        Text("Нет событий")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Платежи
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Платежи")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingAddPayment = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.indigo)
                        }
                    }
                    
                    if let payments = caseItem.payments, !payments.isEmpty {
                        ForEach(payments.sorted { $0.date > $1.date }) { payment in
                            PaymentRow(payment: payment)
                        }
                        
                        // Итого
                        HStack {
                            Text("Итого:")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.0f", payments.reduce(0) { $0 + $1.amount })) ₽")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 8)
                    } else {
                        Text("Нет платежей")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Документы
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Документы")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingAddDocument = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.indigo)
                        }
                    }
                    
                    if let documents = caseItem.documents, !documents.isEmpty {
                        ForEach(documents) { document in
                            DocumentRow(document: document)
                        }
                    } else {
                        Text("Нет документов")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Дело")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(case: caseItem)
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(case: caseItem)
        }
        .sheet(isPresented: $showingAddDocument) {
            AddDocumentView(case: caseItem)
        }
    }
}

// MARK: - Добавление дела

struct AddCaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var client: Client?
    
    @Query(sort: \Client.lastName) private var clients: [Client]
    
    @State private var number = ""
    @State private var title = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var status: CaseStatus = .active
    @State private var paymentMethod: PaymentMethod = .hourly
    @State private var hourlyRate = ""
    @State private var monthlyAmount = ""
    @State private var selectedClient: Client?
    
    init(client: Client? = nil) {
        self.client = client
        _selectedClient = State(initialValue: client)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Номер дела", text: $number)
                    TextField("Название", text: $title)
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Клиент") {
                    if client == nil {
                        Picker("Клиент", selection: $selectedClient) {
                            Text("Выберите клиента").tag(nil as Client?)
                            ForEach(clients) { client in
                                Text(client.fullName).tag(client as Client?)
                            }
                        }
                    } else {
                        Text(client?.fullName ?? "")
                    }
                }
                
                Section("Статус и оплата") {
                    Picker("Статус", selection: $status) {
                        ForEach(CaseStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    Picker("Метод оплаты", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    
                    if paymentMethod == .hourly {
                        TextField("Ставка за час (₽)", text: $hourlyRate)
                            .keyboardType(.decimalPad)
                    } else if paymentMethod == .monthly {
                        TextField("Сумма в месяц (₽)", text: $monthlyAmount)
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
                    .disabled(number.isEmpty || title.isEmpty)
                }
            }
        }
    }
    
    private func saveCase() {
        let caseItem = Case(
            number: number,
            title: title,
            description: description,
            notes: notes,
            status: status,
            paymentMethod: paymentMethod,
            hourlyRate: Double(hourlyRate) ?? 0,
            monthlyAmount: Double(monthlyAmount),
            client: selectedClient
        )
        modelContext.insert(caseItem)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Добавление события

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let case: Case
    
    @State private var title = ""
    @State private var type: EventType = .meeting
    @State private var date = Date()
    @State private var duration = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Информация") {
                    TextField("Название", text: $title)
                    
                    Picker("Тип", selection: $type) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
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
            case: case
        )
        modelContext.insert(event)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Добавление платежа

struct AddPaymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let case: Case
    
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
                    DatePicker("Дата платежа", selection: $date, displayedComponents: .date)
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
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func savePayment() {
        let payment = Payment(
            amount: Double(amount) ?? 0,
            date: date,
            notes: notes,
            case: case
        )
        modelContext.insert(payment)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Добавление документа

struct AddDocumentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let case: Case
    
    @State private var title = ""
    @State private var documentType: DocumentType = .other
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Информация") {
                    TextField("Название", text: $title)
                    
                    Picker("Тип", selection: $documentType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section {
                    Text("В реальном приложении здесь будет выбор файла или сканирование")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Новый документ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveDocument()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveDocument() {
        // Заглушка — в реальном приложении здесь будет сохранение файла
        let document = Document(
            title: title,
            fileName: "\(title).pdf",
            filePath: "/documents/\(UUID().uuidString).pdf",
            documentType: documentType,
            case: case
        )
        modelContext.insert(document)
        try? modelContext.save()
        dismiss()
    }
}