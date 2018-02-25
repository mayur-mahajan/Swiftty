import XCTest
@testable import Swiftty

class BootstrapTests: XCTestCase {
    class ByteToStringCodec: ChannelHandlerAdapter {
        override func onWrite(ctx: ChannelHandlerContext, data: Any) {
            if let data = data as? String,
                let obj = data.data(using: .utf8) {
                ctx.fireWrite(message: obj)
            }
            else {
                ctx.fireRead(message: data)
            }
        }
        
        override func onRead(ctx: ChannelHandlerContext, data: Any) {
            if let data = data as? Data,
                let strMessage = String(data: data, encoding: .utf8) {
                ctx.fireRead(message: strMessage)
            }
            else {
                ctx.fireRead(message: data)
            }
        }
    }

    class EchoHandler: ChannelHandlerAdapter {
        let latch: CountdownLatch

        init(named: String, latch: CountdownLatch) {
            self.latch = latch
            super.init(named: named)
        }
        
        override func onRead(ctx: ChannelHandlerContext, data: Any) {
            guard let message = data as? String else {
                print("unexpected message received, forwarding..")
                ctx.fireRead(message: data)
                return
            }
            
            print("got string \(message)")
            if message.trimmingCharacters(in: CharacterSet.newlines).lowercased() == "bye" {
                print("closing channel and stopping")
                ctx.channel.close() { _,_ in }
                latch.countdown()
                return
            }

            // Echo back the message
            print("received string \(message), echoing back")
            ctx.fireWrite(message: message)
        }
    }

    func testServerBootstrap() {
        var bindError: Error?
        let latch = CountdownLatch(count: 0)
        var acceptChannel: Channel?
        
        let address = SocketAddress(port: 9119)

        // Create a server bootstrap and start listening on a port
        let serverBS = ServerBootstrap()
            .numQueues(4)
            .channelFactory() {
                return try SocketChannel()
            }
            .childInitializer() { channel in
                print("Child initializer called on \(channel)")
                _ = channel.pipeline?
                    .add(last: ByteToStringCodec(named: "b2s"))
                    .add(last: EchoHandler(named: "echo", latch: latch))
            }
            
        serverBS.bind(toAddress: address) { (channel, error) in
            print("Got channel \(String(describing: channel)) and error \(String(describing: error))")
            bindError = error
            acceptChannel = channel
        }
        
        XCTAssertNotNil(serverBS, "Server bootstrap not created")

        print("Trigger client connect. Comment line for below manual testing")
        let rc = TestUtil.send(string: "bye", toHost: "127.0.0.1", port: 9119)
        XCTAssertEqual(rc, 0)
        print("Waiting for server to stop...")
        latch.await()
        
        XCTAssertNotNil(acceptChannel, "Accept channel is null")
        XCTAssertNil(bindError, "Error during socker bind: \(bindError!)")
        acceptChannel?.close() { _,_  in
            print("accept hannel closed")
        }
    }

}

#if os(Linux)
    extension BootstrapTests {
        static var allTests : [(String, BootstrapTests -> () throws -> Void)] {
            return [
                ("testServerBootstrap", testServerBootstrap),
            ]
        }
    }
#endif

