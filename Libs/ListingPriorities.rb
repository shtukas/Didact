

class ListingPriorities

    # ListingPriorities::metric(item)
    def self.metric(item)

        return item["listing-priority"] if item["listing-priority"]

        if item["mikuType"] == "DesktopTx1" then
            return 0.9
        end

        if item["mikuType"] == "DxStackItem" then
            return 0.8 + 0.2*0.1*Math.atan(-item["position"]) # range: (0.7, 0.9)
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
