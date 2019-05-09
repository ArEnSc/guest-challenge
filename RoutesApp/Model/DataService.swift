//
//  DataSerializer.swift
//  RoutesApp
//
//  Created by Michael Chung on 5/7/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import Foundation
import Promises

class DataService {
    static let shared = DataService()
    let queue: DispatchQueue = DispatchQueue(label: "com.data.airport")
    
    fileprivate func readCommaSeparatedValues(with fileName: String) -> [[String]]? {
        guard let filepath = Bundle.main.path(forResource: "Data/\(fileName)", ofType: "csv")
            else {
                return nil
        }
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            var cleanFile = contents.replacingOccurrences(of: "\r", with: "\n")
            cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
            let cleanContents = csv(data: cleanFile)
            
            return cleanContents
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }
    
    fileprivate func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }
    
    func getAirlines() -> Promise<[Airline]> {
        return Promise<[Airline]>(on:queue, { (fullfill,reject) in
            
            guard let airlines = self.readCommaSeparatedValues(with: "airlines")?.compactMap({ (row) -> Airline in
                return Airline(name: row[0], twoDigitCode: row[1], threeDigitCode: row[2], country: row[3])
            })
            else {
                fullfill([])
                return
            }
            
            var result = airlines
            result.removeFirst()
            
            fullfill(result)
        })
      
    }
    
    // filter out /N
    func getAirports() -> Promise<[Airport]> {
        return Promise<[Airport]>(on: queue, { (fullfill,reject) in
            
            guard let airports = self.readCommaSeparatedValues(with: "airports")?.compactMap({ (row) -> Airport in
                return Airport(name: row[0], city:row[1] ,country:row[2],IATAThree:row[3] ,lat:Double(row[4]) ?? 0.0,long:Double(row[5]) ?? 0.0)
            })
            else {
                let empty:[Airport] = []
                fullfill(empty)
                return
            }
            
            var result = airports.filter { (airport) -> Bool in
                
                if airport.IATAThree == "\\N" {
                    return false
                }
                
                return true
            }
            result.removeFirst()
            fullfill(result)
        })
    }
    
    func getRoutes() -> Promise<[Route]> {
        return Promise<[Route]>(on: queue, { (fullfill,reject) in
            
            guard let routes = self.readCommaSeparatedValues(with: "routes")?.compactMap({ (row) -> Route in
                return Route(airlineId:row[0],origin:row[1], destination:row[2])
            }) else {
                fullfill([])
                return
            }
            
            var result = routes
            result.removeFirst()
            
            fullfill(result)
        })
    }
    
    
    
}
