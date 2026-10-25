import UIKit

// MARK: - OnboardingPageViewController

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

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupTitle()
    }

    private func setupBackground() {
        backgroundImageView.image = UIImage(resource: page.backgroundImage)
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

    // текст всегда черный, фон у онбординга светлый в любой теме
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
