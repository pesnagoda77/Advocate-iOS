import XCTest
@testable import Advocate

// MARK: - Тесты моделей

final class ModelTests: XCTestCase {
    
    func testClientCreation() {
        let client = Client(
            lastName: "Иванов",
            firstName: "Иван",
            middleName: "Иванович",
            phone: "+79991234567",
            email: "ivanov@example.com",
            notes: "Тестовый клиент"
        )
        
        XCTAssertEqual(client.fullName, "Иванов Иван Иванович")
        XCTAssertEqual(client.phone, "+79991234567")
        XCTAssertTrue(client.email.isValidEmail)
        XCTAssertNotNil(client.id)
        XCTAssertNotNil(client.createdAt)
    }
    
    func testClientFullNameFormatting() {
        let client1 = Client(lastName: "Петров", firstName: "Петр")
        XCTAssertEqual(client1.fullName, "Петров Петр")
        
        let client2 = Client(lastName: "Сидоров", firstName: "Сидор", middleName: "Сидорович")
        XCTAssertEqual(client2.fullName, "Сидоров Сидор Сидорович")
        
        let client3 = Client(lastName: "Иванова", firstName: "Мария", middleName: "")
        XCTAssertEqual(client3.fullName, "Иванова Мария")
    }
    
    func testCaseCreation() {
        let client = Client(lastName: "Тестов", firstName: "Тест")
        let caseItem = Case(
            number: "А40-123456/2026",
            title: "Тестовое дело",
            description: "Описание дела",
            notes: "Заметки",
            status: .active,
            paymentMethod: .hourly,
            hourlyRate: 5000,
            client: client
        )
        
        XCTAssertEqual(caseItem.number, "А40-123456/2026")
        XCTAssertEqual(caseItem.status, .active)
        XCTAssertEqual(caseItem.hourlyRate, 5000)
        XCTAssertEqual(caseItem.client?.fullName, "Тестов Тест")
        XCTAssertNotNil(caseItem.createdAt)
    }
    
    func testEventCreation() {
        let event = Event(
            type: .court,
            title: "Судебное заседание",
            date: Date(),
            durationHours: 2.5,
            notes: "Важное заседание"
        )
        
        XCTAssertEqual(event.type, .court)
        XCTAssertEqual(event.durationHours, 2.5)
        XCTAssertFalse(event.isCompleted)
    }
    
    func testPaymentCreation() {
        let payment = Payment(
            amount: 50000,
            date: Date(),
            notes: "Аванс"
        )
        
        XCTAssertEqual(payment.amount, 50000)
        XCTAssertEqual(payment.notes, "Аванс")
    }
    
    func testDocumentCreation() {
        let document = Document(
            title: "Договор",
            fileName: "contract.pdf",
            filePath: "/docs/contract.pdf",
            documentType: .contract
        )
        
        XCTAssertEqual(document.documentType, .contract)
        XCTAssertFalse(document.isFavorite)
    }
}

// MARK: - Тесты ViewModels

final class ClientViewModelTests: XCTestCase {
    
    var viewModel: ClientViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ClientViewModel()
    }
    
    func testSearchClients() {
        let clients = [
            Client(lastName: "Иванов", firstName: "Иван", phone: "+79991111111"),
            Client(lastName: "Петров", firstName: "Петр", phone: "+79992222222"),
            Client(lastName: "Сидоров", firstName: "Сидор", email: "sidor@example.com")
        ]
        
        let results = viewModel.searchClients(query: "Иван", in: clients)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.fullName, "Иванов Иван")
        
        let phoneResults = viewModel.searchClients(query: "2222", in: clients)
        XCTAssertEqual(phoneResults.count, 1)
        XCTAssertEqual(phoneResults.first?.fullName, "Петров Петр")
        
        let emailResults = viewModel.searchClients(query: "sidor", in: clients)
        XCTAssertEqual(emailResults.count, 1)
        XCTAssertEqual(emailResults.first?.fullName, "Сидоров Сидор")
    }
    
    func testSearchClientsEmptyQuery() {
        let clients = [
            Client(lastName: "Иванов", firstName: "Иван"),
            Client(lastName: "Петров", firstName: "Петр")
        ]
        
        let results = viewModel.searchClients(query: "", in: clients)
        XCTAssertEqual(results.count, 2)
    }
}

