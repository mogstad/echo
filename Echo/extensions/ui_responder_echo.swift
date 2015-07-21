import Foundation

var DidNotResignFirstResponder = "didNotResignFirstResponder"

weak var firstResponder: UIResponder?

extension UIResponder {

  class func currentFirstResponder() -> UIResponder? {
    firstResponder = nil
    UIApplication.sharedApplication().sendAction("findFirstResponder",
      to: nil,
      from: nil,
      forEvent: nil)

    return firstResponder
  }

  func findFirstResponder() {
    firstResponder = self
  }

  // To prevent an infinate loop, as we refresh the input accessory view in
  // keyboard notifications. Reloading input views generates new keyboard
  // notifications.
  func refreshInputViews() {
    if self.isFirstResponder() {
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
        UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    } get {
      if let didNotResignFirstResponder = objc_getAssociatedObject(self, &DidNotResignFirstResponder) as? NSNumber {
        return didNotResignFirstResponder.boolValue
      }
      return false
    }
  }

}
