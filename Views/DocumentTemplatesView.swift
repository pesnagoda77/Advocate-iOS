import SwiftUI
import SwiftData

// MARK: - Экран шаблонов документов

struct DocumentTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory: DocumentCategory = .all
    @State private var searchText = ""
    @State private var showingTemplateEditor = false
    
    let templates = DocumentTemplate.allTemplates
    
    var filteredTemplates: [DocumentTemplate] {
        var result = templates
        
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Категории
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DocumentCategory.allCases) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Список шаблонов
                List {
                    ForEach(filteredTemplates) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            TemplateRow(template: template)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Шаблоны")
            .searchable(text: $searchText, prompt: "Поиск шаблонов")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTemplateEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTemplateEditor) {
                TemplateEditorView()
            }
        }
    }
}

// MARK: - Детали шаблона

struct TemplateDetailView: View {
    let template: DocumentTemplate
    
    @State private var clientName = ""
    @State private var caseNumber = ""
    @State private var courtName = ""
    @State private var generatedDocument: String?
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Информация о шаблоне
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Label(template.category.displayName, systemImage: template.category.icon)
                            .font(.caption)
                            .foregroundStyle(.indigo)
                        
                        Spacer()
                        
                        Text("\(template.fields.count) полей")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Поля для заполнения
                VStack(alignment: .leading, spacing: 16) {
                    Text("Данные для заполнения")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(template.fields) { field in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(field.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            switch field.type {
                            case .text:
                                TextField(field.placeholder, text: binding(for: field))
                                    .textFieldStyle(.roundedBorder)
                            case .multiline:
                                TextField(field.placeholder, text: binding(for: field), axis: .vertical)
                                    .lineLimit(3...6)
                                    .textFieldStyle(.roundedBorder)
                            case .date:
                                DatePicker(field.label, selection: dateBinding(for: field), displayedComponents: .date)
                            case .number:
                                TextField(field.placeholder, text: binding(for: field))
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Кнопка генерации
                Button {
                    generateDocument()
                } label: {
                    Label("Сгенерировать документ", systemImage: "doc.text")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Результат
                if let document = generatedDocument {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Результат")
                                .font(.headline)
                            Spacer()
                            Button {
                                showingShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        
                        Text(document)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .sheet(isPresented: $showingShareSheet) {
                        ShareSheet(activityItems: [document])
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Шаблон")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func binding(for field: TemplateField) -> Binding<String> {
        // Заглушка — в реальном приложении здесь будет словарь значений
        .constant("")
    }
    
    private func dateBinding(for field: TemplateField) -> Binding<Date> {
        .constant(Date())
    }
    
    private func generateDocument() {
        // Заглушка — в реальном приложении здесь будет генерация документа
        generatedDocument = template.sampleText
    }
}

// MARK: - Редактор шаблонов

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var category: DocumentCategory = .claim
    @State private var fields: [TemplateField] = []
    @State private var sampleText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название", text: $name)
                    TextField("Описание", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Picker("Категория", selection: $category) {
                        ForEach(DocumentCategory.allCases.filter { $0 != .all }) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
                Section("Поля") {
                    ForEach(fields) { field in
                        HStack {
                            Text(field.label)
                            Spacer()
                            Text(field.type.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        fields.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        addField()
                    } label: {
                        Label("Добавить поле", systemImage: "plus.circle")
                    }
                }
                
                Section("Пример текста") {
                    TextField("Текст шаблона с {полями}", text: $sampleText, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Новый шаблон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        // Сохранение шаблона
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addField() {
        let field = TemplateField(
            label: "Поле \(fields.count + 1)",
            placeholder: "Введите значение",
            type: .text
        )
        fields.append(field)
    }
}

// MARK: - Модели шаблонов

struct DocumentTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: DocumentCategory
    let fields: [TemplateField]
    let sampleText: String
    
    static let allTemplates: [DocumentTemplate] = [
        DocumentTemplate(
            name: "Исковое заявление",
            description: "Шаблон искового заявления в суд общей юрисдикции",
            category: .claim,
            fields: [
                TemplateField(label: "Название суда", placeholder: "Введите название суда", type: .text),
                TemplateField(label: "Истец", placeholder: "ФИО истца", type: .text),
                TemplateField(label: "Ответчик", placeholder: "ФИО ответчика", type: .text),
                TemplateField(label: "Предмет иска", placeholder: "Опишите предмет иска", type: .multiline),
                TemplateField(label: "Сумма иска", placeholder: "Сумма в рублях", type: .number)
            ],
            sampleText: "В {court} обращается {plaintiff} к {defendant} с иском о {subject} на сумму {amount} рублей."
        ),
        DocumentTemplate(
            name: "Ходатайство",
            description: "Ходатайство о назначении экспертизы",
            category: .motion,
            fields: [
                TemplateField(label: "Название суда", placeholder: "Введите название суда", type: .text),
                TemplateField(label: "Дело №", placeholder: "Номер дела", type: .text),
                TemplateField(label: "Предмет ходатайства", placeholder: "Опишите ходатайство", type: .multiline)
            ],
            sampleText: "В производстве {court} находится дело № {caseNumber}. Прошу назначить {subject}."
        ),
        DocumentTemplate(
            name: "Доверенность",
            description: "Генеральная доверенность на представление интересов",
            category: .powerOfAttorney,
            fields: [
                TemplateField(label: "Доверитель", placeholder: "ФИО доверителя", type: .text),
                TemplateField(label: "Представитель", placeholder: "ФИО представителя", type: .text),
                TemplateField(label: "Дата окончания", placeholder: "Дата", type: .date),
                TemplateField(label: "Полномочия", placeholder: "Перечислите полномочия", type: .multiline)
            ],
            sampleText: "Я, {principal}, доверяю {agent} представлять мои интересы до {date}."
        ),
        DocumentTemplate(
            name: "Жалоба",
            description: "Апелляционная жалоба на решение суда",
            category: .appeal,
            fields: [
                TemplateField(label: "Название суда", placeholder: "Введите название суда", type: .text),
                TemplateField(label: "Решение", placeholder: "Описание обжалуемого решения", type: .multiline),
                TemplateField(label: "Доводы", placeholder: "Доводы жалобы", type: .multiline)
            ],
            sampleText: "На решение {court} от {date} подаётся апелляционная жалоба по следующим доводам: {arguments}."
        ),
        DocumentTemplate(
            name: "Договор",
            description: "Шаблон договора оказания юридических услуг",
            category: .contract,
            fields: [
                TemplateField(label: "Заказчик", placeholder: "ФИО/название заказчика", type: .text),
                TemplateField(label: "Исполнитель", placeholder: "ФИО/название исполнителя", type: .text),
                TemplateField(label: "Предмет договора", placeholder: "Описание услуг", type: .multiline),
                TemplateField(label: "Сумма", placeholder: "Стоимость услуг", type: .number),
                TemplateField(label: "Срок", placeholder: "Срок выполнения", type: .text)
            ],
            sampleText: "Договор между {client} и {lawyer} на оказание юридических услуг по {subject} на сумму {amount} рублей."
        )
    ]
}

struct TemplateField: Identifiable {
    let id = UUID()
    let label: String
    let placeholder: String
    let type: FieldType
}

enum FieldType: String, CaseIterable {
    case text = "text"
    case multiline = "multiline"
    case date = "date"
    case number = "number"
    
    var displayName: String {
        switch self {
        case .text: return "Текст"
        case .multiline: return "Многострочный"
        case .date: return "Дата"
        case .number: return "Число"
        }
    }
}

enum DocumentCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case claim = "claim"
    case motion = "motion"
    case powerOfAttorney = "powerOfAttorney"
    case appeal = "appeal"
    case contract = "contract"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "Все"
        case .claim: return "Иски"
        case .motion: return "Ходатайства"
        case .powerOfAttorney: return "Доверенности"
        case .appeal: return "Жалобы"
        case .contract: return "Договоры"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.on.doc"
        case .claim: return "doc.text"
        case .motion: return "doc.plaintext"
        case .powerOfAttorney: return "doc.person"
        case .appeal: return "doc.arrow.up"
        case .contract: return "doc.append"
        }
    }
}

// MARK: - Компоненты

struct CategoryButton: View {
    let category: DocumentCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.indigo : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct TemplateRow: View {
    let template: DocumentTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            
            Text(template.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(template.category.displayName, systemImage: template.category.icon)
                    .font(.caption2)
                    .foregroundStyle(.indigo)
                
                Spacer()
                
                Text("\(template.fields.count) полей")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
