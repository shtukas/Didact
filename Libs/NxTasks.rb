

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

        if LucilleCore::askQuestionAnswerAsBoolean("set engine ? ") then
            engine = TxEngine::interactivelyMakeOrNull()
            Events::publishItemAttributeUpdate(uuid, "engine-0852", engine)
        end

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
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxTask", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask_vX(uuid, description)
    def self.descriptionToTask_vX(uuid, description)
        Events::publishItemInit("NxTask", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        "🔹 #{TxEngine::prefix(item)}#{item["description"]}#{TxCores::suffix(item)}"
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        CoreDataRefStrings::access(task["uuid"], task["field11"])
    end

    # NxTasks::maintenance()
    def self.maintenance()

        # Ensuring consistency of lineages

        Catalyst::mikuType("NxTask").each{|task|
            next if task["lineage-nx128"].nil?
            thread = Catalyst::itemOrNull(task["lineage-nx128"])
            next if thread
            Events::publishItemAttributeUpdate(task["uuid"], "lineage-nx128", nil)
        }

        # Pick up NxFronts-BufferIn
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataHub/NxFronts-BufferIn").each{|location|
            NxTasks::bufferInLocationToTask(location)
            LucilleCore::removeFileSystemLocation(location)
        }

        # Feed Infinity using NxIce
        if Catalyst::mikuType("NxTask").size < 100 then
            Catalyst::mikuType("NxIce").take(10).each{|item|
                thread = Catalyst::itemOrNull("8d67eae1-787e-4763-81bf-3ffb6e28c0eb") # Infinity Thread
                Events::publishItemAttributeUpdate(item["uuid"], "lineage-nx128", thread["uuid"])
                Events::publishItemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
            }
        end
    end

    # NxTasks::fsck()
    def self.fsck()
        Catalyst::mikuType("NxTask").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
