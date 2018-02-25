import Foundation
import Dispatch

public class CountdownLatch {
    private let queue = DispatchQueue(label: "CountdownLatchQueue")
    let semaphore: DispatchSemaphore
    
    public init(count: Int) {
        semaphore = DispatchSemaphore(value: count)
    }
    
    public func countdown() {
        queue.async {
            self.semaphore.signal()
        }
    }
    
    public func await() {
        _ = semaphore.wait(timeout: .distantFuture)
    }
}
