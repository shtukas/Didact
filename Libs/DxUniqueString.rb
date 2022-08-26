
# encoding: UTF-8

class DxUniqueString

    # ----------------------------------------------------------------------
    # Objects Management

    # DxUniqueString::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxUniqueString")
    end

    # DxUniqueString::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (empty to abort): ")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setJsonEncoded(uuid, "uuid", uuid)
        DxF1::setJsonEncoded(uuid, "mikuType", "DxUniqueString")
        DxF1::setJsonEncoded(uuid, "unixtime", unixtime)
        DxF1::setJsonEncoded(uuid, "datetime", datetime)
        DxF1::setJsonEncoded(uuid, "uniquestring", uniquestring)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxUniqueString::toString(item)
    def self.toString(item)
        "(DxUniqueString) #{item["uniquestring"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxUniqueString::access(item)
    def self.access(item)
        puts "DxUniqueString::access has not been implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end
