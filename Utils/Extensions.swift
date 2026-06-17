import Foundation

// MARK: - Расширения для Date

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
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}

// MARK: - Расширения для String

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
    
    func extractNumbers() -> String {
        self.filter { $0.isNumber }
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
    
    static func getFileSize(at path: String) -> Int64? {
        let url = documentsDirectory().appendingPathComponent(path)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
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

// MARK: - Утилиты для форматирования

struct FormatUtils {
    static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₽"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value) ₽"
    }
    
    static func formatPhone(_ phone: String) -> String {
        let numbers = phone.extractNumbers()
        guard numbers.count == 11 else { return phone }
        
        let index1 = numbers.index(numbers.startIndex, offsetBy: 1)
        let index2 = numbers.index(numbers.startIndex, offsetBy: 4)
        let index3 = numbers.index(numbers.startIndex, offsetBy: 7)
        let index4 = numbers.index(numbers.startIndex, offsetBy: 9)
        
        return "+7 (\(numbers[index1..<index2])) \(numbers[index2..<index3])-\(numbers[index3..<index4])-\(numbers[index4...])"
    }
    
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}