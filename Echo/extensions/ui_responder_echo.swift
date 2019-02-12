import Foundation

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

  // To prevent an infinate loop, as we refresh the input accessory view in
  // keyboard notifications. Reloading input views generates new keyboard
  // notifications.
  func refreshInputViews() {
    if self.isFirstResponder {
      self.didNotResignFirstResponder = true
      self.reloadInputViews()
      self.didNotResignFirstResponder = false
    }
  }

  var didNotResignFirstResponder: Bool {
    set {
      objc_setAssociatedObject(self,
        &DidNotResignFirstResponder,
        newValue as NSNumber?,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    } get {
      if let didNotResignFirstResponder = objc_getAssociatedObject(self, &DidNotResignFirstResponder) as? NSNumber {
        return didNotResignFirstResponder.boolValue
      }
      return false
    }
  }

}
