// Copyright (c) 2026 Wormholy contributors
// SPDX-License-Identifier: MIT

struct WebSocketMessageRingBuffer {
    private var storage = ContiguousArray<WebSocketMessage?>()
    private var head = 0
    private var tail = 0
    private var count = 0

    mutating func append(_ message: WebSocketMessage, limit: Int?) {
        if let limit, limit <= 0 {
            removeAll()
            return
        }

        ensureCapacity(for: count + 1)
        storage[tail] = message
        tail = advancedIndex(tail)
        count += 1

        if let limit {
            while count > limit {
                removeFirst()
            }
        }
    }

    mutating func drain() -> [WebSocketMessage] {
        let messages = (0..<count).compactMap { storage[(head + $0) & mask] }
        removeAll()
        return messages
    }

    private var mask: Int {
        storage.count - 1
    }

    private func advancedIndex(_ index: Int) -> Int {
        (index + 1) & mask
    }

    private mutating func removeFirst() {
        storage[head] = nil
        head = advancedIndex(head)
        count -= 1
    }

    private mutating func removeAll() {
        while count > 0 {
            removeFirst()
        }
        head = 0
        tail = 0
    }

    private mutating func ensureCapacity(for requiredCount: Int) {
        if storage.isEmpty {
            storage = ContiguousArray(repeating: nil, count: 2)
            return
        }
        guard storage.count < requiredCount else { return }

        var resized = ContiguousArray<WebSocketMessage?>(repeating: nil, count: storage.count * 2)
        for offset in 0..<count {
            resized[offset] = storage[(head + offset) & mask]
        }
        storage = resized
        head = 0
        tail = count
    }
}
