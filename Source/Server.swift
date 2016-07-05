// Server.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import TCP
@_exported import HTTPParser
@_exported import HTTPSerializer

public struct Server {
    public let server: C7.Host
    public let parser: S4.RequestParser.Type
    public let middleware: [S4.Middleware]
    public let responder: S4.Responder
    public let serializer: S4.ResponseSerializer.Type
    public let port: Int
    public let bufferSize: Int = 2048

    public init(host: String = "0.0.0.0", port: Int = 8080, reusePort: Bool = false, parser: S4.RequestParser.Type = RequestParser.self, middleware: Middleware..., responder: Responder, serializer: S4.ResponseSerializer.Type = ResponseSerializer.self) throws {
        self.server = try TCPServer(host: host, port: port, reusePort: reusePort)
        self.parser = parser
        self.middleware = middleware
        self.responder = responder
        self.serializer = serializer
        self.port = port
    }

    public init(_ responder: Responder) throws {
        try self.init(responder: responder)
    }

    public init(_ representable: ResponderRepresentable) throws {
        try self.init(responder: representable.responder)
    }

    public init(host: String = "0.0.0.0", port: Int = 8080, reusePort: Bool = false, parser: S4.RequestParser.Type = RequestParser.self, middleware: Middleware..., serializer: S4.ResponseSerializer.Type = ResponseSerializer.self, _ respond: Respond) throws {
        self.server = try TCPServer(host: host, port: port, reusePort: reusePort)
        self.parser = parser
        self.middleware = middleware
        self.responder = BasicResponder(respond)
        self.serializer = serializer
        self.port = port
    }
}

extension Server {
    public func start() throws {
        try self.start(Server.log)
    }

    public func start(_ failure: (ErrorProtocol) -> Void = Server.log) throws {
        printHeader()
        while true {
            let stream = try server.accept(timingOut: .never)
            co {
                do {
                    try self.process(stream: stream)
                } catch {
                    failure(error)
                }
            }
        }
    }

    private func process(stream: Stream) throws {
        let parser = self.parser.init(stream: stream)
        let serializer = self.serializer.init(stream: stream)

        while !stream.closed {
            do {
                let request = try parser.parse()
                let response = try middleware.chain(to: responder).respond(to: request)
                try serializer.serialize(response)

                if let upgrade = response.didUpgrade {
                    try upgrade(request, stream)
                    try stream.close()
                }

                if !request.isKeepAlive {
                    try stream.close()
                }
            } catch {
                if stream.closed {
                    break
                }
                if let response = Server.recover(error: error) {
                    try serializer.serialize(response)
                } else {
                    let response = Response(status: .internalServerError)
                    try serializer.serialize(response)
                    throw error
                }
            }
        }
    }

    public func startInBackground(_ failure: (ErrorProtocol) -> Void = Server.log) {
        co {
            do {
                try self.start()
            } catch {
                failure(error)
            }
        }
    }

