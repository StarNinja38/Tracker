import UIKit

// MARK: - OnboardingPageViewController

/// Одна страница онбординга: фон на весь экран и заголовок.
final class OnboardingPageViewController: UIViewController {

    private enum Layout {
        static let titleSideInset: CGFloat = 16
        static let titleBottomOffset: CGFloat = 270
    }

    private let titleLabel = UILabel()
    private let backgroundImageView = UIImageView()

    private let page: OnboardingPage

    init(page: OnboardingPage) {
        self.page = page
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
        backgroundImageView.image = UIImage(named: page.backgroundImageName)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Заголовок чёрный в обеих темах: фон-картинка всегда светлая.
    private func setupTitle() {
        titleLabel.text = page.title
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .black
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
