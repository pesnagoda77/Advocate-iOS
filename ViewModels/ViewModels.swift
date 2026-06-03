import SwiftUI
import SwiftData

// MARK: - ViewModels для бизнес-логики

@Observable
class ClientViewModel {
    private var modelContext: ModelContext?
    
    func setupContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func createClient(lastName: String, firstName: String, middleName: String = "", phone: String = "", email: String = "") -> Client? {
        guard let context = modelContext else { return nil }
        
        let client = Client(lastName: lastName, firstName: firstName, middleName: middleName, phone: phone, email: email)
        context.insert(client)
        
        do {
            try context.save()
            return client
        } catch {
            print("Ошибка сохранения клиента: \(error)")
            return nil
        }
    }
    
    func deleteClient(_ client: Client) {
        guard let context = modelContext else { return }
        context.delete(client)
        try? context.save()
    }
    
    func searchClients(query: String, in clients: [Client]) -> [Client] {
        guard !query.isEmpty else { return clients }
        return clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(query) ||
            $0.phone.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
}

@Observable
class CaseViewModel {
    private var modelContext: ModelContext?
    
    func setupContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func createCase(number: String, title: String, description: String = "", status: CaseStatus = .active, paymentMethod: PaymentMethod = .hourly, client: Client? = nil, monthlyAmount: Double? = nil, paymentStartDate: Date? = nil) -> Case? {
        guard let context = modelContext else { return nil }
        
        let caseItem = Case(number: number, title: title, description: description, status: status, paymentMethod: paymentMethod)
        caseItem.client = client
        caseItem.monthlyAmount = monthlyAmount
        caseItem.paymentStartDate = paymentStartDate
        
        context.insert(caseItem)
        
        do {
            try context.save()
            return caseItem
        } catch {
            print("Ошибка сохранения дела: \(error)")
            return nil
        }
    }
    
    func deleteCase(_ caseItem: Case) {
        guard let context = modelContext else { return }
        context.delete(caseItem)
        try? context.save()
    }
    
    func totalEarnings(from cases: [Case]) -> Double {
        cases.reduce(0) { total, caseItem in
            total + (caseItem.payments?.reduce(0) { $0 + $1.amount } ?? 0)
        }
    }
    
    func activeCasesCount(from cases: [Case]) -> Int {
        cases.filter { $0.status == .active }.count
    }
    
    func casesByStatus(_ status: CaseStatus, from cases: [Case]) -> [Case] {
        cases.filter { $0.status == status }
    }
}

@Observable
class EventViewModel {
    private var modelContext: ModelContext?
    
    func setupContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func createEvent(type: EventType, date: Date, duration: Int, notes: String = "", caseItem: Case? = nil) -> Event? {
        guard let context = modelContext else { return nil }
        
        let event = Event(type: type, date: date, duration: duration, notes: notes)
        event.caseItem = caseItem
        
        context.insert(event)
        
        do {
            try context.save()
            return event
        } catch {
            print("Ошибка сохранения события: \(error)")
            return nil
        }
    }
    
    func upcomingEvents(from events: [Event]) -> [Event] {
        events.filter { $0.date >= Date() }.sorted { $0.date < $1.date }
    }
    
    func eventsForDate(_ date: Date, from events: [Event]) -> [Event] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func totalHoursThisMonth(from events: [Event]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let monthEvents = events.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return monthEvents.reduce(0) { $0 + $1.duration }
    }
}

@Observable
class PaymentViewModel {
    private var modelContext: ModelContext?
    
    func setupContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func createPayment(amount: Double, date: Date, notes: String = "", caseItem: Case? = nil) -> Payment? {
        guard let context = modelContext else { return nil }
        
        let payment = Payment(amount: amount, date: date, notes: notes)
        payment.caseItem = caseItem
        
        context.insert(payment)
        
        do {
            try context.save()
            return payment
        } catch {
            print("Ошибка сохранения платежа: \(error)")
            return nil
        }
    }
    
    func totalPaymentsThisMonth(from payments: [Payment]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let monthPayments = payments.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        return monthPayments.reduce(0) { $0 + $1.amount }
    }
    
