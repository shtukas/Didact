
class Fsck

    # Fsck::fsckOrError(item)
    def self.fsckOrError(item)
        if item["mikuType"] == "NxAnniversary" then
            return
        end
        if item["mikuType"] == "NxPool" then
            return
        end
        if item["mikuType"] == "Wave" then
            return
        end
        raise "I do not know how to fsck mikutype: #{item["mikuType"]}"
    end
end