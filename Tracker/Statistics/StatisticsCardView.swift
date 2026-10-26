import UIKit

// MARK: - StatisticsCardView

final class StatisticsCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 1
        static let inset: CGFloat = 12
        static let spacing: CGFloat = 7
    }

    private let valueLabel = UILabel()
    private let titleLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with item: StatisticsItem) {
        valueLabel.text = "\(item.value)"
        titleLabel.text = item.title
    }

    // рамка градиентом как в макете: градиент маскируется контуром карточки
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        let inset = Layout.borderWidth / 2
        borderMask.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: Layout.cornerRadius
        ).cgPath
    }

    private func setupView() {
        gradientLayer.colors = [
            UIColor(red: 0.99, green: 0.30, blue: 0.29, alpha: 1).cgColor,
            UIColor(red: 0.27, green: 0.90, blue: 0.62, alpha: 1).cgColor,
            UIColor(red: 0.00, green: 0.48, blue: 0.98, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        borderMask.lineWidth = Layout.borderWidth
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        gradientLayer.mask = borderMask
        layer.addSublayer(gradientLayer)

        valueLabel.font = .systemFont(ofSize: 34, weight: .bold)
        valueLabel.textColor = UIColor(resource: .ypBlack)
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = UIColor(resource: .ypBlack)

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = Layout.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.inset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.inset),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
