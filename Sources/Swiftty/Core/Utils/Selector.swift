public protocol Selection {
    associatedtype T
    var next:T { get }
}

public struct RoundRobinIndexSelection: Selection {
    private var idx = AtomicInteger()
    private let count: Int
    
    public init(withCount: Int) {
        count = withCount
    }
    
    public var next: Int {
        let val: Int = idx.incrementAndGet() % self.count
        return abs(val)
    }
}

public struct RandomIndexSelection: Selection {
    private let count: Int
    
    public init(withCount: Int) {
        count = withCount
    }
    
    public var next: Int {
#if os(Linux)
        return Int(random() % (self.count))
#else
        return Int(arc4random_uniform(UInt32(self.count)))
#endif
    }

}
