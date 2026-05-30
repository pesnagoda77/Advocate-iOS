import SwiftUI
import SwiftData

// MARK: - AI Генератор документов

struct DocumentGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let caseItem: Case?
    
    @State private var selectedTemplate: DocumentTemplate = .hodataystvo
    @State private var fieldValues: [String: String] = [:]
    @State private var generatedText: String = ""
    @State private var isGenerating = false
    @State private var showResult = false
    @State private var documentTitle = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Шаблон") {
                    Picker("Шаблон", selection: $selectedTemplate) {
                        ForEach(DocumentTemplate.allCases, id: \.self) { template in
                            Text(template.displayName).tag(template)
                        }
                    }
                    .onChange(of: selectedTemplate) { _ in
                        fieldValues = [:]
                        generatedText = ""
                        showResult = false
                    }
                }
                
                Section("Поля") {
                    ForEach(selectedTemplate.fields, id: \.key) { field in
                        if field.isMultiline {
                            TextEditor(text: binding(for: field.key))
                                .frame(minHeight: 100)
                        } else {
                            TextField(field.placeholder, text: binding(for: field.key))
                        }
                    }
                }
                
                if showResult {
                    Section("Результат") {
                        TextEditor(text: $generatedText)
                            .frame(minHeight: 200)
                    }
                    
                    Section("Сохранение") {
                        TextField("Название документа", text: $documentTitle)
                        
                        Button("Сохранить как PDF") {
                            saveAsPDF()
                        }
                        .disabled(documentTitle.isEmpty)
                        
                        Button("Копировать текст") {
                            UIPasteboard.general.string = generatedText
                        }
                    }
                }
            }
            .navigationTitle("Генератор документов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                if !showResult {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Сгенерировать") {
                            generateDocument()
                        }
                        .disabled(!isFormValid)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        selectedTemplate.fields
            .filter { $0.isRequired }
            .allSatisfy { field in
                !(fieldValues[field.key]?.isEmpty ?? true)
            }
    }
    
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { fieldValues[key] ?? "" },
            set: { fieldValues[key] = $0 }
        )
    }
    
    private func generateDocument() {
        isGenerating = true
        
        // Локальная генерация (rule-based)
        let result = selectedTemplate.generate(fields: fieldValues, caseItem: caseItem)
        
        generatedText = result
        documentTitle = "\(selectedTemplate.displayName) \(Date().formatted(.dateTime.day().month().year()))"
        showResult = true
        isGenerating = false
    }
    
    private func saveAsPDF() {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            let attributedText = NSAttributedString(string: generatedText, attributes: attributes)
            attributedText.draw(in: CGRect(x: 50, y: 50, width: 512, height: 692))
        }
        
        let fileName = "\(documentTitle)_\(Date().timeIntervalSince1970).pdf"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        try? data.write(to: fileURL)
        
        let document = Document(
            title: documentTitle,
            fileName: fileName,
            filePath: fileURL.path,
            documentType: .generated,
            isFavorite: false
        )
        modelContext.insert(document)
        
        if let caseItem = caseItem {
            caseItem.documents.append(document)
        }
        
        dismiss()
    }
}

// MARK: - Шаблоны документов

enum DocumentTemplate: CaseIterable {
    case hodataystvo
    case zhaloba
    case zayavlenie
    case dogovor
    case doverennost
    case pretenziya
    
    var displayName: String {
        switch self {
        case .hodataystvo: return "Ходатайство"
        case .zhaloba: return "Жалоба"
        case .zayavlenie: return "Заявление"
        case .dogovor: return "Договор"
        case .doverennost: return "Доверенность"
        case .pretenziya: return "Претензия"
        }
    }
    
