//
//  Airports.swift
//  RoutesApp
//
//  Created by Michael Chung on 5/7/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import Foundation

struct Airport:Equatable,Hashable {
    var name:String
    var city:String
    var country:String
    var IATAThree:String
    var lat:Double
    var long:Double
}
