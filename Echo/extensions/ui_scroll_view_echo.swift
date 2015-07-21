import UIKit

extension UIScrollView {

  func stopScrolling() {
    self.setContentOffset(self.contentOffset, animated: false)
  }

}