    var fields: [TemplateField] {
        switch self {
        case .hodataystvo:
            return [
                TemplateField(key: "organ", label: "Орган", placeholder: "Название органа", isRequired: true),
                TemplateField(key: "investigator", label: "Следователь", placeholder: "ФИО следователя", isRequired: true),
                TemplateField(key: "case_number", label: "Номер дела", placeholder: "№ дела", isRequired: true),
                TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО заявителя", isRequired: true),
                TemplateField(key: "subject", label: "Предмет", placeholder: "О чем ходатайство", isRequired: true),
                TemplateField(key: "justification", label: "Обоснование", placeholder: "Обоснование", isRequired: false, isMultiline: true)
            ]
        case .zhaloba:
            return [
                TemplateField(key: "prosecutor", label: "Прокуратура", placeholder: "Название прокуратуры", isRequired: true),
                TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО заявителя", isRequired: true),
                TemplateField(key: "against", label: "На кого жалоба", placeholder: "На кого подается жалоба", isRequired: true),
                TemplateField(key: "case_number", label: "Номер дела", placeholder: "№ дела", isRequired: true),
                TemplateField(key: "essence", label: "Суть", placeholder: "Суть жалобы", isRequired: true, isMultiline: true),
                TemplateField(key: "evidence", label: "Доказательства", placeholder: "Доказательства", isRequired: false, isMultiline: true)
            ]
        case .zayavlenie:
            return [
                TemplateField(key: "organ", label: "Орган", placeholder: "Название органа", isRequired: true),
                TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО заявителя", isRequired: true),
                TemplateField(key: "victim", label: "Потерпевший", placeholder: "ФИО потерпевшего (если не заявитель)", isRequired: false),
                TemplateField(key: "crime", label: "Преступление", placeholder: "Статья/состав преступления", isRequired: true),
                TemplateField(key: "date", label: "Дата", placeholder: "Дата происшествия", isRequired: true),
                TemplateField(key: "place", label: "Место", placeholder: "Место происшествия", isRequired: true),
                TemplateField(key: "description", label: "Описание", placeholder: "Описание происшествия", isRequired: true, isMultiline: true),
                TemplateField(key: "evidence", label: "Доказательства", placeholder: "Доказательства", isRequired: false, isMultiline: true)
            ]
        case .dogovor:
            return [
                TemplateField(key: "client", label: "Клиент", placeholder: "ФИО клиента", isRequired: true),
                TemplateField(key: "lawyer", label: "Юрист", placeholder: "ФИО юриста", isRequired: true),
                TemplateField(key: "service", label: "Услуга", placeholder: "Описание услуги", isRequired: true, isMultiline: true),
                TemplateField(key: "amount", label: "Сумма", placeholder: "Сумма договора", isRequired: true),
                TemplateField(key: "term", label: "Срок", placeholder: "Срок оказания услуги", isRequired: true),
                TemplateField(key: "conditions", label: "Условия", placeholder: "Дополнительные условия", isRequired: false, isMultiline: true)
            ]
        case .doverennost:
            return [
                TemplateField(key: "principal", label: "Доверитель", placeholder: "ФИО доверителя", isRequired: true),
                TemplateField(key: "agent", label: "Представитель", placeholder: "ФИО представителя", isRequired: true),
                TemplateField(key: "powers", label: "Полномочия", placeholder: "Описание полномочий", isRequired: true, isMultiline: true),
                TemplateField(key: "term", label: "Срок", placeholder: "Срок действия", isRequired: true)
            ]
        case .pretenziya:
            return [
                TemplateField(key: "recipient", label: "Адресат", placeholder: "Название организации/ФИО", isRequired: true),
                TemplateField(key: "sender", label: "Отправитель", placeholder: "ФИО отправителя", isRequired: true),
                TemplateField(key: "subject", label: "Предмет", placeholder: "Предмет претензии", isRequired: true),
                TemplateField(key: "essence", label: "Суть", placeholder: "Суть претензии", isRequired: true, isMultiline: true),
                TemplateField(key: "demands", label: "Требования", placeholder: "Требования", isRequired: true, isMultiline: true),
                TemplateField(key: "deadline", label: "Срок ответа", placeholder: "Срок для ответа", isRequired: true)
            ]
        }
    }
    
    func generate(fields: [String: String], caseItem: Case?) -> String {
        switch self {
        case .hodataystvo:
            return generateHodataystvo(fields: fields)
        case .zhaloba:
            return generateZhaloba(fields: fields)
        case .zayavlenie:
            return generateZayavlenie(fields: fields)
        case .dogovor:
            return generateDogovor(fields: fields, caseItem: caseItem)
        case .doverennost:
            return generateDoverennost(fields: fields)
        case .pretenziya:
            return generatePretenziya(fields: fields)
        }
    }
    
