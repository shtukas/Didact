
# encoding: UTF-8

class NxEvents

    # ----------------------------------------------------------------------
    # IO

    # NxEvents::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxEvent")
    end

    # NxEvents::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEvents::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = CommonUtils::interactiveDateTimeBuilder()
        DxF1s::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1s::setJsonEncoded(uuid, "mikuType",    "NxEvent")
        DxF1s::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1s::setJsonEncoded(uuid, "datetime",    datetime)
        DxF1s::setJsonEncoded(uuid, "description", description)
        DxF1s::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: c4d9e89d-d4f2-4a44-8c66-311431977b4c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEvents::toString(item)
    def self.toString(item)
        "(event) #{item["description"]}"
    end
end
