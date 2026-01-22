import UIKit

struct AppDesign {
    static let primaryColor = UIColor.systemBlue
    static let backgroundColor = UIColor.systemGroupedBackground
    static let cardBackground = UIColor.secondarySystemGroupedBackground
    static let cornerRadius: CGFloat = 14
    
    static func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
    }
}
