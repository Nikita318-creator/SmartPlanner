import Foundation

class ICloudManager {
    static let shared = ICloudManager()
    
    // Тот самый ID со скриншота. Сюда вставь полный ID контейнера.
    private let containerID = "iCloud.com.SmartPlanner.app.SmartPlann"
    
    private let localFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("tasks.json")
    
    func backupToCloud(completion: @escaping (Bool, String) -> Void) {
        // Проверка: доступно ли облако вообще?
        DispatchQueue.global().async {
            guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: self.containerID) else {
                DispatchQueue.main.async {
                    completion(false, "iCloud container not found. Check Capabilities.")
                }
                return
            }
            
            // Путь к папке Documents внутри облака
            let cloudDocumentsURL = containerURL.appendingPathComponent("Documents")
            let cloudFileURL = cloudDocumentsURL.appendingPathComponent("tasks.json")
            
            do {
                // Создаем папку Documents в облаке, если её нет
                if !FileManager.default.fileExists(atPath: cloudDocumentsURL.path) {
                    try FileManager.default.createDirectory(at: cloudDocumentsURL, withIntermediateDirectories: true)
                }
                
                // Если файл уже есть — удаляем, чтобы перезаписать свежий бекап
                if FileManager.default.fileExists(atPath: cloudFileURL.path) {
                    try FileManager.default.removeItem(at: cloudFileURL)
                }
                
                // Копируем локальный файл в облако
                try FileManager.default.copyItem(at: self.localFileURL, to: cloudFileURL)
                
                DispatchQueue.main.async {
                    completion(true, "Backup successful!")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func restoreFromCloud(completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global().async {
            guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: self.containerID) else {
                DispatchQueue.main.async { completion(false, "iCloud not configured.") }
                return
            }
            
            let cloudFileURL = containerURL.appendingPathComponent("Documents").appendingPathComponent("tasks.json")
            
            // Проверяем, есть ли что восстанавливать
            if !FileManager.default.fileExists(atPath: cloudFileURL.path) {
                DispatchQueue.main.async { completion(false, "No backup file found in iCloud.") }
                return
            }
            
            do {
                // Удаляем старый локальный файл, если он есть
                if FileManager.default.fileExists(atPath: self.localFileURL.path) {
                    try FileManager.default.removeItem(at: self.localFileURL)
                }
                
                // Копируем из облака в локальную песочницу
                try FileManager.default.copyItem(at: cloudFileURL, to: self.localFileURL)
                
                DispatchQueue.main.async {
                    // КРИТИЧНО: просим TaskManager обновить массив tasks из файла
                    TaskManager.shared.reloadTasks()
                    completion(true, "Data successfully restored!")
                }
            } catch {
                DispatchQueue.main.async { completion(false, "Restore error: \(error.localizedDescription)") }
            }
        }
    }
}
