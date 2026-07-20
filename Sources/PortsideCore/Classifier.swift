import Foundation

public enum Classifier {

    public static func framework(arguments: String) -> Framework {
        let args = arguments.lowercased()
        let tokens = args.split(separator: " ").map(String.init)
        let exe = ((arguments.split(separator: " ").first).map(String.init) ?? "" as String)
        let exeName = (exe as NSString).lastPathComponent.lowercased()

        // Order matters: specific tools before the runtimes that host them.
        let markers: [(String, Framework)] = [
            ("vite", .vite),
            ("next dev", .next), ("next-server", .next), ("next start", .next),
            ("nuxt", .nuxt),
            ("astro", .astro),
            ("remix", .remix),
            ("react-scripts", .cra),
            ("webpack", .webpack),
            ("manage.py runserver", .django), ("django", .django),
            ("uvicorn", .fastapi), ("fastapi", .fastapi),
            ("flask", .flask),
            ("rails", .rails), ("puma", .rails),
            ("artisan serve", .laravel),
            ("php-fpm", .php),
            ("gradle", .java), ("spring", .java),
        ]
        for (marker, framework) in markers where matches(marker, args: args, tokens: tokens) {
            return framework
        }

        let runtimes: [(String, Framework)] = [
            ("node", .node), ("bun", .bun), ("deno", .deno),
            ("python", .python), ("python3", .python),
            ("ruby", .ruby), ("php", .php), ("java", .java),
            ("go", .go), ("cargo", .rust),
            ("postgres", .postgres), ("mysqld", .mysql),
            ("redis-server", .redis), ("mongod", .mongo),
            ("caddy", .caddy), ("nginx", .nginx),
            ("dotnet", .dotnet),
        ]
        for (name, framework) in runtimes where exeName == name || exeName.hasPrefix(name + "-") {
            return framework
        }
        if args.contains("docker") || exeName.contains("com.docker") {
            return .docker
        }
        return .unknown
    }

    /// A one-word marker (e.g. "vite", "rails") must match a whole token or a
    /// token's path basename — never an arbitrary substring — so a project
    /// folder that happens to contain the marker's text (`my-rails-app`,
    /// `webpack-notes`) doesn't get misclassified. Multi-word markers
    /// ("next dev", "manage.py runserver") represent a specific consecutive
    /// phrase, which a plain substring check on the full string handles fine.
    private static func matches(_ marker: String, args: String, tokens: [String]) -> Bool {
        guard !marker.contains(" ") else { return args.contains(marker) }
        return tokens.contains { $0 == marker || ($0 as NSString).lastPathComponent == marker }
    }

    /// Dev servers get top billing; OS daemons and ordinary apps go to "Other".
    public static func kind(executable: String, framework: Framework) -> ServerKind {
        if framework != .unknown { return .dev }
        let systemPrefixes = [
            "/System/", "/usr/libexec/", "/usr/sbin/", "/sbin/",
            "/Library/Apple/", "/System/Applications/",
        ]
        for prefix in systemPrefixes where executable.hasPrefix(prefix) {
            return .other
        }
        let devRoots = ["/opt/homebrew/", "/usr/local/", "/Users/"]
        let devPathHints = ["/.nvm/", "/.asdf/", "/.mise/", "/node_modules/", "/.cargo/", "/go/bin/"]
        if devRoots.contains(where: executable.hasPrefix)
            || devPathHints.contains(where: executable.contains) {
            return .dev
        }
        return .other
    }
}

public enum ProjectNamer {

    /// Given a process working directory, find the project's own name:
    /// manifest name field where available, else the folder name.
    public static func projectName(cwd: String, fileManager: FileManager = .default) -> String? {
        guard cwd != "/", cwd != NSHomeDirectory() else { return nil }

        let packageJSON = (cwd as NSString).appendingPathComponent("package.json")
        if let data = fileManager.contents(atPath: packageJSON),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["name"] as? String, !name.isEmpty {
            return name
        }

        let manifests = [
            "Cargo.toml", "pyproject.toml", "go.mod", "Gemfile",
            "composer.json", "mix.exs", "Package.swift", "requirements.txt",
        ]
        let hasManifest = manifests.contains {
            fileManager.fileExists(atPath: (cwd as NSString).appendingPathComponent($0))
        }
        let hasProjectFile = (try? fileManager.contentsOfDirectory(atPath: cwd))?
            .contains { $0.hasSuffix(".csproj") || $0.hasSuffix(".fsproj") || $0.hasSuffix(".xcodeproj") }
            ?? false

        if hasManifest || hasProjectFile {
            return (cwd as NSString).lastPathComponent
        }
        return nil
    }
}
