import UIKit

enum KeyboardChangeType {
  case willShow, willHide, didShow, didHide

  static func fromNotificationName(_ name: NSNotification.Name) -> KeyboardChangeType? {
    switch name {
    case NSNotification.Name.UIKeyboardDidHide:
      return .didHide
    case NSNotification.Name.UIKeyboardWillHide:
      return .willHide
    case NSNotification.Name.UIKeyboardDidShow:
      return .didShow
    case NSNotification.Name.UIKeyboardWillShow:
      return .willShow
    default:
      return nil
    }
  }
}

extension KeyboardChangeType: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .willHide:
      return "will hide"
    case .willShow:
      return "will show"
    case .didHide:
      return "did hide"
    case .didShow:
      return "did show"
    }
  }
}
