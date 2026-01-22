import UIKit

// MARK: - Models

enum TaskPriority: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var weight: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    var color: UIColor {
        switch self {
        case .high: return .systemRed
        case .medium: return .systemOrange
        case .low: return .systemBlue
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case work = "Work"
    case personal = "Personal"
    case study = "Study"
    case health = "Health"
}

struct SmartTask: Codable, Hashable {
    let id: UUID
    var title: String
    var notes: String // ДОБАВИЛ ПОЛЕ ОПИСАНИЯ
    var date: Date
    var priority: TaskPriority
    var category: TaskCategory
    var isCompleted: Bool
}

// MARK: - Data Manager (Singleton)

class TaskManager {
    static let shared = TaskManager()
    
    private let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("tasks.json")
    
    var tasks: [SmartTask] = []
    
    private init() {
        loadTasks()
    }
    
    func getSmartSchedule() -> [SmartTask] {
        return tasks.filter { !$0.isCompleted }.sorted {
            if $0.priority.weight != $1.priority.weight {
                return $0.priority.weight > $1.priority.weight
            }
            return $0.date < $1.date
        }
    }
    
    func addTask(_ task: SmartTask) {
        tasks.append(task)
        saveTasks()
        NotificationManager.shared.scheduleNotification(for: task) // Планируем пуш
        NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
    }

    func toggleComplete(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
            
            let task = tasks[index]
            if task.isCompleted {
                NotificationManager.shared.cancelNotification(for: task) // Удаляем пуш если завершено
            } else {
                NotificationManager.shared.scheduleNotification(for: task) // Возвращаем в очередь если сняли галочку
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
        }
    }

    func deleteTask(at index: Int) {
        let task = tasks[index]
        NotificationManager.shared.cancelNotification(for: task) // Удаляем пуш при удалении таска
        
        tasks.remove(at: index)
        saveTasks()
        NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
    }

    // При массовой загрузке (из iCloud или календаря)
    func reloadTasks() {
        loadTasks()
        // Перепланируем все активные задачи
        tasks.filter { !$0.isCompleted }.forEach {
            NotificationManager.shared.scheduleNotification(for: $0)
        }
        NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
    }

    private func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Save error: \(error)")
        }
    }
    
    private func loadTasks() {
        do {
            let data = try Data(contentsOf: fileURL)
            tasks = try JSONDecoder().decode([SmartTask].self, from: data)
            print("Successfully loaded \(tasks.count) tasks")
        } catch {
            print("New storage initialized")
        }
    }
}
