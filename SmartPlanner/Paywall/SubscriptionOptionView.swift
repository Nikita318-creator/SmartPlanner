import UIKit
import ApphudSDK

class SubscriptionOptionView: UIView {
    let productId: String
    var isSelected: Bool = false { didSet { updateStyle() } }
    
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    
    init(productId: String, product: ApphudProduct?) {
        self.productId = productId
        super.init(frame: .zero)
        
        titleLabel.text = productId == SubsIDs.weeklySubsId ? "WEEKLY ACCESS" : "MONTHLY ACCESS"
        titleLabel.font = .systemFont(ofSize: 14, weight: .black)
        
        priceLabel.text = product?.skProduct?.localizedPrice ?? "-/-"
        priceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayout() {
        backgroundColor = AppDesign.cardBackground
        layer.cornerRadius = AppDesign.cornerRadius
        AppDesign.applyShadow(to: self)
        
        [titleLabel, priceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            priceLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 64)
        ])
    }
    
    private func updateStyle() {
        layer.borderWidth = isSelected ? 3 : 0
        layer.borderColor = AppDesign.primaryColor.cgColor
        titleLabel.textColor = isSelected ? AppDesign.primaryColor : .label
    }
}
