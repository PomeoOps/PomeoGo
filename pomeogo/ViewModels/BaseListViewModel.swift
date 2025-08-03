import Foundation
import Combine

class BaseListViewModel<ItemType: Identifiable & Equatable>: ObservableObject {
    @Published var items: [ItemType] = []
    @Published var selectedItem: ItemType?
    
    func add(_ item: ItemType) {
        items.append(item)
        objectWillChange.send()
    }
    
    func update(_ item: ItemType) {
        // 子类可重写
        objectWillChange.send()
    }
    
    func delete(_ item: ItemType) {
        items.removeAll { $0.id == item.id }
        objectWillChange.send()
    }
} 