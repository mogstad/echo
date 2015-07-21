import UIKit

class ComposerView: UIView {

  @IBOutlet var textView: UITextView!

  private let sizingTextView: UITextView = UITextView(frame: .zeroRect)
  override func intrinsicContentSize() -> CGSize {

    self.sizingTextView.font = self.textView.font
    self.sizingTextView.text = self.textView.text
    self.sizingTextView.textContainerInset = self.textView.textContainerInset

    let textViewSize = self.sizingTextView.sizeThatFits(CGSize(width: self.textView.frame.width, height: .max))

    return CGSize(width: UIViewNoIntrinsicMetric, height: textViewSize.height)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    //self.textView.frame = self.bounds
  }

}
