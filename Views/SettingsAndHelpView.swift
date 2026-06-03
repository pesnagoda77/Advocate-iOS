import SwiftUI
import SwiftData

// MARK: - Экран настроек

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль") {
                    TextField("ФИО", text: $viewModel.lawyerName)
                    TextField("Телефон", text: $viewModel.lawyerPhone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $viewModel.lawyerEmail)
                        .keyboardType(.emailAddress)
                }
                
                Section("Оформление") {
                    Toggle("Тёмная тема", isOn: $viewModel.darkModeEnabled)
                }
                
                Section("Уведомления") {
                    Toggle("Включить уведомления", isOn: $viewModel.notificationsEnabled)
                    
                    if viewModel.notificationsEnabled {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            Text("Настройка уведомлений")
                        }
                    }
                }
                
                Section("Оплата по умолчанию") {
                    Picker("Метод", selection: $viewModel.defaultPaymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Text(method.displayName)
                                .tag(method)
                        }
                    }
                }
                
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Сборка")
                        Spacer()
                        Text("2026.06.03")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("Политика конфиденциальности", destination: URL(string: "https://ehc.studio/privacy")!)
                    Link("Условия использования", destination: URL(string: "https://ehc.studio/terms")!)
                }
                
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Сбросить все настройки", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Настройки")
            .confirmationDialog("Сбросить настройки?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Сбросить", role: .destructive) {
                    viewModel.resetAllSettings()
                }
                Button("Отмена", role: .cancel) { }
            } message: {
                Text("Все настройки будут сброшены к значениям по умолчанию. Данные клиентов и дел не затронуты.")
            }
        }
    }
}

// MARK: - Настройка уведомлений

struct NotificationSettingsView: View {
    @State private var eventReminders = true
    @State private var paymentReminders = true
    @State private var courtReminders = true
    @State private var reminderTime = 30 // минут до события
    
    var body: some View {
        Form {
            Section("Типы уведомлений") {
                Toggle("Напоминания о встречах", isOn: $eventReminders)
                Toggle("Напоминания о платежах", isOn: $paymentReminders)
                Toggle("Напоминания о заседаниях", isOn: $courtReminders)
            }
            
            Section("Время напоминания") {
                Stepper("За \(reminderTime) минут до события", value: $reminderTime, in: 15...120, step: 15)
            }
            
            Section("Звук") {
                NavigationLink {
                    SoundPickerView()
                } label: {
                    Text("Звук уведомления")
                }
            }
        }
        .navigationTitle("Уведомления")
    }
}

// MARK: - Выбор звука

struct SoundPickerView: View {
    @State private var selectedSound = "default"
    
    let sounds = [
        ("default", "Стандартный"),
        ("chime", "Колокольчик"),
        ("bell", "Звонок"),
        ("click", "Щелчок"),
        ("none", "Без звука")
    ]
    
    var body: some View {
        List {
            ForEach(sounds, id: \.0) { sound in
                Button {
                    selectedSound = sound.0
                } label: {
                    HStack {
                        Text(sound.1)
                        Spacer()
                        if selectedSound == sound.0 {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.indigo)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Звук")
    }
}

// MARK: - Экран статистики

struct StatisticsView: View {
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    @Query(sort: \Payment.date, order: .reverse) private var payments: [Payment]
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Карточки статистики
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Активные дела",
                            value: "\(activeCasesCount)",
                            icon: "briefcase.fill",
                            color: .indigo
                        )
                        
                        StatCard(
                            title: "Всего клиентов",
                            value: "\(uniqueClientsCount)",
                            icon: "person.2.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Заработано (мес)",
                            value: "\(monthlyEarnings, specifier: "%.0f") ₽",
                            icon: "creditcard.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Часов (мес)",
                            value: "\(monthlyHours) ч",
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // График доходов
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Доходы по месяцам")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Здесь будет график (Swift Charts)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 200)
                            .overlay(
                                Text("График доходов")
                                    .foregroundStyle(.secondary)
                            )
                            .padding(.horizontal)
                    }
                    
                    // Последние платежи
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Последние платежи")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(payments.prefix(5)) { payment in
                            PaymentRow(payment: payment)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Статистика")
        }
    }
    
    var activeCasesCount: Int {
        cases.filter { $0.status == .active }.count
    }
    
    var uniqueClientsCount: Int {
        Set(cases.compactMap { $0.client?.id }).count
    }
    
    var monthlyEarnings: Double {
        let calendar = Calendar.current
        let now = Date()
        return payments
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthlyHours: Int {
        let calendar = Calendar.current
        let now = Date()
        return events
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.duration }
    }
}

// MARK: - Компоненты

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Экран помощи

struct HelpView: View {
    let topics = [
        ("Начало работы", "Как добавить первого клиента и создать дело", "person.badge.plus"),
        ("Документы", "Сканирование и генерация документов", "doc.text"),
        ("События", "Календарь и напоминания", "calendar"),
        ("Оплата", "Учёт времени и платежей", "creditcard"),
        ("Подписка", "PRO-версия и пробный период", "star.fill"),
        ("Экспорт данных", "Резервное копирование", "arrow.up.doc"),
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Частые вопросы") {
                    ForEach(topics, id: \.0) { topic in
                        NavigationLink {
                            HelpTopicView(title: topic.0, description: topic.1)
                        } label: {
                            HStack {
                                Image(systemName: topic.2)
                                    .foregroundStyle(.indigo)
                                    .frame(width: 24)
                                Text(topic.0)
                            }
                        }
                    }
                }
                
                Section("Поддержка") {
                    Link(destination: URL(string: "mailto:support@ehc.studio")!) {
                        Label("Написать в поддержку", systemImage: "envelope")
                    }
                    
                    Link(destination: URL(string: "https://t.me/ehc_support")!) {
                        Label("Telegram поддержка", systemImage: "message")
                    }
                }
                
                Section("О приложении") {
                    HStack {
                        Text("Advocate для iOS")
                        Spacer()
                        Text("Версия 1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Разработано EHC Studio")
                        .foregroundStyle(.secondary)
                    
                    Text("© 2026 ElHombreCalvo")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .navigationTitle("Помощь")
        }
    }
}

struct HelpTopicView: View {
    let title: String
    let description: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                // Здесь будет подробная инструкция
                Text("Подробная инструкция по работе с этим разделом приложения. Здесь будут скриншоты и пошаговые действия.")
                    .font(.body)
                    .padding(.top)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
