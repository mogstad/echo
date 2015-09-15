import UIKit

struct KeyboardChange {

  let type: KeyboardChangeType
  let begin: CGRect
  let end: CGRect
  let animation: KeyboardAnimation?

  init?(notification: NSNotification) {
    if let userInfo = notification.userInfo,
      end = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
      begin = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue,
      type = KeyboardChangeType.fromNotificationName(notification.name) {

        self.type = type
        self.end = end.CGRectValue()
        self.begin = end.CGRectValue()
        self.animation = KeyboardAnimation(notification: notification)
    } else {
      return nil
    }
  }

  func belongsTo(responder: UIResponder) -> Bool {
    switch self.type {
    case .willHide, .willShow, .didShow:
      return responder.isFirstResponder()
    case .didHide:
      // Not exactly exact science, but a decent guess
      return responder.isFirstResponder() == false
    }
  }

}

extension KeyboardChange: CustomDebugStringConvertible {
  var debugDescription: String {
    return "<KeyboardChange end=\"\(self.end)\" type=\"\(self.type)\">"
  }
}
