

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxTask", uuid)

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Events::publishItemInit("NxTask", uuid)

        nhash = Datablobs::putBlob(url)
        coredataref = "url:#{nhash}"

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Events::publishItemInit("NxTask", uuid)

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxTask", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask_vX(uuid, description)
    def self.descriptionToTask_vX(uuid, description)
        Events::publishItemInit("NxTask", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "🔹 #{item["description"]}#{TxCores::suffix(item)}"
    end

    # NxTasks::newGlobalFirstPosition()
    def self.newGlobalFirstPosition()
        t = Catalyst::mikuType("NxTask")
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # NxTasks::newGlobalLastPosition()
    def self.newGlobalLastPosition()
        t = Catalyst::mikuType("NxTask")
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::access(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()

        Catalyst::mikuType("NxTask").each{|item|
            if item["coreX-2300"] and Catalyst::itemOrNull(item["coreX-2300"]).nil? then
                Events::publishItemAttributeUpdate(uuid, "coreX-2300", "7cf30bc6-d791-4c0c-b03f-16c728396f22") # infinity
                Events::publishItemAttributeUpdate(uuid, "global-position", NxTasks::newGlobalFirstPosition())
            end
        }

        # Pick up NxFronts-BufferIn
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataHub/NxFronts-BufferIn").each{|location|
            next if File.basename(location)[0, 1] == "."
            NxTasks::bufferInLocationToTask(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        # Feed Infinity using NxIce
        if Catalyst::mikuType("NxTask").size < 100 then
            Catalyst::mikuType("NxIce").take(10).each{|item|

            }
        end
    end

    # NxTasks::fsck()
    def self.fsck()
        Catalyst::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end

    # NxTasks::bufferInItems()
    def self.bufferInItems()
        Catalyst::mikuType("NxTask")
            .select{|item| item["lineage-nx128"].nil? }
            .select{|item| item["description"].include?("(buffer-in)") }
            .sort_by{|item| item["unixtime"] }
    end

end
