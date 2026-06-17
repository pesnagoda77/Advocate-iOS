import SwiftUI
import SwiftData

// MARK: - Экран документов

struct DocumentsView: View {
    @Query(sort: \Document.createdAt, order: .reverse) private var documents: [Document]
    @State private var searchText = ""
    @State private var selectedFilter: DocumentType?
    @State private var showingScanner = false
    @State private var showingImagePicker = false
    
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
                    Text("Сканер документов")
                        .font(.headline)
                        .padding()
                    
                    Text("В реальном приложении здесь будет камера VisionKit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Button("Симулировать сканирование") {
                        // Заглушка
                    }
                    .padding()
                } else {
                    // Предпросмотр отсканированных страниц
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(0..<scannedImages.count, id: \.self) { index in
                                Image(uiImage: scannedImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    
                    Form {
                        Section("Информация") {
                            TextField("Название документа", text: $documentTitle)
                            
                            Picker("Тип", selection: $selectedType) {
                                ForEach(DocumentType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Сканер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Image Picker

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