final class CaseViewModelTests: XCTestCase {
    
    var viewModel: CaseViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = CaseViewModel()
    }
    
    func testActiveCasesCount() {
        let cases = [
            Case(number: "1", title: "Дело 1", status: .active),
            Case(number: "2", title: "Дело 2", status: .active),
            Case(number: "3", title: "Дело 3", status: .closed),
            Case(number: "4", title: "Дело 4", status: .archived)
        ]
        
        XCTAssertEqual(viewModel.activeCasesCount(from: cases), 2)
    }
    
    func testCasesByStatus() {
        let cases = [
            Case(number: "1", title: "Дело 1", status: .active),
            Case(number: "2", title: "Дело 2", status: .closed),
            Case(number: "3", title: "Дело 3", status: .active)
        ]
        
        let activeCases = viewModel.casesByStatus(.active, from: cases)
        XCTAssertEqual(activeCases.count, 2)
        
        let closedCases = viewModel.casesByStatus(.closed, from: cases)
        XCTAssertEqual(closedCases.count, 1)
    }
    
    func testTotalEarnings() {
        let case1 = Case(number: "1", title: "Дело 1")
        let payment1 = Payment(amount: 50000, date: Date())
        let payment2 = Payment(amount: 30000, date: Date())
        case1.payments = [payment1, payment2]
        
        let case2 = Case(number: "2", title: "Дело 2")
        let payment3 = Payment(amount: 100000, date: Date())
        case2.payments = [payment3]
        
        let total = viewModel.totalEarnings(from: [case1, case2])
        XCTAssertEqual(total, 180000)
    }
}

final class EventViewModelTests: XCTestCase {
    
    var viewModel: EventViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = EventViewModel()
    }
    
    func testUpcomingEvents() {
        let pastEvent = Event(type: .meeting, title: "Прошлое", date: Date().addingTimeInterval(-86400))
        let futureEvent1 = Event(type: .court, title: "Будущее 1", date: Date().addingTimeInterval(86400))
        let futureEvent2 = Event(type: .consultation, title: "Будущее 2", date: Date().addingTimeInterval(172800))
        
        let events = [pastEvent, futureEvent1, futureEvent2]
        let upcoming = viewModel.upcomingEvents(from: events)
        
        XCTAssertEqual(upcoming.count, 2)
        XCTAssertEqual(upcoming.first?.title, "Будущее 1")
    }
    
    func testTotalHoursThisMonth() {
        let calendar = Calendar.current
        let now = Date()
        
        let event1 = Event(type: .meeting, title: "Встреча", date: now, durationHours: 2)
        let event2 = Event(type: .court, title: "Суд", date: now, durationHours: 3.5)
        let lastMonthEvent = Event(type: .call, title: "Звонок", date: calendar.date(byAdding: .month, value: -1, to: now)!, durationHours: 1)
        
        let events = [event1, event2, lastMonthEvent]
        let totalHours = viewModel.totalHoursThisMonth(from: events)
        
        XCTAssertEqual(totalHours, 5.5)
    }
}

final class PaymentViewModelTests: XCTestCase {
    
    var viewModel: PaymentViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = PaymentViewModel()
    }
    
    func testTotalPaymentsThisMonth() {
        let calendar = Calendar.current
        let now = Date()
        
        let payment1 = Payment(amount: 50000, date: now)
        let payment2 = Payment(amount: 30000, date: now)
        let lastMonthPayment = Payment(amount: 100000, date: calendar.date(byAdding: .month, value: -1, to: now)!)
        
        let payments = [payment1, payment2, lastMonthPayment]
        let total = viewModel.totalPaymentsThisMonth(from: payments)
        
        XCTAssertEqual(total, 80000)
    }
}

// MARK: - Тесты утилит

final class ExtensionsTests: XCTestCase {
    
    func testEmailValidation() {
        XCTAssertTrue("test@example.com".isValidEmail)
        XCTAssertTrue("user.name+tag@example.co.uk".isValidEmail)
        XCTAssertFalse("invalid".isValidEmail)
        XCTAssertFalse("@example.com".isValidEmail)
        XCTAssertFalse("test@".isValidEmail)
    }
    
