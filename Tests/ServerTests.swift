import XCTest
import HTTPServer

class ServerTests: XCTestCase {
    func testServer() {
        do {
            try Server { _ in
                Response(
                    version: Version(major: 1, minor: 1),
                    status: .InternalServerError,
                    headers: ["Content-Length": "13"],
                    body: Drain("Hello, World!")
                )
            }.start()
        } catch {
            XCTFail("\(error)")
        }
    }
}
