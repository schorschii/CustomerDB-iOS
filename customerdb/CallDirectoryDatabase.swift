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
        //"CREATE TABLE IF NOT EXISTS error_log (id INTEGER PRIMARY KEY AUTOINCREMENT, text VARCHAR NOT NULL);",
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
        let sql = "SELECT id, display_name, phone_number FROM insert_number ORDER BY CAST(phone_number AS INTEGER)"
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
    
    func getNumber(phoneNumber: String) -> CallDirectoryNumber? {
        var number:CallDirectoryNumber? = nil
        var stmt:OpaquePointer?
        let sql = "SELECT id, display_name, phone_number FROM insert_number WHERE phone_number = ?"
        if sqlite3_prepare(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
            let phoneNumber = phoneNumber as NSString
            sqlite3_bind_text(stmt, 1, phoneNumber.utf8String, -1, nil)
            while sqlite3_step(stmt) == SQLITE_ROW {
                number = CallDirectoryNumber(
                    displayName: String(cString: sqlite3_column_text(stmt, 1)),
                    phoneNumber: String(cString: sqlite3_column_text(stmt, 2))
                )
            }
        }
        return number
    }
    
    // it is important to trim non-number chars so that ORDER BY works correctly
    // iOS throws an error if the numbers are not delivered correctly...
    let NUMBER_CHARS : Set<Character> = Set("1234567890")
    func insertNumber(_ number: CallDirectoryNumber) {
        let displayName = number.mDisplayName
        let phoneNumber = number.mPhoneNumber.filter {NUMBER_CHARS.contains($0)}
        
        if(number.mDisplayName.trimmingCharacters(in: .whitespacesAndNewlines) == ""
        || number.mPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) == ""
        || getNumber(phoneNumber: phoneNumber) != nil) {
            return
        }
        
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "INSERT INTO insert_number (customer_id, display_name, phone_number) VALUES (?,?,?)", -1, &stmt, nil) == SQLITE_OK {
            let displayName1 = displayName as NSString
            let phoneNumber1 = phoneNumber as NSString
            sqlite3_bind_int64(stmt, 1, number.mCustomerId)
            sqlite3_bind_text(stmt, 2, displayName1.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, phoneNumber1.utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
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
