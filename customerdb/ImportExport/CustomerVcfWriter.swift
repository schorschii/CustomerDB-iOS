//
//  VcfWriter.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class CustomerVcfWriter {
    
    class VcfEntry {
        var mFields: [VcfField] = []
        init() {
        }
    }
    class VcfField {
        var mOptions: [String]
        var mValues: [String]
        init(options: [String], values: [String]) {
            mOptions = options
            mValues = values
        }
    }
    
    var mCustomers: [Customer] = []
    
    init(customers: [Customer]) {
        mCustomers = customers
    }
    
    static var FORMAT_WITHOUT_DASHES = "yyyyMMdd" // vCard 4.0
    static var FORMAT_WITH_DASHES = "yyyy-MM-dd" // vCard 2.1, 3.0, 4.0
    static func formatWithoutDashesRaw(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerVcfWriter.FORMAT_WITHOUT_DASHES
        return dateFormatter.string(from: date)
    }
    private static func parseVcfDateRaw(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        if(strDate.trimmingCharacters(in: .whitespacesAndNewlines).count == 10) {
            dateFormatter.dateFormat = CustomerVcfWriter.FORMAT_WITH_DASHES
        } else {
            dateFormatter.dateFormat = CustomerVcfWriter.FORMAT_WITHOUT_DASHES
        }
        return dateFormatter.date(from:strDate)
    }
    
    func buildVcfContent() -> String {
        var content = ""

        for currentCustomer in mCustomers {
            content += "BEGIN:VCARD\n";
            content += "VERSION:2.1\n";
            content += "FN;ENCODING=QUOTED-PRINTABLE:"+escapeVcfValue(currentCustomer.mTitle)+" "+escapeVcfValue(currentCustomer.mFirstName)+" "+escapeVcfValue(currentCustomer.mLastName)+"\n";
            content += "N;ENCODING=QUOTED-PRINTABLE:"+escapeVcfValue(currentCustomer.mLastName)+";"+escapeVcfValue(currentCustomer.mFirstName)+";;"+escapeVcfValue(currentCustomer.mTitle)+";\n";
            if(currentCustomer.mPhoneHome != "") {
                content += "TEL;HOME:"+escapeVcfValue(currentCustomer.mPhoneHome)+"\n";
            }
            if(currentCustomer.mPhoneMobile != "") {
                content += "TEL;CELL:"+escapeVcfValue(currentCustomer.mPhoneMobile)+"\n";
            }
            if(currentCustomer.mPhoneWork != "") {
                content += "TEL;WORK:"+escapeVcfValue(currentCustomer.mPhoneWork)+"\n";
            }
            if(currentCustomer.mEmail != "") {
                content += "EMAIL;INTERNET:"+currentCustomer.mEmail+"\n";
            }
            if(currentCustomer.getAddressString() != "") {
                content += "ADR;TYPE=HOME:"+";;"+escapeVcfValue(currentCustomer.mStreet)+";"+escapeVcfValue(currentCustomer.mCity)+";;"+escapeVcfValue(currentCustomer.mZipcode)+";"+escapeVcfValue(currentCustomer.mCountry)+"\n";
            }
            if(currentCustomer.mGroup != "") {
                content += "ORG:"+escapeVcfValue(currentCustomer.mGroup)+"\n";
            }
            if(currentCustomer.mBirthday != nil) {
                content += "BDAY:"+CustomerVcfWriter.formatWithoutDashesRaw(date:currentCustomer.mBirthday!)+"\n";
            }
            if(currentCustomer.mNotes != "") {
                content += "NOTE;ENCODING=QUOTED-PRINTABLE:"+escapeVcfValue(currentCustomer.mNotes)+"\n";
            }
            if(currentCustomer.mCustomFields != "") {
                content += "X-CUSTOM-FIELDS:"+escapeVcfValue(currentCustomer.mCustomFields)+"\n";
            }
            if(currentCustomer.mImage != nil && currentCustomer.mImage!.count > 0) {
                content += "PHOTO;ENCODING=BASE64;JPEG:"+currentCustomer.mImage!.base64EncodedString()+"\n"
            }
            content += "END:VCARD\n\n";
        }

        return content
    }
    
    private func escapeVcfValue(_ value:String) -> String {
        return value.replacingOccurrences(of: "\n", with: "\\n")
    }
    
    private static let VCF_FIELDS: [String] = [
            // thanks, Wikipedia
            "ADR", "AGENT", "ANNIVERSARY",
            "BDAY", "BEGIN", "BIRTHPLACE",
            "CALADRURI", "CALURI", "CATEGORIES", "CLASS", "CLIENTPIDMAP",
            "DEATHDATE", "DEATHPLACE",
            "EMAIL", "END", "EXPERTISE",
            "FBURL", "FN",
            "GENDER", "GEO",
            "HOBBY",
            "IMPP", "INTEREST",
            "KEY", "KIND",
            "LABEL", "LANG", "LOGO",
            "MAILER", "MEMBER",
            "N", "NAME", "NICKNAME", "NOTE",
            "ORG", "ORG-DIRECTORY",
            "PHOTO", "PROID", "PROFILE",
            "RELATED", "REV", "ROLE",
            "SORT-STRING", "SOUND", "SOURCE",
            "TEL", "TITLE", "TZ",
            "UID", "URL",
            "VERSION",
            "XML"
    ]
    private static func isVcfField(_ text: String) -> Bool {
        let upperText = text.uppercased()
        let keyValue = upperText.split(separator: ":")
        if(keyValue.count >= 1) {
            let subKeys = keyValue[0].split(separator: ";")
            if(String(subKeys[0]).starts(with: "X-")) {
                return true
            }
            for field in VCF_FIELDS {
                if(String(subKeys[0]).starts(with: field)) {
                    return true
                }
            }
        }
        return false
    }
    
    static func readVcfFile(url: URL) -> [Customer] {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            return readVcfString(text: text)
        } catch let error {
            print(error.localizedDescription)
            return []
        }
    }
    static func readVcfString(text: String) -> [Customer] {
        // STEP 0 : a vcf field can be broken up into multiple lines
        // we concatenate them here into a single line again
        var vcfFields: [String] = []
        var currFieldValue = ""
        text.enumerateLines { line, _ in
            if(isVcfField(line)) {
                if(currFieldValue.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
                    vcfFields.append(currFieldValue)
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
            vcfFields.append(currFieldValue)
        }
        
        // STEP 1 : parse VCF string into structured data
        var tempVcfEntry: VcfEntry? = nil
        var tempVcfEntries: [VcfEntry] = []
        for line in vcfFields {
            let upperLine = line.uppercased()
            if(upperLine.starts(with: "BEGIN:VCARD")) {
                tempVcfEntry = VcfEntry()
            }
            if(upperLine.starts(with: "END:VCARD")) {
                if(tempVcfEntry != nil) {
                    tempVcfEntries.append(tempVcfEntry!)
                }
                tempVcfEntry = nil
            }
            if(tempVcfEntry != nil) {
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
                    tempVcfEntry!.mFields.append(VcfField(options: options, values: decodedValuesList))
                } else {
                    tempVcfEntry!.mFields.append(VcfField(options: options, values: values))
                }
            }
        }
        
        // STEP 2 : create customers from VCF data
        var newCustomers: [Customer] = []
        for e in tempVcfEntries {
            var fullNameTemp = ""
            let newCustomer = Customer()

            // apply all VCF fields
            for f in e.mFields {
                switch(f.mOptions[0].uppercased()) {
                    case "FN":
                        if(f.mValues.count >= 1) { fullNameTemp = f.mValues[0] }
                        break

                    case "N":
                        if(f.mValues.count >= 1) { newCustomer.mLastName = f.mValues[0] }
                        if(f.mValues.count >= 2) { newCustomer.mFirstName = f.mValues[1] }
                        if(f.mValues.count >= 4) { newCustomer.mTitle = f.mValues[3] }
                        break

                    case "EMAIL":
                        if(f.mValues.count >= 1) { newCustomer.mEmail = f.mValues[0] }
                        break

                    case "ADR":
                        var street = ""
                        var zipcode = ""
                        var city = ""
                        var country = ""
                        if(f.mValues.count > 2) { street = f.mValues[2] }
                        if(f.mValues.count > 3) { city = f.mValues[3] }
                        if(f.mValues.count > 5) { zipcode = f.mValues[5] }
                        if(f.mValues.count > 6) { country = f.mValues[6] }
                        if(newCustomer.mStreet.trimmingCharacters(in: .whitespacesAndNewlines) == ""
                            && newCustomer.mZipcode.trimmingCharacters(in: .whitespacesAndNewlines) == ""
                            && newCustomer.mCity.trimmingCharacters(in: .whitespacesAndNewlines) == ""
                            && newCustomer.mCountry.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                            newCustomer.mStreet = street
                            newCustomer.mZipcode = zipcode
                            newCustomer.mCity = city
                            newCustomer.mCountry = country
                        } else {
                            addAdditionalInfoToDescription(currentCustomer: newCustomer, info: street + "\n" + zipcode + " " + city + "\n" + country)
                        }
                        break

                    case "TITLE", "URL", "NOTE":
                        addAdditionalInfoToDescription(currentCustomer: newCustomer, info: f.mValues[0])
                        break

                    case "X-CUSTOM-FIELDS":
                        newCustomer.mCustomFields = f.mValues[0]
                        break

                    case "TEL":
                        var telParam = ""
                        if(f.mOptions.count > 1) { telParam = f.mOptions[1].trimmingCharacters(in: .whitespacesAndNewlines) }
                        addTelephoneNumber(currentCustomer: newCustomer, telParam: telParam, telValue: f.mValues[0])
                        break

                    case "ORG":
                        newCustomer.mGroup = f.mValues[0]
                        break

                    case "BDAY":
                        newCustomer.mBirthday = parseVcfDateRaw(strDate: f.mValues[0])
                        break

                    case "PHOTO":
                        newCustomer.putAttribute(key: "image", value: String(f.mValues[0]))
                        break
                    
                    default:
                        break
                }
            }

            // apply name fallback if name is empty
            if(newCustomer.mFirstName == "" && newCustomer.mLastName == "") {
                newCustomer.mLastName = fullNameTemp
            }

            // only add if name is not empty
            if(!(newCustomer.mFirstName == "" && newCustomer.mLastName == "" && newCustomer.mTitle == "")) {
                newCustomers.append(newCustomer)
            }
        }

        return newCustomers
    }
    
    private static func addTelephoneNumber(currentCustomer: Customer, telParam: String, telValue: String) {
        let telParamUpper = telParam.uppercased()

        if(telParamUpper.starts(with: "HOME")) {

            if(currentCustomer.mPhoneHome.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                currentCustomer.mPhoneHome = telValue
            } else {
                addTelephoneNumberAlternative(currentCustomer: currentCustomer, telParam: telParam, telValue: telValue)
            }

        } else if(telParamUpper.starts(with: "CELL")) {

            if(currentCustomer.mPhoneMobile.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                currentCustomer.mPhoneMobile = telValue
            } else {
                addTelephoneNumberAlternative(currentCustomer: currentCustomer, telParam: telParam, telValue: telValue)
            }

        } else if(telParamUpper.starts(with: "WORK")) {

            if(currentCustomer.mPhoneWork.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                currentCustomer.mPhoneWork = telValue
            } else {
                addTelephoneNumberAlternative(currentCustomer: currentCustomer, telParam: telParam, telValue: telValue)
            }

        } else {

            if(currentCustomer.mPhoneHome == "") {
                currentCustomer.mPhoneHome = telValue;
            } else if(currentCustomer.mPhoneMobile == "") {
                currentCustomer.mPhoneMobile = telValue
            } else if(currentCustomer.mPhoneWork == "") {
                currentCustomer.mPhoneWork = telValue
            } else {
                addTelephoneNumberAlternative(currentCustomer: currentCustomer, telParam: telParam, telValue: telValue)
            }

        }
    }
    private static func addTelephoneNumberAlternative(currentCustomer: Customer, telParam: String, telValue: String) {
        addAdditionalInfoToDescription(currentCustomer: currentCustomer, info: telParam + ": " + telValue)
    }
    private static func addAdditionalInfoToDescription(currentCustomer: Customer, info: String) {
        currentCustomer.mNotes = (currentCustomer.mNotes + "\n\n" + info).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
