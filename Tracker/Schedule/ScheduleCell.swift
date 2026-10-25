import UIKit

// MARK: - ScheduleCell

final class ScheduleCell: UITableViewCell {

    static let reuseIdentifier = "ScheduleCell"

    var onSwitchChanged: ((Bool) -> Void)?

    private let dayLabel = UILabel()
    private let daySwitch = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(day: WeekDay, isOn: Bool) {
        dayLabel.text = day.fullName
        daySwitch.isOn = isOn
        daySwitch.accessibilityIdentifier = day.shortName
    }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        dayLabel.font = .systemFont(ofSize: 17)
        dayLabel.textColor = UIColor(named: "YP Black")
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dayLabel)

        daySwitch.onTintColor = UIColor(named: "YP Blue")
        daySwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        daySwitch.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(daySwitch)

        NSLayoutConstraint.activate([
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            daySwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            daySwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    @objc private func switchChanged() {
        onSwitchChanged?(daySwitch.isOn)
    }
}
