import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        tabBar.tintColor = .systemIndigo
        tabBar.backgroundColor = .systemBackground
    }
    
    private func setupTabs() {
        let tasksVC = UINavigationController(rootViewController: TaskListViewController())
        tasksVC.tabBarItem = UITabBarItem(title: "Tasks", image: UIImage(systemName: "list.bullet"), tag: 0)
        
        let smartVC = UINavigationController(rootViewController: SmartScheduleViewController())
        smartVC.tabBarItem = UITabBarItem(title: "Smart Plan", image: UIImage(systemName: "brain.head.profile"), tag: 1)
        
        let analyticsVC = UINavigationController(rootViewController: AnalyticsViewController())
        analyticsVC.tabBarItem = UITabBarItem(title: "Analytics", image: UIImage(systemName: "chart.pie.fill"), tag: 2)
        
        viewControllers = [tasksVC, smartVC, analyticsVC]
    }
}
