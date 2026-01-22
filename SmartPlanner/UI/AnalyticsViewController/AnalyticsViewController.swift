import UIKit

class AnalyticsViewController: UIViewController {
    
    // MARK: - Types
    
    private struct AnalyticsSection {
        let title: String
        let rows: [AnalyticsRow]
    }
    
    private struct AnalyticsRow {
        let label: String
        let value: String
        let isSubRow: Bool
        let color: UIColor?
    }
    
    // MARK: - Properties
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [AnalyticsSection] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(updateStats), name: NSNotification.Name("TasksUpdated"), object: nil)
        updateStats()
    }
    
    private func setupUI() {
        title = "Analytics"
        view.backgroundColor = AppDesign.backgroundColor
        
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StatCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    
    @objc private func updateStats() {
        let tasks = TaskManager.shared.tasks
        let cal = Calendar.current
        let now = Date()
        
        // Временные рамки
        let last7Days = cal.date(byAdding: .day, value: -7, to: now)!
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        
        // Генерация секций
        sections = [
            generateAnalyticsSection(for: tasks.filter { $0.date >= last7Days }, title: "Last 7 Days"),
            generateAnalyticsSection(for: tasks.filter { $0.date >= startOfMonth }, title: "This Month"),
            generateAnalyticsSection(for: tasks, title: "All Time")
        ]
        
        tableView.reloadData()
    }
    
    private func generateAnalyticsSection(for tasks: [SmartTask], title: String) -> AnalyticsSection {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // 1. Фильтрация групп
        let completed = tasks.filter { $0.isCompleted }
        let overdue = tasks.filter { !$0.isCompleted && cal.startOfDay(for: $0.date) < today }
        let upcoming = tasks.filter { !$0.isCompleted && cal.startOfDay(for: $0.date) >= today }
        
        var rows: [AnalyticsRow] = []
        
        // Helper для добавления строк с приоритетами
        func appendGroup(title: String, groupTasks: [SmartTask], groupColor: UIColor) {
            rows.append(AnalyticsRow(label: title, value: "\(groupTasks.count)", isSubRow: false, color: groupColor))
            
            for priority in TaskPriority.allCases {
                let count = groupTasks.filter { $0.priority == priority }.count
                if count > 0 {
                    rows.append(AnalyticsRow(label: "∟ \(priority.rawValue)", value: "\(count)", isSubRow: true, color: .secondaryLabel))
                }
            }
        }
        
        // Заполнение данными
        appendGroup(title: "Overdue Tasks", groupTasks: overdue, groupColor: .systemRed)
        appendGroup(title: "Completed Tasks", groupTasks: completed, groupColor: .systemGreen)
        appendGroup(title: "Upcoming Tasks", groupTasks: upcoming, groupColor: AppDesign.primaryColor)
        
        return AnalyticsSection(title: title, rows: rows)
    }
}

// MARK: - UITableViewDataSource

extension AnalyticsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Используем системную ячейку с конфигурацией Value1 (текст слева, значение справа)
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "StatCell")
        let row = sections[indexPath.section].rows[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        
        // Стилизация текста
        content.text = row.label
        content.textProperties.font = .systemFont(ofSize: row.isSubRow ? 14 : 16, weight: row.isSubRow ? .regular : .semibold)
        content.textProperties.color = row.color ?? .label
        
        content.secondaryText = row.value
        content.secondaryTextProperties.font = .monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        content.secondaryTextProperties.color = .label
        
        // KISS: Небольшой отступ для вложенных строк через кастомный префикс (уже в label)
        cell.contentConfiguration = content
        cell.backgroundColor = AppDesign.cardBackground
        cell.selectionStyle = .none
        
        return cell
    }
}
