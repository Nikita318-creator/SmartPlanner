import UIKit

class SmartScheduleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var smartTasks: [SmartTask] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AI Schedule"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "smartCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name("TasksUpdated"), object: nil)
        refresh()
    }
    
    @objc private func refresh() {
        // AI Logic: Get tasks sorted by Importance
        smartTasks = TaskManager.shared.getSmartSchedule()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return smartTasks.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Recommended Order (Highest Priority First)"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "smartCell", for: indexPath)
        let task = smartTasks[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        content.secondaryText = "Due: \(task.date.formatted(date: .numeric, time: .shortened))"
        content.image = UIImage(systemName: "circle.fill")
        content.imageProperties.tintColor = task.priority.color // Red/Orange/Blue
        
        cell.contentConfiguration = content
        return cell
    }
}
