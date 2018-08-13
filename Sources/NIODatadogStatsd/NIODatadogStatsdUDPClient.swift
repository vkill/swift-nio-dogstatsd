import NIO

fileprivate let onDemandSharedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

public final class NIODatadogStatsdUDPClient {

    private let channel: Channel
    private let handler: NIODatadogStatsdUDPClientHandler

    private init(channel: Channel, handler: NIODatadogStatsdUDPClientHandler) {
        self.channel = channel
        self.handler = handler
    }

    public func close() -> EventLoopFuture<Void> {
        return channel.close(mode: .all)
    }

    public var onClose: EventLoopFuture<Void> {
        return channel.closeFuture
    }

    public static func bind(
        host: String,
        port: Int,
        on eventLoopGroup: EventLoopGroup? = nil,
        onHandlerError: @escaping (Error) -> () = { _ in }
    ) throws -> EventLoopFuture<NIODatadogStatsdUDPClient> {
        let socketAddress = try SocketAddress.newAddressResolving(host: host, port: port)
        return try self.bind(socketAddress: socketAddress, on: eventLoopGroup)
    }

    public static func bind(
        socketAddress: SocketAddress,
        on eventLoopGroup: EventLoopGroup? = nil,
        onHandlerError: @escaping (Error) -> () = { _ in }
    ) throws -> EventLoopFuture<NIODatadogStatsdUDPClient> {
        return try self.bind0(socketAddress: socketAddress, on: eventLoopGroup)
    }

    public static func bind(
        unixDomainSocketPath: String,
        on eventLoopGroup: EventLoopGroup? = nil,
        onHandlerError: @escaping (Error) -> () = { _ in }
    ) throws -> EventLoopFuture<NIODatadogStatsdUDPClient> {
        return try self.bind0(unixDomainSocketPath: unixDomainSocketPath, on: eventLoopGroup)
    }

    private static func bind0(
        socketAddress: SocketAddress? = nil,
        unixDomainSocketPath: String = "/var/run/NIOSimpleUDPClient.unix",
        on eventLoopGroup: EventLoopGroup? = nil,
        onHandlerError: @escaping (Error) -> () = { _ in }
    ) throws -> EventLoopFuture<NIODatadogStatsdUDPClient> {
        let eventLoopGroup = eventLoopGroup
            ?? MultiThreadedEventLoopGroup.currentEventLoop
            ?? onDemandSharedEventLoopGroup

        let handler = NIODatadogStatsdUDPClientHandler(onError: onHandlerError)

        let bootstrap = DatagramBootstrap(group: eventLoopGroup)
        _ = bootstrap.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        _ = bootstrap.channelInitializer { channel in
            channel.pipeline.add(handler: handler)
        }

        let channelFuture: EventLoopFuture<Channel>

        if let socketAddress = socketAddress {
            channelFuture = bootstrap.bind(to: socketAddress)
        } else {
            channelFuture = bootstrap.bind(unixDomainSocketPath: unixDomainSocketPath)
        }

        return channelFuture.map { channel in
            return NIODatadogStatsdUDPClient(channel: channel, handler: handler)
        }
    }

    public func writeAndFlush(_ text: String, to: (host: String, port: Int)) throws {
        var buffer = channel.allocator.buffer(capacity: text.utf8.count)
        buffer.write(string: text)
        let remoteAddress = try SocketAddress.newAddressResolving(host: to.host, port: to.port)

        return self.writeAndFlush(buffer, to: remoteAddress)
    }

    private func writeAndFlush(_ buffer: ByteBuffer, to remoteAddress: SocketAddress, promise: EventLoopPromise<Void>? = nil) {
        let data = AddressedEnvelope(remoteAddress: remoteAddress, data: buffer)
        self.channel.writeAndFlush(data, promise: promise)
    }
}
