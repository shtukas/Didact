
class DxStack

    # DxStack::issue(target, position)
    def self.issue(target, position)
        uuid = SecureRandom.uuid
        Events::publishItemInit("DxStackItem", uuid)
        Events::publishItemAttributeUpdate(uuid, "targetuuid", target["uuid"])
        Events::publishItemAttributeUpdate(uuid, "position", position)
        Catalyst::itemOrNull(uuid)
    end

    # Data

    # DxStack::toString(item)
    def self.toString(item)
        target = DxStack::targetOrNull(item)
        if target then
            "(stack: #{"%6.2f" % item["position"]}) #{PolyFunctions::toString(target)}"
        else
            Catalyst::destroy(item["uuid"])
            "(stack) garbage collected"
        end
    end

    # DxStack::itemsInOrder()
    def self.itemsInOrder()
        Catalyst::mikuType("DxStackItem")
            .sort_by{|item| item["position"]}
    end

    # DxStack::targetOrNull(item)
    def self.targetOrNull(item)
        Catalyst::itemOrNull(item["targetuuid"])
    end

    # DxStack::newFirstPosition()
    def self.newFirstPosition()
        Catalyst::mikuType("DxStackItem").reduce(0){|x, item| [x, item["position"]].min } - 1
    end

    # DxStack::newNextPosition()
    def self.newNextPosition()
        Catalyst::mikuType("DxStackItem").reduce(0){|x, item| [x, item["position"]].max } + 1
    end

    # Ops

    # DxStack::onTarget(item, l = lambda {|target| })
    def self.onTarget(item, l)
        target = DxStack::targetOrNull(item)
        return if target.nil?
        l.call(target)
    end
end