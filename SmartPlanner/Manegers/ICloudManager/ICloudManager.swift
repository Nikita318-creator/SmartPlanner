import Foundation

class ICloudManager {
    static let shared = ICloudManager()
    
    // ID из твоего скриншота
    private let containerID = "iCloud.com.SmartPlanner.app.SmartPlann"
    private let fileName = "tasks.json"
    
    private var localFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    // Проверка: включил ли пользователь синхронизацию в Settings
    private var isSyncEnabled: Bool {
        return !UserDefaults.standard.bool(forKey: "isCloudDisabled")
    }

    func syncLocalFileToCloud() {
        // Если синхронизация выключена — ничего не отправляем
        guard isSyncEnabled else { return }
        
        DispatchQueue.global(qos: .background).async {
            guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: self.containerID) else {
                print("iCloud Container не доступен")
                return
            }
            
            let cloudURL = containerURL.appendingPathComponent("Documents").appendingPathComponent(self.fileName)
            
            do {
                let cloudDirectory = cloudURL.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: cloudDirectory.path) {
                    try FileManager.default.createDirectory(at: cloudDirectory, withIntermediateDirectories: true)
                }
                
                // Перезаписываем файл в облаке актуальной локальной версией
                if FileManager.default.fileExists(atPath: cloudURL.path) {
                    try FileManager.default.removeItem(at: cloudURL)
                }
                try FileManager.default.copyItem(at: self.localFileURL, to: cloudURL)
                print("Файл успешно синхронизирован с iCloud")
            } catch {
                print("Ошибка синхронизации: \(error.localizedDescription)")
            }
        }
    }
    
    func pullFromCloud() {
        guard isSyncEnabled else { return }
        
        DispatchQueue.global(qos: .background).async {
            guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: self.containerID) else { return }
            let cloudURL = containerURL.appendingPathComponent("Documents").appendingPathComponent(self.fileName)
            
            if FileManager.default.fileExists(atPath: cloudURL.path) {
                do {
                    if FileManager.default.fileExists(atPath: self.localFileURL.path) {
                        try FileManager.default.removeItem(at: self.localFileURL)
                    }
                    try FileManager.default.copyItem(at: cloudURL, to: self.localFileURL)
                    
                    DispatchQueue.main.async {
                        TaskManager.shared.reloadTasks()
                    }
                } catch {
                    print("Ошибка загрузки из облака: \(error)")
                }
            }
        }
    }
}
