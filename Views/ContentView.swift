import SwiftUI
import SwiftData
import PDFKit
import PhotosUI

// MARK: - Главный экран с табами

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
            
            ClientsView()
                .tabItem {
                    Label("Клиенты", systemImage: "person.2.fill")
                }
            
            CasesView()
                .tabItem {
                    Label("Дела", systemImage: "briefcase.fill")
                }
            
            DocumentsView()
                .tabItem {
                    Label("Документы", systemImage: "doc.text.fill")
                }
            
            TimeView()
                .tabItem {
                    Label("Время", systemImage: "clock.fill")
                }
        }
        .accentColor(.indigo)
    }
}

// MARK: - Главный экран (Dashboard)

struct HomeView: View {
    @Query(sort: \Case.createdAt, order: .reverse) private var cases: [Case]
    @Query(sort: \Event.date, order: .reverse) private var events: [Event]
    @Query(sort: \Payment.date, order: .reverse) private var payments: [Payment]
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Статистика
                    StatsSection(cases: cases, events: events, payments: payments)
                    
                    // Ближайшие события
                    UpcomingEventsSection(events: events.filter { !$0.isCompleted }.prefix(5))
                    
                    // Последние дела
                    RecentCasesSection(cases: cases.prefix(5))
                }
                .padding()
            }
            .navigationTitle("Advocate")
            .searchable(text: $searchText, prompt: "Поиск по делам, клиентам, документам")
        }
    }
}

// MARK: - Секция статистики

struct StatsSection: View {
    let cases: [Case]
    let events: [Event]
    let payments: [Payment]
    
    var activeCases: Int {
        cases.filter { $0.status == .active }.count
    }
    
    var totalEarnings: Double {
        payments.reduce(0) { $0 + $1.amount }
    }
    
    var hoursThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        return events
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .compactMap { $0.durationHours }
            .reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Активные дела",
                    value: "\(activeCases)",
                    icon: "briefcase.fill",
                    color: .indigo
                )
                
                StatCard(
                    title: "Заработано",
                    value: String(format: "%.0f ₽", totalEarnings),
                    icon: "rublesign.circle.fill",
                    color: .green
                )
            }
            
            StatCard(
                title: "Часов в этом месяце",
                value: String(format: "%.1f ч", hoursThisMonth),
                icon: "clock.fill",
                color: .orange,
                isWide: true
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isWide: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: isWide ? .infinity : nil, minHeight: 100)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Ближайшие события

struct UpcomingEventsSection: View {
    let events: ArraySlice<Event>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ближайшие события")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("Все") {
                    CalendarView()
                }
                .font(.caption)
            }
            
            if events.isEmpty {
                Text("Нет предстоящих событий")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(events) { event in
                    EventRow(event: event)
                }
            }
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.type.icon)
                .font(.title3)
                .foregroundColor(.indigo)
                .frame(width: 40, height: 40)
                .background(Color.indigo.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let duration = event.durationHours {
                Text(String(format: "%.1f ч", duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Последние дела

struct RecentCasesSection: View {
    let cases: ArraySlice<Case>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Последние дела")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("Все") {
                    CasesView()
                }
                .font(.caption)
            }
            
            ForEach(cases) { caseItem in
                CaseRow(caseItem: caseItem)
            }
        }
    }
}

