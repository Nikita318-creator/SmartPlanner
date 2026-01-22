import UIKit

class TaskListViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<String, UUID>!
    private var collapsedSections: Set<String> = ["COMPLETED", "OVERDUE"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureDataSource()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSnapshot), name: NSNotification.Name("TasksUpdated"), object: nil)
        updateSnapshot()
    }
    
    private func setupNavigationBar() {
        view.backgroundColor = AppDesign.backgroundColor
        title = "Smart Schedule"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)),
            style: .plain, target: self, action: #selector(didTapAdd)
        )
        addButton.tintColor = AppDesign.primaryColor
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = AppDesign.backgroundColor
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.backgroundColor = .clear
        config.showsSeparators = false
        
        config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self = self, let taskID = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            let delete = UIContextualAction(style: .destructive, title: nil) { _, _, completion in
                if let index = TaskManager.shared.tasks.firstIndex(where: { $0.id == taskID }) {
                    TaskManager.shared.deleteTask(at: index)
                }
                completion(true)
            }
            delete.image = UIImage(systemName: "trash.fill")
            return UISwipeActionsConfiguration(actions: [delete])
        }
        
        return UICollectionViewCompositionalLayout.list(using: config)
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<TaskCardCell, UUID> { (cell, indexPath, id) in
            if let task = TaskManager.shared.tasks.first(where: { $0.id == id }) {
                cell.configure(with: task)
                cell.onCheckmarkTapped = { TaskManager.shared.toggleComplete(id: id) }
            }
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] (headerView, elementKind, indexPath) in
            guard let self = self else { return }
            
            // Берем ID секции из текущего snapshot, чтобы не зависеть от индексов
            let sections = self.dataSource.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return }
            let sectionIdentifier = sections[indexPath.section]
            
            var config = headerView.defaultContentConfiguration()
            config.text = sectionIdentifier
            config.textProperties.font = .systemFont(ofSize: 13, weight: .black)
            config.textProperties.color = sectionIdentifier == "OVERDUE" ? .systemRed : .secondaryLabel
            headerView.contentConfiguration = config
            
            // ПРАВИЛЬНЫЙ ПОВОРОТ СТРЕЛОЧКИ
            let isCollapsed = self.collapsedSections.contains(sectionIdentifier)
            
            // Создаем опции и выставляем поворот: если НЕ свернуто, значит стрелка вниз (rotated = true)
            var disclosureOptions = UICellAccessory.DisclosureIndicatorOptions()
            disclosureOptions.tintColor = .gray
//            disclosureOptions.isRotated = !isCollapsed // Вот тут магия поворота
            
            headerView.accessories = [.disclosureIndicator(displayed: .always, options: disclosureOptions)]
            
            // ТАП-ЖЕСТ через кастомный класс
            let tap = CustomTapGesture(target: self, action: #selector(self.toggleSection(_:)))
            tap.sectionID = sectionIdentifier
            headerView.gestureRecognizers?.forEach { headerView.removeGestureRecognizer($0) }
            headerView.addGestureRecognizer(tap)
        }
        
        dataSource = UICollectionViewDiffableDataSource<String, UUID>(collectionView: collectionView) { (cv, idx, id) in
            return cv.dequeueConfiguredReusableCell(using: cellRegistration, for: idx, item: id)
        }
        
        dataSource.supplementaryViewProvider = { (cv, kind, idx) in
            return cv.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: idx)
        }
    }
    
    @objc private func toggleSection(_ gesture: CustomTapGesture) {
        guard let sectionIdentifier = gesture.sectionID else { return }
        
        if collapsedSections.contains(sectionIdentifier) {
            collapsedSections.remove(sectionIdentifier)
        } else {
            collapsedSections.insert(sectionIdentifier)
        }
        updateSnapshot()
    }
    
    @objc func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<String, UUID>()
        let tasks = TaskManager.shared.tasks
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // Фильтрация
        let overdueItems = tasks.filter { !$0.isCompleted && cal.startOfDay(for: $0.date) < today }
        let todayItems = tasks.filter { !$0.isCompleted && cal.isDateInToday($0.date) }
        let tomorrowItems = tasks.filter { !$0.isCompleted && cal.isDateInTomorrow($0.date) }
        let futureItems = tasks.filter { !$0.isCompleted && cal.startOfDay(for: $0.date) > cal.date(byAdding: .day, value: 1, to: today)! }
        let completedItems = tasks.filter { $0.isCompleted }
        
        func addSection(named: String, items: [SmartTask]) {
            // ЛОГИКА: Показываем секцию только если в ней есть задачи
            if !items.isEmpty {
                snapshot.appendSections([named])
                if !collapsedSections.contains(named) {
                    let sortedIDs = items.sorted {
                        if $0.priority.weight != $1.priority.weight { return $0.priority.weight > $1.priority.weight }
                        return $0.date < $1.date
                    }.map { $0.id }
                    snapshot.appendItems(sortedIDs, toSection: named)
                }
            }
        }
        
        addSection(named: "OVERDUE", items: overdueItems)
        addSection(named: "TODAY", items: todayItems)
        addSection(named: "TOMORROW", items: tomorrowItems)
        
        let grouped = Dictionary(grouping: futureItems) { task -> String in
            let df = DateFormatter()
            df.dateFormat = "EEEE, d MMM"
            return df.string(from: task.date).uppercased()
        }
        
        grouped.keys.sorted { t1, t2 in
            let df = DateFormatter(); df.dateFormat = "EEEE, d MMM"
            guard let d1 = df.date(from: t1.capitalized), let d2 = df.date(from: t2.capitalized) else { return false }
            return d1 < d2
        }.forEach { addSection(named: $0, items: grouped[$0]!) }
        
        addSection(named: "COMPLETED", items: completedItems)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc func didTapAdd() {
        let vc = AddTaskViewController()
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}

// Кастомный жест, чтобы протащить ID секции
class CustomTapGesture: UITapGestureRecognizer {
    var sectionID: String?
}

extension TaskListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let task = TaskManager.shared.tasks.first(where: { $0.id == id }) else { return }
        
        let detailVC = TaskDetailViewController(task: task)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
