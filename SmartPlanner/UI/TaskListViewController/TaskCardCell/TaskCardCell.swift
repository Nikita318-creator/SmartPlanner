import UIKit

class TaskCardCell: UICollectionViewCell {
    var onCheckmarkTapped: (() -> Void)?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppDesign.cardBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkmarkIcon: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let priorityBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        let tap = UITapGestureRecognizer(target: self, action: #selector(checkTapped))
        checkmarkIcon.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func checkTapped() {
        onCheckmarkTapped?()
    }
    
    private func setupLayout() {
        contentView.addSubview(containerView)
        [priorityBar, titleLabel, dateLabel, checkmarkIcon].forEach { containerView.addSubview($0) }
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            priorityBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            priorityBar.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            priorityBar.widthAnchor.constraint(equalToConstant: 4),
            priorityBar.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: priorityBar.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: checkmarkIcon.leadingAnchor, constant: -12),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            checkmarkIcon.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            checkmarkIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 24),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with task: SmartTask) {
        priorityBar.backgroundColor = task.priority.color
        dateLabel.text = task.date.formatted(date: .abbreviated, time: .shortened)
        
        if task.isCompleted {
            containerView.alpha = 0.5
            checkmarkIcon.image = UIImage(systemName: "checkmark.circle.fill")
            checkmarkIcon.tintColor = .systemGreen
            let attr: [NSAttributedString.Key: Any] = [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            titleLabel.attributedText = NSAttributedString(string: task.title, attributes: attr)
        } else {
            containerView.alpha = 1.0
            checkmarkIcon.image = UIImage(systemName: "circle")
            checkmarkIcon.tintColor = .systemGray4
            titleLabel.attributedText = nil
            titleLabel.text = task.title
        }
    }
}
