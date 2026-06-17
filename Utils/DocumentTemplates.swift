import Foundation

// MARK: - Расширенные шаблоны документов

struct DocumentTemplates {
    
    static let allTemplates: [DocumentTemplate] = [
        // Исковые заявления
        hodataystvoTemplate,
        iskovoeZayavlenieTemplate,
        zhalobaTemplate,
        
        // Ходатайства
        hodataystvoORassmotreniiTemplate,
        hodataystvoOSvideteleTemplate,
        hodataystvoOExpertizeTemplate,
        
        // Договоры
        dogovorPorucheniyaTemplate,
        dogovorOkazaniyaUslugTemplate,
        dogovorLizingaTemplate,
        
        // Доверенности
        generalnayaDoverennostTemplate,
        specialnayaDoverennostTemplate,
        
        // Претензии
        pretenziyaPoDogovoruTemplate,
        pretenziyaPoKachestvuTemplate,
        
        // Заявления
        zayavlenieOVozbuzhdeniiTemplate,
        zayavlenieOZashiteTemplate,
        
        // Служебные записки
        sluzhebnayaZapiskaTemplate,
        
        // Акты
        aktVypolnennyhRabotTemplate
    ]
    
    // MARK: - Исковые заявления
    
    static let hodataystvoTemplate = DocumentTemplate(
        id: "hodataystvo",
        name: "Ходатайство",
        description: "Универсальное ходатайство в суд",
        category: .motion,
        fields: [
            TemplateField(key: "court", label: "Суд", placeholder: "Название суда", isRequired: true),
            TemplateField(key: "judge", label: "Судья", placeholder: "ФИО судьи", isRequired: false),
            TemplateField(key: "case_number", label: "Номер дела", placeholder: "№ дела", isRequired: true),
            TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО заявителя", isRequired: true),
            TemplateField(key: "subject", label: "Предмет ходатайства", placeholder: "О чём ходатайство", isRequired: true, isMultiline: true),
            TemplateField(key: "justification", label: "Обоснование", placeholder: "Почему просите", isRequired: true, isMultiline: true),
            TemplateField(key: "attachments", label: "Приложения", placeholder: "Перечень документов", isRequired: false, isMultiline: true)
        ],
        generate: { fields in
            generateHodataystvo(fields: fields)
        }
    )
    
