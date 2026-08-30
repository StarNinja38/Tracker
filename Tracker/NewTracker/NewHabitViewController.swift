import UIKit

// MARK: - NewHabitViewController

/// Создание привычки. По заданию спринта 14 секций эмодзи и цвета нет,
/// кнопка «Категория» присутствует, но не работает.
final class NewHabitViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let textFieldHeight: CGFloat = 75
        static let textFieldTopInset: CGFloat = 24
        static let rowHeight: CGFloat = 75
        static let tableTopInset: CGFloat = 24
        static let cornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 60
        static let buttonSpacing: CGFloat = 8
        static let buttonBottomInset: CGFloat = 16
    }

    private enum Constants {
        static let titleLimit = 38
        /// 18 цветов карточек из макета. Экран выбора цвета — задание спринта 15,
        /// пока цвет и эмодзи назначаются случайно.
        static let colorNames = (1...18).map { "Color selection \($0)" }
        static let emojis = ["🙂", "😻", "🌺", "🐶", "❤️", "😱", "🏝", "😪", "🥦", "🏓"]
    }

    /// Отдаёт созданный трекер главному экрану.
    var onCreate: ((Tracker) -> Void)?

    private let titleTextField = UITextField()
    private let optionsTableView = UITableView(frame: .zero, style: .plain)
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)

    private var selectedSchedule: [WeekDay] = []

    private let options = ["Категория", "Расписание"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP White")
        title = "Новая привычка"
        navigationItem.hidesBackButton = true

        setupTextField()
        setupTableView()
        setupButtons()
        setupKeyboardDismiss()
        updateCreateButtonState()
    }

    // MARK: Вёрстка кодом

    private func setupTextField() {
        titleTextField.placeholder = "Введите название трекера"
        titleTextField.font = .systemFont(ofSize: 17)
        titleTextField.backgroundColor = UIColor(named: "YP Background")
        titleTextField.layer.cornerRadius = Layout.cornerRadius
        titleTextField.layer.masksToBounds = true
        titleTextField.delegate = self
        titleTextField.clearButtonMode = .whileEditing
        titleTextField.accessibilityIdentifier = "tracker title"
        titleTextField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        // Отступ текста от края поля.
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: Layout.sideInset, height: Layout.textFieldHeight))
        titleTextField.leftView = padding
        titleTextField.leftViewMode = .always

        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleTextField)
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.textFieldTopInset),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            titleTextField.heightAnchor.constraint(equalToConstant: Layout.textFieldHeight)
        ])
    }

    private func setupTableView() {
        optionsTableView.dataSource = self
        optionsTableView.delegate = self
        optionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
        optionsTableView.backgroundColor = UIColor(named: "YP Background")
        optionsTableView.layer.cornerRadius = Layout.cornerRadius
        optionsTableView.layer.masksToBounds = true
        optionsTableView.isScrollEnabled = false
        optionsTableView.separatorInset = UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
        optionsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(optionsTableView)
        NSLayoutConstraint.activate([
            optionsTableView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: Layout.tableTopInset),
            optionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            optionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            optionsTableView.heightAnchor.constraint(equalToConstant: Layout.rowHeight * CGFloat(options.count))
        ])
    }

    private func setupButtons() {
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(UIColor(named: "YP Red"), for: .normal)
        cancelButton.backgroundColor = UIColor(named: "YP White")
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(named: "YP Red")?.cgColor
        cancelButton.layer.cornerRadius = Layout.cornerRadius
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        cancelButton.accessibilityIdentifier = "cancel tracker"

        createButton.setTitle("Создать", for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        createButton.setTitleColor(UIColor(named: "YP White"), for: .normal)
        createButton.layer.cornerRadius = Layout.cornerRadius
        createButton.addTarget(self, action: #selector(didTapCreate), for: .touchUpInside)
        createButton.accessibilityIdentifier = "create tracker"

        let stack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = Layout.buttonSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset + 4),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(Layout.sideInset + 4)),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.buttonBottomInset),
            stack.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }

    /// Клавиатура перекрывает нижние кнопки, поэтому прячем её по тапу мимо поля.
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    // MARK: Состояние

    /// «Создать» доступна только когда есть название и выбран хотя бы один день.
    private func updateCreateButtonState() {
        let hasTitle = !(titleTextField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        let isEnabled = hasTitle && !selectedSchedule.isEmpty
        createButton.isEnabled = isEnabled
        createButton.backgroundColor = UIColor(named: isEnabled ? "YP Black" : "YP Gray")
    }

    private func scheduleSubtitle() -> String? {
        guard !selectedSchedule.isEmpty else { return nil }
        if selectedSchedule.count == WeekDay.allCases.count { return "Каждый день" }
        return WeekDay.displayOrder
            .filter { selectedSchedule.contains($0) }
            .map(\.shortName)
            .joined(separator: ", ")
    }

    // MARK: Действия

    @objc private func titleChanged() {
        updateCreateButtonState()
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapCreate() {
        let title = (titleTextField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, !selectedSchedule.isEmpty else { return }

        let colorName = Constants.colorNames.randomElement() ?? "YP Blue"
        let tracker = Tracker(
            id: UUID(),
            title: title,
            color: UIColor(named: colorName) ?? .systemBlue,
            emoji: Constants.emojis.randomElement() ?? "🙂",
            schedule: selectedSchedule
        )

        onCreate?(tracker)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension NewHabitViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = options[indexPath.row]
        configuration.textProperties.font = .systemFont(ofSize: 17)
        configuration.textProperties.color = UIColor(named: "YP Black") ?? .label

        // Под «Расписание» показываем выбранные дни.
        if indexPath.row == 1, let subtitle = scheduleSubtitle() {
            configuration.secondaryText = subtitle
            configuration.secondaryTextProperties.font = .systemFont(ofSize: 17)
            configuration.secondaryTextProperties.color = UIColor(named: "YP Gray") ?? .secondaryLabel
        }

        cell.contentConfiguration = configuration
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = options[indexPath.row]
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NewHabitViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        view.endEditing(true)

        // «Категория» по заданию спринта 14 не функционирует.
        guard indexPath.row == 1 else { return }

        let schedule = ScheduleViewController()
        schedule.selectedDays = selectedSchedule
        schedule.onDone = { [weak self] days in
            guard let self else { return }
            self.selectedSchedule = days
            self.optionsTableView.reloadData()
            self.updateCreateButtonState()
        }
        navigationController?.pushViewController(schedule, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension NewHabitViewController: UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let current = textField.text ?? ""
        guard let stringRange = Range(range, in: current) else { return false }
        let updated = current.replacingCharacters(in: stringRange, with: string)
        return updated.count <= Constants.titleLimit
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
