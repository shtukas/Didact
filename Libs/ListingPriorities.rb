

class ListingPriorities

    # ListingPriorities::increasingFunctionOfUnixtime(unixtime)
    def self.increasingFunctionOfUnixtime(unixtime)
        Math.atan(unixtime.to_f/(10**8))
    end

    # ListingPriorities::metric(item)
    def self.metric(item)

        if item["stack-0620"] then
            return 0.96 + 0.02*0.01*Math.atan(-item["stack-0620"]) # range: (0.97, 0.99)
        end

        if item["mikuType"] == "DesktopTx1" then
            return 0.95
        end

        if item["mikuType"] == "NxAnniversary" then
            return 0.93
        end

        if item["mikuType"] == "PhysicalTarget" then
            return 0.91
        end

        if item["mikuType"] == "NxOndate" then
            return 0.68 - 0.01*ListingPriorities::increasingFunctionOfUnixtime(DateTime.parse(item["datetime"]).to_time.to_i)
        end

        if item["mikuType"] == "NxBurner" then
            return 0.67
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.65
        end

        if item["mikuType"] == "NxTask" and item["engine-2251"] then
            # recovery time: [0.5, 0.6]
            return TxEngine::engineToListingPriority(item["engine-2251"])
        end

        if item["mikuType"] == "NxTask" and !item["engine-2251"] then
            return 0.5
        end

        if item["mikuType"] == "TxCore" then
            return 0.45
        end

        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 0.4
        end

        if item["mikuType"] == "NxQuark" then
            return 0
        end

        raise "I do not know how to ListingPriorities::metric item: #{item}"
    end
end
