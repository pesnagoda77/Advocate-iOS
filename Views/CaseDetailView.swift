import SwiftUI
import SwiftData

// MARK: - Детали дела

struct CaseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var caseItem: Case
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAddEvent = false
    @State private var showingAddPayment = false
    
    var body: some View {
        List {
            Section("Информация") {
                HStack {
                    Text("Номер")
                    Spacer()
                    Text(caseItem.number)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Статус")
                    Spacer()
                    StatusBadge(status: caseItem.status)
                }
                
                HStack {
                    Text("Оплата")
                    Spacer()
                    Text(caseItem.paymentMethod.displayName)
                        .foregroundStyle(.secondary)
                }
                
                if caseItem.paymentMethod == .subscription {
                    HStack {
                        Text("Ежемесячно")
                        Spacer()
                        Text("\(caseItem.monthlyAmount ?? 0, specifier: "%.0f") ₽")
                            .foregroundStyle(.secondary)
                    }
                    
                    if let startDate = caseItem.paymentStartDate {
                        HStack {
                            Text("Начало оплаты")
                            Spacer()
                            Text(startDate, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Описание") {
                Text(caseItem.description)
                    .foregroundStyle(.secondary)
            }
            
            Section("Клиент") {
                if let client = caseItem.client {
                    NavigationLink {
                        ClientDetailView(client: client)
                    } label: {
                        ClientRow(client: client)
                    }
                } else {
                    Text("Клиент не назначен")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("События") {
                if let events = caseItem.events, !events.isEmpty {
                    ForEach(events.sorted(by: { $0.date > $1.date })) { event in
                        EventRow(event: event)
                    }
                } else {
                    Text("Нет событий")
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    showingAddEvent = true
                } label: {
                    Label("Добавить событие", systemImage: "plus.circle")
                }
            }
            
            Section("Платежи") {
                if let payments = caseItem.payments, !payments.isEmpty {
                    ForEach(payments.sorted(by: { $0.date > $1.date })) { payment in
                        PaymentRow(payment: payment)
                    }
                    
                    HStack {
                        Text("Всего")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(totalPayments, specifier: "%.0f") ₽")
                            .fontWeight(.semibold)
                            .foregroundStyle(.indigo)
                    }
                } else {
                    Text("Нет платежей")
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    showingAddPayment = true
                } label: {
                    Label("Добавить платеж", systemImage: "plus.circle")
                }
            }
            
            Section("Информация") {
                HStack {
                    Text("Создано")
                    Spacer()
                    Text(caseItem.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(caseItem.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Изменить") {
                    showingEditSheet = true
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCaseView(caseItem: caseItem)
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(caseItem: caseItem)
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentView(caseItem: caseItem)
        }
        .confirmationDialog("Удалить дело?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                modelContext.delete(caseItem)
                try? modelContext.save()
            }
            Button("Отмена", role: .cancel) { }
        }
    }
    
    var totalPayments: Double {
        caseItem.payments?.reduce(0) { $0 + $1.amount } ?? 0
    }
}

// MARK: - Добавление дела

struct AddCaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    
    @State private var number = ""
    @State private var title = ""
    @State private var description = ""
    @State private var status: CaseStatus = .active
    @State private var paymentMethod: PaymentMethod = .hourly
    @State private var monthlyAmount = ""
    @State private var paymentStartDate = Date()
    
    var isValid: Bool {
        !number.isEmpty && !title.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Номер дела", text: $number)
                    TextField("Заголовок", text: $title)
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Статус") {
                    Picker("Статус", selection: $status) {
                        ForEach(CaseStatus.allCases) { status in
                            Text(status.displayName)
                                .tag(status)
                        }
                    }
                }
                
                Section("Оплата") {
                    Picker("Метод", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.displayName)
                                .tag(method)
                        }
                    }
                    
                    if paymentMethod == .subscription {
                        TextField("Ежемесячная сумма", text: $monthlyAmount)
                            .keyboardType(.decimalPad)
                        DatePicker("Начало оплаты", selection: $paymentStartDate, displayedComponents: .date)
                    }
                }
                
                Section("Клиент") {
                    Text(client.fullName)
                        .foregroundStyle(.secondary)
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
                        let caseItem = Case(
                            number: number,
                            title: title,
                            description: description,
                            status: status,
                            paymentMethod: paymentMethod
                        )
                        caseItem.client = client
                        
                        if paymentMethod == .subscription, let amount = Double(monthlyAmount) {
                            caseItem.monthlyAmount = amount
                            caseItem.paymentStartDate = paymentStartDate
                        }
                        
                        modelContext.insert(caseItem)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Редактирование дела

struct EditCaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var caseItem: Case
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Номер", text: $caseItem.number)
                    TextField("Заголовок", text: $caseItem.title)
                    TextField("Описание", text: $caseItem.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Статус") {
                    Picker("Статус", selection: $caseItem.status) {
                        ForEach(CaseStatus.allCases) { status in
                            Text(status.displayName)
                                .tag(status)
                        }
                    }
                }
                
                Section("Оплата") {
                    Picker("Метод", selection: $caseItem.paymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.displayName)
                                .tag(method)
                        }
                    }
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
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Добавление события

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let caseItem: Case
    
    @State private var type: EventType = .meeting
    @State private var date = Date()
    @State private var duration = 60
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Тип") {
                    Picker("Тип события", selection: $type) {
                        ForEach(EventType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section("Дата и время") {
                    DatePicker("Дата", selection: $date)
                    Stepper("Длительность: \(duration) мин", value: $duration, in: 15...480, step: 15)
                }
                
                Section("Заметки") {
                    TextField("Заметки", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Дело") {
                    Text(caseItem.title)
                        .foregroundStyle(.secondary)
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
                        let event = Event(
                            type: type,
                            date: date,
                            duration: duration,
                            notes: notes
                        )
                        event.caseItem = caseItem
                        modelContext.insert(event)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Добавление платежа

struct AddPaymentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let caseItem: Case
    
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    
    var isValid: Bool {
        Double(amount) != nil && Double(amount)! > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Сумма") {
                    TextField("Сумма", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section("Дата") {
                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                }
                
                Section("Заметки") {
                    TextField("Заметки", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Дело") {
                    Text(caseItem.title)
                        .foregroundStyle(.secondary)
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
                        if let amountValue = Double(amount) {
                            let payment = Payment(
                                amount: amountValue,
                                date: date,
                                notes: notes
                            )
                            payment.caseItem = caseItem
                            modelContext.insert(payment)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Компоненты

struct CaseRow: View {
    let caseItem: Case
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(caseItem.title)
                    .font(.headline)
                Spacer()
                StatusBadge(status: caseItem.status)
            }
            
            Text("№ \(caseItem.number)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let client = caseItem.client {
                Text(client.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct StatusBadge: View {
    let status: CaseStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack {
            Image(systemName: event.type.icon)
                .foregroundStyle(.indigo)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.type.displayName)
                    .font(.subheadline)
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(event.duration) мин")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct PaymentRow: View {
    let payment: Payment
    
    var body: some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .foregroundStyle(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(payment.amount, specifier: "%.0f") ₽")
                    .font(.subheadline)
                Text(payment.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}
