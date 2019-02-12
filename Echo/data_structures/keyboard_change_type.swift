import UIKit

enum KeyboardChangeType {
  case willShow, willHide, didShow, didHide, didChangeFrame, willChangeFrame

  static func fromNotificationName(_ name: NSNotification.Name) -> KeyboardChangeType? {
    switch name {
    case UIResponder.keyboardDidHideNotification:
      return .didHide
    case UIResponder.keyboardWillHideNotification:
      return .willHide
    case UIResponder.keyboardDidShowNotification:
      return .didShow
    case UIResponder.keyboardWillShowNotification:
      return .willShow
    case UIResponder.keyboardWillChangeFrameNotification:
      return .willChangeFrame
    case UIResponder.keyboardDidChangeFrameNotification:
      return .didChangeFrame
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
    case .willChangeFrame:
      return "will change frame"
    case .didChangeFrame:
      return "did change frame"
    }
  }
}