    private static func recover(error: ErrorProtocol) -> Response? {
        switch error {
        case ClientError.badRequest:
            return Response(status: .badRequest)
        case ClientError.unauthorized:
            return Response(status: .unauthorized)
        case ClientError.paymentRequired:
            return Response(status: .paymentRequired)
        case ClientError.forbidden:
            return Response(status: .forbidden)
        case ClientError.notFound:
            return Response(status: .notFound)
        case ClientError.methodNotAllowed:
            return Response(status: .methodNotAllowed)
        case ClientError.notAcceptable:
            return Response(status: .notAcceptable)
        case ClientError.proxyAuthenticationRequired:
            return Response(status: .proxyAuthenticationRequired)
        case ClientError.requestTimeout:
            return Response(status: .requestTimeout)
        case ClientError.conflict:
            return Response(status: .conflict)
        case ClientError.gone:
            return Response(status: .gone)
        case ClientError.lengthRequired:
            return Response(status: .lengthRequired)
        case ClientError.preconditionFailed:
            return Response(status: .preconditionFailed)
        case ClientError.requestEntityTooLarge:
            return Response(status: .requestEntityTooLarge)
        case ClientError.requestURITooLong:
            return Response(status: .requestURITooLong)
        case ClientError.unsupportedMediaType:
            return Response(status: .unsupportedMediaType)
        case ClientError.requestedRangeNotSatisfiable:
            return Response(status: .requestedRangeNotSatisfiable)
        case ClientError.expectationFailed:
            return Response(status: .expectationFailed)
        case ClientError.imATeapot:
            return Response(status: .imATeapot)
        case ClientError.authenticationTimeout:
            return Response(status: .authenticationTimeout)
        case ClientError.enhanceYourCalm:
            return Response(status: .enhanceYourCalm)
        case ClientError.unprocessableEntity:
            return Response(status: .unprocessableEntity)
        case ClientError.locked:
            return Response(status: .locked)
        case ClientError.failedDependency:
            return Response(status: .failedDependency)
        case ClientError.preconditionRequired:
            return Response(status: .preconditionRequired)
        case ClientError.tooManyRequests:
            return Response(status: .tooManyRequests)
        case ClientError.requestHeaderFieldsTooLarge:
            return Response(status: .requestHeaderFieldsTooLarge)

        case ServerError.internalServerError:
            return Response(status: .internalServerError)
        case ServerError.notImplemented:
            return Response(status: .notImplemented)
        case ServerError.badGateway:
            return Response(status: .badGateway)
        case ServerError.serviceUnavailable:
            return Response(status: .serviceUnavailable)
        case ServerError.gatewayTimeout:
            return Response(status: .gatewayTimeout)
        case ServerError.httpVersionNotSupported:
            return Response(status: .httpVersionNotSupported)
        case ServerError.variantAlsoNegotiates:
            return Response(status: .variantAlsoNegotiates)
        case ServerError.insufficientStorage:
            return Response(status: .insufficientStorage)
        case ServerError.loopDetected:
            return Response(status: .loopDetected)
        case ServerError.notExtended:
            return Response(status: .notExtended)
        case ServerError.networkAuthenticationRequired:
            return Response(status: .networkAuthenticationRequired)

        default:
            return nil
        }
    }

    private static func log(error: ErrorProtocol) -> Void {
        print("Error: \(error)")
    }

    private func printHeader() {
        var header = "\n"
        header += "\n"
        header += "\n"
        header += "                             _____\n"
        header += "     ,.-``-._.-``-.,        /__  /  ___ _      ______\n"
        header += "    |`-._,.-`-.,_.-`|         / /  / _ \\ | /| / / __ \\\n"
        header += "    |   |ˆ-. .-`|   |        / /__/  __/ |/ |/ / /_/ /\n"
        header += "    `-.,|   |   |,.-`       /____/\\___/|__/|__/\\____/ (c)\n"
        header += "        `-.,|,.-`           -----------------------------\n"
        header += "\n"
        header += "================================================================================\n"
        header += "Started HTTP server, listening on port \(port)."
        print(header)
    }
}

extension Request {
    var connection: String? {
        get {
            return headers.headers["connection"]
        }

        set(connection) {
            headers.headers["connection"] = connection
        }
    }

    var isKeepAlive: Bool {
        if version.minor == 0 {
            return connection?.lowercased() == "keep-alive"
        }
        return connection?.lowercased() != "close"
    }
}

extension Response {
    typealias DidUpgrade = (Request, Stream) throws -> Void

    // Warning: The storage key has to be in sync with Zewo.HTTP's upgrade property.
    var didUpgrade: DidUpgrade? {
        get {
            return storage["response-connection-upgrade"] as? DidUpgrade
        }

        set(didUpgrade) {
            storage["response-connection-upgrade"] = didUpgrade
        }
    }
}

extension Response {
    init(status: Status = .ok, headers: Headers = [:], body: Data = []) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: [],
            body: .buffer(body)
        )

        self.headers["Content-Length"] = body.count.description
    }
}
