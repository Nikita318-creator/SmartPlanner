import UIKit

class TaskListViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureDataSource()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSnapshot), name: NSNotification.Name("TasksUpdated"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSnapshot()
    }
    
    private func setupNavigationBar() {
        view.backgroundColor = AppDesign.backgroundColor
        title = "SmartPlanner"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = AppDesign.backgroundColor
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // Кнопка добавления в бизнес-стиле (акцентная, но строгая)
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)),
            style: .plain,
            target: self,
            action: #selector(didTapAdd)
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
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var configuration = config
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            
            // Бизнес-логика: удаление через свайп с подтверждением
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                guard let self = self, let taskID = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
                
                let delete = UIContextualAction(style: .destructive, title: nil) { _, _, completion in
                    // Находим индекс и удаляем из менеджера (сохранение внутри менеджера)
                    if let index = TaskManager.shared.tasks.firstIndex(where: { $0.id == taskID }) {
                        TaskManager.shared.deleteTask(at: index)
                    }
                    completion(true)
                }
                delete.image = UIImage(systemName: "trash.fill")
                delete.backgroundColor = .systemRed
                
                return UISwipeActionsConfiguration(actions: [delete])
            }
            
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
            section.interGroupSpacing = 8
            return section
        }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<TaskCardCell, UUID> { (cell, indexPath, id) in
            if let task = TaskManager.shared.tasks.first(where: { $0.id == id }) {
                cell.configure(with: task)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Int, UUID>(collectionView: collectionView) { cv, idx, id in
            cv.dequeueConfiguredReusableCell(using: cellRegistration, for: idx, item: id)
        }
    }
    
    @objc func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        // Сортировка: Сначала невыполненные по приоритету (Business Logic)
        let sortedTasks = TaskManager.shared.tasks.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            return $0.priority.weight > $1.priority.weight
        }
        snapshot.appendItems(sortedTasks.map { $0.id })
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc func didTapAdd() {
        let vc = AddTaskViewController()
        let nav = UINavigationController(rootViewController: vc)
        // Для iPad/iPhone Plus используем форму листа
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}

extension TaskListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let taskID = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        TaskManager.shared.toggleComplete(id: taskID)
    }
}
