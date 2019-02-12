import UIKit
import Echo

extension UIView {

  func showLayoutGuides() {
    // You sub may contain layout guides
    // so recursively add guides
    for sub in subviews {
      sub.showLayoutGuides()
    }

    guard let layoutGuides = self.layer.sublayers else {
      return
    }

    // Clear previous layers
    for layer in layoutGuides {
      if layer is LayoutGuideLayer {
        layer.removeFromSuperlayer()
      }
    }

    // Add new layers for guides
    for guide in self.layoutGuides {
      let layoutGuideLayer = LayoutGuideLayer(guide: guide)
      self.layer.addSublayer(layoutGuideLayer)
    }
  }

}

class LayoutGuideLayer: CAShapeLayer {

  init(guide:UILayoutGuide) {
    super.init()

    self.path = UIBezierPath(rect: guide.layoutFrame).cgPath
    self.lineWidth = 0.5
    self.lineDashPattern = [1, 1, 1, 1]
    self.fillColor = UIColor.clear.cgColor
    self.strokeColor = UIColor.red.cgColor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}


class LOL: UICollectionViewCell {
  let label: UILabel

  override init(frame: CGRect) {
    self.label = UILabel(frame: .zero)
    super.init(frame: frame)
    self.label.transform = CGAffineTransform(scaleX: 1, y: -1)
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
    self.collectionView.register(LOL.self, forCellWithReuseIdentifier: "LOL")
    self.collectionView.keyboardDismissMode = .interactive
    self.collectionView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)

    let hideKeyboard = UITapGestureRecognizer(target: self, action: #selector(ViewController.hideKeyboard(_:)))
    self.collectionView.addGestureRecognizer(hideKeyboard)
    self.automaticallyAdjustsScrollViewInsets = false

    let controller = InputAccessoryController(
      scrollView: self.collectionView,
      behaviours: [],
      accessoryView: self.accessoryView,
      textView: self.textView)

    self.accessoryView.bottomAnchor.constraint(equalTo: controller.keyboardLayoutGuide.topAnchor).isActive = true

    controller.delegate = self

    self.controller = controller
  }

  @objc func hideKeyboard(_ sender: UIGestureRecognizer) {
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.view.showLayoutGuides()
  }

  override func didReceiveMemoryWarning() {
    self.view.showLayoutGuides()
  }

}

extension ViewController: UICollectionViewDataSource {

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 300
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LOL", for: indexPath) as! LOL

    cell.backgroundColor = UIColor.red
    cell.label.text = "#\(indexPath.item)"
    return cell
  }

}

extension ViewController: InputAccessoryControllerResponderDelegate {
  func showAccessoryViewForResponder(_ responder: UIResponder) -> Bool {
    return true
  }
}

extension ViewController: InputAccessoryControllerDelegate {

  func updateAccessoryView(_ rect: CGRect, adjustContentOffset: Bool, animation: KeyboardAnimation?) {

//    let value = self.constraint.constant;
//    self.constraint.constant = self.keyboardHeight(rect)
//    var contentInset = self.collectionView.contentInset
//    contentInset.top = self.constraint.constant + self.accessoryView.bounds.height
//    contentInset.bottom = 80
//
//    var contentOffset = self.collectionView.contentOffset
//    contentOffset.y += self.collectionView.contentInset.top - contentInset.top
//
//    let offset: CGPoint? = adjustContentOffset ? contentOffset : nil
//
//    if let animation = animation {
//      let fraction = (260 - value) / 260;
//        UIView.animate(withDuration: 0.25 * TimeInterval(fraction),
//          delay: animation.delay,
//          options: [.curveEaseInOut],
//          animations: {
//            self.view.layoutIfNeeded()
//            self.update(contentInset, contentOffset: offset)
//          },
//          completion: nil)
//    } else {
//      self.update(contentInset, contentOffset: offset)
//    }
  }

  fileprivate func update(_ contentInset: UIEdgeInsets, contentOffset: CGPoint?) {
    if let contentOffset = contentOffset {
      self.collectionView.contentOffset = contentOffset
    }
    self.collectionView.contentInset = contentInset
    self.collectionView.scrollIndicatorInsets = contentInset
  }

  func keyboardHeight(_ rect: CGRect) -> CGFloat {
    let endFrame = self.view.convert(rect, from: nil)
    return max(0, self.view.bounds.height - endFrame.maxY)
  }

}

extension ViewController: UITextViewDelegate {

  func textViewDidChange(_ textView: UITextView) {
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
