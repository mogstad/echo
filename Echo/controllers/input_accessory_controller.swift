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

  /// Notifications are a mess, dealing with userInfo is pita
  func normalizeKeyboardNotification(_ notification: Notification) {
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

          self.delegate?.updateAccessoryView(CGRect(origin: origin, size: self.accessoryView.bounds.size),
            adjustContentOffset: true,
            animation: keyboardNotification.animation)

        }

        // Important that this is called after the `updateAccessoryView` 
        // delegate callback, as the notification’s frame includes the accessory
        // view
        if keyboardNotification.type == .didHide || keyboardNotification.type == .didShow  {
          self.refreshInputViews()
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
      self.delegate?.updateAccessoryView(frame,
        adjustContentOffset: self.scrollView.isDragging == false,
        animation: nil)
    }
  }

  /// Gets called when the inputAccessoryView’s parent has a new frame, this
  /// usually means we’re interactively dismissing the keyboard, we therefor 
  /// need to update the UI, and compensate the scroll view’s `scrollOffset` if 
  /// the scroll view is inverted.
  func inputAccessoryViewTracked(_ notification: Notification) {
    if let userInfo = notification.userInfo, let end = userInfo["frame"] as? NSValue {
      let rect = end.cgRectValue

      let textViewInputAccesoryHeight = self.textView.inputAccessoryView?.bounds.height ?? 0
      let origin = CGPoint(
        x: rect.minX,
        y: rect.minY + textViewInputAccesoryHeight - self.accessoryView.bounds.height)

      let inputAccessoryView = CGRect(origin: origin, size: self.accessoryView.bounds.size)
      self.delegate?.updateAccessoryView(inputAccessoryView,
        adjustContentOffset: self.scrollView.isDragging == false,
        animation: nil)

      if self.scrollView.isDragging && self.behaviours.contains(.adjustContentOffset) {
        if self.movingKeyboard == false {
          self.movingKeyboard = true
        } else if let scrollViewOffsetBeforeDragging = self.scrollViewOffsetBeforeDragging {
          self.scrollView.contentOffset = scrollViewOffsetBeforeDragging
        }
      }
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
    NotificationCenter.default.addObserver(self,
      selector: #selector(InputAccessoryController.inputAccessoryViewTracked(_:)),
      name: NSNotification.Name(rawValue: "InputAccessoryViewTracked"),
      object: nil)

    let notifications = [
      NSNotification.Name.UIKeyboardWillShow,
      NSNotification.Name.UIKeyboardDidShow,
      NSNotification.Name.UIKeyboardWillHide,
      NSNotification.Name.UIKeyboardDidHide
    ]

    for notification in notifications {
      NotificationCenter.default.addObserver(self,
        selector: #selector(InputAccessoryController.normalizeKeyboardNotification(_:)),
        name: notification,
        object: nil)
    }
  }

}
