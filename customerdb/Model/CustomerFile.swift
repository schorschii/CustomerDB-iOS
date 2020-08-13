//
//  CustomerFile.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class CustomerFile {
    var mName = ""
    var mContent:Data? = nil

    init(name:String, content:Data) {
        mName = name
        mContent = content
    }
}
