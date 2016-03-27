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
    public let server: C7.StreamServer
    public let parser: S4.RequestParser
    public let middleware: [S4.Middleware]
    public let responder: S4.Responder
    public let serializer: S4.ResponseSerializer
    public let port: Int

    public init(address: String? = nil, port: Int = 8080, reusePort: Bool = false, parser: S4.RequestParser = RequestParser(), middleware: Middleware..., responder: Responder, serializer: S4.ResponseSerializer = ResponseSerializer()) throws {
        self.server = try TCPStreamServer(address: address, port: port, reusePort: reusePort)
        self.parser = parser
        self.middleware = middleware
        self.responder = responder
        self.serializer = serializer
        self.port = port
    }

    public init(_ responder: Responder) throws {
        try self.init(responder: responder)
    }

    public init(address: String? = nil, port: Int = 8080, reusePort: Bool = false, parser: S4.RequestParser = RequestParser(), middleware: Middleware..., serializer: S4.ResponseSerializer = ResponseSerializer(), _ respond: Respond) throws {
        self.server = try TCPStreamServer(address: address, port: port, reusePort: reusePort)
        self.parser = parser
        self.middleware = middleware
        self.responder = BasicResponder(respond)
        self.serializer = serializer
        self.port = port
    }
}

extension Server {
    public func start(failure: ErrorProtocol -> Void = Server.printError) throws {
        printHeader()
        while true {
            let stream = try server.accept()
            co {
                do {
                    try self.processStream(stream)
                } catch {
                    failure(error)
                }
            }
        }
    }

    private func processStream(stream: Stream) throws {
        while !stream.closed {
            do {
                let data = try stream.receive()
                if let request = try parser.parse(data) {
                    let response = try middleware.intercept(responder).respond(request)
                    try serialize(response, stream: stream)

                    if let upgrade = response.upgrade {
                        try upgrade(request, stream)
                        stream.close()
                    }

                    if !request.isKeepAlive {
                        stream.close()
                        break
                    }
                }
            } catch StreamError.closedStream {
                break
            } catch {
                let response = Response(status: .internalServerError)
                try serialize(response, stream: stream)
                throw error
            }
        }
    }

    private func serialize(response: Response, stream: Stream) throws {
        try serializer.serialize(response) { data in
            try stream.send(data)
        }

        try stream.flush()
    }

    public func startInBackground(failure: ErrorProtocol -> Void = Server.printError) {
        co {
            do {
                try self.start()
            } catch {
                failure(error)
            }
        }
    }

    private static func printError(error: ErrorProtocol) -> Void {
        print("Error: \(error)")
    }

    private func printHeader() {
        print("")
        print("")
        print("")
        print("                             _____")
        print("     ,.-``-._.-``-.,        /__  /  ___ _      ______")
        print("    |`-._,.-`-.,_.-`|         / /  / _ \\ | /| / / __ \\")
        print("    |   |ˆ-. .-`|   |        / /__/  __/ |/ |/ / /_/ /")
        print("    `-.,|   |   |,.-`       /____/\\___/|__/|__/\\____/ (c)")
        print("        `-.,|,.-`           -----------------------------")
        print("")
        print("================================================================================")
        print("Started HTTP server, listening on port \(port).")
    }
}

extension Request {
    var connection: HeaderValues {
        get {
            return headers.headers["connection"] ?? HeaderValues([])
        }

        set(connection) {
            headers.headers["connection"] = connection
        }
    }

    var isKeepAlive: Bool {
        if version.minor == 0 {
            return connection.values.contains({$0.lowercased().contains("keep-alive")})
        }

        return connection.values.contains({!$0.lowercased().contains("close")})
    }
}

extension Response {
    typealias Upgrade = (Request, Stream) throws -> Void

    // Warning: The storage key has to be in sync with Zewo.HTTP's upgrade property.
    var upgrade: Upgrade? {
        get {
            return storage["response-connection-upgrade"] as? Upgrade
        }

        set(upgrade) {
            storage["response-connection-upgrade"] = upgrade
        }
    }
}

