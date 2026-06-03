import SwiftUI
import SwiftData

// MARK: - Детали клиента

struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var client: Client
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            Section("Контакты") {
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(.indigo)
                    Text(client.phone)
                    Spacer()
                    if !client.phone.isEmpty {
                        Link(destination: URL(string: "tel:\(client.phone)")!) {
                            Image(systemName: "phone.arrow.up.right")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.indigo)
                    Text(client.email)
                    Spacer()
                    if !client.email.isEmpty {
                        Link(destination: URL(string: "mailto:\(client.email)")!) {
                            Image(systemName: "arrow.up.right")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            Section("Дела") {
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
                        .foregroundStyle(.secondary)
                }
                
                NavigationLink {
                    AddCaseView(client: client)
                } label: {
                    Label("Добавить дело", systemImage: "plus.circle")
                        .foregroundStyle(.indigo)
                }
            }
            
            Section("Информация") {
                HStack {
                    Text("Добавлен")
                    Spacer()
                    Text(client.createdAt, style: .date)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("ID")
                    Spacer()
                    Text(client.id.uuidString.prefix(8))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .navigationTitle(client.fullName)
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
            EditClientView(client: client)
        }
        .confirmationDialog("Удалить клиента?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                modelContext.delete(client)
                try? modelContext.save()
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Все дела клиента будут удалены. Это действие нельзя отменить.")
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
    
    var isValid: Bool {
        !lastName.isEmpty && !firstName.isEmpty
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
                        .textContentType(.emailAddress)
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
                        let client = Client(
                            lastName: lastName,
                            firstName: firstName,
                            middleName: middleName,
                            phone: phone,
                            email: email
                        )
                        modelContext.insert(client)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Редактирование клиента

struct EditClientView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var client: Client
    
    var body: some View {
        NavigationStack {
            Form {
                Section("ФИО") {
                    TextField("Фамилия", text: $client.lastName)
                    TextField("Имя", text: $client.firstName)
                    TextField("Отчество", text: $client.middleName)
                }
                
                Section("Контакты") {
                    TextField("Телефон", text: $client.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $client.email)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Изменить")
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

// MARK: - Компоненты

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(client.fullName)
                .font(.headline)
            
            HStack {
                if !client.phone.isEmpty {
                    Label(client.phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let cases = client.cases {
                    Text("• \(cases.count) дел")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
