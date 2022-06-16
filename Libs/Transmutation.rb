
# encoding: UTF-8

class Transmutation

    # Transmutation::transmutation1(item, source, target, isSimulation)
    def self.transmutation1(item, source, target, isSimulation = false)

        if source == "TxDated" and target == "TxTodo" then
            return true if isSimulation
            item["mikuType"] = "TxTodo"
            Librarian::commit(item)
            return
        end

        if source == "TxDated" and target == "TxFloat" then
            return true if isSimulation
            item["mikuType"] = "TxFloat"
            Librarian::commit(item)
            return
        end

        if source == "TxFloat" and target == "TxDated" then
            return true if isSimulation
            item["mikuType"] = "TxDated"
            item["datetime"] = CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull()
            Librarian::commit(item)
            return
        end

        if source == "TxFloat" and target == "TxTodo" then
            return true if isSimulation
            item["mikuType"] = "TxTodo"
            Librarian::commit(item)
            return
        end

        if source == "TxTodo" and target == "NxDataNode" then
            return true if isSimulation
            item["mikuType"] = "NxDataNode"
            Librarian::commit(item)
            LxAction::action("landing", item)
            return
        end

        if source == "NxDataNode" and target == "NxPerson" then
            return true if isSimulation
            item["mikuType"] = "NxPerson"
            item["name"] = item["description"]
            Librarian::commit(item)
        end

        return false if isSimulation

        puts "I do not yet know how to transmute from '#{source}' to '#{target}'"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutation::transmutation2(item, source)
    def self.transmutation2(item, source)
        target = Iam::interactivelyGetTransmutationTargetOrNull()
        return if target.nil?
        Transmutation::transmutation1(item, source, target)
    end
end
