import UIKit

class TaskListViewController: UIViewController {
    
    // Modern Collection View
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, UUID>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureDataSource()
        
        // Listen for data changes
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
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = AppDesign.backgroundColor
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = AppDesign.primaryColor
        // Увеличиваем кнопку визуально
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        addButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = AppDesign.backgroundColor
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        // Modern List Layout
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var configuration = config
            configuration.backgroundColor = AppDesign.backgroundColor
            configuration.showsSeparators = false
            
            // Swipe Actions
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                guard let self = self, let taskID = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
                
                let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                    if let index = TaskManager.shared.tasks.firstIndex(where: { $0.id == taskID }) {
                        TaskManager.shared.deleteTask(at: index)
                    }
                    completion(true)
                }
                return UISwipeActionsConfiguration(actions: [delete])
            }
            
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 20, trailing: 0)
            section.interGroupSpacing = 12 // Расстояние между карточками
            return section
        }
    }
    
    private func configureDataSource() {
        // Registration
        let cellRegistration = UICollectionView.CellRegistration<TaskCardCell, UUID> { (cell, indexPath, id) in
            if let task = TaskManager.shared.tasks.first(where: { $0.id == id }) {
                cell.configure(with: task)
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Int, UUID>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: UUID) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
    }
    
    @objc func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(TaskManager.shared.tasks.map { $0.id })
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc func didTapAdd() {
        let vc = AddTaskViewController()
        present(UINavigationController(rootViewController: vc), animated: true)
    }
}

extension TaskListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let taskID = dataSource.itemIdentifier(for: indexPath) else { return }
        collectionView.deselectItem(at: indexPath, animated: true)
        
        // Haptic Feedback (Вибрация при нажатии)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        TaskManager.shared.toggleComplete(id: taskID)
    }
}
