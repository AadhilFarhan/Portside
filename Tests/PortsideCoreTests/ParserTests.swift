import Foundation
import XCTest
@testable import PortsideCore

final class LsofParserTests: XCTestCase {

    func testParsesTypicalOutput() {
        let output = """
        p358
        cnode
        n*:3000
        n127.0.0.1:3001
        p912
        cpython3.12
        n[::1]:8000
        """
        let sockets = LsofParser.parse(output)
        XCTAssertEqual(sockets.count, 3)
        XCTAssertEqual(sockets[0], ListeningSocket(pid: 358, command: "node", port: 3000, scope: .allInterfaces))
        XCTAssertEqual(sockets[1], ListeningSocket(pid: 358, command: "node", port: 3001, scope: .loopback))
        XCTAssertEqual(sockets[2], ListeningSocket(pid: 912, command: "python3.12", port: 8000, scope: .loopback))
    }

    func testDedupesDualStackListeners() {
        let output = """
        p100
        cnode
        n*:5173
        n*:5173
        """
        XCTAssertEqual(LsofParser.parse(output).count, 1)
    }

    func testAddressScopes() {
        XCTAssertEqual(LsofParser.parseAddress("*:3000")?.scope, .allInterfaces)
        XCTAssertEqual(LsofParser.parseAddress("127.0.0.1:80")?.scope, .loopback)
        XCTAssertEqual(LsofParser.parseAddress("[::1]:5432")?.scope, .loopback)
        XCTAssertEqual(LsofParser.parseAddress("192.168.1.7:8080")?.scope, .specific)
        XCTAssertNil(LsofParser.parseAddress("garbage"))
        XCTAssertNil(LsofParser.parseAddress("*:notaport"))
    }
}

final class PsParserTests: XCTestCase {

    func testParsesRows() {
        let output = """
          358  1.5  84212 05:42 /usr/local/bin/node /Users/x/app/server.js
          912  0.0   1024 1-02:03:04 python3 -m http.server 8000
        """
        let rows = PsParser.parse(output)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[358]?.cpuPercent, 1.5)
        XCTAssertEqual(rows[358]?.residentBytes, 84212 * 1024)
        XCTAssertEqual(rows[358]?.elapsed, 342)
        XCTAssertEqual(rows[358]?.executable, "/usr/local/bin/node")
        XCTAssertEqual(rows[912]?.elapsed, 93784.0)
    }

    func testElapsedFormats() {
        XCTAssertEqual(PsParser.parseElapsed("00:05"), 5)
        XCTAssertEqual(PsParser.parseElapsed("01:02:03"), 3723)
        XCTAssertEqual(PsParser.parseElapsed("2-00:00:01"), 172801)
        XCTAssertNil(PsParser.parseElapsed("junk"))
    }
}

final class ClassifierTests: XCTestCase {

    func testFrameworkDetection() {
        XCTAssertEqual(Classifier.framework(arguments: "node /x/node_modules/.bin/vite dev"), .vite)
        XCTAssertEqual(Classifier.framework(arguments: "node next-server (v14.2)"), .next)
        XCTAssertEqual(Classifier.framework(arguments: "python3 manage.py runserver"), .django)
        XCTAssertEqual(Classifier.framework(arguments: "/usr/bin/python3 -m uvicorn app:app"), .fastapi)
        XCTAssertEqual(Classifier.framework(arguments: "puma 6.4.2 (tcp://0.0.0.0:3000)"), .rails)
        XCTAssertEqual(Classifier.framework(arguments: "/opt/homebrew/bin/node server.js"), .node)
        XCTAssertEqual(Classifier.framework(arguments: "/opt/homebrew/opt/postgresql@16/bin/postgres -D /opt/homebrew/var"), .postgres)
        XCTAssertEqual(Classifier.framework(arguments: "/usr/libexec/rapportd"), .unknown)
    }

    func testKindClassification() {
        XCTAssertEqual(Classifier.kind(executable: "/usr/libexec/rapportd", framework: .unknown), .other)
        XCTAssertEqual(Classifier.kind(executable: "/System/Library/CoreServices/x", framework: .unknown), .other)
        XCTAssertEqual(Classifier.kind(executable: "/opt/homebrew/bin/node", framework: .node), .dev)
        XCTAssertEqual(Classifier.kind(executable: "/Users/dev/.nvm/versions/node/v20/bin/node", framework: .unknown), .dev)
    }
}

final class ProjectNamerTests: XCTestCase {

    func testReadsPackageJSONName() throws {
        let dir = NSTemporaryDirectory() + "portside-test-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let manifest = #"{"name": "my-cool-app", "version": "1.0.0"}"#
        FileManager.default.createFile(atPath: dir + "/package.json", contents: Data(manifest.utf8))
        XCTAssertEqual(ProjectNamer.projectName(cwd: dir), "my-cool-app")
    }

    func testRootAndHomeAreNotProjects() {
        XCTAssertNil(ProjectNamer.projectName(cwd: "/"))
        XCTAssertNil(ProjectNamer.projectName(cwd: NSHomeDirectory()))
    }
}
