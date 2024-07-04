
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(parent, uuid, description)
    def self.descriptionToTask1(parent, uuid, description)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "parentuuid-0032", parent["uuid"])
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::icon(item)
    def self.icon(item)
        "🔹"
    end

    # NxTasks::ratio(item)
    def self.ratio(item)
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours"].to_f/7)
    end

    # NxTasks::ratioString(item)
    def self.ratioString(item)
        return "" if item["hours"].nil?
        " (#{"%6.2f" % (100 * NxTasks::ratio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxTasks::toString(item)
    def self.toString(item)
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTasks::icon(item)} #{item["description"]}#{NxTasks::ratioString(item)}"
    end

    # NxTasks::orphans()
    def self.orphans()
        Items::mikuType("NxTask")
            .select{|item| Catalyst::isOrphan(item) }
    end
end
