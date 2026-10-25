import UIKit

// MARK: - TrackerCellDelegate

protocol TrackerCellDelegate: AnyObject {
    func trackerCellDidTapPlus(_ cell: TrackerCell)
}

// MARK: - TrackerCell

final class TrackerCell: UICollectionViewCell {

    static let reuseIdentifier = "TrackerCell"

    private enum Layout {
        static let cardHeight: CGFloat = 90
        static let cardCornerRadius: CGFloat = 16
        static let emojiSize: CGFloat = 24
        static let emojiInset: CGFloat = 12
        static let titleInset: CGFloat = 12
        static let plusButtonSize: CGFloat = 34
        static let plusTopInset: CGFloat = 8
        static let plusTrailingInset: CGFloat = 12
        static let counterLeadingInset: CGFloat = 12
        static let pinSize: CGFloat = 24
        static let pinInset: CGFloat = 4
    }

    weak var delegate: TrackerCellDelegate?

    private let cardView = UIView()
    private let emojiBackgroundView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let counterLabel = UILabel()
    private let plusButton = UIButton(type: .custom)
    private let pinImageView = UIImageView()

    // для контекстного меню подсвечиваем только цветную карточку, без счетчика
    var previewView: UIView {
        cardView
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
        setupEmoji()
        setupTitle()
        setupPin()
        setupCounter()
        setupPlusButton()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(with tracker: Tracker, isCompleted: Bool, completedDays: Int, isEnabled: Bool) {
        cardView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.title
        pinImageView.isHidden = !tracker.isPinned
        counterLabel.text = Self.daysText(completedDays)

        let symbolName = isCompleted ? SystemImage.checkmark : SystemImage.plus
        plusButton.setImage(UIImage(systemName: symbolName), for: .normal)
        plusButton.backgroundColor = tracker.color
        plusButton.alpha = isCompleted ? 0.3 : 1
        plusButton.isEnabled = isEnabled
        plusButton.accessibilityIdentifier = isCompleted
            ? AccessibilityIdentifiers.trackerDoneButton
            : AccessibilityIdentifiers.trackerUndoneButton
    }

    // склонение дней лежит в Localizable.stringsdict
    static func daysText(_ count: Int) -> String {
        String.localizedStringWithFormat(NSLocalizedString("days.count", comment: ""), count)
    }

    private func setupCard() {
        cardView.layer.cornerRadius = Layout.cardCornerRadius
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: Layout.cardHeight)
        ])
    }

    private func setupEmoji() {
        emojiBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emojiBackgroundView.layer.cornerRadius = Layout.emojiSize / 2
        emojiBackgroundView.layer.masksToBounds = true
        emojiBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(emojiBackgroundView)

        emojiLabel.font = .systemFont(ofSize: 14)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiBackgroundView.addSubview(emojiLabel)

        NSLayoutConstraint.activate([
            emojiBackgroundView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Layout.emojiInset),
            emojiBackgroundView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: Layout.emojiInset),
            emojiBackgroundView.widthAnchor.constraint(equalToConstant: Layout.emojiSize),
            emojiBackgroundView.heightAnchor.constraint(equalToConstant: Layout.emojiSize),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackgroundView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackgroundView.centerYAnchor)
        ])
    }

    private func setupTitle() {
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: Layout.titleInset),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -Layout.titleInset),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -Layout.titleInset)
        ])
    }

    private func setupPin() {
        pinImageView.image = UIImage(
            systemName: SystemImage.pin,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        )
        pinImageView.tintColor = .white
        pinImageView.contentMode = .center
        pinImageView.isHidden = true
        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(pinImageView)
        NSLayoutConstraint.activate([
            pinImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Layout.pinInset),
            pinImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -Layout.pinInset),
            pinImageView.widthAnchor.constraint(equalToConstant: Layout.pinSize),
            pinImageView.heightAnchor.constraint(equalToConstant: Layout.pinSize)
        ])
    }

    private func setupCounter() {
        counterLabel.font = .systemFont(ofSize: 12, weight: .medium)
        counterLabel.textColor = UIColor(resource: .ypBlack)
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(counterLabel)
        NSLayoutConstraint.activate([
            counterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.counterLeadingInset),
            counterLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 16)
        ])
    }

    private func setupPlusButton() {
        plusButton.tintColor = UIColor(resource: .ypWhite)
        plusButton.layer.cornerRadius = Layout.plusButtonSize / 2
        plusButton.layer.masksToBounds = true
        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(plusButton)
        NSLayoutConstraint.activate([
            plusButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: Layout.plusTopInset),
            plusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.plusTrailingInset),
            plusButton.widthAnchor.constraint(equalToConstant: Layout.plusButtonSize),
            plusButton.heightAnchor.constraint(equalToConstant: Layout.plusButtonSize)
        ])
    }

    @objc private func didTapPlus() {
        delegate?.trackerCellDidTapPlus(self)
    }
}
