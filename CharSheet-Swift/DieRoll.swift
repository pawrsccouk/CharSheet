////
////  PWDieRoll.m
////  CharSheet
////
////  Created by Patrick Wallace on 13/12/2012.
////
////  This holds the various stats and skills that make up a die roll, and then performs the rolling.
//
import Foundation
import CoreData

class DieRoll : NSObject {
    
    // MARK: - Input Properties
    
    var stat: Stat? {
        didSet {
            resetResults()
        }
    }
    var skills: MutableOrderedSet<Skill> = MutableOrderedSet() {
        didSet {
            resetResults()
        }
    }
    var adds: Int = 0 {
        didSet {
            resetResults()
        }
    }
    var specialties: [String: Specialty] = [:] {
        didSet {
            resetResults()
        }
    }
    
    var extraD4s: Int = 0 {
        didSet {
            resetResults()
        }
    }
    
    var charSheet: CharSheet

    // MARK: Output Properties
    
    // These values are only available after the die roll.
    var d6Rolls: [Int] = []
    var dieRollsPerSkill: [String: [Int]] = [:]
    var extraD4Rolls: [Int] = []
    
    
    var resultAsHTML: String {
        get {
            var log = NSMutableString()
            log.appendString("<html><head/><body>")
            log.appendString("D6 Roll:<br/>")
            
            // For the D6 rolls, first check for a botch and return immediately if so.
            if isBotch(d6Rolls) {
                return String(format:"%@ + %@ (Botch!)",d6Rolls[0], d6Rolls[1])
            }
            
            // Format the D6 rolls.
            assert(d6Rolls.count % 2 == 0, "Uneven number of d6 rolls")
            var d6Total = 0
            log.appendString(spacing)
            for var i = 0, c = d6Rolls.count; i < c; i += 2 {
                let n1 = d6Rolls[i], n2 = d6Rolls[i+1]
                var isDouble = n1 == n2
                if i > 0 {
                    log.appendString(", ")
                }
                log.appendFormat("%@ + %@ %@", n1, n2, isDouble ? "(Double!)" : "")
                d6Total += n1 + n2
            }
            log.appendFormat("&nbsp;&nbsp;= %d<br/>", d6Total)
            
            // Add the stat if necessary.
            if let s = stat {
                log.appendFormat("Stats: <br/>%@%@ = %@<br/>", spacing, s.name, s.value)
            }
            // Now add the skill rolls.
            if skills.count > 0 {
                log.appendString("Skills:<br/>")
                
                for skill in skills.array {
                    var spec = specialties[skill.name]
                    let rollsForSkill: [Int] = dieRollsPerSkill[skill.name] ?? []
                    log.appendFormat("%@%@<br/>", spacing, formatSkillRoll(skill, rolls: rollsForSkill, spec: spec))
                }
            }
            
            // Add any final adds.
            if(adds != 0) {
                log.appendFormat("Adds:<br/>%@+ %d<br/>", spacing, adds)
            }
            log.appendString("<br/><hr/>")
            log.appendFormat("<b>Total = %d</b>", total)
            log.appendString("</body></html>")
            return log
        }
    }
    
    
    var total: Int {
        get {
            if isBotch(d6Rolls) { return 0 }
            var total = d6Rolls.reduce(0) { $0 + $1 }
            
            if let s = stat {
                total += s.value.integerValue
            }
            for skill in skills.array {
                if let rolls = dieRollsPerSkill[skill.name] {
                    total += rolls.reduce(0) { $0 + $1 }
                }
                if let spec = specialties[skill.name] {
                    total += spec.value.integerValue
                }
            }
            total += adds
            return total
        }
    }
    
    
    // MARK: - Housekeeping
    
    init(charSheet: CharSheet) {
        self.charSheet = charSheet
        super.init()
        resetResults()
    }
    
    
    
    
    // MARK: Methods
    
