import UIKit

class SmartScheduleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var smartTasks: [SmartTask] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name("TasksUpdated"), object: nil)
        refresh()
        
        if !IAPManager.shared.hasActiveSubscription {
            let lockView = PaywallView(frame: self.view.bounds)
            self.view.addSubview(lockView)
            lockView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
    private func setupUI() {
        // Оставляем системный тайтл согласно ТЗ [cite: 2]
        title = "Smart Schedule"
        view.backgroundColor = AppDesign.backgroundColor
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "smartCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    
    @objc private func refresh() {
        let allTasks = TaskManager.shared.tasks
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // Фильтрация согласно ТЗ: только актуальные задачи [cite: 8, 40]
        let activeTasks = allTasks.filter { task in
            let isOverdue = cal.startOfDay(for: task.date) < today
            return !task.isCompleted && !isOverdue
        }
        
        // Умная сортировка: Сначала сегодня по приоритету, затем всё остальное по приоритету [cite: 12, 13]
        smartTasks = activeTasks.sorted { t1, t2 in
            let isT1Today = cal.isDateInToday(t1.date)
            let isT2Today = cal.isDateInToday(t2.date)
            
            if isT1Today != isT2Today {
                return isT1Today
            }
            
            if t1.priority.weight != t2.priority.weight {
                return t1.priority.weight > t2.priority.weight
            }
            return t1.date < t2.date
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return smartTasks.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if smartTasks.isEmpty { return nil }
        
        // Эмоциональные заголовки вместо технических
        let firstTaskIsToday = Calendar.current.isDateInToday(smartTasks[0].date)
        return firstTaskIsToday ? "Top of your list right now 👇" : "Coming up next... 🗺️"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "smartCell", for: indexPath)
        let task = smartTasks[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        
        // Добавляем понятный контекст времени
        let timeString = task.date.formatted(date: .omitted, time: .shortened)
        let isToday = Calendar.current.isDateInToday(task.date)
        content.secondaryText = isToday ? "Today at \(timeString)" : task.date.formatted(date: .abbreviated, time: .shortened)
        
        // Визуальный акцент на приоритете через цвет [cite: 10, 21]
        content.image = UIImage(systemName: "circle.fill")
        content.imageProperties.tintColor = task.priority.color
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = smartTasks[indexPath.row]
        
        // Открытие детальной информации [cite: 9]
        let detailVC = TaskDetailViewController(task: task)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
