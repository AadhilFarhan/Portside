import Foundation

public enum BindScope: String, Sendable, Equatable {
    case loopback
    case allInterfaces
    case specific
}

public struct ListeningSocket: Sendable, Equatable {
    public let pid: Int32
    public let command: String
    public let port: Int
    public let scope: BindScope

    public init(pid: Int32, command: String, port: Int, scope: BindScope) {
        self.pid = pid
        self.command = command
        self.port = port
        self.scope = scope
    }
}

public enum Framework: String, Sendable, CaseIterable {
    case vite, next, nuxt, astro, remix, webpack, cra
    case node, bun, deno
    case django, flask, fastapi, python
    case rails, ruby
    case laravel, php
    case go, rust, dotnet, java
    case postgres, mysql, redis, mongo
    case docker, caddy, nginx
    case unknown

    public var displayName: String {
        switch self {
        case .vite: "Vite"
        case .next: "Next.js"
        case .nuxt: "Nuxt"
        case .astro: "Astro"
        case .remix: "Remix"
        case .webpack: "webpack"
        case .cra: "React Scripts"
        case .node: "Node"
        case .bun: "Bun"
        case .deno: "Deno"
        case .django: "Django"
        case .flask: "Flask"
        case .fastapi: "FastAPI"
        case .python: "Python"
        case .rails: "Rails"
        case .ruby: "Ruby"
        case .laravel: "Laravel"
        case .php: "PHP"
        case .go: "Go"
        case .rust: "Rust"
        case .dotnet: ".NET"
        case .java: "Java"
        case .postgres: "Postgres"
        case .mysql: "MySQL"
        case .redis: "Redis"
        case .mongo: "MongoDB"
        case .docker: "Docker"
        case .caddy: "Caddy"
        case .nginx: "nginx"
        case .unknown: ""
        }
    }
}

public enum ServerKind: Sendable, Equatable {
    case dev
    case other
}

/// One row in the UI: a process listening on one port.
public struct DevServer: Sendable, Equatable, Identifiable {
    public var id: String { "\(pid):\(port)" }

    public let pid: Int32
    public let port: Int
    public let scope: BindScope
    public let executable: String
    public let arguments: String
    public let projectName: String?
    public let workingDirectory: String?
    public let framework: Framework
    public let kind: ServerKind
    public let cpuPercent: Double
    public let residentBytes: Int64
    public let elapsed: TimeInterval

    public init(
        pid: Int32, port: Int, scope: BindScope, executable: String,
        arguments: String, projectName: String?, workingDirectory: String?,
        framework: Framework, kind: ServerKind, cpuPercent: Double,
        residentBytes: Int64, elapsed: TimeInterval
    ) {
        self.pid = pid
        self.port = port
        self.scope = scope
        self.executable = executable
        self.arguments = arguments
        self.projectName = projectName
        self.workingDirectory = workingDirectory
        self.framework = framework
        self.kind = kind
        self.cpuPercent = cpuPercent
        self.residentBytes = residentBytes
        self.elapsed = elapsed
    }

    /// Best human name for the row: project folder/manifest name, else framework, else executable.
    public var displayName: String {
        if let projectName, !projectName.isEmpty { return projectName }
        if framework != .unknown { return framework.displayName }
        return (executable as NSString).lastPathComponent
    }

    public var localURL: URL {
        URL(string: "http://localhost:\(port)")!
    }
}
