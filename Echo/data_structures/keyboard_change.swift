import UIKit

struct KeyboardChange {

  let type: KeyboardChangeType
  let begin: CGRect
  let end: CGRect
  let animation: KeyboardAnimation?

  init?(notification: Notification) {
    if let userInfo = notification.userInfo,
      let end = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
      let begin = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue,
      let type = KeyboardChangeType.fromNotificationName(notification.name) {

        self.type = type
        self.end = end.cgRectValue
        self.begin = begin.cgRectValue
        self.animation = KeyboardAnimation(notification: notification)
    } else {
      return nil
    }
  }

  func belongsTo(_ responder: UIResponder) -> Bool {
    switch self.type {
    case .willHide, .willShow, .didShow:
      return responder.isFirstResponder
    case .didHide:
      // Not exactly exact science, but a decent guess
      return responder.isFirstResponder == false
    }
  }

}

extension KeyboardChange: CustomDebugStringConvertible {
  var debugDescription: String {
    return "<KeyboardChange end=\"\(self.end)\" type=\"\(self.type)\">"
  }
}
