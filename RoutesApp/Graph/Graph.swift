//
//  Graph.swift
//  RoutesApp
//
//  Created by Michael Chung on 5/7/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import Foundation

struct Vertex<T:Equatable>:Hashable {
    var data:T
    
    public var hashValue: Int {
        return "\(data)".hashValue
    }

    static public func == (lhs: Vertex,rhs:Vertex) -> Bool {
        return lhs.data == rhs.data
    }
}

public enum EdgeType {
    case directed, undirected
}

struct Edge<T:Hashable>: Comparable {
    
    static func < (lhs: Edge<T>, rhs: Edge<T>) -> Bool {
        let a = lhs.weight
        let b = rhs.weight
        return a < b
    }
    
    public var source: Vertex<T>
    public var destination: Vertex<T>
    public let weight:Double
    
    static public func == (lhs: Edge<T>,rhs: Edge<T>) -> Bool {
        return lhs.source == rhs.source &&
               lhs.destination == rhs.destination &&
               lhs.weight == rhs.weight
    }
}

protocol Graphable {
    associatedtype Element: Hashable

    var description: CustomStringConvertible { get }
    
    func createVertex(data: Element) -> Vertex<Element>
    func add(_ type: EdgeType, from source: Vertex<Element>, to destination: Vertex<Element>, weight: Double)
    func weight(from source: Vertex<Element>, to destination: Vertex<Element>) -> Double
    func edges(from source: Vertex<Element>) -> [Edge<Element>]
}

class AdjacencyList<T: Hashable>: Graphable {
    typealias Element = T
    
    public var backingStore : [Vertex<T>: [Edge<T>]] = [:]
    public init() {}
    
    var description: CustomStringConvertible {
        var result = ""
        
        // Outgoing Edges
        for (vertex, edges) in backingStore {
            var edgeString = ""
            for (index, edge) in edges.enumerated() {
                let dest = edge.destination as? Vertex<Airport>
    
                if index != edges.count - 1 {
                    edgeString.append("\(dest!.data.IATAThree),")
                } else {
                    edgeString.append("\(dest!.data.IATAThree)")
                }
            }
            
            let v = vertex.data as? Airport
            result.append("\(v!.IATAThree) ---> [ \(edgeString) ] \(edges.count) \n ")
        }
        return result
    }
    
    fileprivate func addDirectedEdge(from source: Vertex<Element>, to destination: Vertex<Element>, weight: Double) {
        let edge = Edge(source: source, destination: destination, weight: weight)
        backingStore[source]?.append(edge)
    }
    
    fileprivate func addUndirectedEdge(vertices: (Vertex<Element>, Vertex<Element>), weight: Double) {
        let (source, destination) = vertices
        addDirectedEdge(from: source, to: destination, weight: weight)
        addDirectedEdge(from: destination, to: source, weight: weight)
    }

    func createVertex(data: T) -> Vertex<T> {
        let vertex = Vertex(data: data)
        
        if backingStore[vertex] == nil {
            backingStore[vertex] = []
        }
        
        return vertex
    }
    
    func add(_ type: EdgeType, from source: Vertex<Element>, to destination: Vertex<Element>, weight: Double) {
        switch type {
            case .directed:
                addDirectedEdge(from: source, to: destination, weight: weight)
            case .undirected:
                addUndirectedEdge(vertices: (source, destination), weight: weight)
        }
    }
    
    func weight(from source: Vertex<Element>, to destination: Vertex<Element>) -> Double {
        guard let edges = backingStore[source] else { return 0.0 }
        
        for edge in edges {
            if edge.destination == destination {
                return edge.weight
            }
        }
        
        return 0.0
    }
    
    func edges(from source: Vertex<Element>) -> [Edge<Element>] {
        return backingStore[source] ?? []
    }
}


