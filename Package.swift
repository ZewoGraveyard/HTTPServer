import PackageDescription

let package = Package(
    name: "HTTPServer",
    dependencies: [
        .Package(url: "https://github.com/Zewo/TCP.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/Zewo/HTTPParser.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/Zewo/HTTPSerializer.git", majorVersion: 0, minor: 4),
    ]
)
