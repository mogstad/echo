import UIKit

open class TextView: UITextView {

  fileprivate lazy var placeholderTextView: UITextView = {
    let textView = UITextView()
    textView.isOpaque = false
    textView.isScrollEnabled = false
    textView.backgroundColor = UIColor.clear
    textView.alpha = 0.2
    textView.isEditable = false
    textView.isUserInteractionEnabled = false
    return textView
  }()

  open var placeholderColor: UIColor {
    set {
      self.placeholderTextView.textColor = newValue
    }
    get {
      return self.placeholderTextView.textColor!
    }
  }

  open var placeholder: String {
    set {
      self.placeholderTextView.text = newValue
    }
    get {
      return self.placeholderTextView.text
    }
  }

  override open var font: UIFont? {
    didSet {
      self.placeholderTextView.font = self.font
    }
  }

  override open var textContainerInset: UIEdgeInsets {
    didSet {
      self.placeholderTextView.textContainerInset = self.textContainerInset
    }
  }

  override open var contentInset: UIEdgeInsets {
    didSet {
      self.placeholderTextView.contentInset = self.contentInset
    }
  }

  override open var text: String! {
    didSet {
      self.configurePlaceholderTextViewVisibility()
    }
  }

  override open var attributedText: NSAttributedString! {
    didSet {
      self.configurePlaceholderTextViewVisibility()
    }
  }

  override public init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    self.setup()
  }

  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    self.setup()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    self.placeholderTextView.frame = self.bounds
  }

  // Private

  @objc func textViewChanged(_ textView: UITextView) {
    self.configurePlaceholderTextViewVisibility()
  }

  fileprivate func configurePlaceholderTextViewVisibility() {
    self.placeholderTextView.isHidden = self.text.count == 0 ? false : true
  }

  fileprivate func setup() {
    self.addSubview(self.placeholderTextView)
    NotificationCenter.default.addObserver(self,
      selector: #selector(TextView.textViewChanged(_:)),
      name: UITextView.textDidChangeNotification,
      object: self)
  }

}
