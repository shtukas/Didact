

class NxTasks

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        Broadcasts::publishItemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)

        Broadcasts::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Broadcasts::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Broadcasts::publishItemAttributeUpdate(uuid, "description", description)
        Broadcasts::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Broadcasts::publishItemAttributeUpdate(uuid, "global-position", Catalyst::newGlobalLastPosition())

        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::urlToTask(url)
    def self.urlToTask(url)
        description = "(vienna) #{url}"
        uuid = SecureRandom.uuid

        Broadcasts::publishItemInit(uuid, "NxTask")

        nhash = Datablobs::putBlob(url)
        coredataref = "url:#{nhash}"

        Broadcasts::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Broadcasts::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Broadcasts::publishItemAttributeUpdate(uuid, "description", description)
        Broadcasts::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::bufferInLocationToTask(location)
    def self.bufferInLocationToTask(location)
        description = "(buffer-in) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        Broadcasts::publishItemInit(uuid, "NxTask")

        coredataref = CoreDataRefStrings::locationToAionPointCoreDataReference(uuid, location)

        Broadcasts::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Broadcasts::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Broadcasts::publishItemAttributeUpdate(uuid, "description", description)
        Broadcasts::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Broadcasts::publishItemAttributeUpdate(uuid, "global-position", Catalyst::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Broadcasts::publishItemInit(uuid, "NxTask")
        Broadcasts::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Broadcasts::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Broadcasts::publishItemAttributeUpdate(uuid, "description", description)
        Broadcasts::publishItemAttributeUpdate(uuid, "global-position", Catalyst::newGlobalLastPosition())
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        icon = "🔹"
        if item["red-1854"] == CommonUtils::today() then
            icon = "🔺"
        end
        "#{icon} #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxTasks::orphans()
    def self.orphans()
        Catalyst::mikuType("NxTask")
            .select{|item| item["parent-1328"].nil? }
            .sort_by{|item| item["unixtime"] }
            .reverse
    end

    # NxTasks::redItems()
    def self.redItems()
        Catalyst::mikuType("NxTask")
            .select{|item| item["red-1854"] == CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(task)
    def self.access(task)
        if task["field11"] and Catalyst::children(task).size > 0 then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["content access", "elements access (default)"])
            if option.nil? or option == "elements access (default)" then
                Catalyst::program1(item)
                return
            end
            CoreDataRefStrings::accessAndMaybeEdit(task["uuid"], task["field11"])
            return
        end
        if Catalyst::children(task).size > 0 then
            Catalyst::program1(task)
            return
        end
        if task["field11"] then
            CoreDataRefStrings::accessAndMaybeEdit(task["uuid"], task["field11"])
            return
        end
    end

    # NxTasks::maintenance()
    def self.maintenance()

        Catalyst::mikuType("NxTask").each{|item|
            if item["parent-1328"] and Catalyst::itemOrNull(item["parent-1328"]).nil? then
                Broadcasts::publishItemAttributeUpdate(item["uuid"], "parent-1328", nil)
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
end
