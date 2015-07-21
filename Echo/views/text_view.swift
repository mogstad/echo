import UIKit

public class TextView: UITextView {

  private lazy var placeholderTextView: UITextView = {
    let textView = UITextView()
    textView.opaque = false
    textView.scrollEnabled = false
    textView.backgroundColor = UIColor.clearColor()
    textView.alpha = 0.2
    textView.editable = false
    textView.userInteractionEnabled = false
    return textView
  }()

  public var placeholderColor: UIColor {
    set {
      self.placeholderTextView.textColor = newValue
    }
    get {
      return self.placeholderTextView.textColor
    }
  }

  public var placeholder: String {
    set {
      self.placeholderTextView.text = newValue
    }
    get {
      return self.placeholderTextView.text
    }
  }

  override public var font: UIFont! {
    didSet {
      self.placeholderTextView.font = self.font
    }
  }

  override public var textContainerInset: UIEdgeInsets {
    didSet {
      self.placeholderTextView.textContainerInset = self.textContainerInset
    }
  }

  override public var contentInset: UIEdgeInsets {
    didSet {
      self.placeholderTextView.contentInset = self.contentInset
    }
  }

  override public var text: String! {
    didSet {
      self.configurePlaceholderTextViewVisibility()
    }
  }

  override public var attributedText: NSAttributedString! {
    didSet {
      self.configurePlaceholderTextViewVisibility()
    }
  }

  override public init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    self.setup()
  }

  required public init(coder: NSCoder) {
    super.init(coder: coder)
    self.setup()
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  // Remove the input accessory view right before resigning as first responder 
  // to make sure the keyboard animates to the correct location. Without this 
  // fix the keyboard animates the height of the input accessory view too far.
  public override func resignFirstResponder() -> Bool {
    self.inputAccessoryView = nil
    self.refreshInputViews()
    return super.resignFirstResponder()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    self.placeholderTextView.frame = self.bounds
  }

  // Private

  func textViewChanged(textView: UITextView) {
    self.configurePlaceholderTextViewVisibility()
  }

  private func configurePlaceholderTextViewVisibility() {
    self.placeholderTextView.hidden = count(self.text) == 0 ? false : true
  }

  private func setup() {
    self.addSubview(self.placeholderTextView)
    NSNotificationCenter.defaultCenter().addObserver(self,
      selector: "textViewChanged:",
      name: UITextViewTextDidChangeNotification,
      object: self)
  }

}
