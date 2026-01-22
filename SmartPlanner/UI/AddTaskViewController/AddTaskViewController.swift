import UIKit

class AddTaskViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    private let titleField: UITextField = {
        let f = UITextField()
        f.placeholder = "Task Name"
        f.font = .systemFont(ofSize: 17, weight: .medium)
        return f
    }()
    
    // МНОГОСТРОЧНОЕ ПОЛЕ ДЛЯ DESCRIPTION
    private let notesView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .clear
        return tv
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
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func dateChanged() {
        if let dateLabel = view.viewWithTag(999) as? UILabel {
            dateLabel.text = dateFormatter.string(from: datePicker.date)
        }
    }

    @objc private func saveTapped() {
        guard let title = titleField.text, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            shakeView(titleField)
            return
        }
        
        let newTask = SmartTask(
            id: UUID(),
            title: title,
            notes: notesView.text ?? "", // СОХРАНЯЕМ ОПИСАНИЕ
            date: datePicker.date,
            priority: TaskPriority.allCases[prioritySegment.selectedSegmentIndex],
            category: TaskCategory.allCases[categorySegment.selectedSegmentIndex],
            isCompleted: false
        )
        
        TaskManager.shared.addTask(newTask)
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() { dismiss(animated: true) }
    
    private func shakeView(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.duration = 0.5
        animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        view.layer.add(animation, forKey: "shake")
    }

    private func setupTapToDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notif in
            guard let kbFrame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.tableView.contentInset.bottom = kbFrame.height
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.tableView.contentInset.bottom = 0
        }
    }
}

extension AddTaskViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 4 } // СЕКЦИЙ ТЕПЕРЬ 4
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["TITLE", "DESCRIPTION", "DEADLINE", "SETTINGS"][section]
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
                titleField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
        case 1:
            cell.contentView.addSubview(notesView)
            notesView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                notesView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                notesView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
                notesView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
                notesView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
                cell.contentView.heightAnchor.constraint(equalToConstant: 100)
            ])
        case 2:
            let stack = UIStackView()
            stack.axis = .vertical
            stack.translatesAutoresizingMaskIntoConstraints = false
            let topL = UILabel(); topL.text = "Date & Time"; topL.font = .systemFont(ofSize: 14)
            let botL = UILabel(); botL.text = dateFormatter.string(from: datePicker.date); botL.font = .systemFont(ofSize: 12); botL.textColor = .secondaryLabel; botL.tag = 999
            stack.addArrangedSubview(topL); stack.addArrangedSubview(botL)
            cell.contentView.addSubview(stack)
            cell.contentView.addSubview(datePicker)
            datePicker.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                stack.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                datePicker.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                datePicker.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 54)
            ])
        case 3:
            let stack = UIStackView(arrangedSubviews: [prioritySegment, categorySegment])
            stack.axis = .vertical; stack.spacing = 10; stack.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
                stack.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                stack.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
            ])
        default: break
        }
        return cell
    }
}
