import UIKit

enum KeyboardChangeType {
  case willShow, willHide, didShow, didHide

  static func fromNotificationName(name: String) -> KeyboardChangeType? {
    switch name {
    case UIKeyboardDidHideNotification:
      return .didHide
    case UIKeyboardWillHideNotification:
      return .willHide
    case UIKeyboardDidShowNotification:
      return .didShow
    case UIKeyboardWillShowNotification:
      return .willShow
    default:
      return nil
    }
  }
}

extension KeyboardChangeType: DebugPrintable {
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
