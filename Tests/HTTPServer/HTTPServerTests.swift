import XCTest
@testable import HTTPServer

class HTTPServerTests: XCTestCase {
    func testReality() {
        XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
    }
}

extension HTTPServerTests {
    static var allTests : [(String, (HTTPServerTests) -> () throws -> Void)] {
        return [
           ("testReality", testReality),
        ]
    }
}
