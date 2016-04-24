import XCTest
@testable import HTTPServer

class ExampleTests: XCTestCase {
	func testReality() {
		XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
	}
}

extension ExampleTests {
    static var allTests : [(String, ExampleTests -> () throws -> Void)] {
        return [
           ("testReality", testReality),
        ]
    }
}