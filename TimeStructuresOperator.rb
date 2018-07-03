
# encoding: UTF-8

# TimeStructuresOperator

class TimeStructuresOperator
    
    # TimeStructure: { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }   

    def self.setTimeStructure(uuid, timeUnitInDays, timeCommitmentInHours)
        timestructure = { "time-unit-in-days"=> timeUnitInDays, "time-commitment-in-hours" => timeCommitmentInHours }
        FKVStore::set("02D6DCBC-87BD-4D4D-8F0B-411B7C06B972:#{uuid}", JSON.generate(timestructure))
        timestructure
    end

    def self.getTimeStructureOrNull(uuid)
        timestructure = FKVStore::getOrNull("02D6DCBC-87BD-4D4D-8F0B-411B7C06B972:#{uuid}")
        return nil if timestructure.nil?
        JSON.parse(timestructure)
    end
end