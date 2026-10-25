import UIKit

// MARK: - OnboardingViewController

final class OnboardingViewController: UIPageViewController {

    private enum Layout {
        static let buttonSideInset: CGFloat = 20
        static let buttonBottomInset: CGFloat = 50
        static let buttonHeight: CGFloat = 60
        static let buttonCornerRadius: CGFloat = 16
        static let pageControlBottomOffset: CGFloat = 24
    }

    private let viewModel: OnboardingViewModel

    private lazy var pages: [UIViewController] = viewModel.pages.map { OnboardingPageViewController(page: $0) }

    private let pageControl = UIPageControl()
    private let actionButton = UIButton(type: .system)

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
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
        bind()
    }

    private func bind() {
        viewModel.onPageChange = { [weak self] index in
            self?.pageControl.currentPage = index
        }
    }

    private func setupPageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.3)
        pageControl.isUserInteractionEnabled = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
    }

    private func setupActionButton() {
        actionButton.setTitle(viewModel.buttonTitle, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = .black
        actionButton.layer.cornerRadius = Layout.buttonCornerRadius
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        actionButton.accessibilityIdentifier = "onboarding finish"
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
        viewModel.didTapFinish()
    }
}

// MARK: - UIPageViewControllerDataSource

extension OnboardingViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        return pages[viewModel.indexBefore(index)]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        return pages[viewModel.indexAfter(index)]
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
            completed,
            let current = viewControllers?.first,
            let index = pages.firstIndex(of: current)
        else { return }
        viewModel.didShowPage(at: index)
    }
}
