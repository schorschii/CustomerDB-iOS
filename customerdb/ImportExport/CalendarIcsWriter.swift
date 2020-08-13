//
//  CalendarIcsWriter.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class CalendarIcsWriter {
    
    class IcsEntry {
        var mFields: [IcsField] = []
        init() {
        }
    }
    class IcsField {
        var mOptions: [String]
        var mValues: [String]
        init(options: [String], values: [String]) {
            mOptions = options
            mValues = values
        }
    }
    
    var mAppointments: [CustomerAppointment] = []
    
    init(appointments: [CustomerAppointment]) {
        mAppointments = appointments
    }
    
    static var ICS_FORMAT = "yyyyMMdd'T'HHmmss"
    static func format(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CalendarIcsWriter.ICS_FORMAT
        return dateFormatter.string(from: date)
    }
    static func parse(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CalendarIcsWriter.ICS_FORMAT
        return dateFormatter.date(from: strDate)
    }
    
    func buildIcsContent() -> String {
        var content = ""
        content += "BEGIN:VCALENDAR\n";
        content += "VERSION:2.0\n";
        for currentAppointment in mAppointments {
            content += "BEGIN:VEVENT\n";
            content += "SUMMARY:"+escapeIcsValue(currentAppointment.mTitle)+"\n";
            content += "DESCRIPTION:"+escapeIcsValue(currentAppointment.mNotes)+"\n";
            content += "LOCATION:"+escapeIcsValue(currentAppointment.mLocation)+"\n";
            content += "DTSTART:"+escapeIcsValue(CalendarIcsWriter.format(date: currentAppointment.mTimeStart!))+"\n";
            content += "DTEND:"+escapeIcsValue(CalendarIcsWriter.format(date: currentAppointment.mTimeEnd!))+"\n";
            content += "END:VEVENT\n";
        }
        content += "END:VCALENDAR\n\n";
        return content
    }
    
    private func escapeIcsValue(_ value:String) -> String {
        return value.replacingOccurrences(of: "\n", with: "\\n")
    }
    
    private static let ICS_FIELDS: [String] = [
            "PROID", "METHOD", "BEGIN", "TZID", "DTSTART", "DTEND", "DTSTAMP", "RRULE",
            "TZOFFSETFROM", "TZOFFSETTO", "END", "UID", "ORGANIZER", "LOCATION", "GEO",
            "SUMMARY", "DESCRIPTION", "CLASS", "VERSION"
    ]
    private static func isIcsField(_ text: String) -> Bool {
        let upperText = text.uppercased()
        let keyValue = upperText.split(separator: ":")
        if(keyValue.count >= 1) {
            let subKeys = keyValue[0].split(separator: ";")
            if(String(subKeys[0]).starts(with: "X-")) {
                return true
            }
            for field in ICS_FIELDS {
                if(String(subKeys[0]).starts(with: field)) {
                    return true
                }
            }
        }
        return false
    }
    
    static func readIcsFile(url: URL) -> [CustomerAppointment] {
        var text = ""
        
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch let error {
            print(error.localizedDescription)
            return []
        }
        
        // STEP 0 : an ics field can be broken up into multiple lines
        // we concatenate them here into a single line again
        var icsFields: [String] = []
        var currFieldValue = ""
        text.enumerateLines { line, _ in
            if(isIcsField(line)) {
                if(currFieldValue.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
                    icsFields.append(currFieldValue)
                }
                currFieldValue = line.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                var append = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // avoid the double equal sign hell
                if(append.starts(with: "=") && currFieldValue.hasSuffix("=")) {
                    append.remove(at: append.startIndex)
                }
                currFieldValue += append
            }
        }
        if(currFieldValue.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
            icsFields.append(currFieldValue)
        }
        
        // STEP 1 : parse ICS string into structured data
        var tempIcsEntry: IcsEntry? = nil
        var tempIcsEntries: [IcsEntry] = []
        for line in icsFields {
            let upperLine = line.uppercased()
            if(upperLine.starts(with: "BEGIN:VEVENT")) {
                tempIcsEntry = IcsEntry()
            }
            if(upperLine.starts(with: "END:VEVENT")) {
                if(tempIcsEntry != nil) {
                    tempIcsEntries.append(tempIcsEntry!)
                }
                tempIcsEntry = nil
            }
            if(tempIcsEntry != nil) {
                let keyValue = line.split(separator: ":", maxSplits: 2)
                if(keyValue.count != 2) { continue }
                let options = keyValue[0].components(separatedBy: ";")
                let values = keyValue[1].components(separatedBy: ";")
                if(QuotedPrintable.isVcfFieldQuotedPrintableEncoded(fieldOptions: options)) {
                    // decode quoted printable encoded fields
                    var decodedValuesList: [String] = []
                    for v in values {
                        if let decoded = v.decodeQuotedPrintable() {
                            decodedValuesList.append(decoded)
                        }
                    }
                    tempIcsEntry!.mFields.append(IcsField(options: options, values: decodedValuesList))
                } else {
                    tempIcsEntry!.mFields.append(IcsField(options: options, values: values))
                }
            }
        }
        
        // STEP 2 : create appointments from ICS data
        var newAppointments: [CustomerAppointment] = []
        for e in tempIcsEntries {
            let newAppointment = CustomerAppointment()

            // apply all ICS fields
            for f in e.mFields {
                switch(f.mOptions[0].uppercased()) {
                    case "SUMMARY":
                        if(f.mValues.count >= 1) { newAppointment.mTitle = f.mValues[0] }
                        break

                    case "DESCRIPTION":
                        if(f.mValues.count >= 1) { newAppointment.mNotes = f.mValues[0] }
                        break

                    case "LOCATION":
                        newAppointment.mLocation = f.mValues[0]
                        break

                    case "DTSTART":
                        newAppointment.mTimeStart = CalendarIcsWriter.parse(strDate: f.mValues[0])
                        break

                    case "DTEND":
                        newAppointment.mTimeEnd = CalendarIcsWriter.parse(strDate: f.mValues[0])
                        break
                    
                    default:
                        break
                }
            }

            // only add if name is not empty
            if(newAppointment.mTitle != "" && newAppointment.mTimeStart != nil && newAppointment.mTimeEnd != nil) {
                newAppointments.append(newAppointment)
            }
        }

        return newAppointments
    }
    
}
