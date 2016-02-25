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
@_exported import HTTP

public struct Server: ServerType {
    public let server: StreamServerType
    public let parser: RequestParserType
    public let middleware: [MiddlewareType]
    public let responder: ResponderType
    public let serializer: ResponseSerializerType
    public let port: Int

    public init(address: String? = nil, port: Int = 8080, reusePort: Bool = false, parser: RequestParserType = RequestParser(), middleware: MiddlewareType..., responder: ResponderType, serializer: ResponseSerializerType = ResponseSerializer()) throws {
        self.server = try TCPStreamServer(address: address, port: port, reusePort: reusePort)
        self.parser = parser
        self.middleware = middleware
        self.responder = responder
        self.serializer = serializer
        self.port = port
    }

    public init(address: String? = nil, port: Int = 8080, reusePort: Bool = false, parser: RequestParserType = RequestParser(), middleware: MiddlewareType..., serializer: ResponseSerializerType = ResponseSerializer(), respond: Respond) throws {
        self.server = try TCPStreamServer(address: address, port: port, reusePort: reusePort)
        self.parser = parser
        self.middleware = middleware
        self.responder = Responder(respond: respond)
        self.serializer = serializer
        self.port = port
    }
}

extension Server {
    public func start(failure: ErrorType -> Void = Server.printError) throws {
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

    private func processStream(stream: StreamType) throws {
        while !stream.closed {
            do {
                let data = try stream.receive()
                if let request = try parser.parse(data) {
                    var request = request
                    request.ip = stream.ip

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
            } catch StreamError.ClosedStream {
                break
            } catch {
                let response = Response(status: .InternalServerError)
                try serialize(response, stream: stream)
                throw error
            }
        }
    }

    private func serialize(response: Response, stream: StreamType) throws {
        try serializer.serialize(response) { data in
            try stream.send(data)
        }

        try stream.flush()
    }

    public func startInBackground(failure: ErrorType -> Void = Server.printError) {
        co {
            do {
                try self.start()
            } catch {
                failure(error)
            }
        }
    }

    private static func printError(error: ErrorType) -> Void {
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
        print("Started HTTPServer, listening on port \(port).")
    }
}

extension Request {
    public var ip: IP? {
        get {
            return storage["ip"] as? IP
        }

        set {
            storage["ip"] = newValue
        }
    }
}