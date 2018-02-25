import Foundation
import Dispatch

public enum ChannelError : Error {
    case bindFailure(String)
    case writeFailure(Error)
}

public typealias ChannelCompletion = (Channel?, ChannelError?) -> Void

public protocol ChannelOperations {
    func register(withQueue: DispatchQueue)
    func bind(at: Address, onComplete: @escaping ChannelCompletion)
    func connect(to: Address, onComplete: ChannelCompletion)
    func disconnect(_ onComplete: ChannelCompletion)
    func close(_ onComplete: ChannelCompletion)
    func write(_ data: Data, _ onComplete: ChannelCompletion)
}

public protocol Channel: class, ChannelOperations {
    var localAddress: Address? { get }
    var remoteAddress: Address? { get }
    var dispatchQueue: DispatchQueue? { get }
    var pipeline: ChannelPipeline? { get }
}

public extension Channel {
    public static var ignoreCompletion: ChannelCompletion {
        return {_,_ in }
    }
}

// One for each Channel event
public protocol ChannelTriggers {
    func fireRegistered()
    func fireUnregistered()
    func fireActive()
    func fireInactive()

    func fireRead(message: Any)
    func fireWrite(message: Any)
    func fireError(error: ChannelError)
}

// One for each Channel trigger
public protocol ChannelEvents {
    func onRegistered(ctx: ChannelHandlerContext)
    func onUnregistered(ctx: ChannelHandlerContext)
    func onActive(ctx: ChannelHandlerContext)
    func onInactive(ctx: ChannelHandlerContext)
    
    func onRead(ctx: ChannelHandlerContext, data: Any)
    func onWrite(ctx: ChannelHandlerContext, data: Any)
    func onError(ctx: ChannelHandlerContext, error: ChannelError)
}

public protocol ChannelHandlerContext : ChannelTriggers {
    var channel: Channel { get }
    var handler: ChannelHandler { get }
}

public protocol ChannelHandler : AnyObject, ChannelEvents {
    var name: String { get }
    func handlerAdded(ctx: ChannelHandlerContext)
    func handlerRemoved(ctx: ChannelHandlerContext)
}
