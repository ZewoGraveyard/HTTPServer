#if os(Linux)

import XCTest
@testable import HTTPServerTestSuite

XCTMain([
    testCase(ExampleTests.allTests)
])

#endif
