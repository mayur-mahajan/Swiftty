import Foundation

public class DirectBuffer: Buffer {
    private var data = [Byte]()
    
    public init() {
        self.data.reserveCapacity(32)
    }
    
    public init(from: [Byte]) {
        self.data = from
        self.readerIndex = 0
        self.writerIndex = from.capacity
    }

    public var readerIndex: Int = 0 {
        didSet {
            if readerIndex < 0 || readerIndex > self.writerIndex {
                fatalError("Attempted to set reader index beyond bounds")
            }
        }
    }

    public var writerIndex: Int = 0 {
        didSet {
            if writerIndex < self.readerIndex || writerIndex > self.capacity {
                fatalError("Attempted to set writer index beyond bounds")
            }
        }
    }

    private var markedReaderIndex: Int?
    private var markedWriterIndex: Int?
    
    public var capacity: Int {
        get {
            return data.capacity
        }
        set {
            data.reserveCapacity(newValue)
        }
    }

}
