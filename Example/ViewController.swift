import UIKit
import Echo

class LOL: UICollectionViewCell {
  let label: UILabel

  override init(frame: CGRect) {
    self.label = UILabel(frame: .zero)
    super.init(frame: frame)
    self.label.transform = CGAffineTransformMakeScale(1, -1)
    self.addSubview(self.label)
  }
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.label.frame = self.bounds
  }

}

class ViewController: UIViewController {

  @IBOutlet var textView: TextView!
  @IBOutlet var textField: UITextField!
  @IBOutlet var collectionView: UICollectionView!
  @IBOutlet var accessoryView: UIView!
  @IBOutlet var constraint: NSLayoutConstraint!
  
  var controller: InputAccessoryController?
  var secondController: InputAccessoryController?
  override func viewDidLoad() {
    super.viewDidLoad()

    self.collectionView.dataSource = self
    self.collectionView.registerClass(LOL.self, forCellWithReuseIdentifier: "LOL")
    self.collectionView.keyboardDismissMode = .Interactive
    self.collectionView.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0)

    let hideKeyboard = UITapGestureRecognizer(target: self, action: "hideKeyboard:")
    self.collectionView.addGestureRecognizer(hideKeyboard)
    self.automaticallyAdjustsScrollViewInsets = false
    
    let controller = InputAccessoryController(
      scrollView: self.collectionView,
      behaviours: [.disableInteractiveDismissing],
      accessoryView: self.accessoryView,
      textView: self.textView)

    controller.delegate = self

    self.controller = controller
  }

  func hideKeyboard(sender: UIGestureRecognizer) {
    self.textView.resignFirstResponder()
    self.textField.resignFirstResponder()
  }

}

extension ViewController: UICollectionViewDataSource {

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 300
  }

  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LOL", forIndexPath: indexPath) as! LOL

    cell.backgroundColor = UIColor.redColor()
    cell.label.text = "#\(indexPath.item)"
    return cell
  }

}

extension ViewController: InputAccessoryControllerResponderDelegate {
  func showAccessoryViewForResponder(responder: UIResponder) -> Bool {
    return true
  }
}

extension ViewController: InputAccessoryControllerDelegate {

  func updateAccessoryView(rect: CGRect, adjustContentOffset: Bool, animation: KeyboardAnimation?) {
    self.constraint.constant = self.keyboardHeight(rect)
    var contentInset = self.collectionView.contentInset
    contentInset.top = self.constraint.constant + self.accessoryView.bounds.height
    contentInset.bottom = 80

    var contentOffset = self.collectionView.contentOffset
    contentOffset.y += self.collectionView.contentInset.top - contentInset.top

    let offset: CGPoint? = adjustContentOffset ? contentOffset : nil

    if let animation = animation {
      UIView.animateWithDuration(animation.duration,
        delay: animation.delay,
        options: animation.options,
        animations: {
          self.update(contentInset, contentOffset: offset)
          self.view.layoutIfNeeded()
        },
        completion: nil)
    } else {
      self.update(contentInset, contentOffset: offset)
    }
  }

  private func update(contentInset: UIEdgeInsets, contentOffset: CGPoint?) {
    if let contentOffset = contentOffset {
      self.collectionView.contentOffset = contentOffset
    }
    self.collectionView.contentInset = contentInset
    self.collectionView.scrollIndicatorInsets = contentInset
  }

  func keyboardHeight(rect: CGRect) -> CGFloat {
    let endFrame = self.view.convertRect(rect, fromView: nil)
    return max(0, self.view.bounds.height - endFrame.maxY)
  }

}

extension ViewController: UITextViewDelegate {

  func textViewDidChange(textView: UITextView) {
    self.accessoryView.invalidateIntrinsicContentSize()
    self.accessoryView.layoutIfNeeded()

    // This works around the content being scrolled beyond the bottom.

    let endRange = NSRange(
      location: textView.text.characters.count,
      length: 0)
    
    if NSEqualRanges(textView.selectedRange, endRange) == true {
      let bottom = CGPoint(x: 0, y: textView.contentSize.height - textView.frame.size.height)
      textView.setContentOffset(bottom, animated: false)
    }
  }

}