struct CaseRow: View {
    let caseItem: Case
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caseItem.number)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(caseItem.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let client = caseItem.client {
                    Text(client.fullName)
                        .font(.caption2)
                        .foregroundColor(.indigo)
                }
            }
            
            Spacer()
            
            StatusBadge(status: caseItem.status)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: CaseStatus
    
    var color: Color {
        switch status {
        case .active: return .green
        case .archived: return .orange
        case .closed: return .gray
        }
    }
    
    var text: String {
        switch status {
        case .active: return "Активно"
        case .archived: return "Архив"
        case .closed: return "Закрыто"
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// MARK: - Документы (ключевая фича)

struct DocumentsView: View {
    @Query(sort: \Document.createdAt, order: .reverse) private var documents: [Document]
    @State private var searchText = ""
    @State private var showingScanner = false
    @State private var showingImagePicker = false
    @State private var selectedFilter: DocumentType?
    
    var filteredDocuments: [Document] {
        var result = documents
        
        if let filter = selectedFilter {
            result = result.filter { $0.documentType == filter }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.fileName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Фильтры по типу
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "Все",
                            isSelected: selectedFilter == nil,
                            action: { selectedFilter = nil }
                        )
                        
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            FilterChip(
                                title: type.displayName,
                                isSelected: selectedFilter == type,
                                action: { selectedFilter = type }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Список документов
                List {
                    ForEach(filteredDocuments) { document in
                        DocumentRow(document: document)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Документы")
            .searchable(text: $searchText, prompt: "Поиск по названию")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "doc.viewfinder.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScannerView()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker { images in
                    // Создание документа из выбранных фото
                    createDocumentFromImages(images)
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.indigo : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct DocumentRow: View {
    let document: Document
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: document.documentType.icon)
                .font(.title3)
                .foregroundColor(.indigo)
                .frame(width: 44, height: 44)
                .background(Color.indigo.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(document.documentType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(document.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if document.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Сканер документов (VisionKit)

struct DocumentScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedImages: [UIImage] = []
    @State private var documentTitle = ""
    @State private var selectedType: DocumentType = .other
    @State private var selectedCase: Case? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                if scannedImages.isEmpty {
                    DocumentCameraView { images in
                        scannedImages = images
                    }
                } else {
                    // Предпросмотр отсканированных страниц
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(0..<scannedImages.count, id: \.self) { index in
                                Image(uiImage: scannedImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                    
                    Form {
                        TextField("Название документа", text: $documentTitle)
                        
                        Picker("Тип документа", selection: $selectedType) {
                            ForEach(DocumentType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        
                        // Выбор дела (опционально)
                        Picker("Дело (опционально)", selection: $selectedCase) {
                            Text("Без дела").tag(nil as Case?)
                            ForEach(cases) { caseItem in
                                Text("\(caseItem.number) — \(caseItem.title)").tag(caseItem as Case?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Сканирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                if !scannedImages.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Сохранить") {
                            saveDocument()
                        }
                        .disabled(documentTitle.isEmpty)
                    }
                }
            }
        }
    }
    
    func saveDocument() {
        // Создание PDF из отсканированных изображений
        let pdfDocument = PDFDocument()
        
        for (index, image) in scannedImages.enumerated() {
            guard let cgImage = image.cgImage else { continue }
            let pdfPage = PDFPage(image: UIImage(cgImage: cgImage))
            pdfDocument.insert(pdfPage!, at: index)
        }
        
        // Сохранение PDF в FileManager
        let fileName = "\(documentTitle)_\(Date().timeIntervalSince1970).pdf"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if pdfDocument.write(to: fileURL) {
            // Сохранение в SwiftData
            let document = Document(
                title: documentTitle,
                fileName: fileName,
                filePath: fileURL.path,
                documentType: selectedType,
                isFavorite: false
            )
            modelContext.insert(document)
            
            // Связь с делом, если выбрано
            if let caseItem = selectedCase {
                caseItem.documents.append(document)
            }
        }
        
        dismiss()
    }
}

// MARK: - Image Picker (галерея)

struct ImagePicker: UIViewControllerRepresentable {
    let onSelect: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 10
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onSelect: ([UIImage]) -> Void
        
        init(onSelect: @escaping ([UIImage]) -> Void) {
            self.onSelect = onSelect
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        images.append(image)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.onSelect(images)
            }
        }
    }
}

// MARK: - VisionKit Camera Wrapper

struct DocumentCameraView: UIViewControllerRepresentable {
    let onScan: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([UIImage]) -> Void
        
        init(onScan: @escaping ([UIImage]) -> Void) {
            self.onScan = onScan
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: pageIndex))
            }
            onScan(images)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Scanner error: \(error)")
        }
    }
}

// MARK: - Заглушки для других экранов

struct ClientsView: View {
    var body: some View {
        NavigationStack {
            Text("Клиенты")
                .navigationTitle("Клиенты")
        }
    }
}

struct CasesView: View {
    var body: some View {
        NavigationStack {
            Text("Дела")
                .navigationTitle("Дела")
        }
    }
}

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            Text("Календарь")
                .navigationTitle("Календарь")
        }
    }
}

struct TimeView: View {
    var body: some View {
        NavigationStack {
            Text("Учёт времени")
                .navigationTitle("Учёт времени")
        }
    }
}
