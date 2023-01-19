import UIKit

public protocol InputAccessoryControllerDelegate: AnyObject {

  /// Called whenever the keyboard frame changes
  ///
  /// - parameter rect: input accessory view’s frame in the window coordinate system
  /// - parameter adjustContentOffset: indicates if the content offset should be
  ///   updated accordingly.
  /// - parameter animation: struct including details how to animated the change.
  func updateAccessoryView(_ rect: CGRect, adjustContentOffset: Bool, animation: KeyboardAnimation?)

}

/// Optional protocol to allow other responders to display the input accessory 
/// view
public protocol InputAccessoryControllerResponderDelegate: InputAccessoryControllerDelegate {

  func showAccessoryViewForResponder(_ responder: UIResponder) -> Bool

}

enum Status {
  case scrubbing(position: CGFloat, keyboardHeight: CGFloat)
  case visible(keyboardHeight: CGFloat)
  case hidden

  var keyboardHeight: CGFloat? {
    switch self {
    case let .scrubbing(_, keyboardHeight):
        return keyboardHeight
    case let .visible(keyboardHeight):
        return keyboardHeight
    default:
        return nil
    }
  }
}

/// InputAccessoryController coordinates the interaction between a scroll view
/// and an input accessory view. Setting a view as the responder’s 
/// `inputAccessoryView` has many problems, and results in hacks fragmented 
/// through out your code base. InputAccessoryController listens to keyboard 
/// notifications and your scroll views’s content offset to determine where the 
/// keyboard is located and tell you when it’s time to update your UI to make 
/// room for the keyboard and update the input accessory view.
open class InputAccessoryController: NSObject {

  let scrollView: UIScrollView
  let accessoryView: UIView
  let textView: UIResponder
  var status: Status = .hidden

  var panGestureRecognizer: UIPanGestureRecognizer!
  let behaviours: InputAccessoryControllerBehaviours
  open weak var delegate: InputAccessoryControllerDelegate?

  public let keyboardLayoutGuide = KeyboardLayoutGuide()

