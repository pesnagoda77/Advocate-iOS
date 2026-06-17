import Foundation

// MARK: - Экспорт данных

struct DataExporter {
    
    // MARK: - JSON Export
    
    static func exportToJSON(clients: [Client], cases: [Case], events: [Event], payments: [Payment], documents: [Document]) -> Data? {
        let exportData = ExportData(
            exportDate: Date(),
            appVersion: AppConstants.appVersion,
            clients: clients.map { ClientExport($0) },
            cases: cases.map { CaseExport($0) },
            events: events.map { EventExport($0) },
            payments: payments.map { PaymentExport($0) },
            documents: documents.map { DocumentExport($0) }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try? encoder.encode(exportData)
    }
    
    static func importFromJSON(_ data: Data) -> ExportData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ExportData.self, from: data)
    }
    
    // MARK: - CSV Export
    
    static func exportClientsToCSV(_ clients: [Client]) -> String {
        var csv = "ID,LastName,FirstName,MiddleName,Phone,Email,Notes,CreatedAt\n"
        
        for client in clients {
            let row = [
                client.id.uuidString,
                escapeCSV(client.lastName),
                escapeCSV(client.firstName),
                escapeCSV(client.middleName),
                escapeCSV(client.phone),
                escapeCSV(client.email),
                escapeCSV(client.notes),
                ISO8601DateFormatter().string(from: client.createdAt)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    static func exportCasesToCSV(_ cases: [Case]) -> String {
        var csv = "ID,Number,Title,Description,Notes,Status,PaymentMethod,HourlyRate,MonthlyAmount,ClientID,CreatedAt\n"
        
        for caseItem in cases {
            let row = [
                caseItem.id.uuidString,
                escapeCSV(caseItem.number),
                escapeCSV(caseItem.title),
                escapeCSV(caseItem.description),
                escapeCSV(caseItem.notes),
                caseItem.status.rawValue,
                caseItem.paymentMethod.rawValue,
                String(caseItem.hourlyRate),
                caseItem.monthlyAmount.map { String($0) } ?? "",
                caseItem.clientId?.uuidString ?? "",
                ISO8601DateFormatter().string(from: caseItem.createdAt)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    static func exportEventsToCSV(_ events: [Event]) -> String {
        var csv = "ID,Type,Title,Description,Notes,Date,DurationHours,Rate,FixedAmount,IsCompleted,CaseID,CreatedAt\n"
        
        for event in events {
            let row = [
                event.id.uuidString,
                event.type.rawValue,
                escapeCSV(event.title),
                escapeCSV(event.description),
                escapeCSV(event.notes),
                ISO8601DateFormatter().string(from: event.date),
                event.durationHours.map { String($0) } ?? "",
                event.rate.map { String($0) } ?? "",
                event.fixedAmount.map { String($0) } ?? "",
                event.isCompleted ? "1" : "0",
                event.caseId?.uuidString ?? "",
                ISO8601DateFormatter().string(from: event.createdAt)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    static func exportPaymentsToCSV(_ payments: [Payment]) -> String {
        var csv = "ID,Amount,Date,Notes,CaseID,CreatedAt\n"
        
        for payment in payments {
            let row = [
                payment.id.uuidString,
                String(payment.amount),
                ISO8601DateFormatter().string(from: payment.date),
                escapeCSV(payment.notes),
                payment.caseId?.uuidString ?? "",
                ISO8601DateFormatter().string(from: payment.createdAt)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
    
    // MARK: - Backup
    
    static func createBackup(clients: [Client], cases: [Case], events: [Event], payments: [Payment], documents: [Document]) -> URL? {
        guard let jsonData = exportToJSON(clients: clients, cases: cases, events: events, payments: payments, documents: documents) else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "advocate_backup_\(dateFormatter.string(from: Date())).json"
        
        let url = FileUtils.documentsDirectory().appendingPathComponent(filename)
        
        do {
            try jsonData.write(to: url)
            return url
        } catch {
            print("Ошибка создания бэкапа: \(error)")
            return nil
        }
    }
    
    static func restoreFromBackup(url: URL) -> ExportData? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return importFromJSON(data)
    }
    
    // MARK: - Helpers
    
    private static func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let clients: [ClientExport]
    let cases: [CaseExport]
    let events: [EventExport]
    let payments: [PaymentExport]
    let documents: [DocumentExport]
}

struct ClientExport: Codable {
    let id: UUID
    let lastName: String
    let firstName: String
    let middleName: String
    let phone: String
    let email: String
    let notes: String
    let createdAt: Date
    
    init(_ client: Client) {
        self.id = client.id
        self.lastName = client.lastName
        self.firstName = client.firstName
        self.middleName = client.middleName
        self.phone = client.phone
        self.email = client.email
        self.notes = client.notes
        self.createdAt = client.createdAt
    }
}

struct CaseExport: Codable {
    let id: UUID
    let number: String
    let title: String
    let description: String
    let notes: String
    let status: String
    let paymentMethod: String
    let hourlyRate: Double
    let monthlyAmount: Double?
    let clientId: UUID?
    let createdAt: Date
    
    init(_ caseItem: Case) {
        self.id = caseItem.id
        self.number = caseItem.number
        self.title = caseItem.title
        self.description = caseItem.description
        self.notes = caseItem.notes
        self.status = caseItem.status.rawValue
        self.paymentMethod = caseItem.paymentMethod.rawValue
        self.hourlyRate = caseItem.hourlyRate
        self.monthlyAmount = caseItem.monthlyAmount
        self.clientId = caseItem.clientId
        self.createdAt = caseItem.createdAt
    }
}

struct EventExport: Codable {
    let id: UUID
    let type: String
    let title: String
    let description: String
    let notes: String
    let date: Date
    let durationHours: Double?
    let rate: Double?
    let fixedAmount: Double?
    let isCompleted: Bool
    let caseId: UUID?
    let createdAt: Date
    
    init(_ event: Event) {
        self.id = event.id
        self.type = event.type.rawValue
        self.title = event.title
        self.description = event.description
        self.notes = event.notes
        self.date = event.date
        self.durationHours = event.durationHours
        self.rate = event.rate
        self.fixedAmount = event.fixedAmount
        self.isCompleted = event.isCompleted
        self.caseId = event.caseId
        self.createdAt = event.createdAt
    }
}

struct PaymentExport: Codable {
    let id: UUID
    let amount: Double
    let date: Date
    let notes: String
    let caseId: UUID?
    let createdAt: Date
    
    init(_ payment: Payment) {
        self.id = payment.id
        self.amount = payment.amount
        self.date = payment.date
        self.notes = payment.notes
        self.caseId = payment.caseId
        self.createdAt = payment.createdAt
    }
}

struct DocumentExport: Codable {
    let id: UUID
    let title: String
    let fileName: String
    let filePath: String
    let documentType: String
    let isFavorite: Bool
    let caseId: UUID?
    let createdAt: Date
    
    init(_ document: Document) {
        self.id = document.id
        self.title = document.title
        self.fileName = document.fileName
        self.filePath = document.filePath
        self.documentType = document.documentType.rawValue
        self.isFavorite = document.isFavorite
        self.caseId = document.caseId
        self.createdAt = document.createdAt
    }
}