    static let iskovoeZayavlenieTemplate = DocumentTemplate(
        id: "iskovoe_zayavlenie",
        name: "Исковое заявление",
        description: "Иск в суд общей юрисдикции",
        category: .claim,
        fields: [
            TemplateField(key: "court", label: "Суд", placeholder: "Название суда", isRequired: true),
            TemplateField(key: "plaintiff", label: "Истец", placeholder: "ФИО/название истца", isRequired: true),
            TemplateField(key: "plaintiff_address", label: "Адрес истца", placeholder: "Адрес для корреспонденции", isRequired: true),
            TemplateField(key: "defendant", label: "Ответчик", placeholder: "ФИО/название ответчика", isRequired: true),
            TemplateField(key: "defendant_address", label: "Адрес ответчика", placeholder: "Адрес ответчика", isRequired: true),
            TemplateField(key: "claim_amount", label: "Цена иска", placeholder: "Сумма в рублях", isRequired: true),
            TemplateField(key: "subject", label: "Предмет спора", placeholder: "О чём спор", isRequired: true, isMultiline: true),
            TemplateField(key: "circumstances", label: "Обстоятельства дела", placeholder: "Описание ситуации", isRequired: true, isMultiline: true),
            TemplateField(key: "evidence", label: "Доказательства", placeholder: "Перечень доказательств", isRequired: true, isMultiline: true),
            TemplateField(key: "legal_basis", label: "Правовое обоснование", placeholder: "Ссылки на законы", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateIskovoeZayavlenie(fields: fields)
        }
    )
    
    static let zhalobaTemplate = DocumentTemplate(
        id: "zhaloba",
        name: "Жалоба",
        description: "Апелляционная/кассационная жалоба",
        category: .appeal,
        fields: [
            TemplateField(key: "court", label: "Суд", placeholder: "Название суда", isRequired: true),
            TemplateField(key: "appellant", label: "Заявитель", placeholder: "ФИО заявителя", isRequired: true),
            TemplateField(key: "case_number", label: "Номер дела", placeholder: "№ дела", isRequired: true),
            TemplateField(key: "decision_date", label: "Дата решения", placeholder: "Дата вынесения решения", isRequired: true),
            TemplateField(key: "essence", label: "Суть жалобы", placeholder: "В чём суть", isRequired: true, isMultiline: true),
            TemplateField(key: "arguments", label: "Доводы", placeholder: "Юридические доводы", isRequired: true, isMultiline: true),
            TemplateField(key: "requests", label: "Просьбы", placeholder: "Чего просите", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateZhaloba(fields: fields)
        }
    )
    
    // MARK: - Ходатайства
    
    static let hodataystvoORassmotreniiTemplate = DocumentTemplate(
        id: "hodataystvo_rassmotrenie",
        name: "Ходатайство о рассмотрении дела",
        description: "Ходатайство о рассмотрении дела в отсутствие",
        category: .motion,
        fields: [
            TemplateField(key: "court", label: "Суд", placeholder: "Название суда", isRequired: true),
            TemplateField(key: "case_number", label: "Номер дела", placeholder: "№ дела", isRequired: true),
            TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "reason", label: "Причина отсутствия", placeholder: "Почему не можете присутствовать", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateHodataystvoORassmotrenii(fields: fields)
        }
    )
    
    static let hodataystvoOSvideteleTemplate = DocumentTemplate(
        id: "hodataystvo_svidetel",
        name: "Ходатайство о вызове свидетеля",
        description: "Ходатайство о вызове свидетеля в суд",
        category: .motion,
        fields: [
            TemplateField(key: "court", label: "Суд", placeholder: "Название суда", isRequired: true),
            TemplateField(key: "case_number", label: "Номер дела", placeholder: "№ дела", isRequired: true),
            TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "witness", label: "Свидетель", placeholder: "ФИО свидетеля", isRequired: true),
            TemplateField(key: "witness_address", label: "Адрес свидетеля", placeholder: "Адрес", isRequired: true),
            TemplateField(key: "relevance", label: "Показания", placeholder: "Что может подтвердить", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateHodataystvoOSvidetele(fields: fields)
        }
    )
    
    static let hodataystvoOExpertizeTemplate = DocumentTemplate(
        id: "hodataystvo_expertiza",
        name: "Ходатайство о назначении экспертизы",
        description: "Ходатайство о назначении судебной экспертизы",
        category: .motion,
        fields: [
            TemplateField(key: "court", label: "Суд", placeholder: "Название суда", isRequired: true),
            TemplateField(key: "case_number", label: "Номер дела", placeholder: "№ дела", isRequired: true),
            TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "expertise_type", label: "Вид экспертизы", placeholder: "Какая экспертиза нужна", isRequired: true),
            TemplateField(key: "questions", label: "Вопросы эксперту", placeholder: "Перечень вопросов", isRequired: true, isMultiline: true),
            TemplateField(key: "justification", label: "Обоснование", placeholder: "Почему нужна экспертиза", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateHodataystvoOExpertize(fields: fields)
        }
    )
    
    // MARK: - Договоры
    
    static let dogovorPorucheniyaTemplate = DocumentTemplate(
        id: "dogovor_porucheniya",
        name: "Договор поручения",
        description: "Договор поручения на оказание юридических услуг",
        category: .contract,
        fields: [
            TemplateField(key: "principal", label: "Доверитель", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "principal_address", label: "Адрес доверителя", placeholder: "Адрес", isRequired: true),
            TemplateField(key: "agent", label: "Поверенный", placeholder: "ФИО юриста", isRequired: true),
            TemplateField(key: "agent_address", label: "Адрес поверенного", placeholder: "Адрес", isRequired: true),
            TemplateField(key: "subject", label: "Предмет договора", placeholder: "Что поручаете", isRequired: true, isMultiline: true),
            TemplateField(key: "amount", label: "Вознаграждение", placeholder: "Сумма в рублях", isRequired: true),
            TemplateField(key: "term", label: "Срок", placeholder: "Срок действия", isRequired: true),
            TemplateField(key: "special_conditions", label: "Особые условия", placeholder: "Дополнительные условия", isRequired: false, isMultiline: true)
        ],
        generate: { fields in
            generateDogovorPorucheniya(fields: fields)
        }
    )
    
    static let dogovorOkazaniyaUslugTemplate = DocumentTemplate(
        id: "dogovor_uslug",
        name: "Договор об оказании услуг",
        description: "Договор на оказание юридических услуг",
        category: .contract,
        fields: [
            TemplateField(key: "client", label: "Заказчик", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "client_address", label: "Адрес заказчика", placeholder: "Адрес", isRequired: true),
            TemplateField(key: "executor", label: "Исполнитель", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "executor_address", label: "Адрес исполнителя", placeholder: "Адрес", isRequired: true),
            TemplateField(key: "services", label: "Услуги", placeholder: "Перечень услуг", isRequired: true, isMultiline: true),
            TemplateField(key: "amount", label: "Стоимость", placeholder: "Сумма в рублях", isRequired: true),
            TemplateField(key: "payment_terms", label: "Порядок оплаты", placeholder: "Когда и как платить", isRequired: true, isMultiline: true),
            TemplateField(key: "term", label: "Срок", placeholder: "Срок оказания услуг", isRequired: true)
        ],
        generate: { fields in
            generateDogovorOkazaniyaUslug(fields: fields)
        }
    )
    
    static let dogovorLizingaTemplate = DocumentTemplate(
        id: "dogovor_lizinga",
        name: "Договор лизинга",
        description: "Договор финансовой аренды (лизинга)",
        category: .contract,
        fields: [
            TemplateField(key: "lessor", label: "Лизингодатель", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "lessee", label: "Лизингополучатель", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "seller", label: "Продавец", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "property", label: "Имущество", placeholder: "Что передаётся в лизинг", isRequired: true, isMultiline: true),
            TemplateField(key: "cost", label: "Стоимость", placeholder: "Стоимость имущества", isRequired: true),
            TemplateField(key: "lease_term", label: "Срок лизинга", placeholder: "На сколько месяцев", isRequired: true),
            TemplateField(key: "monthly_payment", label: "Ежемесячный платёж", placeholder: "Сумма", isRequired: true),
            TemplateField(key: "buyout_price", label: "Выкупная цена", placeholder: "Стоимость выкупа", isRequired: true)
        ],
        generate: { fields in
            generateDogovorLizinga(fields: fields)
        }
    )
    
    // MARK: - Доверенности
    
    static let generalnayaDoverennostTemplate = DocumentTemplate(
        id: "generalnaya_doverennost",
        name: "Генеральная доверенность",
        description: "Генеральная доверенность на все действия",
        category: .powerOfAttorney,
        fields: [
            TemplateField(key: "principal", label: "Доверитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "principal_birthdate", label: "Дата рождения", placeholder: "ДД.ММ.ГГГГ", isRequired: true),
            TemplateField(key: "principal_passport", label: "Паспорт", placeholder: "Серия номер", isRequired: true),
            TemplateField(key: "agent", label: "Представитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "agent_birthdate", label: "Дата рождения представителя", placeholder: "ДД.ММ.ГГГГ", isRequired: true),
            TemplateField(key: "agent_passport", label: "Паспорт представителя", placeholder: "Серия номер", isRequired: true),
            TemplateField(key: "term", label: "Срок", placeholder: "На сколько выдаётся", isRequired: true),
            TemplateField(key: "powers", label: "Полномочия", placeholder: "Перечень полномочий", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateGeneralnayaDoverennost(fields: fields)
        }
    )
    
    static let specialnayaDoverennostTemplate = DocumentTemplate(
        id: "specialnaya_doverennost",
        name: "Специальная доверенность",
        description: "Доверенность на конкретные действия",
        category: .powerOfAttorney,
        fields: [
            TemplateField(key: "principal", label: "Доверитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "agent", label: "Представитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "specific_powers", label: "Конкретные полномочия", placeholder: "На что именно", isRequired: true, isMultiline: true),
            TemplateField(key: "term", label: "Срок", placeholder: "До какого числа", isRequired: true)
        ],
        generate: { fields in
            generateSpecialnayaDoverennost(fields: fields)
        }
    )
    
    // MARK: - Претензии
    
    static let pretenziyaPoDogovoruTemplate = DocumentTemplate(
        id: "pretenziya_dogovor",
        name: "Претензия по договору",
        description: "Претензия о нарушении условий договора",
        category: .claim,
        fields: [
            TemplateField(key: "recipient", label: "Адресат", placeholder: "Название организации/ФИО", isRequired: true),
            TemplateField(key: "recipient_address", label: "Адрес адресата", placeholder: "Адрес", isRequired: true),
            TemplateField(key: "sender", label: "Отправитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "sender_address", label: "Адрес отправителя", placeholder: "Адрес", isRequired: true),
            TemplateField(key: "contract_number", label: "Номер договора", placeholder: "№ договора", isRequired: true),
            TemplateField(key: "contract_date", label: "Дата договора", placeholder: "ДД.ММ.ГГГГ", isRequired: true),
            TemplateField(key: "violation", label: "Нарушение", placeholder: "Что нарушено", isRequired: true, isMultiline: true),
            TemplateField(key: "demands", label: "Требования", placeholder: "Чего требуете", isRequired: true, isMultiline: true),
            TemplateField(key: "deadline", label: "Срок ответа", placeholder: "Сколько дней", isRequired: true)
        ],
        generate: { fields in
            generatePretenziyaPoDogovoru(fields: fields)
        }
    )
    
    static let pretenziyaPoKachestvuTemplate = DocumentTemplate(
        id: "pretenziya_kachestvo",
        name: "Претензия по качеству",
        description: "Претензия о некачественном товаре/услуге",
        category: .claim,
        fields: [
            TemplateField(key: "recipient", label: "Адресат", placeholder: "Название организации", isRequired: true),
            TemplateField(key: "sender", label: "Отправитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "product", label: "Товар/услуга", placeholder: "Что приобрели", isRequired: true),
            TemplateField(key: "purchase_date", label: "Дата покупки", placeholder: "ДД.ММ.ГГГГ", isRequired: true),
            TemplateField(key: "defects", label: "Недостатки", placeholder: "Что не так", isRequired: true, isMultiline: true),
            TemplateField(key: "demands", label: "Требования", placeholder: "Замена/возврат/ремонт", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generatePretenziyaPoKachestvu(fields: fields)
        }
    )
    
    // MARK: - Заявления
    
    static let zayavlenieOVozbuzhdeniiTemplate = DocumentTemplate(
        id: "zayavlenie_vozbuzhdenie",
        name: "Заявление о возбуждении дела",
        description: "Заявление о возбуждении уголовного/административного дела",
        category: .statement,
        fields: [
            TemplateField(key: "authority", label: "Орган", placeholder: "Куда подаётся", isRequired: true),
            TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "applicant_address", label: "Адрес", placeholder: "Адрес заявителя", isRequired: true),
            TemplateField(key: "victim", label: "Потерпевший", placeholder: "ФИО (если не заявитель)", isRequired: false),
            TemplateField(key: "offense", label: "Преступление/правонарушение", placeholder: "Что произошло", isRequired: true, isMultiline: true),
            TemplateField(key: "date", label: "Дата", placeholder: "Когда произошло", isRequired: true),
            TemplateField(key: "place", label: "Место", placeholder: "Где произошло", isRequired: true),
            TemplateField(key: "witnesses", label: "Свидетели", placeholder: "Кто видел", isRequired: false, isMultiline: true),
            TemplateField(key: "evidence", label: "Доказательства", placeholder: "Что есть", isRequired: false, isMultiline: true)
        ],
        generate: { fields in
            generateZayavlenieOVozbuzhdenii(fields: fields)
        }
    )
    
    static let zayavlenieOZashiteTemplate = DocumentTemplate(
        id: "zayavlenie_zashita",
        name: "Заявление о защите прав",
        description: "Заявление о защите прав потребителя/гражданина",
        category: .statement,
        fields: [
            TemplateField(key: "authority", label: "Орган", placeholder: "Куда подаётся", isRequired: true),
            TemplateField(key: "applicant", label: "Заявитель", placeholder: "ФИО", isRequired: true),
            TemplateField(key: "rights_violated", label: "Нарушенные права", placeholder: "Какие права", isRequired: true, isMultiline: true),
            TemplateField(key: "circumstances", label: "Обстоятельства", placeholder: "Что произошло", isRequired: true, isMultiline: true),
            TemplateField(key: "demands", label: "Требования", placeholder: "Чего требуете", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateZayavlenieOZashite(fields: fields)
        }
    )
    
    // MARK: - Служебные записки
    
    static let sluzhebnayaZapiskaTemplate = DocumentTemplate(
        id: "sluzhebnaya_zapiska",
        name: "Служебная записка",
        description: "Внутренняя служебная записка",
        category: .memo,
        fields: [
            TemplateField(key: "recipient", label: "Кому", placeholder: "Должность/ФИО", isRequired: true),
            TemplateField(key: "sender", label: "От кого", placeholder: "Должность/ФИО", isRequired: true),
            TemplateField(key: "subject", label: "Тема", placeholder: "О чём", isRequired: true),
            TemplateField(key: "content", label: "Содержание", placeholder: "Текст записки", isRequired: true, isMultiline: true),
            TemplateField(key: "proposal", label: "Предложение", placeholder: "Что предлагаете", isRequired: true, isMultiline: true)
        ],
        generate: { fields in
            generateSluzhebnayaZapiska(fields: fields)
        }
    )
    
    // MARK: - Акты
    
    static let aktVypolnennyhRabotTemplate = DocumentTemplate(
        id: "akt_rabot",
        name: "Акт выполненных работ",
        description: "Акт приёмки выполненных работ/услуг",
        category: .act,
        fields: [
            TemplateField(key: "customer", label: "Заказчик", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "executor", label: "Исполнитель", placeholder: "ФИО/название", isRequired: true),
            TemplateField(key: "contract_number", label: "Договор", placeholder: "№ договора", isRequired: true),
            TemplateField(key: "work_description", label: "Описание работ", placeholder: "Что выполнено", isRequired: true, isMultiline: true),
            TemplateField(key: "start_date", label: "Дата начала", placeholder: "ДД.ММ.ГГГГ", isRequired: true),
            TemplateField(key: "end_date", label: "Дата окончания", placeholder: "ДД.ММ.ГГГГ", isRequired: true),
            TemplateField(key: "amount", label: "Стоимость", placeholder: "Сумма", isRequired: true)
        ],
        generate: { fields in
            generateAktVypolnennyhRabot(fields: fields)
        }
    )
}

// MARK: - Модели шаблонов

struct DocumentTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let category: DocumentCategory
    let fields: [TemplateField]
    let generate: ([String: String]) -> String
}

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

enum DocumentCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case claim = "claim"
    case motion = "motion"
    case powerOfAttorney = "powerOfAttorney"
    case appeal = "appeal"
    case contract = "contract"
    case statement = "statement"
    case memo = "memo"
    case act = "act"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "Все"
        case .claim: return "Иски/Претензии"
        case .motion: return "Ходатайства"
        case .powerOfAttorney: return "Доверенности"
        case .appeal: return "Жалобы"
        case .contract: return "Договоры"
        case .statement: return "Заявления"
        case .memo: return "Служебные"
        case .act: return "Акты"
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
        case .statement: return "pencil.doc"
        case .memo: return "note.text"
        case .act: return "checkmark.seal"
        }
    }
}