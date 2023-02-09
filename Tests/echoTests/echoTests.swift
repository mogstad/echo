import XCTest
@testable import echo

final class echoTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(echo().text, "Hello, World!")
    }
}
