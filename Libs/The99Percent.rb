# encoding: UTF-8

class The99Percent

    # reference = {
    #     "count"    =>
    #     "datetime" =>
    # }

    # The99Percent::issueNewReference()
    def self.issueNewReference()
        count = The99Percent::getCurrentCount()
        reference = {
            "count"    => count,
            "datetime" => Time.new.utc.iso8601
        }
        puts JSON.pretty_generate(reference).green
        return !LucilleCore::askQuestionAnswerAsBoolean("Issue this new reference ? ")
        XCache::set("002c358b-e6ee-41bd-9bee-105396a6349a", JSON.generate(reference))
        reference
    end

    # The99Percent::getReference()
    def self.getReference()
        reference = XCache::getOrNull("002c358b-e6ee-41bd-9bee-105396a6349a")
        if reference then
            JSON.parse(reference)
        else
            The99Percent::issueNewReference()
        end
    end

    # The99Percent::getCurrentCount()
    def self.getCurrentCount()
        ["TxDated", "TxProject", "NxTask", "NxIced", "NxLine"]
            .map{|mikuType| Fx18Index2PrimaryLookup::countObjectsByMikuType(mikuType) }
            .inject(0, :+)
    end

    # The99Percent::ratio()
    def self.ratio()
        reference = The99Percent::getReference()
        current   = The99Percent::getCurrentCount()
        current.to_f/reference["count"]
    end
end
