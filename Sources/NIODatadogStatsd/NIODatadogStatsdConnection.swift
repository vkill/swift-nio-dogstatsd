import DatadogStatsd
import NIO

public final class NIODatadogStatsdConnection: DatadogStatsdConnection {
    public var client: NIODatadogStatsdUDPClient?

    public init(client: NIODatadogStatsdUDPClient? = nil) {
        self.client = client
    }

    public func bind(host: String, port: Int, on eventLoopGroup: EventLoopGroup?) throws -> EventLoopFuture<()> {
        return try NIODatadogStatsdUDPClient.bind(host: host, port: port, on: eventLoopGroup) { handlerError in
            Swift.print("NIODatadogStatsdUDPClient onHandlerError, error: \(handlerError)")
        }.map { [weak self] simpleUDPClient in
            if let me = self {
                me.client = simpleUDPClient
            }

            _ = simpleUDPClient.onClose.map{_ in
                Swift.print("NIODatadogStatsdUDPClient closed")
            }.mapIfError{ error in
                Swift.print("NIODatadogStatsdUDPClient closed, error: \(error)")
            }
        }.mapIfError{ error in
            Swift.print("NIODatadogStatsdUDPClient error happened, error: \(error)")
        }
    }

    public func write(_ text: String, to: (host: String, port: Int)) throws {
        if let client = client {
            return try client.write(text, to: to)
        }
    }
}

extension NIODatadogStatsdUDPClient {
    func write(_ text: String, to: (host: String, port: Int)) throws {
        return try self.writeAndFlush(text, to: to)
    }
}
