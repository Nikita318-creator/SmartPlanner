import UIKit

class AddTaskViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // UI Elements
    private let titleField: UITextField = {
        let f = UITextField()
        f.placeholder = "What needs to be done?"
        f.font = .systemFont(ofSize: 17)
        return f
    }()
    
    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.preferredDatePickerStyle = .compact
        return p
    }()
    
    private let priorityControl = UISegmentedControl(items: TaskPriority.allCases.map { $0.rawValue })
    private let categoryControl = UISegmentedControl(items: TaskCategory.allCases.map { $0.rawValue })

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
    }
    
    private func setupUI() {
        title = "New Event"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // РЕАЛЬНОЕ СОХРАНЕНИЕ
    @objc private func saveTapped() {
        guard let title = titleField.text, !title.isEmpty else {
            let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
            anim.values = [-10, 10, -10, 10, 0]
            titleField.layer.add(anim, forKey: "shake")
            return
        }
        
        let newTask = SmartTask(
            id: UUID(),
            title: title,
            date: datePicker.date,
            priority: TaskPriority.allCases[priorityControl.selectedSegmentIndex],
            category: TaskCategory.allCases[categoryControl.selectedSegmentIndex],
            isCompleted: false
        )
        
        TaskManager.shared.addTask(newTask)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() { dismiss(animated: true) }

    // ОБРАБОТКА КЛАВИАТУРЫ (чтобы не перекрывала поля)
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notif in
            guard let kbFrame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.tableView.contentInset.bottom = kbFrame.height
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.tableView.contentInset.bottom = 0
        }
        // Скрытие клавиатуры по тапу на таблицу
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

extension AddTaskViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 3 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["Details", "Schedule", "Organization"][section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        switch indexPath.section {
        case 0: cell.contentView.addSubview(titleField); titleField.frame = cell.contentView.bounds.insetBy(dx: 16, dy: 0)
        case 1:
            cell.textLabel?.text = "Deadline"
            cell.accessoryView = datePicker
        case 2:
            let stack = UIStackView(arrangedSubviews: [priorityControl, categoryControl])
            stack.axis = .vertical; stack.spacing = 8; stack.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
            ])
        default: break
        }
        return cell
    }
}
