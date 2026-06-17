import Foundation
import SwiftData

// MARK: - Модели данных (SwiftData)

@Model
class Client {
    @Attribute(.unique) var id: UUID
    var lastName: String
    var firstName: String
    var middleName: String
    var phone: String
    var email: String
    var notes: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Case.client)
    var cases: [Case]?
    
    init(lastName: String, firstName: String, middleName: String = "", phone: String = "", email: String = "", notes: String = "") {
        self.id = UUID()
        self.lastName = lastName
        self.firstName = firstName
        self.middleName = middleName
        self.phone = phone
        self.email = email
        self.notes = notes
        self.createdAt = Date()
    }
    
    var fullName: String {
        "\(lastName) \(firstName) \(middleName)".trimmingCharacters(in: .whitespaces)
    }
}

@Model
class Case {
    @Attribute(.unique) var id: UUID
    var number: String
    var title: String
    var description: String
    var notes: String
    var status: CaseStatus
    var paymentMethod: PaymentMethod
    var hourlyRate: Double
    var monthlyAmount: Double?
    var paymentStartDate: Date?
    var createdAt: Date
    
    var clientId: UUID?
    @Relationship(inverse: \Client.cases)
    var client: Client?
    
    @Relationship(deleteRule: .cascade, inverse: \Event.case)
    var events: [Event]?
    
    @Relationship(deleteRule: .cascade, inverse: \Payment.case)
    var payments: [Payment]?
    
    @Relationship(deleteRule: .cascade, inverse: \Document.case)
    var documents: [Document]?
    
    init(number: String, title: String, description: String = "", notes: String = "", status: CaseStatus = .active, paymentMethod: PaymentMethod = .hourly, hourlyRate: Double = 0, monthlyAmount: Double? = nil, paymentStartDate: Date? = nil, client: Client? = nil) {
        self.id = UUID()
        self.number = number
        self.title = title
        self.description = description
        self.notes = notes
        self.status = status
        self.paymentMethod = paymentMethod
        self.hourlyRate = hourlyRate
        self.monthlyAmount = monthlyAmount
        self.paymentStartDate = paymentStartDate
        self.createdAt = Date()
        self.client = client
        self.clientId = client?.id
    }
}

enum CaseStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case archived = "ARCHIVED"
    case closed = "CLOSED"
    
    var displayName: String {
        switch self {
        case .active: return "Активно"
        case .archived: return "Архив"
        case .closed: return "Закрыто"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case hourly = "HOURLY"
    case fixed = "FIXED"
    case monthly = "MONTHLY"
    
    var displayName: String {
        switch self {
        case .hourly: return "Почасовая"
        case .fixed: return "Фиксированная"
        case .monthly: return "Ежемесячная"
        }
    }
}

@Model
class Event {
    @Attribute(.unique) var id: UUID
    var type: EventType
    var title: String
    var description: String
    var notes: String
    var date: Date
    var durationHours: Double?
    var rate: Double?
    var fixedAmount: Double?
    var isCompleted: Bool
    var createdAt: Date
    
    var caseId: UUID?
    @Relationship(inverse: \Case.events)
    var case: Case?
    
    init(type: EventType, title: String, description: String = "", notes: String = "", date: Date, durationHours: Double? = nil, rate: Double? = nil, fixedAmount: Double? = nil, case: Case? = nil) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.notes = notes
        self.date = date
        self.durationHours = durationHours
        self.rate = rate
        self.fixedAmount = fixedAmount
        self.isCompleted = false
        self.createdAt = Date()
        self.case = case
        self.caseId = case?.id
    }
}

enum EventType: String, Codable, CaseIterable {
    case meeting = "MEETING"
    case court = "COURT"
    case consultation = "CONSULTATION"
    case documentReview = "DOCUMENT_REVIEW"
    case call = "CALL"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .meeting: return "Встреча"
        case .court: return "Суд"
        case .consultation: return "Консультация"
        case .documentReview: return "Работа с документами"
        case .call: return "Звонок"
        case .other: return "Другое"
        }
    }
    
    var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .court: return "building.columns.fill"
        case .consultation: return "bubble.left.fill"
        case .documentReview: return "doc.text.fill"
        case .call: return "phone.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
class Payment {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var date: Date
    var notes: String
    var createdAt: Date
    
    var caseId: UUID?
    @Relationship(inverse: \Case.payments)
    var case: Case?
    
    init(amount: Double, date: Date, notes: String = "", case: Case? = nil) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.notes = notes
        self.createdAt = Date()
        self.case = case
        self.caseId = case?.id
    }
}

@Model
class Document {
    @Attribute(.unique) var id: UUID
    var title: String
    var fileName: String
    var filePath: String
    var documentType: DocumentType
    var createdAt: Date
    var isFavorite: Bool
    
    var caseId: UUID?
    @Relationship(inverse: \Case.documents)
    var case: Case?
    
    init(title: String, fileName: String, filePath: String, documentType: DocumentType = .other, case: Case? = nil) {
        self.id = UUID()
        self.title = title
        self.fileName = fileName
        self.filePath = filePath
        self.documentType = documentType
        self.createdAt = Date()
        self.isFavorite = false
        self.case = case
        self.caseId = case?.id
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case contract = "CONTRACT"
    case courtOrder = "COURT_ORDER"
    case statement = "STATEMENT"
    case evidence = "EVIDENCE"
    case correspondence = "CORRESPONDENCE"
    case powerOfAttorney = "POWER_OF_ATTORNEY"
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .contract: return "Договор"
        case .courtOrder: return "Судебный документ"
        case .statement: return "Заявление"
        case .evidence: return "Доказательство"
        case .correspondence: return "Переписка"
        case .powerOfAttorney: return "Доверенность"
        case .other: return "Другое"
        }
    }
    
    var icon: String {
        switch self {
        case .contract: return "doc.text.fill"
        case .courtOrder: return "building.columns.fill"
        case .statement: return "pencil.doc.fill"
        case .evidence: return "folder.fill"
        case .correspondence: return "envelope.fill"
        case .powerOfAttorney: return "signature"
        case .other: return "doc.fill"
        }
    }
}