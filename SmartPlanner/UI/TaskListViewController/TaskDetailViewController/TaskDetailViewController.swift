import UIKit

class TaskDetailViewController: UIViewController {
    private let task: SmartTask
    
    init(task: SmartTask) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Details"
        setupUI()
    }
    
    private func setupUI() {
        // Контейнер (оставляем твой оригинальный стиль)
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 15
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // 1. Заголовок
        let titleLabel = UILabel()
        titleLabel.text = task.title
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.numberOfLines = 0
        
        // 2. Статус
        let statusLabel = UILabel()
        statusLabel.text = task.isCompleted ? "✅ Completed" : "⏳ In Progress"
        statusLabel.font = .systemFont(ofSize: 16, weight: .bold)
        statusLabel.textColor = task.isCompleted ? .systemGreen : .systemOrange
        
        // 3. Дедлайн
        let dateLabel = UILabel()
        dateLabel.text = "⏰ Deadline: " + task.date.formatted(date: .long, time: .shortened)
        dateLabel.font = .systemFont(ofSize: 16)
        
        // 4. Приоритет
        let priorityLabel = UILabel()
        priorityLabel.text = "🚩 Priority: \(task.priority.rawValue)"
        priorityLabel.font = .systemFont(ofSize: 16, weight: .medium)
        priorityLabel.textColor = task.priority.color
        
        // 5. Категория
        let categoryLabel = UILabel()
        categoryLabel.text = "📁 Category: \(task.category.rawValue)"
        categoryLabel.font = .systemFont(ofSize: 16)
        
        // РАЗДЕЛИТЕЛЬ
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        // 6. ОПИСАНИЕ (Notes)
        let notesHeader = UILabel()
        notesHeader.text = "NOTES"
        notesHeader.font = .systemFont(ofSize: 12, weight: .bold)
        notesHeader.textColor = .secondaryLabel
        
        let notesLabel = UILabel()
        notesLabel.text = task.notes.isEmpty ? "No additional notes" : task.notes
        notesLabel.font = .systemFont(ofSize: 16)
        notesLabel.numberOfLines = 0
        
        // Сборка стека (включаем ВСЕ поля)
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            statusLabel,
            dateLabel,
            priorityLabel,
            categoryLabel,
            divider,
            notesHeader,
            notesLabel
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(container)
        container.addSubview(stack)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
    }
}
