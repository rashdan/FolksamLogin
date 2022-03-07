import Foundation

/// An enum to validate and extract information from a string that represents a Swedish Social Security Number.
/// It can have the following values:
///
/// - personnummer
/// - samordningsnummer
/// - organisationsnummer
/// - invalid
///
public enum SwedishSSN {
    ///  The string represents a valid `personnummer`. It also contains the information about the gender
    case personnummer(gender: Gender?)
    /// The string represents a valid `samordningsnummer`. It also contains the information about the gender
    case samordningsnummer(gender: Gender?)
    /// The string represents a valid `organisationsnummer`. It also contains the information about the company type
    case organisationsnummer(companyType: CompanyType)
    /// The string is invalid and cannot represent a `personnummer`, a `samordningsnummer` or an `organisationsnummer`
    case invalid

    /// The type that a company can have if it is an `organisationsnummer`
    /// Based on [WIkipedia](https://sv.wikipedia.org/wiki/Organisationsnummer), it can have the following values
    ///
    /// - dödsbon
    /// - offentlig
    /// - utländskaFöretag
    /// - aktiebolag
    /// - enkeltbolag
    /// - ekonomiskFörening
    /// - ideellFörening
    /// - handelsKommanditBolag
    /// - invalid
    public enum CompanyType {
        /// 1 – Dödsbon
        case dödsbon
        /// 2 – Stat, landsting, kommuner, församlingar
        case offentlig
        /// 3 – Utländska företag som bedriver näringsverksamhet eller äger fastigheter i Sverige
        case utländskaFöretag
        /// 5 – Aktiebolag
        case aktiebolag
        /// 6 – Enkelt bolag
        case enkeltbolag
        /// 7 – Ekonomiska föreningar, bostadsrättsföreningar
        case ekonomiskFörening
        /// 8 – Ideella föreningar och stiftelser
        case ideellFörening
        /// 9 – Handelsbolag, kommanditbolag och enkla bolag
        case handelsKommanditBolag
        /// If it's 4 🤓
        case invalid
    }

    /// The gender if it is a `personnummer` or `samordningsnummer`.
    /// It can have the following values:
    ///
    /// - male
    /// - female
    public enum Gender {
        /// If he is a male
        case male
        /// If she is a female
        case female
    }

    /// An enum that contains the available seerators.
    enum Seperator: String {
        /// Plus sign. Is used to identify > 100 years old people.
        case plus = "+"
        /// Minus sign. All the other cases.
        case minus = "-"

        /// A helper function to check if a string is equals with enums rawValue
        ///
        /// - Parameter string: a string representing the rawValue of an enum case
        /// - Returns: true if string equals enum case rawValue. Else false
        func equals(_ string: String) -> Bool {
            return rawValue == string
        }
    }

    /// Enum's initializer. Expects a string as a parameter, and based on it, it sets the correct value to `self`.
    /// By default, it is `.invalid`
    ///
    /// - Parameter ssn: A string representing the Swedish Social Security Number
    public init(_ ssn: String) {
        // Default value. To avoid `'self' used before 'self.init' call or assignment to 'self'`
        self = .invalid

        guard let parts = getPNOParts(forSSN: ssn) else {
            self = .invalid
            return
        }

        var (century, year, month, day, seperator, number, checksum) = parts

        seperator = update(seperator: seperator, withCentury: century, withYear: year)
        century = update(century: century, withSeperator: seperator, withYear: year)

        guard isLuhnValid(number: "\(year)\(month)\(day)\(number)\(checksum)") else {
            self = .invalid
            return
        }

        if isPersonummerValid(century: century, year: year, month: month, day: day) {
            self = .personnummer(gender: getGender(for: number))
        } else if isSamordningsnummerValid(century: century, year: year, month: month, day: day) {
            self = .samordningsnummer(gender: getGender(for: number))
        } else if isOrganisationsnummer(month: month) {
            self = .organisationsnummer(companyType: getCompanyType(for: year))
        }
    }

    /// Typealias that represents a tuple with all the parts of the personnummer.
    private typealias PNOPartsType = (
        century: String,
        year: String,
        month: String,
        day: String,
        seperator: String,
        num: String,
        checksum: String
    )

    /// Function which takes as an argument a string and return tuple with all the different parts of the personummer.
    /// If the data is invalid, it returns nil
    ///
    /// - Parameter ssn: A string representing the Swedish Social Security Number
    /// - Returns: If ssn is valid, it returns a tuple with all the different parts of the personummer.
    ///     Otherwise, it returns nil
    private func getPNOParts(forSSN ssn: String) -> PNOPartsType? {
        let pattern = "^(\\d{2}){0,1}(\\d{2})(\\d{2})(\\d{2})([\\+\\-\\s]?)(\\d{3})(\\d)$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let matches = regex.matches(in: ssn, range: NSRange(ssn.startIndex..., in: ssn))

        guard let match = matches.first else {
            return nil
        }
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else {
            return nil
        }

        let century = ssn.getValue(for: match.range(at: 1))
        let year = ssn.getValue(for: match.range(at: 2))
        let month = ssn.getValue(for: match.range(at: 3))
        let day = ssn.getValue(for: match.range(at: 4))
        let seperator = ssn.getValue(for: match.range(at: 5))
        let num = ssn.getValue(for: match.range(at: 6))
        let checksum = ssn.getValue(for: match.range(at: 7))

        return (
            century: century,
            year: year,
            month: month,
            day: day,
            seperator: seperator,
            num: num,
            checksum: checksum
        )
    }

