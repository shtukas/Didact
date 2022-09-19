
# encoding: UTF-8

class Nx112

    # Nx112::carrierAccess(item)
    def self.carrierAccess(item)
        return if item.nil?
        puts "Nx112::carrierAccess(item): #{PolyFunctions::toString(item)}"
        if item["nx112"] then
            Nx112::targetAccess(item["nx112"])
        else
            LucilleCore::pressEnterToContinue()
        end

    end

    # Nx112::targetAccess(uuid)
    def self.targetAccess(uuid)
        return if uuid.nil?
        target = ItemsEventsLog::getProtoItemOrNull(uuid)
        if target.nil? then
            puts "I the target object (uuid: #{uuid}) doesn't exists."
            LucilleCore::pressEnterToContinue()
            return
        end
        PolyActions::access(target)
    end
end
