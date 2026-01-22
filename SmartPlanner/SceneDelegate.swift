import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        
        let isLightMode = UserDefaults.standard.bool(forKey: "isLightMode")
        window.overrideUserInterfaceStyle = isLightMode ? .light : .dark
        
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        ICloudManager.shared.pullFromCloud()
    }
}
