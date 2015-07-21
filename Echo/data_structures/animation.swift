import UIKit

public struct KeyboardAnimation {
  
  public let duration: NSTimeInterval
  public let options: UIViewAnimationOptions
  public let delay: NSTimeInterval = 0
  
  init?(notification: NSNotification) {
    if let userInfo = notification.userInfo,
      curve = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber,
      duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {

        self.duration = duration.doubleValue == 0 ? 0.1 : duration.doubleValue
        self.options = UIViewAnimationOptions(rawValue: curve.unsignedLongValue == 0 ? 7 : curve.unsignedLongValue)

    } else {
      return nil
    }
  }

}
