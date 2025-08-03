import Foundation
import CloudKit

class CloudKitHelper: ObservableObject {
    private let container: CKContainer
    private let database: CKDatabase
    @Published var isSignedIn = false
    @Published var error: Error?
    
    init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
        checkAccountStatus()
    }
    
    private func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = error
                    self?.isSignedIn = false
                    return
                }
                self?.isSignedIn = status == .available
            }
        }
    }
    func save(_ record: CKRecord) async throws {
        try await database.save(record)
    }
    func delete(_ recordID: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: recordID)
    }
    func subscribe(to recordType: String) async throws {
        let subscriptionID = "subscription_\(recordType)"
        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
        )
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        try await database.save(subscription)
    }
    func unsubscribe(from recordType: String) async throws {
        let subscriptionID = "subscription_\(recordType)"
        try await database.deleteSubscription(withID: subscriptionID)
    }
} 
