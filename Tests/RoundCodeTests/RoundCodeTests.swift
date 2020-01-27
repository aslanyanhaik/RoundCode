import XCTest
@testable import RoundCode

final class RoundCodeTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(RoundCode().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
