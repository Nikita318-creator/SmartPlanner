import Foundation
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
    var date: Date
    var priority: TaskPriority
    var category: TaskCategory
    var isCompleted: Bool
}

// MARK: - Data Manager (Singleton)

class TaskManager {
    static let shared = TaskManager()
    private let saveKey = "SavedTasks"
    
    var tasks: [SmartTask] = [] {
        didSet { saveTasks() } // Авто-сохранение при любом изменении
    }
    
    private init() { loadTasks() }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([SmartTask].self, from: data) {
            tasks = decoded
        }
    }
    
    func addTask(_ task: SmartTask) {
        tasks.append(task)
        notifyUpdate()
    }
    
    func deleteTask(at index: Int) {
        tasks.remove(at: index)
        notifyUpdate()
    }
    
    func toggleComplete(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
            notifyUpdate()
        }
    }
    
    // Simple AI Recommendation Logic
    func getSmartSchedule() -> [SmartTask] {
        return tasks.filter { !$0.isCompleted }.sorted {
            // Sort by Priority Weight descending, then by Date ascending
            if $0.priority.weight != $1.priority.weight {
                return $0.priority.weight > $1.priority.weight
            }
            return $0.date < $1.date
        }
    }
    
    private func notifyUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
    }
}