    func resetResults() {
        d6Rolls = []
        dieRollsPerSkill = [:]
    }
    
    
    
    
    func sanitiseHTML(input: String) -> String
    {
        var output = NSMutableString(capacity: countElements(input))
        for c in input {
            switch c {
            case "<" : output.appendString("&lt;" )
            case ">" : output.appendString("&gt;" )
            case "&" : output.appendString("&amp;")
            case "\n": output.appendString("<br/>")
            default  : output.appendString("\(c)")
            }
        }
        return output
    }
    
    
    
    
    func formatSkillRoll(skill: Skill?, rolls: [Int], spec: Specialty?) -> String {
        var skillTotal = rolls.reduce(0) { n1, n2 in n1 + n2}
        var specStr    = "", finalTotal = 0
        if let specialty = spec {
            specStr = String(format:"(+ %d)", specialty.value.integerValue)
            finalTotal += specialty.value.integerValue
        }
        finalTotal += skillTotal
        return String(format:"%@ (%d) = %@ %@ = %d", sanitiseHTML(skill?.name ?? ""), rolls.count, (rolls as NSArray).componentsJoinedByString(" + "), specStr, finalTotal)
    }
    
    func isBotch(d6Rolls: [Int]) -> Bool {
        assert(countElements(d6Rolls) == 2, "Invalid no. of d6")
        return d6Rolls[0] + d6Rolls[1] == 3
    }
    
    
    
    
    let spacing = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
    
    // Return the summary of a die roll for the logs.
    func getSummary() -> String {
        var statStr  = "<No stat>"
        if let statName = self.stat?.shortName {
            statStr = statName
        }
        var skillNames: NSArray = skills.array.map{ obj in (obj as Skill).name }
        var skillStr = skillNames.componentsJoinedByString("/")
        return NSString(format:"%@ + %@", statStr, skillStr)
    }
    
    
    
    // Return the detail text of a die roll for the logs.
    func getLogDetail() -> String {
        
        func summariseSkillRoll(skill: Skill) -> String {
            
            var d4Rolls: NSArray = []
            if let dieRollsForSkill = dieRollsPerSkill[skill.name] {
                d4Rolls = dieRollsForSkill
            }
            var d4rollStr = d4Rolls.componentsJoinedByString("+")
            var specValue = 0
            if let spec = specialties[skill.name] {
                specValue = spec.value.integerValue
            }
            return String(format:"%@: %@ (+%@)", skill.name, d4Rolls, specValue)
            
        }
        
        var statStr = (stat != nil) ? String(format:"Stat: %@=%@", stat!.name, stat!.value) : "Stat: None";
        var d6str   = String(format:"D6 Rolls: %@", (d6Rolls as NSArray).componentsJoinedByString(" + "))
        var skillResults: NSArray = skills.array.map(summariseSkillRoll)
        var skillStr = skillResults.componentsJoinedByString("\n")
        
        return String(format:"%@\n%@\n%@\nAdds:%d\nTotal: %d", d6str, statStr, skillStr, adds, total)
    }
    
    
    
    
    func addLogEntry() -> LogEntry {
        var entry = charSheet.addLogEntry()
        entry.summary = getSummary()
        entry.change  = getLogDetail()
        return entry;
    }
    
    
    
    func rollD6(doublesReroll: Bool) -> [Int] {
        var results: [Int] = []
        var firstRoll = true
        var n1: Int, n2: Int
        
        do {
            n1 = (Int(rand()) % 6) + 1
            n2 = (Int(rand()) % 6) + 1
            results.append(n1)
            results.append(n2)
            
            // If the first roll was a botch, then return immediately.
            if firstRoll && isBotch(results) {
                return results
            }
            firstRoll = false
        } while doublesReroll && n1 == n2
        
        return results;
    }
    
    
    
    
    func rollD4(numToRoll: Int) -> [Int] {
        var results: [Int] = []
        for var i = 0, c = numToRoll; i < c; ++i {
            results.append((Int(rand()) % 4) + 1)
        }
        return results
    }
    
    
    
    func roll() {
        var intSeed: UInt32 = UInt32(NSDate.timeIntervalSinceReferenceDate())
        srand(intSeed)
        resetResults()
        
        // D6 rolls
        d6Rolls += rollD6(true)
        // D4 rolls.
        for skill in self.skills.array {
            var skillExtraD4 = charSheet.extraDiceForSkill(skill as Skill)
            var d4Results = rollD4(skill.value.integerValue + skillExtraD4)
            dieRollsPerSkill[skill.name] = d4Results
        }
        // Fixed values (stat & specialties) don't need to be handled here.
    }
    
}
