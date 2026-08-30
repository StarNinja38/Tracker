import UIKit

// MARK: - OnboardingPageViewController

/// Одна страница онбординга: фон + заголовок.
/// ⚠️ Фоновая картинка из Figma не подключена — вместо неё сплошной цвет.
/// Положи ассеты в Assets.xcassets и передай их имена в `backgroundImageName`.
final class OnboardingPageViewController: UIViewController {

    private enum Layout {
        static let titleSideInset: CGFloat = 16
        static let titleBottomOffset: CGFloat = 270
    }

    private let titleLabel = UILabel()
    private let backgroundImageView = UIImageView()

    private let titleText: String
    private let placeholderColor: UIColor
    private let backgroundImageName: String?

    init(titleText: String, placeholderColor: UIColor, backgroundImageName: String? = nil) {
        self.titleText = titleText
        self.placeholderColor = placeholderColor
        self.backgroundImageName = backgroundImageName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupTitle()
    }

    private func setupBackground() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        if let backgroundImageName, let image = UIImage(named: backgroundImageName) {
            backgroundImageView.image = image
        } else {
            backgroundImageView.backgroundColor = placeholderColor
        }
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupTitle() {
        titleLabel.text = titleText
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = UIColor(named: "YP Black")
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.titleSideInset),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.titleSideInset),
            titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Layout.titleBottomOffset)
        ])
    }
}
