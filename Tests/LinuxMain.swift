import XCTest
@testable import SwifttyTests
 
XCTMain([
    testCase(BufferTests.allTests),
    testCase(BootstrapTests.allTests),
])