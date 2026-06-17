import SwiftUI
import SwiftData

// MARK: - Главный файл приложения

struct AdvocateApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Client.self,
            Case.self,
            Event.self,
            Payment.self,
            Document.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Константы приложения

struct AppConstants {
    static let appName = "Advocate"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    static let developer = "EHC Studio"
    static let supportEmail = "support@ehc.studio"
    static let supportTelegram = "https://t.me/ehc_support"
    static let privacyPolicyURL = "https://ehc.studio/privacy"
    static let termsOfServiceURL = "https://ehc.studio/terms"

    static let trialDays = 14
    static let subscriptionPriceMonthly = 499.0 // рублей
    static let subscriptionPriceYearly = 4990.0 // рублей (экономия 17%)

    static let maxFreeDocuments = 10
    static let maxFreeTemplates = 3
    static let maxFreeClients = 5

    static let fileSizeLimitMB = 50
    static let scanQuality: CGFloat = 1.0 // 0.0 - 1.0
}

// MARK: - Темы приложения

struct AppTheme {
    static let primaryColor = Color.indigo
    static let secondaryColor = Color.blue
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red

    static let backgroundColor = Color(.systemBackground)
    static let secondaryBackgroundColor = Color(.secondarySystemBackground)
    static let groupedBackgroundColor = Color(.systemGroupedBackground)

    static let textColor = Color(.label)
    static let secondaryTextColor = Color(.secondaryLabel)
    static let placeholderTextColor = Color(.placeholderText)

    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8

    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.05
}

// MARK: - Анимации

struct AppAnimations {
    static let defaultDuration: Double = 0.3
    static let springResponse: Double = 0.5
    static let springDamping: Double = 0.7

    static var defaultAnimation: Animation {
        .spring(response: springResponse, dampingFraction: springDamping)
    }

    static var easeInOutAnimation: Animation {
        .easeInOut(duration: defaultDuration)
    }
}

// MARK: - Локализация (русский)

struct LocalizedStrings {
    static let clients = "Клиенты"
    static let cases = "Дела"
    static let documents = "Документы"
    static let time = "Время"
    static let settings = "Настройки"
    static let statistics = "Статистика"
    static let help = "Помощь"

    static let add = "Добавить"
    static let edit = "Изменить"
    static let delete = "Удалить"
    static let save = "Сохранить"
    static let cancel = "Отмена"
    static let done = "Готово"
    static let search = "Поиск"

    static let active = "Активное"
    static let closed = "Закрыто"
    static let paused = "Приостановлено"
    static let archived = "В архиве"

    static let meeting = "Встреча"
    static let court = "Суд"
    static let consultation = "Консультация"
    static let deadline = "Дедлайн"

    static let hourly = "Почасовая"
    static let fixed = "Фикс"
    static let subscription = "Подписка"
    static let success = "Успех"

    static let proVersion = "PRO-версия"
    static let trialDaysLeft = "Осталось %d дней пробного периода"
    static let subscribeNow = "Оформить подписку"
    static let restorePurchases = "Восстановить покупки"
}

// MARK: - Тестовые данные (для превью и тестирования)

struct PreviewData {
    static let sampleClient = Client(
        lastName: "Иванов",
        firstName: "Иван",
        middleName: "Иванович",
        phone: "+7 (999) 123-45-67",
        email: "ivanov@example.com"
    )

    static let sampleCase = Case(
        number: "А40-123456/2026",
        title: "Взыскание задолженности по договору",
        description: "Иск о взыскании задолженности по договору подряда на сумму 1 500 000 рублей",
        status: .active,
        paymentMethod: .hourly
    )

    static let sampleEvent = Event(
        type: .court,
        title: "Судебное заседание",
        date: Date().addingTimeInterval(86400 * 3), // через 3 дня
        durationHours: 2,
        notes: "Предварительное слушание, зал 305"
    )

    static let samplePayment = Payment(
        amount: 50000,
        date: Date(),
        notes: "Аванс по договору"
    )

    static let sampleDocument = Document(
        title: "Договор подряда",
        fileName: "contract_001.pdf",
        filePath: "/documents/contract_001.pdf",
        documentType: .contract
    )
}