    private func generateHodataystvo(fields: [String: String]) -> String {
        let organ = fields["organ"] ?? "[ОРГАН]"
        let investigator = fields["investigator"] ?? "[СЛЕДОВАТЕЛЬ]"
        let caseNumber = fields["case_number"] ?? "[НОМЕР ДЕЛА]"
        let applicant = fields["applicant"] ?? "[ЗАЯВИТЕЛЬ]"
        let subject = fields["subject"] ?? "[ПРЕДМЕТ]"
        let justification = fields["justification"] ?? ""
        let currentDate = Date().formatted(date: .numeric, time: .omitted)
        
        var result = """
        В \(organ)
        
        Следователю
        \(investigator)
        
        От: \(applicant)
        
        Дело № \(caseNumber)
        
        ХОДАТАЙСТВО
        \(subject)
        
        В производстве \(organ) находится уголовное дело № \(caseNumber).
        """
        
        if !justification.isEmpty {
            result += "\n\nОбоснование:\n\(justification)"
        }
        
        result += """
        
        
        На основании изложенного, руководствуясь ст. 198, 199, 207 УПК РФ,
        
        ПРОШУ:
        1. \(subject)
        2. Известить заявителя о месте и времени производства следственного действия.
        
        Приложение:
        1. Копия доверенности (при наличии)
        
        \(currentDate)                    _________________ /\(applicant)/
        """
        
        return result
    }
    
    private func generateZhaloba(fields: [String: String]) -> String {
        let prosecutor = fields["prosecutor"] ?? "[ПРОКУРАТУРА]"
        let applicant = fields["applicant"] ?? "[ЗАЯВИТЕЛЬ]"
        let against = fields["against"] ?? "[НА КОГО]"
        let caseNumber = fields["case_number"] ?? "[НОМЕР ДЕЛА]"
        let essence = fields["essence"] ?? "[СУТЬ]"
        let evidence = fields["evidence"] ?? ""
        let currentDate = Date().formatted(date: .numeric, time: .omitted)
        
        var result = """
        В \(prosecutor)
        
        От: \(applicant)
        
        ЖАЛОБА
        на действия (бездействие) \(against)
        
        По уголовному делу № \(caseNumber)
        
        УВАЖАЕМАЯ ПРОКУРАТУРА!
        
        Довожу до Вашего сведения следующее.
        
        \(essence)
        """
        
        if !evidence.isEmpty {
            result += "\n\nДоказательства незаконности действий:\n\(evidence)"
        }
        
        result += """
        
        
        Считаю указанные действия незаконными и необоснованными по следующим основаниям:
        
        1. Действия \(against) нарушают права и законные интересы заявителя.
        2. Указанные действия не соответствуют требованиям УПК РФ.
        3. Заявителем не были соблюдены процессуальные сроки по вине должностного лица.
        
        На основании изложенного, руководствуясь ст. 21 ФЗ «О прокуратуре РФ»,
        ст. 124, 125, 146 УПК РФ,
        
        ПРОШУ:
        1. Проверить законность действий \(against).
        2. Отменить незаконное решение (действие).
        3. Восстановить права заявителя.
        4. О принятом решении сообщить заявителю в письменной форме.
        
        Приложения:
        1. Копия жалобы
        2. Документы, подтверждающие изложенное
        
        \(currentDate)                    _________________ /\(applicant)/
        """
        
        return result
    }
    
