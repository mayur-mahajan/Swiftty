import XCTest
@testable import Swiftty
 
XCTMain([
    testCase(BufferTests.allTests),
    testCase(BootstrapTests.allTests),
])