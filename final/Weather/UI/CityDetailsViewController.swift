import UIKit

final class CityDetailsViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    @IBOutlet private weak var cityTitleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleTextField: UITextField!
    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var favoriteButton: UIButton!

    var city: City?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        titleTextField.delegate = self
        noteTextView.delegate = self

        noteTextView.layer.borderWidth = 1
        noteTextView.layer.borderColor = UIColor.separator.cgColor
        noteTextView.layer.cornerRadius = 10

        iconImageView.image = UIImage(systemName: "cloud.sun")
        iconImageView.tintColor = .systemBlue

        applyCity()
        updateFavoriteUI(isFavorite: false)
    }

    private func applyCity() {
        let name = city?.name ?? "City"
        cityTitleLabel.text = name
        title = name

        let parts = [city?.admin1, city?.country].compactMap { $0 }.filter { !$0.isEmpty }
        subtitleLabel.text = parts.joined(separator: ", ")
        subtitleLabel.isHidden = parts.isEmpty
    }

    private func updateFavoriteUI(isFavorite: Bool) {
        favoriteButton.setTitle(isFavorite ? "Remove from Favorites" : "Add to Favorites", for: .normal)
    }

    @IBAction private func favoriteTapped(_ sender: UIButton) {
        let isRemoving = (sender.title(for: .normal) ?? "").contains("Remove")
        updateFavoriteUI(isFavorite: !isRemoving)

        UIView.animate(withDuration: 0.15, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15) {
                sender.transform = .identity
            }
        })
    }

    @IBAction private func saveTapped(_ sender: UIButton) {
        view.endEditing(true)
        UIView.animate(withDuration: 0.2, animations: {
            sender.alpha = 0.6
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.alpha = 1
            }
        })
    }
}


