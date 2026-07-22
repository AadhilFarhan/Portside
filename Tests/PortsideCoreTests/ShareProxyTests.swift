import XCTest
@testable import PortsideCore

final class ShareProxyTests: XCTestCase {

    func testRejectsPortZero() {
        XCTAssertThrowsError(try ShareProxy(targetPort: 0)) { error in
            XCTAssertEqual(error as? ShareProxyError, .invalidPort(0))
        }
    }

    func testRejectsNegativePort() {
        XCTAssertThrowsError(try ShareProxy(targetPort: -1)) { error in
            XCTAssertEqual(error as? ShareProxyError, .invalidPort(-1))
        }
    }

    func testRejectsPortAboveValidRange() {
        XCTAssertThrowsError(try ShareProxy(targetPort: 70000)) { error in
            XCTAssertEqual(error as? ShareProxyError, .invalidPort(70000))
        }
    }
}
