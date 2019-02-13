import UIKit

class Yolo: UIView {
  @IBOutlet var composerView: ComposerView!
  override var intrinsicContentSize: CGSize {
    return CGSize(
      width: UIView.noIntrinsicMetric,
      height: self.composerView.intrinsicContentSize.height + self.layoutMargins.bottom)
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    let viewBottomAnchor = self.layoutMarginsGuide.bottomAnchor
    NSLayoutConstraint.activate([
//      self.heightConstraint,
//      self.leftAnchor.constraint(equalTo: owningView.leftAnchor),
//      self.rightAnchor.constraint(equalTo: owningView.rightAnchor),
      self.composerView.bottomAnchor.constraint(equalTo: viewBottomAnchor),
    ])

  }

}

class ComposerView: UIView {

  @IBOutlet var textView: UITextView!

  fileprivate let sizingTextView: UITextView = UITextView(frame: .zero)
  override var intrinsicContentSize: CGSize {

    self.sizingTextView.font = self.textView.font
    self.sizingTextView.text = self.textView.text
    self.sizingTextView.textContainerInset = self.textView.textContainerInset

    let textViewSize = self.sizingTextView.sizeThatFits(CGSize(width: self.textView.frame.width, height: .greatestFiniteMagnitude))

    return CGSize(
      width: UIView.noIntrinsicMetric,
      height: textViewSize.height)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    //self.textView.frame = self.bounds
  }

}
