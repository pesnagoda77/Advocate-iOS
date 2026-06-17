import SwiftUI
import SwiftData

// MARK: - Экран клиентов

struct ClientsView: View {
    @Query(sort: \Client.lastName) private var clients: [Client]
    @State private var searchText = ""
    @State private var showingAddClient = false
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients
        }
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
                .onDelete { indexSet in
                    // Удаление клиента
                }
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
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.fullName)
                .font(.headline)
            
            if !client.phone.isEmpty {
                Text(client.phone)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let cases = client.cases, !cases.isEmpty {
                Text("\(cases.count) дел")
                    .font(.caption2)
                    .foregroundColor(.indigo)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Детали клиента

struct ClientDetailView: View {
    let client: Client
    @State private var showingEditClient = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Информация о клиенте
                VStack(alignment: .leading, spacing: 12) {
                    Text(client.fullName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if !client.phone.isEmpty {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.indigo)
                            Text(client.phone)
                            Spacer()
                            Link(destination: URL(string: "tel:\(client.phone)")!) {
                                Image(systemName: "phone.arrow.up.right")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    if !client.email.isEmpty {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.indigo)
                            Text(client.email)
                            Spacer()
                            Link(destination: URL(string: "mailto:\(client.email)")!) {
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if !client.notes.isEmpty {
                        Text(client.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Дела клиента
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Дела")
                            .font(.headline)
                        
                        Spacer()
                        
                        NavigationLink("Добавить") {
                            AddCaseView(client: client)
                        }
                        .font(.caption)
                    }
                    
                    if let cases = client.cases, !cases.isEmpty {
                        ForEach(cases) { caseItem in
                            NavigationLink {
                                CaseDetailView(caseItem: caseItem)
                            } label: {
                                CaseRow(caseItem: caseItem)
                            }
                        }
                    } else {
                        Text("Нет дел")
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
        .navigationTitle("Клиент")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditClient = true
                } label: {
                    Text("Изменить")
                }
            }
        }
        .sheet(isPresented: $showingEditClient) {
            EditClientView(client: client)
        }
    }
}

// MARK: - Добавление клиента

struct AddClientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var lastName = ""
    @State private var firstName = ""
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
            lastName: lastName,
            firstName: firstName,
            middleName: middleName,
            phone: phone,
            email: email,
            notes: notes
        )
        modelContext.insert(client)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Редактирование клиента

struct EditClientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    
    @State private var lastName: String
    @State private var firstName: String
    @State private var middleName: String
    @State private var phone: String
    @State private var email: String
    @State private var notes: String
    
    init(client: Client) {
        self.client = client
        _lastName = State(initialValue: client.lastName)
        _firstName = State(initialValue: client.firstName)
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
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
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
                        updateClient()
                    }
                }
            }
        }
    }
    
    private func updateClient() {
        client.lastName = lastName
        client.firstName = firstName
        client.middleName = middleName
        client.phone = phone
        client.email = email
        client.notes = notes
        try? modelContext.save()
        dismiss()
    }
}