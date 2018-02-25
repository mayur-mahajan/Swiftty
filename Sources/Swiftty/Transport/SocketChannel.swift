import Socket
import Foundation
import Dispatch

public class SocketAddress: Address {
    private let internalAddress: Socket.Address
    
    public init(rawAddress: Socket.Address) {
        internalAddress = rawAddress
    }
    
    public init(port: Int) {
        var addr = sockaddr_in()
        addr.sin_port = UInt16(port).bigEndian
        internalAddress = .ipv4(addr)
    }

    public var port: Int? {
        if let port = Socket.hostnameAndPort(from: internalAddress)?.port {
            return Int(port)
        }
        return nil
    }
}

public class SocketChannel : Channel {
    let sock: Socket
    var serverBound = false
    
    var readerSource: DispatchSourceRead?
    var writerSource: DispatchSourceWrite?
    
    public private(set) var dispatchQueue: DispatchQueue? {
        willSet {
            if dispatchQueue != nil {
                fatalError("Attempt to re-register channel")
            }
        }
    }
    
    public private(set) var pipeline: ChannelPipeline?
    
    public convenience init() throws {
        try self.init(with: try Socket.create())
    }
    
    init(with rawSocket: Socket) throws {
        sock = rawSocket
        try sock.setBlocking(mode: false)
    }
    
    private func readListeningSocket() throws -> Any {
        let newSock = try self.sock.acceptClientConnection()
        debugPrint("Accepted connection from: \(newSock.remoteHostname) on port \(newSock.remotePort)")
        debugPrint("Socket Signature: \(String(describing: newSock.signature?.description))")
        return try SocketChannel(with: newSock)
    }
    
    private func readDataSocket() throws -> Any {
        var data = Data()
        let count = try self.sock.read(into: &data)
        debugPrint("read event handler called \(self), data \(data) read \(count) bytes")
        return data
    }
    
    public func register(withQueue: DispatchQueue) {
        self.dispatchQueue = withQueue
        self.pipeline = DefaultChannelPipeline(self)
        
        self.readerSource = DispatchSource.makeReadSource(fileDescriptor: sock.socketfd, queue: withQueue)
        debugPrint("Reader source created for socket \(self.readerSource!)")
        self.readerSource!.setEventHandler() {
            do {
                let obj = self.sock.isServer ? try self.readListeningSocket() : try self.readDataSocket()
                self.pipeline?.fireRead(message: obj)
            }
            catch {
                print("Error reading from socket \(error)")
            }
        }
        self.readerSource!.setCancelHandler() {
            debugPrint("cancel handler called")
        }
        self.readerSource!.resume()
    }
    
    public func bind(at: Address, onComplete: @escaping ChannelCompletion) {
        guard let sockAddr = at as? SocketAddress else {
            onComplete(nil, ChannelError.bindFailure("invalid address type"))
            return
        }
        
        guard let port = sockAddr.port else {
            onComplete(nil, ChannelError.bindFailure("cannot retrieve port"))
            return
        }

        guard let queue = self.dispatchQueue else {
            onComplete(nil, ChannelError.bindFailure("channel not registered"))
            return
        }
        
        debugPrint("SocketChannel bind called")
        queue.async {
            do {
                try self.sock.listen(on: port)
                print("Listening on port: \(port)")
                self.serverBound = true
                
                onComplete(self, nil)
            }
            catch {
                onComplete(nil, ChannelError.bindFailure("Error: \(error)"))
            }
        }
    }
    
    public func connect(to: Address, onComplete: ChannelCompletion) {
        
    }

    public func disconnect(_ onComplete: ChannelCompletion) {
        
    }

    public func close(_ onComplete: ChannelCompletion) {
        self.readerSource?.cancel()
        self.writerSource?.cancel()

        serverBound = false
        sock.close()
    }
    
    public func write(_ data: Data, _ onComplete: (Channel?, ChannelError?) -> Void) {
        do {
            try sock.write(from: data)
        }
        catch {
            onComplete(nil, ChannelError.writeFailure(error))
        }
    }
    
    public var localAddress: Address? {
        return nil
    }

    public var remoteAddress: Address? {
        return nil
    }
    
}
