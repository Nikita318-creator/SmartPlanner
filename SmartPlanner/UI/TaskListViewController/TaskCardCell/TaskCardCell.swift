import UIKit

class TaskCardCell: UICollectionViewCell {
    
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
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false 
        return label
    }()
    
    private let priorityBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let checkmarkIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayout() {
        contentView.addSubview(containerView)
        [priorityBar, titleLabel, dateLabel, checkmarkIcon].forEach { containerView.addSubview($0) }
        
        NSLayoutConstraint.activate([
            // ВАЖНО: Привязываем контейнер к contentView жестко
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Фиксируем минимальную высоту ячейки, чтобы она не сплющивалась
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),
            
            // Линия приоритета
            priorityBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            priorityBar.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            priorityBar.widthAnchor.constraint(equalToConstant: 4),
            priorityBar.heightAnchor.constraint(equalToConstant: 34),
            
            // Заголовок
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: priorityBar.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: checkmarkIcon.leadingAnchor, constant: -12),
            
            // Дата
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
            
            // Иконка
            checkmarkIcon.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            checkmarkIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 26),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 26)
        ])
    }
    
    func configure(with task: SmartTask) {
        titleLabel.text = task.title
        dateLabel.text = task.date.formatted(date: .abbreviated, time: .shortened)
        priorityBar.backgroundColor = task.priority.color
        
        if task.isCompleted {
            containerView.alpha = 0.6
            checkmarkIcon.image = UIImage(systemName: "checkmark.circle.fill")
            checkmarkIcon.tintColor = .systemGreen
            let attributeString = NSMutableAttributedString(string: task.title)
            attributeString.addAttribute(.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            titleLabel.attributedText = attributeString
        } else {
            containerView.alpha = 1.0
            checkmarkIcon.image = UIImage(systemName: "circle")
            checkmarkIcon.tintColor = .systemGray4
            titleLabel.attributedText = nil
            titleLabel.text = task.title
        }
    }
}
