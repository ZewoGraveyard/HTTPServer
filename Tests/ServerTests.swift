import XCTest
import HTTPServer

class ServerTests: XCTestCase {
    func testServer() {
        do {
            try Server { _ in Response(body: "Hello, World!") }.start()
        } catch {
            XCTFail("\(error)")
        }
    }
}
