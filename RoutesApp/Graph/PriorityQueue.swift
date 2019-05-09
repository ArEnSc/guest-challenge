//
//  PriorityQueue.swift
//  RoutesApp
//
//  Created by Michael Chung on 5/8/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import Foundation

protocol Queue {
    associatedtype T
    mutating func enqueue(_ element:T) -> Bool
    mutating func dequeue() -> T?
    var isEmpty:Bool { get }
    var peek:T? { get }
}


struct PriorityQueue<T:Equatable>: Queue {
    
    private var backingStore: Heap<T>
    
    init(sort:@escaping(T,T) -> Bool,elements:[T] = []) {
        backingStore = Heap(sort:sort, elements:elements)
        
    }
    
    var isEmpty: Bool {
        return backingStore.isEmpty
    }
    
    var peek: T? {
        return backingStore.peek()
    }
    
    mutating func enqueue(_ element: T) -> Bool {
        backingStore.insert(element)
        return true
    }
    
    mutating func dequeue() -> T? {
        return backingStore.remove()
    }
}
