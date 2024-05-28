# encoding: UTF-8

=begin
NxBackup
    - "uuid"         : String
    - "mikuType"     : "NxBackup"
    - "description"  : String
=end

class NxBackups

    # NxBackups::readUuidsFromFile()
    def self.filepath()
        "#{Config::pathToGalaxy()}/DataHub/Drives, Passwords, Backups and Lost Procedures.txt"
    end

    # NxBackups::descriptionsFromFiles()
    def self.descriptionsFromFiles()
        IO.read(filepath)
            .lines
            .map{|l| l.strip }
            .select{|l| l.include?("::") }
            .map{|line| line.split("::").first.strip }
    end


    # NxBackups::removeObsoleteItems()
    def self.removeObsoleteItems()
        datatrace = Catalyst::datatrace()
        descriptions = NxBackups::descriptionsFromFiles()
        Cubes1::mikuType(datatrace, "NxBackup").each{|item|
            if !descriptions.include?(item["description"]) then
                Cubes1::destroy(item["uuid"])
            end
        }
    end

    # NxBackups::buildMissingItems()
    def self.buildMissingItems()
        datatrace = Catalyst::datatrace()
        descriptionsFromFiles = NxBackups::descriptionsFromFiles()
        descriptionsFromItems = Cubes1::mikuType(datatrace, "NxBackup").map{|item| item["description"] }
        (descriptionsFromFiles - descriptionsFromItems).each{|description|
            uuid = SecureRandom.uuid
            Cubes1::itemInit(uuid, "NxBackup")
            Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
            Cubes1::setAttribute(uuid, "description", description)
        }
    end

    # NxBackups::maintenance()
    def self.maintenance()
        NxBackups::buildMissingItems()
        NxBackups::removeObsoleteItems()
    end

    # NxBackups::getPeriodForDescriptionOrNull(description)
    def self.getPeriodForDescriptionOrNull(description)
        line = IO.read(filepath)
                .lines
                .map{|l| l.strip }
                .select{|l| l.include?("::") }
                .select{|line| line.start_with?(description)}
                .first
        return nil if line.nil? 
        line.split("::")[1].strip.to_f
    end

    # NxBackups::getLastUnixtimeForDescriptionOrZero(description)
    def self.getLastUnixtimeForDescriptionOrZero(description)
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/backups-lastest-times")
            .select{|location| File.basename(location).include?(description) }
            .each{|filepath|
                return DateTime.parse(IO.read(filepath).strip).to_time.to_i
            }
        0
    end

    # NxBackups::setNowForDescription(description)
    def self.setNowForDescription(description)
        folderpath = "#{Config::pathToCatalystDataRepository()}/backups-lastest-times"
        LucilleCore::locationsAtFolder(folderpath).each{|location|
            if File.basename(location).include?(description) then
                FileUtils.rm(location)
            end
        }
        filepath = "#{folderpath}/#{description}-#{Time.new.to_i}.txt"
        File.open(filepath, "w"){|f| f.puts(Time.new.utc.iso8601) }
    end

    # NxBackups::dueTimeOrNull(item)
    def self.dueTimeOrNull(item)
        period = NxBackups::getPeriodForDescriptionOrNull(item["description"])
        return nil if period.nil?
        NxBackups::getLastUnixtimeForDescriptionOrZero(item["description"]) + period*86400
    end

    # NxBackups::itemIsDue(item)
    def self.itemIsDue(item)
        period = NxBackups::dueTimeOrNull(item)
        return false if period.nil?
        period <= Time.new.to_i
    end

    # NxBackups::muiItems(datatrace)
    def self.muiItems(datatrace)
        Cubes1::mikuType(datatrace, "NxBackup").select{|item| NxBackups::itemIsDue(item) }
    end

    # NxBackups::toString(item)
    def self.toString(item)
        period = NxBackups::getPeriodForDescriptionOrNull(item["description"])
        return "💾 #{item["description"]}" if period.nil?
        dueTime = NxBackups::dueTimeOrNull(item)
        return "💾 #{item["description"]}" if dueTime.nil?
        "💾 #{item["description"]} (every #{period} days; due: #{Time.at(dueTime).utc.iso8601.gsub("T", " ")})"
    end
end
