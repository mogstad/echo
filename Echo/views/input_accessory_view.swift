import UIKit

class InputAccessoryView: UIView {

  fileprivate weak var observerSuperview: UIView?

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.removeSuperviewObserver()
  }

  override var canBecomeFirstResponder : Bool {
    return true
  }

  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

    if keyPath == "center" {
      let userInfo: [AnyHashable: Any] = [
        "frame": NSValue(cgRect: self.superview!.frame)
      ]
      NotificationCenter.default.post(name: Notification.Name(rawValue: "InputAccessoryViewTracked"), object: self, userInfo: userInfo)
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }

  override func willMove(toSuperview newSuperview: UIView?) {
    self.removeSuperviewObserver()
    self.addSuperviewObserver(newSuperview)
    super.willMove(toSuperview: newSuperview)
  }

  // MARK: Private

  fileprivate func addSuperviewObserver(_ superview: UIView?) {
    self.removeSuperviewObserver()
    if let superview = superview {
      self.observerSuperview = superview
      superview.addObserver(self, forKeyPath: "center", options: .new, context: nil)
    }
  }

  fileprivate func removeSuperviewObserver() {
    self.observerSuperview?.removeObserver(self, forKeyPath: "center")
    self.observerSuperview = nil
  }

}
