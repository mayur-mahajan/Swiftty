import XCTest
@testable import CoreTests
 
XCTMain([
    testCase(BufferTests.allTests),
    testCase(BootstrapTests.allTests),
])