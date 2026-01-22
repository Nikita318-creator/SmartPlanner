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
        let hasSwitch: Bool
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
            SettingItem(title: "iCloud Sync", image: "icloud.fill", color: .systemBlue, hasSwitch: true, action: nil),
            SettingItem(title: "Import from Calendar", image: "calendar.badge.plus", color: nil, hasSwitch: false) { [weak self] in self?.handleCalendarImport() },
            
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
                let controlSwitch = UISwitch()
                if item.title == "Light Mode" {
                    controlSwitch.isOn = UserDefaults.standard.bool(forKey: "isLightMode")
                    controlSwitch.addTarget(self, action: #selector(self?.themeChanged(_:)), for: .valueChanged)
                } else {
                    // iCloud Sync: по умолчанию включено (isCloudDisabled = false)
                    controlSwitch.isOn = !UserDefaults.standard.bool(forKey: "isCloudDisabled")
                    controlSwitch.addTarget(self, action: #selector(self?.cloudSyncChanged(_:)), for: .valueChanged)
                }
                let configuration = UICellAccessory.CustomViewConfiguration(customView: controlSwitch, placement: .trailing())
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
        let syncIDs = settingsData.values.filter { $0.title == "iCloud Sync" || $0.title == "Import from Calendar" }.map { $0.id }
        let legalIDs = settingsData.values.filter { !appearanceIDs.contains($0.id) && !syncIDs.contains($0.id) }.map { $0.id }
        
        snapshot.appendItems(appearanceIDs, toSection: "APPEARANCE")
        snapshot.appendItems(syncIDs, toSection: "SYNCHRONIZATION")
        snapshot.appendItems(legalIDs, toSection: "LEGAL & FEEDBACK")
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    // MARK: - Handlers

    @objc private func themeChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "isLightMode")
        view.window?.windowScene?.windows.forEach { window in
            window.overrideUserInterfaceStyle = sender.isOn ? .light : .dark
        }
    }
    
    @objc private func cloudSyncChanged(_ sender: UISwitch) {
        // Если switch ON (включено), значит Disabled = false
        UserDefaults.standard.set(!sender.isOn, forKey: "isCloudDisabled")
        if sender.isOn {
            ICloudManager.shared.syncLocalFileToCloud()
        }
    }
    
    private func handleCalendarImport() {
        let eventStore = EKEventStore()
        let completion: (Bool, Error?) -> Void = { [weak self] granted, _ in
            if granted {
                DispatchQueue.main.async { self?.fetchCalendarEvents(store: eventStore) }
            }
        }
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents(completion: completion)
        } else {
            eventStore.requestAccess(to: .event, completion: completion)
        }
    }

    private func fetchCalendarEvents(store: EKEventStore) {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = store.events(matching: predicate)
        
        var addedCount = 0
        for event in events {
            let exists = TaskManager.shared.tasks.contains { $0.title == event.title && $0.date == event.startDate }
            if !exists {
                let task = SmartTask(id: UUID(), title: event.title ?? "Untitled", notes: event.notes ?? "", date: event.startDate, priority: .medium, category: .personal, isCompleted: false)
                TaskManager.shared.addTask(task)
                addedCount += 1
            }
        }
        
        let alert = UIAlertController(title: "Import", message: "Added \(addedCount) tasks.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
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
