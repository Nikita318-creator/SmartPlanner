import UIKit

class TaskCardCell: UICollectionViewCell {
    static let id = "TaskCardCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppDesign.cardBackground
        view.layer.cornerRadius = AppDesign.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let categoryBadge: UIButton = {
        let btn = UIButton()
        btn.isUserInteractionEnabled = false
        btn.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
        btn.layer.cornerRadius = 6
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        return btn
    }()
    
    private let priorityIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        AppDesign.applyShadow(to: containerView)
        
        // Layout Container
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        
        let stackV = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        stackV.axis = .vertical
        stackV.spacing = 4
        stackV.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(priorityIndicator)
        containerView.addSubview(stackV)
        containerView.addSubview(categoryBadge)
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Priority Strip
            priorityIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            priorityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            priorityIndicator.widthAnchor.constraint(equalToConstant: 4),
            priorityIndicator.heightAnchor.constraint(equalToConstant: 30),
            
            // Text Stack
            stackV.leadingAnchor.constraint(equalTo: priorityIndicator.trailingAnchor, constant: 12),
            stackV.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackV.trailingAnchor.constraint(lessThanOrEqualTo: categoryBadge.leadingAnchor, constant: -8),
            
            // Badge
            categoryBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            categoryBadge.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(with task: SmartTask) {
        titleLabel.text = task.title
        dateLabel.text = task.date.formatted(date: .abbreviated, time: .shortened)
        
        // Priority Color
        priorityIndicator.backgroundColor = task.priority.color
        
        // Category Badge Style
        categoryBadge.setTitle(task.category.rawValue.uppercased(), for: .normal)
        categoryBadge.backgroundColor = task.priority.color.withAlphaComponent(0.1)
        categoryBadge.setTitleColor(task.priority.color, for: .normal)
        
        // Completed State
        containerView.alpha = task.isCompleted ? 0.6 : 1.0
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: task.title)
        if task.isCompleted {
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
        }
        titleLabel.attributedText = attributeString
    }
}
