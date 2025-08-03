import XCTest
@testable import pomeogo

final class ProjectTests: XCTestCase {
    func testProjectInit() {
        let project = Project(name: "测试项目")
        XCTAssertEqual(project.name, "测试项目")
    }
} 