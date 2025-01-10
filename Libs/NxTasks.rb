
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "global-positioning-4233", rand) # default value to ensure that the item has all the mandatory fields
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location)
    def self.locationToTask(description, location)
        uuid = SecureRandom.uuid
        payload = UxPayload::locationToPayload(uuid, location)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "global-positioning-4233", rand) # default value to ensure that the item has all the mandatory fields
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        "🔹 #{item["description"]}"
    end

    # NxTasks::taskInsertionPosition()
    def self.taskInsertionPosition()
        items = Items::mikuType("NxTask").sort_by{|item| item["global-positioning-4233"] }

        while items.any?{|item| !item["is_origin_24r4"] } do
            items.shift
        end

        items = items.drop(1)

        return rand if items.size == 0

        if items.size < 2 then
            return items.last["global-positioning-4233"] + 1
        end

        0.5 * (items[0]["global-positioning-4233"] + items[1]["global-positioning-4233"])
    end

    # NxTasks::performItemPositioning(item)
    def self.performItemPositioning(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["Infinity, 10 to 20 task (default)", "NxCore"])

        if option.nil? or option == "Infinity, 10 to 20 task (default)" then
            position = NxTasks::taskInsertionPosition()
            Items::setAttribute(item["uuid"], "global-positioning-4233", position)
        end

        if option == "NxCore" then
            parent = NxCores::interactivelySelectOrNull()
            return if parent.nil?
            Items::setAttribute(item["uuid"], "parentuuid-0014", parent["uuid"])
            position = Operations::interactivelySelectGlobalPositionInParent(parent)
            Items::setAttribute(item["uuid"], "global-positioning-4233", position)
        end
    end
end
