import NIO

final class NIODatadogStatsdUDPClientHandler : ChannelOutboundHandler {
    private var errorHandler: (Error) -> ()

    init(onError: @escaping (Error) -> ()) {
        self.errorHandler = onError
    }

    typealias OutboundIn = AddressedEnvelope<ByteBuffer>

    func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        ctx.write(data, promise: promise)
    }

    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        Swift.print("handler errorCaught, error: \(error)")
        ctx.close(promise: nil)

        self.errorHandler(error)
    }
}
