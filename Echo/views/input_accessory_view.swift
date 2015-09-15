import UIKit

class InputAccessoryView: UIView {

  private weak var observerSuperview: UIView?

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.userInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.removeSuperviewObserver()
  }

  override func canBecomeFirstResponder() -> Bool {
    return true
  }

  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

    if keyPath == "center" {
      let userInfo: [NSObject: AnyObject] = [
        "frame": NSValue(CGRect: self.superview!.frame)
      ]
      NSNotificationCenter.defaultCenter().postNotificationName("InputAccessoryViewTracked", object: self, userInfo: userInfo)
    } else {
      super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }
  }

  override func willMoveToSuperview(newSuperview: UIView?) {
    self.removeSuperviewObserver()
    self.addSuperviewObserver(newSuperview)
    super.willMoveToSuperview(newSuperview)
  }

  // MARK: Private

  private func addSuperviewObserver(superview: UIView?) {
    self.removeSuperviewObserver()
    if let superview = superview {
      self.observerSuperview = superview
      superview.addObserver(self, forKeyPath: "center", options: .New, context: nil)
    }
  }

  private func removeSuperviewObserver() {
    self.observerSuperview?.removeObserver(self, forKeyPath: "center")
    self.observerSuperview = nil
  }

}
