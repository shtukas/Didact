# encoding: UTF-8

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        NxTodosIO::items() + Database2::itemsForMikuType("Wave")
    end

    # Catalyst::getCatalystItemOrNull(uuid)
    def self.getCatalystItemOrNull(uuid)

        item = NxTriages::getOrNull(uuid)
        return item if item

        item = NxOndates::getOrNull(uuid)
        return item if item

        item = Database2::getObjectByUUIDOrNull(uuid)
        return item if item

        item = NxTodosIO::getOrNull(uuid)
        return item if item

        nil
    end
end
