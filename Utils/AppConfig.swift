import SwiftUI

// MARK: - Главный файл приложения (точка входа)
// Этот файл будет AdvocateApp.swift в Xcode проекте
// Здесь определена структура, но без @main (нужен Мак для компиляции)

struct AdvocateApp: App {
    // SwiftData container — будет настроен в Xcode
    // var sharedModelContainer: ModelContainer = {
    //     let schema = Schema([
    //         Client.self,
    //         Case.self,
    //         Event.self,
    //         Payment.self,
    //         Document.self,
    //     ])
    //     let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    //     do {
    //         return try ModelContainer(for: schema, configurations: [modelConfiguration])
    //     } catch {
    //         fatalError("Could not create ModelContainer: \(error)")
    //     }
    // }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // .modelContainer(sharedModelContainer)
        }
    }
}

// MARK: - Preview Provider для всех экранов
// Это позволит видеть превью в Xcode Canvas (нужен Мак)

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("Главный экран")
    }
}

struct ClientsView_Previews: PreviewProvider {
    static var previews: some View {
        ClientsView()
            .previewDisplayName("Клиенты")
    }
}

struct CasesView_Previews: PreviewProvider {
    static var previews: some View {
        CasesView()
            .previewDisplayName("Дела")
    }
}

struct DocumentTemplatesView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentTemplatesView()
            .previewDisplayName("Шаблоны")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .previewDisplayName("Настройки")
    }
}

// MARK: - Launch Screen (storyboard будет создан в Xcode)
// Здесь описание того, что нужно сделать в Xcode

/*
 Launch Screen (LaunchScreen.storyboard):
 - Центр: логотип EHC (квадрат 7x7 с градацией + звёзды + EHC)
 - Низ: "Advocate" + "© 2026 EHC Studio"
 - Фон: системный фон (адаптируется к тёмной теме)
 - Constraints: центрирование, отступы
 
 Assets:
 - AppIcon: 1024x1024, с градацией серого + золотым акцентом
 - Logo: для Launch Screen и About
 */

// MARK: - Info.plist (будет создан в Xcode)
/*
 Ключи для Info.plist:
 - CFBundleDisplayName: "Advocate"
 - CFBundleShortVersionString: "1.0.0"
 - CFBundleVersion: "1"
 - LSRequiresIPhoneOS: YES
 - UIRequiredDeviceCapabilities: [armv7]
 - UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait]
 - NSCameraUsageDescription: "Приложению нужен доступ к камере для сканирования документов"
 - NSPhotoLibraryUsageDescription: "Приложению нужен доступ к фото для импорта документов"
 - UNNotificationUsageDescription: "Приложение отправляет напоминания о встречах и судах"
 */

// MARK: - Entitlements (будет создан в Xcode)
/*
 com.apple.developer.associated-domains: [applinks:ehc.studio]
 com.apple.security.application-groups: [group.com.ehc.advocate]
 */

// MARK: - App Store метаданные (уже есть в AppStore/Metadata.md)
// Дополнительные материалы для App Store:

/*
 Скриншоты (6 штук для iPhone):
 1. Главный экран (Dashboard) — статистика, ближайшие события
 2. Список клиентов — поиск, фильтры
 3. Детали дела — статус, события, платежи
 4. Сканер документов — камера, обрезка
 5. Шаблоны документов — список, генерация
 6. Настройки — профиль, подписка
 
 Превью видео (опционально):
 - 15-30 секунд, демонстрация основных функций
 
 Ключевые слова (100 символов):
 advocate, lawyer, attorney, legal, documents, scanner, templates, court, case, client
 
 Категория: Business / Productivity
 */

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
        date: Date().addingTimeInterval(86400 * 3), // через 3 дня
        duration: 120,
        notes: "Предварительное слушание, зал 305"
    )
    
    static let samplePayment = Payment(
        amount: 50000,
        date: Date(),
        notes: "Аванс по договору"
    )
    
    static let sampleDocument = Document(
        type: .contract,
        filePath: "/documents/contract_001.pdf",
        isFavorite: true
    )
}

// MARK: - Расширения для удобства

extension Date {
    func formatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }
    
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension String {
    var isValidEmail: Bool {
        let regex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i
        return self.wholeMatch(of: regex) != nil
    }
    
    var isValidPhone: Bool {
        let regex = /^\+?[0-9\s\-\(\)]{10,20}$/
        return self.wholeMatch(of: regex) != nil
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Утилиты для работы с файлами

struct FileUtils {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func createDirectoryIfNeeded(_ path: String) {
        let url = documentsDirectory().appendingPathComponent(path)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    static func saveFile(_ data: Data, to path: String) -> Bool {
        let url = documentsDirectory().appendingPathComponent(path)
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Ошибка сохранения файла: \(error)")
            return false
        }
    }
    
    static func deleteFile(at path: String) -> Bool {
        let url = documentsDirectory().appendingPathComponent(path)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
                return true
            } catch {
                print("Ошибка удаления файла: \(error)")
                return false
            }
        }
        return false
    }
    
    static func fileExists(at path: String) -> Bool {
        let url = documentsDirectory().appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: url.path)
    }
}

// MARK: - Утилиты для работы с PDF

struct PDFUtils {
    static func createPDF(from text: String, title: String) -> Data? {
        // Заглушка — в реальном приложении здесь будет создание PDF
        // через PDFKit или UIGraphicsPDFRenderer
        return nil
    }
    
    static func mergePDFs(_ urls: [URL]) -> Data? {
        // Заглушка — слияние PDF файлов
        return nil
    }
    
    static func extractText(from pdfURL: URL) -> String? {
        // Заглушка — извлечение текста из PDF
        return nil
    }
}

// MARK: - Утилиты для работы с сетью

struct NetworkUtils {
    static func isConnectedToInternet() -> Bool {
        // Заглушка — проверка подключения к интернету
        // В реальном приложении: Reachability или NWPathMonitor
        return true
    }
    
    static func syncDataToCloud() async throws {
        // Заглушка — синхронизация с iCloud
        // В реальном приложении: CKContainer, CKDatabase
    }
    
    static func backupToCloud() async throws {
        // Заглушка — резервное копирование
        // В реальном приложении: экспорт в JSON, загрузка в iCloud
    }
}

// MARK: - Утилиты для безопасности

struct SecurityUtils {
    static func hashPassword(_ password: String) -> String {
        // Заглушка — хеширование пароля
        // В реальном приложении: Keychain, CryptoKit
        return password
    }
    
    static func saveToKeychain(key: String, value: String) -> Bool {
        // Заглушка — сохранение в Keychain
        // В реальном приложении: SecItemAdd
        return true
    }
    
    static func readFromKeychain(key: String) -> String? {
        // Заглушка — чтение из Keychain
        // В реальном приложении: SecItemCopyMatching
        return nil
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
