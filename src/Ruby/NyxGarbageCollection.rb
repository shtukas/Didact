# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run()
    def self.run()
        
        puts "NyxGarbageCollection::run()"
        
        NyxPrimaryObjects::objectsEnumerator().each{|object|
            next if NyxPrimaryObjects::nyxNxSets().include?(object["nyxNxSet"])
            puts "removing invalid setid : #{object}"
            NyxObjects::destroy(object)
        }

        Arrows::arrows().each{|arrow|
            b1 = NyxPrimaryObjects::getOrNull(arrow["sourceuuid"]).nil?
            b2 = NyxPrimaryObjects::getOrNull(arrow["targetuuid"]).nil?
            isNotConnecting = (b1 or b2)
            if isNotConnecting then
                puts "removing arrow: #{arrow}"
                NyxObjects::destroy(arrow)
            end
        }

        NSDataTypeX::attributes().each{|attribute|
            next if NyxPrimaryObjects::getOrNull(attribute["targetuuid"])
            puts "removing attribute without a target: #{attribute}"
            NyxObjects::destroy(attribute)
        }

        # remove datalines with parent node

        # remove datapoints with parent dataline

    end
end
