import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Запрос разрешения при старте
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notifications granted: \(granted)")
        }
    }
    
    // Планирование пуша для конкретной задачи
    func scheduleNotification(for task: SmartTask) {
        // Если задача завершена, удаляем уведомление из очереди
        if task.isCompleted {
            cancelNotification(for: task)
            return
        }
        
        // Планируем за 1 час до события
        let triggerDate = task.date.addingTimeInterval(-3600)
        
        // Если время уже прошло — не планируем
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        
        // Формируем красивый заголовок с приоритетом
        let priorityEmoji = task.priority == .high ? "‼️" : (task.priority == .medium ? "⚠️" : "ℹ️")
        content.title = "\(priorityEmoji) \(task.title)"
        
        // Формируем время без даты
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: task.date)
        
        // Тело пуша: Описание + Время
        content.body = "\(timeString) • \(task.notes)"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // ID задачи гарантирует отсутствие дублей
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for task: SmartTask) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
}
