import UIKit

// MARK: - StatisticsViewController

final class StatisticsViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let topInset: CGFloat = 77
        static let cardHeight: CGFloat = 90
        static let cardSpacing: CGFloat = 12
        static let placeholderImageSize: CGFloat = 80
        static let placeholderSpacing: CGFloat = 8
    }

    private let viewModel: StatisticsViewModel

    private let stackView = UIStackView()
    private let placeholderImageView = UIImageView()
    private let placeholderLabel = UILabel()

    init(viewModel: StatisticsViewModel = StatisticsViewModel()) {
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
        title = NSLocalizedString("statistics.title", comment: "")
        navigationController?.navigationBar.prefersLargeTitles = true

        setupStackView()
        setupPlaceholder()
        bind()
        viewModel.loadData()
    }

    private func bind() {
        viewModel.onItemsChange = { [weak self] items in
            self?.show(items)
        }
    }

    private func show(_ items: [StatisticsItem]?) {
        let isEmpty = items == nil
        placeholderImageView.isHidden = !isEmpty
        placeholderLabel.isHidden = !isEmpty
        stackView.isHidden = isEmpty

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        items?.forEach { item in
            let card = StatisticsCardView()
            card.configure(with: item)
            card.heightAnchor.constraint(equalToConstant: Layout.cardHeight).isActive = true
            stackView.addArrangedSubview(card)
        }
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = Layout.cardSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.topInset),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset)
        ])
    }

    private func setupPlaceholder() {
        placeholderImageView.image = UIImage(resource: .placeholderStatistics)
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderImageView)

        placeholderLabel.text = NSLocalizedString("statistics.empty", comment: "")
        placeholderLabel.font = .systemFont(ofSize: 12, weight: .medium)
        placeholderLabel.textColor = UIColor(resource: .ypBlack)
        placeholderLabel.textAlignment = .center
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            placeholderImageView.widthAnchor.constraint(equalToConstant: Layout.placeholderImageSize),
            placeholderImageView.heightAnchor.constraint(equalToConstant: Layout.placeholderImageSize),

            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor, constant: Layout.placeholderSpacing)
        ])
    }
}
