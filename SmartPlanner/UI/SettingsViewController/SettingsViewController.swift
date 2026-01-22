import UIKit
import StoreKit
import EventKit

class SettingsViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<String, UUID>!
    
    private struct SettingItem {
        let id = UUID()
        let title: String
        let image: String
        let color: UIColor?
        let hasSwitch: Bool // Добавляем флаг для тогла
        let action: (() -> Void)?
    }
    
    private var settingsData: [UUID: SettingItem] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        prepareData()
        configureHierarchy()
        configureDataSource()
        updateSnapshot()
    }
    
    private func setupNavigationBar() {
        view.backgroundColor = AppDesign.backgroundColor
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func prepareData() {
        settingsData.removeAll()
        let items = [
            // Секция Appearance
            SettingItem(title: "Light Mode", image: "sun.max.fill", color: .systemYellow, hasSwitch: true, action: nil),
            
            // Секция Sync
            SettingItem(title: "Import from Calendar", image: "calendar.badge.plus", color: nil, hasSwitch: false) { [weak self] in self?.handleCalendarImport() },
            SettingItem(title: "Backup to iCloud", image: "icloud.and.arrow.up", color: nil, hasSwitch: false) { [weak self] in self?.handleICloudBackup() },
            SettingItem(title: "Restore from iCloud", image: "icloud.and.arrow.down", color: .systemGreen, hasSwitch: false) { [weak self] in self?.handleICloudRestore() },
            
            // Секция Legal
            SettingItem(title: "Privacy Policy", image: "shield.lefthalf.filled", color: nil, hasSwitch: false) { [weak self] in self?.openURL("https://example.com/privacy") },
            SettingItem(title: "Terms of Service", image: "doc.text", color: nil, hasSwitch: false) { [weak self] in self?.openURL("https://example.com/terms") },
            SettingItem(title: "Rate Us", image: "star.fill", color: .systemOrange, hasSwitch: false) { [weak self] in self?.requestReview() }
        ]
        items.forEach { settingsData[$0.id] = $0 }
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, UUID> { [weak self] cell, indexPath, id in
            guard let item = self?.settingsData[id] else { return }
            
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            content.image = UIImage(systemName: item.image)
            content.imageProperties.tintColor = item.color ?? .label
            
            cell.contentConfiguration = content
            
            if item.hasSwitch {
                let themeSwitch = UISwitch()
                themeSwitch.isOn = UserDefaults.standard.bool(forKey: "isLightMode")
                themeSwitch.addTarget(self, action: #selector(self?.themeChanged(_:)), for: .valueChanged)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: themeSwitch, placement: .trailing())
                cell.accessories = [.customView(configuration: configuration)]
            } else {
                cell.accessories = [.disclosureIndicator()]
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<String, UUID>(collectionView: collectionView) { (cv, idx, id) in
            return cv.dequeueConfiguredReusableCell(using: cellRegistration, for: idx, item: id)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { (header, kind, idx) in
            let sections = ["APPEARANCE", "SYNCHRONIZATION", "LEGAL & FEEDBACK"]
            var config = header.defaultContentConfiguration()
            config.text = sections[idx.section]
            config.textProperties.font = .systemFont(ofSize: 13, weight: .black)
            config.textProperties.color = .secondaryLabel
            header.contentConfiguration = config
        }
        
        dataSource.supplementaryViewProvider = { (cv, kind, idx) in
            return cv.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: idx)
        }
    }
    
    private func configureHierarchy() {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.backgroundColor = .clear
        
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = AppDesign.backgroundColor
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<String, UUID>()
        snapshot.appendSections(["APPEARANCE", "SYNCHRONIZATION", "LEGAL & FEEDBACK"])
        
        let appearanceIDs = settingsData.values.filter { $0.title == "Light Mode" }.map { $0.id }
        let syncIDs = settingsData.values.filter { $0.image.contains("calendar") || $0.image.contains("icloud") }.map { $0.id }
        let legalIDs = settingsData.values.filter { !appearanceIDs.contains($0.id) && !syncIDs.contains($0.id) }.map { $0.id }
        
        snapshot.appendItems(appearanceIDs, toSection: "APPEARANCE")
        snapshot.appendItems(syncIDs, toSection: "SYNCHRONIZATION")
        snapshot.appendItems(legalIDs, toSection: "LEGAL & FEEDBACK")
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    // MARK: - Handlers

    @objc private func themeChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "isLightMode")
        
        // Применяем тему ко всем окнам приложения мгновенно
        view.window?.windowScene?.windows.forEach { window in
            window.overrideUserInterfaceStyle = sender.isOn ? .light : .dark
        }
    }
    
    private func handleCalendarImport() {
        let eventStore = EKEventStore()
        
        // Проверка разрешений в зависимости от версии iOS
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                if granted {
                    self?.fetchCalendarEvents(store: eventStore)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                if granted {
                    self?.fetchCalendarEvents(store: eventStore)
                }
            }
        }
    }

    private func fetchCalendarEvents(store: EKEventStore) {
        // Берем события на месяц вперед
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = store.events(matching: predicate)
        
        var newTasksAdded = 0
        
        for event in events {
            // Проверяем, не добавляли ли мы это событие ранее (по заголовку и дате),
            // чтобы избежать дубликатов при повторном нажатии
            let isAlreadyAdded = TaskManager.shared.tasks.contains {
                $0.title == event.title && $0.date == event.startDate
            }
            
            if !isAlreadyAdded {
                let newTask = SmartTask(
                    id: UUID(),
                    title: event.title ?? "Untitled Event",
                    notes: event.notes ?? "Imported from Calendar",
                    date: event.startDate,
                    priority: .medium, // Дефолтный приоритет для импорта
                    category: .personal, // Дефолтная категория
                    isCompleted: false
                )
                
                // Используем DispatchQueue.main, так как addTask шлет нотификацию для UI
                DispatchQueue.main.async {
                    TaskManager.shared.addTask(newTask)
                }
                newTasksAdded += 1
            }
        }
        
        // Опционально: показать алерт о завершении
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Import Complete",
                message: "Added \(newTasksAdded) new tasks from your calendar.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func handleICloudBackup() {
        ICloudManager.shared.backupToCloud { [weak self] success, message in
            let alert = UIAlertController(
                title: success ? "Success" : "Backup Failed",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    private func handleICloudRestore() {
        let alert = UIAlertController(
            title: "Restore Data?",
            message: "This will replace your current tasks with the version from iCloud. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Restore", style: .destructive) { [weak self] _ in
            ICloudManager.shared.restoreFromCloud { success, message in
                let resAlert = UIAlertController(title: success ? "Success" : "Error", message: message, preferredStyle: .alert)
                resAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(resAlert, animated: true)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func requestReview() {
        if let scene = view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

extension SettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let item = settingsData[id],
              let action = item.action else { return }
        action()
    }
}
