import UIKit

public struct KeyboardAnimation {
  
  public let duration: TimeInterval
  public let options: UIViewAnimationOptions
  public let delay: TimeInterval = 0
  
  init?(notification: Notification) {
    if let userInfo = notification.userInfo,
      let curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
      let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {

        self.duration = duration.doubleValue == 0 ? 0.1 : duration.doubleValue
        self.options = UIViewAnimationOptions(rawValue: curve.uintValue == 0 ? 7 : curve.uintValue)

    } else {
      return nil
    }
  }

}
