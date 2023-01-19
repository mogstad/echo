import UIKit

open class KeyboardLayoutGuide: UILayoutGuide {

  lazy var heightConstraint: NSLayoutConstraint = {
    return self.heightAnchor.constraint(equalToConstant: 0)
  }()

  weak override open var owningView: UIView? {
    didSet {
      self.setup()
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  internal func setup() {
    guard let owningView = self.owningView else {
      return
    }

    NSLayoutConstraint.activate([
      self.heightConstraint,
      self.leftAnchor.constraint(equalTo: owningView.leftAnchor),
      self.rightAnchor.constraint(equalTo: owningView.rightAnchor),
      self.bottomAnchor.constraint(equalTo: owningView.bottomAnchor),
    ])
  }

}
