import UIKit

// MARK: - CategoryFormViewController

/// Экран с полем для названия категории и кнопкой «Готово».
final class CategoryFormViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let textFieldHeight: CGFloat = 75
        static let textFieldTopInset: CGFloat = 24
        static let errorTopInset: CGFloat = 8
        static let cornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 60
        static let buttonSideInset: CGFloat = 20
        static let buttonBottomInset: CGFloat = 16
    }

    private let viewModel: CategoryFormViewModel

    private let titleTextField = UITextField()
    private let errorLabel = UILabel()
    private let doneButton = UIButton(type: .system)

    init(viewModel: CategoryFormViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP White")
        title = viewModel.screenTitle
        navigationItem.hidesBackButton = true

        setupTextField()
        setupErrorLabel()
        setupDoneButton()
        setupKeyboardDismiss()
        bind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleTextField.becomeFirstResponder()
    }

    // MARK: Байндинги

    private func bind() {
        viewModel.onDoneAllowedStateChange = { [weak self] isAllowed in
            self?.setDoneButton(enabled: isAllowed)
        }
        viewModel.onErrorStateChange = { [weak self] message in
            self?.errorLabel.text = message
            self?.errorLabel.isHidden = message == nil
        }
        viewModel.onFinish = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        viewModel.start()
    }

    private func setDoneButton(enabled: Bool) {
        doneButton.isEnabled = enabled
        doneButton.backgroundColor = UIColor(named: enabled ? "YP Black" : "YP Gray")
    }

    // MARK: Вёрстка кодом

    private func setupTextField() {
        titleTextField.text = viewModel.initialText
        titleTextField.placeholder = viewModel.placeholder
        titleTextField.font = .systemFont(ofSize: 17)
        titleTextField.backgroundColor = UIColor(named: "YP Background")
        titleTextField.layer.cornerRadius = Layout.cornerRadius
        titleTextField.layer.masksToBounds = true
        titleTextField.clearButtonMode = .whileEditing
        titleTextField.returnKeyType = .done
        titleTextField.delegate = self
        titleTextField.accessibilityIdentifier = "category title"
        titleTextField.addTarget(self, action: #selector(titleChanged), for: .editingChanged)

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

    private func setupErrorLabel() {
        errorLabel.font = .systemFont(ofSize: 17)
        errorLabel.textColor = UIColor(named: "YP Red")
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: Layout.errorTopInset),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset)
        ])
    }

    private func setupDoneButton() {
        doneButton.setTitle("Готово", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.setTitleColor(UIColor(named: "YP White"), for: .normal)
        doneButton.layer.cornerRadius = Layout.cornerRadius
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        doneButton.accessibilityIdentifier = "category done"
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.buttonSideInset),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.buttonSideInset),
            // Без клавиатуры гайд совпадает с низом safe area, с клавиатурой — поднимает кнопку над ней.
            doneButton.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -Layout.buttonBottomInset),
            doneButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    // MARK: Действия

    @objc private func titleChanged() {
        viewModel.didChangeTitle(titleTextField.text ?? "")
    }

    @objc private func didTapDone() {
        view.endEditing(true)
        viewModel.didTapDone()
    }

    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension CategoryFormViewController: UIGestureRecognizerDelegate {

    /// Тап по кнопке не должен прятать клавиатуру: «Готово» привязана к ней
    /// и уехала бы вниз раньше, чем палец отпустит кнопку.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        !(touch.view is UIControl)
    }
}

// MARK: - UITextFieldDelegate

extension CategoryFormViewController: UITextFieldDelegate {

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
