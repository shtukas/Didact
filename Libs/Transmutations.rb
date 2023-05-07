
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxFire", "NxTask"]
    end

    # Transmutations::interactivelySelectMikuTypeOrNull()
    def self.interactivelySelectMikuTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", Transmutations::targetMikuTypes())
    end

    # Transmutations::transmute(uuid)
    def self.transmute(uuid)
        sourceType = Blades::getMandatoryAttribute2(uuid, "mikuType")

        targetMikuType = Transmutations::interactivelySelectMikuTypeOrNull()
        return if targetMikuType.nil?

        if item["mikuType"] == "NxFire" and targetMikuType == "NxTask" then
            Blades::setAttribute2(uuid, "engine", TxEngines::interactivelyMakeEngineOrDefault())
            Blades::setAttribute2(uuid, "boarduuid", NxBoards::interactivelySelectBoarduuidOrNull())
            Blades::setAttribute2(uuid, "mikuType", "NxFire")

            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFire" then
            Blades::setAttribute2(uuid, "boarduuid", NxBoards::interactivelySelectBoarduuidOrNull())
            Blades::setAttribute2(uuid, "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            board    = NxBoards::interactivelySelectOneOrNull()
            position = NxTasksPositions::decidePositionAtOptionalBoard(board)
            engine   = TxEngines::interactivelyMakeEngineOrDefault()
            Blades::setAttribute2(uuid, "boarduuid", board ? board["uuid"] : nil)
            Blades::setAttribute2(uuid, "position", position)
            Blades::setAttribute2(uuid, "engine", engine)
            Blades::setAttribute2(uuid, "mikuType", "NxTask")
            return
        end

        puts "I do not know how to transmute uuid: #{uuid}, sourceType: #{sourceType} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end
end