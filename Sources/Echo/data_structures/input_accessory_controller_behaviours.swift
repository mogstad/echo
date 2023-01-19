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
public struct InputAccessoryControllerBehaviours: OptionSet {

  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }

    public static let allZeros = InputAccessoryControllerBehaviours([])
  public static let adjustContentOffset = InputAccessoryControllerBehaviours(rawValue: 0b1)
}