    func testPhoneValidation() {
        XCTAssertTrue("+79991234567".isValidPhone)
        XCTAssertTrue("8 (999) 123-45-67".isValidPhone)
        XCTAssertFalse("123".isValidPhone)
        XCTAssertFalse("abc".isValidPhone)
    }
    
    func testStringTruncation() {
        let longString = "Очень длинная строка текста"
        XCTAssertEqual(longString.truncated(to: 10), "Очень длин...")
        XCTAssertEqual(longString.truncated(to: 100), longString)
    }
    
    func testDateFormatting() {
        let date = Date(timeIntervalSince1970: 0)
        let formatted = date.formatted("dd.MM.yyyy")
        XCTAssertEqual(formatted, "01.01.1970")
    }
}

final class FormatUtilsTests: XCTestCase {
    
    func testCurrencyFormatting() {
        let formatted = FormatUtils.formatCurrency(150000)
        XCTAssertTrue(formatted.contains("150000"))
        XCTAssertTrue(formatted.contains("₽"))
    }
    
    func testPhoneFormatting() {
        let formatted = FormatUtils.formatPhone("+79991234567")
        XCTAssertEqual(formatted, "+7 (999) 123-45-67")
    }
    
    func testFileSizeFormatting() {
        let kb = FormatUtils.formatFileSize(1024)
        XCTAssertTrue(kb.contains("KB"))
        
        let mb = FormatUtils.formatFileSize(1024 * 1024)
        XCTAssertTrue(mb.contains("MB"))
    }
}

// MARK: - Тесты бизнес-логики

final class BusinessLogicTests: XCTestCase {
    
    func testCaseTotalPayments() {
        let caseItem = Case(number: "1", title: "Тест")
        let payment1 = Payment(amount: 10000, date: Date())
        let payment2 = Payment(amount: 20000, date: Date())
        let payment3 = Payment(amount: 15000, date: Date())
        
        caseItem.payments = [payment1, payment2, payment3]
        
        let total = caseItem.payments?.reduce(0) { $0 + $1.amount } ?? 0
        XCTAssertEqual(total, 45000)
    }
    
    func testHourlyRateCalculation() {
        let caseItem = Case(number: "1", title: "Тест", paymentMethod: .hourly, hourlyRate: 5000)
        let event = Event(type: .meeting, title: "Встреча", date: Date(), durationHours: 3, case: caseItem)
        
        let earnings = (event.durationHours ?? 0) * (event.case?.hourlyRate ?? 0)
        XCTAssertEqual(earnings, 15000)
    }
    
    func testDocumentTypeIcon() {
        XCTAssertEqual(DocumentType.contract.icon, "doc.text.fill")
        XCTAssertEqual(DocumentType.courtOrder.icon, "building.columns.fill")
        XCTAssertEqual(DocumentType.powerOfAttorney.icon, "signature")
    }
    
    func testEventTypeDisplayName() {
        XCTAssertEqual(EventType.meeting.displayName, "Встреча")
        XCTAssertEqual(EventType.court.displayName, "Суд")
        XCTAssertEqual(EventType.consultation.displayName, "Консультация")
    }
}

// MARK: - Тесты производительности

final class PerformanceTests: XCTestCase {
    
    func testClientSearchPerformance() {
        let viewModel = ClientViewModel()
        var clients: [Client] = []
        
        for i in 0..<1000 {
            clients.append(Client(
                lastName: "Фамилия\(i)",
                firstName: "Имя\(i)",
                phone: "+7999\(i)"
            ))
        }
        
        measure {
            _ = viewModel.searchClients(query: "Фамилия500", in: clients)
        }
    }
    
    func testCaseFilteringPerformance() {
        let viewModel = CaseViewModel()
        var cases: [Case] = []
        
        for i in 0..<1000 {
            cases.append(Case(
                number: "А40-\(i)/2026",
                title: "Дело \(i)",
                status: i % 3 == 0 ? .active : (i % 3 == 1 ? .closed : .archived)
            ))
        }
        
        measure {
            _ = viewModel.activeCasesCount(from: cases)
        }
    }
}