open class Codec<DownstreamType,UpstreamType>: ChannelHandlerAdapter {
    
    public func encode(_ data: UpstreamType) -> DownstreamType {
        fatalError("Codec::encode not implemented")
    }
    
    public func decode(_ data: DownstreamType) -> UpstreamType {
        fatalError("Codec::decode not implemented")
    }
    
    override open func onRead(ctx: ChannelHandlerContext, data: AnyObject) {
        if let data = data as? DownstreamType {
            let outData = decode(data)
            ctx.fireRead(message: outData as AnyObject)
        }
        else {
            super.onRead(ctx: ctx, data: data)
        }
    }
    
    override open func onWrite(ctx: ChannelHandlerContext, data: AnyObject) {
        if let data = data as? UpstreamType {
            let outData = encode(data)
            ctx.fireRead(message: outData as AnyObject)
        }
        else {
            super.onRead(ctx: ctx, data: data)
        }
    }

}
