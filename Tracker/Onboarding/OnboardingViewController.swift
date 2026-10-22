import UIKit

// MARK: - OnboardingViewController

/// Онбординг из двух страниц: свайп между ними, `UIPageControl` и кнопка перехода в приложение.
final class OnboardingViewController: UIPageViewController {

    private enum Layout {
        static let buttonSideInset: CGFloat = 20
        static let buttonBottomInset: CGFloat = 50
        static let buttonHeight: CGFloat = 60
        static let buttonCornerRadius: CGFloat = 16
        static let pageControlBottomOffset: CGFloat = 24
    }

    /// Вызывается, когда пользователь закончил онбординг.
    var onFinish: (() -> Void)?

    private lazy var pages: [UIViewController] = [
        OnboardingPageViewController(
            titleText: "Отслеживайте только то, что хотите",
            placeholderColor: UIColor(named: "YP Blue") ?? .systemBlue,
            backgroundImageName: "onboarding_blue"
        ),
        OnboardingPageViewController(
            titleText: "Даже если это не литры воды и йога",
            placeholderColor: UIColor(named: "YP Red") ?? .systemRed,
            backgroundImageName: "onboarding_red"
        )
    ]

    private let pageControl = UIPageControl()
    private let actionButton = UIButton(type: .system)

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true)
        }

        setupPageControl()
        setupActionButton()
    }

    // MARK: Вёрстка кодом

    private func setupPageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = UIColor(named: "YP Black")
        pageControl.pageIndicatorTintColor = UIColor(named: "YP Black")?.withAlphaComponent(0.3)
        pageControl.isUserInteractionEnabled = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
    }

    private func setupActionButton() {
        actionButton.setTitle("Вот это технологии!", for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        actionButton.setTitleColor(UIColor(named: "YP White"), for: .normal)
        actionButton.backgroundColor = UIColor(named: "YP Black")
        actionButton.layer.cornerRadius = Layout.buttonCornerRadius
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.buttonSideInset),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.buttonSideInset),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.buttonBottomInset),
            actionButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -Layout.pageControlBottomOffset)
        ])
    }

    @objc private func didTapActionButton() {
        onFinish?()
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardingViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let previous = index - 1
        guard previous >= 0 else { return pages.last }   // зацикливаем, как в макете
        return pages[previous]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        let next = index + 1
        guard next < pages.count else { return pages.first }
        return pages[next]
    }
}

// MARK: - UIPageViewControllerDelegate

extension OnboardingViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard
            let current = viewControllers?.first,
            let index = pages.firstIndex(of: current)
        else { return }
        pageControl.currentPage = index
    }
}
