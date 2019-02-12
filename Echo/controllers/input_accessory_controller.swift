import UIKit

public protocol InputAccessoryControllerDelegate: class {

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
  var keyboardHeight: CGFloat? = nil
  var keyboardVisible = false
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
    self.accessoryView.superview?.addLayoutGuide(self.keyboardLayoutGuide)

  }

  // MARK: Private

  private func invoke(_ rect: CGRect, adjustContentOffset: Bool, animation: KeyboardAnimation?) {

    func keyboardHeight(view: UIView, rect: CGRect) -> CGFloat {
      let endFrame = view.convert(rect, from: nil)
      return max(0, view.bounds.height - endFrame.maxY)
    }

    self.delegate?.updateAccessoryView(rect,
                                       adjustContentOffset: adjustContentOffset,
                                       animation: animation)




    if let view = self.keyboardLayoutGuide.owningView {
      print("Works \(keyboardHeight(view: view, rect: rect))")
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
        let view = recognizer.view,
        let window = view.window,
        let keyboardHeight = self.keyboardHeight
        else {
          print("View isn’t in the window")
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

      print("#handlePanGestureRecognizer")
      self.invoke(inputAccessoryView,
                  adjustContentOffset: false,
                  animation: nil)
    case .began, .ended:
//      self.scrollView.stopScrolling()
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
      self.keyboardVisible = false
    } else if keyboardNotification.type == .didShow {
      self.keyboardVisible = true
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

        let accessoryViewFrame = CGRect(origin: origin, size: self.accessoryView.bounds.size)
        self.invoke(accessoryViewFrame,
                    adjustContentOffset: true,
                    animation: keyboardNotification.animation
        )
      }

      if keyboardNotification.type == .willChangeFrame || keyboardNotification.type == .didChangeFrame {
        self.keyboardHeight = keyboardNotification.end.height
      }
    }
  }

  fileprivate func validateKeyboardNotification(_ keyboardChange: KeyboardChange) -> Bool {
    if let _ = self.delegate as? InputAccessoryControllerResponderDelegate {
      return (self.textView.didNotResignFirstResponder == false)
    } else {
      return (
        keyboardChange.belongsTo(self.textView) &&
        self.textView.didNotResignFirstResponder == false
      )
    }
  }

  fileprivate func bindKeyboardNotifications() {
    let notifications = [
      UIResponder.keyboardWillShowNotification,
      UIResponder.keyboardWillChangeFrameNotification,
      UIResponder.keyboardDidHideNotification,
      UIResponder.keyboardWillHideNotification,
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
  open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    print("self.keyboardVisible: \(self.keyboardVisible)")
    return self.scrollView.keyboardDismissMode == .interactive && self.keyboardVisible
  }

  /// Only recognice simultaneous gestures when its the `panGesture`
  open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return gestureRecognizer === self.panGestureRecognizer
  }

}
