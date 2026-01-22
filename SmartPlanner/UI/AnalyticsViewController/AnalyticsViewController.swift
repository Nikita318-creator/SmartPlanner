import UIKit

class AnalyticsViewController: UIViewController {
    
    private let statsLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Analytics"
        view.backgroundColor = .systemBackground
        
        statsLabel.numberOfLines = 0
        statsLabel.textAlignment = .center
        statsLabel.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(statsLabel)
        NSLayoutConstraint.activate([
            statsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateStats), name: NSNotification.Name("TasksUpdated"), object: nil)
        updateStats()
    }
    
    @objc private func updateStats() {
        let allTasks = TaskManager.shared.tasks
        let total = allTasks.count
        let completed = allTasks.filter { $0.isCompleted }.count
        let pending = total - completed
        
        let workCount = allTasks.filter { $0.category == .work }.count
        let healthCount = allTasks.filter { $0.category == .health }.count
        
        let text = """
        📊 PRODUCTIVITY REPORT
        
        Total Tasks: \(total)
        ✅ Completed: \(completed)
        ⏳ Pending: \(pending)
        
        --- Categories ---
        💼 Work: \(workCount)
        ❤️ Health: \(healthCount)
        
        Efficiency: \(total > 0 ? (completed * 100 / total) : 0)%
        """
        
        statsLabel.text = text
    }
}
