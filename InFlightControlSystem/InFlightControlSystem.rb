#!/Users/pascal/.rvm/rubies/ruby-2.5.1/bin/ruby

# encoding: UTF-8

require 'colorize'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

# --------------------------------------------------------------------

=begin

Item {
    "uuid"        : String,
    "description" : String
    "position"    : Float
    "activation"  : String # optional, path to a shell script to call when the item is started
}

Companion {
    "uuid"         : String
    "runningState" : Float
    "timesPoints"  : Array[TimePoints]
}

TimePoint = {
    "unixtime" : Float
    "timespan" : Float
}

=end

# --------------------------------------------------------------------

# ---------------
# IO Items

def itemsFolderpath()
    "/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/items"
end

def getItems2()
    Dir.entries(itemsFolderpath())
        .select{|filename| filename[-5, 5] == ".json" }
        .map{|filename| JSON.parse(IO.read("#{itemsFolderpath()}/#{filename}")) }
end

def getTopItems()
    getItems2()
        .sort{|i1, i2| i1["position"] <=> i2["position"] }
        .first(3)
end

def saveItem2(item)
    uuid = item["uuid"]
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
end

def getItemByUUIDOrNull(uuid)
    filepath = "#{itemsFolderpath()}/#{uuid}.json"
    return nil if !File.exists?(filepath)
    JSON.parse(IO.read(filepath))
end

# ---------------
# IO Companions

def companionsKeyPrefix()
    getTopItems()
        .map{|item| item["uuid"] }
        .sort
        .join("-")
end

def getCompanion(uuid)
    companion = KeyValueStore::getOrNull(nil, "#{companionsKeyPrefix()}:#{uuid}")
    if companion.nil? then
        companion = {
            "uuid"         => uuid,
            "runningState" => nil,
            "timesPoints"  => []
        }
    else
        companion = JSON.parse(companion)
    end
    companion
end

def saveCompanion(companion)
    KeyValueStore::set(nil, "#{companionsKeyPrefix()}:#{companion["uuid"]}", JSON.generate(companion))
end

# ---------------
# Run Management

def startItem(uuid)
    item = getItemByUUIDOrNull(uuid)
    return if item.nil?
    if item["activation"] then
        system(item["activation"])
    end
    companion = getCompanion(uuid)
    return if companion["runningState"]
    companion["runningState"] = Time.new.to_i
    saveCompanion(companion)
end

def stopItem(uuid)
    companion = getCompanion(uuid)
    return if companion["runningState"].nil?
    unixtime = companion["runningState"]
    timespan = Time.new.to_i - unixtime
    companion["runningState"] = nil
    companion["timesPoints"] << {
        "unixtime" => Time.new.to_i,
        "timespan" => timespan
    } 
    saveCompanion(companion)
end

# ---------------
# Operations

def itemIsTopItem(uuid)
    getTopItems().any?{|i| i["uuid"] == uuid }
end

def getItemLiveTimespan(uuid)
    companion = getCompanion(uuid)
    x1 = 0
    if companion["runningState"] then
        x1 = Time.new.to_i - companion["runningState"]
    end
    x1 + companion["timesPoints"].map{|point| point["timespan"] }.inject(0, :+)
end

def getItemLiveTimespanTopItemsDifferentialInHoursOrNull(uuid)
    timespan = getItemLiveTimespan(uuid)
    differentTimespans = getTopItems()
                            .select{|item| item["uuid"] != uuid }
                            .map {|item| getItemLiveTimespan(item["uuid"]) }
    return nil if differentTimespans.nil?
    (timespan - differentTimespans.min).to_f/3600
end

def topItemsOrderedByTimespan()
    getTopItems().sort{|i1, i2| getItemLiveTimespan(i1["uuid"]) <=> getItemLiveTimespan(i2["uuid"]) }
end

def itemsOrderedByPosition()
    getItems2().sort{|i1, i2| i1["position"] <=> i2["position"] }
end

def getNextAction() # [ nil | String, lambda ]

    runningitems = topItemsOrderedByTimespan()
                .select{|item| getCompanion(item["uuid"])["runningState"] }
    lowestitem = topItemsOrderedByTimespan()[0]

    if runningitems.size == 0 then
        return [ "start: #{lowestitem["description"]}".red , lambda { startItem(lowestitem["uuid"]) } ]
    end

    firstrunningitem = runningitems[0]

    if firstrunningitem["uuid"] == lowestitem["uuid"] then
        return [ nil , lambda { stopItem(firstrunningitem["uuid"]) } ]
    else
        return [ "stop: #{firstrunningitem["description"]}".red , lambda { stopItem(firstrunningitem["uuid"]) } ]
    end
end

def getReportLine() 
    report = [ "In Flight Control System 🛰️ " ]
    topItemsOrderedByTimespan()
        .select{|item| getCompanion(item["uuid"])["runningState"] }
        .each{|item| 
            d1 = getItemLiveTimespanTopItemsDifferentialInHoursOrNull(item["uuid"])
            d2 = d1 ? " (#{d1.round(2)} hours)" : ""
            report << "running: #{item["description"]}#{d2}".green 
        }
    nextaction = getNextAction()
    if nextaction then
        report << nextaction[0] # can be null
    end
    report.compact.join(" >> ")
end

def getReportText()
    nsize = getItems2().map{|item| item["description"].size }.max
    itemsOrderedByPosition()
        .map{|item| 
            if itemIsTopItem(item["uuid"]) then
                companion = getCompanion(item["uuid"])
                "(#{"%5.3f" % item["position"]}) #{item["description"].ljust(nsize)} (#{"%6.2f" % (getItemLiveTimespan(item["uuid"]).to_f/3600)} hours)"
            else
                "(#{"%5.3f" % item["position"]}) #{item["description"].ljust(nsize)}"
            end
        }
        .join("\n")
end

def selectItemOrNull()
    LucilleCore::selectEntityFromListOfEntitiesOrNull("item", itemsOrderedByPosition(), lambda{|item| item["description"] })
end

def onScreenNotification(title, message)
    title = title.gsub("'","")
    message = message.gsub("'","")
    message = message.gsub("[","|")
    message = message.gsub("]","|")
    command = "terminal-notifier -title '#{title}' -message '#{message}'"
    system(command)
end
