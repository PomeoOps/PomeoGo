import SwiftUI

@main
struct PomeoGoApp: App {
    // @StateObject private var cloudKitHelper = CloudKitHelper()
    // private var syncService: SyncService!
    @StateObject private var dataManager = DataManager.shared
    
    init() {
        // syncService = SyncService(cloudKitHelper: cloudKitHelper, dataManager: dataManager)
    }
    
    var body: some Scene {
        WindowGroup {
            MainSplitView(dataManager: dataManager)
                .environmentObject(dataManager)
                .task {
                    // 初始化任务
                    // try await syncService.startSync()
                }
        }
    }
} 