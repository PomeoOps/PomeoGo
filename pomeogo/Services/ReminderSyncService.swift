import Foundation
import EventKit

class ReminderSyncService {
    static let shared = ReminderSyncService()
    private let eventStore = EKEventStore()
    private init() {}

    // MARK: - 权限申请
    func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestAccess(to: .reminder) { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }

    // MARK: - 读取 Apple Reminders
    func fetchReminders(completion: @escaping ([EKReminder]?, Error?) -> Void) {
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            DispatchQueue.main.async {
                completion(reminders, nil)
            }
        }
    }

    // MARK: - 写入 Apple Reminders（预留）
    func addReminder(title: String, completion: @escaping (Bool, Error?) -> Void) {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        do {
            try eventStore.save(reminder, commit: true)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
} 