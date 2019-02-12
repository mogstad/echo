import UIKit

public struct KeyboardAnimation {
  
  public let duration: TimeInterval
  public let options: UIView.AnimationOptions
  public let delay: TimeInterval = 0

  init(duration: TimeInterval, options: UIView.AnimationOptions, delay: TimeInterval) {
    self.duration = duration
    self.options = options
  }

  init?(notification: Notification) {
    if let userInfo = notification.userInfo,
      let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber,
      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber {

        self.duration = duration.doubleValue == 0 ? 0.1 : duration.doubleValue
        self.options = UIView.AnimationOptions(rawValue: curve.uintValue == 0 ? 7 : curve.uintValue << 16)

    } else {
      return nil
    }
  }

}
