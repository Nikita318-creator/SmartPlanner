import Foundation

class ICloudManager {
    static let shared = ICloudManager()
    
    private let containerID = "iCloud.com.SmartPlanner.app.SmartPlann"
    private let fileName = "tasks.json"
    
    private var localFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    private var cloudFileURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: containerID)?
            .appendingPathComponent("Documents")
            .appendingPathComponent(fileName)
    }

    // Инициализация мониторинга изменений в облаке
    func setupCloudSync() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        
        // Запускаем процесс скачивания, если файла нет локально, но он есть в облаке
        downloadFromCloudIfNeeded()
    }

    @objc private func handleCloudChange() {
        // Логика обработки изменений (например, настроек темы)
        let isLightMode = NSUbiquitousKeyValueStore.default.bool(forKey: "isLightMode")
        UserDefaults.standard.set(isLightMode, forKey: "isLightMode")
    }

    func syncLocalFileToCloud() {
        guard let cloudURL = cloudFileURL else { return }
        
        DispatchQueue.global(qos: .background).async {
            do {
                if FileManager.default.fileExists(atPath: cloudURL.path) {
                    try FileManager.default.removeItem(at: cloudURL)
                }
                
                let cloudDirectory = cloudURL.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: cloudDirectory.path) {
                    try FileManager.default.createDirectory(at: cloudDirectory, withIntermediateDirectories: true)
                }
                
                try FileManager.default.copyItem(at: self.localFileURL, to: cloudURL)
            } catch {
                print("Cloud sync error: \(error.localizedDescription)")
            }
        }
    }

    private func downloadFromCloudIfNeeded() {
        guard let cloudURL = cloudFileURL else { return }
        
        // Если файла нет локально — пробуем забрать из облака
        if !FileManager.default.fileExists(atPath: localFileURL.path) &&
            FileManager.default.fileExists(atPath: cloudURL.path) {
            try? FileManager.default.copyItem(at: cloudURL, to: localFileURL)
            TaskManager.shared.reloadTasks()
        }
    }
}
