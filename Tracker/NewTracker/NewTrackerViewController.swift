import UIKit

// MARK: - NewTrackerViewController

final class NewTrackerViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let textFieldHeight: CGFloat = 75
        static let textFieldTopInset: CGFloat = 24
        static let daysTopInset: CGFloat = 24
        static let daysToTextFieldSpacing: CGFloat = 40
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

    private enum SelectionSection: Int, CaseIterable {
        case emoji
        case color

        var title: String {
            switch self {
            case .emoji: "Emoji"
            case .color: "Цвет"
            }
        }
    }

    var onSave: ((Tracker, String) -> Void)?

    private let viewModel: NewTrackerViewModel

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let completedDaysLabel = UILabel()
    private let titleTextField = UITextField()
    private let optionsTableView = UITableView(frame: .zero, style: .plain)
    private lazy var selectionCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)

    private var optionViewModels: [NewTrackerOptionViewModel] = []

    init(viewModel: NewTrackerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        title = viewModel.screenTitle
        navigationItem.hidesBackButton = true
        optionViewModels = viewModel.optionViewModels

        setupButtons()
        setupScrollView()
        setupTextField()
        setupTableView()
        setupSelectionCollectionView()
        setupKeyboardDismiss()
        bind()
    }

    private func bind() {
        viewModel.onCreateAllowedStateChange = { [weak self] isAllowed in
            self?.setCreateButton(enabled: isAllowed)
        }
        viewModel.onOptionsChange = { [weak self] options in
            self?.optionViewModels = options
            self?.optionsTableView.reloadData()
        }
        viewModel.start()
    }

    private func setCreateButton(enabled: Bool) {
        createButton.isEnabled = enabled
        createButton.backgroundColor = UIColor(resource: enabled ? .ypBlack : .ypGray)
    }

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
        titleTextField.text = viewModel.initialTitle
        titleTextField.placeholder = "Введите название трекера"
        titleTextField.font = .systemFont(ofSize: 17)
        titleTextField.backgroundColor = UIColor(resource: .ypBackground)
        titleTextField.layer.cornerRadius = Layout.cornerRadius
        titleTextField.layer.masksToBounds = true
        titleTextField.delegate = self
        titleTextField.clearButtonMode = .whileEditing
        titleTextField.accessibilityIdentifier = AccessibilityIdentifiers.trackerTitleField
        titleTextField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: Layout.sideInset, height: Layout.textFieldHeight))
        titleTextField.leftView = padding
        titleTextField.leftViewMode = .always

        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleTextField)

        // при редактировании сверху счетчик дней, поле опускается под него
        let textFieldTop: NSLayoutConstraint
        if let daysText = viewModel.completedDaysText {
            completedDaysLabel.text = daysText
            completedDaysLabel.font = .systemFont(ofSize: 32, weight: .bold)
            completedDaysLabel.textColor = UIColor(resource: .ypBlack)
            completedDaysLabel.textAlignment = .center
            completedDaysLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(completedDaysLabel)
            NSLayoutConstraint.activate([
                completedDaysLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.daysTopInset),
                completedDaysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.sideInset),
                completedDaysLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.sideInset)
            ])
            textFieldTop = titleTextField.topAnchor.constraint(
                equalTo: completedDaysLabel.bottomAnchor,
                constant: Layout.daysToTextFieldSpacing
            )
        } else {
            textFieldTop = titleTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.textFieldTopInset)
        }

        NSLayoutConstraint.activate([
            textFieldTop,
            titleTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.sideInset),
            titleTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.sideInset),
            titleTextField.heightAnchor.constraint(equalToConstant: Layout.textFieldHeight)
        ])
    }

    private func setupTableView() {
        optionsTableView.dataSource = self
        optionsTableView.delegate = self
        optionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "OptionCell")
        optionsTableView.backgroundColor = UIColor(resource: .ypBackground)
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
            optionsTableView.heightAnchor.constraint(equalToConstant: Layout.rowHeight * CGFloat(viewModel.options.count))
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
        selectionCollectionView.accessibilityIdentifier = AccessibilityIdentifiers.selectionCollection
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

    // коллекция не скроллится, поэтому высоту считаю сам
    private func selectionCollectionHeight() -> CGFloat {
        SelectionSection.allCases.reduce(0) { height, section in
            let rows = (CGFloat(itemsCount(in: section)) / Layout.selectionItemsPerRow).rounded(.up)
            return height
                + Layout.selectionHeaderHeight
                + Layout.selectionSectionTopInset
                + rows * Layout.selectionItemSize
                + Layout.selectionSectionSpacing
        }
    }

    private func itemsCount(in section: SelectionSection) -> Int {
        switch section {
        case .emoji: viewModel.emojis.count
        case .color: viewModel.colors.count
        }
    }

    private func setupButtons() {
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(UIColor(resource: .ypRed), for: .normal)
        cancelButton.backgroundColor = UIColor(resource: .ypWhite)
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(resource: .ypRed).cgColor
        cancelButton.layer.cornerRadius = Layout.cornerRadius
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        cancelButton.accessibilityIdentifier = AccessibilityIdentifiers.cancelTrackerButton

        createButton.setTitle(viewModel.saveButtonTitle, for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        createButton.setTitleColor(UIColor(resource: .ypWhite), for: .normal)
        createButton.layer.cornerRadius = Layout.cornerRadius
        createButton.addTarget(self, action: #selector(didTapCreate), for: .touchUpInside)
        createButton.accessibilityIdentifier = AccessibilityIdentifiers.createTrackerButton

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

    // прячем клавиатуру по тапу мимо поля
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }

    @objc private func titleChanged() {
        viewModel.didChangeTitle(titleTextField.text ?? "")
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapCreate() {
        guard let result = viewModel.makeTracker() else { return }

        // добавляю после закрытия, чтобы алерт с ошибкой показался на главном экране
        let onSave = onSave
        dismiss(animated: true) {
            onSave?(result.tracker, result.categoryTitle)
        }
    }

    private func showCategories() {
        let categories = CategoryListViewController(viewModel: viewModel.makeCategoryListViewModel())
        navigationController?.pushViewController(categories, animated: true)
    }

    private func showSchedule() {
        let schedule = ScheduleViewController(viewModel: viewModel.makeScheduleViewModel())
        navigationController?.pushViewController(schedule, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension NewTrackerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        optionViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath)
        let option = optionViewModels[indexPath.row]

        var configuration = cell.defaultContentConfiguration()
        configuration.text = option.title
        configuration.textProperties.font = .systemFont(ofSize: 17)
        configuration.textProperties.color = UIColor(resource: .ypBlack)

        if let subtitle = option.subtitle {
            configuration.secondaryText = subtitle
            configuration.secondaryTextProperties.font = .systemFont(ofSize: 17)
            configuration.secondaryTextProperties.color = UIColor(resource: .ypGray)
        }

        cell.contentConfiguration = configuration
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = option.title

        // у последней строки разделитель не нужен
        let isLast = indexPath.row == optionViewModels.count - 1
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

        switch viewModel.options[indexPath.row] {
        case .category: showCategories()
        case .schedule: showSchedule()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension NewTrackerViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        SelectionSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        SelectionSection(rawValue: section).map(itemsCount) ?? 0
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
                emoji: viewModel.emojis[indexPath.item],
                isSelected: indexPath.item == viewModel.selectedEmojiIndex
            )
            return cell

        case .color:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColorCell.reuseIdentifier,
                for: indexPath
            ) as? ColorCell else { return UICollectionViewCell() }
            cell.configure(
                color: UIColor(resource: viewModel.colors[indexPath.item]),
                isSelected: indexPath.item == viewModel.selectedColorIndex,
                identifier: AccessibilityIdentifiers.colorCell(indexPath.item + 1)
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
        case .emoji: viewModel.didSelectEmoji(at: indexPath.item)
        case .color: viewModel.didSelectColor(at: indexPath.item)
        case nil: return
        }

        UIView.performWithoutAnimation {
            collectionView.reloadSections(IndexSet(integer: indexPath.section))
        }
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

    // 6 ячеек в ряд на любом экране
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
        return viewModel.canChangeTitle(to: current.replacingCharacters(in: stringRange, with: string))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
