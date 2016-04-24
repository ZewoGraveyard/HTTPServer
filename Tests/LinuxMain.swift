#if os(Linux)

import XCTest
@testable import HTTPServerTestSuite

XCTMain([
    testCase(HTTPServerTests.allTests)
])

#endif
