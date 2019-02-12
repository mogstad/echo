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
  var keyboardHeight: CGFloat? = nil;
  var panGestureRecognizer: UIPanGestureRecognizer!
  let behaviours: InputAccessoryControllerBehaviours

  fileprivate var movingKeyboard: Bool = false {
    didSet {
      if self.movingKeyboard == false {
        self.scrollViewOffsetBeforeDragging = nil
      } else {
        self.scrollViewOffsetBeforeDragging = self.scrollView.contentOffset
      }
    }
  }
  
  fileprivate var scrollViewOffsetBeforeDragging: CGPoint?
  open weak var delegate: InputAccessoryControllerDelegate?

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
    self.addContentOffsetObserver()
    self.observeAccessoryBoundsChanges()
  }

  deinit {
    self.scrollView.removeObserver(self, forKeyPath: "contentOffset")
    self.accessoryView.layer.removeObserver(self, forKeyPath: "bounds")
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: Private

  fileprivate func createInputAccessoryView() {
    self.accessoryView.layoutIfNeeded()
    let input = InputAccessoryView(frame: self.accessoryView.bounds)
    if let textView = self.textView as? UITextView {
      textView.inputAccessoryView = input
    } else if let textField = self.textView as? UITextField {
      textField.inputAccessoryView = input
    }
  }

  fileprivate func updateMovingKeyboard() {
    self.movingKeyboard = self.scrollView.isDragging
  }

  @objc func handlePanGestureRecognizer(recognizer: UIPanGestureRecognizer) {
    guard
      recognizer.state == .changed,
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
    self.delegate?.updateAccessoryView(inputAccessoryView,
                                       adjustContentOffset: false,
                                       animation: nil)
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

        if keyboardNotification.type == .willHide || keyboardNotification.type == .willShow || keyboardNotification.type == .didHide {
          let height = window.frame.height
          let origin: CGPoint
          if keyboardNotification.type == .willShow {
            var keyboardHeight = window.frame.height - keyboardNotification.end.origin.y
            keyboardHeight = min(keyboardHeight, keyboardNotification.end.height)
            origin = CGPoint(
              x: keyboardNotification.end.minX,
              y: height - keyboardHeight - self.accessoryView.bounds.height)
          } else {
            origin = CGPoint(x: 0, y: window.frame.height)
          }

          print("#willHide #didHide #willShow: \(keyboardNotification.animation)")
          self.delegate?.updateAccessoryView(CGRect(origin: origin, size: self.accessoryView.bounds.size),
            adjustContentOffset: true,
            animation: keyboardNotification.animation)

        }

      if keyboardNotification.type == .willChangeFrame || keyboardNotification.type == .didChangeFrame {
        print("#didChangeFrame: \(keyboardNotification.animation)")
        self.keyboardHeight = keyboardNotification.end.height
      }

        // Important that this is called after the `updateAccessoryView` 
        // delegate callback, as the notification’s frame includes the accessory
        // view
        if keyboardNotification.type == .didHide || keyboardNotification.type == .didShow  {
          // self.refreshInputViews()
        }
        self.movingKeyboard = false
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

  /// Sets or resets the input accessory view depending on if the text view is
  /// first responder or not. We only want the inputAccessoryView if the text 
  /// view is first responder.
  fileprivate func refreshInputViews() {
    print("refresh input views")
    if self.behaviours.contains(.disableInteractiveDismissing) == false {
      if self.textView.isFirstResponder {
        self.createInputAccessoryView()
        self.textView.refreshInputViews()
      } else {
        self.estimateAccessoryView()
      }
    }
  }

  fileprivate func estimateAccessoryView() {
    if let window = self.accessoryView.window {
      let height = window.bounds.height
      let size = self.accessoryView.bounds.size
      let frame = CGRect(origin: CGPoint(x: 0, y: height - size.height), size: self.accessoryView.bounds.size)
      print("#estimateAccessoryView")
      self.delegate?.updateAccessoryView(frame,
        adjustContentOffset: self.scrollView.isDragging == false,
        animation: nil)
    }
  }

  /// Add KVO observer to our collection view, we need to keep track of the last
  /// scrolled position and if the scrolling happend because the user is 
  /// dragging.
  fileprivate func addContentOffsetObserver() {
    self.scrollView.addObserver(self, forKeyPath: "contentOffset", options: [], context: nil)
  }

  /// Add KVO observer to the accessory view to update the textView’s 
  /// placeholder accessory view to make sure the size is the same, to make sure
  /// the keyboard notifications has the correct frame.
  fileprivate func observeAccessoryBoundsChanges() {
    self.accessoryView.layer.addObserver(self, forKeyPath: "bounds", options: [.new, .old], context: nil)
  }

  open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    guard let keyPath = keyPath else { return }
    let object = object as! NSObject
    switch keyPath {
    case "contentOffset" where object == self.scrollView:
      if self.scrollView.isDragging == false {
        self.movingKeyboard = false
      }
    case "bounds" where object == self.accessoryView.layer:
      if self.behaviours.contains(.disableInteractiveDismissing) == false {
        self.refreshInputViews()
      } else if self.textView.isFirstResponder {
        let input = InputAccessoryView(frame: self.accessoryView.bounds)
        self.setInputAccessoryView(input)
        self.textView.refreshInputViews()
        self.setInputAccessoryView(nil)
        self.textView.refreshInputViews()
      } else {
        self.estimateAccessoryView()
      }
    default:
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }

  fileprivate func setInputAccessoryView(_ input: UIView?) {
    if let textView = self.textView as? UITextView {
      textView.inputAccessoryView = input
    } else if let textField = self.textView as? UITextField {
      textField.inputAccessoryView = input
    }
  }

  fileprivate func bindKeyboardNotifications() {
    let notifications = [
      UIResponder.keyboardWillShowNotification,
      UIResponder.keyboardDidShowNotification,
      UIResponder.keyboardWillHideNotification,
      UIResponder.keyboardDidHideNotification,
      UIResponder.keyboardWillChangeFrameNotification,
      UIResponder.keyboardDidChangeFrameNotification,
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
    return self.scrollView.keyboardDismissMode == .interactive
  }

  /// Only recognice simultaneous gestures when its the `panGesture`
  open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return gestureRecognizer === self.panGestureRecognizer
  }

}
