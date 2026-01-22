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
        label.textColor = .label
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
        stack.spacing = 12
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
    
    private let footerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing = 20
        return stack
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupFooter()
        refreshProducts()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyGradient()
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        backgroundColor = AppDesign.backgroundColor
        
        [headerImageView, gradientOverlay, contentStack, subscribeButton, footerStack].forEach {
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
            
            // Градиент перекрывает нижнюю часть картинки для плавного ухода в цвет фона
            gradientOverlay.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            gradientOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientOverlay.heightAnchor.constraint(equalTo: headerImageView.heightAnchor, multiplier: 0.6),
            
            contentStack.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            
            subscribeButton.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 24),
            subscribeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            subscribeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            subscribeButton.heightAnchor.constraint(equalToConstant: 56),
            
            footerStack.topAnchor.constraint(equalTo: subscribeButton.bottomAnchor, constant: 16),
            footerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            footerStack.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    private func applyGradient() {
        gradientOverlay.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let gradient = CAGradientLayer()
        gradient.frame = gradientOverlay.bounds
        gradient.colors = [
            AppDesign.backgroundColor.withAlphaComponent(0).cgColor,
            AppDesign.backgroundColor.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradientOverlay.layer.addSublayer(gradient)
    }
    
    private func setupFooter() {
        let termsBtn = createFooterButton(title: "Terms of Use", action: #selector(didTapTerms))
        let privacyBtn = createFooterButton(title: "Privacy Policy", action: #selector(didTapPrivacy))
        let restoreBtn = createFooterButton(title: "Restore", action: #selector(didTapRestore))
        
        [termsBtn, privacyBtn, restoreBtn].forEach { footerStack.addArrangedSubview($0) }
    }
    
    private func createFooterButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let attrTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        button.setAttributedTitle(attrTitle, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    // MARK: - Logic
    
    func refreshProducts() {
        let storeProducts = IAPManager.shared.getProducts()
        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        optionViews.removeAll()
        
        let ids = [SubsIDs.weeklySubsId, SubsIDs.monthlySubsId]
        
        ids.forEach { id in
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
    
    // MARK: - Actions
    
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
    
    @objc private func didTapRestore() {
        IAPManager.shared.restorePurchases { [weak self] result in
            DispatchQueue.main.async {
                if result == .restored {
                    NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
                    self?.removeFromSuperview()
                }
            }
        }
    }
    
    @objc private func didTapTerms() {
        if let url = URL(string: "https://yourdomain.com/terms") { UIApplication.shared.open(url) }
    }
    
    @objc private func didTapPrivacy() {
        if let url = URL(string: "https://yourdomain.com/privacy") { UIApplication.shared.open(url) }
    }
}
