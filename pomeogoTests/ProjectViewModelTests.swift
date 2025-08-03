import XCTest
@testable import pomeogo

@MainActor
class ProjectViewModelTests: XCTestCase {
    func testCreateProject() {
        let dataManager = DataManager()
        let vm = ProjectViewModel(dataManager: dataManager)
        
        let project = vm.createProject(name: "Test Project", description: "desc", epic: nil)
        XCTAssertEqual(project.name, "Test Project")
        XCTAssertEqual(vm.projects.count, 1)
    }
    
    func testUpdateProject() {
        let dataManager = DataManager()
        let vm = ProjectViewModel(dataManager: dataManager)
        
        let project = vm.createProject(name: "A", description: "B", epic: nil)
        project.name = "C"
        vm.updateProject(project)
        
        XCTAssertEqual(project.name, "C")
    }
    
    func testDeleteProject() {
        let dataManager = DataManager()
        let vm = ProjectViewModel(dataManager: dataManager)
        
        let project = vm.createProject(name: "A", description: nil, epic: nil)
        let initialCount = vm.projects.count
        vm.deleteProject(project)
        
        XCTAssertEqual(vm.projects.count, initialCount - 1)
    }
    
    func testCreateEpic() {
        let dataManager = DataManager()
        let vm = ProjectViewModel(dataManager: dataManager)
        
        let epic = vm.createEpic(name: "Epic1", description: "E")
        XCTAssertEqual(epic.name, "Epic1")
        XCTAssertEqual(vm.epics.count, 1)
    }
    
    func testUpdateEpic() {
        let dataManager = DataManager()
        let vm = ProjectViewModel(dataManager: dataManager)
        
        let epic = vm.createEpic(name: "Epic1", description: nil)
        epic.name = "Epic2"
        vm.updateEpic(epic)
        
        XCTAssertEqual(epic.name, "Epic2")
    }
    
    func testDeleteEpic() {
        let dataManager = DataManager()
        let vm = ProjectViewModel(dataManager: dataManager)
        
        let epic = vm.createEpic(name: "Epic1", description: nil)
        let initialCount = vm.epics.count
        vm.deleteEpic(epic)
        
        XCTAssertEqual(vm.epics.count, initialCount - 1)
    }
} 