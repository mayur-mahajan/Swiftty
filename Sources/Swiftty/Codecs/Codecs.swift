open class Codec<DownstreamType,UpstreamType>: ChannelHandlerAdapter {
    
    public func encode(_ data: UpstreamType) -> DownstreamType {
        fatalError("Codec::encode not implemented")
    }
    
    public func decode(_ data: DownstreamType) -> UpstreamType {
        fatalError("Codec::decode not implemented")
    }
    
    override open func onRead(ctx: ChannelHandlerContext, data: Any) {
        if let data = data as? DownstreamType {
            let outData = decode(data)
            ctx.fireRead(message: outData)
        }
        else {
            super.onRead(ctx: ctx, data: data)
        }
    }
    
    override open func onWrite(ctx: ChannelHandlerContext, data: Any) {
        if let data = data as? UpstreamType {
            let outData = encode(data)
            ctx.fireRead(message: outData)
        }
        else {
            super.onRead(ctx: ctx, data: data)
        }
    }

}
