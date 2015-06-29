//
//  PWDieRoll.m
//  CharSheet
//
//  Created by Patrick Wallace on 13/12/2012.
//
//  This holds the various stats and skills that make up a die roll, and then performs the rolling.

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
            assert( skills.array.filter{ $0.name == nil }.isEmpty, "All skills must have a name." )
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
    
    // TODO: Implement extra D4s.
    var extraD4s: Int16 = 0 {
        didSet {
            resetResults()
        }
    }
    
    var charSheet: CharSheet!

    // MARK: Output Properties
    
    // These values are only available after the die roll.
    var d6Rolls: [Int16] = []
    var dieRollsPerSkill: [String: [Int16]] = [:]
    var extraD4Rolls: [Int16] = []
    
    
    var resultAsHTML: String {
        get {
            var log = NSMutableString()
            log.appendString("<html><head/><body>")
            log.appendString("D6 Roll:<br/>")
            
            // For the D6 rolls, first check for a botch and return immediately if so.
            if isBotch(d6Rolls) {
                return "\(d6Rolls[0]) + \(d6Rolls[1]) (Botch!)"
            }
            
            // Format the D6 rolls.
            assert(d6Rolls.count % 2 == 0, "Uneven number of d6 rolls")
            var d6Total = Int16(0)
            log.appendString(spacing)
            for var i = 0, c = d6Rolls.count; i < c; i += 2 {
                let n1 = d6Rolls[i], n2 = d6Rolls[i+1]
                var isDouble = n1 == n2
                if i > 0 {
                    log.appendString(", ")
                }
                let doubleStr = isDouble ? "(Double!)" : ""
                log.appendString("\(n1) + \(n2) \(doubleStr)")
                d6Total += n1 + n2
            }
            log.appendString("&nbsp;&nbsp;= \(d6Total)<br/>")
            
            // Add the stat if necessary.
            if let s = stat {
                log.appendString("Stats: <br/>\(spacing)\(s.name!) = \(s.value)<br/>")
            }
            // Now add the skill rolls.
            if skills.count > 0 {
                log.appendString("Skills:<br/>")
                
                for skill in skills.array {
                    let spec = specialties[skill.name as! String]
                    
                    let rollsForSkill: [Int16] = dieRollsPerSkill[skill.name as! String] ?? []
                    let skillRollStr = formatSkillRoll(skill, rolls: rollsForSkill, spec: spec)
                    log.appendString("\(spacing)\(skillRollStr)<br/>")
                }
            }
            
            // Add any final adds.
            if(adds != 0) {
                log.appendString("Adds:<br/>\(spacing)+ \(adds)<br/>")
            }
            log.appendString("<br/><hr/>")
            log.appendString("<b>Total = \(total)</b>")
            log.appendString("</body></html>")
            return log.description
        }
    }
    
    
    var total: Int16 {
        get {
            if isBotch(d6Rolls) { return 0 }
            var total = d6Rolls.reduce(0) { $0 + $1 }
            
            if let s = stat {
                total += s.value
            }
            for skill in skills.array {
                if let rolls = dieRollsPerSkill[skill.name as! String] {
                    total += rolls.reduce(0) { $0 + $1 }
                }
                if let spec = specialties[skill.name as! String] {
                    total += spec.value
                }
            }
            total += adds
            return total
        }
    }
    
    
    // MARK: - Housekeeping
    
    convenience init(charSheet: CharSheet) {
        self.init()
        self.charSheet = charSheet
        resetResults()
    }
    
    override init() {
        super.init()
        resetResults()
    }
    
    // MARK: Public API
    
    func addLogEntry() -> LogEntry {
        var entry = charSheet.addLogEntry()
        entry.summary = getSummary()
        entry.change  = getLogDetail()
        return entry;
    }
    
    

    
    // MARK: Private API
    
    private func resetResults() {
        d6Rolls = []
        dieRollsPerSkill = [:]
    }
    
    
    
    
    private func sanitiseHTML(input: String) -> String {
        var output = NSMutableString(capacity: count(input))
        for c in input {
            switch c {
            case "<" : output.appendString("&lt;" )
            case ">" : output.appendString("&gt;" )
            case "&" : output.appendString("&amp;")
            case "\n": output.appendString("<br/>")
            default  : output.appendString("\(c)")
            }
        }
        return output as String
    }
    
    
    
    
    private func formatSkillRoll(skill: Skill, rolls: [Int16], spec: Specialty?) -> String {
        var skillTotal = rolls.reduce(0) { n1, n2 in n1 + n2}
        var specStr    = "", finalTotal = Int16(0)
        if let specialty = spec {
            specStr = String(format:"(+ %d)", specialty.value)
            finalTotal += specialty.value
        }
        finalTotal += skillTotal
        let skillName = skill.name!, rollsText = (rolls.map{$0.description} as NSArray).componentsJoinedByString(" + ")
        return String(format:"%@ (%d) = %@ %@ = %d",
			sanitiseHTML(skillName as? String ?? "No name"), rolls.count, rollsText, specStr, finalTotal)
    }
    
    
    
    private func isBotch(d6Rolls: [Int16]) -> Bool {
        assert(count(d6Rolls) >= 2, "Not enough d6")
        return d6Rolls[0] + d6Rolls[1] == 3
    }
    
    
    
    
    let spacing = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
    
    // Return the summary of a die roll for the logs.
    private func getSummary() -> String {
        var statStr  = "<No stat>"
        if let statName = self.stat?.shortName {
            statStr = statName
        }
        var skillNames: NSArray = skills.array.map{ obj in (obj as Skill).name! }
        var skillStr = skillNames.componentsJoinedByString("/")
        return "\(statStr) + \(skillStr)"
    }
    
    
    
    // Return the detail text of a die roll for the logs.
    private func getLogDetail() -> String {
        
        func summariseSkillRoll(skill: Skill) -> String {
            
            var d4Rolls: [Int16] = []
            if let dieRollsForSkill = dieRollsPerSkill[skill.name as! String] {
                d4Rolls = dieRollsForSkill
            }
            var d4rollStr = (d4Rolls.map{$0.description} as NSArray).componentsJoinedByString("+")
            var specValue: Int16 = 0
            if let spec = specialties[skill.name as! String] {
                specValue = spec.value
            }
            return "\(skill.name!): \(d4Rolls) (+\(specValue))"
            
        }
        
        let statStr = (stat != nil) ? "Stat: \(stat!.name!)=\(stat!.value)" : "Stat: None"
        let d6s     = (d6Rolls.map{ $0.description } as NSArray).componentsJoinedByString(" + ")
        let d6str   = "D6 Rolls: \(d6s)"
        let skillResults: NSArray = skills.array.map(summariseSkillRoll)
        let skillStr = skillResults.componentsJoinedByString("\n")
        
        return String(format:"%@\n%@\n%@\nAdds:%d\nTotal: %d", d6str, statStr, skillStr, adds, total)
    }
    

    private func rollD6(doublesReroll: Bool) -> [Int16] {
        var results: [Int16] = []
        var firstRoll = true
        var n1 = Int16(0), n2 = Int16(0)
        
        do {
            n1 = Int16(rand() % 6) + 1
            n2 = Int16(rand() % 6) + 1
            results.append(n1)
            results.append(n2)
            
            // If the first roll was a botch, then return immediately.
            if firstRoll && isBotch(results) {
                return results
            }
            firstRoll = false
        } while doublesReroll && n1 == n2
        
        return results
    }
    
    
    
    
    private func rollD4(numToRoll: Int16) -> [Int16] {
        var results: [Int16] = []
        for var i: Int16 = 0, c: Int16 = numToRoll; i < c; ++i {
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
            let skillExtraD4: Int16 = charSheet.extraDiceForSkill(skill as Skill)
            let d4Results = rollD4(Int16(skill.value) + Int16(skillExtraD4))
            dieRollsPerSkill[skill.name as! String] = d4Results
        }
        // Fixed values (stat & specialties) don't need to be handled here.
    }
    
}
