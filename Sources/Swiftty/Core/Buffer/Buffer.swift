public protocol Buffer {
    var readableBytes: Int { get }
    var capacity: Int { get set }
    var readerIndex: Int { get set }
    var writerIndex: Int { get set }
}

public extension Buffer {
    var isReadable: Bool {
        return self.readableBytes > 0
    }
    
    var isWriteable: Bool {
        return self.writeableBytes > 0
    }
    
    var readableBytes: Int {
        return self.writerIndex - self.readerIndex
    }
    
    var writeableBytes: Int {
        return self.capacity - self.writerIndex
    }
    
    mutating func clear() {
        self.readerIndex = 0
        self.writerIndex = 0
    }
}
