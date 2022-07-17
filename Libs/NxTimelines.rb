
# encoding: UTF-8

class NxTimelines

    # ----------------------------------------------------------------------
    # IO

    # NxTimelines::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18s::fileExists?(objectuuid)
        return nil if Fx18s::getAttributeOrNull(objectuuid, "mikuType") != "NxTimeline"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18s::getAttributeOrNull(objectuuid, "description"),
        }
    end

    # NxTimelines::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxTimeline")
            .map{|objectuuid| NxTimelines::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxTimelines::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyFx18Logically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxTimelines::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        Fx18s::makeNewFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxTimeline")
        Fx18s::setAttribute2(uuid, "unixtime",    unixtime)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxTimelines::toString(item)
    def self.toString(item)
        "(timeline) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxTimelines::nx20s()
    def self.nx20s()
        NxTimelines::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxTimelines::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
