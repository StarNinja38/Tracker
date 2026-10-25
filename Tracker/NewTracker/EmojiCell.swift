import UIKit

// MARK: - EmojiCell

final class EmojiCell: UICollectionViewCell {

    static let reuseIdentifier = "EmojiCell"

    private let emojiLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        emojiLabel.font = .systemFont(ofSize: 32)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        contentView.backgroundColor = isSelected ? UIColor(named: "YP LightGray") : .clear
        accessibilityIdentifier = "emoji \(emoji)"
    }
}