    func paymentsForCase(_ caseItem: Case, from payments: [Payment]) -> [Payment] {
        payments.filter { $0.caseItem?.id == caseItem.id }
    }
}

@Observable
class DocumentViewModel {
    private var modelContext: ModelContext?
    
    func setupContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func createDocument(type: DocumentType, filePath: String, isFavorite: Bool = false) -> Document? {
        guard let context = modelContext else { return nil }
        
        let document = Document(type: type, filePath: filePath, isFavorite: isFavorite)
        context.insert(document)
        
        do {
            try context.save()
            return document
        } catch {
            print("Ошибка сохранения документа: \(error)")
            return nil
        }
    }
    
    func deleteDocument(_ document: Document) {
        guard let context = modelContext else { return }
        
        // Удаляем файл с диска
        if FileManager.default.fileExists(atPath: document.filePath) {
            try? FileManager.default.removeItem(atPath: document.filePath)
        }
        
        context.delete(document)
        try? context.save()
    }
    
    func toggleFavorite(_ document: Document) {
        document.isFavorite.toggle()
        try? modelContext?.save()
    }
    
    func documentsByType(_ type: DocumentType, from documents: [Document]) -> [Document] {
        documents.filter { $0.type == type }
    }
    
    func favoriteDocuments(from documents: [Document]) -> [Document] {
        documents.filter { $0.isFavorite }
    }
    
    func searchDocuments(query: String, from documents: [Document]) -> [Document] {
        guard !query.isEmpty else { return documents }
        return documents.filter {
            $0.filePath.localizedCaseInsensitiveContains(query) ||
            $0.type.displayName.localizedCaseInsensitiveContains(query)
        }
    }
}

@Observable
class SubscriptionViewModel {
    private var modelContext: ModelContext?
    
    var isPro: Bool = false
    var trialDaysLeft: Int = 14
    var subscriptionEndDate: Date?
    
    func setupContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func checkTrialStatus() {
        // Проверяем, есть ли сохранённая дата окончания триала
        if let endDate = UserDefaults.standard.object(forKey: "trialEndDate") as? Date {
            subscriptionEndDate = endDate
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
            trialDaysLeft = max(0, daysLeft)
            isPro = trialDaysLeft > 0
        } else {
            // Первый запуск — начинаем триал
            let endDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
            UserDefaults.standard.set(endDate, forKey: "trialEndDate")
            subscriptionEndDate = endDate
            trialDaysLeft = 14
            isPro = true
        }
    }
    
    func activateSubscription() {
        // Здесь будет интеграция с StoreKit
        isPro = true
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        subscriptionEndDate = endDate
        UserDefaults.standard.set(endDate, forKey: "subscriptionEndDate")
    }
    
    func cancelSubscription() {
        isPro = false
        UserDefaults.standard.removeObject(forKey: "subscriptionEndDate")
    }
}

@Observable
class SettingsViewModel {
    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }
    
    var darkModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "darkModeEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "darkModeEnabled") }
    }
    
    var defaultPaymentMethod: PaymentMethod {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: "defaultPaymentMethod"),
               let method = PaymentMethod(rawValue: rawValue) {
                return method
            }
            return .hourly
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "defaultPaymentMethod") }
    }
    
    var lawyerName: String {
        get { UserDefaults.standard.string(forKey: "lawyerName") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lawyerName") }
    }
    
    var lawyerPhone: String {
        get { UserDefaults.standard.string(forKey: "lawyerPhone") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lawyerPhone") }
    }
    
    var lawyerEmail: String {
        get { UserDefaults.standard.string(forKey: "lawyerEmail") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "lawyerEmail") }
    }
    
    func resetAllSettings() {
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "darkModeEnabled")
        UserDefaults.standard.removeObject(forKey: "defaultPaymentMethod")
        UserDefaults.standard.removeObject(forKey: "lawyerName")
        UserDefaults.standard.removeObject(forKey: "lawyerPhone")
        UserDefaults.standard.removeObject(forKey: "lawyerEmail")
    }
}
