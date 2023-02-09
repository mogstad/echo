import Foundation
import UIKit

var DidNotResignFirstResponder = "didNotResignFirstResponder"

weak var firstResponder: UIResponder?

extension UIResponder {

  class func currentFirstResponder() -> UIResponder? {
    firstResponder = nil
    UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder),
      to: nil,
      from: nil,
      for: nil)

    return firstResponder
  }

  @objc func findFirstResponder() {
    firstResponder = self
  }

}