    /// A function to update the seperator if it is missing or if its invalid, based on the century and year.
    ///
    /// - Parameters:
    ///   - seperator: The current seperator. It can be a valid seperator(-, +), an empty ("") or an invalid.
    ///   - century: The century. It is the 2 first digits of a 12-digit ssn. It can be empty, in case of 10-digit ssn.
    ///   - year: The year.
    /// - Returns: An update seperator depending on the parameters
    private func update(seperator: String, withCentury century: String, withYear year: String) -> String {
        var result = seperator
        seperatorCondition:
            if seperator.isEmpty || (!Seperator.plus.equals(seperator) && !Seperator.minus.equals(seperator)) {
            if century.isEmpty {
                result = Seperator.minus.rawValue
            } else {
                guard let century = Int(century), let year = Int(year) else {
                    break seperatorCondition
                }
                if currentYear - (century * 100 + year) < 100 {
                    result = Seperator.minus.rawValue
                } else {
                    result = Seperator.plus.rawValue
                }
            }
        }
        return result
    }

    /// A function to update the century if it is missing, based on the seperator and year.
    ///
    /// - Parameters:
    ///   - century: The current value of century.
    ///   - seperator: The current value of seperator, after being updated.
    ///   - year: The year
    /// - Returns: An updated value of the century, depending on the parameters
    private func update(century: String, withSeperator seperator: String, withYear year: String) -> String {
        var result = century
        centuryCondition: if century.isEmpty {
            var baseYear = currentYear - 100
            if seperator == Seperator.plus.rawValue {
                baseYear = currentYear - 200
            }
            guard let year = Int(year) else {
                break centuryCondition
            }
            result = String((100 + baseYear + (year - baseYear) % 100) / 100)
        }

        return result
    }

    /// Property to get the value of the current year
    private var currentYear: Int {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year
    }

    /// Function to validate if a the date, that the first digits of ssn represent, is valid
    ///
    /// - Parameters:
    ///   - century: The century
    ///   - year: The year
    ///   - month: The month
    ///   - day: The day
    /// - Returns: true if date components are valid. Otherwise, false
    private func isValidDate(century: String, year: String, month: String, day: String) -> Bool {
        var components = DateComponents()
        components.month = Int(month)
        components.year = Int("\(century)\(year)")
        components.day = Int(day)
        components.calendar = Calendar.current

        return components.isValidDate
    }

    /// Function to validate if ssn represent a valid number according to Luhn Algorithm
    ///
    /// - Parameter number: The number in string format
    /// - Returns: true if it is a valid number according to Luhn Algorithm. Otherwise false.
    private func isLuhnValid(number: String) -> Bool {
        var sum = 0
        let reversedCharacters = number.reversed().map { String($0) }
        for (idx, element) in reversedCharacters.enumerated() {
            guard let digit = Int(element) else {
                return false
            }

            switch (idx % 2 == 1, digit) {
            case (true, 9):
                sum += 9
            case (true, 0 ... 8):
                sum += (digit * 2) % 9
            default:
                sum += digit
            }
        }
        return sum % 10 == 0
    }

    /// Function to validate if the data corresponds to a valid Personnummer
    ///
    /// - Parameters:
    ///   - century: The century
    ///   - year: The year
    ///   - month: The month
    ///   - day: The day
    /// - Returns: true if it a valid personnumer. Otherwise false
    private func isPersonummerValid(century: String, year: String, month: String, day: String) -> Bool {
        return isValidDate(century: century, year: year, month: month, day: day)
    }

    /// Function to validate if the data corresponds to a valid Samordningsnummer
    ///
    /// - Parameters:
    ///   - century: The century
    ///   - year: The year
    ///   - month: The month
    ///   - day: The day
    /// - Returns: true if it a valid samordningsnummer. Otherwise false
    private func isSamordningsnummerValid(century: String, year: String, month: String, day: String) -> Bool {
        guard let intDay = Int(day) else {
            return false
        }
        let actualDay = String(intDay - 60)
        return isValidDate(century: century, year: year, month: month, day: actualDay)
    }

    /// Function to validate if the data corresponds to a valid Organisationsnummer
    ///
    /// - Parameter month: The month
    /// - Returns: true if it a valid organisationsnummer. Otherwise false
    private func isOrganisationsnummer(month: String) -> Bool {
        guard let intMonth = Int(month) else {
            return false
        }
        return intMonth >= 20
    }

    /// Function to get the gender based on the second to last number
    ///
    /// - Parameter number: A number
    /// - Returns: .female if the number is even. .male if number is odd
    private func getGender(for number: String) -> Gender? {
        guard let intNumber = Int(number) else {
            return nil
        }

        return intNumber % 2 == 0 ? .female : .male
    }

    /// Function to get the company type base on the first number
    ///
    /// - Parameter number: A number
    /// - Returns: the corresponding company type based on the parameter
    private func getCompanyType(for number: String) -> CompanyType {
        let digit = number.first
        switch digit {
        case "1":
            return CompanyType.dödsbon
        case "2":
            return CompanyType.offentlig
        case "3":
            return CompanyType.utländskaFöretag
        case "5":
            return CompanyType.aktiebolag
        case "6":
            return CompanyType.enkeltbolag
        case "7":
            return CompanyType.ekonomiskFörening
        case "8":
            return CompanyType.ideellFörening
        case "9":
            return CompanyType.handelsKommanditBolag
        default:
            return .invalid
        }
    }
}

// MARK: - String Extension

extension String {
    /// Function to get value in range
    ///
    /// - Parameter range: A range from which to take the substring
    /// - Returns: A string with the data in the range passed as parameter
    func getValue(for range: NSRange) -> String {
        if range.location == NSNotFound {
            return ""
        } else {
            return (self as NSString).substring(with: range)
        }
    }
}
