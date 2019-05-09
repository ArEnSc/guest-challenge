//
//  AirportPathFinder.swift
//  RoutesApp
//
//  Created by Michael Chung on 5/8/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import Foundation
import Promises

enum Visit<T:Hashable> {
    case start
    case edge(Edge<T>)
}

public class Dijkstra<T:Hashable> {
    typealias Graph = AdjacencyList<T>
    let graph: Graph
    
    init(graph:Graph) {
        self.graph = graph
    }
    
    private func route(to destination: Vertex<T>, with paths:[Vertex<T> : Visit<T>]) -> [Edge<T>] {
        var vertex = destination
        var path:[Edge<T>] = []
        
        while let visit = paths[vertex],
            case .edge(let edge) = visit {
            path = [edge] + path
            vertex = edge.source
        }
        
        return path
    }
    
    private func distance(to destination:Vertex<T>,with paths:[Vertex<T> : Visit<T>]) -> Double {
        let path = route(to: destination, with: paths)
        let distances = path.compactMap { $0.weight }
        let result = distances.reduce(0.0, +)
        return result
    }
    
    func shortestPath(from start:Vertex<T>) -> [Vertex<T>:Visit<T>] {
        var paths: [Vertex<T> : Visit<T>] = [start: .start]
        
        var priorityQueue = PriorityQueue<Vertex<T>>.init(sort:{ (d1,d2) -> Bool in
            return self.distance(to: d1, with: paths) < self.distance(to: d2, with: paths)
        })
        
        _ = priorityQueue.enqueue(start)
        
        while let vertex = priorityQueue.dequeue() {
            for edge in graph.edges(from: vertex) {
                let weight = edge.weight
                
                if paths[edge.destination] == nil ||
                    distance(to: vertex, with: paths) + weight <
                    distance(to: edge.destination, with: paths) {
                    paths[edge.destination] = .edge(edge)
                    _ = priorityQueue.enqueue(edge.destination)
                }
            }
        }
        
        return paths
    }
    
    func shortestPath(to destination:Vertex<T>,pathes:[Vertex<T> : Visit <T>]) -> [Edge<T>] {
        return route(to: destination, with: pathes)
    }
    
}

protocol Routable {
    var vertexA:VertexId { get }
    var vertexB:VertexId { get }
    var weight:Double { get }
}

protocol VertexId {
    var id:String { get }
}

class AirPortPathFinder {
   
    // localize these IRL ;D
    enum Error:String, Swift.Error, LocalizedError  {
        case airportNotFound = "Airport Not Found Try Again"
        case vertexNotFound = "Internal Error"
        case NoRouteBetweenAirports = "No Route Between Airports"
        
        public var errorDescription: String? {
            return self.rawValue
        }
    }
    
    var globalGraph:AdjacencyList<Airport>
    
    var queue:DispatchQueue = DispatchQueue(label: "com.airport.path.finder")
    
    var vertexLookup:[String:Vertex<Airport>] = [String:Vertex<Airport>]()
    var pathFinder:Dijkstra<Airport>
    
    init(airports:[Airport], routes:[Route]) {
        
        globalGraph = AdjacencyList()
        
        self.pathFinder = Dijkstra(graph: globalGraph)
        
        for airport in airports {
            let vertex = globalGraph.createVertex(data: airport)
            vertexLookup[vertex.data.IATAThree] = vertex
        }
        
        for route in routes {
            if let v1 = vertexLookup[route.origin],
                let v2 = vertexLookup[route.destination] {
                globalGraph.add(.directed, from: v1, to: v2, weight: 1)
            }
        }
        
    }
    
    func airportExists(name: String) -> Promise<Airport> {
        return Promise(on: queue, { (fullfill, reject) in
            
        })
    }

    private func shortestPathBetween(origin:Airport, destination:Airport)-> Promise <[Edge<Airport>]>{
        return Promise(on: queue, { (fullfill,reject) in
            
            guard let v1 = self.vertexLookup[origin.IATAThree],
                let v2 = self.vertexLookup[destination.IATAThree] else {
                reject(Error.vertexNotFound)
                return
            }
            
            let pathes = self.pathFinder.shortestPath(from: v1)
            let path = self.pathFinder.shortestPath(to: v2, pathes: pathes)
            
            if path.count == 0 {
                reject(Error.NoRouteBetweenAirports)
                return
            } else {
                fullfill(path)
                return
            }
           
        })
    }
    
    private func pathList(for path:[Edge<Airport>]) -> Promise<[String]> {
        return Promise(on:queue,{ (fullfill,reject) in
            
            var result = [String]()
            
            for (idx,edge) in path.enumerated() {
                if idx == path.count-1 {
                    result.append(edge.source.data.IATAThree)
                    result.append(edge.destination.data.IATAThree)
                } else {
                    result.append(edge.source.data.IATAThree)
                }
            }
            
            fullfill(result)
            
        })
    }
    
    // Performs look up for the airports
    private func airports(for IATAThrees:[String]) -> Promise<[Airport]> {
        return Promise(on:queue, { (fullfill,reject) in
            var result = [Airport]()
            for i in IATAThrees {
                if let data = self.vertexLookup[i]?.data {
                    result.append(data)
                } else {
                    continue
                }
            }
            fullfill(result)
        })
    }
    
    // This is the function to call to get a list of airports
    public func airportPathesBetween(origin:Airport, destination:Airport) -> Promise<[Airport]> {
        return Promise<[Airport]> { () -> [Airport] in
            
            let path = try await(self.shortestPathBetween(origin: origin, destination: destination))
            let IATAThrees = try await(self.pathList(for: path))
            let airports = try await(self.airports(for: IATAThrees))
            
            return airports
        }
    }
}
