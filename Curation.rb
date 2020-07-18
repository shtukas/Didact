
# encoding: UTF-8

=begin
    KeyToStringOnDiskStore::setFlagTrue(repositorylocation or nil, key)
    KeyToStringOnDiskStore::setFlagFalse(repositorylocation or nil, key)
    KeyToStringOnDiskStore::flagIsTrue(repositorylocation or nil, key)

    KeyToStringOnDiskStore::set(repositorylocation or nil, key, value)
    KeyToStringOnDiskStore::getOrNull(repositorylocation or nil, key)
    KeyToStringOnDiskStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyToStringOnDiskStore::destroy(repositorylocation or nil, key)
=end

class Curation

    # Curation::run()
    def self.run()

        curationTimeControlUUID = "56995147-b264-49fb-955c-d5a919395ea3"

        return if (rand*rand) < BankExtended::recoveredDailyTimeInHours(curationTimeControlUUID)

        time1 = Time.new.to_f

        unconnected = NSDataType3::getElementByNameOrNull("[unconnected]")

        NSDataType3::getNSDataType3NavigationTargets(unconnected)
        .each{|ns3|
            system("clear")

            puts "Network placement curation"
            puts NSDataType3::ns3ToString(ns3)
            puts ""
            puts "First I am going to show you the ns3 so that you do a bit of cleaning there"
            LucilleCore::pressEnterToContinue()
            NSDataType3::landing(ns3)
            puts ""
            puts "Now please select a parent for it (possibly the root node)"
            parent = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()
            if parent then
                Arrows::make(parent, ns3)
                Arrows::remove(unconnected, ns3)
            end
            break
        }

        time2 = Time.new.to_f

        Bank::put(curationTimeControlUUID, time2-time1)

    end
end