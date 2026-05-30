import SwiftUI
import SwiftData

// MARK: - Клиенты

struct ClientsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Client.lastName) private var clients: [Client]
    
    @State private var searchText = ""
    @State private var showingAddClient = false
    
    var filteredClients: [Client] {
        if searchText.isEmpty { return clients }
        return clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.phone.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredClients) { client in
                    NavigationLink {
                        ClientDetailView(client: client)
                    } label: {
                        ClientRow(client: client)
                    }
                }
                .onDelete(perform: deleteClients)
            }
            .navigationTitle("Клиенты")
            .searchable(text: $searchText, prompt: "Поиск по имени, телефону, email")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddClient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView()
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredClients[index])
        }
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.indigo)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !client.phone.isEmpty {
                    Text(client.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(client.cases.count) дел")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Детали клиента

struct ClientDetailView: View {
    let client: Client
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEdit = false
    @State private var showingAddCase = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Карточка клиента
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.indigo)
                    
                    Text(client.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !client.phone.isEmpty {
                        Link(destination: URL(string: "tel:\(client.phone)")!) {
                            Label(client.phone, systemImage: "phone.fill")
                                .font(.subheadline)
                        }
                    }
                    
                    if !client.email.isEmpty {
                        Link(destination: URL(string: "mailto:\(client.email)")!) {
                            Label(client.email, systemImage: "envelope.fill")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Дела клиента
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Дела")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingAddCase = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.indigo)
                        }
                    }
                    
                    if client.cases.isEmpty {
                        Text("Нет дел")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(client.cases) { caseItem in
                            CaseMiniRow(caseItem: caseItem)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Клиент")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Изменить") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditClientView(client: client)
        }
        .sheet(isPresented: $showingAddCase) {
            AddCaseView(client: client)
        }
    }
}

struct CaseMiniRow: View {
    let caseItem: Case
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(caseItem.number)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(caseItem.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            StatusBadge(status: caseItem.status)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Добавление клиента

struct AddClientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var middleName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("ФИО") {
                    TextField("Фамилия", text: $lastName)
                    TextField("Имя", text: $firstName)
                    TextField("Отчество", text: $middleName)
                }
                
                Section("Контакты") {
                    TextField("Телефон", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Новый клиент")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveClient()
                    }
                    .disabled(lastName.isEmpty || firstName.isEmpty)
                }
            }
        }
    }
    
    private func saveClient() {
        let client = Client(
            firstName: firstName,
            lastName: lastName,
            middleName: middleName,
            phone: phone,
            email: email,
            notes: notes
        )
        modelContext.insert(client)
        dismiss()
    }
}

struct EditClientView: View {
    let client: Client
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var middleName: String
    @State private var phone: String
    @State private var email: String
    @State private var notes: String
    
    init(client: Client) {
        self.client = client
        _firstName = State(initialValue: client.firstName)
        _lastName = State(initialValue: client.lastName)
        _middleName = State(initialValue: client.middleName)
        _phone = State(initialValue: client.phone)
        _email = State(initialValue: client.email)
        _notes = State(initialValue: client.notes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("ФИО") {
                    TextField("Фамилия", text: $lastName)
                    TextField("Имя", text: $firstName)
                    TextField("Отчество", text: $middleName)
                }
                
                Section("Контакты") {
                    TextField("Телефон", text: $phone)
                    TextField("Email", text: $email)
                }
                
                Section("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Изменить клиента")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        client.firstName = firstName
                        client.lastName = lastName
                        client.middleName = middleName
                        client.phone = phone
                        client.email = email
                        client.notes = notes
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Добавление дела

struct AddCaseView: View {
    let client: Client
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var number = ""
    @State private var title = ""
    @State private var status: CaseStatus = .active
    @State private var paymentMethod: PaymentMethod = .hourly
    @State private var rate: String = ""
    @State private var notes = ""
    
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
