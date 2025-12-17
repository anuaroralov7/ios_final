import UIKit

final class ShimmerView: UIView {
    private let gradient = CAGradientLayer()
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [0.0, 0.5, 1.0]
        layer.addSublayer(gradient)

        layer.cornerRadius = 10
        layer.masksToBounds = true

        updateColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    private func updateColors() {
        let base = UIColor.systemGray5.cgColor
        let highlight = UIColor.systemGray4.cgColor
        gradient.colors = [base, highlight, base]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds.insetBy(dx: -bounds.width, dy: 0)
        if isAnimating {
            startAnimating()
        }
    }

    func startAnimating() {
        isAnimating = true
        gradient.removeAnimation(forKey: "shimmer")

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width
        animation.duration = 1.2
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradient.add(animation, forKey: "shimmer")
    }

    func stopAnimating() {
        isAnimating = false
        gradient.removeAnimation(forKey: "shimmer")
    }
}
