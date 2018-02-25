import Foundation
import Dispatch

class QueueHolder: Selection {
    private let count: Int
    private var queues: [DispatchQueue]
    private let queueSelector: RoundRobinIndexSelection
    
    init(withCount: Int) {
        count = withCount
        queueSelector = RoundRobinIndexSelection(withCount: count)
        queues = [DispatchQueue]()
        queues.reserveCapacity(withCount)
        for i in 0..<withCount {
            queues.append(DispatchQueue(label: "bootstrap-io-\(i)"))
        }
    }
    
    init(withQueues: [DispatchQueue]) {
        count = withQueues.count
        queueSelector = RoundRobinIndexSelection(withCount: count)
        queues = withQueues
    }
    
    public var next: DispatchQueue {
        return queues[queueSelector.next]
    }
    
}

public class ClientBootstrap {
    private var queueHolder: QueueHolder?
    
    public func withQueues(_ queues: [DispatchQueue]) -> ClientBootstrap {
        if queueHolder == nil {
            queueHolder = QueueHolder(withQueues: queues)
        }
        return self
    }
    
    public func withNumQueues(_ num: Int) -> ClientBootstrap {
        if queueHolder == nil {
            queueHolder = QueueHolder(withCount: num)
        }
        return self
    }
    
}

public class ServerBootstrap {
    private var queueHolder: QueueHolder?
    private var childInitializer: ((Channel) -> Void)?
    private var channelFactory: (() throws -> Channel)?
    private let acceptQueue = DispatchQueue(label: "bootstrap-accept")
    
    public init() {}

    public func queues(_ queues: [DispatchQueue]) -> ServerBootstrap {
        if queueHolder == nil {
            queueHolder = QueueHolder(withQueues: queues)
        }
        return self
    }
    
    public func numQueues(_ num: Int) -> ServerBootstrap {
        if queueHolder == nil {
            queueHolder = QueueHolder(withCount: num)
        }
        return self
    }
    
    public func channelFactory(_ factory: @escaping (() throws -> Channel)) -> ServerBootstrap {
        channelFactory = factory
        return self
    }
    
    public func childInitializer(_ initializer: @escaping ((Channel) -> Void)) -> ServerBootstrap {
        childInitializer = initializer
        return self
    }
    
    public func bind(toAddress: Address, completion: @escaping ChannelCompletion) {
        do {
            guard let channel = try channelFactory?() else {
                completion(nil, ChannelError.bindFailure("missing channel factory"))
                return
            }

            channel.register(withQueue: acceptQueue)
            let acceptor = ServerBootstrapAcceptor(self.queueHolder!, initializer: self.childInitializer)
            _ = channel.pipeline?.add(last: acceptor)
            channel.bind(at: toAddress, onComplete: completion)
        }
        catch {
            completion(nil, ChannelError.bindFailure("failed to create channel: \(error)"))
        }
    }

}

class ServerBootstrapAcceptor: ChannelHandlerAdapter {
    unowned let queueHolder: QueueHolder
    let childInitializer: ((Channel) -> Void)?
    
    init(_ holder: QueueHolder, initializer: ((Channel) -> Void)?) {
        self.queueHolder = holder
        self.childInitializer = initializer
        super.init(named: "ServerBootstrapAcceptor")
    }

    override func onRead(ctx: ChannelHandlerContext, data: AnyObject) {
        if let socket = data as? SocketChannel {
            debugPrint("ServerBootstrapAcceptor read called with data \(data)...")
            socket.register(withQueue: queueHolder.next)
            childInitializer?(socket)
        }
        else {
            ctx.fireRead(message: data)
        }
    }
    
}