    private func generateZayavlenie(fields: [String: String]) -> String {
        let organ = fields["organ"] ?? "[ОРГАН]"
        let applicant = fields["applicant"] ?? "[ЗАЯВИТЕЛЬ]"
        let victimInput = fields["victim"] ?? ""
        let victim = victimInput.isEmpty ? applicant : victimInput
        let crime = fields["crime"] ?? "[ПРЕСТУПЛЕНИЕ]"
        let date = fields["date"] ?? "[ДАТА]"
        let place = fields["place"] ?? "[МЕСТО]"
        let description = fields["description"] ?? "[ОПИСАНИЕ]"
        let evidence = fields["evidence"] ?? ""
        let currentDate = Date().formatted(date: .numeric, time: .omitted)
        
        var result = """
        В \(organ)
        
        От: \(applicant)
        """
        
        if victim != applicant {
            result += "\nПотерпевший: \(victim)"
        }
        
        result += """
        
        
        ЗАЯВЛЕНИЕ
        о возбуждении уголовного дела
        
        Прошу возбудить уголовное дело в отношении неустановленного лица
        по факту \(crime).
        
        ОБСТОЯТЕЛЬСТВА ДЕЛА:
        
        \(date) в \(place) произошло следующее:
        
        \(description)
        
        В результате совершенного деяния причинен значительный материальный
        и моральный ущерб.
        
        ПРИЗНАКИ ПРЕСТУПЛЕНИЯ:
        
        Действия неустановленного лица содержат признаки состава преступления,
        предусмотренного \(crime), а именно:
        - наличие объективной стороны преступления;
        - наличие субъективной стороны (прямой умысел);
        - причинение значительного вреда.
        """
        
        if !evidence.isEmpty {
            result += "\n\nДоказательства:\n\(evidence)"
        }
        
        result += """
        
        
        На основании изложенного, руководствуясь ст. 140, 141, 144, 145 УПК РФ,
        
        ПРОШУ:
        1. Возбудить уголовное дело по признакам состава преступления,
        предусмотренного \(crime).
        2. Принять меры к установлению лица, совершившего преступление.
        3. О принятом решении и ходе расследования сообщить заявителю.
        
        Приложения:
        1. Копия заявления
        2. Документы, подтверждающие изложенное
        
        \(currentDate)                    _________________ /\(applicant)/
        """
        
        return result
    }
    
    private func generateDogovor(fields: [String: String], caseItem: Case?) -> String {
        let client = fields["client"] ?? caseItem?.client?.fullName ?? "[КЛИЕНТ]"
        let lawyer = fields["lawyer"] ?? "[ЮРИСТ]"
        let service = fields["service"] ?? "[УСЛУГА]"
        let amount = fields["amount"] ?? "[СУММА]"
        let term = fields["term"] ?? "[СРОК]"
        let conditions = fields["conditions"] ?? ""
        let currentDate = Date().formatted(date: .numeric, time: .omitted)
        
        var result = """
        ДОГОВОР № ___
        на оказание юридических услуг
        
        г. ________________\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t
    private func generateDoverennost(fields: [String: String]) -> String {
        let principal = fields["principal"] ?? "[ДОВЕРИТЕЛЬ]"
        let agent = fields["agent"] ?? "[ПРЕДСТАВИТЕЛЬ]"
        let powers = fields["powers"] ?? "[ПОЛНОМОЧИЯ]"
        let term = fields["term"] ?? "[СРОК]"
        let currentDate = Date().formatted(date: .numeric, time: .omitted)
        
        return """
        ДОВЕРЕННОСТЬ № ___
        
        г. ________________\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t
    private func generatePretenziya(fields: [String: String]) -> String {
        let recipient = fields["recipient"] ?? "[АДРЕСАТ]"
        let sender = fields["sender"] ?? "[ОТПРАВИТЕЛЬ]"
        let subject = fields["subject"] ?? "[ПРЕДМЕТ]"
        let essence = fields["essence"] ?? "[СУТЬ]"
        let demands = fields["demands"] ?? "[ТРЕБОВАНИЯ]"
        let deadline = fields["deadline"] ?? "[СРОК]"
        let currentDate = Date().formatted(date: .numeric, time: .omitted)
        
        return """
        В \(recipient)
        
        От: \(sender)
        
        ПРЕТЕНЗИЯ
        \(subject)
        
        \(essence)
        
        ТРЕБОВАНИЯ:
        \(demands)
        
        Прошу рассмотреть данную претензию и сообщить о результатах в срок до \(deadline).
        В случае неудовлетворения требований в указанный срок, я буду вынужден обратиться в суд.
        
        \(currentDate)                    _________________ /\(sender)/
        """
    }
}

// MARK: - Модель поля шаблона

struct TemplateField: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let placeholder: String
    let isRequired: Bool
    let isMultiline: Bool
    
    init(key: String, label: String, placeholder: String, isRequired: Bool, isMultiline: Bool = false) {
        self.key = key
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.isMultiline = isMultiline
    }
}