  public init(scrollView: UIScrollView, behaviours: InputAccessoryControllerBehaviours, accessoryView: UIView, textView: UIResponder) {
    self.scrollView = scrollView
    self.accessoryView = accessoryView
    self.textView = textView
    self.behaviours = behaviours
    super.init()
    self.panGestureRecognizer = UIPanGestureRecognizer(
      target: self,
      action: #selector(handlePanGestureRecognizer(recognizer:)))
    self.panGestureRecognizer.delegate = self
    self.scrollView.addGestureRecognizer(self.panGestureRecognizer)
    self.bindKeyboardNotifications()
    self.setupKeyboardLayoutGuide()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  public func setupKeyboardLayoutGuide() {
    self.accessoryView.superview?.addLayoutGuide(
      self.keyboardLayoutGuide)
  }

  // MARK: Private

  private func invoke(_ rect: CGRect, adjustContentOffset: Bool, animation: KeyboardAnimation?) {

    func keyboardHeight(view: UIView, rect: CGRect) -> CGFloat {
      let endFrame = view.convert(rect, from: nil)
      return max(0, view.bounds.height - endFrame.maxY - self.scrollView.safeAreaInsets.bottom)
    }

    self.delegate?.updateAccessoryView(rect,
                                       adjustContentOffset: adjustContentOffset,
                                       animation: animation)

    if let view = self.keyboardLayoutGuide.owningView {
      self.keyboardLayoutGuide.heightConstraint.constant = keyboardHeight(view: view, rect: rect)
      if let _ = animation {
        view.layoutIfNeeded()
      } else {
        view.layoutIfNeeded()
      }
    }

  }

  @objc func handlePanGestureRecognizer(recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {
    case .changed:
      guard
        let keyboardHeight = self.status.keyboardHeight,
        let view = recognizer.view,
        let window = view.window
        else {
          return
      }

      let location = recognizer.location(in: view)
      let absoluteLocation = view.convert(location, to: window)
      let y = max(absoluteLocation.y, window.bounds.height - keyboardHeight);
      let origin = CGPoint(
        x: 0,
        y: y - self.accessoryView.bounds.size.height
      )
      let inputAccessoryView = CGRect(
        origin: origin,
        size: self.accessoryView.bounds.size)

      self.status = .scrubbing(
        position: absoluteLocation.y,
        keyboardHeight: keyboardHeight)

      self.invoke(inputAccessoryView,
                  adjustContentOffset: false,
                  animation: nil)
    case .began, .ended:
      break
    default:
      break
    }

  }

  /// Notifications are a mess, dealing with userInfo is pita
  @objc func normalizeKeyboardNotification(_ notification: Notification) {
  if let keyboardNotification = KeyboardChange(notification: notification), self.validateKeyboardNotification(keyboardNotification) {
      guard let window = self.scrollView.window else { return }
      if keyboardNotification.type == .willShow {
        // Stop scrolling, prevents a layout glitch that only happens if the
        // scroll view is scrolling and the keyboard appears. Should probably
        // look into the root of the issue instead of working around it, but
        // this is good for now.
        self.scrollView.stopScrolling()
      }

    if keyboardNotification.type == .willHide {
      self.status = .hidden
    } else if keyboardNotification.type == .didShow {
      self.status = .visible(keyboardHeight: keyboardNotification.end.height)
    }

      if keyboardNotification.type == .willChangeFrame {
        let height = window.frame.height
        let origin: CGPoint
        var keyboardHeight = window.frame.height - keyboardNotification.end.origin.y
        keyboardHeight = min(keyboardHeight, keyboardNotification.end.height)
        origin = CGPoint(
          x: keyboardNotification.end.minX,
          y: height - keyboardHeight - self.accessoryView.bounds.height
        )

        let accessoryViewFrame = CGRect(
          origin: origin,
          size: self.accessoryView.bounds.size)

        if var animation = keyboardNotification.animation {
          if case let .scrubbing(value, _) = self.status {

            let delta = value - keyboardNotification.end.minY
            let fraction = delta / keyboardNotification.end.height

            animation = KeyboardAnimation(
              duration: animation.duration * TimeInterval(fraction),
              options: [.curveEaseInOut],
              delay: 0)
          }

          UIView.animate(withDuration: animation.duration,
            delay: animation.delay,
            options: animation.options,
            animations: {
              self.invoke(accessoryViewFrame,
                          adjustContentOffset: true,
                          animation: animation)
            },
            completion: nil)
        } else {
          self.invoke(accessoryViewFrame, adjustContentOffset: true, animation: nil)

        }
      }
    }
  }

  fileprivate func validateKeyboardNotification(_ keyboardChange: KeyboardChange) -> Bool {
    if let delegate = self.delegate as? InputAccessoryControllerResponderDelegate {
      if let firstResponser = UIResponder.currentFirstResponder() {
        return delegate.showAccessoryViewForResponder(firstResponser)
      }
      return false
    } else {
      return keyboardChange.belongsTo(responder: self.textView)
    }
  }

  fileprivate func bindKeyboardNotifications() {
    let notifications = [
      UIResponder.keyboardWillShowNotification,
      UIResponder.keyboardWillChangeFrameNotification,
      UIResponder.keyboardWillHideNotification,
      UIResponder.keyboardDidHideNotification,
      UIResponder.keyboardDidShowNotification,
    ]

    for notification in notifications {
      NotificationCenter.default.addObserver(self,
        selector: #selector(InputAccessoryController.normalizeKeyboardNotification(_:)),
        name: notification,
        object: nil)
    }
  }

}

extension InputAccessoryController: UIGestureRecognizerDelegate {

  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if case .visible(_) = self.status {
      return self.scrollView.keyboardDismissMode == .interactive
    }
    return false
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return true
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return gestureRecognizer === self.panGestureRecognizer
  }

}
