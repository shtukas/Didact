

class TxDrives

    # TxDrives::interactivelyBuildNewOrNull()
    def self.interactivelyBuildNewOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        return nil if hours == 0
        date = CommonUtils::interactivelyMakeADateOrNull()
        return nil if date.nil?
        {
            "hours" => hours,
            "type"  => "deadline",
            "date"  => date
        }
    end

    # TxDrives::checkPriorityLiveness(item)
    def self.checkPriorityLiveness(item)
        return item if !Config::isPrimaryInstance()
        return item if item["priority"].nil?
        return item if item["priority"]["date"] > CommonUtils::today()
        puts "The following item with priority has an expired priority"
        puts PolyFunctions::toString(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["expand", "terminate"])
        return item if option.nil?
        if option == "expand" then
            priority = TxDrives::interactivelyBuildNewOrNull()
            return item if priority.nil?
            Cubes::setAttribute2(item["uuid"], "priority", priority)
            return Cubes::itemOrNull(item["uuid"])
        end
        if option == "terminate" then
            Cubes::setAttribute2(item["uuid"], "priority", nil)
            return Cubes::itemOrNull(item["uuid"])
        end
        raise "(error: 0947d4ad-1f5a-4a2a-91bd-ea40d3fb4099)"
    end

    # TxDrives::isActiveEngineItem(item)
    def self.isActiveEngineItem(item)
        return false if item["mikuType"] != "NxThread"
        return false if item["priority"].nil?
        ratio = Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/item["priority"]["hours"]
        ratio < 1
    end

    # TxDrives::ratio(item)
    def self.ratio(item)
        Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/item["priority"]["hours"]
    end
end