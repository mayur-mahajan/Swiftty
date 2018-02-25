import Foundation
import Dispatch

public protocol ChannelPipeline: ChannelTriggers {
    func add(first: ChannelHandler) -> ChannelPipeline
    func add(last: ChannelHandler) -> ChannelPipeline
    func add(_ handler: ChannelHandler, after: ChannelHandler) -> ChannelPipeline
}

class DefaultChannelPipeline: ChannelPipeline {
    unowned let channel: Channel
    
    var head: DefaultChannelHandlerContext
    var tail: DefaultChannelHandlerContext
    
    init(_ ch: Channel) {
        channel = ch
        head = HeadContext(channel)
        tail = TailContext(channel)
        head.next = tail
        tail.prev = head
    }
    
    @discardableResult
    public func add(first: ChannelHandler) -> ChannelPipeline {
        let newContext = DefaultChannelHandlerContext(channel, handler: first)
        doAdd(after: head, node: newContext)
        return self
    }
    
    @discardableResult
    public func add(last: ChannelHandler) -> ChannelPipeline {
        let newContext = DefaultChannelHandlerContext(channel, handler: last)
        doAdd(node: newContext, before: tail)
        return self
    }
    
    @discardableResult
    public func add(_ handler: ChannelHandler, after: ChannelHandler) -> ChannelPipeline {
        var current = head
        while current !== tail {
            if current.handler === after {
                let newContext = DefaultChannelHandlerContext(channel, handler: handler)
                doAdd(after: current, node: newContext)
            }
            current = current.next!
        }
        return self
    }
    
    @discardableResult
    public func add(_ handler: ChannelHandler, afterNamed: String) -> ChannelPipeline {
        var current = head
        while current !== tail {
            if current.handler.name == afterNamed {
                let newContext = DefaultChannelHandlerContext(channel, handler: handler)
                doAdd(after: current, node: newContext)
            }
            current = current.next!
        }
        return self
    }

    
    private func doAdd(node: DefaultChannelHandlerContext, before: DefaultChannelHandlerContext) {
        node.next = before
        node.prev = before.prev
        before.prev?.next = node
        before.prev = node
    }
    
    private func doAdd(after: DefaultChannelHandlerContext, node: DefaultChannelHandlerContext) {
        node.next = after.next
        node.prev = after
        after.prev?.next = node
        after.prev = node
    }
    
    func fireRegistered() {
        head.handler.onRegistered(ctx: head)
    }
    
    func fireUnregistered() {
        head.handler.onUnregistered(ctx: head)
    }
    
    func fireActive() {
        head.handler.onActive(ctx: head)
    }
    
    func fireInactive() {
        head.handler.onInactive(ctx: head)
    }
    
    func fireRead(message: Any) {
        head.handler.onRead(ctx: head, data: message)
    }
    
    func fireWrite(message: Any) {
        tail.handler.onWrite(ctx: tail, data: message)
    }
    
    func fireError(error: ChannelError) {
        head.handler.onError(ctx: head, error: error)
    }

}

class DefaultChannelHandlerContext: ChannelHandlerContext {
    public unowned let channel: Channel
    
    public private(set) var handler: ChannelHandler
    
    var prev: DefaultChannelHandlerContext?
    var next: DefaultChannelHandlerContext?
    
    init(_ channel: Channel, handler: ChannelHandler) {
        self.channel = channel
        self.handler = handler
    }
    
    func fireRegistered() {
        if let nextCtx = next {
            nextCtx.handler.onRegistered(ctx: nextCtx)
        }
    }

    func fireUnregistered() {
        if let nextCtx = next {
            nextCtx.handler.onUnregistered(ctx: nextCtx)
        }
    }

    func fireActive() {
        if let nextCtx = next {
            nextCtx.handler.onActive(ctx: nextCtx)
        }
    }

    func fireInactive() {
        if let nextCtx = next {
            nextCtx.handler.onInactive(ctx: nextCtx)
        }
    }

    func fireRead(message: Any) {
        if let nextCtx = next {
            nextCtx.handler.onRead(ctx: nextCtx, data: message)
        }
    }
    
    func fireWrite(message: Any) {
        if let prevCtx = prev {
            prevCtx.handler.onWrite(ctx: prevCtx, data: message)
        }
    }

    func fireError(error: ChannelError) {
        next?.handler.onError(ctx: self, error: error)
    }
}

open class ChannelHandlerAdapter : ChannelHandler {
    open private(set) var name: String
    
    public init(named: String) {
        name = named
    }

    open func onRegistered(ctx: ChannelHandlerContext) {
        ctx.fireRegistered()
    }
    open func onUnregistered(ctx: ChannelHandlerContext) {
        ctx.fireUnregistered()
    }
    open func onActive(ctx: ChannelHandlerContext) {
        ctx.fireActive()
    }
    open func onInactive(ctx: ChannelHandlerContext) {
        ctx.fireInactive()
    }
    open func onRead(ctx: ChannelHandlerContext, data: Any) {
        ctx.fireRead(message: data)
    }
    open func onWrite(ctx: ChannelHandlerContext, data: Any) {
        ctx.fireWrite(message: data)
    }

    open func handlerAdded(ctx: ChannelHandlerContext) {}
    open func handlerRemoved(ctx: ChannelHandlerContext) {}
    open func onError(ctx: ChannelHandlerContext, error: ChannelError) {
        ctx.fireError(error: error)
    }
}

class HeadContext : DefaultChannelHandlerContext {
    init(_ channel: Channel) {
        super.init(channel, handler: HeadHandler())
    }

    class HeadHandler: ChannelHandlerAdapter {
        init() {
            super.init(named: "HeadHandler")
        }
        
        override func onWrite(ctx: ChannelHandlerContext, data: Any) {
            guard let msg = data as? Data else {
                debugPrint("expecting message of type 'Data'")
                return
            }

            ctx.channel.write(msg) {_,_ in }
        }
    }
    
}

class TailContext : DefaultChannelHandlerContext {
    init(_ channel: Channel) {
        super.init(channel, handler: TailHandler())
    }
    
    class TailHandler: ChannelHandlerAdapter {
        init() {
            super.init(named: "TailHandler")
        }

        override func onError(ctx: ChannelHandlerContext, error: ChannelError) {
            print("Error: \(error) reached end of pipeline")
        }
        
        override func onRead(ctx: ChannelHandlerContext, data: Any) {
            print("Error: read event reached end of pipeline for \(data)")
        }
    }
}
