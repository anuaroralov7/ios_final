import UIKit

final class CityTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel

        if #available(iOS 14.0, *) {
            var bg: UIBackgroundConfiguration
            if #available(iOS 18.0, *) {
                bg = UIBackgroundConfiguration.listCell()
            } else {
                bg = UIBackgroundConfiguration.listGroupedCell()
            }
            bg.backgroundColor = .secondarySystemGroupedBackground
            bg.cornerRadius = 12
            bg.backgroundInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
            backgroundConfiguration = bg
        } else {
            backgroundColor = .clear
            contentView.backgroundColor = .secondarySystemBackground
            contentView.layer.cornerRadius = 12
            contentView.layer.masksToBounds = true
        }

        selectionStyle = .default

        accessoryType = .none
        setupChevronAccessory()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if accessoryView == nil {
            setupChevronAccessory()
        }
    }

    private func setupChevronAccessory() {
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.contentMode = .scaleAspectFit
        chevron.tintColor = .tertiaryLabel
        chevron.frame = CGRect(x: 0, y: 0, width: 10, height: 16)
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        container.addSubview(chevron)
        chevron.center = CGPoint(x: container.bounds.midX + 2, y: container.bounds.midY)
        
        accessoryView = container
    }

    func configure(title: String, subtitle: String, icon: UIImage? = nil, iconColor: UIColor? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        
        if let icon, let iconImageView = iconImageView {
            iconImageView.image = icon
            iconImageView.tintColor = iconColor ?? .systemPink
            iconImageView.isHidden = false
        } else {
            iconImageView?.isHidden = true
        }
    }
}
