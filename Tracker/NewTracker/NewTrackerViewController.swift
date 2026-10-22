import UIKit

// MARK: - NewTrackerViewController

/// Создание привычки или нерегулярного события. У события нет раздела
/// «Расписание», в остальном экраны одинаковые. Кнопка «Категория» по заданию
/// спринта 15 есть, но экран категорий появится в следующем спринте.
final class NewTrackerViewController: UIViewController {

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

        static let selectionTopInset: CGFloat = 32
        static let selectionSideInset: CGFloat = 18
        static let selectionItemSize: CGFloat = 52
        static let selectionItemsPerRow: CGFloat = 6
        static let selectionHeaderHeight: CGFloat = 34
        static let selectionSectionTopInset: CGFloat = 12
        static let selectionSectionSpacing: CGFloat = 16
        static let contentBottomInset: CGFloat = 16
    }

    private enum Constants {
        static let titleLimit = 38
        /// 18 эмодзи и 18 цветов из макета Figma.
        static let emojis = [
            "🙂", "😻", "🌺", "🐶", "❤️", "😱",
            "😇", "😡", "🥶", "🤔", "🙌", "🍔",
            "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
        ]
        static let colorNames = (1...18).map { "Color selection \($0)" }
    }

    /// Секции сетки выбора: эмодзи сверху, цвета под ними.
    private enum SelectionSection: Int, CaseIterable {
        case emoji
        case color

        var title: String {
            switch self {
            case .emoji: return "Emoji"
            case .color: return "Цвет"
            }
        }

        var itemsCount: Int {
            switch self {
            case .emoji: return Constants.emojis.count
            case .color: return Constants.colorNames.count
            }
        }
    }

    /// Отдаёт созданный трекер главному экрану.
    var onCreate: ((Tracker) -> Void)?

    private let type: TrackerType

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleTextField = UITextField()
    private let optionsTableView = UITableView(frame: .zero, style: .plain)
    private lazy var selectionCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)

    private var selectedSchedule: [WeekDay] = []
    private var selectedEmojiIndex: Int?
    private var selectedColorIndex: Int?

    private var options: [String] {
        switch type {
        case .habit: return ["Категория", "Расписание"]
        case .irregularEvent: return ["Категория"]
        }
    }

    init(type: TrackerType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP White")
        title = type.screenTitle
        navigationItem.hidesBackButton = true

        setupButtons()
        setupScrollView()
        setupTextField()
        setupTableView()
        setupSelectionCollectionView()
        setupKeyboardDismiss()
        updateCreateButtonState()
    }

    // MARK: Вёрстка кодом

    /// Кнопки прибиты к низу экрана, всё остальное прокручивается над ними.
    private func setupScrollView() {
        scrollView.keyboardDismissMode = .onDrag
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -Layout.buttonBottomInset),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

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
        contentView.addSubview(titleTextField)
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.textFieldTopInset),
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.sideInset),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.sideInset),
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
        contentView.addSubview(optionsTableView)
        NSLayoutConstraint.activate([
            optionsTableView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: Layout.tableTopInset),
            optionsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.sideInset),
            optionsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.sideInset),
            optionsTableView.heightAnchor.constraint(equalToConstant: Layout.rowHeight * CGFloat(options.count))
        ])
    }

    private func setupSelectionCollectionView() {
        selectionCollectionView.backgroundColor = .clear
        selectionCollectionView.isScrollEnabled = false
        selectionCollectionView.dataSource = self
        selectionCollectionView.delegate = self
        selectionCollectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseIdentifier)
        selectionCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseIdentifier)
        selectionCollectionView.register(
            TrackerCategoryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier
        )
        selectionCollectionView.accessibilityIdentifier = "selection collection"
        selectionCollectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectionCollectionView)
        NSLayoutConstraint.activate([
            selectionCollectionView.topAnchor.constraint(equalTo: optionsTableView.bottomAnchor, constant: Layout.selectionTopInset),
            selectionCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionCollectionView.heightAnchor.constraint(equalToConstant: selectionCollectionHeight()),
            selectionCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.contentBottomInset)
        ])
    }

    /// Сетка не прокручивается сама, поэтому её высота считается заранее:
    /// заголовок, отступ и ряды по шесть ячеек в каждой секции.
    private func selectionCollectionHeight() -> CGFloat {
        SelectionSection.allCases.reduce(0) { height, section in
            let rows = (CGFloat(section.itemsCount) / Layout.selectionItemsPerRow).rounded(.up)
            return height
                + Layout.selectionHeaderHeight
                + Layout.selectionSectionTopInset
                + rows * Layout.selectionItemSize
                + Layout.selectionSectionSpacing
        }
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

    /// «Создать» доступна, когда заполнены все разделы: название, эмодзи, цвет
    /// и — только у привычки — хотя бы один день расписания.
    private func updateCreateButtonState() {
        let hasTitle = !(titleTextField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        let hasSchedule = type == .irregularEvent || !selectedSchedule.isEmpty
        let isEnabled = hasTitle && hasSchedule && selectedEmojiIndex != nil && selectedColorIndex != nil
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
        guard
            !title.isEmpty,
            let emojiIndex = selectedEmojiIndex,
            let colorIndex = selectedColorIndex,
            let color = UIColor(named: Constants.colorNames[colorIndex])
        else { return }

        // Пустое расписание — признак нерегулярного события.
        let schedule = type == .habit ? selectedSchedule : []
        guard type == .irregularEvent || !schedule.isEmpty else { return }

        let tracker = Tracker(
            id: UUID(),
            title: title,
            color: color,
            emoji: Constants.emojis[emojiIndex],
            schedule: schedule
        )

        // Трекер уходит на главный экран после закрытия шторки: если сохранение
        // не удастся, алерт об ошибке будет показан уже поверх главного экрана.
        let onCreate = onCreate
        dismiss(animated: true) {
            onCreate?(tracker)
        }
    }
}

// MARK: - UITableViewDataSource

extension NewTrackerViewController: UITableViewDataSource {

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

        // У последней строки разделитель не нужен — под ней скругление.
        let isLast = indexPath.row == options.count - 1
        cell.separatorInset = isLast
            ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: tableView.bounds.width)
            : UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension NewTrackerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        view.endEditing(true)

        // «Категория» по заданию спринта 15 ещё не открывает экран.
        guard type == .habit, indexPath.row == 1 else { return }

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

// MARK: - UICollectionViewDataSource

extension NewTrackerViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        SelectionSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        SelectionSection(rawValue: section)?.itemsCount ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch SelectionSection(rawValue: indexPath.section) {
        case .emoji:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmojiCell.reuseIdentifier,
                for: indexPath
            ) as? EmojiCell else { return UICollectionViewCell() }
            cell.configure(
                emoji: Constants.emojis[indexPath.item],
                isSelected: indexPath.item == selectedEmojiIndex
            )
            return cell

        case .color:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColorCell.reuseIdentifier,
                for: indexPath
            ) as? ColorCell else { return UICollectionViewCell() }
            let colorName = Constants.colorNames[indexPath.item]
            cell.configure(
                color: UIColor(named: colorName) ?? .systemBlue,
                isSelected: indexPath.item == selectedColorIndex,
                identifier: colorName
            )
            return cell

        case nil:
            return UICollectionViewCell()
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard
            kind == UICollectionView.elementKindSectionHeader,
            let section = SelectionSection(rawValue: indexPath.section),
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier,
                for: indexPath
            ) as? TrackerCategoryHeaderView
        else {
            return UICollectionReusableView()
        }
        header.configure(title: section.title)
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NewTrackerViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        view.endEditing(true)

        switch SelectionSection(rawValue: indexPath.section) {
        case .emoji: selectedEmojiIndex = indexPath.item
        case .color: selectedColorIndex = indexPath.item
        case nil: return
        }

        UIView.performWithoutAnimation {
            collectionView.reloadSections(IndexSet(integer: indexPath.section))
        }
        updateCreateButtonState()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: Layout.selectionItemSize, height: Layout.selectionItemSize)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: Layout.selectionSectionTopInset,
            left: Layout.selectionSideInset,
            bottom: Layout.selectionSectionSpacing,
            right: Layout.selectionSideInset
        )
    }

    /// Шесть ячеек в ряд на любой ширине экрана: свободное место делится между промежутками.
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        let itemsWidth = Layout.selectionItemSize * Layout.selectionItemsPerRow
        let freeWidth = collectionView.bounds.width - Layout.selectionSideInset * 2 - itemsWidth
        return max(0, (freeWidth / (Layout.selectionItemsPerRow - 1)).rounded(.down))
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.selectionHeaderHeight)
    }
}

// MARK: - UITextFieldDelegate

extension NewTrackerViewController: UITextFieldDelegate {

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
