import UIKit

// MARK: - ColorCell

/// Цвет в сетке выбора. Выбранный обводится рамкой того же цвета с прозрачностью 30%.
final class ColorCell: UICollectionViewCell {

    static let reuseIdentifier = "ColorCell"

    private enum Layout {
        static let colorSize: CGFloat = 40
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 3
    }

    private let colorView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.layer.borderWidth = Layout.borderWidth

        colorView.layer.cornerRadius = Layout.cornerRadius
        colorView.layer.masksToBounds = true
        colorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(colorView)
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: Layout.colorSize),
            colorView.heightAnchor.constraint(equalToConstant: Layout.colorSize)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(color: UIColor, isSelected: Bool, identifier: String) {
        colorView.backgroundColor = color
        contentView.layer.borderColor = isSelected
            ? color.withAlphaComponent(0.3).cgColor
            : UIColor.clear.cgColor
        accessibilityIdentifier = identifier
    }
}
