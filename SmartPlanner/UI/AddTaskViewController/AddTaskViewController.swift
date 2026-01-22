import UIKit

class AddTaskViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Единый форматтер для всего экрана
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    private let titleField: UITextField = {
        let f = UITextField()
        f.placeholder = "Task Name"
        f.borderStyle = .none
        f.font = .systemFont(ofSize: 17)
        f.returnKeyType = .done
        return f
    }()
    
    private let datePicker: UIDatePicker = {
        let p = UIDatePicker()
        p.preferredDatePickerStyle = .compact
        p.datePickerMode = .dateAndTime
        return p
    }()
    
    private let prioritySegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: TaskPriority.allCases.map { $0.rawValue })
        sc.selectedSegmentIndex = 1
        return sc
    }()
    
    private let categorySegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: TaskCategory.allCases.map { $0.rawValue })
        sc.selectedSegmentIndex = 0
        return sc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        setupTapToDismiss()
        
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
    }
    
    private func setupUI() {
        title = "New Task"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        titleField.delegate = self
    }

    @objc private func dateChanged() {
        // Обновляем только нужную ячейку, чтобы не дергать всю таблицу
        let indexPath = IndexPath(row: 0, section: 1)
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.textLabel?.text = dateFormatter.string(from: datePicker.date)
        }
    }

    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func saveTapped() {
        guard let title = titleField.text, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            shakeView(titleField)
            return
        }
        
        let newTask = SmartTask(
            id: UUID(),
            title: title,
            date: datePicker.date,
            priority: TaskPriority.allCases[prioritySegment.selectedSegmentIndex],
            category: TaskCategory.allCases[categorySegment.selectedSegmentIndex],
            isCompleted: false
        )
        
        TaskManager.shared.addTask(newTask)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    private func shakeView(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        view.layer.add(animation, forKey: "shake")
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notif in
            guard let kbFrame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.tableView.contentInset.bottom = kbFrame.height
            self?.tableView.verticalScrollIndicatorInsets.bottom = kbFrame.height
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.tableView.contentInset.bottom = 0
            self?.tableView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
}

extension AddTaskViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddTaskViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 3 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["TASK INFO", "DEADLINE", "PRIORITY & CATEGORY"][section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        
        switch indexPath.section {
        case 0:
            cell.contentView.addSubview(titleField)
            titleField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                titleField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                titleField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                titleField.heightAnchor.constraint(equalToConstant: 44)
            ])
        case 1:
            // Теперь здесь всегда актуальный формат через форматтер
            cell.textLabel?.text = dateFormatter.string(from: datePicker.date)
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.accessoryView = datePicker
        case 2:
            let stack = UIStackView(arrangedSubviews: [prioritySegment, categorySegment])
            stack.axis = .vertical
            stack.spacing = 10
            stack.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
                stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10)
            ])
        default: break
        }
        return cell
    }
}
