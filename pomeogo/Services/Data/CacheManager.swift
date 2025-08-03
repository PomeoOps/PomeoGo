import Foundation

// MARK: - 缓存管理器
class CacheManager {
    private let cache = NSCache<NSString, CacheEntry>()
    private let queue = DispatchQueue(label: "com.pomeogo.cache", attributes: .concurrent)
    private var allKeys = Set<String>()
    
    let maxCacheSize: Int64 = 50 * 1024 * 1024 // 50MB
    let maxCacheCount = 1000
    let defaultTTL: TimeInterval = 300 // 5分钟
    
    init() {
        cache.totalCostLimit = maxCacheCount
        startPeriodicCleanup()
    }
    
    // MARK: - 基本操作
    
    func setValue<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        queue.async(flags: .barrier) {
            let size = self.calculateSize(value)
            let entry = CacheEntry(
                value: value,
                timestamp: Date(),
                ttl: ttl ?? self.defaultTTL,
                size: size
            )
            
            self.cache.setObject(entry, forKey: key as NSString)
            self.allKeys.insert(key)
        }
    }
    
    func getValue<T: Codable>(forKey key: String) -> T? {
        return queue.sync {
            guard let entry = cache.object(forKey: key as NSString) else {
                return nil
            }
            
            if entry.isExpired {
                cache.removeObject(forKey: key as NSString)
                allKeys.remove(key)
                return nil
            }
            
            entry.updateLastAccessTime()
            
            if let value = entry.value as? T {
                return value
            }
            
            return nil
        }
    }
    
    func removeValue(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeObject(forKey: key as NSString)
            self.allKeys.remove(key)
        }
    }
    
    func exists(forKey key: String) -> Bool {
        return queue.sync {
            guard let entry = cache.object(forKey: key as NSString) else {
                return false
            }
            
            if entry.isExpired {
                cache.removeObject(forKey: key as NSString)
                allKeys.remove(key)
                return false
            }
            
            return true
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
            self.allKeys.removeAll()
        }
    }
    
    func cleanup() {
        queue.async(flags: .barrier) {
            let keysToRemove = self.allKeys.filter { key in
                guard let entry = self.cache.object(forKey: key as NSString) else {
                    return true
                }
                return entry.isExpired
            }
            
            for key in keysToRemove {
                self.cache.removeObject(forKey: key as NSString)
                self.allKeys.remove(key)
            }
            
            self.evictOldestIfNeeded()
        }
    }
    
    func getCacheSize() async -> Int64 {
        return await withCheckedContinuation { continuation in
            queue.async {
                var totalSize: Int64 = 0
                
                for key in self.allKeys {
                    if let entry = self.cache.object(forKey: key as NSString) {
                        totalSize += entry.size
                    }
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
    
    // MARK: - 私有辅助方法
    
    private func calculateSize<T: Codable>(_ value: T) -> Int64 {
        do {
            let data = try JSONEncoder().encode(value)
            return Int64(data.count)
        } catch {
            return 1024
        }
    }
    
    private func evictOldestIfNeeded() {
        // 由于这个方法已经在 queue.async(flags: .barrier) 上下文中调用，
        // 我们可以直接访问属性，不需要额外的同步
        var totalSize: Int64 = 0
        for key in allKeys {
            if let entry = cache.object(forKey: key as NSString) {
                totalSize += entry.size
            }
        }
        let currentSize = totalSize
        let currentCount = allKeys.count
        
        if currentSize > maxCacheSize || currentCount > maxCacheCount {
            let allEntries = allKeys.compactMap { key -> (String, CacheEntry)? in
                guard let entry = cache.object(forKey: key as NSString) else { return nil }
                return (key, entry)
            }.sorted { $0.1.lastAccessTime < $1.1.lastAccessTime }
            
            var removedSize: Int64 = 0
            var removedCount = 0
            
            for (key, entry) in allEntries {
                if (currentSize - removedSize) <= maxCacheSize && 
                   (currentCount - removedCount) <= maxCacheCount {
                    break
                }
                
                cache.removeObject(forKey: key as NSString)
                allKeys.remove(key)
                removedSize += entry.size
                removedCount += 1
            }
        }
    }
    
    private func getCacheCount() -> Int {
        return queue.sync {
            return allKeys.count
        }
    }
    
    private func startPeriodicCleanup() {
        DispatchQueue.global(qos: .background).async {
            while true {
                self.cleanup()
                Thread.sleep(forTimeInterval: 120)
            }
        }
    }
}

// MARK: - 缓存条目
class CacheEntry {
    let value: Any
    let timestamp: Date
    let ttl: TimeInterval
    let size: Int64
    private(set) var lastAccessTime: Date
    
    var isExpired: Bool {
        return Date().timeIntervalSince(lastAccessTime) > ttl
    }
    
    init(value: Any, timestamp: Date, ttl: TimeInterval, size: Int64) {
        self.value = value
        self.timestamp = timestamp
        self.ttl = ttl
        self.size = size
        self.lastAccessTime = timestamp
    }
    
    func updateLastAccessTime() {
        lastAccessTime = Date()
    }
} 