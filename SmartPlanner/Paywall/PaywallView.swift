import UIKit
import ApphudSDK

class PaywallView: UIView {
    
    private var selectedProductId: String = SubsIDs.monthlySubsId
    private var optionViews: [SubscriptionOptionView] = []
    
    // MARK: - UI Components
    
    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.image = UIImage(named: "paywall_header")
        iv.clipsToBounds = true
        return iv
    }()
    
    private let gradientOverlay = UIView()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SMART PLANNER PRO"
        label.font = .systemFont(ofSize: 28, weight: .black)
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Enjoy unlimited access, view detailed task analytics, and use Smart AI Schedule for precise time management."
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let optionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()
    
    private let subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = AppDesign.primaryColor
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString("UPGRADE NOW", attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 18, weight: .bold)]))
        button.configuration = config
        return button
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        refreshProducts()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradient()
    }
    
    private func setupLayout() {
        backgroundColor = AppDesign.backgroundColor
        
        [headerImageView, gradientOverlay, contentStack, subscribeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(optionsStack)
        
        subscribeButton.addTarget(self, action: #selector(didTapSubscribe), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.45),
            
            gradientOverlay.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            gradientOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientOverlay.heightAnchor.constraint(equalTo: headerImageView.heightAnchor, multiplier: 0.6),
            
            contentStack.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            
            subscribeButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25),
            subscribeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            subscribeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            subscribeButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func applyGradient() {
        gradientOverlay.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let gradient = CAGradientLayer()
        gradient.frame = gradientOverlay.bounds
        gradient.colors = [AppDesign.backgroundColor.withAlphaComponent(0).cgColor, AppDesign.backgroundColor.cgColor]
        gradient.locations = [0.0, 1.0]
        gradientOverlay.layer.addSublayer(gradient)
    }
    
    func refreshProducts() {
        let storeProducts = IAPManager.shared.getProducts()
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionViews.removeAll()
        
        [SubsIDs.weeklySubsId, SubsIDs.monthlySubsId].forEach { id in
            let product = storeProducts.first(where: { $0.productId == id })
            let optionView = SubscriptionOptionView(productId: id, product: product)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(didSelectOption(_:)))
            optionView.addGestureRecognizer(tap)
            
            optionsStack.addArrangedSubview(optionView)
            optionViews.append(optionView)
            
            if id == selectedProductId { optionView.isSelected = true }
        }
    }
    
    @objc private func didSelectOption(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? SubscriptionOptionView else { return }
        selectedProductId = tappedView.productId
        optionViews.forEach { $0.isSelected = ($0 == tappedView) }
    }
    
    @objc private func didTapSubscribe() {
        subscribeButton.isEnabled = false
        IAPManager.shared.purchase(productId: selectedProductId) { [weak self] result in
            DispatchQueue.main.async {
                self?.subscribeButton.isEnabled = true
                if result == .purchased || result == .restored {
                    NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
                    self?.removeFromSuperview()
                }
            }
        }
    }
}

// MARK: - Option View

class SubscriptionOptionView: UIView {
    let productId: String
    var isSelected: Bool = false { didSet { updateStyle() } }
    
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    
    init(productId: String, product: ApphudProduct?) {
        self.productId = productId
        super.init(frame: .zero)
        
        titleLabel.text = productId == SubsIDs.weeklySubsId ? "WEEKLY" : "MONTHLY"
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
