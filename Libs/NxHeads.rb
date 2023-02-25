# encoding: UTF-8

class NxHeads

    # NxHeads::items()
    def self.items()
        N1DataIO::getMikuType("NxHead")
    end

    # NxHeads::commit(item)
    def self.commit(item)
        N1DataIO::commitObject(item)
    end

    # NxHeads::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N1DataIO::getObjectOrNull(uuid)
    end

    # NxHeads::destroy(uuid)
    def self.destroy(uuid)
        N1DataIO::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxHeads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Watch '#{title}' on Netflix",
            "field11"     => nil,
            "position"    => position
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{N1DataIO::putBlob(url)}"
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxTails::commit(item)
        item
    end

    # NxHeads::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(DatablobStoreElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxTails::commit(item)
        item
    end

    # NxHeads::priority()
    def self.priority()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxHeads::startPosition() - 1
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxHeads::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxHeads::toString(item)
    def self.toString(item)
        rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
        "(stream) (#{"%5.2f" % rt}) #{item["description"]} (pos: #{item["position"].round(3)})"
    end

    # NxHeads::startZone()
    def self.startZone()
        NxHeads::items().map{|item| item["position"] }.sort.take(3).inject(0, :+).to_f/3
    end

    # NxHeads::startPosition()
    def self.startPosition()
        positions = NxHeads::items().map{|item| item["position"] }
        return NxTails::frontPosition() - 1 if positions.empty?
        positions.min
    end

    # NxHeads::endPosition()
    def self.endPosition()
        positions = NxHeads::items().map{|item| item["position"] }
        return NxTails::frontPosition() - 1 if positions.empty?
        positions.max
    end

    # NxHeads::listingItems()
    def self.listingItems()
        items = NxHeads::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
            .take(3)
            .map {|item|
                {
                    "item" => item,
                    "rt"   => BankUtils::recoveredAverageHoursPerDay(item["uuid"])
                }
            }
            .select{|packet| packet["rt"] < 1 }
            .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
            .map {|packet| packet["item"] }

        return items if items.size > 0

        # If we reach this point it means that all first three items have a rt >= 1,
        # let's try the next three and we stop at them.

        NxHeads::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
            .drop(3)
            .take(3)
            .map {|item|
                {
                    "item" => item,
                    "rt"   => BankUtils::recoveredAverageHoursPerDay(item["uuid"])
                }
            }
            .select{|packet| packet["rt"] < 1 }
            .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
            .map {|packet| packet["item"] }
    end

    # NxHeads::listingRunningItems()
    def self.listingRunningItems()
        NxHeads::items().select{|item| NxBalls::itemIsActive(item) }
    end

    # --------------------------------------------------
    # Operations

    # NxHeads::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
