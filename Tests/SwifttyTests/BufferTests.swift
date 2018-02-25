import XCTest
@testable import Swiftty

class BufferTests: XCTestCase {
    static var allTests : [(String, (BufferTests) -> () throws -> Void)] {
        return [
            ("testEmptyBuffer", testEmptyBuffer),
            ("testFixedBufferFromArray", testFixedBufferFromArray),
        ]
    }

    func testEmptyBuffer() {
        let buf: Buffer = DirectBuffer()
        
        XCTAssertEqual(buf.isReadable, false, "Buffer is readable")
        XCTAssertEqual(buf.isWriteable, true, "Buffer is not writeable")
    }
    
    func testFixedBufferFromArray() {
        let array = [Byte]("test string".utf8)
        let buf: Buffer = DirectBuffer(from: array)
        
        XCTAssertEqual(buf.isReadable, true, "Buffer is not readable")
        XCTAssertEqual(buf.isWriteable, false, "Buffer is writeable")
    }
}
