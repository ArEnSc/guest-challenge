//
//  Heap.swift
//  RoutesApp
//
//  Created by Michael Chung on 5/8/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import Foundation
/**
 var heap = Heap(sort: <, elements: [1,12,3,4,1,6,8,7])
 while !heap.isEmpty {
    print(heap.remove())
 }
 
 
 remove 0(log n)
 insert 0(log n)
 search 0(n)
 peak 0(1)
 
 **/
struct Heap<T: Equatable> {
    var elements: [T] = []
    let sort: (T,T) -> Bool
    
    init(sort:@escaping (T,T)->Bool,elements:[T] = []) {
        self.sort = sort
        self.elements = elements
        
        if !elements.isEmpty {
            for i in (0 ..< elements.count / 2).reversed() {
                siftDown(from: i)
            }
        }
    }
    
    var isEmpty:Bool {
        return elements.isEmpty
    }
    
    var count: Int {
        return elements.count
    }
    
    func peek() -> T? {
        return elements.first
    }
    
    func leftChildIndex(ofParentAt index:Int) -> Int {
        return (2 * index) + 1
    }
    
    func rightChildIndex(ofParentAt index:Int) -> Int {
        return (2 * index) + 2
    }
    
    func parentIndex(ofChildAt index:Int) -> Int {
        return (index - 1) / 2
    }
    
    mutating func remove() -> T? {
        guard !isEmpty else {
            return nil
        }
        elements.swapAt(0, count - 1)
        
        defer {
            siftDown(from: 0)
        }
        
        return elements.removeLast()
    }
    
    mutating func siftDown(from index:Int) {
        var parent = index
        while true {
            let left = leftChildIndex(ofParentAt: parent)
            let right = rightChildIndex(ofParentAt: parent)
            var candidate:Int = parent
            
            if left < count && sort(elements[left], elements[candidate]) {
                candidate = left
            }
            
            if right < count && sort(elements[right], elements[candidate]) {
                candidate = right
            }
            
            if candidate == parent {
                return
            }
            
            elements.swapAt(parent, candidate)
            parent = candidate
        }
    }
    
    mutating func insert(_ element:T) {
        elements.append(element)
        siftUp(from: elements.count - 1)
    }
    
    mutating func siftUp(from index:Int) {
        var child = index
        var parent = parentIndex(ofChildAt:  child)
        while child > 0 && sort(elements[child],elements[parent]) {
            elements.swapAt(child, parent)
            child = parent
            parent = parentIndex(ofChildAt: child)
        }
    }
    
    mutating func remove(at index:Int) -> T? {
        guard index < elements.count else {
            return nil
        }
        
        if index == elements.count - 1 {
            return elements.removeLast()
        } else {
            elements.swapAt(index, elements.count-1)
            defer {
                siftDown(from: index)
                siftUp(from: index)
            }
            return elements.removeLast()
        }
    }
    
    func index(of element:T, startingAt i:Int) -> Int? {
        if i >= count {
            return nil
        }
        if sort(element, elements[i]) {
            return nil
        }
        if element == elements[i] {
            return i
        }
        if let j = index(of: element, startingAt: leftChildIndex(ofParentAt: i)) {
            return j
        }
        if let j = index(of: element, startingAt: rightChildIndex(ofParentAt: i)) {
            return j
        }
        return nil
    }
    
    
}
