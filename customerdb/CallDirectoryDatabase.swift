//
//  CallDirectoryDatabase.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import SQLite3

class CallDirectoryDatabase {
    
    static var DB_FILE = "calldirext.sqlite"
    static var CREATE_DB_STATEMENTS = [
        "CREATE TABLE IF NOT EXISTS insert_number (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, display_name VARCHAR NOT NULL, phone_number VARCHAR NOT NULL);",
        //"INSERT INTO insert_number (customer_id, display_name, phone_number) VALUES (0, 'schorschii', '1234');"
    ]
    
    var db: OpaquePointer?
    
    init() {
        if let fileurl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.sieber.systems.customerdb")?
            .appendingPathComponent(CallDirectoryDatabase.DB_FILE) {
            if(sqlite3_open(fileurl.path, &db) != SQLITE_OK) {
                print("error opening database "+fileurl.path)
            }
            for query in CallDirectoryDatabase.CREATE_DB_STATEMENTS {
                if(sqlite3_exec(db, query, nil,nil,nil) != SQLITE_OK) {
                    print("error creating table: "+String(cString: sqlite3_errmsg(db)!))
                }
            }
        }
    }
    
    func getNumbers() -> [CallDirectoryNumber] {
        var entries:[CallDirectoryNumber] = []
        var stmt:OpaquePointer?
        let sql = "SELECT id, display_name, phone_number FROM insert_number"
        if sqlite3_prepare(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                entries.append(
                    CallDirectoryNumber(
                        displayName: String(cString: sqlite3_column_text(stmt, 1)),
                        phoneNumber: String(cString: sqlite3_column_text(stmt, 2))
                    )
                )
            }
        }
        return entries
    }
    
    func insertNumber(insertNumbers: [CallDirectoryNumber]) -> Bool {
        var stmt:OpaquePointer?
        for insertNumber in insertNumbers {
            if sqlite3_prepare(self.db, "INSERT INTO insert_number (customer_id, display_name, phone_number) VALUES (?,?,?)", -1, &stmt, nil) == SQLITE_OK {
                let displayName = insertNumber.mDisplayName as NSString
                let phoneNumber = insertNumber.mPhoneNumber as NSString
                sqlite3_bind_int64(stmt, 1, insertNumber.mCustomerId)
                sqlite3_bind_text(stmt, 2, displayName.utf8String, -1, nil)
                sqlite3_bind_text(stmt, 3, phoneNumber.utf8String, -1, nil)
                if sqlite3_step(stmt) == SQLITE_DONE {
                    sqlite3_finalize(stmt)
                }
            }
        }
        return true
    }
    
    func truncateNumbers() {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM insert_number WHERE 1 = 1", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }

}
