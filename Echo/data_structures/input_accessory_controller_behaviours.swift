import Foundation

/// InputAccessoryControllerBehaviours changes how the InputAccessoryController 
/// works, you should enable behaviours depending how you’ve setup your user 
/// interface.
///
/// ## List of Behaviours
///
/// ### adjustContentOffset
///
/// When enabled, the content offset will be adjusted while interactively
/// dismissing the keyboard. Usually only needed for inverted scrollViews, where
/// the scroll view gets resized to make room for the keyboard.
///
/// ### disableInteractiveDismissing
///
/// Enable when interactive dismissing is disabled, it allows us to do some 
/// optimizations, and allows the input accessory view to be visible when 
/// another responder is first responder.
///
public struct InputAccessoryControllerBehaviours: OptionSetType {

  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }

  public static let allZeros = InputAccessoryControllerBehaviours(rawValue: 0)
  public static let adjustContentOffset = InputAccessoryControllerBehaviours(rawValue: 0b1)
  public static let disableInteractiveDismissing = InputAccessoryControllerBehaviours(rawValue: 0b10)
}
